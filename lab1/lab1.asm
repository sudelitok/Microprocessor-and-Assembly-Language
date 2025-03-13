stacksg		SEGMENT PARA STACK 'yigin'
			DW 12 DUP(?)
stacksg		ENDS

datasg		SEGMENT PARA 'veri'
vize		DB 77, 85, 64,96
final 		DB 56, 63, 86, 74
obp         DB 4 DUP(?)
n			DW 4
v_katsayi   DB 4
f_katsayi   DB 6
b           DB 10
total      DW 0
datasg		ENDS

codesg		SEGMENT PARA 'kod'
			ASSUME DS:datasg, SS:stacksg, CS:codesg
MAIN        PROC FAR
			PUSH DS
            
			XOR AX, AX
			PUSH AX
			MOV AX, datasg
			MOV DS, AX

            XOR SI, SI
            MOV CX, n
CALC_GPA:   MOV AL, vize[SI]
            MUL v_katsayi
            MOV [total], AX
            MOV AL, final[SI]
            MUL f_katsayi
            ADD [total], AX
            MOV AX, [total]
            DIV b
            CMP AH, 5
            JB NO_ROUND
            INC AL
NO_ROUND:   MOV obp[SI], AL
            INC SI
            LOOP CALC_GPA

			XOR SI, SI
            MOV CX, n 
S_LOOP1:    PUSH CX  ;inner loop'ta farklı bir değer kullanacağım bu yüzden outer loop için olan değeri saklamam lazım
            XOR DI, DI
            MOV CX, n
            SUB CX, SI
S_LOOP2:    MOV AL, obp[DI]
            CMP AL, obp[DI+1]
            JAE GREATER
            XCHG AL, obp[DI+1] ;AL obp[DI]'yi tutuyor
            MOV obp[DI], AL
GREATER:    INC DI
            LOOP S_LOOP2
            POP CX ;outer loop'un döngü sayısı 
            INC SI
            LOOP S_LOOP1
            RETF
MAIN        ENDP
codesg		ENDS
		    END MAIN

