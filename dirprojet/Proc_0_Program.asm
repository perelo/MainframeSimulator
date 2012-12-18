JMBSI 198        ;0  absolute jump to $prep: to prepare the memory structure (intvec, proc/file tables)
SETRI R1 0         ;1=$int1: address where the current proc id is stored
LDMEM R1 R0        ;2 get the last scheduled process id, to start from right after it (round robin)
SETRI R2 1         ;3 the increment for process table slots
ADDRG R0 R0 R2     ;4 the next process id to study, or one past the last (then we are going to wrap around)
SETRI R11 20       ;5 the address where the number of processes is stored
LDMEM R11 R1       ;6 R1 now contains the number of processes
SETRG R9 R1        ;7 save R1 into R9, so R9 now also contains the number of processes -- constant
ADDRG R9 R9 R2     ;8 actually make R9 one larger because proc id are from 1 to R1 , R9 is constant, needed for the wrap around test
SETRI R3 1         ;9 the ReadyToRun process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R4 3         ;10 the SemWait process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R15 100      ;11 the start address of the semaphore vector (where we keep the semaphore state values)
SETRI R6 0         ;12 for now 'no', we did not find any non-exited process yet    
SETRG R7 R0        ;13=$top: copy R0 for the test for the wrap around
SUBRG R7 R7 R9     ;14 prepare the test for R0 wrap around
JNZRI R7 1  ;15 if R7 (that is R0) is not equal to R9 (the number of processes) we can continue
SETRI R0 1         ;16 otherwise, we need to set R0 to 1 to wrap around (pid zero is for the kernel)
SETRG R10 R11      ;17=$nextPid: prepare the offset for the process table start address
ADDRG R10 R10 R0   ;18 now R10 contains the address of the current process slot in the process table
SETRI R14 200      ;19 the start of the proc sem waitlists address vect, one list for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R14 R14 R0   ;20 the address of the start of the proc sem waitlists address vect for the current process
LDMEM R10 R8       ;21 get the state of the current process (address in R10) into R8
JZROI R8 17 ;22 this process is exited, we jump to $nextproc:
SETRI R6 1         ;23 yes, we found at least one non-exited process
SETRG R12 R8       ;24 save R8 into R12, we need the state once again
SUBRG R8 R8 R3     ;25 prepare the test whether this process is in the ready state
JZROI R8 21 ;26 jump to $startproc: for id R0 and process table address R10, since it is indeed ready
SUBRG R12 R12 R4   ;27 prepare the test whether this process is in semwait
JNZRI R12 11 ;28 jump to $nextproc: since the proc of id R0 is not in semwait
SETRI R13 0        ;29 ok, this proc is in semwait, preparing for semoptest(0): we are first only testing
SETRI R5 1         ;30 the frame width for the subroutine call 
SETRI R16 277 ;31 the address of the start of the $semoptest sub
CLLSB R5 R16       ;32 call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 6 ;33  because it means we still cannot apply the semops this proc was waiting for
SETRI R13 1        ;34 ok, ready to apply them 
SETRI R5 1         ;35 the frame width for the subroutine call
SETRI R16 277 ;36 the address of the start of the $semoptest sub    
CLLSB R5 R16       ;37 call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 236   ;38 this should never ever happen
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
LDMEM R14 R5       ;75 now R5 contains the first address of the proc sem waitlists vect in kernel memory
STMEM R5 R2        ;76 first we store the length, then we're going to go one by one to copy the R2 elements, starting with the first
SETRI R7 1         ;77 constant increment
ADDRG R5 R5 R7     ;78=$semwcopy: advance R5 to the address of the first component of the current element of the proc sem waitlists 
LDPRM R1 R3 R8     ;79 read the first component of the first semop from process memory
STMEM R5 R8        ;80 store the first component of the first semop in kernel memory
ADDRG R3 R3 R7     ;81 advance R3 to the address of the second component of the current semop of the proc sem waitlists in proc memory
ADDRG R5 R5 R7     ;82 advance R5 to the address of the second component of the current semop of the proc sem waitlists in kernel memory
LDPRM R1 R3 R8     ;83 read the second component of the current semop from process memory
STMEM R5 R8        ;84 store the second component of the current semop in kernel memory
ADDRG R3 R3 R7     ;85 advance R3 to the address of the first component of the next semop (if any) of the proc sem waitlists in proc memory
SUBRG R2 R2 R7     ;86 decrement the loop counter
JNZRI R2 -10 ;87 loop back to continue copying until done
SETRI R15 100      ;88 done, so now preparing the start address of the semaphore vector (where we keep the semaphore state values)  
SETRI R13 0        ;89 preparing for semoptest(0): we are first only testing
SETRI R5 1         ;90 the frame width for the subroutine call 
SETRI R16 277 ;91 the address of the start of the $semoptest sub
CLLSB R5 R16       ;92 call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 -93    ;93 because it means we cannot apply the semops, so we need to elect another process , the current one will remain in SemWait for now
SETRI R13 1        ;94 ok, ready to apply them 
SETRI R5 1         ;95 the frame width for the subroutine call 
SETRI R16 277 ;96 the address of the start of the $semoptest sub
CLLSB R5 R16       ;97 call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 176   ;98 this should never ever happen
SETRI R6 2         ;99 the Running state, for the ready process which we just found
STMEM R0 R6        ;100 change the process state back to running (address in R0)
SETRI R6 20        ;101 offset to get the process id from the process slot address
SUBRG R0 R0 R6     ;102 get the process id in R0
SETRI R1 0         ;103 address where the current proc id is stored
STMEM R1 R0        ;104 store the (newly become) current proc id
LDPSW R0           ;105 go on to execute proc of id R0  , @@end of interrupt #4@@
SETRI R0 0         ;106=$int5: consoleOut request for current process  , the address where its pid is stored
LDMEM R0 R1        ;107 R1 now has the pid of the process which is requesting the consoleOut operation
SETRI R6 20        ;108 offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;109 R0 now contains the process slot address
SETRI R5 1         ;110 the readyToRun state
JZROI R2 -111     ;111 no item to write, go back to the scheduler
STMEM R0 R5        ;112 store the readyToRun state for the current process
SETRI R7 301       ;113 The address in kernel memory where we need to write the # of items for the consoleOut
STMEM R7 R2        ;114 store the number of items to write at addr 301
SETRI R8 304       ;115 The address in kernel memory where we decided to write the items (copying them from the process memory)
SETRI R7 302       ;116 The address in kernel memory where we need to write the start address (param) where to read the items for the consoleOut
STMEM R7 R8        ;117 now effectively preparing the start address "parameter" for consoleOut (i.e. write the number '304' at address 302)
SETRI R9 404       ;118 The address in kernel memory where we decided to write the item types (copying them from the process memory)
SETRI R7 303       ;119 The address in kernel memory where we need to write the start address (param) where to read the item types for the consoleOut
STMEM R7 R9        ;120 now effectively preparing the type vect start address "parameter" for consoleOut (i.e. write the number '404' at address 303)
SETRI R10 0        ;121 counter: number of items already written, initial value is 0
ADDRG R12 R3 R10   ;122=$write_item: R12 now contains the address of the item to be obtained (read), start addr + counter offset
LDPRM R1 R12 R6    ;123 R6 now contains the first item to be obtained (read) and thus sent to consoleOut (recall R3 is given to us by the proc)
ADDRG R13 R8 R10   ;124 R13 now contains the address to write the item we just read (R6), start addr + counter offset
STMEM R13 R6       ;125 now writing the item (from R6) which we just read from the process memory a few lines above, at address 304 + counter in kernel mem
ADDRG R12 R4 R10   ;126 R12 now contains the address of the type of the item to be obtained (read), start addr + counter offset
LDPRM R1 R12 R7    ;127 R7 now contains the type of the item to be obtained (read) and thus sent to consoleOut
ADDRG R13 R9 R10   ;128 R13 now contains the address to write the type of the item we just read (R6), start addr + counter offset
STMEM R13 R7       ;129 now writing the item type (from R7) which we just read from the process memory a few lines above, at address 404 + counter in kernel mem
ADDRG R10 R10 R5   ;130 increment the counter, because we juste wrote an item in the kernel mem (at start addr of the vect to be read to output the items)
SUBRG R11 R2 R10   ;131 prepare R11 : number of items left to write
JNZRI R11 -11 ;132 still some items to write, jump to $write_item to write the others
SETRI R7 300       ;133 ok, no more items to write, store the address in kernel memory where, by writing a value of 1, we trigger the consoleOut
STMEM R7 R5        ;134 there we go -- we just requested a "hardware consoleOut" through "memory-mapping IO"
JMBSI 1        ;135 absolute jump to $int1: to keep going  , @@end of interrupt #5@@
SETRI R0 0         ;136=$int6: consoleIn request for current process  , the address where its pid is stored
LDMEM R0 R1        ;137 R1 now has the pid of the process which is requesting the consoleIn operation
SETRI R6 20        ;138 offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;139 R0 now contains the process slot address
SETRI R5 1         ;140 the readyToRun state
STMEM R0 R5        ;141 store the readyToRun state for the current process
JZROI R2 -142     ;142 no item to read, go back to the scheduler
SETRI R7 301       ;143 The address in kernel memory where we need to write the # of items for the consoleIn
STMEM R7 R2        ;144 store the number of items to write at addr 301
SETRI R8 304       ;145 The address in kernel memory where we decided to write the items (copying them from the consoleInputStream)
SETRI R7 302       ;146 The address in kernel memory where we need to write the start address (param) where to write the items we read from the consoleIn
STMEM R7 R8        ;147 now effectively preparing the start address "parameter" for consoleIn (i.e. write the number '304' at address 302)
SETRI R9 404       ;148 The address in kernel memory where we decided to write the item types (copying them from the process memory)
SETRI R7 303       ;149 The address in kernel memory where we need to write the start address (param) where to read the item types for the consoleIn
STMEM R7 R9        ;150 now effectively preparing the type vect start address "parameter" for consoleIn (i.e. write the number '404' at address 303)
SETRI R10 0        ;151 counter : number of types already written, initial value is 0
ADDRG R12 R4 R10   ;152=$write_type: R12 now contains the address of the item type to be obtained (read), start addr + counter offset
LDPRM R1 R12 R6    ;153 R6 now contains the first item type to be obtained (read)
ADDRG R13 R9 R10   ;154 R13 now contains the address to write the item type we just read (R6), start addr + counter offset
STMEM R13 R6       ;155 now writing the item type (from R6) which we just read from the process memory a few lines above, at addr 404 + counter in kernel mem
ADDRG R10 R10 R5   ;156 increment the counter, because we juste wrote an item type in the kernel mem
SUBRG R11 R10 R2   ;157 prepare R11 : number of item types left to write
JNZRI R11 -7 ;158 still some item types to write, jump to write_type to write the others
SETRI R0 0         ;159 ok, all the params have been prepared (# of items to read ; addr where to write the items ; addr where to read the types ; types of each item)
SETRI R7 300       ;160 store the address in kernel memory where, by writing a value of 0, we trigger the consoleIn
STMEM R7 R0        ;161 we request a "hardware consoleIn" through "memory-mapping IO", then we'll copy items from kernel mem to proc mem
SETRI R10 0        ;162 now the the vect of the read items (from consoleIn) is at addr contained in R9 , init counter: number of items already written
ADDRG R12 R8 R10   ;163=$write_item_to_proc: R12 now contains the adress (in kernel mem) of the item to be wrote on the proc mem, start addr + counter offset
LDMEM R12 R6       ;164 R6 now contains the first item to be wrote in the proc mem
ADDRG R13 R3 R10   ;165 R13 now contains the address where to write the item we just read (R6), start addr + counter offset
STPRM R1 R13 R6    ;166 now writing the item (from R6) which we just read from the kernel memory, in the proc memory
ADDRG R10 R10 R5   ;167 increment the counter, because we juste wrote an item in the proc mem
SUBRG R11 R2 R10   ;168 prepare R11 : number of items left to write
JNZRI R11 -7 ;169 still some items to write, jump to $write_item_to_proc to write the others
JMBSI 1        ;170 absolute jump to $int1: to keep going  , @@end of interrupt #6@@
SETRI R0 0         ;171=$int7: randomGenerate request for current process  , the address where its pid is stored
LDMEM R0 R1        ;172 R1 now has the pid of the process which is requesting the consoleIn operation
SETRI R6 20        ;173 offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;174 R0 now contains the process slot address
SETRI R7 1         ;175 the readyToRun state, also used as constant increment
STMEM R0 R7        ;176 store the readyToRun state for the current process
JZROI R2 -177     ;177 no item to generate, jump to $int1: to keep going
SETRI R8 501       ;178 address where to write the # of items to generate
STMEM R8 R2        ;179 store the # of items to generate at addr 500
ADDRG R8 R8 R7     ;180 increment addr, R8 now contains the addr where to write the min value
STMEM R8 R3        ;181 store the min value at addr 502
ADDRG R8 R8 R7     ;182 increment addr, R8 now contains the addr where to write the max value
STMEM R8 R4        ;183 store the max value at addr 503
SETRI R9 505       ;184 start address where to write the random-generated items (in kernel mem)
ADDRG R8 R8 R7     ;185 increment addr, R8 now contains the addr of the start addr where to write the random-generated items
STMEM R8 R9        ;186 store the start addr where to write the items (i.e write 505 at addr 504)
SETRI R8 500       ;187 code to trigger the generation
STMEM R8 R8        ;188 trigger the generation -- second parameter is ignored
SETRI R10 0        ;189 init counter: number of items already written
ADDRG R11 R9 R10   ;190=$write_random: R11 now contains the address (in kernel mem) of the item to be wrote on the proc mem, start addr + counter offset
LDMEM R11 R6       ;191 R6 now contains the first item to be wrote in the proc mem
ADDRG R12 R5 R10   ;192 R12 now contains the address where to write the item we just read (R6), start addr + counter offset
STPRM R1 R12 R6    ;193 now writing the item (from R6) which we just read from the kernel memory, in the proc memory
ADDRG R10 R10 R7   ;194 increment the counter, because we juste wrote an item in the proc mem
SUBRG R13 R2 R10   ;195 prepare R13 : number of items left to write
JNZRI R13 -7 ;196 still some items to write, jump to $write_random to write the others
JMBSI 1        ;197 absolute jump to $int1: to keep going  , @@end of interrupt #7@@
SETRI R0 1         ;198=$prep: initial kernel setup, R0 constant increment/decrement value
SETRI R1 1         ;199 address of first slot in the interrupt vector
SETRI R2 1     ;200 prog address of $int1 start next available process
STMEM R1 R2        ;201 setting up the interrupt vector for interrupt #1
ADDRG R1 R1 R0     ;202 increment the address of slots
SETRI R2 53     ;203 prog address of $int2: exit current process
STMEM R1 R2        ;204 setting up the interrupt vector for interrupt #2
ADDRG R1 R1 R0     ;205 increment the address of slots
SETRI R2 60     ;206 prog address of $int3: scheduler interrupt
STMEM R1 R2        ;207 setting up the interrupt vector for interrupt #3
ADDRG R1 R1 R0     ;208 increment the address of slots
SETRI R2 67     ;209 prog address of $int4: semop Request
STMEM R1 R2        ;210 setting up the interrupt vector for interrupt #4
ADDRG R1 R1 R0     ;211 increment the address of slots
SETRI R2 106     ;212 address of $int5: consoleOut Request
STMEM R1 R2        ;213 setting up the interrupt vector for interrupt #5
ADDRG R1 R1 R0     ;214 increment the address of slots
SETRI R2 136     ;215 address of $int6: consoleIn Request
STMEM R1 R2        ;216 setting up the interrupt vector for interrupt #6
ADDRG R1 R1 R0     ;217 increment the address of slots
SETRI R2 171     ;218 address of $int7: consoleIn Request
STMEM R1 R2        ;219 setting up the interrupt vector for interrupt #7
SETRI R1 21        ;220 address where process table starts
SETRI R2 1         ;221 ReadyToRun initial procstate value
GETI0 R3           ;222 number of processes
SETRG R13 R3       ;223 save the number of process cuz we need it again after $procAndSchedSeqSetup
SETRI R8 20        ;224 address to save the number of processes
STMEM R8 R3        ;225 saving the number of processes
ADDRG R9 R8 R0     ;226 offset for the semwaitlists
SETRI R10 201      ;227 the start of the proc sem waitlists address vect, one for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R7 R10 R8    ;228 the first such address 
SETRI R4 501       ;229 address where to write the # of items to generate
STMEM R4 R3        ;230 store the # of items to generate at addr 501
ADDRG R4 R4 R0     ;231 increment addr, R4 now contains the addr where to write the min value
SETRI R5 0         ;232 the min value
STMEM R4 R5        ;233 store the min value (0) at addr 502
ADDRG R4 R4 R0     ;234 increment addr, R4 now contains the addr where to write the max value
SETRG R5 R3        ;235 the max value is nb_proc cuz we want the offset of the seq to switch with seq[0]
STMEM R4 R5        ;236 store the max value at addr 503
SETRI R6 600       ;237 the start of the scheduler's sequence address vect
ADDRG R6 R6 R3     ;238 R6 now contains the start address where to write the random-generated items (in kernel mem)
ADDRG R4 R4 R0     ;239 increment addr, R4 now contains the addr of the start addr where to write the random-generated items
STMEM R4 R6        ;240 store the start addr where to write the items (i.e write 600 - nb_proc at addr 504)
SETRI R4 500       ;241 code to trigger the generation
STMEM R4 R4        ;242 trigger the generation -- second parameter is ignored
SETRI R4 599       ;243 the start of the scheduler's sequence address vect - 1 (hope there's at least one)
ADDRG R4 R4 R3     ;244 now R4 is the end of the scheduler's sequence address vect, cuz we store the pids backward
STMEM R1 R2        ;245=$procAndSchedSeqSetup: set initial process state value to current slot
ADDRG R1 R1 R0     ;246 advance address for process table slot
STMEM R10 R7       ;247 setting the start address for the current proc sem waitlists in the master proc sem waitlists address vect
ADDRG R7 R7 R9     ;248 increment the start address with the right offset
ADDRG R10 R10 R0   ;249 advance address in the master proc sem waitlists address vect
STMEM R4 R3        ;250 store the current <maxpid - pid> in the sequence
SUBRG R4 R4 R0     ;251 decrement the addr where to store the current pid, so it is filled backward
SUBRG R3 R3 R0     ;252 decrement loop counter
JNZRI R3 -9 ;253 jump back to $procSetup: for max number processes
ADDRG R4 R4 R0     ;254 R4 is now 600, the start addr of the seq
SETRG R6 R4        ;255 store the addr of the first item in the seq (the one to be swapped w/ a random item in the seq)
ADDRG R4 R4 R13    ;256 R4 is now the start addr of the random-generated list
SETRI R2 0         ;257 also count of swapped items
LDMEM R4 R7        ;258=$swapRandom: get the random number, it's the offset in the pid seq to swap with the first item of the seq
ADDRG R9 R6 R7     ;259 store the addr of the item to swap
LDMEM R9 R10       ;260 get the item to be swapped in R10
LDMEM R6 R11       ;261 get the first item of the seq in R11
SETRG R12 R10      ;262 tmp item, contains R10
SETRG R10 R11      ;263 put R11 in R10
SETRG R11 R12      ;264 put R12 (R10) in R11
STMEM R6 R11       ;265 now store the first item of the seq in random pos
STMEM R9 R10       ;266 and store the item get at random pos in first pos
ADDRG R4 R4 R0     ;267 increment the addr in the random-generated list
ADDRG R2 R2 R0     ;268 increment the counter
SUBRG R1 R13 R2    ;269 prepare R1 to tell us if we are done
JNZRI R1 -13 ;270 jump to $swapRandom if we still have some items to swap
SETRI R0 0         ;271 address where current scheduled proc id is stored
SETRI R1 0         ;272 pid 0
STMEM R0 R1        ;273 just to initialize the state of the system for int1 
JMBSI 1        ;274 absolute jump to $int1: to start the work    , @@end of initial kernel setup@@
SDOWN              ;275=$crash: 
SETRI R20 0        ;276 the V() semop value (and V state value)
SETRI R16 1        ;277=$semoptest: can we indeed P() each sem we were waiting for ? (the V()'s will go through anyway)
LDMEM R14 R22      ;278 R22 now contains the address where the current proc semwaitlist really starts
LDMEM R22 R17      ;279 R17 contains the number of semops requested by the current proc (whatever that proc is)
ADDRG R22 R22 R16  ;280=$procsemtop: R22 contains the address of the current semaphore index
LDMEM R22 R18      ;281 R18 contains the current semaphore index
ADDRG R18 R18 R15  ;282 R18 now contains the address of the current semaphore
LDMEM R18 R19      ;283 R19 contains the state value of the current semaphore
SUBRG R19 R19 R16  ;284 prepare the test whether the current semaphore is in the P state (then R19 is going to be zero)
ADDRG R22 R22 R16  ;285 R22 now contains the address of the current semop 
LDMEM R22 R21      ;286 R21 now contains the semop code for the current semaphore
SUBRG R21 R21 R16  ;287 prepare the test whether the current semop code is P() (then R21 is going to be zero)
JNZRI R19 4 ;288 jump to $maybeDoPorVonSemV: if the current semaphore is in the V state
JNZRI R21 9 ;289 ok, the current semaphore is in P , now, jump to $maybeDoVonSemP: if the current semop code is V()
SETRI R16 0        ;290 actually the current semop is P(), (and the current semaphore is in P) so we cannot do anything , we return with 0 in R16 
SETRI R17 1        ;291 the stack frame width -- we know its only 1
RETSB R17          ;292 for any RETSB we need the R17=1 for the stack frame width
JZROI R13 2 ;293=$maybeDoPorVonSemV: jump to $nextsem if we only need to examine and not also do it
JNZRI R21 1 ;294 jump to $nextsem: if the current semop code is V(), because V() on a semaphore in state V is a no-op
STMEM R18 R16      ;295 ok, do P() on the semaphore (which was in state V) -- R18 had the address of the current semaphore 
SUBRG R17 R17 R16  ;296=$nextsem: decrement semaphore loop counter
JNZRI R17 -18 ;297 jump to $procsemtop: if we have more semaphores to examine and perphaps operate upon
RETSB R16          ;298 we are all done, we return with 1 in R16 (and use the fact that the stack frame width is also 1)
JZROI R13 -4 ;299=$maybeDoVonSemP: actually jump to $nextsem if we only need to examine and not also do it
STMEM R18 R27      ;300 ok, do V() on the semaphore (which was in state P) -- R18 had the address of the current semaphore 
JMTOI -6     ;301 jump to $nextsem:
