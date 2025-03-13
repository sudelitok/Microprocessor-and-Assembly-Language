myss        SEGMENT PARA STACK 's'
            DW  32 DUP(?)
myss        ENDS
myds        SEGMENT PARA 'd'
CR	    EQU 13
LF	    EQU 10
sayilar     DW 10 DUP(0)
n           DW 10
modNum      DW 0 
MSG1	    DB CR, LF, 'Eleman sayisini veriniz(1 ile 10 arasinda): ', 0
MSG2	    DB CR, LF, 'Sayi veriniz(-32768 ile 32767 arasinda): ', 0
HATA1	    DB CR, LF, 'Dikkat !!! Sayi vermediniz yeniden giris yapiniz.!!!  ', 0
SONUC1	    DB CR, LF, 'Mod: ', 0
SONUC2      DB CR, LF, 'Mod yok!!! Her sayi dizide 1 defa bulunuyor! ', 0 
myds        ENDS

mycs        SEGMENT PARA 'c'
            ASSUME CS:mycs, DS:myds, SS:myss

GIRIS_DIZI  MACRO sayilar, n
            LOCAL eleman_say, eleman
            PUSH AX
            PUSH CX    ; kullanacağım registerları ana yordamda değerlerinin değişmemesi için stack'e atıyorum
            PUSH SI
eleman_say: MOV AX, OFFSET MSG1
            CALL PUT_STR    ; MSG1’i göster 
            CALL GETN  	    ; kullanıcının gireceği eleman sayısını oku
            CMP AX, 10
            JG eleman_say
            CMP AX, 0
            JLE eleman_say
            MOV n, AX   ;n 1-10 arasında

            MOV CX, n
            XOR SI, SI
eleman:     MOV AX, OFFSET MSG2
            CALL PUT_STR    ; MSG2’yi göster 
            CALL GETN  	    ; kullanıcının girdiği elemanı oku
            MOV sayilar[SI], AX  ;okunan elemanı diziye at
            ADD SI, 2  ;elemanlar word tipinde olduğu için 2 arttırıyorum 
            LOOP eleman
            POP SI 
            POP CX      ;stack'e attığım değerleri çıkartıyorum
            POP AX
            ENDM

MAIN        PROC FAR
            PUSH DS     
            XOR AX, AX  
            PUSH AX 
            MOV AX, myds
            MOV DS, AX

            GIRIS_DIZI sayilar, n

            PUSH n ;SP+18
            LEA AX, sayilar
            PUSH AX ;SP+16
            PUSH modNum ;SP+14
            CALL FIND_MOD  ;offset değer stack'e yerleşir SP+12
            POP modNum  ;FIND_MOD sonrasında yeni eğer pop edilir
            POP AX
            POP n
            
            CMP modNum, 0
            JE mod_yok ;her sayi dizide 1 kere bulunuyor, tekrar etmiyor
            MOV AX, OFFSET SONUC1
            CALL PUT_STR	; SONUC1’i göster
            MOV AX, modNum
            CALL PUTN
            JMP son
mod_yok:    MOV AX, OFFSET SONUC2
            CALL PUT_STR	; SONUC2’yi göster

son:        RETF
MAIN        ENDP

FIND_MOD    PROC NEAR
            PUSH BX ;SP+10
            PUSH SI ;SP+8
            PUSH DI ;SP+6
            PUSH AX ;SP+4
            PUSH BP ;SP+2
            PUSH CX ;SP
            
            MOV BP, SP
            XOR BX,BX ;count ve maxCount değerlerini tutmak için
            MOV SI, [BP+16] ;ilk döngü için dizinin başlangıç adresi
            MOV CX, [BP+18]  ;ilk döngü için dönüş sayısı dizinin eleman sayısı
            DEC CX ;son elemanı kontrol etmeye gerek yok
L1:         PUSH CX ;ikinci döngü için ilk döngü sayısı stack'e atılır
            MOV BL, 0 ;o sayı için tekrar sayısı 0'lanır
            MOV DI, SI 
            ADD DI, 2 ; ikinci döngü dizinin bir sonraki elemanı göstermeli, word tipinde olduğu için 2 arttırmalıyız        
            MOV AX, [SI]
L2:         CMP AX, [DI]
            JNE farkli
            INC BL ;tekrar ettiği için count++
farkli:     ADD DI, 2
            LOOP L2
            CMP BL, BH ; o sayının tekrar sayısının hesaplanan maximum tekrar sayısından büyük olup olmadığına bakılır         
            JNA sonraki
            MOV BH, BL  ;maxCount güncellenir
            XCHG AX, [BP+14] ;stack'te bulunan modNum değerine o ana kadar en çok tekrar eden sayı atanır
sonraki:    POP CX
            ADD SI, 2
            LOOP L1           

            POP CX
            POP BP
            POP AX
            POP DI
            POP SI
            POP BX

            RET 
FIND_MOD    ENDP

GETC	PROC NEAR
        ;------------------------------------------------------------------------
        ; Klavyeden basılan karakteri AL yazmacına alır ve ekranda gösterir. 
        ; işlem sonucunda sadece AL etkilenir. 
        ;------------------------------------------------------------------------
        MOV AH, 1h
        INT 21H
        RET 
GETC	ENDP 

PUTC	PROC NEAR
        ;------------------------------------------------------------------------
        ; AL yazmacındaki değeri ekranda gösterir. DL ve AH değişiyor. AX ve DX 
        ; yazmaçlarının değerleri korumak için PUSH/POP yapılır. 
        ;------------------------------------------------------------------------
        PUSH AX
        PUSH DX
        MOV DL, AL
        MOV AH,2
        INT 21H
        POP DX
        POP AX
        RET 
PUTC 	ENDP 

GETN 	PROC NEAR
        ;------------------------------------------------------------------------
        ; Klavyeden basılan sayiyi okur, sonucu AX yazmacı üzerinden dondurur. 
        ; DX: sayının işaretli olup/olmadığını belirler. 1 (+), -1 (-) demek 
        ; BL: hane bilgisini tutar 
        ; CX: okunan sayının islenmesi sırasındaki ara değeri tutar. 
        ; AL: klavyeden okunan karakteri tutar (ASCII)
        ; AX zaten dönüş değeri olarak değişmek durumundadır. Ancak diğer 
        ; yazmaçların önceki değerleri korunmalıdır. 
        ;------------------------------------------------------------------------
        PUSH BX
        PUSH CX
        PUSH DX
GETN_START:
        MOV DX, 1	                        ; sayının şimdilik + olduğunu varsayalım 
        XOR BX, BX 	                        ; okuma yapmadı Hane 0 olur. 
        XOR CX,CX	                        ; ara toplam değeri de 0’dır. 
NEW:
        CALL GETC	                        ; klavyeden ilk değeri AL’ye oku. 
        CMP AL,CR 
        JE FIN_READ	                        ; Enter tuşuna basilmiş ise okuma biter
        CMP  AL, '-'	                        ; AL ,'-' mi geldi ? 
        JNE  CTRL_NUM	                        ; gelen 0-9 arasında bir sayı mı?
NEGATIVE:
        MOV DX, -1	                        ; - basıldı ise sayı negatif, DX=-1 olur
        JMP NEW		                        ; yeni haneyi al
CTRL_NUM:
        CMP AL, '0'	                        ; sayının 0-9 arasında olduğunu kontrol et.
        JB error 
        CMP AL, '9'
        JA error		                ; değil ise HATA mesajı verilecek
        SUB AL,'0'	                        ; rakam alındı, haneyi toplama dâhil et 
        MOV BL, AL	                        ; BL’ye okunan haneyi koy 
        MOV AX, 10 	                        ; Haneyi eklerken *10 yapılacak 
        PUSH DX		                        ; MUL komutu DX’i bozar işaret için saklanmalı
        MUL CX		                        ; DX:AX = AX * CX
        POP DX		                        ; işareti geri al 
        MOV CX, AX	                        ; CX deki ara değer *10 yapıldı 
        ADD CX, BX 	                        ; okunan haneyi ara değere ekle 
        JMP NEW 		                ; klavyeden yeni basılan değeri al 
ERROR:
        MOV AX, OFFSET HATA1 
        CALL PUT_STR	                        ; HATA mesajını göster 
        JMP GETN_START                          ; o ana kadar okunanları unut yeniden sayı almaya başla 
FIN_READ:
        MOV AX, CX	                        ; sonuç AX üzerinden dönecek 
        CMP DX, 1	                        ; İşarete göre sayıyı ayarlamak lazım 
        JE FIN_GETN
        NEG AX		                        ; AX = -AX
FIN_GETN:
        POP DX
        POP CX
        POP DX
        RET 
GETN 	ENDP 

PUTN 	PROC NEAR
        ;------------------------------------------------------------------------
        ; AX de bulunan sayiyi onluk tabanda hane hane yazdırır. 
        ; CX: haneleri 10’a bölerek bulacağız, CX=10 olacak
        ; DX: 32 bölmede işleme dâhil olacak. Soncu etkilemesin diye 0 olmalı 
        ;------------------------------------------------------------------------
        PUSH CX
        PUSH DX 	
        XOR DX,	DX 	                        ; DX 32 bit bölmede soncu etkilemesin diye 0 olmalı 
        PUSH DX		                        ; haneleri ASCII karakter olarak yığında saklayacağız.
                                                ; Kaç haneyi alacağımızı bilmediğimiz için yığına 0 
                                                ; değeri koyup onu alana kadar devam edelim.
        MOV CX, 10	                        ; CX = 10
        CMP AX, 0
        JGE CALC_DIGITS	
        NEG AX 		                        ; sayı negatif ise AX pozitif yapılır. 
        PUSH AX		                        ; AX sakla 
        MOV AL, '-'	                        ; işareti ekrana yazdır. 
        CALL PUTC
        POP AX		                        ; AX’i geri al 
        
CALC_DIGITS:
        DIV CX  		                ; DX:AX = AX/CX  AX = bölüm DX = kalan 
        ADD DX, '0'	                        ; kalan değerini ASCII olarak bul 
        PUSH DX		                        ; yığına sakla 
        XOR DX,DX	                        ; DX = 0
        CMP AX, 0	                        ; bölen 0 kaldı ise sayının işlenmesi bitti demek
        JNE CALC_DIGITS	                        ; işlemi tekrarla 
        
DISP_LOOP:
                                                ; yazılacak tüm haneler yığında. En anlamlı hane üstte 
                                                ; en az anlamlı hane en alta ve onu altında da 
                                                ; sona vardığımızı anlamak için konan 0 değeri var. 
        POP AX		                        ; sırayla değerleri yığından alalım
        CMP AX, 0 	                        ; AX=0 olursa sona geldik demek 
        JE END_DISP_LOOP 
        CALL PUTC 	                        ; AL deki ASCII değeri yaz
        JMP DISP_LOOP                           ; işleme devam
        
END_DISP_LOOP:
        POP DX 
        POP CX
        RET
PUTN 	ENDP 

PUT_STR	PROC NEAR
        ;------------------------------------------------------------------------
        ; AX de adresi verilen sonunda 0 olan dizgeyi karakter karakter yazdırır.
        ; BX dizgeye indis olarak kullanılır. Önceki değeri saklanmalıdır. 
        ;------------------------------------------------------------------------
	PUSH BX 
        MOV BX,	AX			        ; Adresi BX’e al 
        MOV AL, BYTE PTR [BX]	                ; AL’de ilk karakter var 
PUT_LOOP:   
        CMP AL,0		
        JE  PUT_FIN 			        ; 0 geldi ise dizge sona erdi demek
        CALL PUTC 			        ; AL’deki karakteri ekrana yazar
        INC BX 				        ; bir sonraki karaktere geç
        MOV AL, BYTE PTR [BX]
        JMP PUT_LOOP			        ; yazdırmaya devam 
PUT_FIN:
	POP BX
	RET 
PUT_STR	ENDP

mycs        ENDS
            END MAIN