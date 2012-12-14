JMBSI $prep        ;LNR  absolute jump to $prep: to prepare the memory structure (intvec, proc/file tables)
#-------- start of $int1 ----------------------------
SETRI R1 0         ;LNR=$int1: address where the current proc id is stored
LDMEM R1 R0        ;LNR get the last scheduled process id, to start from right after it (round robin)
SETRI R2 1         ;LNR the increment for process table slots
ADDRG R0 R0 R2     ;LNR the next process id to study, or one past the last (then we are going to wrap around)
SETRI R11 20       ;LNR the address where the number of processes is stored
LDMEM R11 R1       ;LNR R1 now contains the number of processes
SETRG R9 R1        ;LNR save R1 into R9, so R9 now also contains the number of processes -- constant
ADDRG R9 R9 R2     ;LNR actually make R9 one larger because proc id are from 1 to R1 , R9 is constant, needed for the wrap around test
SETRI R3 1         ;LNR the ReadyToRun process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R4 3         ;LNR the SemWait process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R15 100      ;LNR the start address of the semaphore vector (where we keep the semaphore state values)
SETRI R6 0         ;LNR for now 'no', we did not find any non-exited process yet    
SETRG R7 R0        ;LNR=$top: copy R0 for the test for the wrap around
SUBRG R7 R7 R9     ;LNR prepare the test for R0 wrap around
JNZRI R7 $nextPid  ;LNR if R7 (that is R0) is not equal to R9 (the number of processes) we can continue
SETRI R0 1         ;LNR otherwise, we need to set R0 to 1 to wrap around (pid zero is for the kernel)
SETRG R10 R11      ;LNR=$nextPid: prepare the offset for the process table start address
ADDRG R10 R10 R0   ;LNR now R10 contains the address of the current process slot in the process table
SETRI R14 200      ;LNR the start of the proc sem waitlists address vect, one list for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R14 R14 R0   ;LNR the address of the start of the proc sem waitlists address vect for the current process
LDMEM R10 R8       ;LNR get the state of the current process (address in R10) into R8
JZROI R8 $nextproc ;LNR this process is exited, we jump to $nextproc:
SETRI R6 1         ;LNR yes, we found at least one non-exited process
SETRG R12 R8       ;LNR save R8 into R12, we need the state once again
SUBRG R8 R8 R3     ;LNR prepare the test whether this process is in the ready state
JZROI R8 $startproc ;LNR jump to $startproc: for id R0 and process table address R10, since it is indeed ready
SUBRG R12 R12 R4   ;LNR prepare the test whether this process is in semwait
JNZRI R12 $nextproc ;LNR jump to $nextproc: since the proc of id R0 is not in semwait
SETRI R13 0        ;LNR ok, this proc is in semwait, preparing for semoptest(0): we are first only testing
SETRI R5 1         ;LNR the frame width for the subroutine call 
SETRI R16 $semoptest ;LNR the address of the start of the $semoptest sub
CLLSB R5 R16       ;LNR call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 $nextproc ;LNR  because it means we still cannot apply the semops this proc was waiting for
SETRI R13 1        ;LNR ok, ready to apply them 
SETRI R5 1         ;LNR the frame width for the subroutine call
SETRI R16 $semoptest ;LNR the address of the start of the $semoptest sub    
CLLSB R5 R16       ;LNR call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 $crash   ;LNR this should never ever happen
JMTOI $startproc   ;LNR jump to $startproc: we are now done with all the semaphore operations, and can complete the election of process of pid R0
ADDRG R0 R0 R2     ;LNR=$nextproc: increment the pid for the next process to study 
SUBRG R1 R1 R2     ;LNR decrement loop counter
JNZRI R1  $top     ;LNR jump to $top: loop for max number processes
JNZRI R6 $wait     ;LNR no ready proc but at least one not exited, so we go to $wait: 
SDOWN              ;LNR all processes have exited, we're done, system going down
INTRP              ;LNR we allow interrupts (which were disabled by the call to this interrupt)
NOPER              ;LNR=$wait: a bit for some interrupt (e.g. net I/O complete), which then jumps right there
JMBSI $wait        ;LNR and we loop back to $wait: in order to wait some more
SETRI R3 2         ;LNR=$startproc: the Running state, for the ready process which we just found
STMEM R10 R3       ;LNR change the process state to running (address in R0)
SETRI R1 0         ;LNR address where the current proc id is stored
STMEM R1 R0        ;LNR store the (newly become) current proc id
LDPSW R0           ;LNR go on to execute proc of id R0    , @@end of interrupt #1@@
#-------- start of $int2 ----------------------------
SETRI R0 0         ;LNR=$int2: exit current process    , the address where its pid is stored
LDMEM R0 R1        ;LNR R1 now has the pid of the process which is now exiting
SETRI R2 20        ;LNR offset to get the process slot address from the process id
ADDRG R0 R1 R2     ;LNR R0 now contains the process slot address
SETRI R3 0         ;LNR the exited process state value
STMEM R0 R3        ;LNR set the state of the process to exit
JMBSI $int1        ;LNR absolute jump to $int1: to keep going    , @@end of interrupt #2@@
#-------- start of $int3 ----------------------------
SETRI R0 0         ;LNR=$int3: scheduler interrupt, the current process , the address where its pid is stored
LDMEM R0 R1        ;LNR R1 now has the pid of the process which was just interrupted
SETRI R2 20        ;LNR offset to get the process slot address from the process id
ADDRG R0 R1 R2     ;LNR R0 now contains the process slot address
SETRI R3 1         ;LNR the interrupted process new state value of readyToRun
STMEM R0 R3        ;LNR set the state of the process to readyToRun
JMBSI $int1        ;LNR absolute jump to $int1: to keep going    , @@end of interrupt #3@@
#-------- start of $int4 ----------------------------
# R2 contains the number of semop entries
# R3 contains the start address in process memory for the semop list ((semId,semOp),(semId,semOp),...)
SETRI R0 0         ;LNR=$int4: semop request for current process  , the address where its pid is stored
LDMEM R0 R1        ;LNR R1 now has the pid of the process which is requesting a semop
SETRI R4 20        ;LNR offset to get the process slot address from the process id
ADDRG R0 R1 R4     ;LNR R0 now contains the process slot address
SETRI R6 3         ;LNR the SemWait state value
STMEM R0 R6        ;LNR change the process state to SemWait (address in R0)
SETRI R14 200      ;LNR the start of the proc sem waitlists address vect, one for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R14 R14 R1   ;LNR the start of the current proc sem waitlist address vect
LDMEM R14 R5       ;LNR now R5 contains the first address of the proc sem waitlists vect in kernel memory
STMEM R5 R2        ;LNR first we store the length, then we're going to go one by one to copy the R2 elements, starting with the first
SETRI R7 1         ;LNR constant increment
ADDRG R5 R5 R7     ;LNR=$semwcopy: advance R5 to the address of the first component of the current element of the proc sem waitlists 
LDPRM R1 R3 R8     ;LNR read the first component of the first semop from process memory
STMEM R5 R8        ;LNR store the first component of the first semop in kernel memory
ADDRG R3 R3 R7     ;LNR advance R3 to the address of the second component of the current semop of the proc sem waitlists in proc memory
ADDRG R5 R5 R7     ;LNR advance R5 to the address of the second component of the current semop of the proc sem waitlists in kernel memory
LDPRM R1 R3 R8     ;LNR read the second component of the current semop from process memory
STMEM R5 R8        ;LNR store the second component of the current semop in kernel memory
ADDRG R3 R3 R7     ;LNR advance R3 to the address of the first component of the next semop (if any) of the proc sem waitlists in proc memory
SUBRG R2 R2 R7     ;LNR decrement the loop counter
JNZRI R2 $semwcopy ;LNR loop back to continue copying until done
SETRI R15 100      ;LNR done, so now preparing the start address of the semaphore vector (where we keep the semaphore state values)  
SETRI R13 0        ;LNR preparing for semoptest(0): we are first only testing
SETRI R5 1         ;LNR the frame width for the subroutine call 
SETRI R16 $semoptest ;LNR the address of the start of the $semoptest sub
CLLSB R5 R16       ;LNR call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 $int1    ;LNR because it means we cannot apply the semops, so we need to elect another process , the current one will remain in SemWait for now
SETRI R13 1        ;LNR ok, ready to apply them 
SETRI R5 1         ;LNR the frame width for the subroutine call 
SETRI R16 $semoptest ;LNR the address of the start of the $semoptest sub
CLLSB R5 R16       ;LNR call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 $crash   ;LNR this should never ever happen
SETRI R6 2         ;LNR the Running state, for the ready process which we just found
STMEM R0 R6        ;LNR change the process state back to running (address in R0)
SETRI R6 20        ;LNR offset to get the process id from the process slot address
SUBRG R0 R0 R6     ;LNR get the process id in R0
SETRI R1 0         ;LNR address where the current proc id is stored
STMEM R1 R0        ;LNR store the (newly become) current proc id
LDPSW R0           ;LNR go on to execute proc of id R0  , @@end of interrupt #4@@
#-------- start of $int5 ----------------------------
# R2 contains the number of items to write
# R3 contains the start address in process memory where to read the items one by one
# R4 contains the start address in process memory where to read the item types one by one (0 for int, 1 for char)
JZROI R2 $int1     ;LNR=$int5: consoleOut request for current process  , no item to write, go back to the scheduler
SETRI R0 0         ;LNR the address where its pid is stored
LDMEM R0 R1        ;LNR R1 now has the pid of the process which is requesting the consoleOut operation
SETRI R6 20        ;LNR offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;LNR R0 now contains the process slot address
SETRI R5 1         ;LNR the readyToRun state
STMEM R0 R5        ;LNR store the readyToRun state for the current process
SETRI R7 301       ;LNR The address in kernel memory where we need to write the # of items for the consoleOut
STMEM R7 R2        ;LNR store the number of items to write at addr 301
SETRI R8 304       ;LNR The address in kernel memory where we decided to write the items (copying them from the process memory)
SETRI R7 302       ;LNR The address in kernel memory where we need to write the start address (param) where to read the items for the consoleOut
STMEM R7 R8        ;LNR now effectively preparing the start address "parameter" for consoleOut (i.e. write the number '304' at address 302)
SETRI R9 404       ;LNR The address in kernel memory where we decided to write the item types (copying them from the process memory)
SETRI R7 303       ;LNR The address in kernel memory where we need to write the start address (param) where to read the item types for the consoleOut
STMEM R7 R9        ;LNR now effectively preparing the type vect start address "parameter" for consoleOut (i.e. write the number '404' at address 303)
SETRI R10 0        ;LNR counter: number of items already written, initial value is 0
ADDRG R12 R3 R10   ;LNR=$write_item: R12 now contains the address of the item to be obtained (read), start addr + counter offset
LDPRM R1 R12 R6    ;LNR R6 now contains the first item to be obtained (read) and thus sent to consoleOut (recall R3 is given to us by the proc)
ADDRG R13 R8 R10   ;LNR R13 now contains the address to write the item we just read (R6), start addr + counter offset
STMEM R13 R6       ;LNR now writing the item (from R6) which we just read from the process memory a few lines above, at address 304 + counter in kernel mem
ADDRG R12 R4 R10   ;LNR R12 now contains the address of the type of the item to be obtained (read), start addr + counter offset
LDPRM R1 R12 R7    ;LNR R7 now contains the type of the item to be obtained (read) and thus sent to consoleOut
ADDRG R13 R9 R10   ;LNR R13 now contains the address to write the type of the item we just read (R6), start addr + counter offset
STMEM R13 R7       ;LNR now writing the item type (from R7) which we just read from the process memory a few lines above, at address 404 + counter in kernel mem
ADDRG R10 R10 R5   ;LNR increment the counter, because we juste wrote an item in the kernel mem (at start addr of the vect to be read to output the items)
SUBRG R11 R2 R10   ;LNR prepare R11 : number of items left to write
JNZRI R11 $write_item ;LNR still some items to write, jump to $write_item to write the others
SETRI R7 300       ;LNR ok, no more items to write, store the address in kernel memory where, by writing a value of 1, we trigger the consoleOut
STMEM R7 R5        ;LNR there we go -- we just requested a "hardware consoleOut" through "memory-mapping IO"
JMBSI $int1        ;LNR done, go back to the scheduler
#-------- start of $int6 ----------------------------
# R2 contains the number of items to read
# R3 contains the start address in process memory where to write the items one by one
# R4 contains the start address in process memory where to read the item types one by one (0 for int, 1 for char)
JZROI R2 $int1     ;LNR=$int6: consoleIn request for current process  , no item to read, go back to the scheduler
SETRI R0 0         ;LNR the address where its pid is stored
LDMEM R0 R1        ;LNR R1 now has the pid of the process which is requesting the consoleIn operation
SETRI R6 20        ;LNR offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;LNR R0 now contains the process slot address
SETRI R5 1         ;LNR the readyToRun state
STMEM R0 R5        ;LNR store the readyToRun state for the current process
SETRI R7 301       ;LNR The address in kernel memory where we need to write the # of items for the consoleIn
STMEM R7 R2        ;LNR store the number of items to write at addr 301
SETRI R8 304       ;LNR The address in kernel memory where we decided to write the items (copying them from the consoleInputStream)
SETRI R7 302       ;LNR The address in kernel memory where we need to write the start address (param) where to write the items we read from the consoleIn
STMEM R7 R8        ;LNR now effectively preparing the start address "parameter" for consoleIn (i.e. write the number '304' at address 302)
SETRI R9 404       ;LNR The address in kernel memory where we decided to write the item types (copying them from the process memory)
SETRI R7 303       ;LNR The address in kernel memory where we need to write the start address (param) where to read the item types for the consoleIn
STMEM R7 R9        ;LNR now effectively preparing the type vect start address "parameter" for consoleIn (i.e. write the number '404' at address 303)
SETRI R10 0        ;LNR counter : number of types already written, initial value is 0
ADDRG R12 R4 R10   ;LNR=$write_type: R12 now contains the address of the item type to be obtained (read), start addr + counter offset
LDPRM R1 R12 R6    ;LNR R6 now contains the first item type to be obtained (read)
ADDRG R13 R9 R10   ;LNR R13 now contains the address to write the item type we just read (R6), start addr + counter offset
STMEM R13 R6       ;LNR now writing the item type (from R6) which we just read from the process memory a few lines above, at addr 404 + counter in kernel mem
ADDRG R10 R10 R5   ;LNR increment the counter, because we juste wrote an item type in the kernel mem
SUBRG R11 R10 R2   ;LNR prepare R11 : number of item types left to write
JNZRI R11 $write_type ;LNR still some item types to write, jump to write_type to write the others
SETRI R0 0         ;LNR ok, all the params have been prepared (# of items to read ; addr where to write the items ; addr where to read the types ; types of each item)
SETRI R7 300       ;LNR store the address in kernel memory where, by writing a value of 0, we trigger the consoleIn
STMEM R7 R0        ;LNR we request a "hardware consoleIn" through "memory-mapping IO", then we'll copy items from kernel mem to proc mem
SETRI R10 0        ;LNR now the the vect of the read items (from consoleIn) is at addr contained in R9 , init counter: number of items already written
ADDRG R12 R8 R10   ;LNR=$write_item_to_proc: R12 now contains the adress (in kernel mem) of the item to be wrote on the proc mem, start addr + counter offset
LDMEM R12 R6       ;LNR R6 now contains the first item to be wrote in the proc mem
ADDRG R13 R3 R10   ;LNR R13 now contains the address where to write the item we just read (R6), start addr + counter offset
STPRM R1 R13 R6    ;LNR now writing the item (from R6) which we just read from the kernel memory, in the proc memory
ADDRG R10 R10 R5   ;LNR increment the counter, because we juste wrote an item in the proc mem
SUBRG R11 R2 R10   ;LNR prepare R11 : number of items left to write
JNZRI R11 $write_item_to_proc ;LNR still some items to write, jump to $write_item to write the others
JMBSI $int1        ;LNR done, go back to the scheduler
# ......
#======== start of initial kernel setup =============
SETRI R0 1         ;LNR=$prep: initial kernel setup, R0 constant increment/decrement value
SETRI R1 1         ;LNR address of first slot in the interrupt vector
SETRI R2 $int1     ;LNR prog address of $int1 start next available process
STMEM R1 R2        ;LNR setting up the interrupt vector for interrupt #1
ADDRG R1 R1 R0     ;LNR increment the address of slots
SETRI R2 $int2     ;LNR prog address of $int2: exit current process
STMEM R1 R2        ;LNR setting up the interrupt vector for interrupt #2
ADDRG R1 R1 R0     ;LNR increment the address of slots
SETRI R2 $int3     ;LNR prog address of $int3: scheduler interrupt
STMEM R1 R2        ;LNR setting up the interrupt vector for interrupt #3
ADDRG R1 R1 R0     ;LNR increment the address of slots
SETRI R2 $int4     ;LNR prog address of $int4: semop Request
STMEM R1 R2        ;LNR setting up the interrupt vector for interrupt #3
ADDRG R1 R1 R0     ;LNR increment the address of slots
SETRI R2 $int5     ;LNR address of $int5: consoleOut Request
STMEM R1 R2        ;LNR setting up the interrupt vector for interrupt #4
ADDRG R1 R1 R0     ;LNR increment the address of slots
SETRI R2 $int6     ;LNR address of $int6: consoleIn Request
STMEM R1 R2        ;LNR setting up the interrupt vector for interrupt #5
SETRI R1 21        ;LNR address where process table starts
SETRI R2 1         ;LNR ReadyToRun initial procstate value
GETI0 R3           ;LNR number of processes
SETRI R8 20        ;LNR address to save the number of processes
STMEM R8 R3        ;LNR saving the number of processes
ADDRG R9 R8 R0     ;LNR offset for the semwaitlists
SETRI R10 200      ;LNR the start of the proc sem waitlists address vect, one for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R7 R10 R8    ;LNR the first such address 
STMEM R1 R2        ;LNR=$procSetup: set initial process state value to current slot
ADDRG R1 R1 R0     ;LNR advance address for process table slot
STMEM R10 R7       ;LNR setting the start address for the current proc sem waitlists in the master proc sem waitlists address vect
ADDRG R7 R7 R9     ;LNR increment the start address with the right offset
ADDRG R10 R10 R0   ;LNR advance address in the master proc sem waitlists address vect
SUBRG R3 R3 R0     ;LNR decrement loop counter
JNZRI R3 $procSetup ;LNR jump back to $procSetup: for max number processes
SETRI R0 0         ;LNR address where current scheduled proc id is stored
SETRI R1 0         ;LNR pid 0
STMEM R0 R1        ;LNR just to initialize the state of the system for int1 
JMBSI $int1        ;LNR absolute jump to $int1: to start the work    , @@end of initial kernel setup@@
SDOWN              ;LNR=$crash: 
#-------- start of $semoptest() ---------------------
#  input parameters (not modified in this procedure): 
#    R13 if 0, just test, if 1, then go ahead and do it as well while sweeping through
#    R14 the address where we put the address of start of the semlist (starting with the # of elems, and then pairs (semIndex,semOpVal)
#    R15 the address of the semvect of the kernel (100)
#  output value:
#    R16 1 if it is possible to do all operations, 0 if not
#  uses locally (that is, modifies):
#    R17=counter,R18=semAddr,R19=semVal,R20=ct0,R21=semOpVal, R22<-[R14],modif 
#- - - - - - - - - - - - - - - - - - - - - - - - - - - 
SETRI R20 0        ;LNR the V() semop value (and V state value)
SETRI R16 1        ;LNR=$semoptest: can we indeed P() each sem we were waiting for ? (the V()'s will go through anyway)
LDMEM R14 R22      ;LNR R22 now contains the address where the current proc semwaitlist really starts
LDMEM R22 R17      ;LNR R17 contains the number of semops requested by the current proc (whatever that proc is)
ADDRG R22 R22 R16  ;LNR=$procsemtop: R22 contains the address of the current semaphore index
LDMEM R22 R18      ;LNR R18 contains the current semaphore index
ADDRG R18 R18 R15  ;LNR R18 now contains the address of the current semaphore
LDMEM R18 R19      ;LNR R19 contains the state value of the current semaphore
SUBRG R19 R19 R16  ;LNR prepare the test whether the current semaphore is in the P state (then R19 is going to be zero)
ADDRG R22 R22 R16  ;LNR R22 now contains the address of the current semop 
LDMEM R22 R21      ;LNR R21 now contains the semop code for the current semaphore
SUBRG R21 R21 R16  ;LNR prepare the test whether the current semop code is P() (then R21 is going to be zero)
JNZRI R19 $maybeDoPorVonSemV ;LNR jump to $maybeDoPorVonSemV: if the current semaphore is in the V state
JNZRI R21 $maybeDoVonSemP ;LNR ok, the current semaphore is in P , now, jump to $maybeDoVonSemP: if the current semop code is V()
SETRI R16 0        ;LNR actually the current semop is P(), (and the current semaphore is in P) so we cannot do anything , we return with 0 in R16 
SETRI R17 1        ;LNR the stack frame width -- we know its only 1
RETSB R17          ;LNR for any RETSB we need the R17=1 for the stack frame width
JZROI R13 $nextsem ;LNR=$maybeDoPorVonSemV: jump to $nextsem if we only need to examine and not also do it
JNZRI R21 $nextsem ;LNR jump to $nextsem: if the current semop code is V(), because V() on a semaphore in state V is a no-op
STMEM R18 R16      ;LNR ok, do P() on the semaphore (which was in state V) -- R18 had the address of the current semaphore 
SUBRG R17 R17 R16  ;LNR=$nextsem: decrement semaphore loop counter
JNZRI R17 $procsemtop ;LNR jump to $procsemtop: if we have more semaphores to examine and perphaps operate upon
RETSB R16          ;LNR we are all done, we return with 1 in R16 (and use the fact that the stack frame width is also 1)
JZROI R13 $nextsem ;LNR=$maybeDoVonSemP: actually jump to $nextsem if we only need to examine and not also do it
STMEM R18 R27      ;LNR ok, do V() on the semaphore (which was in state P) -- R18 had the address of the current semaphore 
JMTOI $nextsem     ;LNR jump to $nextsem:
#--------------------------------------
#101: semVectStart: each semaphore is one int ("mem cell"), its ID is its offset from 100,
#                  V() is zero, P() is one     , we store at 100 the max # of
#              semaphores (50)
#--------------------------------------
