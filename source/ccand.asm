;ccand.asm
;CAMP09 
;candidate routines

;candidate_swap() 
;stores current candidate to memory
;loads next candidate to current
_CANDSWAP 
	LDA V_PARTY
	JSR _CANDSAVE
	INC V_PARTY
	LDA V_PARTY
	CMP S_PLAYER
	BNE @WRAP
	LDA #00
	STA V_PARTY
@WRAP 
	JSR _CANDLOAD
	RTS 

;candidate_save(A=party index)
;stores current candidate to memory
_CANDSAVE 
	TAX 
	+__LAB2O V_ALLCND
	LDY #CANDDATA
	JSR _OFFSET
	LDY #00
@LOOP 
	LDA C_SCHEDC,Y
	STA (OFFSET),Y
	INY 
	CPY #CANDDATA
	BNE @LOOP
	RTS 

;candidate_load(A=party index)
;loads saved candidate to current
_CANDLOAD 
	TAX 
	+__LAB2O V_ALLCND
	LDY #CANDDATA
	JSR _OFFSET
	LDY #00
@LOOP LDA (OFFSET),Y
	STA C_SCHEDC,Y
	INY 
	CPY #CANDDATA
	BNE @LOOP
	RTS 

;primary_candidate_select() 
_CANDSEL 
	LDA #00
	STA V_WEEK
@NEXTPTY 
	LDA #00
	STA C_INCUMB
	STA V_CANDSEL
	STA FPARTY ;primary index counter
	JSR _CANDGEN

	+__COORD P_PNAMER,P_PNAMEC
	LDX V_PARTY
	LDA V_PTCOL,X
	STA GX_DCOL

	+__LAB2O D_PARTY
	LDX V_PARTY
	LDY #NAMELEN+1
	JSR _OFFSET
	+__O2XY
	JSR _GX_STR ;draw party name

	LDA GX_DCOL
	STA GX_BCOL

	LDX V_PARTY
	LDA V_PTCOL,X
	STA GX_DCOL
	+__LAB2XY T_CONVEN
	+__COORD P_CONVNR,P_CONVNC
	JSR _GX_STR

	LDA S_CUSTOM
	BEQ @SANYWAY
	JSR _CANDSEL2
	JSR _CANDSEL3
	JMP @SELECTD
@SANYWAY

@NEXTCAN 
	LDX FPARTY
	JSR _CANDSEL2
@REDRAW
	LDA V_CANDSEL
	BEQ @LEAN
	JSR _ISSUEMAP2
	JMP @DRAWN
@LEAN
	JSR _MAPCMB3
@DRAWN
	
	+__COORD P_NOYESR,P_NOYESC
	+__LAB2XY T_CANDSEL
	JSR _GX_STR	
	LDX #P_NOYESR
	LDY #P_NOYESR+2
	JSR _RSELECT
	CMP #02
	BEQ @TOGGLE
	CMP #01
	BEQ @SELECTD

@INCCAND 
	INC FPARTY
	LDA FPARTY
	CMP #PRIMARYC
	BNE @NEXTCAN
	LDA #00
	STA FPARTY
	BEQ @NEXTCAN

@TOGGLE
	LDA V_CANDSEL
	EOR #01
	STA V_CANDSEL
	JMP @REDRAW
@SELECTD
	JSR _FTC
	BNE @REDRAW
	LDA C_HOME
	JSR _CPOFFS
	LDA #CPBLEAN
	CLC
	ADC V_PARTY
	TAY
	LDA (CP_ADDR),Y
	CLC
	ADC #$01
	STA (CP_ADDR),Y ;STATE LEAN + 1 in home state
	
	LDY C_HOME
	JSR _HQPLUS
	LDY C_HOME
	JSR _HQPLUS ;HQ + 2 in home state
	
	LDA S_CUSTOM
	BEQ @SKIPVP
	;select VP home state
	+__COORD P_CONVNR+3,P_CONVNC
	+__LAB2XY T_VP
	JSR _GX_STR
	
@MAPSEL
	JSR _MAP
	LDA MAP_RES
	BEQ @MAPSEL
	STA C_VP
	JSR _DRWVP
	JSR _FTC
	BNE @MAPSEL
@SKIPVP

	LDY C_VP
	JSR _HQPLUS 
	LDY C_VP
	JSR _HQPLUS ;HQ + 2 in VP state

	JSR _NAMEINP
	JSR _DRWINCM
	JSR _DRWAIM
	
	JMP @QDONE

@QUICKG2 
	LDX #00
	LDA #03
@AILOOP 
	STA V_AI,X
	INX 
	CPX #$04
	BNE @AILOOP
@QDONE 
	JSR _CANDSS2 ;factor in INCUMBENT bonus
	JSR _CANDSWAP ;incs v_party

	LDA V_PARTY
	BEQ @DONE
	JMP @NEXTPTY
@DONE 
	RTS 
;load candidate info
_CANDSEL2 
	JSR _CPYPRIM
	JSR _CANDSSC
	JSR _DRWCAND
	RTS 

;custom candidate select
_CANDSEL3
	LDA S_CUSTOM
	BNE @ON
	RTS
@ON
	JSR _MAP
	LDA MAP_RES
	BEQ @ON
	STA C_HOME
	STA C_VBONUS
	JSR _STATEGR
	STX C_CREG
	STX C_IREG
	JSR _DRWCAND
	
	LDA #$00
	STA FVAR1
@PRIMARY
	LDA #P_PRIMR
	CLC
	ADC FVAR1
	STA GX_CROW
	LDA #P_PRIMC
	STA GX_CCOL
	LDA #FILLCHR
	STA GX_CIND
	LDA #C_WHITE
	STA GX_DCOL
	JSR _GX_CHAR
@INPUT
	JSR _INPUTF3
	STA GX_CIND
	AND #$0F
	CMP #$01
	BCC @INPUT
	CMP #$09
	BCS @INPUT
	LDX FVAR1
	STA C_CHAR,X
	JSR _GX_CHAR
	INC FVAR1
	LDA FVAR1
	CMP #$05
	BNE @PRIMARY
	
	JSR _GENHEAL
	STA C_HEALTH
	LDX C_CORP
	JSR _GENMONEY
	STA C_MONEY
	
	JSR _CANDSSC
	JSR _DRWCAND
	
	LDA #$00
	STA FVAR1
@ISSUES
	LDA #P_ISSUER
	CLC
	ADC FVAR1
	STA GX_CROW
	LDA #P_ISSUEC
	STA GX_CCOL
	LDA #FILLCHR
	STA GX_CIND
	LDA #C_WHITE
	STA GX_DCOL
	JSR _GX_CHAR
@INPUT2
	JSR _INPUTF3
	STA GX_CIND
	CMP #NUMBERS
	BCC @INPUT2
	CMP #NUMBERS+10
	BCS @INPUT2
	AND #$0F
	LDX FVAR1
	STA C_ISSUES,X
	JSR _GX_CHAR
	INC FVAR1
	LDA FVAR1
	CMP #ISSUEC
	BNE @ISSUES
	JSR _DRWCAND
	
	JSR _FTC
	BEQ @DONE
	JMP _CANDSEL3
@DONE
	RTS

;copy_primary_candidate(X=PRIMARY INDEX)
_CPYPRIM 
	+__LAB2O V_PRIMRY
	LDY #PRIMDATC
	JSR _OFFSET
	LDY #01
	LDX #00
@PSLOOP 
	LDA (OFFSET),Y
	STA C_CHAR,X
	INY 
	INX 
	CPX #$05
	BNE @PSLOOP
	LDX #00
@ISLOOP 
	LDA (OFFSET),Y
	STA C_ISSUES,X
	INY 
	INX 
	CPX #$05
	BNE @ISLOOP
	LDA (OFFSET),Y
	STA C_HOME
	STA C_VBONUS
	STA V_VBONUS
	INY 
	LDA (OFFSET),Y
	STA C_TITLE
	INY 
	LDA (OFFSET),Y
	STA C_HEALTH
	INY 
	LDA (OFFSET),Y
	STA C_MONEY
	INY
	LDA (OFFSET),Y
	LDX V_PARTY
	STA V_PROFILE,X
	INY
	LDA (OFFSET),Y
	STA C_VP
	RTS 

;setup_player_names() 
;copies four "PLAYER #" as defaults
_SETUPPN 
	+__LAB2O V_PNAME
	LDA #00
	STA FVAR1 ;player index
	+__LAB2A T_PLAYER

@LOOP 
	LDA OFFSET
	STA FARG3
	LDA OFFSET+1
	STA FARG3+1 ;destination
	LDA #NAMELEN
	STA FARG5
	JSR _COPY
	INC FVAR1
	LDA FVAR1
	ORA #$30 ;player #
	LDY #$07
	STA (OFFSET),Y
	LDA #00
	LDY #$08
	STA (OFFSET),Y
	LDX #$01
	LDY #NAMELEN
	JSR _OFFSET ;inc destination
	LDA FVAR1
	CMP #PLAYERMAX
	BNE @LOOP
	RTS 

;primary_candidate_generation() 
_CANDGEN 
	+__LAB2O V_PRIMRY
	LDA #PRIMARYC
	STA FVAR1 ;current candidate
@TOP 
	LDY #$05
@CLRLOOP 
	LDA #$01
	STA (OFFSET),Y
	DEY 
	BNE @CLRLOOP
	
	LDX #$14 ;20 "primary points"

	LDA S_EQCER
	BEQ @SKIPEQ
	LDA #05
	LDY #01
	STA (OFFSET),Y
	LDY #03
	STA (OFFSET),Y
	LDX #$0A ;10 "primary points"
@SKIPEQ 
@RNGLOOP 
	LDA #$05
	JSR _RNG ;rand(0,3)
	TAY
	INY 
	LDA S_EQCER
	BEQ @SKIPEQ2
	CPY #$01 ;if EQUAL CER, do not add to CHAR/INTL
	BEQ @RNGLOOP
	CPY #$03
	BEQ @RNGLOOP
@SKIPEQ2 
	LDA (OFFSET),Y
	CMP #$08
	BEQ @RNGLOOP
	CLC 
	ADC #$01
	STA (OFFSET),Y
	DEX 
	BNE @RNGLOOP
;;
@PRIMDONE
	LDA S_3PMODE
	BEQ @SKIPWOR
	JSR _ISSUWOR
@SKIPWOR 
	
	LDY #$06
@NEXTISS ;issues
	LDA #00
	STA FRET3
	JSR _ISSUSEL
	JSR _ISSUSEL2
	
	STA (OFFSET),Y
	INY 

	CPY #$0B
	BNE @NEXTISS
	BEQ @DONEISS
@DONEISS 
	JSR _RANDSTATE
	STA (OFFSET),Y
	INY 
@REROLL
	LDA #12
	JSR _RNG ;candidate title
	BEQ @SKMULT
	TAX
	LDA FVAR5
	CMP #24 ;DC
	CPX #03
	BCC @REROLL
	LDA #00
	CLC 
@MULT 
	ADC #$05
	DEX 
	BNE @MULT
@SKMULT 
	STA (OFFSET),Y
	JSR _GENHEAL
	INY 
	STA (OFFSET),Y ;random health
	STY FVAR2
	LDY #$05
	LDA (OFFSET),Y
	TAX
	JSR _GENMONEY
	LDY FVAR2
	INY 
	STA (OFFSET),Y ;random funds
@SKIPBON 
	INY
	LDA #$FF
	JSR _RNG
	STA (OFFSET),Y ;random profile
	
@ROLLVP
	JSR _RANDSTATE
	INY
	STA (OFFSET),Y
	
	LDY #PRIMDATC
	LDX #$01
	JSR _OFFSET
	LDY FVAR2

	DEC FVAR1
	BEQ @RTS
	JMP @TOP
@RTS 
	RTS 

;generate_random_health()
_GENHEAL
	LDA #$20
	JSR _RNG
	RTS
;generate_random_money(X = CORP)
_GENMONEY
	LDA #$20
	JSR _RNG
	
	CPX #$07
	BEQ @BONUS1
	CPX #$08
	BEQ @BONUS2
	BNE @BONVAL
@BONUS1 
	CLC
	ADC #30
	BNE @BONVAL
@BONUS2 
	CLC
	ADC #70
@BONVAL
	RTS
	
;issue_candidate_X() 
;generates issue value for selected party
;LOCAL: FRET3
_ISSUECD 
	JSR _ISSUECS
	JSR _ISSUECS
	JSR _COINFLIP
	BEQ @SKIP
	DEC FRET3
@SKIP 
	RTS 
_ISSUECR 
	JSR _ISSUECD
	INC FRET3
	INC FRET3
	RTS 
_ISSUECS 
	JSR _COINFLIP
	CLC 
	ADC FRET3
	ADC #$01
	STA FRET3
	RTS 
_ISSUECP 
	JSR _ISSUECS
	INC FRET3
	INC FRET3
	INC FRET3
	INC FRET3
	RTS 
_ISSUECI 
	JSR _COINFLIP
	CLC 
	ADC #$03
	STA FRET3
	RTS 
_ISSUECW 
	TYA 
	SEC 
	SBC #$06
	TAX 
	LDA V_MAX,X
	STA FRET3
	RTS 
;regional issue(FVAR5 = home state) 
;takes values from home state
;LOCAL: FY1
_ISSUECREG
	+__O2O2 ;store offset
	STY FY1
	LDA FVAR5
	JSR _CPOFFS
	LDA FY1
	SEC
	SBC #$06 ;the current generated candidate offset
	TAY
	LDA (IS_ADDR),Y
	STA FRET3
	+__O2O
	LDY FY1
	RTS

;issue_select() 
;chooses which party to select issue for
_ISSUSEL 
	JSR _ISIND
	BEQ @INDDBL
	LDA #16
	JMP @DBL
@INDDBL
	LDA #32
@DBL
	JSR _RNG
	BNE @ISSUEX
	LDA #ISSUEX
	STA FRET3
	BNE @RTS
@ISSUEX
	LDA #128
	JSR _RNG
	BNE @ISSUEN
	LDA #ISSUEN
	STA FRET3
	BNE @RTS
@ISSUEN
	
	LDA V_PARTY
	BNE @REP

	JSR _ISSUECD
	RTS 
@REP 
	CMP #$01
	BNE @4P
	JSR _ISSUECR
	RTS 
@4P 
	CMP #$03
	BNE @3P
	JSR _ISSUECS
	RTS 
@3P 
	LDA S_PLAYER
	CMP #$04
	BNE @WOR
	JSR _ISSUECP
	RTS 
@WOR 
	LDA S_3PMODE
	BEQ @IND
	JSR _ISSUECW
	RTS 
@IND 
	JSR _ISSUECI
@RTS
	RTS 
;apply modifiers to issues
;FRET3 = base issue value
_ISSUSEL2
	LDX FRET3
	CPX #ISSUEX
	BEQ @DONE
	CPX #ISSUEN
	BEQ @DONE
	
	LDA S_GMMODE
	BNE @RANDOM ;random mode
	LDA V_PARTY
	CMP #$02
	BCC @LIMITED
	LDA #$0C ;1/12 for IPS
	BNE @EXTREME
@LIMITED 
	LDA #$04 ;1/4 for DR
@EXTREME
	JSR _RNG
	BNE @DONE
	
	;+/- 
	JSR _COINFLIP
	BNE @RPLUS1
	DEX 
	JMP @DONE
@RPLUS1 
	INX 
@DONE
	TXA
	RTS
@RANDOM 
	LDA #$07
	JSR _RNG
	BEQ @RANDOM
	TAX 
	BNE @DONE
	
;generates WORKER issues
_ISSUWOR 
	JSR _MAXR
	LDA #$06
	STA FVAR2
	JSR _ISSUWOR2
	LDA #$06
	STA FVAR2
	JSR _ISSUWOR2
	LDA #$01
	STA FVAR2
	JSR _ISSUWOR2
	LDA #$01
	STA FVAR2
	JSR _ISSUWOR2
	JSR _COINFLIP
	CLC 
	ADC #$03
	STA FVAR2
	JSR _ISSUWOR2
	RTS 

_ISSUWOR2 
	LDA #$05
	JSR _RNG
	TAX 
	LDA V_MAX,X
	BNE _ISSUWOR2
	LDA FVAR2
	STA V_MAX,X
	RTS 

;convenience_char() 
;inits party single char/colors
;LOCAL: FVAR1,FVAR2
_CONVCHR 
	LDA #00
	TAX
	TAY
	STA FVAR1
	STA FVAR2
@LOOP 
	LDA D_PARTY,X
	STA V_PTCHAR,Y

	STY FVAR2
	LDY FVAR1
	LDA D_PARTY,X
	STA V_PTCHR3,Y
	LDA D_PARTY+1,X
	STA V_PTCHR3+1,Y
	LDA D_PARTY+2,X
	STA V_PTCHR3+2,Y
	LDA #00
	STA V_PTCHR3+3,Y
	INY 
	INY 
	INY 
	INY 
	STY FVAR1
	LDY FVAR2

	TXA 
	CLC 
	ADC #PARTYNAMELEN
	TAX 
	INY 
	CPY #$06
	BNE @LOOP
	RTS 

;copies colors from data to var
_COPYCOL 
	+__LAB2A2 D_PTCOL2,V_PTCOL
	LDA #$07
	STA FARG5
	JSR _COPY
	RTS 

;3_player_setup() 
;switches PAT to IND/WOR
_SETUP3P 
	LDA S_PLAYER
	CMP #$03
	BEQ @CONTIN
	RTS
@CONTIN
	LDA S_3PMODE
	BNE @WORKERS

	LDA V_PTCOL+5
	STA V_PTCOL+2

	+__LAB2A2 IND3,PAT3
	LDA #PARTYNAMELEN
	STA FARG5
	JSR _COPY ;copy INDEPENDENT over PATRIOT
	JMP @INDEPEN
@WORKERS 
	LDA V_PTCOL+6
	STA V_PTCOL+2

	+__LAB2A2 WOR3,PAT3
	LDA #PARTYNAMELEN
	STA FARG5
	JSR _COPY ;copy WORKERS over PATRIOT
@INDEPEN
	;target megastates
	RTS 

;init_cp_ec() 
;LOCAL: FVAR1-3
_INITCP 
	JSR _CPOFFR ;reset cp_addr
@LOOP1
	LDX CPSTATE
	LDA D_INITCP-1,X
	STA FVAR3 ;state leans
	LSR 
	LSR 
	LSR 
	LSR 
	AND #$0F
	STA FVAR1 ;D LEAN
	
	LDA FVAR3
	AND #$0F
	STA FVAR2 ;R LEAN

	JSR _INITCP2 ;3/4 player cp
	JSR _CPOFFI ;inc addr
	BNE @LOOP1
	
	LDA S_PLAYER
	CMP #03
	BNE @SKIPBAL
	LDA S_GMMODE
	BNE @SKIPBAL
	JSR _3PBALANCE
@SKIPBAL
@RTS
	RTS 
;sets all state leans (skips 2P if >3P, as they've already been loaded)
_INITCP2
	LDY #CPBLEAN
	
	LDA S_PLAYER
	CMP #03
	BCS @4P
	
	LDA FVAR1
	STA (CP_ADDR),Y
	LDA FVAR2
	INY
	STA (CP_ADDR),Y
	RTS
@4P
	BEQ @3P
	
	INY
	INY
	LDA FVAR2
	STA (CP_ADDR),Y
	INY
	LDA FVAR1
	STA (CP_ADDR),Y
	RTS
@3P
	LDA FVAR1
	CMP FVAR2
	BEQ @DEM
	BCS @DEM
@REP
	LDA FVAR2
@DEM
	STA FVAR3
@3PAPPLY
	LDY #CPBLEAN+2
	LDA FVAR3
	STA (CP_ADDR),Y
	RTS

;state_lean_even(CP_ADDR set, FVAR7 = times to run)
;moves state leans towards value 7
_SLEVEN
@PARTCOUNT
	LDY #CPBLEAN
@PLAYLOOP
	LDA (CP_ADDR),Y
	BEQ @SKIP
	CMP #07 ;draw towards even
	BEQ @SKIP
	BCC @PLUS
	SEC
	SBC #01
	STA (CP_ADDR),Y
	JMP @SKIP
@PLUS
	CLC
	ADC #01
	STA (CP_ADDR),Y
@SKIP
	INY
	CPY #CPBLOCK
	BNE @PLAYLOOP
	DEC FVAR7
	BNE @PARTCOUNT
	RTS
;init_cp_issues() 
;issue-based state leans
_INITCPI 
	LDA #00
	STA V_PARTY
	JSR _CANDLOAD
	JSR _CPOFFR
@LOOP2 
@LOOP1 ;get party offset
	LDA V_PARTY
	CLC 
	ADC #CPBLEAN
	STA FY1
	;get issue bonus
	LDA CPSTATE
	STA FARG1
	LDA #00
	STA FRET1

	JSR _CISSUEB
	LDA FRET1
	LSR ;state lean = 1 + issue bonus / 2
	CLC
	ADC #07
	LDY FY1
	STA (CP_ADDR),Y
	;starting CP = new state lean
	JSR _CANDSWAP
	LDA V_PARTY
	BNE @LOOP1
	JSR _CPOFFI
	BNE @LOOP2
	;reset loaded party
	LDA #00
	STA V_PARTY
	JSR _CANDLOAD

	RTS 

;candidate_secondary_stat_calc() 
_CANDSSC 
	JSR _CANDSS2
	JSR _CANDSS1
	RTS 
_CANDSS1 
	LDA C_MONEY
	CLC 
	ADC #$20
	CLC 
	ADC C_FUND
	ADC C_FUND
	CLC 
	ADC C_INTL
	STA C_MONEY

	LDA C_STAM

	ASL 
	ASL 
	ADC #$09
	SEC 
	SBC C_NETW
	STA C_STR
	LDA C_HEALTH
	CLC 
	ADC #$18
	ASL 
	CLC 
	ADC C_STR
	STA C_HEALTH

	LDA C_CHAR
	CLC 
	ADC C_NETW
	LDX C_CORP
	DEX 
	CLC 
	ADC D_TVCORP,X
	BPL @TVNEG
	LDA #$01
@TVNEG 
	STA C_TV
	LDA #00
	CLC 
	ADC C_STAM
	ASL 
	ADC C_INTL
	STA C_LMIN
	LDA C_HOME
	JSR _STATEGR
	STX C_IREG
	STX C_CREG
	RTS 
;for incumbent bonus recalculation
_CANDSS2 
	LDA C_CHAR
	ASL 
	CLC 
	ADC C_INTL
	STA C_CER
	LDA C_INCUMB
	AND #$0F
	TAX 
	LDA D_INCCER,X
	CLC 
	ADC C_CER
	STA C_CER ;add INCUMBENT bonus

	LDA C_CORP
	CLC 
	ADC C_NETW
	ASL 
	CLC
	ADC C_CORP
	STA C_FUND

	LDA C_INCUMB
	AND #$0F
	TAX 
	LDA D_INCFND,X
	CLC 
	ADC C_FUND ;add INCUMBENT bonus
	STA C_FUND

	RTS 
	
;setup_hq
_SETUPHQ
	LDA #00
	LDX #01
@LOOP
	STA V_HQ,X
	INX 
	CPX #STATE_C
	BNE @LOOP
	RTS