SETRI R0 0	  ; index of first (and unique) semaphore 
SETRI R2 1	  ; code of P(), and also count of semop()s
SETRI R3 210	  ; address for the P() semop
STMEM R3 R0	  ; store the index of the semaphore to operate on
ADDRG R3 R3 R2	  ; advance the address
STMEM R3 R2	  ; store the P() operation code
SETRI R3 220	  ; address for the V() semop
STMEM R3 R0	  ; store the index of the semaphore to operate on
ADDRG R3 R3 R2    ; advance the address
STMEM R3 R0       ; store the V() operation code
SETRI R5 10	  ; shared memory address (agreed upon with the other proc)
SETRI R4 4	  ; int number for semop() request, that is int4 
SETRI R3 210	  ; waitLoop , set address for the P() semop
CLINT R4	  ; P() the semaphore
LDSHM R5 R6	  ; read the shared memory value
SETRI R3 220	  ; set address for the V() semop
CLINT R4	  ; V() the semaphore
JZROI R6 -5	  ; jump back to waitLoop if the value read from shmem is zero
SETRI R3 300	  ; some address in process memory
STMEM R3 R6	  ; store the value read from shared memory at that address in proc mem
SETRI R4 380	  ; some other address in process memory, for the "format" 
SETRI R1 1	  ; type char
STMEM R4 R1	  ; store the type value
SETRI R2 1	  ; how many elements -- just one
SETRI R0 5	  ; int number for consoleOut request
CLINT R0          ; call interruption int5 for kernel consoleOut
SETRI R9 2        ; int number for exit()
CLINT R9          ; kernel int2 exits the process
