SETRI R2 3        ; # of random items to generate
SETRI R3 -1       ; min (included)
SETRI R4 5        ; max (excluded)
SETRI R5 800      ; addr where to write the random-generated items
SETRI R7 7        ; int number for the random-gernerate interruption
CLINT R7          ; generate the items
SETRI R9 2        ; int number for exit()
CLINT R9          ; kernel int2 exits the process
