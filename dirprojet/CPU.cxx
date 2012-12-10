#include <CPU.h>
#include <sstream>
#include <iostream>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstdlib>
#include <cerrno>

using namespace std;
using namespace nsSysteme;

CPU::CPU(const string &id, ostream  &log, istream &consoleIn, ostream &consoleOut,
         const int nGenReg, const int nProc) : 
    BaseCPU(id,log, consoleIn, consoleOut, nGenReg, nProc) {
    const int memFd (Open("Memory",O_RDWR|O_CREAT, S_IRUSR | S_IWUSR));
    const int wordSize(sizeof(int));
    for(int kProc(0); kProc < nProc; kProc ++) {
        mem[kProc]  . setUp(memFd,MEMORYSIZEPERPROCESS * wordSize, kProc * MEMORYSIZEPERPROCESS * wordSize);
        ostringstream buffstr,buff2str;
        buffstr  << "Proc_" << kProc << "_Program.asm";
        buff2str << "Prog_" << kProc << "_0"; 
        proc[kProc] . loadProc(buffstr . str(),buff2str . str());
    }
    sharedMem . setUp(memFd,MEMORYSIZEPERPROCESS * wordSize, nProc * MEMORYSIZEPERPROCESS * wordSize);
    prReg  . setVal(PROCPSWFRAMESTART); 
    pcReg  . setVal(0);
    spReg  . setVal(MEMORYSIZEPERPROCESS - 1);
    mdReg  . switchToMaster();
    inReg0 . setVal(nProc - 1);
    logStream << "CPU::CPU() complete for " << cpuId << "\n";
}

CPU::~CPU() {
    logStream << "\nMemory dump at end time\n";
    logStream << "Shared memory\n";
    sharedMem . dumpAll(logStream);
    logStream << "\n-----------------------------------\n";
    for(unsigned int kProc (0); kProc < mem . size(); kProc++) {
        logStream << "Proc " << kProc << "\n";
        mem[kProc] . dumpAll(logStream);
        logStream << "\n-----------------------------------\n";
    }
}


void CPU::execute(const Instruction &instr) throw(CExc){
    const string cpuLog ("CPU(" + cpuId + ")::execute() pr ");
    switch(instr . iType) {
        case        NOPER:
            logStream << cpuLog << prReg . getVal() << " " << instr << "\n";
            sleep(1);
            break;
        case    DMPRG: 
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            dumpReg(logStream,true);
            break;
        case    MSTRM:
            mdReg . switchToMaster();
            logStream << cpuLog << prReg . getVal() << " MSTRM MD = " << mdReg . getVal() << "\n"; 
            break;
        case        USERM:
            mdReg . switchToUser();
            logStream << cpuLog << prReg . getVal() << " USERM MD = " << mdReg . getVal() << "\n"; 
            break;
        case        NINTR:
            qInterruptible = false;
            logStream << cpuLog << prReg . getVal() << " " << instr << " qI = " << qInterruptible << "\n";
            break;
        case        INTRP:
            qInterruptible = true;
            logStream << cpuLog << prReg . getVal() << " " << instr << " qI = " << qInterruptible << "\n";
            break;
            case        SETRI:
            genReg[instr . op1] . setVal(instr . numVal);
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R"   << instr . op1 << " = " << genReg[instr . op1] . getVal() << "\n"; 
            break;
        case        SETRG:
            genReg[instr . op1] . setVal(genReg[instr . op2] . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op1 << " = " << genReg[instr . op1] . getVal() << "\n"; 
            break;
        case        SETPR:
            prReg . setVal(genReg[instr . op1] . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " PR = " << prReg . getVal() << "\n"; 
            break;
        case        CPPRG:
            genReg[instr . op1] . setVal(prReg . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op1 << " = " << genReg[instr . op1] . getVal() << "\n"; 
            break;
        case        ADDRG:
            genReg[instr . op1] . setVal(genReg[instr . op2] . getVal() + genReg[instr . op3] . getVal()); 
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op1 << " = " << genReg[instr . op1] . getVal() << "\n"; 
            break;
        case        SUBRG:
            genReg[instr . op1] . setVal(genReg[instr . op2] . getVal() - genReg[instr . op3] . getVal()); 
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op1 << " = " << genReg[instr . op1] . getVal() << "\n"; 
            break;
        case    PSHRG: {
            const int wordSize  (sizeof(int));
            const int crtProc   (prReg . getVal());
            mem[crtProc] . storeAt((spReg . getVal() - genReg[instr . op1] . getVal()) * wordSize, genReg[instr . op2] . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " SP = " << spReg . getVal()   << " stack[@-" 
                      << genReg[instr . op1] . getVal() << "]: " 
                      << mem[crtProc] . loadFrom((spReg . getVal() - genReg[instr . op1] . getVal()) * wordSize) << "\n";
        } 
            break;
        case    POPRG: {
            const int wordSize  (sizeof(int));
            const int crtProc   (prReg . getVal());
            genReg[instr . op2] . setVal(mem[crtProc] . loadFrom((spReg . getVal() + genReg[instr . op1] . getVal()) * wordSize));
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " SP = " << spReg . getVal() << " stack[@+" 
                      << genReg[instr . op1] . getVal() << "]: "
                      << " R" << instr . op2 << " = " << genReg[instr . op2] . getVal() << "\n"; 
        }
            break;
        case        JMABS:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            pcReg . setVal(genReg[instr . op1] . getVal());
            logStream << "zero, PC = " << pcReg . getVal() << "\n";
            break;
        case        JMPTO:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            pcReg . relativeJump(genReg[instr . op1] . getVal());
            logStream << "zero, PC = " << pcReg . getVal() << "\n";
            break;
        case        JZERO:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(genReg[instr . op1] . getVal() == 0) {
                pcReg . relativeJump(genReg[instr . op2] . getVal());
                logStream << "zero, PC = " << pcReg . getVal() << "\n";
            }
            else {
                logStream << "non zero, PC = " << pcReg . getVal() << "\n";
            }
            break;
        case        JNZRO:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(genReg[instr . op1] . getVal() != 0) {
                pcReg . relativeJump(genReg[instr . op2] . getVal());
                logStream << "non zero, PC = " << pcReg . getVal() << "\n";
            }
            else {
                logStream << "zero, PC = " << pcReg . getVal() << "\n";
            }
            break;
        case        JMBSI:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            pcReg . setVal(instr . numVal);
            logStream << "zero, PC = " << pcReg . getVal() << "\n";
            break;
        case        JMTOI:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            pcReg . relativeJump(instr . numVal);
            logStream << "zero, PC = " << pcReg . getVal() << "\n";
            break;
        case        JZROI:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(genReg[instr . op1] . getVal() == 0) {
                pcReg . relativeJump(instr . numVal);
                logStream << "zero, PC = " << pcReg . getVal() << "\n";
            }
            else {
                logStream << "non zero, PC = " << pcReg . getVal() << "\n";
            }
            break;
        case        JNZRI:
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(genReg[instr . op1] . getVal() != 0) {
                pcReg . relativeJump(instr . numVal);
                logStream << "non zero, PC = " << pcReg . getVal() << "\n";
            }
            else {
                logStream << "zero, PC = " << pcReg . getVal() << "\n";
            }
            break;
        case        LDMEM: {
            const int wordSize  (sizeof(int));
            const int crtProc   (prReg . getVal());
            genReg[instr . op2] . setVal(mem[crtProc] . loadFrom(genReg[instr . op1] . getVal() * wordSize)); 
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op2 << " = " << genReg[instr . op2] . getVal() 
                      << " from addr " << genReg[instr . op1] . getVal() << "\n"; 
        }
            break;
        case        STMEM:{
            const int wordSize  (sizeof(int));
            const int crtProc   (prReg . getVal());
            bool      qNormal   (true);
            if(mdReg . getVal() == 1 && crtProc == KERNELPID) { 
                // then we see if it is a special memory-mapped I/O address and request
                if(genReg[instr . op1] . getVal() == CONSOLEINPUTOUTPUTTRIGGER) {
                    if(genReg[instr . op2] . getVal() == 0) { 
                        consoleInOut . input(consoleInputStream,mem[crtProc],genReg[instr . op1] . getVal());
                    }
                    else if(genReg[instr . op2] . getVal() == 1) { 
                        consoleInOut . output(consoleOutputStream,mem[crtProc],genReg[instr . op1] . getVal());
                    }
                    else {
                        cerr << "SYSTEM FAULT: Wrong consoleInputOutput code " <<  genReg[instr . op2] . getVal()
                             << " expected 0 or 1.\n";
                        exit(2);
                    }
                    qNormal = false;
                }
            }
            if(qNormal) {
                mem[crtProc] . storeAt(genReg[instr . op1] . getVal() * wordSize, genReg[instr . op2] . getVal());
                logStream << cpuLog << prReg . getVal() << " " << instr 
                          << " R" << instr . op2 << " = " << genReg[instr . op2] . getVal() 
                          << " to addr " << genReg[instr . op1] . getVal() << "\n"; 
            }
        }
            break;
        case        LDSHM: {
            const int wordSize  (sizeof(int));
            genReg[instr . op2] . setVal(sharedMem . loadFrom(genReg[instr . op1] . getVal() * wordSize)); 
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op2 << " = " << genReg[instr . op2] . getVal() 
                      << " from addr " << genReg[instr . op1] . getVal() << "\n"; 
        }
            break;
        case        STSHM:{
            const int wordSize  (sizeof(int));
            sharedMem . storeAt(genReg[instr . op1] . getVal() * wordSize, genReg[instr . op2] . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op2 << " = " << genReg[instr . op2] . getVal() 
                      << " to addr " << genReg[instr . op1] . getVal() << "\n"; 
        }
            break;
        case        LDPSW: {
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(mdReg . getVal() != 1) {
                throw CExc("Illegally attempting to LDPSW"," when not in master mode.");
            }
            const unsigned int proc2ld   (genReg[instr . op1] . getVal());
            if(proc2ld > mem . size()) {
                throw CExc("Too large proc value for LDPSW",proc2ld);
            }
            const int frameStart(PROCPSWFRAMESTART);
            const int wordSize  (sizeof(int));
            spReg . setVal(mem[proc2ld] . loadFrom(frameStart));
            pcReg . setVal(mem[proc2ld] . loadFrom(frameStart + wordSize));
            mdReg . setVal(mem[proc2ld] . loadFrom(frameStart + 2 * wordSize));
            for(unsigned int kReg(0); kReg < genReg . size(); kReg++) {
                genReg[kReg] . setVal(mem[proc2ld] . loadFrom(frameStart + (3 + kReg) * wordSize));
            }
            prReg . setVal(proc2ld);
            qInterruptible = true;
            dumpReg(logStream,true);
        }
            break;
        case        SPSWR: {
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(mdReg . getVal() != 1) {
                throw CExc("Illegally attempting to SPSWR"," when not in master mode.");
            }
            const unsigned int proc2st   (genReg[instr . op1] . getVal());
            if(proc2st > mem . size()) {
                throw CExc("Too large proc value for SPSWR",proc2st);
            }
            const int frameStart(PROCPSWFRAMESTART);
            const int wordSize  (sizeof(int));
            mem[proc2st] . storeAt(frameStart + (3 + instr . op2) * wordSize, genReg[instr . op3] . getVal());
        }
            break;
        case        LDPRM: {
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(mdReg . getVal() != 1) {
                throw CExc("Illegally attempting to LDPRM"," when not in master mode.");
            }
            const int wordSize  (sizeof(int));
            genReg[instr . op3] . setVal(mem[genReg[instr . op1] . getVal()] . loadFrom(genReg[instr . op2] . getVal() * wordSize)); 
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op3 << " = " << genReg[instr . op3] . getVal() 
                      << " from addr " << genReg[instr . op2] . getVal() 
                      << " of proc "   << genReg[instr . op1] . getVal() 
                      << "\n"; 
        }
            break;
        case        STPRM:{
            logStream << cpuLog << prReg . getVal() << " " << instr << " ";
            if(mdReg . getVal() != 1) {
                throw CExc("Illegally attempting to STPRM"," when not in master mode.");
            }
            const int wordSize  (sizeof(int));
            mem[genReg[instr . op1] . getVal()] . storeAt(genReg[instr . op2] . getVal() * wordSize, genReg[instr . op3] . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op3 << " = " << genReg[instr . op3] . getVal() 
                      << " to addr " << genReg[instr . op2] . getVal()
                      << " of proc " << genReg[instr . op1] . getVal()
                      << "\n"; 
        }
            break;
        case        WKCPU:
            //// A FAIRE, PAR EXEMPLE SELON L'IDEE
            //// ECRIRE au CPU[genReg[instr . op1] . getVal()] LA VALEUR  genReg[instr . op2] . getVal()
            //// ECRIRE au CPU[genReg[instr . op1] . getVal()] LA VALEUR  genReg[instr . op3] . getVal()
            //// FAIRE QUE le CPU(genReg[instr . op1] . getVal()) SOIT INTERROMPU (quand il "le permettra")
            //// ... etc. ...
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " signalling CPU(" << genReg[instr . op1] . getVal() << ") data: "
                      << genReg[instr . op2] . getVal() << " and " << genReg[instr . op3] . getVal()
                      << "\n";
            break;
        case    GETI0:
            genReg[instr . op1] . setVal(inReg0 . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op1 << " = " << genReg[instr . op1] . getVal() 
                      << "\n";
            break;
        case    GETI1:
            genReg[instr . op1] . setVal(inReg1 . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr 
                      << " R" << instr . op1 << " = " << genReg[instr . op1] . getVal() 
                      << "\n";
            break;
        case        CLLSB: {
            const int wordSize  (sizeof(int));
            const int crtProc   (prReg . getVal());
            spReg . setVal(spReg . getVal() - genReg[instr . op1] . getVal());
            mem[crtProc] . storeAt(spReg . getVal() * wordSize, pcReg . getVal());
            pcReg . setVal(genReg[instr . op2] . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr << " PC = " << pcReg . getVal() << "\n";
        }
            break;
        case        RETSB:{
            const int wordSize  (sizeof(int));
            const int crtProc   (prReg . getVal());
            pcReg . setVal(mem[crtProc] . loadFrom(spReg . getVal() * wordSize));
            spReg . setVal(spReg . getVal() + genReg[instr . op1] . getVal());
            logStream << cpuLog << prReg . getVal() << " " << instr << " PC = " << pcReg . getVal() << "\n";
        }
            break;
        case        CLINT: 
            logStream << cpuLog << prReg . getVal() << " " << instr ;
            interrupt(genReg[instr . op1] . getVal(),true);
            break;
        case    SPECP:
            logStream << cpuLog << prReg . getVal() << " " << instr << " not implemented.\n";
            break;
        case    SDOWN:
            logStream << cpuLog << prReg . getVal() << " " << instr << "\n";
            if(mdReg . getVal() != 1) {
                throw CExc("Illegally attempting to SDOWN"," when not in master mode.");
            }
            qRun = false;
            break;           
        default: cerr << "INTERNAL ERROR Should never get here.\n";exit(1);
    } // end of switch(instruction type)
    dumpReg(logStream);
} // end of CPU::execute()

void CPU::interrupt(const int interruptNumber, bool qCLINTInstr) throw(CExc) {
    qInterruptible = false;
    if(!qCLINTInstr) {
        logStream << cpuId << " Interrupt #" << interruptNumber << " ";
    }
    const int proc2stPSW   (prReg . getVal());
    const int wordSize  (sizeof(int));
    if(proc2stPSW) { // save PSW for regular processes only, not for kernel
        const int frameStart(PROCPSWFRAMESTART);
        mem[proc2stPSW] . storeAt(frameStart,                spReg . getVal());
        mem[proc2stPSW] . storeAt(frameStart + wordSize,     pcReg . getVal());
        mem[proc2stPSW] . storeAt(frameStart + 2 * wordSize, mdReg . getVal());
        for(unsigned int kReg(0); kReg < genReg . size(); kReg++) {
            mem[proc2stPSW] . storeAt(frameStart + (3 + kReg) * wordSize, genReg[kReg] . getVal());
        }
        mem[KERNELPID] . storeAt(KERNELSAVECURRENTPROCID, prReg . getVal());
        prReg . setVal(KERNELPID); // execute kernel code
    }
    mdReg . switchToMaster();
    pcReg . setVal(mem[KERNELPID] . loadFrom(interruptNumber * wordSize));
    dumpReg(logStream,true);
}

void CPU::pendingIntIfAny() throw(CExc) {
    if(uTick > SAMEPROCMAXINSTRTICKCHUNK) {
        uTick = 0;
        logStream << "Kernel scheduler interrupt.\n";
        interrupt(SCHEDULENEXTPROCINTERRUPT,false);
    }
    logStream << "Not interrupted this time.\n";
}
