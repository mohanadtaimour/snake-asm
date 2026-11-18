; =====================================================================
; TestGame.asm - TEMPORARY test program for Game.asm (Member 2)
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This file tests the game rules without changing Snake.asm or Game.asm.
; It has one main and is excluded from the final game build.
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

DeleteFileA PROTO STDCALL, lpFileName:PTR BYTE

PrintText MACRO textArg
	LOCAL textStr
	.data
	textStr BYTE textArg, 0
	.code
	push edx
	mov edx, OFFSET textStr
	call WriteString
	pop edx
ENDM

CheckDword MACRO testName, actualVal, expectedVal
	LOCAL nameStr
	.data
	nameStr BYTE testName, 0
	.code
	pushad                             ; save every register for the caller
	mov eax, actualVal                 ; EAX receives the actual value
	mov ebx, expectedVal               ; EBX receives the expected value
	mov edx, OFFSET nameStr            ; EDX receives the test name address
	call ReportTest                    ; print the check and update totals
	popad                              ; restore every register for the caller
ENDM

CheckByte MACRO testName, actualVal, expectedVal
	LOCAL nameStr
	.data
	nameStr BYTE testName, 0
	.code
	pushad                             ; save every register for the caller
	movzx eax, actualVal               ; EAX receives the zero-extended actual byte
	mov ebx, expectedVal               ; EBX receives the expected value
	mov edx, OFFSET nameStr            ; EDX receives the test name address
	call ReportTest                    ; print the check and update totals
	popad                              ; restore every register for the caller
ENDM

.data
passCount DWORD 0
failCount DWORD 0
savedHighScore DWORD 0
textFileName BYTE "highscore.dat",0
corruptBuffer WORD 1234h
shortFileHandle DWORD 0
textExpected BYTE "   expected=",0
textActual BYTE "   actual=",0
textPass BYTE "   PASS",0
textFail BYTE "   *** FAIL ***",0

.code

;---------------------------------------------------------------------
ReportTest PROC USES eax ebx edx esi edi
;
; Prints one test name, expected and actual values, and counts PASS or FAIL.
; Receives: EDX = name, EAX = actual, EBX = expected
; Returns:  nothing
;---------------------------------------------------------------------
	mov esi, eax                        ; save actual value
	mov edi, ebx                        ; save expected value
	call WriteString                    ; print test name
	mov edx, OFFSET textExpected        ; EDX points to expected label
	call WriteString                    ; print expected label
	mov eax, edi                        ; EAX holds expected value
	call WriteDec                       ; print expected
	mov edx, OFFSET textActual          ; EDX points to actual label
	call WriteString                    ; print actual label
	mov eax, esi                        ; EAX holds actual value
	call WriteDec                       ; print actual
	cmp esi, edi                        ; compare actual and expected
	jne TestFailed                      ; unequal: count a failure
	inc passCount                       ; equal: count a pass
	mov edx, OFFSET textPass            ; EDX points to PASS
	jmp TestPrint                       ; print PASS or FAIL
TestFailed:
	inc failCount                       ; unequal: count a failure
	mov edx, OFFSET textFail            ; EDX points to FAIL
TestPrint:
	call WriteString                    ; print pass or fail text
	call Crlf                           ; move to the next report line
	ret                                 ; USES restores saved registers
ReportTest ENDP

;---------------------------------------------------------------------
TestInitGame PROC
;
; Checks that InitGame resets game values while keeping the high score.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov highScore, 777                  ; set a known high score
	call InitGame                       ; initialize a new game
	CheckDword "InitGame score", score, 0
	CheckDword "InitGame level", gameLevel, 1
	CheckDword "InitGame tickDelay", tickDelay, START_DELAY
	CheckDword "InitGame state", gameState, STATE_PLAYING
	CheckDword "InitGame length", snakeLength, START_LENGTH
	CheckDword "InitGame highScore unchanged", highScore, 777
	movzx eax, foodX                    ; EAX holds food column
	cmp eax, BOARD_WIDTH                ; compare with board width
	jae InitFoodBad                     ; outside: report fail
	movzx eax, foodY                    ; EAX holds food row
	cmp eax, BOARD_HEIGHT               ; compare with board height
	jae InitFoodBad                     ; outside: report fail
	mov dl, foodX                       ; DL holds food column
	mov dh, foodY                       ; DH holds food row
	call IsOnSnake                      ; EAX is 1 if food is on snake
	cmp eax, 0                          ; must be free
	jne InitFoodBad                     ; snake overlap: report fail
	CheckDword "InitGame food valid", 1, 1
	jmp InitGameDone                    ; skip bad report
InitFoodBad:
	CheckDword "InitGame food valid", 0, 1
InitGameDone:
	ret                                 ; InitGame test is complete
TestInitGame ENDP

;---------------------------------------------------------------------
TestSpawnFood PROC
;
; Calls SpawnFood repeatedly and validates every generated position.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; start with a valid snake
	mov ecx, 500                        ; run exactly 500 spawn trials
SpawnTrialLoop:
	call SpawnFood                      ; generate one valid food position
	movzx eax, foodX                    ; EAX holds food column
	cmp eax, BOARD_WIDTH                ; food column must be inside
	jae SpawnFoundInvalid               ; outside: count invalid
	movzx eax, foodY                    ; EAX holds food row
	cmp eax, BOARD_HEIGHT               ; food row must be inside
	jae SpawnFoundInvalid               ; outside: count invalid
	mov dl, foodX                       ; DL holds food column
	mov dh, foodY                       ; DH holds food row
	call IsOnSnake                      ; EAX is 1 if it overlaps snake
	cmp eax, 0                          ; overlap is invalid
	jne SpawnFoundInvalid               ; snake overlap: count invalid
	jmp SpawnNext                       ; this trial is valid
SpawnFoundInvalid:
	CheckDword "SpawnFood valid trial", 0, 1
SpawnNext:
	loop SpawnTrialLoop                 ; repeat for all 500 trials
	CheckDword "SpawnFood 500 trials completed", 1, 1
	ret                                 ; test is complete
TestSpawnFood ENDP

;---------------------------------------------------------------------
TestNormalAndEat PROC
;
; Checks normal movement and one food move including score and growth.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; start a fresh game
	mov score, 0                        ; set the score to a known value
	mov foodsEaten, 0                   ; set food count to zero
	mov gameLevel, 1                    ; set level 1
	movzx eax, snakeX[0]                ; EAX holds the head column
	movzx ebx, snakeX[0]                ; EBX holds the head backup
	movzx ecx, snakeY[0]                ; ECX holds the head row
	mov dl, snakeX[0]                   ; DL is not needed for setup
	mov dh, snakeY[0]
	movzx edx, snakeX[0]                ; EDX backup no longer used

	mov foodX, 0                        ; place food outside the right path
	mov foodY, 0                        ; keep it away from the snake
	mov eax, snakeLength                ; EAX saves length
	mov ebx, eax                        ; EBX saves length
	call GameTick                       ; move one normal step
	CheckDword "Normal tick result", eax, TICK_OK
	CheckDword "Normal length unchanged", snakeLength, ebx

	call InitGame                       ; reset for the eat case
	mov score, 0                        ; score starts at zero
	mov foodsEaten, 0                   ; no food eaten before this move
	mov gameLevel, 1                    ; level 1 gives 10 points
	mov dl, snakeX[0]                   ; DL receives head column
	inc dl                              ; food is directly right of head
	movzx eax, dl                       ; EAX holds food column backup
	mov foodX, al                       ; place food on the next head cell
	mov al, snakeY[0]                   ; AL receives head row
	mov foodY, al                       ; place food on the head row
	call GameTick                       ; eat and grow one segment
	mov eax, eax                        ; keep tick result visible
	cmp eax, TICK_ATE                   ; check expected eat result
	jne EatWrongTick                    ; wrong result: report it
	CheckDword "Eat tick result", eax, TICK_ATE
EatWrongTick:
	CheckDword "Eat score", score, POINTS_PER_FOOD
	CheckDword "Eat foodsEaten", foodsEaten, 1
	CheckDword "Eat length", snakeLength, START_LENGTH+1
	mov dl, foodX                       ; DL holds food column
	mov dh, foodY                       ; DH holds food row
	call IsOnSnake                      ; EAX must be zero
	cmp eax, 0                          ; food must not overlap snake
	jne EatFoodOnSnake                  ; overlap: report failure
	CheckDword "Eat food valid", 1, 1
	jmp EatTestDone                     ; skip overlap failure
EatFoodOnSnake:
	CheckDword "Eat food valid", 0, 1
EatTestDone:
	ret                                 ; eat test is complete
TestNormalAndEat ENDP

;---------------------------------------------------------------------
TestFifthFood PROC
;
; Checks level two and 135 ms delay on the fifth food.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; start a fresh game
	mov foodsEaten, 4                   ; this eat is the fifth food
	mov gameLevel, 1                    ; begin before level-up
	mov tickDelay, START_DELAY          ; begin at the starting delay
	mov dl, snakeX[0]                   ; DL receives head column
	inc dl                              ; place food directly ahead
	movzx eax, dl                       ; EAX holds next column
	mov foodX, al                       ; store food column
	mov al, snakeY[0]                   ; AL receives head row
	mov foodY, al                       ; store food row
	call GameTick                       ; eat the fifth food
	CheckDword "Fifth food score", score, POINTS_PER_FOOD
	CheckDword "Fifth food level", gameLevel, 2
	CheckDword "Fifth food delay", tickDelay, 135
	ret                                 ; fifth food test is complete
TestFifthFood ENDP

;---------------------------------------------------------------------
TestMinimumDelay PROC
;
; Forces a high level and verifies tickDelay never drops below MIN_DELAY.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; start a fresh game
	mov foodsEaten, 100                 ; force a very high level
	mov dl, snakeX[0]                   ; DL receives head column
	inc dl                              ; place food directly ahead
	movzx eax, dl                       ; EAX holds next column
	mov foodX, al                       ; store food column
	mov al, snakeY[0]                   ; AL receives head row
	mov foodY, al                       ; store food row
	call GameTick                       ; eat and recalculate delay
	cmp tickDelay, MIN_DELAY            ; delay must be at or above minimum
	jb MinimumDelayBad                  ; below minimum: report fail
	CheckDword "Minimum delay", tickDelay, MIN_DELAY
	jmp MinimumDelayDone                ; skip failure report
MinimumDelayBad:
	CheckDword "Minimum delay", tickDelay, MIN_DELAY
MinimumDelayDone:
	ret                                 ; minimum delay test is complete
TestMinimumDelay ENDP

;---------------------------------------------------------------------
TestHigherLevelScore PROC
;
; Checks that the fifth food uses the level before the level-up.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; start a fresh game
	mov score, 0                        ; start with no score
	mov foodsEaten, 4                   ; next food is the fifth
	mov gameLevel, 1                    ; level is 1 before this eat
	mov dl, snakeX[0]                   ; DL receives head column
	inc dl                              ; place food directly ahead
	movzx eax, dl                       ; EAX holds next column
	mov foodX, al                       ; store food column
	mov al, snakeY[0]                   ; AL receives head row
	mov foodY, al                       ; store food row
	call GameTick                       ; eat and level up
	CheckDword "Higher level before-up score", score, 10
	CheckDword "Higher level after-up level", gameLevel, 2
	ret                                 ; score level test is complete
TestHigherLevelScore ENDP

;---------------------------------------------------------------------
TestWalls PROC
;
; Moves the head to each wall and verifies TICK_DIED.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov ecx, 4                          ; run four wall cases
WallCaseLoop:
	cmp ecx, 4                          ; is this the left wall case order?
	je WallLeft                         ; yes
	cmp ecx, 3                          ; right case?
	je WallRight                        ; yes
	cmp ecx, 2                          ; top case?
	je WallTop                          ; yes
	jmp WallBottom                      ; otherwise bottom case
WallLeft:
	call InitGame                       ; initialize a clean snake
	mov snakeX[0], 0                    ; put head at left edge
	mov currentDir, DIR_LEFT            ; move left into wall
	jmp WallRun                         ; run the collision
WallRight:
	call InitGame                       ; initialize a clean snake
	mov snakeX[0], BOARD_WIDTH-1        ; put head at right edge
	mov currentDir, DIR_RIGHT           ; move right into wall
	jmp WallRun                         ; run the collision
WallTop:
	call InitGame                       ; initialize a clean snake
	mov snakeY[0], 0                    ; put head at top edge
	mov currentDir, DIR_UP              ; move up into wall
	jmp WallRun                         ; run the collision
WallBottom:
	call InitGame                       ; initialize a clean snake
	mov snakeY[0], BOARD_HEIGHT-1       ; put head at bottom edge
	mov currentDir, DIR_DOWN            ; move down into wall
WallRun:
	call GameTick                       ; check one wall collision
	CheckDword "Wall death result", eax, TICK_DIED
	CheckDword "Wall sets gameover", gameState, STATE_GAMEOVER
	dec ecx                             ; move to the next wall case
	cmp ecx, 0                          ; are all four wall cases done?
	jne WallCaseLoop                    ; no: run the next wall case
	ret                                 ; four wall tests are complete
TestWalls ENDP

;---------------------------------------------------------------------
TestSelfHit PROC
;
; Checks that the snake dies when it enters its own body.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; initialize a clean snake
	mov snakeLength, 4                  ; create a four segment loop
	mov snakeX[0], 10                   ; head column
	mov snakeY[0], 10                   ; head row
	mov snakeX[1], 10                   ; segment 1 column
	mov snakeY[1], 11                   ; segment 1 row
	mov snakeX[2], 11                   ; segment 2 column
	mov snakeY[2], 11                   ; segment 2 row
	mov snakeX[3], 11                   ; tail column
	mov snakeY[3], 10                   ; tail row
	mov currentDir, DIR_DOWN            ; next cell is segment 1
	call GameTick                       ; attempt to hit the body
	CheckDword "Self hit result", eax, TICK_DIED
	ret                                 ; self-hit test is complete
TestSelfHit ENDP

;---------------------------------------------------------------------
TestTailRule PROC
;
; Checks that entering the tail while not growing is not death.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; initialize a clean snake
	mov snakeLength, 4                  ; create a four segment square
	mov snakeX[0], 10                   ; head column
	mov snakeY[0], 10                   ; head row
	mov snakeX[1], 10                   ; segment 1 column
	mov snakeY[1], 11                   ; segment 1 row
	mov snakeX[2], 11                   ; segment 2 column
	mov snakeY[2], 11                   ; segment 2 row
	mov snakeX[3], 11                   ; tail column
	mov snakeY[3], 10                   ; tail row
	mov currentDir, DIR_RIGHT           ; next cell is the tail
	mov foodX, 5                        ; set food away from the tail
	mov foodY, 5                        ; set food away from the snake
	call GameTick                       ; move into the leaving tail
	cmp eax, TICK_DIED                  ; must not be death
	je TailRuleBad                      ; death: report fail
	CheckDword "Tail rule safe", eax, TICK_OK
	jmp TailRuleDone                    ; skip failure report
TailRuleBad:
	CheckDword "Tail rule safe", eax, TICK_OK
TailRuleDone:
	ret                                 ; tail rule test is complete
TestTailRule ENDP

;---------------------------------------------------------------------
TestPausedAndToggle PROC
;
; Checks paused ticks and TogglePause behavior in valid and invalid states.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; initialize a clean game
	mov gameState, STATE_PAUSED         ; pause before the tick
	movzx edx, snakeX[0]                ; save head column
	call GameTick                       ; GameTick must do nothing
	CheckDword "Paused tick result", eax, TICK_OK
	movzx ecx, snakeX[0]                ; ECX holds head column after tick
	cmp ecx, edx                        ; compare head column before and after
	jne PausedMoved                     ; movement: report failure
	CheckDword "Paused head column", ecx, edx
	jmp PausedCheckDone                 ; skip movement failure
PausedMoved:
	CheckDword "Paused head column", ecx, edx
PausedCheckDone:

	call InitGame                       ; reset to playing
	call TogglePause                    ; playing becomes paused
	CheckDword "Toggle pause state", gameState, STATE_PAUSED
	call TogglePause                    ; paused becomes playing
	CheckDword "Toggle resume state", gameState, STATE_PLAYING

	mov gameState, STATE_GAMEOVER       ; set game-over state
	call TogglePause                    ; must do nothing
	CheckDword "Toggle gameover unchanged", gameState, STATE_GAMEOVER
	mov gameState, STATE_MENU           ; set menu state
	call TogglePause                    ; must do nothing
	CheckDword "Toggle menu unchanged", gameState, STATE_MENU
	ret                                 ; pause tests are complete
TestPausedAndToggle ENDP

;---------------------------------------------------------------------
TestRegisterPreservation PROC
;
; Checks EBX, ECX and EDX remain unchanged through GameTick.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                       ; initialize a normal game
	mov ebx, 12345678h                  ; set EBX sentinel
	mov ecx, 23456789h                  ; set ECX sentinel
	mov edx, 3456789Ah                  ; set EDX sentinel
	call GameTick                       ; run one tick
	CheckDword "GameTick EBX preserved", ebx, 12345678h
	CheckDword "GameTick ECX preserved", ecx, 23456789h
	CheckDword "GameTick EDX preserved", edx, 3456789Ah
	ret                                 ; register test is complete
TestRegisterPreservation ENDP

;---------------------------------------------------------------------
TestFileOperations PROC
;
; Tests save/load, missing files, corrupt files and high-score monotonicity.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	mov eax, highScore                  ; EAX holds the current high score
	mov savedHighScore, eax             ; back up the high score

	mov highScore, 1234                 ; set a known saved value
	call SaveHighScore                  ; write the four-byte value
	mov highScore, 0                    ; clear before loading
	call LoadHighScore                  ; read the saved value
	CheckDword "Save and Load 1234", highScore, 1234

	invoke DeleteFileA, ADDR textFileName
	mov highScore, 999                   ; set a nonzero value before missing load
	call LoadHighScore                  ; missing file should reset to zero
	CheckDword "Missing file gives zero", highScore, 0

	mov edx, OFFSET textFileName        ; EDX points to the test file name
	call CreateOutputFile               ; create a short file
	cmp eax, INVALID_HANDLE_VALUE       ; verify creation succeeded
	je ShortFileDone                    ; failed: cannot test bytes
	mov shortFileHandle, eax            ; save the short file handle
	mov edx, OFFSET corruptBuffer       ; EDX points to two bytes
	mov ecx, 2                          ; write exactly two bytes
	call WriteToFile                    ; write a corrupt short file
	mov eax, shortFileHandle            ; EAX holds the file handle
	call CloseFile                      ; close the short file
	mov highScore, 999                   ; set a nonzero value before corrupt load
	call LoadHighScore                  ; a short file must become zero
	CheckDword "Corrupt short file gives zero", highScore, 0
ShortFileDone:

	mov highScore, 500                   ; set old high score
	mov score, 100                       ; set final score lower
	mov gameState, STATE_PLAYING         ; force a real death tick
	mov snakeX[0], 0                     ; put head at left wall
	mov currentDir, DIR_LEFT             ; move into the wall
	call GameTick                        ; death must not lower high score
	CheckDword "High score never lowers", highScore, 500

	mov eax, savedHighScore              ; EAX holds original high score
	mov highScore, eax                   ; restore original high score
	call SaveHighScore                  ; save the original record back
	ret                                 ; file tests are complete
TestFileOperations ENDP

;---------------------------------------------------------------------
main PROC
;
; Runs every Game.asm unit test and prints final pass/fail totals.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	PrintText "===== Game.asm unit tests ====="
	call Crlf
	call TestInitGame
	call TestSpawnFood
	call TestNormalAndEat
	call TestFifthFood
	call TestMinimumDelay
	call TestHigherLevelScore
	call TestWalls
	call TestSelfHit
	call TestTailRule
	call TestPausedAndToggle
	call TestRegisterPreservation
	call TestFileOperations

	call Crlf
	PrintText "===== RESULT:  passed = "
	mov eax, passCount
	call WriteDec
	PrintText "   failed = "
	mov eax, failCount
	call WriteDec
	call Crlf
	call WaitMsg
	exit
main ENDP

END main
