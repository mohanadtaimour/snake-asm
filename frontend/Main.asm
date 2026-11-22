; =====================================================================
; Main.asm - MEMBER 2: GAME ENTRY POINT AND MAIN LOOP
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This file owns the menu loop, timing loop and game state transitions.
; It calls the backend engine and frontend drawing procedures.
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

.data
startTime DWORD 0
prevHighScore DWORD 0
goodbyeText BYTE "Goodbye!",0

.code

;---------------------------------------------------------------------
main PROC
;
; Runs the menu, game loop, pause handling and game-over flow.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call LoadHighScore                 ; load the record once before the menu
	call StartMusic                     ; start the background music worker

MenuLoop:
	mov gameState, STATE_MENU          ; show menu state while choosing
	call DrawMenu                      ; clear and draw the menu
	call MenuInput                     ; wait for choice or difficulty selection
	cmp eax, MENU_QUIT                 ; did the player choose quit?
	je ExitGame                        ; yes: skip the new game

NewGame:
	call InitGame                      ; reset the snake and game variables
	mov eax, highScore                 ; EAX holds the record before this game
	mov prevHighScore, eax             ; remember it for the new-record check
	call DrawAll                       ; draw the complete new game once
	mov esi, 3                          ; begin the three-second countdown
CountdownLoop:
	mov eax, esi                        ; EAX holds the digit to display
	call DrawCountdown                 ; show the current countdown digit
	call PlayCountdownBeep             ; play the countdown tone
	mov eax, 800                        ; wait 800 milliseconds for this digit
	call Delay                         ; hold the digit before counting down
	dec esi                            ; select the next countdown digit
	jnz CountdownLoop                  ; display 2 and 1 after 3
	mov eax, 0                         ; zero asks DrawCountdown to erase the digit
	call DrawCountdown                 ; clear the final countdown digit
	call PlayGoBeep                    ; signal that the round is starting
DrainCountdownKeys:
	call ReadKey                       ; inspect the keyboard buffer directly
	jnz DrainCountdownKeys             ; keep draining until ReadKey sets ZF

WaitPhase:

	call GetMseconds                   ; read the millisecond clock
	mov startTime, eax                 ; remember the timing phase start

WaitLoop:
	call ReadInput                     ; drain waiting keys
	cmp gameState, STATE_PAUSED        ; did P pause the game?
	je PauseMenuFlow                   ; yes: show the pause menu
	cmp eax, INPUT_QUIT                ; did ESC stop the game?
	je QuitFromGame                    ; yes: save and return to the menu

	mov eax, 10                        ; Delay receives milliseconds in EAX
	call Delay                         ; wait briefly to avoid a tight ReadKey loop

	call GetMseconds                   ; read the current millisecond clock
	sub eax, startTime                 ; EAX is elapsed milliseconds
	cmp eax, tickDelay                 ; has one game tick elapsed?
	jb WaitLoop                        ; no: keep checking keyboard input

	call GameTick                      ; run one backend game tick
	cmp eax, TICK_DIED                 ; did the snake die?
	jne CheckEatSound                  ; no: check for an eating result
	call PlayDieSound                  ; play the death tones
	jmp GameOverScreen                 ; show the game-over screen

CheckEatSound:
	cmp eax, TICK_ATE                  ; did the snake eat this tick?
	jne CheckBonusSound                ; no: check for a bonus item
	call PlayEatSound                  ; play the eating tone
	jmp CheckTickState                 ; sound routine preserves the tick result

CheckBonusSound:
	cmp eax, TICK_BONUS                ; did the snake collect a bonus?
	jne CheckPoisonSound               ; no: check for poison
	call PlayBonusSound                ; play the bonus tone
	jmp CheckTickState                 ; sound routine preserves the tick result

CheckPoisonSound:
	cmp eax, TICK_POISON               ; did the snake collect poison?
	jne CheckTickState                 ; no: continue to state handling
	call PlayPoisonSound               ; play the poison tone

CheckTickState:
	cmp gameState, STATE_PLAYING       ; should the normal frame be drawn?
	jne WaitPhase                      ; paused: skip all incremental drawing

	call DrawFrame                     ; incrementally draw the moving snake
	jmp WaitPhase                      ; start the next timing phase

PauseMenuFlow:
	call RunPauseMenu                  ; get the selected pause-menu action
	cmp eax, PAUSE_RESUME              ; did the player choose Resume?
	je ResumeFromPause                 ; yes: return to active play
	cmp eax, PAUSE_RESTART             ; did the player choose Restart?
	je NewGame                         ; yes: initialize a new round
	jmp QuitFromGame                   ; Quit returns to the main menu

ResumeFromPause:
	call TogglePause                   ; change the state back to PLAYING
	call DrawAll                       ; redraw the board without the pause menu
	jmp WaitPhase                      ; begin a fresh game timing phase

QuitFromGame:
	call SaveHighScore                 ; save a mid-game record before leaving
	mov gameState, STATE_MENU          ; return to menu state
	jmp MenuLoop                       ; go back to the menu

GameOverScreen:
	mov eax, score                     ; EAX holds the final score
	cmp eax, prevHighScore             ; is the score above the record before play?
	jle NotNewHighScore                ; no: clear the new-record flag
	mov eax, 1                         ; yes: ask for NEW HIGH SCORE
	jmp ShowGameOver                   ; show the game-over panel

NotNewHighScore:
	mov eax, 0                        ; no new record was set

ShowGameOver:
	call DrawGameOver                  ; draw game-over details and flag
	call WaitGameOverChoice            ; wait for ENTER, R, or ESC
	cmp eax, MENU_PLAY                 ; did the player choose replay?
	je NewGame                         ; yes: start a new game
	mov gameState, STATE_MENU          ; ESC returns to the menu state
	jmp MenuLoop                       ; go back to the menu

ExitGame:
	mov dl, 0                          ; park the goodbye column at zero
	mov dh, MSG_ROW                    ; print below the board message row
	call Gotoxy                        ; move the console cursor
	mov eax, white + (black * 16)      ; reset to white on black
	call SetTextColor                  ; restore the normal console color
	mov edx, OFFSET goodbyeText        ; EDX points to the goodbye text
	call WriteString                   ; print a short goodbye line
	call Crlf                          ; move to the next console line
	exit                               ; end the program
main ENDP

END main
