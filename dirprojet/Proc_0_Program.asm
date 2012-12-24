JMBSI 248        ;0  absolute jump to $prep: to prepare the memory structure (intvec, proc/file tables)
SETRI R1 0         ;1=$int1: address where the current proc id is stored
LDMEM R1 R0        ;2 get the last scheduled process id, to start from right after it (round robin)
SETRI R2 1         ;3 the increment for process table slots
SETRI R11 20       ;4 the address where the number of processes is stored
LDMEM R11 R1       ;5 R1 now contains the number of processes
SETRG R9 R1        ;6 save R1 into R9, so R9 now also contains the number of processes -- constant
ADDRG R9 R9 R2     ;7 actually make R9 one larger because proc id are from 1 to R1
SETRI R17 49       ;8 start addr-1 of the random sequence of pids
ADDRG R17 R17 R1   ;9 addr of the end of the random sequence of pids
STMEM R17 R0       ;10 store the last scheduled pid at the end of the random sequence of pids
SETRI R17 50       ;11 start addr of the random sequence of pids
SETRI R18 1        ;12 first pid to write at the start of the sequence of pids to be randomized
SUBRG R20 R18 R9   ;13=$writePidInSeqLoop: prepare R20 to tell us if we are done writing the pids in the sequence
JZROI R20 8 ;14 jump to $endPidInSeqLoop if we are done
SUBRG R19 R18 R0   ;15 prepare R19 to tell us if we are about to write the last scheduled pid
JNZRI R19 2 ;16 jump to $writePidInSeq if it's false
ADDRG R18 R18 R2   ;17 increment current pid to write in the sequence
JMBSI 13 ;18 loop to $writePidInSeqLoop after inrement R17
STMEM R17 R18      ;19=$writePidInSeq: actually write the pid in the seq
ADDRG R17 R17 R2   ;20 increment current addr of the sequence
ADDRG R18 R18 R2   ;21 increment current pid to write in the sequence
JMBSI 13 ;22 loop to write the other pids in the seq
JZROI R0 31 ;23=$endPidInSeqLoop: don't randomize the previously written sequence if it's the kernel has just started
SETRI R21 501      ;24 address where to write the # of items to generate
SETRG R22 R1       ;25 save R1 into R21 : we'll generate max_proc -1 random items to randomize the sequence
SUBRG R22 R22 R2   ;26 because it's max_proc -1 and not max_proc
STMEM R21 R22      ;27 store the # of items to generate at addr 501
ADDRG R21 R21 R2   ;28 increment addr, R21 now contains the addr where to write the min value
SETRI R23 0        ;29 the min value
STMEM R21 R23      ;30 store the min value (0) at addr 502
ADDRG R21 R21 R2   ;31 increment addr, R21 now contains the addr where to write the max value
SETRG R23 R22      ;32 the max value is be max_proc-1 cuz we want the offset of the seq to switch with seq[0] to seq[max_proc-1]
STMEM R21 R23      ;33 store the max value at addr 503
ADDRG R21 R21 R2   ;34 increment addr, R21 now contains the addr where to write the addr where to write the random-generated items
ADDRG R17 R17 R2   ;35 R17 now contains the start addr where to write the items
STMEM R21 R17      ;36 store the start addr where to write the items (R17 contains 50 + max_proc)
SETRI R21 500      ;37 code to trigger the generation
STMEM R21 R21      ;38 trigger the generation -- second parameter is ignored
SETRI R21 50       ;39 the start addr of the seq, constant
SETRG R24 R21      ;40 store the addr of the first item in the seq (the one to be swapped w/ a random item in the seq)
SETRI R25 0        ;41 count of swapped items
SETRG R31 R22      ;42 save R22 (max_proc - 1), it's the number of items to write
LDMEM R17 R27      ;43=$swapRandom: get the random number, it's the offset in the pid seq to swap with the first item of the seq
ADDRG R22 R21 R27  ;44 store the addr of the item to swap
LDMEM R22 R28      ;45 get the item to be swapped in R28
LDMEM R21 R29      ;46 get the first item of the seq in R29
SETRG R30 R28      ;47 tmp item, contains R28
SETRG R28 R29      ;48 put R29 in R28
SETRG R29 R30      ;49 put R30 (R28) in R29
STMEM R22 R28      ;50 now store the first item of the seq in random pos
STMEM R21 R29      ;51 and store the item get at random pos in first pos
ADDRG R17 R17 R2   ;52 increment the addr in the random-generated list
ADDRG R25 R25 R2   ;53 increment the counter
SUBRG R26 R25 R31  ;54 prepare R1 to tell us if we are done (counter - max_proc-1 == 0)
JNZRI R26 -13 ;55=$endSwapRdmLoop: jump to $swapRandom if we still have some items to swap
SETRI R3 1         ;56 the ReadyToRun process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R4 3         ;57 the SemWait process state value (proc states: 0(exit), 1(ready), 2(running), 3(semwait), 4(netwait)...)
SETRI R15 100      ;58 the start address of the semaphore vector (where we keep the semaphore state values)
SETRI R6 0         ;59 for now 'no', we did not find any non-exited process yet    
SETRI R32 50       ;60 start addr of the seq, to add to R9 for the wrap around
ADDRG R9 R9 R32    ;61 R9 now contains the last addr of the seq +1
SETRG R7 R32       ;62=$top: copy R32 for the test for the wrap around
SUBRG R7 R7 R9     ;63 prepare the test for R32 wrap around
JNZRI R7 1  ;64 if R7 (that is R32) is not equal to R9 (the number of processes) we can continue
SETRI R32 50       ;65 otherwise, we need to set R10 to 50 to wrap around
LDMEM R32 R0       ;66=$nextPid: R0 is now a random process, the one we want to elect
SETRG R10 R11      ;67 prepare the offset for the process table start address
ADDRG R10 R10 R0   ;68 now R10 contains the address of the current process slot in the process table
SETRI R14 200      ;69 the start of the proc sem waitlists address vect, one list for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R14 R14 R0   ;70 the address of the start of the proc sem waitlists address vect for the current process
LDMEM R10 R8       ;71 get the state of the current process (address in R10) into R8
JZROI R8 17 ;72 this process is exited, we jump to $nextproc:
SETRI R6 1         ;73 yes, we found at least one non-exited process
SETRG R12 R8       ;74 save R8 into R12, we need the state once again
SUBRG R8 R8 R3     ;75 prepare the test whether this process is in the ready state
JZROI R8 21 ;76 jump to $startproc: for id R0 and process table address R10, since it is indeed ready
SUBRG R12 R12 R4   ;77 prepare the test whether this process is in semwait
JNZRI R12 11 ;78 jump to $nextproc: since the proc of id R0 is not in semwait
SETRI R13 0        ;79 ok, this proc is in semwait, preparing for semoptest(0): we are first only testing
SETRI R5 1         ;80 the frame width for the subroutine call 
SETRI R16 291 ;81 the address of the start of the $semoptest sub
CLLSB R5 R16       ;82 call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 6 ;83  because it means we still cannot apply the semops this proc was waiting for
SETRI R13 1        ;84 ok, ready to apply them 
SETRI R5 1         ;85 the frame width for the subroutine call
SETRI R16 291 ;86 the address of the start of the $semoptest sub    
CLLSB R5 R16       ;87 call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 200   ;88 this should never ever happen
JMTOI 8   ;89 jump to $startproc: we are now done with all the semaphore operations, and can complete the election of process of pid R0
ADDRG R32 R32 R2   ;90=$nextproc: increment the address in the pid-seq for the next process to study 
SUBRG R1 R1 R2     ;91 decrement loop counter
JNZRI R1  -31     ;92 jump to $top: loop for max number processes
JNZRI R6 2     ;93 no ready proc but at least one not exited, so we go to $wait: 
SDOWN              ;94 all processes have exited, we're done, system going down
INTRP              ;95 we allow interrupts (which were disabled by the call to this interrupt)
NOPER              ;96=$wait: a bit for some interrupt (e.g. net I/O complete), which then jumps right there
JMBSI 96        ;97 and we loop back to $wait: in order to wait some more
SETRI R3 2         ;98=$startproc: the Running state, for the ready process which we just found
STMEM R10 R3       ;99 change the process state to running (address in R0)
SETRI R1 0         ;100 address where the current proc id is stored
STMEM R1 R0        ;101 store the (newly become) current proc id
LDPSW R0           ;102 go on to execute proc of id R0    , @@end of interrupt #1@@
SETRI R0 0         ;103=$int2: exit current process    , the address where its pid is stored
LDMEM R0 R1        ;104 R1 now has the pid of the process which is now exiting
SETRI R2 20        ;105 offset to get the process slot address from the process id
ADDRG R0 R1 R2     ;106 R0 now contains the process slot address
SETRI R3 0         ;107 the exited process state value
STMEM R0 R3        ;108 set the state of the process to exit
JMBSI 1        ;109 absolute jump to $int1: to keep going    , @@end of interrupt #2@@
SETRI R0 0         ;110=$int3: scheduler interrupt, the current process , the address where its pid is stored
LDMEM R0 R1        ;111 R1 now has the pid of the process which was just interrupted
SETRI R2 20        ;112 offset to get the process slot address from the process id
ADDRG R0 R1 R2     ;113 R0 now contains the process slot address
SETRI R3 1         ;114 the interrupted process new state value of readyToRun
STMEM R0 R3        ;115 set the state of the process to readyToRun
JMBSI 1        ;116 absolute jump to $int1: to keep going    , @@end of interrupt #3@@
SETRI R0 0         ;117=$int4: semop request for current process  , the address where its pid is stored
LDMEM R0 R1        ;118 R1 now has the pid of the process which is requesting a semop
SETRI R4 20        ;119 offset to get the process slot address from the process id
ADDRG R0 R1 R4     ;120 R0 now contains the process slot address
SETRI R6 3         ;121 the SemWait state value
STMEM R0 R6        ;122 change the process state to SemWait (address in R0)
SETRI R14 200      ;123 the start of the proc sem waitlists address vect, one for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R14 R14 R1   ;124 the start of the current proc sem waitlist address vect
LDMEM R14 R5       ;125 now R5 contains the first address of the proc sem waitlists vect in kernel memory
STMEM R5 R2        ;126 first we store the length, then we're going to go one by one to copy the R2 elements, starting with the first
SETRI R7 1         ;127 constant increment
ADDRG R5 R5 R7     ;128=$semwcopy: advance R5 to the address of the first component of the current element of the proc sem waitlists 
LDPRM R1 R3 R8     ;129 read the first component of the first semop from process memory
STMEM R5 R8        ;130 store the first component of the first semop in kernel memory
ADDRG R3 R3 R7     ;131 advance R3 to the address of the second component of the current semop of the proc sem waitlists in proc memory
ADDRG R5 R5 R7     ;132 advance R5 to the address of the second component of the current semop of the proc sem waitlists in kernel memory
LDPRM R1 R3 R8     ;133 read the second component of the current semop from process memory
STMEM R5 R8        ;134 store the second component of the current semop in kernel memory
ADDRG R3 R3 R7     ;135 advance R3 to the address of the first component of the next semop (if any) of the proc sem waitlists in proc memory
SUBRG R2 R2 R7     ;136 decrement the loop counter
JNZRI R2 -10 ;137 loop back to continue copying until done
SETRI R15 100      ;138 done, so now preparing the start address of the semaphore vector (where we keep the semaphore state values)  
SETRI R13 0        ;139 preparing for semoptest(0): we are first only testing
SETRI R5 1         ;140 the frame width for the subroutine call 
SETRI R16 291 ;141 the address of the start of the $semoptest sub
CLLSB R5 R16       ;142 call to $semoptest(R13=0, R14=current proc semlist address, R15=semvect addr)
JZROI R16 -143    ;143 because it means we cannot apply the semops, so we need to elect another process , the current one will remain in SemWait for now
SETRI R13 1        ;144 ok, ready to apply them 
SETRI R5 1         ;145 the frame width for the subroutine call 
SETRI R16 291 ;146 the address of the start of the $semoptest sub
CLLSB R5 R16       ;147 call to $semoptest(R13=1, R14=current proc semlist address, R15=semvect addr)
JZROI R16 140   ;148 this should never ever happen
SETRI R6 2         ;149 the Running state, for the ready process which we just found
STMEM R0 R6        ;150 change the process state back to running (address in R0)
SETRI R6 20        ;151 offset to get the process id from the process slot address
SUBRG R0 R0 R6     ;152 get the process id in R0
SETRI R1 0         ;153 address where the current proc id is stored
STMEM R1 R0        ;154 store the (newly become) current proc id
LDPSW R0           ;155 go on to execute proc of id R0  , @@end of interrupt #4@@
SETRI R0 0         ;156=$int5: consoleOut request for current process  , the address where its pid is stored
LDMEM R0 R1        ;157 R1 now has the pid of the process which is requesting the consoleOut operation
SETRI R6 20        ;158 offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;159 R0 now contains the process slot address
SETRI R5 1         ;160 the readyToRun state
JZROI R2 -161     ;161 no item to write, go back to the scheduler
STMEM R0 R5        ;162 store the readyToRun state for the current process
SETRI R7 301       ;163 The address in kernel memory where we need to write the # of items for the consoleOut
STMEM R7 R2        ;164 store the number of items to write at addr 301
SETRI R8 304       ;165 The address in kernel memory where we decided to write the items (copying them from the process memory)
SETRI R7 302       ;166 The address in kernel memory where we need to write the start address (param) where to read the items for the consoleOut
STMEM R7 R8        ;167 now effectively preparing the start address "parameter" for consoleOut (i.e. write the number '304' at address 302)
SETRI R9 404       ;168 The address in kernel memory where we decided to write the item types (copying them from the process memory)
SETRI R7 303       ;169 The address in kernel memory where we need to write the start address (param) where to read the item types for the consoleOut
STMEM R7 R9        ;170 now effectively preparing the type vect start address "parameter" for consoleOut (i.e. write the number '404' at address 303)
SETRI R10 0        ;171 counter: number of items already written, initial value is 0
ADDRG R12 R3 R10   ;172=$write_item: R12 now contains the address of the item to be obtained (read), start addr + counter offset
LDPRM R1 R12 R6    ;173 R6 now contains the first item to be obtained (read) and thus sent to consoleOut (recall R3 is given to us by the proc)
ADDRG R13 R8 R10   ;174 R13 now contains the address to write the item we just read (R6), start addr + counter offset
STMEM R13 R6       ;175 now writing the item (from R6) which we just read from the process memory a few lines above, at address 304 + counter in kernel mem
ADDRG R12 R4 R10   ;176 R12 now contains the address of the type of the item to be obtained (read), start addr + counter offset
LDPRM R1 R12 R7    ;177 R7 now contains the type of the item to be obtained (read) and thus sent to consoleOut
ADDRG R13 R9 R10   ;178 R13 now contains the address to write the type of the item we just read (R6), start addr + counter offset
STMEM R13 R7       ;179 now writing the item type (from R7) which we just read from the process memory a few lines above, at address 404 + counter in kernel mem
ADDRG R10 R10 R5   ;180 increment the counter, because we juste wrote an item in the kernel mem (at start addr of the vect to be read to output the items)
SUBRG R11 R2 R10   ;181 prepare R11 : number of items left to write
JNZRI R11 -11 ;182 still some items to write, jump to $write_item to write the others
SETRI R7 300       ;183 ok, no more items to write, store the address in kernel memory where, by writing a value of 1, we trigger the consoleOut
STMEM R7 R5        ;184 there we go -- we just requested a "hardware consoleOut" through "memory-mapping IO"
JMBSI 1        ;185 absolute jump to $int1: to keep going  , @@end of interrupt #5@@
SETRI R0 0         ;186=$int6: consoleIn request for current process  , the address where its pid is stored
LDMEM R0 R1        ;187 R1 now has the pid of the process which is requesting the consoleIn operation
SETRI R6 20        ;188 offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;189 R0 now contains the process slot address
SETRI R5 1         ;190 the readyToRun state
STMEM R0 R5        ;191 store the readyToRun state for the current process
JZROI R2 -192     ;192 no item to read, go back to the scheduler
SETRI R7 301       ;193 The address in kernel memory where we need to write the # of items for the consoleIn
STMEM R7 R2        ;194 store the number of items to write at addr 301
SETRI R8 304       ;195 The address in kernel memory where we decided to write the items (copying them from the consoleInputStream)
SETRI R7 302       ;196 The address in kernel memory where we need to write the start address (param) where to write the items we read from the consoleIn
STMEM R7 R8        ;197 now effectively preparing the start address "parameter" for consoleIn (i.e. write the number '304' at address 302)
SETRI R9 404       ;198 The address in kernel memory where we decided to write the item types (copying them from the process memory)
SETRI R7 303       ;199 The address in kernel memory where we need to write the start address (param) where to read the item types for the consoleIn
STMEM R7 R9        ;200 now effectively preparing the type vect start address "parameter" for consoleIn (i.e. write the number '404' at address 303)
SETRI R10 0        ;201 counter : number of types already written, initial value is 0
ADDRG R12 R4 R10   ;202=$write_type: R12 now contains the address of the item type to be obtained (read), start addr + counter offset
LDPRM R1 R12 R6    ;203 R6 now contains the first item type to be obtained (read)
ADDRG R13 R9 R10   ;204 R13 now contains the address to write the item type we just read (R6), start addr + counter offset
STMEM R13 R6       ;205 now writing the item type (from R6) which we just read from the process memory a few lines above, at addr 404 + counter in kernel mem
ADDRG R10 R10 R5   ;206 increment the counter, because we juste wrote an item type in the kernel mem
SUBRG R11 R10 R2   ;207 prepare R11 : number of item types left to write
JNZRI R11 -7 ;208 still some item types to write, jump to write_type to write the others
SETRI R0 0         ;209 ok, all the params have been prepared (# of items to read ; addr where to write the items ; addr where to read the types ; types of each item)
SETRI R7 300       ;210 store the address in kernel memory where, by writing a value of 0, we trigger the consoleIn
STMEM R7 R0        ;211 we request a "hardware consoleIn" through "memory-mapping IO", then we'll copy items from kernel mem to proc mem
SETRI R10 0        ;212 now the the vect of the read items (from consoleIn) is at addr contained in R9 , init counter: number of items already written
ADDRG R12 R8 R10   ;213=$write_item_to_proc: R12 now contains the adress (in kernel mem) of the item to be wrote on the proc mem, start addr + counter offset
LDMEM R12 R6       ;214 R6 now contains the first item to be wrote in the proc mem
ADDRG R13 R3 R10   ;215 R13 now contains the address where to write the item we just read (R6), start addr + counter offset
STPRM R1 R13 R6    ;216 now writing the item (from R6) which we just read from the kernel memory, in the proc memory
ADDRG R10 R10 R5   ;217 increment the counter, because we juste wrote an item in the proc mem
SUBRG R11 R2 R10   ;218 prepare R11 : number of items left to write
JNZRI R11 -7 ;219 still some items to write, jump to $write_item_to_proc to write the others
JMBSI 1        ;220 absolute jump to $int1: to keep going  , @@end of interrupt #6@@
SETRI R0 0         ;221=$int7: randomGenerate request for current process  , the address where its pid is stored
LDMEM R0 R1        ;222 R1 now has the pid of the process which is requesting the consoleIn operation
SETRI R6 20        ;223 offset to get the process slot address from the process id
ADDRG R0 R1 R6     ;224 R0 now contains the process slot address
SETRI R7 1         ;225 the readyToRun state, also used as constant increment
STMEM R0 R7        ;226 store the readyToRun state for the current process
JZROI R2 -227     ;227 no item to generate, jump to $int1: to keep going
SETRI R8 501       ;228 address where to write the # of items to generate
STMEM R8 R2        ;229 store the # of items to generate at addr 500
ADDRG R8 R8 R7     ;230 increment addr, R8 now contains the addr where to write the min value
STMEM R8 R3        ;231 store the min value at addr 502
ADDRG R8 R8 R7     ;232 increment addr, R8 now contains the addr where to write the max value
STMEM R8 R4        ;233 store the max value at addr 503
SETRI R9 505       ;234 start address where to write the random-generated items (in kernel mem)
ADDRG R8 R8 R7     ;235 increment addr, R8 now contains the addr of the start addr where to write the random-generated items
STMEM R8 R9        ;236 store the start addr where to write the items (i.e write 505 at addr 504)
SETRI R8 500       ;237 code to trigger the generation
STMEM R8 R8        ;238 trigger the generation -- second parameter is ignored
SETRI R10 0        ;239 init counter: number of items already written
ADDRG R11 R9 R10   ;240=$write_random: R11 now contains the address (in kernel mem) of the item to be wrote on the proc mem, start addr + counter offset
LDMEM R11 R6       ;241 R6 now contains the first item to be wrote in the proc mem
ADDRG R12 R5 R10   ;242 R12 now contains the address where to write the item we just read (R6), start addr + counter offset
STPRM R1 R12 R6    ;243 now writing the item (from R6) which we just read from the kernel memory, in the proc memory
ADDRG R10 R10 R7   ;244 increment the counter, because we juste wrote an item in the proc mem
SUBRG R13 R2 R10   ;245 prepare R13 : number of items left to write
JNZRI R13 -7 ;246 still some items to write, jump to $write_random to write the others
JMBSI 1        ;247 absolute jump to $int1: to keep going  , @@end of interrupt #7@@
SETRI R0 1         ;248=$prep: initial kernel setup, R0 constant increment/decrement value
SETRI R1 1         ;249 address of first slot in the interrupt vector
SETRI R2 1     ;250 prog address of $int1 start next available process
STMEM R1 R2        ;251 setting up the interrupt vector for interrupt #1
ADDRG R1 R1 R0     ;252 increment the address of slots
SETRI R2 103     ;253 prog address of $int2: exit current process
STMEM R1 R2        ;254 setting up the interrupt vector for interrupt #2
ADDRG R1 R1 R0     ;255 increment the address of slots
SETRI R2 110     ;256 prog address of $int3: scheduler interrupt
STMEM R1 R2        ;257 setting up the interrupt vector for interrupt #3
ADDRG R1 R1 R0     ;258 increment the address of slots
SETRI R2 117     ;259 prog address of $int4: semop Request
STMEM R1 R2        ;260 setting up the interrupt vector for interrupt #4
ADDRG R1 R1 R0     ;261 increment the address of slots
SETRI R2 156     ;262 address of $int5: consoleOut Request
STMEM R1 R2        ;263 setting up the interrupt vector for interrupt #5
ADDRG R1 R1 R0     ;264 increment the address of slots
SETRI R2 186     ;265 address of $int6: consoleIn Request
STMEM R1 R2        ;266 setting up the interrupt vector for interrupt #6
ADDRG R1 R1 R0     ;267 increment the address of slots
SETRI R2 221     ;268 address of $int7: consoleIn Request
STMEM R1 R2        ;269 setting up the interrupt vector for interrupt #7
SETRI R1 21        ;270 address where process table starts
SETRI R2 1         ;271 ReadyToRun initial procstate value
GETI0 R3           ;272 number of processes
SETRI R8 20        ;273 address to save the number of processes
STMEM R8 R3        ;274 saving the number of processes
ADDRG R9 R8 R0     ;275 offset for the semwaitlists
SETRI R10 201      ;276 the start of the proc sem waitlists address vect, one for each proc, (count,(semId,semOp),(semId,semOp),...)
ADDRG R7 R10 R8    ;277 the first such address 
STMEM R1 R2        ;278=$procSetup: set initial process state value to current slot
ADDRG R1 R1 R0     ;279 advance address for process table slot
STMEM R10 R7       ;280 setting the start address for the current proc sem waitlists in the master proc sem waitlists address vect
ADDRG R7 R7 R9     ;281 increment the start address with the right offset
ADDRG R10 R10 R0   ;282 advance address in the master proc sem waitlists address vect
SUBRG R3 R3 R0     ;283 decrement loop counter
JNZRI R3 -7 ;284 jump back to $procSetup: for max number processes
SETRI R0 0         ;285 address where current scheduled proc id is stored
SETRI R1 0         ;286 pid 0
STMEM R0 R1        ;287 just to initialize the state of the system for int1 
JMBSI 1        ;288 absolute jump to $int1: to start the work    , @@end of initial kernel setup@@
SDOWN              ;289=$crash: 
SETRI R20 0        ;290 the V() semop value (and V state value)
SETRI R16 1        ;291=$semoptest: can we indeed P() each sem we were waiting for ? (the V()'s will go through anyway)
LDMEM R14 R22      ;292 R22 now contains the address where the current proc semwaitlist really starts
LDMEM R22 R17      ;293 R17 contains the number of semops requested by the current proc (whatever that proc is)
ADDRG R22 R22 R16  ;294=$procsemtop: R22 contains the address of the current semaphore index
LDMEM R22 R18      ;295 R18 contains the current semaphore index
ADDRG R18 R18 R15  ;296 R18 now contains the address of the current semaphore
LDMEM R18 R19      ;297 R19 contains the state value of the current semaphore
SUBRG R19 R19 R16  ;298 prepare the test whether the current semaphore is in the P state (then R19 is going to be zero)
ADDRG R22 R22 R16  ;299 R22 now contains the address of the current semop 
LDMEM R22 R21      ;300 R21 now contains the semop code for the current semaphore
SUBRG R21 R21 R16  ;301 prepare the test whether the current semop code is P() (then R21 is going to be zero)
JNZRI R19 4 ;302 jump to $maybeDoPorVonSemV: if the current semaphore is in the V state
JNZRI R21 9 ;303 ok, the current semaphore is in P , now, jump to $maybeDoVonSemP: if the current semop code is V()
SETRI R16 0        ;304 actually the current semop is P(), (and the current semaphore is in P) so we cannot do anything , we return with 0 in R16 
SETRI R17 1        ;305 the stack frame width -- we know its only 1
RETSB R17          ;306 for any RETSB we need the R17=1 for the stack frame width
JZROI R13 2 ;307=$maybeDoPorVonSemV: jump to $nextsem if we only need to examine and not also do it
JNZRI R21 1 ;308 jump to $nextsem: if the current semop code is V(), because V() on a semaphore in state V is a no-op
STMEM R18 R16      ;309 ok, do P() on the semaphore (which was in state V) -- R18 had the address of the current semaphore 
SUBRG R17 R17 R16  ;310=$nextsem: decrement semaphore loop counter
JNZRI R17 -18 ;311 jump to $procsemtop: if we have more semaphores to examine and perphaps operate upon
RETSB R16          ;312 we are all done, we return with 1 in R16 (and use the fact that the stack frame width is also 1)
JZROI R13 -4 ;313=$maybeDoVonSemP: actually jump to $nextsem if we only need to examine and not also do it
STMEM R18 R27      ;314 ok, do V() on the semaphore (which was in state P) -- R18 had the address of the current semaphore 
JMTOI -6     ;315 jump to $nextsem:
