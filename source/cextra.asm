;tests if a candidate has CER > 6 compared to all other candidates
_OVERKILL
@COPYCER
	LDA C_CER
	LDX V_PARTY
	STA V_LEAN,X
	JSR _CANDSWAP
	LDA V_PARTY
	BNE @COPYCER
	JSR _LEANTOMAX
	JSR _LEANDIF
	LDA FRET1
	CMP #06
	BCC @DONE
	LDX V_MAXPL
	LDA #01
	STA V_OVERKILL,X
@DONE
	RTS
	
;sets first state to do POLL
_AITOP
	LDA V_PARTY
	JSR _CANDLOAD
	LDA C_HOME
	LDX V_PARTY
	STA V_AITOP,X
	INC V_PARTY
	LDA V_PARTY
	CMP S_PLAYER
	BNE _AITOP
	LDA #00
	STA V_PARTY
	JSR _CANDLOAD
	RTS
	
;draw_blank(A = count)
_DRWBLANK
    STA T_BLANKX+4
    +__LAB2XY T_BLANKX
    JSR _GX_STR
	RTS





