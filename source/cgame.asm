;cgame.asm
;CAMP11 
;main game loop

_START 
	JSR _SPRINIT
	JSR _CLRFAC	
	JSR _SFXINIT
	JSR _RNGINIT
	
	LDA #$80
	JSR _RNG ;seed
	
	JSR _GX_INIT
	JSR _GX_CLRS
	JSR _PRETITL
	JSR _SETUP
	JSR _CLR_T2
	JSR _CLRBR
	JSR _CANDSEL
	JSR _AITOP
	JSR _OVERKILL
	JSR _ALLAICHK
	JSR _SKIPCHK
	JSR _CLRVISLOG

	LDA S_GMMODE
	BEQ @SKIPR
	JSR _INITCPI
@SKIPR 
	
	JSR _PLURAL
	JSR _FPNCHKA
	
	JSR _GX_CLRS
	JSR _DRWBORD
	
	JSR _PRECAMP
	
	LDA #00
	STA V_REDRW1

	JSR _GAME
	JSR _SAVEHIS
	JSR _PSTCAMP
	
	LDA #$01
	STA V_GAMEOV
	
	JSR _FINALCP
	JSR _ERESET
	JSR _DOMCHECK
	
	LDA #00
	STA V_SUMFH
	
	LDA S_QUICKG
	BNE @SKIP
	JSR _RESULTS
@SKIP
	LDA #00
	STA S_SKIPGAME
	JSR _MAPCOL
	LDA #00
	STA V_SUMFH
	JSR _POPCMB3
	JSR _ENDMENU

	RTS 

;pretitle() 
;clears vars
_PRETITL 
	+__LAB2O BASE2
	LDY #00
@INCLOOP 
	LDA #00
@LOOP 
	STA (OFFSET),Y
	INY 
	BNE @LOOP
	INC OFFSET+1
	LDA OFFSET+1
	CMP #>BASE4
	BNE @INCLOOP

	LDA #00
	STA SAVESEL
	STA GX_PCOL
	STA GX_BCOL
	STA GX_X
	STA GX_Y
	STA GX_XO
	STA GX_XP
	STA GX_XB
	STA GX_YO
	STA GX_LX1+1
	STA GX_LX2+1
	STA MAP_COL
	STA MAP_ROW
	STA MAP_HELD
	STA MAP_RES

	LDX #01
@REVLOOP
	LDA #C_DGRAY
	STA V_STCOL,X
	INX 
	CPX #STATE_C
	BNE @REVLOOP
	
	RTS 

;setup() 
;pre-game setup routines
_SETUP 
	LDA #$40
	ORA KEYREP

	AND #$7F
	STA KEYREP ;turn key repeating off

	JSR _COPYCOL
	JSR _CHARSET
	LDA #02
	STA S_PLAYER ;set up for title
	JSR _SETPLIM
	JSR _SETUPPN
	JSR _INITCP ;set up cp for title map
	JSR _ISSUES
	JSR _INITEC
	JSR _MAPCMB1

	JSR _DRW_T2
	JSR _DRWTITLE
	JSR _ATTRACT
	JSR _SETUPHQ
	JSR _TITLE
	
	JSR _DRWRATSMENU
	JSR _DRWUNDMENU
	JSR _MAPSETCALC
	
	JSR _INITCP ;again for >2 players
	JSR _SETUP3P
	JSR _CONVCHR
	JSR _EVENPERC
	
	JSR _COINFLIP
	CLC
	ADC #EVENT_MAJOR
	STA V_EVBIG
	
	LDA #01
	STA V_MOE ;for showing swing (EVEN SL) states only
	
	LDA #00
	STA V_PARTY
	STA V_WEEK
	STA V_SUMFH
	JSR _MAPCMB2
	JSR _FTC
	RTS 

;game() 
;main campaigning loop
;LOCAL: FVAR4
_GAME 
	JSR _SETMOE
	LDA V_PARTY
	BNE @SKIPW
	INC V_WEEK
	LDA V_WEEK
	CMP #WEEKMAX+1
	BNE @SKIPW
	RTS 
@SKIPW
	LDA #P_MENUR3
	STA SAVESEL ;action menu selection reset

	LDA V_WEEK
	BEQ @WEEK0
	LDA V_PARTY
	BNE @SKIPHIS
	JSR _HQAPPLY
	JSR _DCHECK
	JSR _ECHECK
	JSR _SAVEHIS
	
	LDA V_WEEK
	CMP #01
	BNE @SKIPSC
	JSR _SWINGCT
@SKIPSC
	
	JSR _HSOFFS
	
	LDA V_WEEK
	CMP #$02
	BCC @SKIPCHK
	JSR _NGLCHECK
@SKIPCHK

	LDA #01
	STA V_POLLON
	LDA #00
	STA V_RANDCP
	STA V_SUMFH
	JSR _STCTRL ;calculate control values without random CP
	LDA #00
	STA V_POLLON
	
@SKIPHIS
@WEEK0

	LDA V_PARTY ;at the start of the week, redraw the whole map
	BNE @SKIPST
	LDA #00
	STA V_SUMFH
	STA V_POLLON
	LDA #01
	STA V_RANDCP
	JSR _MAPCMB2
	JMP @DONECTRL
@SKIPST
	LDA V_POLLON ;for any player after the first, if the last player POLLED, revert the map to normal
	BEQ @DONECTRL
	LDA #00
	STA V_POLLON
	JSR _MAPCMB3
@DONECTRL

	LDA #00
	STA V_POLLON
	JSR _POPCMB2
	
	LDA C_MONEY ;staff out check
	CMP #$0A
	BCC @NOMONEY
	LDA #00
	BEQ @MONEY
@NOMONEY 
	LDA #$01
@MONEY 
	STA V_OUTOFM
	STA V_STAFFOUT
	STA V_HQBUILT
	
	LDX V_PARTY
	LDA V_AUTOSTAFF,X
	BEQ @AUTOSTAFF
	LDA #00
	STA V_STAFFOUT
@AUTOSTAFF
	
	JSR _RMENUGRAY

	LDA V_WEEK ;last week check
	CMP #$09
	BNE @FINWEEK
	LDA #01
	STA S_MBLANK
@FINWEEK 
	JSR _CLRPOLL ;reset polled regions
	
	LDA #$01
	STA V_REDRW2
	LDA C_IREG
	STA C_CREG
	
	LDA S_SKIPGAME
	BNE _SKIPGAME
	LDA S_QUICKG
	BNE @SKIPMUS
	JSR _DCLRMR
	JSR _CLRBR
	JSR _DUPNEXT
	JSR _MUSIC
@SKIPMUS
	
	JSR _EVENTCAND

_GAMERP ;replan
	JSR _RESETVB
	JSR _FILLVB
	
	JSR _DRWCAND
_GAMECS ;clear schedule
	LDA C_IREG
	STA C_CREG
	LDX C_SCHEDC
	STX V_SCHEDC
	JSR _DRWWSCH
	JSR _SCHCLR
_GAMEKS ;keep schedule
	JSR _INITFH
	JSR _SCHCOPY
	JSR _RMENUGRAY
_GAME3 ;draw right menu, select action
	JSR _DRWSTAF
	JSR _DRWMENR
	JMP _GAME4
_SKIPGAME
	LDA V_WEEK
	ORA #NUMBERS
	STA GX_CIND
	LDA #00
	STA GX_CROW
	STA GX_CCOL
	JSR _GX_CHAR
_GAME4 
	JSR _AI
	BEQ @SKIPENT
	JMP @NOCONF
@SKIPENT 

@SELECT 
	LDX #P_MENUR3
	LDY #P_MENUR4
	LDA SAVESEL
	STA FRET1
	JSR _RSEL6 ;start at savesel
	TAX 
	STA FVAR4
	CLC 
	ADC #P_MENUR3

	STA SAVESEL

	LDA FVAR4
@VISIT 
	BNE @TVADS
	JSR _CLRMENR
	+__LAB2XY T_VISIT
	+__COORD P_VISITR,P_VISITC
	JSR _GX_STR

	LDA C_CREG
	JSR _DRWREGS
	
	LDA #P_VISITR
	STA VISSAVE ;saved row for RSELECT
@VISEL
	LDA VISSAVE
	STA FRET1

	LDA C_SCHEDC
	CMP #$07
	BNE @VICONT
	JMP @FTC
@VICONT 

	LDX C_CREG
	LDA D_REGC-1,X
	CLC 
	ADC #P_VISITR
	TAY
	LDX #P_VISITR
	JSR _RSEL6
	PHA
	
	LDA FRET1
	CLC
	ADC #P_VISITR
	STA VISSAVE
	PLA
	
	BNE @VISTATE
	JMP _GAME3 ;menu
@VISTATE
	SEC 
	SBC #$01
	LDX C_CREG
	CLC 
	ADC D_REGLIM-1,X
	STA FARG1

	LDA FVAR4
	JSR _SCHADD
	JSR _DRWVBON
	JMP @VISEL
@TVADS 
	DEX
	BNE @FUNDR
	JMP @ENTER
@FUNDR 
	DEX
	BNE @REST
	JMP @ENTER
@REST 
	DEX
	BNE @MAP
	JMP @ENTER
@MAP 
	DEX
	BNE @NEWS
	JSR _MAP
	JMP _GAME4
@NEWS
	DEX
	BNE @POLL
	JSR _EDRAW
	JSR _MAPCMB1
	JMP _GAMEKS
@POLL 
	DEX
	BNE @HQ

	LDA V_OUTOFM
	BNE @POLLDON

	LDX C_CREG
	LDA V_POLL-1,X
	BNE @NOCOST
	
	LDA C_MONEY
	CMP #STAFF_COST
	BCC @POLLDON
	JSR _POLLCOST
	STA C_MONEY
@NOCOST
@GPOLL
	LDA V_POLLON
	BNE @SKIPCTRL
	LDA #01
	STA V_POLLON
	STA V_SUMFH ;sum from history ON
	JSR _MAPCMB3
	JSR _POPCMB2
@SKIPCTRL
	
	LDX C_CREG
	INC V_POLL-1,X
	JSR _DRWRATING
	JSR _CLRBL2
	
	LDA #00
	STA V_REDRW1
	INC V_POLLCT

@POLLDON
	JSR _DRWCAND
	JMP _GAMEKS
@HQ
	DEX
	BNE @UNDO

	LDA V_OUTOFM
	BNE @HQDONE
	LDA V_HQBUILT
	BNE @HQDONE
	LDA C_MONEY
	CMP #STAFF_COST
	BCC @HQDONE
	
@STATESEL
	JSR _MAP
	LDA MAP_RES
	BEQ @HQDONE
	TAY
	JSR _HQPLUS
	BEQ @HQDONE
	
	LDA #01
	STA V_HQBUILT
	
	JSR _HQCOST
	JSR _DRWCAND
	JSR _MAPINFO
@HQDONE
	JMP _GAMEKS
@UNDO
	DEX 
	BNE @REPLAN
@UNDO2	
	LDA C_SCHEDC
	BEQ @NOCLEAR
	
	LDX V_PARTY
	LDA V_STLOCK,X
	BEQ @LOCKCHK
	LDA C_SCHEDC
	CMP #03
	BCC @NOCLEAR
@LOCKCHK
	
	JSR _SCHDRW3
	DEC C_SCHEDC
	DEC V_SCHEDC
	
	LDX C_SCHEDC
	LDA V_CPGPTRO,X
	STA V_CPGPTR
	
	LDX C_SCHEDC
	LDA V_SCHEDVB,X
	STA V_VBONUS
	JSR _DRWVBON
@NOCLEAR
	JMP _GAME3
@REPLAN 
	DEX
	BNE @TRAVEL
	JSR _FTC
	BNE @NORP
	LDA #00
	STA C_SCHEDC
	JMP _GAMERP
@NORP 
	JMP @SELECT
@TRAVEL 
	JSR _DRWREGM
	LDX #P_REGLSR2
	LDY #P_REGLSR3
	JSR _RSELECT
	TAX 
	CPX #$09
	BNE @SKIPMEN
	JMP _GAME3
@SKIPMEN 
	INX 
	TXA 
	STA C_CREG
	JMP _GAME3
@ENTER 
	LDA FVAR4
	JSR _SCHADD

	LDA C_SCHEDC
	CMP #$07
	BEQ @FTC
	JMP @SELECT
@FTC
	JSR _FTC
	BEQ @CONFIRM
	JMP @UNDO2
@CONFIRM 
	LDA V_VBONUS
	STA C_VBONUS
	LDA C_CREG
	STA C_IREG
	
	JSR _SCHEXE
	JSR _SCHSAV
	JSR _CANDSWAP
	
	LDA #00
	STA C_SCHEDC
	LDX V_PARTY
	STA V_STLOCK,X
	STA V_RALLYDEATH,X
	JMP _GAME
@NOCONF ;for ai
	LDA S_QUICKG
	BNE @CONFIRM
	JSR _FTC
	JMP @CONFIRM

_CLRTITLE
	LDA #30
	STA GX_LX1
	LDA #40
	STA GX_LX2
	LDA #00
	STA GX_LY1
	LDA #18
	STA GX_LY2
	JSR _GXRECTC

_DRWTITLE
	LDA #C_DRED
	STA GX_DCOL
	+__COORD P_TOP,P_TITLEC
	
	+__LAB2XY T_TITLE
	JSR _GX_STR
	RTS

;title() 
;draws the title settings menu
;processes results
_TITLE
	LDX #00
	TXA
@CLR
	STA V_SETTEMP,X
	INX
	CPX #SETTINGC
	BNE @CLR
@SETTING
	JSR _CLRTITLE
	JSR _DRWTITLE
	
	LDA #$02
	STA S_PLAYER
	LDA #$01
	STA V_SETTEMP+1 ;used for temporary storage
	JSR _DRWSETG
	
	LDA #P_SETTR
	STA SAVESEL
@SELECT
	
	LDX #P_SETTR
	LDY #P_SETTR2
	LDA SAVESEL
	STA FRET1
	JSR _RSEL6
	PHA
	LDA FRET1
	CLC
	ADC #P_SETTR
	STA SAVESEL
	PLA
	
	TAX
	BEQ @SKIPPLY
	LDA V_PLAYNAME-1,X
	EOR #%00000001
	STA V_PLAYNAME-1,X
@SKIPPLY
	TXA
	
	CMP #$02
	BCS @DONECHK
	CMP #$01
	BEQ @GAMEMODE
	
	INC S_PLAYER
	LDA S_PLAYER
	CMP #$05
	BEQ @WRAP
	BNE @PLAYSET
@WRAP
	LDA #$02
@PLAYSET
	STA S_PLAYER
	JSR _SETPLIM

	LDA #C_WHITE
	STA GX_DCOL
	+__COORD P_SETTR,P_RSELC
	LDA S_PLAYER
	ORA #NUMBERS
	JSR _GX_STR2
	
	JMP @SELECT
@GAMEMODE
	LDA #C_WHITE
	STA GX_DCOL
	+__COORD P_SETTR+1,P_RSELC
	LDA V_PLAYNAME+0
	BNE @RAND
	+__LAB2XY T_GMPARTY
	JMP @DRW
@RAND
	+__LAB2XY T_GMRAND
@DRW
	JSR _GX_STR
@DONEDRW
	JMP @SELECT

@DONECHK
	CMP #SETTINGC+1
	BEQ @FTC
	JSR _DRWSETG
	JMP @SELECT
@FTC
	JSR _DRWSETG
	JSR _FTC
	BEQ @CONF
	JMP @SETTING
@CONF
	LDX #$00
@SETLOOP
	LDA V_SETTEMP,X
	STA S_SETTING,X
	INX
	CPX #SETTINGC
	BNE @SETLOOP
	
	JSR _3PPARTY
	RTS 

;end_menu()
_ENDMENU
	JSR _CLRBL
	JSR _MAPCMB1
	
	JSR _DRWPOP
	JSR _CLRBR
	JSR _DRWPOPF
	
	LDA V_MUSFLAG
	BNE @SKIPMUS
	LDA V_WINNER
	STA V_PARTY
	JSR _MUSIC
	LDA #01
	STA V_MUSFLAG
@SKIPMUS
	+__COORD P_ENDMNR,P_ENDMNC
	+__LAB2XY T_ENDMNU
	JSR _GX_STR
	LDX #$11
	LDY #$14
	JSR _RSELECT
	TAX
	
	BNE @DETAILED
	JSR _RESULTS
	JMP _ENDMENU
@DETAILED 
	DEX 
	BNE @PLAYERS
	JSR _MAP
	LDA MAP_RES
	BEQ @SKIP
	CMP #STATE_C
	BCS @SKIP

	STA FSTATE
	JSR _DETAIL
	JSR _FTC
	JSR _GX_CLRS
@SKIP 
	JMP _ENDMENU
@PLAYERS
	DEX
	BNE @ACTLOG
	JSR _CLRBL
	JSR _CANDLOOP
	JMP _ENDMENU
@ACTLOG
	JSR _ACTLOG
	JMP _ENDMENU
	
	