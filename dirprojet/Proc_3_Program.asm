SETRI R3 350    
SETRI R1 20
STMEM R3 R1
SETRI R4 380
SETRI R1 0
STMEM R4 R1
SETRI R2 1
SETRI R0 5
CLINT R0        ; kernel int5 consoleOut
SETRI R6 2
CLINT R6        ; kernel int2 exits the process

