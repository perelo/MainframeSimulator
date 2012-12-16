SETRI R0 0        ; kernel pid, and also index of semRead
SETRI R2 1        ; code of P(), also count of semop()s, and also index of semWrite
SETRI R3 225      ; address for the P() semop on semWrite
STMEM R3 R2       ; store the index of the semaphore to operate on (semWrite)
ADDRG R3 R3 R2    ; advance the address
STMEM R3 R2       ; store the P() operation code
SETRI R3 210      ; address for the V() semop on semRead
STMEM R3 R0       ; store the index of the semaphore to operate on (semRead)
ADDRG R3 R3 R2    ; advance the address
STMEM R3 R0       ; store the V() operation code
SETRI R5 11       ; shared memory start address (agreed upon with the other proc)
SETRI R4 4        ; int number for semop() request, that is int4
SETRI R6 1        ; first value to write in shared memory
SETRI R7 10       ; counter : number of values left to write
SETRI R3 225      ; waitLoop set address for the P() semop on semWrite
CLINT R4          ; P() the semaphore semWrite
STSHM R5 R6       ; store the value in the shared memory
SETRI R3 210      ; set address for the V() semop semRead
CLINT R4          ; V() the semaphore semRead
ADDRG R5 R5 R2    ; increment the address in the shared mem to write the remaining values
ADDRG R6 R6 R2    ; increment the value to be written in shared mem
SUBRG R7 R7 R2    ; decrement counter
JNZRI R7 -8       ; jump to write another value while counter isn't at 0
SETRI R9 2        ; int number for exit() 
CLINT R9          ; kernel int2 exits the process
