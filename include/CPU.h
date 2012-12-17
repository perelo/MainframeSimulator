#include "Board.h"

#define MEMORYSIZEPERPROCESS     1000 
#define KERNELSAVECURRENTPROCID     0
#define KERNELPID                   0 
#define PROCPSWFRAMESTART           0 
#define SAMEPROCMAXINSTRTICKCHUNK   15
#define SCHEDULENEXTPROCINTERRUPT   3
#define MAXSPROCCOUNT               9 
#define MAXSEMAPHORECOUNT           9
#define SEMAPHOREVECTORSTART      100
#define PROCSEMWAITLISTSTART      200
#define PROCSEMWAITLISTSTARTELEMCNT 2
#define CONSOLEINPUTOUTPUTTRIGGER 300 
#define RANDOMGENERATORTRIGGER    500

class CPU : public BaseCPU {
public:
    CPU(const    string &id, ostream  &log,  
        istream &consoleIn,  ostream  &consoleOut,
        const int nGenReg, const int nProc);
    ~CPU();
    void execute  (const Instruction &instr) throw(nsSysteme::CExc); 
    void interrupt(const int interruptNumber, bool qCLINTInstr) throw(nsSysteme::CExc);
    void pendingIntIfAny() throw(nsSysteme::CExc);
};
