SETRI R3 800
SETRI R1 1
SETRI R4 851
STMEM R4 R1
SETRI R4 850
STMEM R4 R1
SETRI R2 2
SETRI R0 6
CLINT R0        ; kernel int6 consoleIn
SETRI R6 2
CLINT R6        ; kernel int2 exits the process

