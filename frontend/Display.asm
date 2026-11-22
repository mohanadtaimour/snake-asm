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
menuControls BYTE "Arrows or WASD = move, P = pause, ESC = back to menu, M = music",0
gameOverText BYTE "GAME OVER",0
gameScoreText BYTE "Score: ",0
gameHighText BYTE "High Score: ",0
gameFoodsText BYTE "Foods eaten: ",0
gameLengthText BYTE "Final length: ",0
gameLevelText BYTE "Level reached: ",0
gamePlayText BYTE "ENTER or R = play again",0
gameMenuText BYTE "ESC = menu",0
newHighText BYTE "NEW HIGH SCORE!",0
pausedText BYTE "PAUSED",0
blankText BYTE "                    ",0
pauseBorderText BYTE "+-------------------+",0
pauseInsideText BYTE "|                   |",0
pauseTitleText BYTE "PAUSED",0
pauseSelectedPrefix BYTE "> ",0
pauseNormalPrefix BYTE "  ",0
pauseResumeText BYTE "Resume",0
pauseRestartText BYTE "Restart",0
pauseQuitText BYTE "Quit to menu",0
difficultyLabel BYTE "Difficulty: ",0       ; menu difficulty label
difficultyEasy BYTE "Easy",0                  ; Easy choice text
difficultyNormal BYTE "Normal",0              ; Normal choice text
difficultyHard BYTE "Hard",0                  ; Hard choice text
difficultySeparator BYTE " / ",0              ; separator between choices
difficultyHint BYTE "   (press 1, 2 or 3)",0 ; menu key hint
drawnSpecialType BYTE SPECIAL_NONE  ; type currently drawn on the board
drawnSpecialX BYTE 0               ; column of the drawn special item
drawnSpecialY BYTE 0               ; row of the drawn special item

.code

;---------------------------------------------------------------------
DrawBorder PROC USES eax ebx ecx edx
;
; Draws the gray rectangular wall around the playable board.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov eax, black + (lightBlue * 16)  ; black spaces on a light blue background
	call SetTextColor                  ; set wall color
	mov ecx, BOARD_WIDTH + 2           ; number of top and bottom columns
	mov ebx, 0                         ; EBX starts at the left screen column
DrawTopLoop:
	mov dl, bl                         ; DL is the horizontal screen column
	mov dh, OFFSET_Y - 1               ; DH is the top wall row
	call Gotoxy                        ; move to this wall cell
	mov al, ' '                        ; AL is a wall cell space
	call WriteChar                     ; print one colored wall cell
	inc ebx                            ; move to the next column
	loop DrawTopLoop                   ; repeat for every top column

	mov ecx, BOARD_WIDTH + 2           ; number of bottom columns
	mov ebx, 0                         ; EBX starts at the left bottom column
DrawBottomLoop:
	mov dl, bl                         ; DL is the bottom screen column
	mov dh, OFFSET_Y + BOARD_HEIGHT    ; DH is the bottom wall row
	call Gotoxy                        ; move to the bottom cell
	mov al, ' '                        ; AL is a wall cell space
	call WriteChar                     ; print one colored wall cell
	inc ebx                            ; move to the next bottom column
	loop DrawBottomLoop                ; repeat for every bottom column

	mov ecx, BOARD_HEIGHT              ; number of left and right wall rows
	mov ebx, 0                         ; EBX will hold the board row offset
DrawSidesLoop:
	mov dl, 0                          ; left wall is at screen column zero
	mov dh, OFFSET_Y                   ; DH starts at the first board row
	add dh, bl                         ; DH is this wall row
	call Gotoxy                        ; move to the left wall
	mov al, ' '                        ; AL is a wall cell space
	call WriteChar                     ; print left wall cell

	mov dl, BOARD_WIDTH + 1            ; right wall is at this screen column
	call Gotoxy                        ; move to the right wall
	mov al, ' '                        ; AL is a wall cell space
	call WriteChar                     ; print right wall cell
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
DrawBodyCell PROC PRIVATE
;
; Draws one striped body cell based on its board coordinates.
; Receives: EBX = board column, EAX = board row
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                             ; preserve all registers used by drawing calls
	mov dl, bl                         ; DL holds the board column
	add dl, OFFSET_X                   ; convert to the screen column
	mov dh, al                         ; DH holds the board row
	add dh, OFFSET_Y                   ; convert to the screen row
	pushad                             ; preserve coordinates across the Irvine call
	call Gotoxy                        ; move to this body cell
	popad                              ; restore board coordinates and screen position
	mov ecx, eax                       ; ECX holds the row for the stripe calculation
	add ecx, ebx                       ; ECX is column plus row
	test ecx, 1                        ; is the cell coordinate sum odd?
	jz DrawBodyCellGreen               ; even cells use green
	mov eax, black + (lightGreen * 16) ; odd cells use a light green background
	jmp DrawBodyCellColorSet           ; apply the selected stripe color
DrawBodyCellGreen:
	mov eax, black + (green * 16)      ; even cells use a green background
DrawBodyCellColorSet:
	call SetTextColor                  ; apply the body stripe color
	mov al, ' '                        ; AL is the solid body cell
	call WriteChar                     ; draw one colored body cell
	mov eax, white + (black * 16)      ; restore white on black
	call SetTextColor                  ; apply normal console color
	popad                              ; restore every caller register
	ret                                ; return without changing registers
DrawBodyCell ENDP

;---------------------------------------------------------------------
DrawHeadCell PROC PRIVATE
;
; Draws the snake head at its board coordinates.
; Receives: EBX = board column, EAX = board row
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                             ; preserve all registers used by drawing calls
	mov dl, bl                         ; DL holds the board column
	add dl, OFFSET_X                   ; convert to the screen column
	mov dh, al                         ; DH holds the board row
	add dh, OFFSET_Y                   ; convert to the screen row
	pushad                             ; preserve coordinates across the Irvine call
	call Gotoxy                        ; move to the head cell
	popad                              ; restore board coordinates and screen position
	mov eax, black + (yellow * 16)     ; black head character on yellow background
	call SetTextColor                  ; apply head color
	mov al, 'O'                        ; AL is the head character
	call WriteChar                     ; draw the head
	mov eax, white + (black * 16)      ; restore white on black
	call SetTextColor                  ; apply normal console color
	popad                              ; restore every caller register
	ret                                ; return without changing registers
DrawHeadCell ENDP

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

	DrawBodyLoop:
	cmp esi, 0                         ; have we reached index zero?
	je DrawSnakeHead                    ; index zero is the head, draw it next
	movzx ebx, snakeX[esi]             ; EBX holds this segment column
	movzx eax, snakeY[esi]             ; EAX holds this segment row
	call DrawBodyCell                  ; draw a striped body cell at these coordinates
	dec esi                            ; move to the previous segment index
	jmp DrawBodyLoop                   ; continue down to segment one

DrawSnakeHead:
	movzx ebx, snakeX[0]               ; EBX holds the head column
	movzx eax, snakeY[0]               ; EAX holds the head row
	call DrawHeadCell                  ; draw the head after the body

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
	cmp foodType, FOOD_GOLDEN          ; is this the golden food?
	jne DrawNormalFood                 ; no: use the standard food style
	mov eax, yellow + (black * 16)     ; golden food is yellow on black
	call SetTextColor                  ; apply the golden food color
	jmp DrawFoodPosition               ; use the shared food position
DrawNormalFood:
	mov eax, lightRed + (black * 16)   ; normal food is light red on black
	call SetTextColor                  ; apply the normal food color
DrawFoodPosition:
	movzx ebx, foodX                   ; EBX holds the food column
	movzx eax, foodY                   ; EAX holds the food row
	mov dl, bl                         ; DL holds the food screen column
	add dl, OFFSET_X                   ; convert to the screen column
	mov dh, al                         ; DH holds the food screen row
	add dh, OFFSET_Y                   ; convert to the screen row
	call Gotoxy                        ; move to the food position
	cmp foodType, FOOD_GOLDEN          ; should the golden food character be drawn?
	jne DrawNormalFoodCharacter        ; no: draw the normal food character
	mov al, '$'                        ; AL is the golden food character
	jmp WriteFoodCharacter             ; share the character output call
DrawNormalFoodCharacter:
	mov al, '@'                        ; AL is the normal food character
WriteFoodCharacter:
	call WriteChar                     ; print the selected food character
	mov eax, white + (black * 16)      ; restore normal console color
	call SetTextColor                  ; apply white on black
	ret                                ; USES restores all saved registers
DrawFood ENDP

;---------------------------------------------------------------------
DrawSpecial PROC
;
; Draws, blinks or erases the active bonus or poison item.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                             ; preserve all registers used for drawing
	mov edi, 0                         ; assume there is no visible special item
	cmp specialType, SPECIAL_NONE     ; is a special item active?
	je DrawSpecialCheckOld            ; no: erase a previously drawn item if needed
	mov edi, 1                         ; the item should be visible by default
	cmp specialTimeLeft, 2000         ; should the item blink during its final seconds?
	jae DrawSpecialCheckOld           ; no: keep drawing it steadily
	mov eax, specialTimeLeft           ; EAX holds the remaining lifetime
	xor edx, edx                       ; clear the upper half before division
	mov ecx, 250                       ; check alternating 250 ms intervals
	div ecx                            ; EAX is the current blink interval
	test eax, 1                        ; is this an odd blink interval?
	jz DrawSpecialCheckOld            ; even intervals remain visible
	mov edi, 0                         ; skip drawing during odd intervals
DrawSpecialCheckOld:
	cmp drawnSpecialType, SPECIAL_NONE ; was a special item previously drawn?
	je DrawSpecialMaybeDraw           ; no: there is nothing to erase
	cmp edi, 0                         ; should the current special be hidden?
	je EraseDrawnSpecial              ; yes: clear the previous item
	mov al, drawnSpecialType           ; AL holds the previous item type
	cmp al, specialType                ; did the item type change?
	jne EraseDrawnSpecial             ; yes: clear the previous item
	mov al, drawnSpecialX              ; AL holds the previous item column
	cmp al, specialX                   ; did the item move horizontally?
	jne EraseDrawnSpecial             ; yes: clear the previous item
	mov al, drawnSpecialY              ; AL holds the previous item row
	cmp al, specialY                   ; did the item move vertically?
	jne EraseDrawnSpecial             ; yes: clear the previous item
	jmp DrawSpecialMaybeDraw          ; same visible item can be redrawn in place
EraseDrawnSpecial:
	mov eax, white + (black * 16)      ; erase the old item on black
	pushad                             ; preserve visibility state while setting color
	call SetTextColor                  ; apply the erase color
	popad                              ; restore drawing and visibility state
	pushad                             ; protect state around cursor and character calls
	mov dl, drawnSpecialX              ; DL holds the old item column
	add dl, OFFSET_X                   ; convert to the screen column
	mov dh, drawnSpecialY              ; DH holds the old item row
	add dh, OFFSET_Y                   ; convert to the screen row
	call Gotoxy                        ; move to the old item cell
	mov al, ' '                        ; clear the old special character
	call WriteChar                     ; erase the old item
	popad                              ; restore drawing and visibility state
	mov drawnSpecialType, SPECIAL_NONE ; remember that no item is drawn
DrawSpecialMaybeDraw:
	cmp edi, 0                         ; should the current item be hidden?
	je DrawSpecialDone                ; yes: finish after erasing any previous item
	cmp specialType, SPECIAL_BONUS    ; is this a bonus item?
	jne DrawSpecialPoisonColor        ; no: use the poison style
	mov eax, lightCyan + (black * 16) ; bonus item is light cyan on black
	pushad                             ; preserve visibility state while setting color
	call SetTextColor                  ; apply the bonus color
	popad                              ; restore drawing and visibility state
	jmp DrawSpecialPosition           ; draw the bonus character
DrawSpecialPoisonColor:
	mov eax, lightMagenta + (black * 16) ; poison item is light magenta on black
	pushad                             ; preserve visibility state while setting color
	call SetTextColor                  ; apply the poison color
	popad                              ; restore drawing and visibility state
DrawSpecialPosition:
	pushad                             ; protect the current visibility state
	mov dl, specialX                   ; DL holds the current item column
	add dl, OFFSET_X                   ; convert to the screen column
	mov dh, specialY                   ; DH holds the current item row
	add dh, OFFSET_Y                   ; convert to the screen row
	call Gotoxy                        ; move to the current item cell
	cmp specialType, SPECIAL_BONUS    ; should the bonus character be drawn?
	jne DrawSpecialPoisonCharacter    ; no: draw the poison character
	mov al, '%'                        ; AL is the bonus character
	jmp WriteSpecialCharacter         ; share the character output call
DrawSpecialPoisonCharacter:
	mov al, 'X'                        ; AL is the poison character
WriteSpecialCharacter:
	call WriteChar                     ; draw the current special item
	popad                              ; restore all drawing registers
	mov al, specialType                ; remember the visible item type
	mov drawnSpecialType, al           ; save the type currently drawn
	mov al, specialX                   ; remember the visible item column
	mov drawnSpecialX, al              ; save the drawn column
	mov al, specialY                   ; remember the visible item row
	mov drawnSpecialY, al              ; save the drawn row
DrawSpecialDone:
	mov eax, white + (black * 16)      ; restore the normal console color
	call SetTextColor                  ; apply white on black
	call ParkCursor                    ; keep the cursor below the board
	popad                              ; restore all caller registers
	ret                                ; return without changing registers
DrawSpecial ENDP

;---------------------------------------------------------------------
DrawObstacles PROC
;
; Draws every fixed obstacle as a light-gray background cell.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                             ; preserve all registers used for drawing
	mov eax, black + (lightGray * 16)  ; black text on a light-gray background
	call SetTextColor                  ; apply the obstacle color
	mov esi, 0                         ; ESI starts at obstacle zero
DrawObstaclesLoop:
	cmp esi, obstacleCount             ; have all active obstacles been drawn?
	jae DrawObstaclesDone              ; yes: restore the normal color
	pushad                             ; protect the obstacle index across Gotoxy
	mov dl, obstacleX[esi]             ; DL holds this obstacle's board column
	add dl, OFFSET_X                   ; convert the column to screen coordinates
	mov dh, obstacleY[esi]             ; DH holds this obstacle's board row
	add dh, OFFSET_Y                   ; convert the row to screen coordinates
	call Gotoxy                        ; move the cursor to this obstacle
	popad                              ; restore the obstacle index and color
	pushad                             ; preserve the loop registers across WriteChar
	mov al, ' '                        ; obstacles are drawn as spaces
	call WriteChar                     ; draw one gray obstacle cell
	popad                              ; restore the obstacle index
	inc esi                            ; move to the next obstacle
	jmp DrawObstaclesLoop              ; draw the next obstacle
DrawObstaclesDone:
	mov eax, white + (black * 16)      ; restore the normal console color
	call SetTextColor                  ; apply white on black
	popad                              ; restore all caller registers
	ret                                ; return without changing registers
DrawObstacles ENDP

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
	call DrawObstacles                 ; draw fixed obstacles inside the board
	mov drawnSpecialType, SPECIAL_NONE ; redraw the item after the screen clear
	call DrawSpecial                   ; draw the current special item
	call DrawHUD                       ; draw the score information
	call DrawSnake                     ; draw every snake segment
	call DrawFood                      ; draw the food
	call ParkCursor                    ; keep the cursor off the board
	popad                              ; restore every register
	ret                                ; DrawAll keeps all registers unchanged
DrawAll ENDP

;---------------------------------------------------------------------
DrawCountdown PROC
;
; Draws or erases one countdown digit above the snake.
; Receives: EAX = 3, 2, 1, or 0 to erase
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                             ; preserve all registers, including the digit
	mov eax, [esp + 28]                ; recover the caller's digit from PUSHAD
	mov dl, (BOARD_WIDTH / 2) + OFFSET_X ; place the digit at the board center
	mov dh, 4 + OFFSET_Y               ; place the digit on board row four
	call Gotoxy                        ; move to the countdown position
	mov eax, [esp + 28]                ; recover the digit after Gotoxy
	cmp eax, 0                         ; should the countdown digit be erased?
	je EraseCountdownDigit             ; yes: draw a normal space
	mov eax, lightRed + (black * 16)   ; countdown digits are light red on black
	call SetTextColor                  ; apply the digit color
	mov eax, [esp + 28]                ; reload the caller's digit after SetTextColor
	call WriteDec                      ; print the countdown digit
	jmp CountdownDigitDone             ; finish with standard color and cursor
EraseCountdownDigit:
	mov eax, white + (black * 16)      ; erased digit uses normal white on black
	call SetTextColor                  ; apply the normal color
	mov al, ' '                        ; use a space to clear the digit
	call WriteChar                     ; erase the countdown digit
CountdownDigitDone:
	mov eax, white + (black * 16)      ; restore the standard console color
	call SetTextColor                  ; apply white on black
	call ParkCursor                    ; keep the cursor below the board
	popad                              ; restore every caller register
	ret                                ; return without changing registers
DrawCountdown ENDP

;---------------------------------------------------------------------
DrawFrame PROC USES eax ebx ecx edx esi edi
;
; Incrementally redraws the tail, body segment 1 and the head.
; Receives: EAX = any GameTick result
; Returns:  nothing
;---------------------------------------------------------------------
	push eax                           ; save the tick result from the caller
	call DrawSpecial                   ; refresh or erase the special item first

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

	movzx ebx, snakeX[1]               ; EBX holds segment 1 column
	movzx eax, snakeY[1]               ; EAX holds segment 1 row
	call DrawBodyCell                  ; draw the striped body cell

DrawFrameHead:
	movzx ebx, snakeX[0]               ; EBX holds head column
	movzx eax, snakeY[0]               ; EAX holds head row
	call DrawHeadCell                  ; draw the head after the body

	pop eax                            ; restore the saved tick result
	push eax                           ; keep the tick result during the HUD checks
	cmp eax, TICK_ATE                  ; did the snake eat this frame?
	jne CheckFrameSpecialResult        ; no: check for a special-item result
	call DrawFood                      ; draw the moved or new food
	call DrawHUD                       ; update score, high score and level
	jmp SkipFrameFood                  ; finish after normal-food updates
CheckFrameSpecialResult:
	cmp eax, TICK_BONUS                ; did the snake collect a bonus?
	je DrawFrameSpecialHUD             ; yes: update the score display
	cmp eax, TICK_POISON               ; did the snake collect poison?
	jne SkipFrameFood                  ; no: no food or score display changes
DrawFrameSpecialHUD:
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
	call DrawDifficulty                ; show the current difficulty choice

	mov eax, white + (black * 16)      ; restore white on black
	call SetTextColor                  ; apply normal color
	call ParkCursor                    ; park the cursor below the board
	popad                              ; restore every register
	ret                                ; DrawMenu keeps all registers unchanged
DrawMenu ENDP

;---------------------------------------------------------------------
DrawDifficulty PROC
;
; Prints the available difficulties and highlights the current choice.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	pushad                             ; preserve all registers used by drawing
	mov dl, 0                          ; start the difficulty line at column zero
	mov dh, 11                         ; print on menu row eleven
	call Gotoxy                        ; move to the difficulty line
	mov eax, white + (black * 16)      ; start in the normal menu text color
	call SetTextColor                  ; apply white on black
	mov edx, OFFSET difficultyLabel    ; EDX points to the line label
	call WriteString                   ; print Difficulty

	cmp difficulty, DIFF_EASY          ; is Easy the selected choice?
	jne DrawEasyNormal                 ; no: use normal color
	mov eax, yellow + (black * 16)     ; yellow highlights the selected choice
	call SetTextColor                  ; apply highlight color
	jmp DrawEasyText                   ; print the selected Easy text
DrawEasyNormal:
	mov eax, white + (black * 16)      ; white marks an unselected choice
	call SetTextColor                  ; apply normal text color
DrawEasyText:
	mov edx, OFFSET difficultyEasy     ; EDX points to Easy
	call WriteString                   ; print Easy
	mov eax, white + (black * 16)      ; separators use the normal text color
	call SetTextColor                  ; apply normal text color
	mov edx, OFFSET difficultySeparator ; EDX points to the separator
	call WriteString                   ; print the first separator

	cmp difficulty, DIFF_NORMAL        ; is Normal the selected choice?
	jne DrawNormalNormal               ; no: use normal color
	mov eax, yellow + (black * 16)     ; yellow highlights the selected choice
	call SetTextColor                  ; apply highlight color
	jmp DrawNormalText                 ; print the selected Normal text
DrawNormalNormal:
	mov eax, white + (black * 16)      ; white marks an unselected choice
	call SetTextColor                  ; apply normal text color
DrawNormalText:
	mov edx, OFFSET difficultyNormal   ; EDX points to Normal
	call WriteString                   ; print Normal
	mov eax, white + (black * 16)      ; separators use the normal text color
	call SetTextColor                  ; apply normal text color
	mov edx, OFFSET difficultySeparator ; EDX points to the separator
	call WriteString                   ; print the second separator

	cmp difficulty, DIFF_HARD          ; is Hard the selected choice?
	jne DrawHardNormal                 ; no: use normal color
	mov eax, yellow + (black * 16)     ; yellow highlights the selected choice
	call SetTextColor                  ; apply highlight color
	jmp DrawHardText                   ; print the selected Hard text
DrawHardNormal:
	mov eax, white + (black * 16)      ; white marks an unselected choice
	call SetTextColor                  ; apply normal text color
DrawHardText:
	mov edx, OFFSET difficultyHard     ; EDX points to Hard
	call WriteString                   ; print Hard
	mov eax, white + (black * 16)      ; the hint uses the normal text color
	call SetTextColor                  ; apply normal text color
	mov edx, OFFSET difficultyHint     ; EDX points to the selection hint
	call WriteString                   ; print the number-key hint
	mov eax, white + (black * 16)      ; restore white on black
	call SetTextColor                  ; apply normal console color
	popad                              ; restore all registers
	ret                                ; DrawDifficulty changes no registers
DrawDifficulty ENDP

;---------------------------------------------------------------------
DrawGameOver PROC USES eax ebx ecx edx esi edi
;
; Draws the game-over panel while keeping the board walls visible.
; Receives: EAX = 1 for a new high score, otherwise 0
; Returns:  nothing
;---------------------------------------------------------------------
	push eax                           ; save the new-high-score flag

	mov eax, white + (black * 16)      ; use normal text color for spaces
	call SetTextColor                  ; set the blank-panel color
	mov ebx, 7                         ; EBX starts at the first blank-panel row
	mov ecx, 13                        ; ECX counts thirteen blank-panel rows
GameOverBlankRows:
	push ecx                           ; save the remaining row count
	mov dh, bl                         ; DH is this blank-panel row
	mov esi, 4                         ; ESI starts at blank-panel column 4
	mov ecx, 26                        ; ECX counts 26 blank columns
GameOverBlankColumns:
	mov eax, esi                       ; EAX holds this blank-panel column
	mov dl, al                         ; DL is this blank-panel column
	call Gotoxy                        ; move to the blank-panel cell
	mov al, ' '                        ; AL is the erase character
	call WriteChar                     ; erase one old board character
	inc esi                            ; move to the next blank-panel column
	loop GameOverBlankColumns          ; repeat across this row
	inc ebx                            ; move to the next blank-panel row
	pop ecx                            ; restore the remaining row count
	loop GameOverBlankRows             ; repeat for thirteen rows

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

	mov dl, 5                          ; set the foods-eaten column
	mov dh, 13                         ; set the foods-eaten row
	call Gotoxy                        ; move to the foods-eaten line
	mov edx, OFFSET gameFoodsText      ; EDX points to the foods label
	call WriteString                   ; print the foods-eaten label
	mov eax, foodsEaten                ; EAX holds the number of foods eaten
	call WriteDec                      ; print the foods-eaten count

	mov dl, 5                          ; set the final-length column
	mov dh, 14                         ; set the final-length row
	call Gotoxy                        ; move to the final-length line
	mov edx, OFFSET gameLengthText     ; EDX points to the length label
	call WriteString                   ; print the final-length label
	mov eax, snakeLength               ; EAX holds the final snake length
	call WriteDec                      ; print the final snake length

	mov dl, 5                          ; set the level-reached column
	mov dh, 15                         ; set the level-reached row
	call Gotoxy                        ; move to the level-reached line
	mov edx, OFFSET gameLevelText      ; EDX points to the level label
	call WriteString                   ; print the level-reached label
	mov eax, gameLevel                 ; EAX holds the final level
	call WriteDec                      ; print the final level

	mov dl, 5                          ; set the play-again column
	mov dh, 17                         ; set the play-again row
	call Gotoxy                        ; move to the play line
	mov edx, OFFSET gamePlayText       ; EDX points to ENTER or R text
	call WriteString                   ; print the replay instruction

	mov dl, 5                          ; set the menu column
	mov dh, 18                         ; set the menu-choice row
	call Gotoxy                        ; move to the menu line
	mov edx, OFFSET gameMenuText       ; EDX points to ESC text
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
DrawPauseMenu PROC
;
; Draws a pause menu and highlights the selected action.
; Receives: EAX = PAUSE_RESUME, PAUSE_RESTART, or PAUSE_QUIT
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                             ; preserve all registers, including the selection
	mov eax, lightBlue + (black * 16)  ; use light blue for the box border
	call SetTextColor                  ; apply the border color
	mov dl, 10                         ; place the box at screen column ten
	mov dh, 8                          ; place the top border on row eight
	call Gotoxy                        ; move to the top border
	mov edx, OFFSET pauseBorderText    ; EDX points to the top border
	call WriteString                   ; draw the top of the box
	mov dl, 10                         ; reset the left box column
	mov dh, 13                         ; place the bottom border on row thirteen
	call Gotoxy                        ; move to the bottom border
	mov edx, OFFSET pauseBorderText    ; EDX points to the bottom border
	call WriteString                   ; draw the bottom of the box
	mov eax, white + (black * 16)      ; set the normal interior color
	call SetTextColor                  ; apply white on black
	mov dl, 10                         ; set the left interior column
	mov dh, 9                          ; set the first interior row
	call Gotoxy                        ; move to row nine inside the box
	mov edx, OFFSET pauseInsideText    ; EDX points to the blank interior row
	call WriteString                   ; clear row nine
	mov dl, 10                         ; reset the left interior column
	mov dh, 10                         ; set the next interior row
	call Gotoxy                        ; move to row ten inside the box
	mov edx, OFFSET pauseInsideText    ; EDX points to the blank interior row
	call WriteString                   ; clear row ten
	mov dl, 10                         ; reset the left interior column
	mov dh, 11                         ; set the next interior row
	call Gotoxy                        ; move to row eleven inside the box
	mov edx, OFFSET pauseInsideText    ; EDX points to the blank interior row
	call WriteString                   ; clear row eleven
	mov dl, 10                         ; reset the left interior column
	mov dh, 12                         ; set the final interior row
	call Gotoxy                        ; move to row twelve inside the box
	mov edx, OFFSET pauseInsideText    ; EDX points to the blank interior row
	call WriteString                   ; clear row twelve
	mov dl, 17                         ; center the pause title in the box
	mov dh, 9                          ; put the title above the menu choices
	call Gotoxy                        ; move to the title position
	mov eax, yellow + (black * 16)     ; use yellow for the pause title
	call SetTextColor                  ; apply the title color
	mov edx, OFFSET pauseTitleText     ; EDX points to PAUSED
	call WriteString                   ; draw the pause title
	mov dl, 12                         ; set the menu item text column
	mov dh, 10                         ; place Resume on the first item row
	call Gotoxy                        ; move to the Resume row
	cmp DWORD PTR [esp + 28], PAUSE_RESUME ; is Resume selected?
	jne DrawPauseResumeNormal          ; no: use the normal item color
	mov eax, yellow + (black * 16)     ; highlight selected Resume in yellow
	call SetTextColor                  ; apply the selected-item color
	mov edx, OFFSET pauseSelectedPrefix ; EDX points to the selection marker
	call WriteString                   ; draw the selected marker
	jmp DrawPauseResumeLabel           ; draw the item label
DrawPauseResumeNormal:
	mov eax, white + (black * 16)      ; use white for an unselected item
	call SetTextColor                  ; apply the normal item color
	mov edx, OFFSET pauseNormalPrefix  ; EDX points to blank marker spacing
	call WriteString                   ; align the unselected label
DrawPauseResumeLabel:
	mov edx, OFFSET pauseResumeText    ; EDX points to Resume
	call WriteString                   ; draw the Resume item
	mov dl, 12                         ; keep the item text column aligned
	mov dh, 11                         ; place Restart on the second item row
	call Gotoxy                        ; move to the Restart row
	cmp DWORD PTR [esp + 28], PAUSE_RESTART ; is Restart selected?
	jne DrawPauseRestartNormal         ; no: use the normal item color
	mov eax, yellow + (black * 16)     ; highlight selected Restart in yellow
	call SetTextColor                  ; apply the selected-item color
	mov edx, OFFSET pauseSelectedPrefix ; EDX points to the selection marker
	call WriteString                   ; draw the selected marker
	jmp DrawPauseRestartLabel          ; draw the item label
DrawPauseRestartNormal:
	mov eax, white + (black * 16)      ; use white for an unselected item
	call SetTextColor                  ; apply the normal item color
	mov edx, OFFSET pauseNormalPrefix  ; EDX points to blank marker spacing
	call WriteString                   ; align the unselected label
DrawPauseRestartLabel:
	mov edx, OFFSET pauseRestartText   ; EDX points to Restart
	call WriteString                   ; draw the Restart item
	mov dl, 12                         ; keep the item text column aligned
	mov dh, 12                         ; place Quit to menu on the third row
	call Gotoxy                        ; move to the Quit row
	cmp DWORD PTR [esp + 28], PAUSE_QUIT ; is Quit to menu selected?
	jne DrawPauseQuitNormal            ; no: use the normal item color
	mov eax, yellow + (black * 16)     ; highlight selected Quit in yellow
	call SetTextColor                  ; apply the selected-item color
	mov edx, OFFSET pauseSelectedPrefix ; EDX points to the selection marker
	call WriteString                   ; draw the selected marker
	jmp DrawPauseQuitLabel             ; draw the item label
DrawPauseQuitNormal:
	mov eax, white + (black * 16)      ; use white for an unselected item
	call SetTextColor                  ; apply the normal item color
	mov edx, OFFSET pauseNormalPrefix  ; EDX points to blank marker spacing
	call WriteString                   ; align the unselected label
DrawPauseQuitLabel:
	mov edx, OFFSET pauseQuitText      ; EDX points to Quit to menu
	call WriteString                   ; draw the Quit item
	mov eax, white + (black * 16)      ; restore the standard console color
	call SetTextColor                  ; apply white on black
	call ParkCursor                    ; keep the cursor below the board
	popad                              ; restore every caller register
	ret                                ; return without changing registers
DrawPauseMenu ENDP

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
ParkCursor PROC USES edx
;
; Moves the blinking cursor away from the game board.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov dl, 0                          ; set cursor column zero
	mov dh, MSG_ROW                    ; set cursor row MSG_ROW
	call Gotoxy                        ; move the cursor to the bottom row
	ret                                ; USES restores EDX
ParkCursor ENDP

END
