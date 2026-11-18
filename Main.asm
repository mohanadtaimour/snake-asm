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
prevState DWORD STATE_MENU
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

MenuLoop:
	mov gameState, STATE_MENU          ; show menu state while choosing
	call DrawMenu                      ; clear and draw the menu
	call WaitMenuChoice                ; block until ENTER or ESC
	cmp eax, MENU_QUIT                 ; did the player choose quit?
	je ExitGame                        ; yes: skip the new game

NewGame:
	call InitGame                      ; reset the snake and game variables
	mov eax, highScore                 ; EAX holds the record before this game
	mov prevHighScore, eax             ; remember it for the new-record check
	mov prevState, STATE_PLAYING       ; initialize the pause state comparison
	call DrawAll                       ; draw the complete new game once

WaitPhase:
	call GetMseconds                   ; read the millisecond clock
	mov startTime, eax                 ; remember the timing phase start

WaitLoop:
	call ReadInput                     ; drain waiting keys
	cmp eax, INPUT_QUIT                ; did ESC stop the game?
	je QuitFromGame                    ; yes: save and return to the menu

	mov eax, 10                        ; Delay receives milliseconds in EAX
	call Delay                         ; wait briefly to avoid a tight ReadKey loop

	call GetMseconds                   ; read the current millisecond clock
	sub eax, startTime                 ; EAX is elapsed milliseconds
	cmp eax, tickDelay                 ; has one game tick elapsed?
	jb WaitLoop                        ; no: keep checking keyboard input

PauseHandling:
	mov eax, gameState                 ; EAX is the current state
	cmp eax, prevState                 ; did the state change this frame?
	je PauseStateSaved                 ; no: keep the previous state

	cmp eax, STATE_PAUSED              ; did it change to PAUSED?
	jne CheckResumed                   ; no: check for resumed playing
	mov eax, 1                        ; EAX asks DrawPaused to show PAUSED
	call DrawPaused                    ; show the paused message
	jmp PauseStateSaved                ; continue to the state save

CheckResumed:
	cmp eax, STATE_PLAYING             ; did it change back to PLAYING?
	jne PauseStateSaved                ; no: no pause message change
	mov eax, 0                        ; EAX asks DrawPaused to hide PAUSED
	call DrawPaused                    ; erase the paused message

PauseStateSaved:
	mov eax, gameState                 ; EAX holds the state to remember
	mov prevState, eax                 ; save it for the next frame

	call GameTick                      ; run one backend game tick
	cmp eax, TICK_DIED                 ; did the snake die?
	je GameOverScreen                  ; yes: show the game-over screen

	cmp gameState, STATE_PLAYING       ; should the normal frame be drawn?
	jne WaitPhase                      ; paused: skip all incremental drawing

	call DrawFrame                     ; incrementally draw the moving snake
	jmp WaitPhase                      ; start the next timing phase

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
	call WaitMenuChoice                ; wait for ENTER or ESC
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
