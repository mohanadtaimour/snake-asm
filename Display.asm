; =====================================================================
; Display.asm - MEMBER 1: SCREEN AND MESSAGE DISPLAY
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This file draws the board and frontend messages. It reads backend
; variables only and never changes snake or game state.
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

.data
hudTextScore BYTE "Score: ",0
hudTextHigh BYTE " High: ",0
hudTextLevel BYTE " Level: ",0
menuTitle BYTE "SNAKE",0
menuHigh BYTE "High Score: ",0
menuEnter BYTE "Press ENTER to play",0
menuEsc BYTE "Press ESC to quit",0
menuControls BYTE "Arrows or WASD = move, P = pause, ESC = back to menu",0
gameOverText BYTE "GAME OVER",0
gameScoreText BYTE "Score: ",0
gameHighText BYTE "High Score: ",0
gamePlayText BYTE "ENTER = play again",0
gameMenuText BYTE "ESC = menu",0
newHighText BYTE "NEW HIGH SCORE!",0
pausedText BYTE "PAUSED",0
blankText BYTE "                    ",0

.code

;---------------------------------------------------------------------
DrawBorder PROC USES eax ebx ecx edx
;
; Draws the gray rectangular wall around the playable board.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov eax, lightGray + (black * 16)  ; light gray foreground on a black background
	call SetTextColor                  ; set wall color
	mov ecx, BOARD_WIDTH + 2           ; number of top and bottom columns
	mov ebx, 0                         ; EBX starts at the left screen column
DrawTopLoop:
	mov dl, bl                         ; DL is the horizontal screen column
	mov dh, OFFSET_Y - 1               ; DH is the top wall row
	call Gotoxy                        ; move to this wall cell
	mov al, '#'                        ; AL is the wall character
	call WriteChar                     ; print one wall character
	inc ebx                            ; move to the next column
	loop DrawTopLoop                   ; repeat for every top column

	mov ecx, BOARD_WIDTH + 2           ; number of bottom columns
	mov ebx, 0                         ; EBX starts at the left bottom column
DrawBottomLoop:
	mov dl, bl                         ; DL is the bottom screen column
	mov dh, OFFSET_Y + BOARD_HEIGHT    ; DH is the bottom wall row
	call Gotoxy                        ; move to the bottom cell
	mov al, '#'                        ; AL is the wall character
	call WriteChar                     ; print one wall character
	inc ebx                            ; move to the next bottom column
	loop DrawBottomLoop                ; repeat for every bottom column

	mov ecx, BOARD_HEIGHT              ; number of left and right wall rows
	mov ebx, 0                         ; EBX will hold the board row offset
DrawSidesLoop:
	mov dl, 0                          ; left wall is at screen column zero
	mov dh, OFFSET_Y                   ; DH starts at the first board row
	add dh, bl                         ; DH is this wall row
	call Gotoxy                        ; move to the left wall
	mov al, '#'                        ; AL is the wall character
	call WriteChar                     ; print left wall

	mov dl, BOARD_WIDTH + 1            ; right wall is at this screen column
	call Gotoxy                        ; move to the right wall
	mov al, '#'                        ; AL is the wall character
	call WriteChar                     ; print right wall
	inc ebx                            ; move to the next wall row
	loop DrawSidesLoop                 ; repeat for every board row

	mov eax, white + (black * 16)      ; restore the normal text color
	call SetTextColor                  ; apply white on black
	ret                                ; USES restores all saved registers
DrawBorder ENDP

;---------------------------------------------------------------------
DrawHUD PROC USES eax edx ecx esi
;
; Prints the score, high score and level on the top HUD row.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov dl, 0                          ; start the HUD at screen column zero
	mov dh, HUD_ROW                    ; draw on the HUD row
	call Gotoxy                        ; move to the HUD position

	mov eax, yellow + (black * 16)     ; yellow text on a black background
	call SetTextColor                  ; set HUD color
	mov edx, OFFSET hudTextScore       ; EDX points to the Score label
	call WriteString                   ; print Score
	mov eax, score                     ; EAX holds the current score
	call WriteDec                      ; print the score number

	mov edx, OFFSET hudTextHigh        ; EDX points to the High label
	call WriteString                   ; print High
	mov eax, highScore                 ; EAX holds the saved high score
	call WriteDec                      ; print the high score

	mov edx, OFFSET hudTextLevel       ; EDX points to the Level label
	call WriteString                   ; print Level
	mov eax, gameLevel                 ; EAX holds the current level
	call WriteDec                      ; print the level number

	mov ecx, 35                        ; enough trailing spaces to erase a longer HUD
EraseHudLoop:
	mov al, ' '                        ; AL is an erased character
	call WriteChar                     ; erase one old character
	loop EraseHudLoop                  ; repeat for the trailing erase width

	mov eax, white + (black * 16)      ; restore white on black
	call SetTextColor                  ; apply normal console color
	ret                                ; USES restores all saved registers
DrawHUD ENDP

;---------------------------------------------------------------------
DrawSnake PROC USES eax ebx ecx edx esi
;
; Draws body segments and then draws the snake head last.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov ecx, snakeLength               ; ECX is the number of segments
	cmp ecx, 0                         ; is the snake empty?
	je DrawSnakeDone                    ; yes: draw nothing

	mov esi, ecx                       ; ESI starts one past the head index count
	dec esi                            ; ESI is the last segment index
	cmp ecx, 1                         ; does only the head exist?
	je DrawSnakeHead                    ; yes: skip body drawing

	mov eax, green + (black * 16)      ; green text on a black background
	call SetTextColor                  ; set body color
DrawBodyLoop:
	cmp esi, 0                         ; have we reached index zero?
	je DrawSnakeHead                    ; index zero is the head, draw it next
	movzx ebx, snakeX[esi]             ; EBX holds this segment column
	movzx eax, snakeY[esi]             ; EAX holds this segment row
	mov dl, bl                         ; DL holds the board column
	add dl, OFFSET_X                   ; convert to the screen column
	mov dh, al                         ; DH holds the board row
	add dh, OFFSET_Y                   ; convert to the screen row
	call Gotoxy                        ; move to this body segment
	mov al, 'o'                        ; AL is the body character
	call WriteChar                     ; print the body segment
	dec esi                            ; move to the previous segment index
	jmp DrawBodyLoop                   ; continue down to segment one

DrawSnakeHead:
	mov eax, lightGreen + (black * 16) ; light green for the head
	call SetTextColor                  ; set head color
	movzx ebx, snakeX[0]               ; EBX holds the head column
	movzx eax, snakeY[0]               ; EAX holds the head row
	mov dl, bl                         ; DL holds the screen column calculation input
	add dl, OFFSET_X                   ; convert head column to screen column
	mov dh, al                         ; DH holds the screen row calculation input
	add dh, OFFSET_Y                   ; convert head row to screen row
	call Gotoxy                        ; move to the head
	mov al, 'O'                        ; AL is the head character
	call WriteChar                     ; print the head

	mov eax, white + (black * 16)      ; restore normal console color
	call SetTextColor                  ; apply white on black
DrawSnakeDone:
	ret                                ; USES restores all saved registers
DrawSnake ENDP

;---------------------------------------------------------------------
DrawFood PROC USES eax ebx edx
;
; Draws the food character at the backend food position.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov eax, lightRed + (black * 16)   ; light red text on a black background
	call SetTextColor                  ; set food color
	movzx ebx, foodX                   ; EBX holds the food column
	movzx eax, foodY                   ; EAX holds the food row
	mov dl, bl                         ; DL holds the food screen column
	add dl, OFFSET_X                   ; convert to the screen column
	mov dh, al                         ; DH holds the food screen row
	add dh, OFFSET_Y                   ; convert to the screen row
	call Gotoxy                        ; move to the food position
	mov al, '*'                        ; AL is the food character
	call WriteChar                     ; print the food
	mov eax, white + (black * 16)      ; restore normal console color
	call SetTextColor                  ; apply white on black
	ret                                ; USES restores all saved registers
DrawFood ENDP

;---------------------------------------------------------------------
DrawAll PROC
;
; Clears and draws the complete game screen once at game start.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	pushad                             ; save every register used by drawing calls
	call Clrscr                        ; clear the complete console
	call DrawBorder                    ; draw the board border
	call DrawHUD                       ; draw the score information
	call DrawSnake                     ; draw every snake segment
	call DrawFood                      ; draw the food
	call ParkCursor                    ; keep the cursor off the board
	popad                              ; restore every register
	ret                                ; DrawAll keeps all registers unchanged
DrawAll ENDP

;---------------------------------------------------------------------
DrawFrame PROC USES eax ebx ecx edx esi edi
;
; Incrementally redraws the tail, body segment 1 and the head.
; Receives: EAX = TICK_OK or TICK_ATE
; Returns:  nothing
;---------------------------------------------------------------------
	push eax                           ; save the tick result from the caller

	cmp tailErased, 1                  ; did the tail leave a cell?
	jne SkipTailErase                   ; no: the snake grew or length did not move
	movzx ebx, lastTailX               ; EBX holds the erased tail column
	movzx eax, lastTailY               ; EAX holds the erased tail row
	mov dl, bl                         ; DL holds the erased screen column
	add dl, OFFSET_X                   ; convert tail column to screen column
	mov dh, al                         ; DH holds the erased screen row
	add dh, OFFSET_Y                   ; convert tail row to screen row
	call Gotoxy                        ; move to the old tail cell
	mov eax, white + (black * 16)      ; use normal color for a space
	call SetTextColor                  ; set normal color
	mov al, ' '                        ; AL is the erase character
	call WriteChar                     ; erase the old tail
SkipTailErase:

	mov ecx, snakeLength               ; ECX holds the number of segments
	cmp ecx, 2                         ; is there a segment 1 to draw?
	jb DrawFrameHead                    ; fewer than two segments: head only

	mov eax, green + (black * 16)     ; green text for body segment 1
	call SetTextColor                  ; set body color
	movzx ebx, snakeX[1]               ; EBX holds segment 1 column
	movzx eax, snakeY[1]               ; EAX holds segment 1 row
	mov dl, bl                         ; DL holds segment 1 screen column
	add dl, OFFSET_X                   ; convert column to screen column
	mov dh, al                         ; DH holds segment 1 screen row
	add dh, OFFSET_Y                   ; convert row to screen row
	call Gotoxy                        ; move to segment 1
	mov al, 'o'                        ; AL is the body character
	call WriteChar                     ; draw segment 1

DrawFrameHead:
	mov eax, lightGreen + (black * 16) ; light green for the head
	call SetTextColor                  ; set head color
	movzx ebx, snakeX[0]               ; EBX holds head column
	movzx eax, snakeY[0]               ; EAX holds head row
	mov dl, bl                         ; DL holds head screen column
	add dl, OFFSET_X                   ; convert column to screen column
	mov dh, al                         ; DH holds head screen row
	add dh, OFFSET_Y                   ; convert row to screen row
	call Gotoxy                        ; move to the new head
	mov al, 'O'                        ; AL is the head character
	call WriteChar                     ; draw the new head

	pop eax                            ; restore the saved tick result
	push eax                           ; keep the tick result during the HUD checks
	cmp eax, TICK_ATE                  ; did the snake eat this frame?
	jne SkipFrameFood                  ; no: skip food and HUD updates
	call DrawFood                      ; draw the moved or new food
	call DrawHUD                       ; update score, high score and level
SkipFrameFood:

	pop eax                            ; restore EAX to the caller tick result
	mov eax, white + (black * 16)      ; restore normal console color
	call SetTextColor                  ; apply white on black
	call ParkCursor                    ; keep the cursor off the board
	ret                                ; USES restores all saved registers
DrawFrame ENDP

;---------------------------------------------------------------------
DrawMenu PROC
;
; Clears the console and draws the title and menu choices.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	pushad                             ; save every register used by drawing calls
	call Clrscr                        ; clear the old screen
	mov dl, 5                          ; set a left menu column
	mov dh, 5                          ; set a top menu row
	call Gotoxy                        ; move to the title position
	mov eax, yellow + (black * 16)     ; yellow title text
	call SetTextColor                  ; set title color
	mov edx, OFFSET menuTitle          ; EDX points to SNAKE
	call WriteString                   ; print the title

	mov dl, 5                          ; set the menu content column
	mov dh, 7                          ; set the first menu content row
	call Gotoxy                        ; move to the high score line
	mov eax, white + (black * 16)      ; white text on black
	call SetTextColor                  ; set menu text color
	mov edx, OFFSET menuHigh           ; EDX points to the high score label
	call WriteString                   ; print the label
	mov eax, highScore                 ; EAX holds the high score
	call WriteDec                      ; print the high score

	mov dl, 5                          ; set the menu content column
	mov dh, 9                          ; set the ENTER row
	call Gotoxy                        ; move to the ENTER line
	mov edx, OFFSET menuEnter          ; EDX points to the ENTER text
	call WriteString                   ; print ENTER to play

	mov dl, 5                          ; set the menu content column
	mov dh, 10                         ; set the ESC row
	call Gotoxy                        ; move to the ESC line
	mov edx, OFFSET menuEsc            ; EDX points to the ESC text
	call WriteString                   ; print ESC to quit

	mov dl, 5                          ; set the hint column
	mov dh, 12                         ; set the controls hint row
	call Gotoxy                        ; move to the controls hint
	mov edx, OFFSET menuControls       ; EDX points to the controls text
	call WriteString                   ; print the controls hint

	mov eax, white + (black * 16)      ; restore white on black
	call SetTextColor                  ; apply normal color
	call ParkCursor                    ; park the cursor below the board
	popad                              ; restore every register
	ret                                ; DrawMenu keeps all registers unchanged
DrawMenu ENDP

;---------------------------------------------------------------------
DrawGameOver PROC USES eax ebx ecx edx esi edi
;
; Draws the game-over panel while keeping the board walls visible.
; Receives: EAX = 1 for a new high score, otherwise 0
; Returns:  nothing
;---------------------------------------------------------------------
	push eax                           ; save the new-high-score flag

	mov dl, 5                          ; set the left message column
	mov dh, 8                          ; set the first game-over row
	call Gotoxy                        ; move inside the board area
	mov eax, yellow + (black * 16)     ; yellow text for game over
	call SetTextColor                  ; set game-over title color
	mov edx, OFFSET gameOverText        ; EDX points to GAME OVER
	call WriteString                   ; print the title

	mov dl, 5                          ; set the score column
	mov dh, 10                         ; set the score row
	call Gotoxy                        ; move to the score line
	mov eax, white + (black * 16)      ; white text for details
	call SetTextColor                  ; set detail color
	mov edx, OFFSET gameScoreText      ; EDX points to Score
	call WriteString                   ; print Score label
	mov eax, score                     ; EAX holds the final score
	call WriteDec                      ; print the final score

	mov dl, 5                          ; set the high-score column
	mov dh, 11                         ; set the high-score row
	call Gotoxy                        ; move to the high-score line
	mov edx, OFFSET gameHighText       ; EDX points to High Score
	call WriteString                   ; print High Score label
	mov eax, highScore                 ; EAX holds the high score
	call WriteDec                      ; print the high score

	mov dl, 5                          ; set the play-again column
	mov dh, 13                         ; set the play-again row
	call Gotoxy                        ; move to the play line
	mov edx, OFFSET gamePlayText       ; EDX points to ENTER text
	call WriteString                   ; print ENTER = play again

	mov dl, 5                          ; set the menu-column
	mov dh, 14                         ; set the menu-choice row
	call Gotoxy                        ; move to the menu line
	mov edx, OFFSET gameMenuText        ; EDX points to ESC text
	call WriteString                   ; print ESC = menu

	pop eax                            ; restore the new-high-score flag
	cmp eax, 1                         ; was this a new record?
	jne GameOverDone                    ; no: skip the record line
	mov dl, 5                         ; set the new-record column
	mov dh, 12                         ; set the new-record row
	call Gotoxy                        ; move to the record line
	mov eax, lightRed + (black * 16)   ; light red for emphasis
	call SetTextColor                  ; set record color
	mov edx, OFFSET newHighText        ; EDX points to NEW HIGH SCORE
	call WriteString                   ; print the record line

GameOverDone:
	mov eax, white + (black * 16)      ; restore normal console color
	call SetTextColor                  ; apply white on black
	call ParkCursor                    ; park the cursor below the board
	ret                                ; USES restores all saved registers
DrawGameOver ENDP

;---------------------------------------------------------------------
DrawPaused PROC USES eax edx
;
; Shows or hides PAUSED on the bottom message row.
; Receives: EAX = 1 to show, 0 to hide
; Returns:  nothing
;---------------------------------------------------------------------
	mov dl, 5                          ; set a visible message column
	mov dh, MSG_ROW                    ; set the bottom message row
	call Gotoxy                        ; move to the message area
	cmp eax, 1                         ; should PAUSED be shown?
	jne HidePaused                     ; no: erase the message
	mov eax, yellow + (black * 16)     ; yellow text for PAUSED
	call SetTextColor                  ; set paused color
	mov edx, OFFSET pausedText         ; EDX points to PAUSED
	call WriteString                   ; print PAUSED
	jmp PausedDone                     ; skip the hide path
HidePaused:
	mov eax, white + (black * 16)      ; normal text color
	call SetTextColor                  ; set normal color
	mov edx, OFFSET blankText          ; EDX points to spaces
	call WriteString                   ; overwrite PAUSED with spaces
PausedDone:
	mov eax, white + (black * 16)      ; restore normal console color
	call SetTextColor                  ; apply white on black
	call ParkCursor                    ; park the cursor below the board
	ret                                ; USES restores all saved registers
DrawPaused ENDP

;---------------------------------------------------------------------
ParkCursor PROC
;
; Moves the blinking cursor away from the game board.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov dl, 0                          ; set cursor column zero
	mov dh, MSG_ROW                    ; set cursor row MSG_ROW
	call Gotoxy                        ; move the cursor to the bottom row
	ret                                ; ParkCursor keeps all registers unchanged
ParkCursor ENDP

END
