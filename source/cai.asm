;cai.asm
;CAMP05 
;AI routines

;main check routine
;ignores if human player, enters schedule if AI
;returns A = ai schedule was entered
_AI 
	LDX V_PARTY
	LDA V_AI,X
	STA SAVEAI
	BEQ @RTS
	JSR _CLRPOLL
	LDA SAVEAI
	CMP #AIHARD1
	BCS @HARD
	JSR _EASY
	BNE @RTSAI
@HARD
	JSR _HARDAI
@RTSAI
	LDA #01
	RTS 
@RTS 
	RTS 

;easy_ai() 
_EASY 
	JSR _SCHCLR
	;set random region
	LDA #$09
	JSR _RNG
	CLC 
	ADC #$01
	STA C_CREG

	LDA #ACT_REST
	JSR _SCHADD
	LDA #ACT_REST
	JSR _SCHADD
	;rest twice
	LDA #ACT_FUNDR
	JSR _SCHADD
	LDA #ACT_FUNDR
	JSR _SCHADD
	;fundraise twice
@VISIT 
	LDX C_CREG
	DEX 
	LDA D_REGC,X
	JSR _RNG
	LDX C_CREG
	CLC 
	ADC D_REGLIM-1,X
	STA FARG1
	LDA #ACT_VISIT
	JSR _SCHADD

	LDA C_SCHEDC
	CMP #$06
	BNE @VISIT
	;campaign in two random states
	LDA #ACT_TVADS
	JSR _SCHADD
	;tv ads in region
	LDA #01
	RTS 

;generic_hard_ai()
_HARDAI
	JSR _AICLRP
	
	JSR _AIHLIST
	JSR _AIPLURAL
	JSR _AIPOLL
	JSR _AIHLMULT
	JSR _AIHQ
	
	JSR _SCHCLR
	
	;store top priority
	LDA V_PRIORI
	LDX V_PARTY
	STA V_AITOP,X
	;var init
	LDA #00
	STA FAI
	STA FAIPTR
	STA FAITV

	;AUX REST/FUNDR ON EVEN WEEKS
	JSR _AIHAUX
	;MAIN LOOP
@LOOP1

	LDA V_CPGPTR
	STA FAIPTR
	
	;WARNING PREVENTION	
	JSR _NOTLAST
	BNE @SKIPPREV
	JSR _LDAPCFC 
	CMP #20
	BCC @FUNDR 
	JSR _LDAPCHC
	CMP #20
	BCC @REST
@SKIPPREV
	
	JSR _AITVADS ;do a TV ADS check
	BNE @FULL
	
	LDX FAI
	LDA V_PRIORI,X
	BEQ @INC
@VISIT
	STA FARG1
	LDA V_VBONUS
	AND #$7F
	CMP FARG1
	BNE @NOPENAL
	LDA V_VBONUS
	BPL @NOPENAL ;if VISIT penalty
	JMP @INC
@NOPENAL
	LDA FARG1
	JSR _AISETREG

	LDA #ACT_VISIT
	JSR _SCHADD
	
	LDA C_SCHEDC
	CMP #$01
	BNE @TWICE ;visit highest-priority state twice on odd weeks (not week 1, and if TV ADS is not first)
	LDA V_WEEK
	CMP #$01
	BEQ @TWICE
	LDA FARG1
	JMP @VISIT
@TWICE
	JMP @INC

@FUNDR
	LDA #ACT_FUNDR
	JSR _SCHADD
	JMP @FULL
@REST 
	LDA #ACT_REST
	JSR _SCHADD
	JMP @FULL
@INC 
	INC FAI
	LDA FAI
	CMP #AISTATE
	BNE @DECPRI
	DEC FAIPRI
	LDA #$00
	STA FAI
@DECPRI
@FULL
	JSR _SCHFULL
	BEQ @DONE
	JMP @LOOP1
@DONE 
	RTS 
	
;normal_ai_tv_ads()
;decides how many TV ADS to run at start of WEEK
_AITVADS
	LDA V_WEEK
	AND #%00000001
	BEQ @FAIL ;odd weeks only
	LDA FAITV
	CMP V_TVMAX ;TV ADS limit
	BCS @FAIL
@LOOP
	LDX FAITV
	LDA V_PRIORI+STATE_C-1,X
	AND #$0F
	STA C_CREG
	LDA #ACT_TVADS
	JSR _SCHADD
	LDA V_WARN
	BEQ @INC
	DEC C_SCHEDC
	JMP @FAIL
@INC
	INC FAITV
@SUCCESS
	LDA #01
	RTS
@FAIL
	LDA #00
	RTS
	
;action_not_last()
;returns 1 if week = 9 AND schedule count = 6
_NOTLAST
	LDA V_WEEK
	CMP #$09
	BNE @FALSE
	LDA C_SCHEDC
	CMP #$06
	BNE @FALSE
	LDA #$01
	RTS
@FALSE
	LDA #00
	RTS

;clear_priority_values()
_AICLRP 
	LDA #00
	TAX 
@CLRLOOP ;for second pass ONLY
	STA V_PRIOR,X
	STA V_PRIORI,X
	INX 
	CPX #AISTATE
	BNE @CLRLOOP

	RTS 

;auxiliary_rest() 
;does REST/FUNDRAISE conditionally
_AIHAUX 
	LDA V_WEEK
	AND #$01
	BEQ @ODD
	RTS
@ODD
	
	JSR _LDAPCF
	CMP #128 ;1 if FUNDS < 128
	BCS @SECOND

	LDA #ACT_FUNDR
	JSR _SCHADD

	JSR _LDAPCF
	CMP #100
	BCS @SECOND

	LDA #ACT_FUNDR
	JSR _SCHADD

	JSR _LDAPCF
	CMP #80
	BCS @SECOND

	LDA #ACT_FUNDR
	JSR _SCHADD
@SECOND 
	JSR _LDAPCH
	CMP #128
	BCS @RTS
	
	LDA #ACT_REST
	JSR _SCHADD

	JSR _LDAPCH
	CMP #128
	BCS @RTS
	
	LDA #ACT_REST
	JSR _SCHADD
@RTS 
	RTS 

;schedule_full_check 
_SCHFULL 
	LDA C_SCHEDC
	CMP #$07
	RTS 
	
;calc_priority_list() 
;sets up all indexes in V_PRIORI, initial V_PRIOR for state ONLY
_AIHLIST
	LDA #00
	TAY
	STA V_PRIORI+AISTATE
	STA FAI
	STA V_POLLCT
	
	LDX #01
@SLOOP

	TXA 
	STA V_PRIORI,Y
	INY 
@SKIPSTA 
	INX
	INC FAI
	CPX #STATE_C
	BNE @SLOOP

	LDX #01
@TVINIT 
	TXA 
	ORA #$F0
	STA V_PRIORI,Y
	INX
	INY
	INC FAI
	CPX #REGION_C+1
	BNE @TVINIT
	
	LDA FAI
	STA V_PRIORI+AISTATE+1 ;index count
	STA FAISUM ;temp hold for above
;calculate initial priority values
	LDA #01
	STA V_SUMFH
	LDA #00
	STA FAI
@STALOOP
	JSR _HSOFFR ;set to WEEK 1 to get initial SL
	LDX FAI
	LDA V_PRIORI,X
	BMI @SKIPTV
	STA FARG1
	TAX
	JSR _HSOFFS2
	LDA FARG1
	JSR _CPOFFS ;for issue bonus only
	
	JSR _MAXR
	JSR _COPYLEAN
	JSR _LEANTOMAX
	JSR _MAX2
	LDY V_PARTY
	LDA V_LEAN,Y
	SEC
	SBC MAXLOW ;SL value = (15 + [for state] (my SL - max SL))
	CLC
	ADC #$0F
	STA FVAR1 ;total
	
	LDX FARG1
	LDA V_EC,X
	LSR
	LSR
	LSR
	CLC
	ADC FVAR1
	STA FVAR1
	
	JSR _CISSUEB
	LDA V_IBONUS
	LSR
	LSR
	CLC
	ADC FVAR1
	STA FVAR1
	
	+__LAB2O V_VISLOG
	LDX V_PARTY
	LDY #STATE_C-1
	JSR _OFFSET
	LDY FARG1
	DEY
	LDA FVAR1
	SEC 
	SBC (OFFSET),Y
	SBC (OFFSET),Y
	BCS @CARRY
	LDA #00
@CARRY
	
	LDX FAI
	STA V_PRIOR,X
@SKIPTV
	INC FAI
	LDA FAI
	CMP FAISUM
	BNE @STALOOP

	RTS

;calculates and applies multipliers, sorts
_AIHLMULT
	LDA #00
	STA FAI
@PASS1
	LDA #00
	STA FAIMUL
	LDX FAI
	LDA V_PRIORI,X
	BMI @TVADS
	
	STA FSTATE
	JSR _CPOFFS
	
	JSR _MULTSWING
	STX V_AITVADS
	JSR _MULTLEAN
	STX V_AITVADS+1
	JSR _MULTCTRL
	STX V_AITVADS+2
	JSR _MULTEC
	
	JSR _AITVPRI
	
	;if normal AI or OVERKILL is true, ignore previous multipliers and just use EC / current control
	LDX V_PARTY
	LDA V_OVERKILL,X
	BEQ @KEEPMULT
	LDA SAVEAI
	CMP #AIHARD1
	BNE @KEEPMULT
	LDA #00
	STA FAIMUL
	JSR _MULTEC
	LDX V_AITVADS+2 ;state control result
	JSR _MULTCTRL3
@KEEPMULT
	
	LDX FAI
	LDA V_PRIOR,X
	STA FVAR1
;execute multipliers (negative: halve that many times, zero: nothing, positive: multiply that many times)
@MULTIPLY
	LDX FAIMUL
	BEQ @SKIPMUL ;skip if no multiplier
	BMI @LESS
	LDA FVAR1
@2XLOOP 
	CLC 
	ADC FVAR1
	BCC @NOWRAP
	LDA #$FF ;cap priority at #$FF 
@NOWRAP 
	DEX 
	BNE @2XLOOP
	BEQ @DONEMUL
@LESS 
	LDA FVAR1
@12XLOOP 
	LSR 
	INX 
	BNE @12XLOOP
	CMP #00
	BNE @DONEMUL
	LDA #01
@DONEMUL 
	STA FVAR1
@SKIPMUL 
	LDA FVAR1
	LDX FAI
	STA V_PRIOR,X
	
	JMP @INC
@TVADS
	;skip on pass 1
@INC
	INC FAI
	LDA FAI
	CMP V_PRIORI+AISTATE+1
	BEQ @DONE
	JMP @PASS1
@DONE
	JSR _AISORT
	
	;divide TV priorities by region's state count, then multiply by 10 to increase precision
	LDA #01
	STA FSTATE ;region
@AVG
	LDX FSTATE
	LDA V_PRIOR+STATE_C-2,X
	BMI @ZERO
	TAY
	LDA #00
	JSR _162FAC
	JSR _FAC2ARG
	LDX FSTATE
	LDA D_REGC-1,X
	TAY
	LDA #00
	JSR _162FAC
	JSR _DIVIDE
	JSR _FMUL10
	JSR _FAC216
	
	TYA
	LDX FSTATE
	CLC
	ADC V_REGISS-1,X ;region issue bonus sum (for breaking ties)
	BNE @NONZERO
@ZERO
	LDA #00
@NONZERO
	STA V_PRIOR+STATE_C-2,X
	
	INC FSTATE
	LDA FSTATE
	CMP #REGION_C+1
	BNE @AVG

	;sort calculated TV ADS priorities	
	LDA #STATE_C-1
	STA FARG4
	LDA #REGION_C+STATE_C-1
	STA FVAR3
	JSR _AISORT2
	
	RTS

;ai_tv_ads_priority()
;applies TV ADS priority for FSTATE
;if swing state, then use CTRL table 2; else if lean >= max then use CTRL table 1, else -1
_AITVPRI
	LDA FSTATE
	JSR _STATEGR
	STX FX1

	LDA V_AITVADS
	BEQ @LEAN
	LDX V_AITVADS+2
	LDA D_AITVADS+3,X
	JMP @ADD
@LEAN
	LDA V_AITVADS+1
	CMP #02
	BNE @NEG
	LDX V_AITVADS+2
	LDA D_AITVADS,X
	JMP @ADD
@NEG
	LDA #$FF
@ADD
	STA FRET1
	LDX FX1
	LDA V_PRIOR+STATE_C-2,X
	CLC
	ADC FRET1
	STA V_PRIOR+STATE_C-2,X
	
	LDA #00
	STA FRET1
	JSR _CISSUEB
	LDA FRET1
	LSR
	LDX FX1
	CLC
	ADC V_REGISS-1,X
	STA V_REGISS-1,X
	
	RTS

;is_independent_party()
;returns boolean (if the current party is 3P AND the game is 3P AND the gamemode is PARTIES)
_ISIND
	LDA S_GMMODE
	BNE @FALSE
	LDA V_PARTY
	CMP #$02
	BNE @FALSE
	LDA S_PLAYER
	CMP #$03
	BNE @FALSE
	LDA #$01
	RTS
@FALSE
	LDA #$00
	RTS

;swap_sort(FVAR3 = upper index; FARG4 = lower index) 
;LOCAL: FVAR1-3,FARG3-4
;sorts the priority list and its INDEX list
_AISORT ;default call
	LDA #STATE_C-1
	STA FVAR3
	LDA #00
	STA FARG4
_AISORT2
	LDA #00
	STA FVAR2 ;done

@LOOP2 
	DEC FVAR3
	LDA FARG4
	STA FVAR1 ;index
@LOOP1 
	LDX FVAR1
	LDA V_PRIOR,X
	CMP V_PRIOR+1,X
	BCS @SKIPSWAP
	+__SWAPX V_PRIOR,V_PRIOR+1,FARG3
	+__SWAPX V_PRIORI,V_PRIORI+1,FARG3
	LDA #01
	STA FVAR2
@SKIPSWAP 
	INC FVAR1
	LDA FVAR1
	CMP FVAR3
	BCC @LOOP1

	LDA FVAR2
	BEQ @DONE
	LDA FVAR3
	CMP FARG4
	BEQ @DONE
	BNE @LOOP2
@DONE 
	RTS 

;multiplier_swing_state(FSTATE = state index, CP_ADDR set)
;1 pt. for a "swing" state, which is if the state's [maximum STATE LEAN of all parties - current party's STATE LEAN] is < 2 (e.g. 8/7 for D/R, or 8/2/2/8 would be swing states for D/S); -1 otherwise
_MULTSWING
	JSR _MULTLMAX
	STA FAITV ;holds max SL index
	DEC FAITV
	LDA #$00
	TAX
	TAY
@LOOP2
	CPY FAITV
	BEQ @INC ;skip check of maximum index
	LDA MAXLOW
	SEC
	SBC V_MAX,X
	BEQ @SWINGPLUS
	CMP #$02
	BCC @SWING
@INC
	INX
	INX
	INY
	CPY S_PLAYER
	BNE @LOOP2
	LDX #00
	JMP @RESULT
@SWINGPLUS
	LDX #02
	JMP @RESULT
@SWING
	LDX #01
@RESULT
	LDA D_AI_SWING,X
	JSR _AIAPPLYM
	RTS

;multiplier_state_lean(CP_ADDR set beforehand)
;-if SL < (max SL in state), -3 pts (then, if WEEK < 4, -6 pts.); else, 0 pts.
_MULTLEAN
	JSR _MULTLMAX
	LDX V_PARTY
	LDA V_LEAN,X
	CMP MAXLOW
	BCS @OK
	LDA V_WEEK
	CMP #$04
	BCS @LATER
	LDX #00
	BEQ @DONE
@LATER
	LDX #01
	BNE @DONE
@OK
	LDX #02
@DONE
	LDA S_PARTISAN
	CMP #$01
	BEQ @HALF
	CMP #$02
	BEQ @RTS
	LDA D_AI_LEAN,X
	JMP @APPLY
@HALF
	LDA D_AI_LEAN2,X
@APPLY
	JSR _AIAPPLYM
@RTS
	RTS

;helper function for multiplier functions (moves SL from history to V_MAX and runs MAX)
_MULTLMAX
	LDA FSTATE
	JSR _STATEGR
	LDA V_POLL-1,X
	BEQ @HIST
	LDA #00 ;if the region has been polled, use the latest lean values
	BEQ @HIST2
@HIST
	LDA #01
@HIST2
	STA V_SUMFH
	JSR _HSOFFR ;set to WEEK 1
	LDX FSTATE
	JSR _HSOFFS2
	JSR _COPYLEAN
	JSR _LEANTOMAX
	JSR _MAX2
	RTS

;ai_poll()
;attempts a POLL
_AIPOLL
	LDA C_MONEY
	CMP #STAFF_COST
	BCC @RTS
	JSR _POLLCOST 
	STA C_MONEY
	
	LDX V_PARTY
	LDA V_PRIORI,X
	JSR _STATEGR
	INC V_POLL-1,X
	
	JSR _HSOFFS
	LDA #01
	STA V_POLLON
	STA V_SUMFH ;sum from history ON
	INC V_POLLCT
@RTS
	RTS
	
;calc_poll_cost(A = C_MONEY)
;returns A = C_MONEY - poll cost
_POLLCOST
	PHA
	LDA V_POLLCT
	BEQ @COST1ST
	PLA
	SEC
	SBC #02
	JMP @COST
@COST1ST
	PLA
	SEC
	SBC #07
@COST
	RTS
	
;ai_set_region(A = region)
_AISETREG
	JSR _STATEGR
	STX C_CREG
	RTS
	
;multiplier_state_control(FSTATE = state index)
;multiplier based on state control
;-state control value: -4 pts. for self, 1 pts. for opponent, 2 pts. for undecided
;additionally, if the state is a must-win, add 1 pt.
_MULTCTRL
	JSR _MULTPLUR
	JSR _AIAPPLYM
	JSR _MULTCTRL2
_MULTCTRL3
	LDA D_AI_CTRL,X
	JSR _AIAPPLYM
	RTS
_MULTCTRL2
	LDX FSTATE
	JSR _LDACTRL
	CMP V_PARTY
	BEQ @SELF
	CMP #UND_PRTY
	BEQ @UND
	LDX #01
	JMP @DONE
@SELF
	LDX #00
	JMP @DONE
@UND
	LDX #02
@DONE
	RTS 
	
;multiplier_low_ec(FSTATE = state index)
_MULTEC
	LDX FSTATE
	LDA V_EC,X
	CMP #10
	BCC @LESS
	LDX #01
	BNE @DONE
@LESS
	LDX #00
@DONE
	LDA D_AI_EC,X
	JSR _AIAPPLYM
	RTS
	
;ai_multiplier_plurality()
;return boolean [if the state is a must-win to get (total EC / player count)]
_MULTPLUR
	+__LAB2O V_AIPLUR
	LDX #AIPLURLEN
	LDY V_PARTY
	JSR _OFFSET
	LDY #00
@LOOP
	LDA (OFFSET),Y
	CMP FSTATE
	BEQ @TRUE
	INY
	CPY #AIPLURLEN
	BNE @LOOP
	LDA #00
	RTS
@TRUE
	LDA #01
	RTS
	
;ai_build_HQ()
;attempt to build an HQ if funds are sufficient, WEEK < 6, and first action was not TV ADS
_AIHQ
	LDA C_MONEY
	CMP #STAFF_COST
	BCC @RTS
	LDA V_WEEK
	CMP #06
	BCC @RTS
	LDY V_PRIORI
	BMI @RTS
	JSR _HQPLUS
	BEQ @RTS
	JSR _HQCOST
@RTS
	RTS
	
;ai_apply_multiplier()
;helper function
_AIAPPLYM
	CLC 
	ADC FAIMUL
	STA FAIMUL
	RTS 
	
;ai_plurality_list()
;makes a list of states that get the AI to (total EC / player count)
;V_PRIOR/V_PRIORI must be filled with initial values
_AIPLURAL
	LDA V_WEEK
	CMP #$01
	BNE @RTS
	
	JSR _AISORT

	+__LAB2O V_AIPLUR
	LDX #AIPLURLEN
	LDY V_PARTY
	JSR _OFFSET
	
	LDA #00
	TAX
	TAY
	STY FY1
	STX V_AIEC
	STX V_AIEC+1
@SUMLOOP
	LDY FY1
	CPY #AIPLURLEN
	BEQ @RTS
	
	LDA V_PRIORI,Y
	PHA
	TAX
	LDA V_EC,X
	CLC
	ADC V_AIEC+1
	STA V_AIEC+1
	BCC @SC
	INC V_AIEC
@SC
	PLA
	STA (OFFSET),Y
	STY FY1

	LDA V_AIEC+1
	STA V_MAX+0
	LDA V_AIEC
	STA V_MAX+1
	LDA V_PLURAL+1
	STA V_MAX+2
	LDA V_PLURAL
	STA V_MAX+3
	
	INC FY1
	JSR _MAX2
	CMP #$02
	BCS @SUMLOOP
@RTS
	RTS


