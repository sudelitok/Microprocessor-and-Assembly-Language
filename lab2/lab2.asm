ortaksg		        SEGMENT PARA 'ortak'
                    ORG 100h
                    ASSUME DS:ortaksg, CS:ortaksg, SS:ortaksg
Basla:		        JMP MAIN
nonPrimeOrEvenSum   DB 15 DUP(0)
primeOddSum         DB 15 DUP(0)
a                   DB 30 DUP(0)
b                   DB 30 DUP(0)
c                   DB 30 DUP(0)
n                   DW 50
hyp                 DB 0
total               DW 0

MAIN                PROC NEAR

                    XOR BX,BX  ;BX a,b,c dizileri için tuttuğum index değeri
                    XOR SI, SI
                    MOV SI, 1 ;a kenarı
                    MOV CX, n 
A_LOOP:             PUSH CX ;A_LOOP'un dönüş değerini B_LOOP'ta kaybetmemek için stack'e atma
                    MOV DI, SI ;b kenarı (aynı değerleri tekrarlamaması için SI'dan başlattım)
                    MOV CX, [n] 
                    SUB CX, SI 
                    INC CX  ;B_LOOP'un dönüş sayısı 
B_LOOP:             MOV AX, SI
                    MUL SI ;a^2
                    MOV [total], AX
                    MOV AX, DI
                    MUL DI ;b^2
                    ADD [total], AX ;c^2

                    PUSH BX
                    CALL HYPOTENUSE
                    POP BX

                    XOR AH, AH 
                    MOV AL, [hyp]  ;cmp işlemleri için hipotenüsü AX'e set ettim. Hipotenüs byte boyutunda olduğundan AL'ye yazılır, AH 0 olur
                    CMP AX, 0
                    JE SKIP_TRIANGLE
                    CMP AX, [n]  ; hipotenüs belirtilen max kenar uzunluğunu aşmamalı
                    JA SKIP_TRIANGLE
                    MOV AX, SI
                    XCHG AL, a[BX]  ;SI 16 bit olmasına rağmen tuttuğu max değer 50 olduğundan AL'de saklanır. Type mismatch olmaması için al kullandım
                    MOV AX, DI
                    XCHG AL, b[BX]
                    MOV c[BX], DL ;kenar değerlerini ilgili dizilere yerleştirdim
                    INC BX  ;yeni üçgen bulundu

                    PUSH BX
                    CALL CLASSIFICATION
                    POP BX
           
SKIP_TRIANGLE:      INC DI  ;B_LOOP indexini (b kenarı) arttır
                    LOOP B_LOOP
                    POP CX  ;A_LOOP için CX değerini stack'ten çıkart
                    INC SI ;A_LOOP indexini (a kenarı) arttır
                    LOOP A_LOOP

                    RET
MAIN                ENDP

HYPOTENUSE	        PROC NEAR
                    MOV [hyp], 0
                    XOR DL, DL  ;1'den 49'a kadar c^2 sıfırlanana kadar çıkartacağım tek sayıların sayısı
                    MOV BX, 1  ;c^2'den çıkartacağım tek sayı (1'den 49'a kadar) (type mismatch olmaması için BX)
                    MOV AX, [total]
SQRT:               SUB AX, BX
                    INC DL  ;C^2'den çıkartılan tek sayı adetini 1 arttırıyorum
                    ADD BX, 2 ; c^2'den çıkarılacak bir sonraki tek sayı 
                    CMP AX, 0
                    JG SQRT  ; c^2 0'dan büyük olduğu sürece devam etmeli. negatif olma ihtimali var
                    JL END_H  ;n^2 = 1+3+5+....+(2n-1) -> n toplanan tek sayıların adetine eşit olur
                                ; n^2 eğer tam kare değilse sonuç negatif, tam kare ise 0 çıkar
                    MOV [hyp], DL  ; AX = 0 olduğuna göre c^2 tam kare olur, kare kökü ise DL'de saklı
END_H:              RET   
HYPOTENUSE	        ENDP

CLASSIFICATION     PROC NEAR
                    MOV BH, [hyp] ; BH'a hipotenüs değerini atadım
                    SHR BH, 1  ;asallık kontrolü için 2'den başlayarak sayının yarısına kadra olan sayılara bölünÜp bölünmediğini kontrol etmemiz yeter
                    MOV BL, 2
CONTINUE:           XOR AH, AH 
                    MOV AL, [hyp]   ;AX'i hipotenüse set ediyorum
                    DIV BL
                    CMP AH, 0   ;kalan 0 ise asal değil
                    JE NON_P_E  ;asal değilse nonPrimeOrEvenSum dizisine
                    INC BL  ;bölünecek bir sonraki sayı
                    CMP BL, BH 
                    JB CONTINUE ;bölünebileceği en küçük sayı 2 olduğu için bölümün hipotenüsün yarısından büyük olduğu durumları kontrol etmeye gerek yok
                    XOR AX, AX
                    MOV AX, SI
                    ADD AX, DI  ;a+b
                    TEST AX, 1  ; a+b tek mi çift mi? tekse sonuç 1
                    JZ NON_P_E  ;çiftse nonPrimeOrEvenSum dizisine
                    MOV BX, -1 ;BX'in değerini while döngüsününün başında 1 arttırarak index'i 0'dan başlatacağım
                    MOV AL, [hyp]
ADD_P:              INC BX ;ilk girdiğinde BX değeri 0 olur
                    CMP BX, 15 
                    JAE END_P
                    CMP AL, primeOddSum[BX]  ;hipotenüs değeri daha önce dizye yerleştirildi mi
                    JE END_P
                    CMP primeOddSum[BX], 0  ;index boş mu
                    JNE ADD_P  ;bir sonraki indexe bakılır
                    MOV primeOddSum[BX], AL  ;uygun yere hipotenüs değeri yerleştirilir
                    JMP END_P  ;diziye ekleme yaptığımız için sonlandırdım
                    
NON_P_E:            MOV BX, -1 ;BX'in değerini while döngüsününün başında 1 arttırarak index'i 0'dan başlatacağım
                    MOV AL, [hyp]
ADD_NP_E:           INC BX ;döngüye ilk girdiğinde BX değeri 0 olur
                    CMP BX, 15                          ;primeOddSum dizisinde yaptığım işlemlerin aynısı
                    JAE END_P                       
                    CMP AL, nonPrimeOrEvenSum[BX]
                    JE END_P
                    CMP nonPrimeOrEvenSum[BX], 0
                    JNE ADD_NP_E
                    MOV nonPrimeOrEvenSum[BX], AL
END_P:              RET
CLASSIFICATION      ENDP

ortaksg		        ENDS
			        END Basla