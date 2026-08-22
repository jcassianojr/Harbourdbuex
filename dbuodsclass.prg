#INCLUDE "hbclass.ch"

REQUEST HB_CODEPAGE_UTF8EX

PROCEDURE Fazerodsclass()
LOCAL oDS, oSheet1
LOCAL nBorder, nFont, nNumFmt, nNumFmt1, nFill1, nFill2
LOCAL nStyle, nStyle1, nStyle2
LOCAL aSTRU
LOCAL nFIELDS
LOCAL cPOS
LOCAL nPOS
LOCAL cCOMP
hb_cdpSelect( 'UTF8EX' )

// Variável alterada para oDS para refletir a nova classe
oDS := WorkBookODS():New(alias()+".ods") 
nNumFmt := oDS:NewFormat("#,##0.000")
nNumFmt1 := oDS:NewFormat("#,##0.00")
oSheet1:= oDS:WorkSheet(alias())

oSheet1:paperSize := 9 // A4
oSheet1:lLandscape := .T.
oSheet1:leftMargin := 0.5
oSheet1:rightMargin := 0.5
oSheet1:topMargin := 0.5
oSheet1:bottomMargin := 0.5
oSheet1:RowDetail( 5, 49.5 )    

nFill1 := oDS:NewFillPattern( 1, "FFEEEEEE", "FFFFFFCC" )
nFill2 := oDS:NewFillPattern( 1, "FFDDDDDD", "FFEEEEEE" )

nFont := oDS:NewFont( "Tahoma", 16, .T., .F., .F., .F., "FFFF0000" )
nBorder := oDS:NewBorder( 1, 1, 1, 1, 0 )

nStyle :=  oDS:NewStyle( nFont, nBorder, nFill1, 2, 2 )
nStyle1 := oDS:NewStyle( , , , , , nNumFmt )
nStyle2 := oDS:NewStyle( , nBorder, , , , nNumFmt1 )

aSTRU:=DBStruct()
nFIELDS := Len( aSTRU )
nPOS    :=1
cCOMP   :=""

IF lDOCCAB
      for i:=1 to nfields
          cPOS:=CHR(64+I)+ALLTRIM(Str(nPOS, 8 , 0 ) )
          evalor:=ALLTRIM(astru[I][1])+","+astru[I][2]
          IF astru[I][2]="C" .OR. astru[I][2]="N"
             evalor+=","+ALLTRIM(STR(astru[I][3],8,0))
          ENDIF  
          IF astru[I][2]="N" 
             evalor+=","+ALLTRIM(STR(astru[I][4],8,0))
          ENDIF   
          oSheet1:Cell(cCOMP+cPOS, evalor )
           IF CHR(64+I)="Z"
              IF EMPTY(cCOMP)
                 cCOMP:="A"
              ELSE
                 cCOMP:=CHR(ASC(cCOMP)+1)  //A-Z AA-AZ BA-BZ ...
              ENDIF
          ENDIF
      next i
    nPOS++
ENDIF

IF lDOCDAD
    cCOMP   :=""
    dbgotop()
    while .not. EOF()
       for i:=1 to nfields
           cPOS:=CHR(64+I)+ALLTRIM(Str(nPOS, 8 , 0 ) )
           evalor:=HB_FIELDGET(I)
           IF VALTYPE(evalor)="C"
            eVALOR := FixSRTExtendido( eVALOR , .T. , .T. , .T. , .T. , .T. )
           ENDIF
           if .NOT. EMPTY(evalor)
              oSheet1:Cell(cCOMP+cPOS, evalor )
           endif
           IF CHR(64+I)="Z"
              IF EMPTY(cCOMP)
                 cCOMP:="A"
              ELSE
                 cCOMP:=CHR(ASC(cCOMP)+1)  //A-Z AA-AZ BA-BZ ...
              ENDIF
           ENDIF
       next I
       nPOS++
       ZEI_FORT( nLASTREC,,, 1 )
       dbskip()
    ENDDO
ENDIF    

oDS:Save()

hb_cdpSelect( 'PTISO' )

Return .t.