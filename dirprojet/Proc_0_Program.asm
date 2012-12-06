JMBSI 129        ;0  absolute jump to $prep: to prepare the memory structure (intvec, proc/file tables)
SETRI R1 0         ;1=$int1: address where the current proc id is stored
LDMEM R1 R0	   ;2 get the last scheduled process id, to start from right after it (round robin)
SETRI R2 1         ;3 the increment for process table slots
ADDRG R0 R0 R2	   ;4 the next process id to study, or one past the last (then we are going to wrap around)
SETRI R11 20       ;5 the address where the number of processes is stored
LDMEM R11 R1       ;6 R1 now contains the number of processes
SETRG R9 R1        ;7 save R1 into R9, so R9 now also contains the number of processes -- constant
ADDRG R9 R9 R2     ;8 actually make R9 one larger because proc id are from 1 to R1 , R9 is constant, needed for the wrap around test
SETRI R3 1         ;9 the ReadyToRun process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R4 3         ;10 the SemWait process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R15 100      ;11 the start address of the semaphore vector (where we keep the semaphore state values)
SETRI R6 0         ;12 for now 'no', we did not find any non-exited process yet    
SETRG R7 R0        ;13=$top: copy R0 for the test for the wrap around
SUBRG R7 R7 R9	   ;14 prepare the test for R0 wrap around
JNZRI R7 1  ;15 if R7 (that is R0) is not equal to R9 (the number of processes) we can continue
SETRI R0 1	   ;16 otherwise, we need to set R0 to 1 to wrap around (pid zero is for the kernel)
SETRG R10 R11	   ;17=$nextPid: prepare the offset for the process table start address
ADDRG R10 R10 R0   ;18 now R10 contains the address of the current process slot in the process table
SETRI R14 200      ;19 the start of the proc sem waitlists address vect, one list for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R14 R14 R0   ;20 the address of the start of the proc sem waitlists address vect for the current process
LDMEM R10 R8       ;21 get the state of the current process (address in R10) into R8
JZROI R8 17 ;22 this process is exited, we jump to $nextproc:
SETRI R6 1         ;23 yes, we found at least one non-exited process
SETRG R12 R8	   ;24 save R8 into R12, we need the state once again
SUBRG R8 R8 R3     ;25 prepare the test whether this process is in the ready state
JZROI R8 21 ;26 jump to $startproc: for id R0 and process table address R10, since it is indeed ready
SUBRG R12 R12 R4   ;27 prepare the test whether this process is in semwait
JNZRI R12 11 ;28 jump to $nextproc: since the proc of id R0 is not in semwait
SETRI R13 0        ;29 ok, this proc is in semwait, preparing for semoptest(0): we are first only testing
SETRI R5 1         ;30 the frame width for the subroutine call 
SETRI R16 169 ;31 the address of the start of the $semoptest sub
CLLSB R5 R16       ;32 call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 6 ;33  because it means we still cannot apply the semops this proc was waiting for
SETRI R13 1        ;34 ok, ready to apply them 
SETRI R5 1         ;35 the frame width for the subroutine call
SETRI R16 169 ;36 the address of the start of the $semoptest sub    
CLLSB R5 R16       ;37 call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 128   ;38 this should never ever happen
JMTOI 8   ;39 jump to $startproc: we are now done with all the semaphore operations, and can complete the election of process of pid R0
ADDRG R0 R0 R2     ;40=$nextproc: increment the pid for the next process to study 
SUBRG R1 R1 R2     ;41 decrement loop counter
JNZRI R1  -30     ;42 jump to $top: loop for max number processes
JNZRI R6 2     ;43 no ready proc but at least one not exited, so we go to $wait: 
SDOWN              ;44 all processes have exited, we're done, system going down
INTRP              ;45 we allow interrupts (which were disabled by the call to this interrupt)
NOPER              ;46=$wait: a bit for some interrupt (e.g. net I/O complete), which then jumps right there
JMBSI 46        ;47 and we loop back to $wait: in order to wait some more
SETRI R3 2         ;48=$startproc: the Running state, for the ready process which we just found
STMEM R10 R3       ;49 change the process state to running (address in R0)
SETRI R1 0         ;50 address where the current proc id is stored
STMEM R1 R0        ;51 store the (newly become) current proc id
LDPSW R0           ;52 go on to execute proc of id R0    , @@end of interrupt #1@@
SETRI R0 0         ;53=$int2: exit current process    , the address where its pid is stored
LDMEM R0 R1        ;54 R1 now has the pid of the process which is now exiting
SETRI R2 20        ;55 offset to get the process slot address from the process id
ADDRG R0 R1 R2     ;56 R0 now contains the process slot address
SETRI R3 0         ;57 the exited process state value
STMEM R0 R3        ;58 set the state of the process to exit
JMBSI 1        ;59 absolute jump to $int1: to keep going    , @@end of interrupt #2@@
SETRI R0 0         ;60=$int3: scheduler interrupt, the current process , the address where its pid is stored
LDMEM R0 R1        ;61 R1 now has the pid of the process which was just interrupted
SETRI R2 20        ;62 offset to get the process slot address from the process id
ADDRG R0 R1 R2     ;63 R0 now contains the process slot address
SETRI R3 1         ;64 the interrupted process new state value of readyToRun
STMEM R0 R3        ;65 set the state of the process to readyToRun
JMBSI 1        ;66 absolute jump to $int1: to keep going    , @@end of interrupt #3@@
SETRI R0 0         ;67=$int4: semop request for current process  , the address where its pid is stored
LDMEM R0 R1        ;68 R1 now has the pid of the process which is requesting a semop
SETRI R4 20        ;69 offset to get the process slot address from the process id
ADDRG R0 R1 R4     ;70 R0 now contains the process slot address
SETRI R6 3         ;71 the SemWait state value
STMEM R0 R6        ;72 change the process state to SemWait (address in R0)
SETRI R14 200      ;73 the start of the proc sem waitlists address vect, one for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R14 R14 R1   ;74 the start of the current proc sem waitlist address vect
LDMEM R14 R5	   ;75 now R5 contains the first address of the proc sem waitlists vect in kernel memory
STMEM R5 R2	   ;76 first we store the length, then we're going to go one by one to copy the R2 elements, starting with the first
SETRI R7 1	   ;77 constant increment
ADDRG R5 R5 R7	   ;78=$semwcopy: advance R5 to the address of the first component of the current element of the proc sem waitlists 
LDPRM R1 R3 R8	   ;79 read the first component of the first semop from process memory
STMEM R5 R8	   ;80 store the first component of the first semop in kernel memory
ADDRG R3 R3 R7	   ;81 advance R3 to the address of the second component of the current semop of the proc sem waitlists in proc memory
ADDRG R5 R5 R7	   ;82 advance R5 to the address of the second component of the current semop of the proc sem waitlists in kernel memory
LDPRM R1 R3 R8	   ;83 read the second component of the current semop from process memory
STMEM R5 R8	   ;84 store the second component of the current semop in kernel memory
ADDRG R3 R3 R7	   ;85 advance R3 to the address of the first component of the next semop (if any) of the proc sem waitlists in proc memory
SUBRG R2 R2 R7	   ;86 decrement the loop counter
JNZRI R2 -10 ;87 loop back to continue copying until done
SETRI R15 100      ;88 done, so now preparing the start address of the semaphore vector (where we keep the semaphore state values)  
SETRI R13 0        ;89 preparing for semoptest(0): we are first only testing
SETRI R5 1         ;90 the frame width for the subroutine call 
SETRI R16 169 ;91 the address of the start of the $semoptest sub
CLLSB R5 R16       ;92 call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 -93    ;93 because it means we cannot apply the semops, so we need to elect another process , the current one will remain in SemWait for now
SETRI R13 1        ;94 ok, ready to apply them 
SETRI R5 1         ;95 the frame width for the subroutine call 
SETRI R16 169 ;96 the address of the start of the $semoptest sub
CLLSB R5 R16       ;97 call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 68   ;98 this should never ever happen
SETRI R6 2         ;99 the Running state, for the ready process which we just found
STMEM R0 R6        ;100 change the process state back to running (address in R0)
SETRI R6 20        ;101 offset to get the process id from the process slot address
SUBRG R0 R0 R6     ;102 get the process id in R0
SETRI R1 0         ;103 address where the current proc id is stored
STMEM R1 R0        ;104 store the (newly become) current proc id
LDPSW R0           ;105 go on to execute proc of id R0  , @@end of interrupt #4@@
SETRI R0 0         ;106=$int5: consoleOut request for current process  , the address where its pid is stored
LDMEM R0 R1        ;107 R1 now has the pid of the process which is requesting the consoleOut operation
SETRI R6 20	   ;108 offset to get the process slot address from the process id
ADDRG R0 R1 R6	   ;109 R0 now contains the process slot address
SETRI R5 1	   ;110 the readyToRun state
STMEM R0 R5	   ;111 store the readyToRun state for the current process
SETRI R7 301	   ;112 The address in kernel memory where we need to write the # of items for the consoleOut
STMEM R7 R5        ;113 just one item for now
LDPRM R1 R3 R6     ;114 R6 now contains the first item to be obtained (read) and thus sent to consoleOut (recall R3 is given to us by the proc)
SETRI R8 304	   ;115 The address in kernel memory where we decided to write the item (copying it from the process memory)
STMEM R8 R6 	   ;116 now writing the item (from R6) which we just read from the process memory a few lines above, at address 304 in kernel mem
SETRI R7 302	   ;117 The address in kernel memory where we need to write the start address (param) where to read the items for the consoleOut
STMEM R7 R8	   ;118 now effectively preparing the start address "parameter" for consoleOut (i.e. write the number '304' at address 302)
LDPRM R1 R4 R7     ;119 R7 now contains the type of first item to be obtained (read) and thus sent to consoleOut
SETRI R8 404	   ;120 The address in kernel memory where we decided to write the item (copying it from the process memory)
STMEM R8 R7 	   ;121 now writing the item type (from R7) which we just read from the process memory a few lines above, at address 404 in kernel mem
SETRI R7 303	   ;122 The address in kernel memory where we need to write the start address (param) where to read the item types for the consoleOut
STMEM R7 R8	   ;123 now effectively preparing the type vect start address "parameter" for consoleOut (i.e. write the number '404' at address 303)
SETRI R7 300	   ;124 The address in kernel memory where, by writing a value of 1, we trigger the consoleOut
STMEM R7 R5	   ;125 there we go -- we just requested a "hardware consoleOut" through "memory-mapping IO"
JMBSI 1        ;126 we are done, so we make an absolute jump to $int1: to keep going , @@end of interrupt #5@@
SETRI R0 0         ;127=$int6: consoleIn request for current process  , the address where its pid is stored
LDMEM R0 R1        ;128 R1 now has the pid of the process which is requesting the consoleIn operation
SETRI R0 1         ;129=$prep: initial kernel setup, R0 constant increment/decrement value
SETRI R1 1         ;130 address of first slot in the interrupt vector
SETRI R2 1     ;131 prog address of $int1 start next available process
STMEM R1 R2        ;132 setting up the interrupt vector for interrupt #1
ADDRG R1 R1 R0     ;133 increment the address of slots
SETRI R2 53     ;134 prog address of $int2: exit current process
STMEM R1 R2        ;135 setting up the interrupt vector for interrupt #2
ADDRG R1 R1 R0     ;136 increment the address of slots
SETRI R2 60     ;137 prog address of $int3: scheduler interrupt
STMEM R1 R2        ;138 setting up the interrupt vector for interrupt #3
ADDRG R1 R1 R0     ;139 increment the address of slots
SETRI R2 67     ;140 prog address of $int4: semop Request
STMEM R1 R2        ;141 setting up the interrupt vector for interrupt #3
ADDRG R1 R1 R0     ;142 increment the address of slots
SETRI R2 106     ;143 address of $int5: consoleOut Request
STMEM R1 R2        ;144 setting up the interrupt vector for interrupt #4
ADDRG R1 R1 R0     ;145 increment the address of slots
SETRI R2 127     ;146 address of $int6: consoleIn Request
STMEM R1 R2        ;147 setting up the interrupt vector for interrupt #5
SETRI R1 21        ;148 address where process table starts
SETRI R2 1         ;149 ReadyToRun initial procstate value
GETI0 R3           ;150 number of processes
SETRI R8 20        ;151 address to save the number of processes
STMEM R8 R3        ;152 saving the number of processes
ADDRG R9 R8 R0	   ;153 offset for the semwaitlists
SETRI R10 200	   ;154 the start of the proc sem waitlists address vect, one for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R7 R10 R8    ;155 the first such address 
STMEM R1 R2        ;156=$procSetup: set initial process state value to current slot
ADDRG R1 R1 R0     ;157 advance address for process table slot
STMEM R10 R7	   ;158 setting the start address for the current proc sem waitlists in the master proc sem waitlists address vect
ADDRG R7 R7 R9	   ;159 increment the start address with the right offset
ADDRG R10 R10 R0   ;160 advance address in the master proc sem waitlists address vect
SUBRG R3 R3 R0     ;161 decrement loop counter
JNZRI R3 -7 ;162 jump back to $procSetup: for max number processes
SETRI R0 0         ;163 address where current scheduled proc id is stored
SETRI R1 0	   ;164 pid 0
STMEM R0 R1	   ;165 just to initialize the state of the system for int1 
JMBSI 1        ;166 absolute jump to $int1: to start the work    , @@end of initial kernel setup@@
SDOWN              ;167=$crash: 
SETRI R20 0        ;168 the V() semop value (and V state value)
SETRI R16 1        ;169=$semoptest: can we indeed P() each sem we were waiting for ? (the V()'s will go through anyway)
LDMEM R14 R22      ;170 R22 now contains the address where the current proc semwaitlist really starts
LDMEM R22 R17      ;171 R17 contains the number of semops requested by the current proc (whatever that proc is)
ADDRG R22 R22 R16  ;172=$procsemtop: R22 contains the address of the current semaphore index
LDMEM R22 R18      ;173 R18 contains the current semaphore index
ADDRG R18 R18 R15  ;174 R18 now contains the address of the current semaphore
LDMEM R18 R19      ;175 R19 contains the state value of the current semaphore
SUBRG R19 R19 R16  ;176 prepare the test whether the current semaphore is in the P state (then R19 is going to be zero)
ADDRG R22 R22 R16  ;177 R22 now contains the address of the current semop 
LDMEM R22 R21      ;178 R21 now contains the semop code for the current semaphore
SUBRG R21 R21 R16  ;179 prepare the test whether the current semop code is P() (then R21 is going to be zero)
JNZRI R19 4 ;180 jump to $maybeDoPorVonSemV: if the current semaphore is in the V state
JNZRI R21 9 ;181 ok, the current semaphore is in P , now, jump to $maybeDoVonSemP: if the current semop code is V()
SETRI R16 0        ;182 actually the current semop is P(), (and the current semaphore is in P) so we cannot do anything , we return with 0 in R16 
SETRI R17 1        ;183 the stack frame width -- we know its only 1
RETSB R17          ;184 for any RETSB we need the R17=1 for the stack frame width
JZROI R13 2 ;185=$maybeDoPorVonSemV: jump to $nextsem if we only need to examine and not also do it
JNZRI R21 1 ;186 jump to $nextsem: if the current semop code is V(), because V() on a semaphore in state V is a no-op
STMEM R18 R16      ;187 ok, do P() on the semaphore (which was in state V) -- R18 had the address of the current semaphore 
SUBRG R17 R17 R16  ;188=$nextsem: decrement semaphore loop counter
JNZRI R17 -18 ;189 jump to $procsemtop: if we have more semaphores to examine and perphaps operate upon
RETSB R16          ;190 we are all done, we return with 1 in R16 (and use the fact that the stack frame width is also 1)
JZROI R13 -4 ;191=$maybeDoVonSemP: actually jump to $nextsem if we only need to examine and not also do it
STMEM R18 R27      ;192 ok, do V() on the semaphore (which was in state P) -- R18 had the address of the current semaphore 
JMTOI -6     ;193 jump to $nextsem:
