.names 7
.proc Main
.proc test6
.proc test4
.proc testing2
.proc testing1
.var 1 thisConstant
.recordDecl game
testing1: Enter 1
Const 10
Sto 0 0
Load 0 0
StoG 4094
Leave
Ret
testing2: Enter 1
Const 1
Sto 0 0
Load 0 0
StoG 4094
Leave
Ret
test4: Enter 4
LoadG 4085
Sto 0 0
LoadG 4082
Sto 0 1
LoadG 4079
Sto 0 2
LoadG 4076
Sto 0 3
Load 0 1
Const 1
Add
Sto 0 1
Load 0 1
StoG 4094
Leave
Ret
test6: Enter 2
LoadG 4085
Sto 0 0
LoadG 4082
Sto 0 1
Leave
Ret
Main: Enter 14
Const 3
StoG 3
LoadG 3
Write
Const 1001
Const 1
Sto 1 1
Sto 1 1
Const 115
Const 115
Const 101
Const 99
Const 99
Const 65
Const 32
Const 100
Const 114
Const 111
Const 99
Const 101
Const 82
Const 13
WriteStr
Load 1 1
Write
Const 1
Sto 0 1
Const 2
Sto 0 2
Const 3
Sto 0 3
Const 4
Sto 0 4
Const 5
Sto 0 5
Const 121
Const 97
Const 114
Const 114
Const 97
Const 32
Const 68
Const 49
Const 8
WriteStr
Load 0 1
Write
Const 4
Sto 0 6
Const 129
Sto 0 7
Const 121
Const 97
Const 114
Const 114
Const 97
Const 32
Const 68
Const 50
Const 8
WriteStr
Load 0 6
Write
Load 0 7
Write
Const 3
Sto 0 0
Load 0 0
Const 1
Equ
FJmp L$1
Const 49
Const 32
Const 101
Const 115
Const 97
Const 99
Const 6
WriteStr
Jmp L$0
L$1: Nop
Load 0 0
Const 2
Equ
FJmp L$2
Const 50
Const 32
Const 101
Const 115
Const 97
Const 99
Const 6
WriteStr
Jmp L$0
L$2: Nop
Load 0 0
Const 3
Equ
FJmp L$3
Const 51
Const 32
Const 101
Const 115
Const 97
Const 99
Const 6
WriteStr
Jmp L$0
L$3: Nop
Const 116
Const 108
Const 117
Const 97
Const 102
Const 101
Const 100
Const 7
WriteStr
L$0: Nop
Const 112
Const 111
Const 111
Const 76
Const 32
Const 114
Const 111
Const 70
Const 8
WriteStr
Const 0
Sto 0 0
L$4: Nop
Load 0 0
Const 10
Lss
FJmp L$5
Load 0 0
Const 1
Add
Load 0 0
Write
Sto 0 0
Jmp L$4
L$5: Nop
Const 84
Const 104
Const 105
Const 115
Const 4
Sto 0 11
StoG 4067
StoG 4064
StoG 4061
StoG 4058
LoadG 4067
LoadG 4064
LoadG 4061
LoadG 4058
Load 0 11
WriteStr
Const 101
Const 116
Const 105
Const 114
Const 119
Const 32
Const 101
Const 110
Const 105
Const 108
Const 32
Const 101
Const 108
Const 112
Const 105
Const 116
Const 108
Const 117
Const 109
Const 32
Const 97
Const 32
Const 115
Const 105
Const 24
WriteStr
Call 1 testing1
LoadG 4094
Sto 0 12
Load 0 12
Write
Call 1 testing2
LoadG 4094
Sto 0 13
Const 101
Const 117
Const 108
Const 97
Const 118
Const 32
Const 116
Const 110
Const 101
Const 100
Const 105
Const 32
Const 102
Const 111
Const 32
Const 110
Const 114
Const 117
Const 116
Const 101
Const 114
Const 21
WriteStr
Load 0 13
Write
Const 101
Const 108
Const 98
Const 97
Const 105
Const 114
Const 97
Const 118
Const 32
Const 97
Const 32
Const 102
Const 111
Const 32
Const 110
Const 114
Const 117
Const 116
Const 101
Const 114
Const 20
WriteStr
Const 15
Sto 0 0
Load 0 0
StoG 4085
Const 1
StoG 4082
Const 2
StoG 4079
Const 3
StoG 4076
Call 1 test4
LoadG 4094
Sto 0 12
Const 115
Const 114
Const 101
Const 116
Const 101
Const 109
Const 97
Const 114
Const 97
Const 112
Const 32
Const 110
Const 111
Const 105
Const 116
Const 99
Const 110
Const 117
Const 102
Const 32
Const 110
Const 114
Const 117
Const 116
Const 101
Const 114
Const 26
WriteStr
Load 0 12
Write
Const 3
Const 2
Gtr
FJmp L$6
Const 4
Sto 0 12
Jmp L$7
L$6: Nop
Const 2
Sto 0 12
L$7: Nop
Const 116
Const 110
Const 101
Const 109
Const 110
Const 103
Const 105
Const 115
Const 115
Const 65
Const 32
Const 110
Const 111
Const 105
Const 116
Const 110
Const 105
Const 100
Const 110
Const 111
Const 67
Const 21
WriteStr
Load 0 12
Write
Leave
Ret
