#include <vector>
#include <map>
#include <string>
#include <iostream>

#include <CExc.h>
#include <nsSysteme.h>


using std::vector;
using std::map;
using std::string;
using std::istream;
using std::ostream;

class Instruction;
class InstructionParser;

class Register {
protected:
    int value;
public:
    Register();
    void setVal(const int val);
    int  getVal() const;
};

typedef vector<Register> RegisterSet;

class StackPointer : public Register {
public:
    StackPointer();
};

class RunMode : public Register {
public:
    RunMode();
    void switchToMaster();
    void switchToUser();
    int  qIsMaster() const;
};

typedef vector<string>       ProgramText;

class ProgramCounter : public Register {
    InstructionParser &instrParse;
public:
    ProgramCounter(InstructionParser &iPar);
    void        relativeJump(int offset);
    Instruction fetch(ProgramText &progText);
};

class Process {
public:
    ProgramText programText;
    string      programName;
    Process();
    void loadProc(const string &fileName, const string &pName) throw(nsSysteme::CExc);
};

typedef vector<Process>  ProcessTable;

class ProcessCounter : public Register {
public:
    ProcessCounter();
};

class Memory { 
    int fileDescr;
    int memSize;
    int offset;
public:
    Memory();
    void setUp(int fD, int mS, int ofs);
    int  loadFrom(int addr) throw (nsSysteme::CExc);
    void storeAt (int addr, int val) throw (nsSysteme::CExc);
    void dumpAll(ostream &os);
};

typedef vector<Memory>  MemoryTable;

enum InstructionType {NOPER=0,
                      DMPRG, // ex: DMPRG              ; dump content of all registers to logstream
                      MSTRM, // ex: MSTRM              ; MD <- MasterMode
                      USERM, // ex: USERM              ; MD <- UserMode
                      NINTR, // ex: NINTR              ; disable interrupts
                      INTRP, // ex: INTRP              ; enable interrupts
                      SETRI, // ex: SETRI R2 254       ; R2 <- 254
                      SETRG, // ex: SETRG R2 R3        ; R2 <- R3
                      SETPR, // ex: SETPR R10          ; PR <- R10 (only in mastermode)
                      CPPRG, // ex: CPPRG R2           ; R2 <- PR  
                      ADDRG, // ex: ADDRG R2 R3 R4     ; R2 <- R3 + R4  
                      SUBRG, // ex: SUBRG R2 R3 R4     ; R2 <- R3 - R4  
                      PSHRG, // ex: PSHRG R5 R4        ; mem[(SP - R5) * sizeof(int)] <- R4
                      POPRG, // ex: POPRG R5 R7        ; R7 <- mem[(SP + R5) * sizeof(int)];
                      JMABS, // ex: JMABS R1           ; PC <- R1 
                      JMPTO, // ex: JMPTO R1           ; PC <- PC + R1 
                      JZERO, // ex: JZERO R12 R5       ; if(R12 == 0) { PC <- PC + R5 }
                      JNZRO, // ex: JNZRO R12 R5       ; if(R12 != 0) { PC <- PC + R5 }
                      JMBSI, // ex: JMBSI 23           ; PC <- 23 
                      JMTOI, // ex: JMTOI 24           ; PC <- PC + 24 
                      JZROI, // ex: JZROI R12 25       ; if(R12 == 0) { PC <- PC + 25 }
                      JNZRI, // ex: JNZRI R12 26       ; if(R12 != 0) { PC <- PC + 26 }
                      LDMEM, // ex: LDMEM R8 R21       ; R21     <- mem[R8] (for current proc memory space)
                      STMEM, // ex: STMEM R8 R21       ; mem[R8] <- R21  (for current proc memory space)
                      LDSHM, // ex: LDSHM R8 R21       ; R21     <- sharedMem[R8] (for all procs shared memory space)
                      STSHM, // ex: STSHM R8 R21       ; sharedMem[R8] <- R21  (for all procs shared memory space)
                      LDPSW, // ex: LDPSW R3           ; <SP,PR,PC,MD,R0,R1,...> <- memOfProc[R3][PROCPSWFRAMESTART]
                      SPSWR, // ex: SPSWR R3 R2 R4     ; memOfProc[R3][PROCPSWFRAMESTART+offset4.R2] <- R4 (master only)
                      LDPRM, // ex: LDPRM R3 R8 R21    ; R21     <- memOfProc[R3][R8] (master only)
                      STPRM, // ex: STPRM R3 R8 R21    ; memOfProc[R3][R8] <- R21 (master only)
                      WKCPU, // ex: WKCPU R3 R5 R6     ; CPU[R3].I0 <- R5 ; CPU[R3].I1 <- R6 ;  signal CPU[R3]
                      GETI0, // ex: GETI0 R5           ; R5 <- I0 (the only way to read I0 (after a WKCPU))
                      GETI1, // ex: GETI1 R5           ; R5 <- I1 (the only way to read I1 (after a WKCPU))
                      CLLSB, // ex: CLLSB R7 R5        ; SP <- SP - R7; mem[SP * sizeof(int)] <- PC; PC <- R5
                      RETSB, // ex: RETSB R6           ; PC <- mem[SP * sizeof(int)] ; SP <- SP + R6
                      CLINT, // ex: CLINT R7           ; PC <- IntVec[R7] (saves the PSW except for the kernel)
                      SPECP, // ex: SPECP R2 R3 R10 R4 ; special instruction given by R2 with (at most) three args(R3,..)
                      SCRASH,// ex: SCRASH             ; crash down the system (master only) -- major inconsistency issue (similar to kernel panic)
                      SDOWN};// ex: SDOWN              ; shut down system (master only)

class Instruction {
public:
    string          instrStr;
    InstructionType iType;
    int             op1, op2, op3;
    string          iArg1,iArg2;
    int             numVal;
    int             qImmediate;
    Instruction(const string &iStr, 
                InstructionType iT,
                int o1, int o2, int r, 
                const string &str1, const string &str2, 
                int qImm);
};

ostream & operator<<(ostream &os, const Instruction& instr);

class InstructionParser {
    map<string,InstructionType> instructDict;
    map<InstructionType,int>    qInstructHasImmediateArg;
public:
    InstructionParser();
    InstructionType getInstrTypeFromString(const string &iStr, int *pqImm) throw(nsSysteme::CExc);
    int             getRegIdFromString    (const string &rStr) throw(nsSysteme::CExc);
};

class ConsoleInOut {
public:
    void input (istream &s,
                Memory  &mem,
                int      startAddr);
    void output(ostream &s,
                Memory  &mem,
                int      startAddr);
};

class RandomGenerator {
public:
    RandomGenerator();
    void generateRandom (Memory &mem, int startAddr) throw (nsSysteme::CExc);
};

class BaseCPU {
protected:
    InstructionParser iPrs;
    StackPointer     spReg;  
    ProgramCounter   pcReg;
    ProcessCounter   prReg; 
    RunMode          mdReg;  // user or master
    RegisterSet      genReg;
    Register         inReg0,inReg1; // for interCPU communication (e.g. CPU<->DMA) 
    MemoryTable      mem;
    Memory           sharedMem;
    ProcessTable     proc;
    string           cpuId;
    ostream         &logStream;
    ostream         &consoleOutputStream;
    istream         &consoleInputStream;
    ConsoleInOut     consoleInOut;
    RandomGenerator  randomGenerator;
    bool            qRun;
    bool            qInterruptible;
    int             iTick,uTick;
public:
    BaseCPU(const string &id, ostream  &log, istream &consoleIn,  ostream  &consoleOut,
            const int nGenReg, const int nProc);
    virtual void dumpReg(ostream &os, bool qRegAsWell = false);
    virtual void execute(const Instruction &) throw(nsSysteme::CExc);
    virtual void run() throw(nsSysteme::CExc);
    virtual void interrupt(const int, bool) throw(nsSysteme::CExc);
    virtual void pendingIntIfAny() throw(nsSysteme::CExc);
};

