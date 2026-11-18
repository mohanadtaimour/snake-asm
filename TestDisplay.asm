; =====================================================================
; TestDisplay.asm - TEMPORARY visual test program for Display.asm
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This program shows each display procedure one at a time.
; It is excluded from the final game build.
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

.data
testBorder BYTE "Press a key: DrawBorder",0
testHUD BYTE "Press a key: DrawHUD 99-100-90",0
testSnake BYTE "Press a key: DrawSnake and DrawFood",0
testFrame BYTE "Press a key: DrawFrame normal and eating",0
testMenu BYTE "Press a key: DrawMenu",0
testGameOver0 BYTE "Press a key: DrawGameOver no record",0
testGameOver1 BYTE "Press a key: DrawGameOver record",0
testPaused BYTE "Press a key: DrawPaused show",0
testPausedHide BYTE "Press a key: DrawPaused hide",0

.code

;---------------------------------------------------------------------
ShowPrompt PROC USES eax edx
;
; Prints a test prompt, waits for one key and clears the screen.
; Receives: EDX = prompt string
; Returns:  nothing
;---------------------------------------------------------------------
	call Crlf                          ; leave some console space
	call WriteString                   ; print the prompt
	call ReadChar                      ; wait for a key between display steps
	call Clrscr                        ; clear before the next display step
	ret                                ; USES restores all registers
ShowPrompt ENDP

;---------------------------------------------------------------------
main PROC
;
; Displays every frontend drawing procedure for visual verification.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                      ; create a valid starting snake and food

	call Clrscr                        ; clear for the border test
	call DrawBorder                    ; show the board border
	mov edx, OFFSET testBorder         ; EDX points to the border prompt
	call ShowPrompt                    ; wait before the next step

	mov score, 99                      ; show the first score width
	mov highScore, 99                  ; show a matching high score
	mov gameLevel, 1                   ; show level 1
	call DrawHUD                       ; draw score 99
	mov edx, OFFSET testHUD            ; EDX points to the HUD prompt
	call ShowPrompt                    ; wait after score 99

	call Clrscr                        ; clear for a clean HUD step
	mov score, 100                     ; make the score longer
	mov highScore, 100                 ; make the high score longer
	call DrawHUD                       ; draw score 100
	mov edx, OFFSET testHUD            ; EDX points to the HUD prompt
	call ShowPrompt                    ; wait after score 100

	call Clrscr                        ; clear before the shrinking HUD step
	mov score, 90                      ; make the score shorter
	mov highScore, 90                  ; make the high score shorter
	call DrawHUD                       ; draw score 90 and trailing spaces
	mov edx, OFFSET testHUD            ; EDX points to the HUD prompt
	call ShowPrompt                    ; wait after score 90

	call InitGame                      ; reset the snake and food
	call Clrscr                        ; clear for snake and food
	call DrawBorder                    ; restore the border
	call DrawSnake                     ; draw all snake segments
	call DrawFood                      ; draw the food
	mov edx, OFFSET testSnake          ; EDX points to the snake prompt
	call ShowPrompt                    ; wait after snake and food

	call InitGame                      ; reset for a normal frame
	call Clrscr                        ; clear for a complete frame setup
	call DrawAll                       ; draw the initial complete board
	call GetNextHead                   ; get the next normal head cell
	mov bl, 0                          ; BL means no growth
	call MoveSnake                     ; move the snake one normal step
	mov eax, TICK_OK                   ; EAX is a normal tick result
	call DrawFrame                     ; draw the normal incremental frame
	mov edx, OFFSET testFrame          ; EDX points to normal frame prompt
	call ShowPrompt                    ; wait after normal frame

	call InitGame                      ; reset for the eating frame
	call Clrscr                        ; clear for eating setup
	call DrawAll                       ; draw initial board
	mov dl, snakeX[0]                  ; DL holds head column
	inc dl                             ; put food on the next right cell
	mov foodX, dl                      ; store food column
	mov al, snakeY[0]                  ; AL holds head row
	mov foodY, al                      ; store food row
	call GameTick                      ; eat and change the score
	mov eax, TICK_ATE                  ; EAX says food was eaten
	call DrawFrame                     ; draw tail, head and eating updates
	mov edx, OFFSET testFrame          ; EDX points to eating frame prompt
	call ShowPrompt                    ; wait after eating frame

	call DrawMenu                      ; show the menu screen
	mov edx, OFFSET testMenu           ; EDX points to the menu prompt
	call ShowPrompt                    ; wait after menu

	call InitGame                      ; reset for game-over tests
	call Clrscr                        ; clear before game-over
	call DrawBorder                    ; keep the walls visible
	mov eax, 0                         ; no new high score
	call DrawGameOver                  ; show game-over without record line
	mov edx, OFFSET testGameOver0      ; EDX points to no-record prompt
	call ShowPrompt                    ; wait after no-record screen

	call Clrscr                        ; clear before record game-over
	call DrawBorder                    ; keep the walls visible
	mov eax, 1                         ; mark a new high score
	call DrawGameOver                  ; show NEW HIGH SCORE
	mov edx, OFFSET testGameOver1      ; EDX points to record prompt
	call ShowPrompt                    ; wait after record screen

	call InitGame                      ; reset before pause tests
	call Clrscr                        ; clear for pause test
	call DrawBorder                    ; draw the board
	mov eax, 1                         ; show PAUSED
	call DrawPaused                    ; print PAUSED
	mov edx, OFFSET testPaused         ; EDX points to pause prompt
	call ShowPrompt                    ; wait after PAUSED

	mov eax, 0                         ; hide PAUSED
	call DrawPaused                    ; erase PAUSED
	mov edx, OFFSET testPausedHide     ; EDX points to hide prompt
	call ShowPrompt                    ; wait after pause hide

	call Clrscr                        ; clear the final test screen
	call WaitMsg                       ; wait before closing
	exit                               ; end the test program
main ENDP

END main
