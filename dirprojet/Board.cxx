
#include <Board.h>
#include <sstream>
#include <iostream>
#include <fstream>
#include <vector>
#include <map>
#include <string>
#include <exception>
#include <cstdlib>
#include "CExc.h"


using namespace std;
using namespace nsSysteme;

Register::Register():value(0) {}

void Register::setVal(const int val) {
    value = val;
}

int Register::getVal() const {
    return(value);
}

StackPointer::StackPointer() : Register() {}

RunMode::RunMode() : Register() {}

void RunMode::switchToMaster() {
    setVal(1);
}

void RunMode::switchToUser() {
    setVal(0);
}

int RunMode::qIsMaster() const {
    return(getVal() == 1);
}


ProgramCounter::ProgramCounter(InstructionParser &iPar) : 
    Register(),instrParse(iPar) {}

void ProgramCounter::relativeJump(int offset) {
    value += offset;
}


Instruction ProgramCounter::fetch(ProgramText &progText) { 
    string instrWord,regOne,regTwo,regThree;
    cerr << "ProgramCounter::fetch() line " << value << "\n";
    istringstream buffStr (progText[value]);
    buffStr >> instrWord >> regOne >> regTwo >> regThree; 
    int qImmediate(0);
    InstructionType iT(instrParse . getInstrTypeFromString(instrWord,&qImmediate));
    Instruction instr(progText[value],
                      iT,
                      instrParse . getRegIdFromString(regOne),
                      instrParse . getRegIdFromString(regTwo),
                      instrParse . getRegIdFromString(regThree),
                      regOne,regTwo,qImmediate);
    value += 1;
    return(instr);
}

Process::Process() {}

void Process::loadProc(const string &fileName, const string &pName) throw(CExc){
    programName = pName;
    ifstream progFile(fileName . c_str());
    if(!progFile) {
      throw CExc("Process::loadProc(" + fileName + "," + pName + ")"," could not open file for reading.");
    }
    for(string oneLine; getline(progFile,oneLine);) {
      if(!(oneLine . size()) || oneLine[0] == '#')  {
        continue; // ignore comment-only lines as well as empty lines
      }
      programText . push_back(oneLine);
    }
}

ProcessCounter::ProcessCounter() : Register() {
    value = 0;
}

Memory::Memory() : fileDescr(-1), memSize(0), offset(-1) {}

void Memory::setUp(int fD, int mS, int ofs)  {
    fileDescr = fD;
    memSize   = mS;
    offset    = ofs;
    char valZero[memSize];
    memset(valZero,0,memSize);
    Lseek(fileDescr, offset, SEEK_SET);
    Write(fileDescr,&valZero,memSize);
    const int wordSize(sizeof(int));
    storeAt(0,mS / wordSize); // preparing the initial value for the spReg slot for the PSW
}

int Memory::loadFrom(int addr) throw (CExc) {
    if(addr > memSize) {
        throw CExc("Memory::loadFrom()"," address too large.");
    }
    if(addr < 0) {
        throw CExc("Memory::loadFrom()"," negative address.");
    }
    int val;
    Lseek(fileDescr, offset + addr, SEEK_SET);
    Read(fileDescr,&val,sizeof(val));
    return(val);
}

void Memory::storeAt(int addr, int val) throw (CExc) {
    if(addr > memSize) {
        throw CExc("Memory::storeAt()"," address too large.");
    }
    if(addr < 0) {
        throw CExc("Memory::storeAt()"," negative address.");
    }
    Lseek(fileDescr, offset + addr, SEEK_SET);
    Write(fileDescr,&val,sizeof(val));
}

void Memory::dumpAll(ostream &os) {
    int memSizeWord(memSize/sizeof(int));
    int memVal[memSizeWord];
    Lseek(fileDescr, offset, SEEK_SET);
    Read(fileDescr,memVal,memSize);
    int kLine(-1);
    os << "0\t";
    for(int kAddr(0); kAddr < memSizeWord; kAddr++) {
        os << memVal[kAddr] << " ";
        if(++kLine >= 9 && kAddr < memSizeWord - 1) {
            os << "\n" << ((kAddr + 1) / 10) * 10 << "\t";
            kLine = -1;
        }
    }
}

Instruction::Instruction(const string    &iStr, 
                         InstructionType iT, 
                         int o1, int o2, int o3,
                         const string   &str1,
                         const string   &str2,
                         int             qImm) :
    instrStr(iStr),iType(iT), op1(o1), op2(o2), op3(o3), iArg1(str1), iArg2(str2), qImmediate(qImm) {
    if(qImmediate) {
      numVal = atoi((qImmediate == 1 ? iArg1 :  iArg2) . c_str());
    }
}

ostream &operator <<(ostream &os, const Instruction& instr) {
    os << instr . instrStr;
    return(os);
}

InstructionParser::InstructionParser() {
    instructDict["NOPER"] = NOPER;
    instructDict["DMPRG"] = DMPRG;
    instructDict["MSTRM"] = MSTRM;
    instructDict["USERM"] = USERM;
    instructDict["NINTR"] = NINTR;
    instructDict["INTRP"] = INTRP;
    instructDict["SETRI"] = SETRI; qInstructHasImmediateArg[SETRI] = 2;
    instructDict["SETRG"] = SETRG;
    instructDict["SETPR"] = SETPR;
    instructDict["CPPRG"] = CPPRG;
    instructDict["ADDRG"] = ADDRG;
    instructDict["SUBRG"] = SUBRG;
    instructDict["PSHRG"] = PSHRG;
    instructDict["POPRG"] = POPRG;
    instructDict["JMABS"] = JMABS;
    instructDict["JMBSI"] = JMBSI; qInstructHasImmediateArg[JMBSI] = 1;
    instructDict["JMPTO"] = JMPTO;
    instructDict["JMTOI"] = JMTOI; qInstructHasImmediateArg[JMTOI] = 1;
    instructDict["JZERO"] = JZERO;
    instructDict["JNZRO"] = JNZRO;
    instructDict["JZROI"] = JZROI; qInstructHasImmediateArg[JZROI] = 2;
    instructDict["JNZRI"] = JNZRI; qInstructHasImmediateArg[JNZRI] = 2;
    instructDict["LDMEM"] = LDMEM;
    instructDict["STMEM"] = STMEM;
    instructDict["LDSHM"] = LDSHM;
    instructDict["STSHM"] = STSHM;
    instructDict["LDPSW"] = LDPSW;
    instructDict["SPSWR"] = SPSWR;
    instructDict["LDPRM"] = LDPRM;
    instructDict["STPRM"] = STPRM;
    instructDict["WKCPU"] = WKCPU;
    instructDict["GETI0"] = GETI0;
    instructDict["GETI1"] = GETI1;
    instructDict["CLLSB"] = CLLSB;
    instructDict["RETSB"] = RETSB;
    instructDict["CLINT"] = CLINT;
    instructDict["SPECP"] = SPECP;
    instructDict["SDOWN"] = SDOWN;
}

InstructionType InstructionParser::getInstrTypeFromString(const string &iStr, int *pqImm) throw(CExc) {
    const map<string,InstructionType>::iterator pInstr(instructDict . find(iStr));
    if(pInstr == instructDict . end()) {
        throw CExc("InstructionParser::getInstrTypeFromString("+iStr+",...)","Invalid instruction");
    }
    if(pqImm == 0) {
        throw CExc("InstructionParser::getInstrTypeFromString("+iStr+",...)"," null pointer, please debug.\n");
    }
    const map<InstructionType,int>::const_iterator pImm(qInstructHasImmediateArg . find(pInstr -> second));
    *pqImm = (pImm != qInstructHasImmediateArg . end() ? pImm -> second : 0);
    return(pInstr -> second);
}

int InstructionParser::getRegIdFromString(const string &rStr) throw(CExc) {
    if(rStr . size() > 1 && rStr[0] == 'R') {
        return(atoi(rStr . substr(1) . c_str()));
    }
    return(-1);
}

void ConsoleInOut::input(istream &s,
                         Memory  &mem,
                         int      startAddr) { 
    const int wordSize(sizeof(int));
// @startAddr   : just the operation code
// @startAddr+1 : the # of items to read
// @startAddr+2 : the start address where to write the items one by one after console input
// @startAddr+3 : the start address where the item type vect is stored (the "format")
    const int nItems         (mem . loadFrom((startAddr + 1) * wordSize));
    const int destAddrStart  (mem . loadFrom((startAddr + 2) * wordSize));
    const int formatAddrStart(mem . loadFrom((startAddr + 3) * wordSize));
    cerr << "ConsoleInput for " << nItems << " items:\n";
    for(int kItem(0); kItem < nItems; kItem++) {
        const int itemFormat (mem . loadFrom((formatAddrStart + kItem) * wordSize));
        if(itemFormat == 0) { // int value
            int a; s >> a; mem . storeAt((destAddrStart + kItem) * wordSize, a);
        }
        else if(itemFormat == 1) { // char value
            char a; s >> a; mem . storeAt((destAddrStart + kItem) * wordSize, static_cast<int>(a));
        }
        else {
            cerr << "ConsoleInputOutput SYSTEM FAULT: Wrong format code " << itemFormat << ", only 0 (int) or 1 (char)\n";
            exit(2);
        }
    }
    cerr << "\nConsoleInput end\n";
}

void ConsoleInOut::output(ostream &s,
                          Memory  &mem,
                          int      startAddr) {
    const int wordSize(sizeof(int));
// @startAddr   : just the operation code
// @startAddr+1 : the # of items to write
// @startAddr+2 : the start address where to read the items one by one for console output
// @startAddr+3 : the start address where the item type vect is stored (the "format")
    const int nItems (mem . loadFrom((startAddr + 1) * wordSize));
    const int fromAddrStart  (mem . loadFrom((startAddr + 2) * wordSize));
    const int formatAddrStart(mem . loadFrom((startAddr + 3) * wordSize));
    cerr << "ConsoleOutput for " << nItems << " items:\n";
    for(int kItem(0); kItem < nItems; kItem++) {
        const int itemFormat (mem . loadFrom((formatAddrStart + kItem) * wordSize));
        if(itemFormat == 0) { // int value
            const int a(mem . loadFrom((fromAddrStart + kItem) * wordSize));
            s << a;
        }
        else if(itemFormat == 1) { // char value
            const char a(mem . loadFrom((fromAddrStart + kItem) * wordSize));
            s << a;
        }
        else {
            cerr << "ConsoleInputOutput SYSTEM FAULT: Wrong format code " << itemFormat << ", only 0 (int) or 1 (char)\n";
            exit(2);
        }
    }
    cerr << "\nConsoleOutput end\n";
}

BaseCPU::BaseCPU(const string &id, ostream  &log, istream &consoleIn, ostream &consoleOut, 
                 const int nGenReg, const int nProc) : pcReg(iPrs), cpuId(id), logStream(log),
                                                       consoleOutputStream(consoleOut),
                                                       consoleInputStream(consoleIn) {
    genReg . resize(nGenReg);
    proc   . resize(nProc);
    mem    . resize(nProc);
    qRun           = true;
    qInterruptible = false;
    logStream << "BaseCPU::BaseCPU() complete for " << cpuId << "\n";
}

void BaseCPU::dumpReg(ostream &os, bool qRegAsWell) {
    os << " PR = " << prReg . getVal() 
       << " SP = " << spReg . getVal() 
       << " PC = " << pcReg . getVal() 
       << " MD = " << mdReg . getVal()
       << " qI = " << qInterruptible;
    if(qRegAsWell) {
        for(unsigned int kReg(0); kReg < genReg . size(); kReg++) {
            os << " R" << kReg << " = " << genReg[kReg] . getVal();  
        }
    }
    os << "\n";
} 

void BaseCPU::execute(const Instruction &) throw(CExc) {
    throw CExc("BaseCPU::execute()"," should never be called.");
}

void BaseCPU::interrupt(const int, bool) throw(CExc) {
    throw CExc("BaseCPU::interrupt()"," should never be called.");
}

void BaseCPU::pendingIntIfAny() throw(CExc) {
    throw CExc("BaseCPU::pendingIntIfAny()"," should never be called.");
}

void BaseCPU::run() throw(CExc) {
    for(iTick = uTick = 0; qRun && iTick < 10000; uTick += (mdReg . getVal() != 1),iTick++) {
        execute(pcReg . fetch(proc[prReg . getVal()] . programText));
        if(qInterruptible) {
            pendingIntIfAny();
        }
    }
    logStream << "CPU " << cpuId << " is now fully stopped, total " << iTick << " instructions overall.\n";
}
