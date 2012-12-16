SETRI R0 0        ; index of semRead semaphore
SETRI R2 1        ; code of P(), also count of semop()s, and also index of semWrite
SETRI R3 215      ; address for the P() semop for semRead
STMEM R3 R0       ; store the index of the semaphore to operate on (semRead)
ADDRG R3 R3 R2    ; advance the address
STMEM R3 R2       ; store the P() operation code
SETRI R3 220      ; address for the V() semop on semWrite
STMEM R3 R2       ; store the index of the semaphore to operate on (semWrite)
ADDRG R3 R3 R2    ; advance the address
STMEM R3 R0       ; store the V() operation code
SETRI R4 4        ; int number for semop() request, that is int4 
SETRI R3 215      ; set address for the P() semop on semRead
CLINT R4          ; P() the semaphore semRead for initialization
SETRI R5 11       ; shared memory start address (agreed upon with the other proc)
SETRI R7 10       ; counter : number of values left to read
SETRI R8 300      ; address where to write the values read
SETRI R9 380      ; address where to write the value types (int)
SETRI R3 215      ; waitLoop , set address for the P() semop on semRead
CLINT R4          ; P() the semaphore semRead
LDSHM R5 R6       ; read from the shared memory value
SETRI R3 220      ; set address for the V() semop on semWite
CLINT R4          ; V() the semaphore semWrite
STMEM R8 R6       ; write the value we just read in the vect to be output
STMEM R9 R0       ; write the value type (type int)
ADDRG R8 R8 R2    ; increment the address where to write the values to read
ADDRG R9 R9 R2    ; increment the address where to write the value types (int)
ADDRG R5 R5 R2    ; increment the address where to read from the shared memory
SUBRG R7 R7 R2    ; decrement counter
JNZRI R7 -12      ; jump to read another value while counter isn't at 0
SETRI R3 300      ; start address in process memory where we've written the read values
SETRI R4 380      ; start address in process memory, for the "format"
SETRI R2 10       ; how many elements -- 10
SETRI R0 5        ; int number for consoleOut request
CLINT R0          ; call interruption int5 for kernel consoleOut
SETRI R9 2        ; int number for exit()
CLINT R9          ; kernel int2 exits the process
