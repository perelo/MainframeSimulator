SETRI R0 0        ; index of first (and unique) semaphore 
SETRI R2 1        ; code of P(), and also count of semop()s
SETRI R3 215      ; address for the P() semop
STMEM R3 R0       ; store the index of the semaphore to operate on
ADDRG R3 R3 R2    ; advance the address
STMEM R3 R2       ; store the P() operation code
SETRI R3 225      ; address for the V() semop
STMEM R3 R0       ; store the index of the semaphore to operate on
ADDRG R3 R3 R2    ; advance the address
STMEM R3 R0       ; store the V() operation code
SETRI R5 10       ; shared memory address (agreed upon with the other proc)
SETRI R4 4        ; int number for semop() request, that is int4
SETRI R6 65       ; value to write in shared memory
SETRI R3 215      ; set address for the P() semop
CLINT R4          ; P() the semaphore
STSHM R5 R6       ; store the value in the shared memory
SETRI R3 225      ; set address for the V() semop
CLINT R4          ; V() the semaphore
SETRI R9 2        ; int number for exit() 
CLINT R9          ; kernel int2 exits the process
