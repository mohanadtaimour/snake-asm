; =====================================================================
; Game.asm - Member 2: Game State & Rules
; Course : Computer Architecture (26EEC5303)  -  Snake game (MASM, Irvine32)
;
; This file stores the game data (food, score, level, speed, state)
; and the game rules. It does NOT draw anything and does NOT read the
; keyboard. It only calls Member 1's snake procedures (Snake.asm).
; =====================================================================

INCLUDE Irvine32.inc            ; Irvine library (also sets .386, .model flat,stdcall)
INCLUDE SnakeDefs.inc           ; shared constants, EXTERNDEFs and PROTOs

; ---------------------------------------------------------------------
.data
; ---- Public data (declared with EXTERNDEF in SnakeDefs.inc) ----
foodX       BYTE  0                 ; column of the food (0..BOARD_WIDTH-1)
foodY       BYTE  0                 ; row of the food    (0..BOARD_HEIGHT-1)
foodType    BYTE FOOD_NORMAL         ; normal or golden food
specialType BYTE SPECIAL_NONE         ; current timed special item
specialX    BYTE 0                    ; special item column
specialY    BYTE 0                    ; special item row
specialTimeLeft DWORD 0               ; milliseconds before the special expires
score       DWORD 0                 ; current score
highScore   DWORD 0                 ; best score ever (kept in a file)
gameLevel   DWORD 1                 ; current level, starts at 1
foodsEaten  DWORD 0                 ; foods eaten in this game
tickDelay   DWORD START_DELAY       ; ms to wait between moves
gameState   DWORD STATE_MENU        ; one of the STATE_ constants
difficulty  DWORD DIFF_NORMAL       ; selected game difficulty
startDelay  DWORD START_DELAY        ; starting delay for the selected difficulty
delayStep   DWORD DELAY_STEP         ; delay reduction per level
obstacleX   BYTE MAX_OBSTACLES DUP(0) ; columns for fixed obstacles
obstacleY   BYTE MAX_OBSTACLES DUP(0) ; rows for fixed obstacles
obstacleCount DWORD 0                 ; number of active fixed obstacles
obstaclesOn DWORD 1                   ; obstacle placement is enabled by default

; ---- Private data (only this file uses these) ----
highScoreFile BYTE "highscore.dat",0 ; name of the high-score file
fileHandle    DWORD 0                ; handle of the file we are using
readBuffer    DWORD 0                ; the 4 bytes read from the file go here

; ---------------------------------------------------------------------
.code

;----------------------------------------------------------
SetDifficulty PROC
;
; Sets the selected difficulty and its starting delay and level step.
; Receives: EAX = DIFF_EASY, DIFF_NORMAL or DIFF_HARD
; Returns:  nothing (invalid values are ignored; registers are unchanged)
;----------------------------------------------------------
    cmp eax, DIFF_EASY                ; is Easy selected?
    je SetEasy                        ; yes: use Easy values
    cmp eax, DIFF_NORMAL              ; is Normal selected?
    je SetNormal                      ; yes: use Normal values
    cmp eax, DIFF_HARD                ; is Hard selected?
    je SetHard                        ; yes: use Hard values
    ret                               ; invalid difficulty leaves settings unchanged
SetEasy:
    mov difficulty, DIFF_EASY          ; store the selected difficulty
    mov startDelay, 200               ; Easy starts at 200 milliseconds
    mov delayStep, 10                 ; Easy speeds up by 10 milliseconds per level
    ret                               ; EAX and other registers are unchanged
SetNormal:
    mov difficulty, DIFF_NORMAL        ; store the selected difficulty
    mov startDelay, START_DELAY        ; Normal uses the shared start delay
    mov delayStep, DELAY_STEP          ; Normal uses the shared delay step
    ret                               ; EAX and other registers are unchanged
SetHard:
    mov difficulty, DIFF_HARD          ; store the selected difficulty
    mov startDelay, 100               ; Hard starts at 100 milliseconds
    mov delayStep, 12                 ; Hard speeds up by 12 milliseconds per level
    ret                               ; EAX and other registers are unchanged
SetDifficulty ENDP

;----------------------------------------------------------
ToggleObstacles PROC
;
; Switches fixed obstacle generation on or off.
; Receives: nothing
; Returns: nothing (obstaclesOn changes between zero and one)
;----------------------------------------------------------
    pushfd                            ; preserve the flags changed by XOR
    xor obstaclesOn, 1                ; flip the obstacle option
    popfd                             ; restore the caller's flags
    ret                               ; return without changing registers
ToggleObstacles ENDP

;----------------------------------------------------------
InitGame PROC
;
; Starts a new game: seeds the random generator, resets the snake,
; resets score/level/speed, sets the state to PLAYING and puts the
; first food on the board. highScore is NOT reset.
; Receives: nothing
; Returns: nothing (all registers are kept unchanged)
;----------------------------------------------------------
    pushad                          ; save ALL registers (we return nothing)

    call Randomize                  ; seed Irvine's random generator (so food differs each game)
    call InitSnake                  ; Member 1: put the snake back to its start position
    call PlaceObstacles             ; put obstacles away from the snake's starting corridor

    mov  score, 0                   ; new game -> score starts at 0
    mov  specialType, SPECIAL_NONE  ; no special item is active in a new game
    mov  specialTimeLeft, 0         ; clear the old special timer
    mov  foodsEaten, 0              ; no food eaten yet
    mov  gameLevel, 1               ; start at level 1
    mov  eax, startDelay            ; EAX holds the selected starting delay
    mov  tickDelay, eax             ; level 1 speed for the selected difficulty
    mov  gameState, STATE_PLAYING   ; the game is now running

    call SpawnFood                  ; place the first food (after InitSnake, so it avoids the snake)

    popad                           ; restore all registers
    ret
InitGame ENDP

;----------------------------------------------------------
PlaceObstacles PROC
;
; Places OBSTACLE_COUNT random obstacles outside the snake's start corridor.
; Receives: nothing
; Returns: nothing (obstacle arrays and count are updated)
;----------------------------------------------------------
    pushad                          ; preserve all registers used for placement
    mov obstacleCount, 0             ; begin this round with no active obstacles
    cmp obstaclesOn, 0                ; are fixed obstacles disabled?
    je PlaceObstaclesDone            ; yes: keep the obstacle count at zero
PlaceObstacleNext:
    cmp obstacleCount, OBSTACLE_COUNT ; have all required obstacles been placed?
    jae PlaceObstaclesDone          ; yes: finish placement
    mov eax, BOARD_WIDTH             ; RandomRange will choose a valid column
    push esi                         ; preserve the active obstacle index
    call RandomRange                 ; EAX = random column
    pop esi                          ; restore the active obstacle index
    push eax                         ; keep the selected column safely
    mov eax, BOARD_HEIGHT            ; RandomRange will choose a valid row
    push esi                         ; preserve the active obstacle index
    call RandomRange                 ; EAX = random row
    pop esi                          ; restore the active obstacle index
    mov dh, al                       ; DH holds the candidate row
    pop eax                          ; recover the candidate column
    mov dl, al                       ; DL holds the candidate column
    cmp dh, (BOARD_HEIGHT / 2) - 1   ; is the row just above the start corridor?
    je PlaceObstacleNext             ; yes: reject the candidate row
    cmp dh, BOARD_HEIGHT / 2         ; is the row at the start corridor?
    je PlaceObstacleNext             ; yes: reject the candidate row
    cmp dh, (BOARD_HEIGHT / 2) + 1   ; is the row just below the start corridor?
    je PlaceObstacleNext             ; yes: reject the candidate row
    call IsObstacle                  ; EAX = 1 if another obstacle is already here
    cmp eax, 1                       ; was this candidate already occupied?
    je PlaceObstacleNext             ; yes: choose another random cell
    mov esi, obstacleCount           ; ESI is the next obstacle array index
    mov obstacleX[esi], dl           ; store the new obstacle column
    mov obstacleY[esi], dh           ; store the new obstacle row
    inc obstacleCount                ; count this obstacle as placed
    jmp PlaceObstacleNext            ; keep placing until the requested count
PlaceObstaclesDone:
    popad                           ; restore all registers
    ret                             ; return with the obstacle array ready
PlaceObstacles ENDP

;----------------------------------------------------------
IsObstacle PROC USES ebx ecx esi
;
; Checks whether an obstacle occupies the requested board cell.
; Receives: DL = column, DH = row
; Returns: EAX = 1 if occupied, otherwise 0 (DL and DH are preserved)
;----------------------------------------------------------
    mov ecx, obstacleCount           ; ECX counts the active obstacles
    mov esi, 0                        ; ESI starts at obstacle zero
IsObstacleLoop:
    cmp esi, ecx                      ; have all active obstacles been checked?
    jae IsObstacleNotFound            ; yes: this cell is clear
    cmp dl, obstacleX[esi]            ; does this obstacle have the same column?
    jne IsObstacleNext                ; no: inspect the next obstacle
    cmp dh, obstacleY[esi]            ; does this obstacle have the same row?
    je IsObstacleFound                ; yes: this cell is occupied
IsObstacleNext:
    inc esi                           ; move to the next obstacle
    jmp IsObstacleLoop                ; continue checking
IsObstacleFound:
    mov eax, 1                        ; report that an obstacle was found
    ret                               ; USES restores EBX, ECX and ESI
IsObstacleNotFound:
    mov eax, 0                        ; report that the cell is clear
    ret                               ; USES restores EBX, ECX and ESI
IsObstacle ENDP

;----------------------------------------------------------
IsCellBlocked PROC
;
; Checks whether a board cell contains the snake, an obstacle or an item.
; Receives: DL = column, DH = row
; Returns: EAX = 1 if blocked, otherwise 0 (DL and DH are preserved)
;----------------------------------------------------------
    push edx                          ; preserve the requested cell across IsOnSnake
    call IsOnSnake                    ; EAX = 1 if a snake segment is in this cell
    pop edx                           ; restore the requested column and row
    cmp eax, 1                        ; is the cell occupied by the snake?
    je IsCellBlockedDone              ; yes: no further checks are needed
    call IsObstacle                   ; check whether an obstacle occupies the cell
    cmp eax, 1                        ; is this cell an obstacle?
    je IsCellBlockedDone              ; yes: the cell is blocked
    cmp dl, foodX                     ; does this cell contain the current food?
    jne IsCellBlockedCheckSpecial     ; no: check the special item
    cmp dh, foodY                     ; is the row also the current food row?
    je IsCellBlockedFound             ; yes: the cell is blocked
IsCellBlockedCheckSpecial:
    cmp specialType, SPECIAL_NONE     ; is a special item active?
    je IsCellBlockedClear             ; no: the cell is clear
    cmp dl, specialX                  ; does this cell contain the special column?
    jne IsCellBlockedClear            ; no: the cell is clear
    cmp dh, specialY                  ; does this cell contain the special row?
    jne IsCellBlockedClear            ; no: the cell is clear
IsCellBlockedFound:
    mov eax, 1                        ; report that the cell is blocked
    ret                               ; DL and DH remain unchanged
IsCellBlockedClear:
    mov eax, 0                        ; report that the cell is clear
IsCellBlockedDone:
    ret                               ; return the blocked-cell result in EAX
IsCellBlocked ENDP

;----------------------------------------------------------
SpawnFood PROC
;
; Puts the food on a random cell that is NOT on the snake, obstacles or items.
; It picks a random column and row; if the cell is blocked
; it simply picks again.
; Receives: nothing
; Returns: nothing (sets foodX and foodY; registers are kept)
;----------------------------------------------------------
    push eax                        ; save registers we change
    push edx

TryAgain:
    mov  eax, BOARD_WIDTH           ; RandomRange gives 0 .. EAX-1, so 0 .. 39
    call RandomRange                ; EAX = random column
    push eax                        ; keep the column safely on the stack

    mov  eax, BOARD_HEIGHT          ; now 0 .. BOARD_HEIGHT-1
    call RandomRange                ; EAX = random row
    mov  dh, al                     ; DH = row    (Gotoxy style: DH = y)
    pop  eax                        ; get the column back into EAX
    mov  dl, al                     ; DL = column (Gotoxy style: DL = x)

    call IsCellBlocked              ; EAX = 1 if that cell has snake or obstacle
    cmp  eax, 0                     ; is the cell free?
    jne  TryAgain                   ; no -> pick another cell

    mov  foodX, dl                  ; free cell found: store the food column
    mov  foodY, dh                  ; and the food row
    mov  eax, GOLDEN_CHANCE         ; choose a golden food one time in five
    call RandomRange                ; EAX = random value from zero through four
    cmp  eax, 0                     ; was this spawn selected as golden?
    jne  SpawnNormalFood            ; no: keep the normal type
    mov  foodType, FOOD_GOLDEN      ; mark this food as golden
    jmp  SpawnFoodDone              ; finish after selecting its type
SpawnNormalFood:
    mov  foodType, FOOD_NORMAL      ; mark this food as normal
SpawnFoodDone:
    pop  edx                        ; restore registers
    pop  eax
    ret
SpawnFood ENDP

;----------------------------------------------------------
SpawnSpecial PROC
;
; Places a timed bonus or poison item on an unoccupied board cell.
; Receives: nothing
; Returns: nothing (special item data is updated)
;----------------------------------------------------------
    pushad                          ; preserve all registers used for placement
SpawnSpecialTryAgain:
    mov eax, BOARD_WIDTH             ; RandomRange chooses a board column
    call RandomRange                 ; EAX = random column
    push eax                         ; keep the selected column
    mov eax, BOARD_HEIGHT            ; RandomRange chooses a board row
    call RandomRange                 ; EAX = random row
    mov dh, al                       ; DH holds the candidate row
    pop eax                          ; recover the candidate column
    mov dl, al                       ; DL holds the candidate column
    call IsCellBlocked               ; EAX = 1 if snake, obstacle or another item is here
    cmp eax, 1                       ; is the candidate cell blocked?
    je SpawnSpecialTryAgain          ; yes: choose another cell
    mov specialX, dl                 ; save the available special column
    mov specialY, dh                 ; save the available special row
    mov eax, 2                       ; choose randomly between two special types
    call RandomRange                 ; EAX = zero or one
    cmp eax, 0                       ; was BONUS selected?
    jne SpawnPoison                  ; no: select POISON
    mov specialType, SPECIAL_BONUS   ; activate a bonus item
    jmp SpawnSpecialSetTimer         ; both types use the same lifetime
SpawnPoison:
    mov specialType, SPECIAL_POISON  ; activate a poison item
SpawnSpecialSetTimer:
    mov specialTimeLeft, SPECIAL_LIFETIME ; start the six-second lifetime
    popad                           ; restore all registers
    ret                             ; return with one special item active
SpawnSpecial ENDP

;----------------------------------------------------------
UpdateHighScore PROC
;
; Updates the high score when the current score exceeds it.
; Receives: nothing
; Returns: nothing (EAX is preserved)
;----------------------------------------------------------
    push eax                         ; preserve the caller's register value
    mov eax, score                   ; EAX holds the current score
    cmp eax, highScore               ; did the score exceed the record?
    jbe UpdateHighScoreDone          ; no: leave the high score unchanged
    mov highScore, eax               ; store the new high score
UpdateHighScoreDone:
    pop eax                          ; restore the caller's register value
    ret                             ; return without changing EAX
UpdateHighScore ENDP

;----------------------------------------------------------
GameTick PROC
;
; Runs ONE frame of the game. Order matters: first look where the
; head WILL go, check for crashes, and only then move the snake.
; Receives: nothing
; Returns: EAX = TICK_OK, TICK_ATE, TICK_DIED, TICK_BONUS or TICK_POISON
;          (EBX, ECX, EDX are kept unchanged)
;----------------------------------------------------------
    push ebx                        ; save the registers we use
    push ecx
    push edx

    ; ---- Step 1: do nothing unless the game is running ----
    cmp  gameState, STATE_PLAYING   ; is the game being played?
    jne  NotPlaying                 ; paused / menu / game over -> do nothing

    cmp  specialType, SPECIAL_NONE  ; is a timed special item active?
    je   SpecialTimerUpdated        ; no: there is no timer to advance
    mov  eax, tickDelay             ; EAX holds the time elapsed this game tick
    cmp  specialTimeLeft, eax       ; will this tick use up the remaining lifetime?
    jbe  ExpireSpecial              ; yes: remove the special item
    sub  specialTimeLeft, eax       ; otherwise reduce its remaining lifetime
    jmp  SpecialTimerUpdated        ; continue into movement checks
ExpireSpecial:
    mov  specialType, SPECIAL_NONE  ; expire the current special item
    mov  specialTimeLeft, 0         ; clear its remaining lifetime
SpecialTimerUpdated:

    ; ---- Step 2: where would the head go next? ----
    call GetNextHead                ; DL = next column, DH = next row (snake is NOT moved)

    ; ---- Step 3: wall check ----
    push edx                        ; save DL/DH (so we do not depend on the callee keeping them)
    call CheckWallHit               ; EAX = 1 if the cell is outside the board
    pop  edx                        ; get DL/DH back (pop does not change EAX)
    cmp  eax, 1                     ; did we hit a wall?
    je   PlayerDied                 ; yes -> game over

    ; ---- Step 4: obstacle check ----
    push edx                        ; save DL/DH around the obstacle check
    call IsObstacle                 ; EAX = 1 if an obstacle is in the next head cell
    pop  edx                        ; restore the next head cell
    cmp  eax, 1                     ; did the snake hit an obstacle?
    je   PlayerDied                 ; yes -> game over

    ; ---- Step 5: will the snake eat the food on this move? ----
    mov  bl, 0                      ; assume NO food here (BL = grow flag = 0)
    cmp  dl, foodX                  ; same column as the food?
    jne  NoFoodHere                 ; no -> not eating
    cmp  dh, foodY                  ; same row as the food?
    jne  NoFoodHere                 ; no -> not eating
    mov  bl, 1                      ; both match -> the snake will eat and GROW

NoFoodHere:
    ; ---- Step 6: self-collision check (needs BL, because a growing snake keeps its tail) ----
    push edx                        ; save the new head cell
    push ebx                        ; save BL (the grow flag)
    call CheckSelfHit               ; EAX = 1 if the head hits the body
    pop  ebx                        ; restore BL
    pop  edx                        ; restore DL/DH
    cmp  eax, 1                     ; did we hit ourselves?
    je   PlayerDied                 ; yes -> game over

    mov  bh, SPECIAL_NONE           ; assume the next cell has no special item
    cmp  specialType, SPECIAL_NONE ; is a special item active?
    je   SpecialCellChecked         ; no: continue with the normal move
    cmp  dl, specialX               ; does the next head cell match the special column?
    jne  SpecialCellChecked         ; no: the snake will not collect it
    cmp  dh, specialY               ; does the next head cell match the special row?
    jne  SpecialCellChecked         ; no: the snake will not collect it
    mov  bh, specialType            ; remember the special type through MoveSnake
SpecialCellChecked:

    ; ---- Step 6: all checks passed, now it is safe to move the snake ----
    push edx                        ; save the new head cell
    push ebx                        ; save BL (the grow flag)
    call MoveSnake                  ; Member 1: move one step (and grow if BL = 1)
    pop  ebx                        ; restore BL (we need it just below)
    pop  edx                        ; restore DL/DH

    ; ---- Step 7: did the snake collect a special item? ----
    cmp  bl, 1                      ; does this move eat normal or golden food?
    je   NormalFoodCollected        ; yes: use the existing food scoring path
    cmp  bh, SPECIAL_BONUS          ; did the snake collect a bonus item?
    je   BonusCollected             ; yes: add bonus points
    cmp  bh, SPECIAL_POISON         ; did the snake collect a poison item?
    je   PoisonCollected            ; yes: subtract points
    jmp  NotEaten                   ; no item was collected

BonusCollected:
    mov  eax, gameLevel             ; EAX holds the current level
    imul eax, eax, BONUS_POINTS     ; bonus points scale with the level
    add  score, eax                 ; add the bonus points
    call UpdateHighScore            ; update the record if this score is higher
    mov  specialType, SPECIAL_NONE  ; remove the collected special item
    mov  specialTimeLeft, 0         ; clear its remaining lifetime
    mov  eax, TICK_BONUS            ; report the bonus collection
    jmp  TickDone                   ; return without changing food or level counts

PoisonCollected:
    cmp  score, POISON_PENALTY      ; is the score smaller than the penalty?
    jb   PoisonScoreZero            ; yes: avoid unsigned underflow
    sub  score, POISON_PENALTY      ; subtract the poison penalty
    jmp  PoisonItemRemoved          ; finish the poison result
PoisonScoreZero:
    mov  score, 0                   ; the score cannot become negative
PoisonItemRemoved:
    mov  specialType, SPECIAL_NONE  ; remove the collected special item
    mov  specialTimeLeft, 0         ; clear its remaining lifetime
    mov  eax, TICK_POISON           ; report the poison collection
    jmp  TickDone                   ; return without changing food or level counts

NormalFoodCollected:
    inc  foodsEaten                 ; one more food eaten

    ; score = score + POINTS_PER_FOOD * gameLevel  (level BEFORE the level-up)
    mov  eax, gameLevel             ; EAX = current level
    imul eax, eax, POINTS_PER_FOOD  ; EAX = level * points per food
    cmp  foodType, FOOD_GOLDEN      ; is the eaten food golden?
    jne  AddFoodScore               ; no: use the normal points
    imul eax, GOLDEN_MULTIPLIER     ; golden food is worth three times as much
AddFoodScore:
    add  score, eax                 ; add the points for this food

    ; gameLevel = foodsEaten / FOODS_PER_LEVEL + 1
    mov  eax, foodsEaten            ; DIV divides EDX:EAX, so put the number in EAX
    xor  edx, edx                   ; clear EDX (the upper half), otherwise DIV gives wrong results
    mov  ecx, FOODS_PER_LEVEL       ; ECX = the divisor
    div  ecx                        ; EAX = foodsEaten / 5 (quotient), EDX = remainder (not used)
    inc  eax                        ; +1 because levels start at 1
    mov  gameLevel, eax             ; store the new level

    ; tickDelay = startDelay - (gameLevel - 1) * delayStep, never below MIN_DELAY
    mov  eax, gameLevel             ; EAX = level
    dec  eax                        ; EAX = level - 1
    imul eax, delayStep             ; EAX = (level - 1) * delayStep
    mov  ecx, startDelay            ; ECX = selected starting delay
    sub  ecx, eax                   ; ECX = new delay (can become negative at high levels)
    cmp  ecx, MIN_DELAY             ; compare as SIGNED numbers
    jge  StoreDelay                 ; delay >= MIN_DELAY -> it is fine as it is
ClampDelay:
    mov  ecx, MIN_DELAY             ; too fast -> use the fastest allowed speed
StoreDelay:
    mov  tickDelay, ecx             ; save the final delay

    ; high score check
    mov  eax, score                 ; EAX = current score
    cmp  eax, highScore             ; is it bigger than the high score?
    jbe  KeepHighScore              ; no (below or equal) -> leave highScore alone
    mov  highScore, eax             ; yes -> new high score
KeepHighScore:

    call SpawnFood                  ; new food AFTER MoveSnake, so it cannot land on the new snake
    cmp  specialType, SPECIAL_NONE ; is there no special item active?
    jne  FoodSpawnComplete          ; keep the existing special item if one is active
    mov  eax, foodsEaten            ; EAX holds the number of foods eaten
    xor  edx, edx                   ; clear the upper half before division
    mov  ecx, SPECIAL_EVERY         ; ECX is the special-spawn interval
    div  ecx                        ; EDX is the remainder after dividing food count
    cmp  edx, 0                     ; is this every third food?
    jne  FoodSpawnComplete          ; no: do not spawn a special item yet
    call SpawnSpecial               ; create a bonus or poison item
FoodSpawnComplete:
    mov  eax, TICK_ATE              ; tell the caller we ate
    jmp  TickDone

NotEaten:
    mov  eax, TICK_OK               ; normal move, nothing special
    jmp  TickDone

NotPlaying:
    mov  eax, TICK_OK               ; game is not running: nothing happened
    jmp  TickDone

PlayerDied:
    mov  gameState, STATE_GAMEOVER  ; the game is over
    mov  eax, score                 ; EAX = final score
    cmp  eax, highScore             ; better than the high score?
    jbe  DeathNoRecord              ; no -> keep the old high score
    mov  highScore, eax             ; yes -> new record
DeathNoRecord:
    call SaveHighScore              ; write highScore to the file
    mov  eax, TICK_DIED             ; tell the caller we died

TickDone:
    pop  edx                        ; restore registers (EAX holds the result)
    pop  ecx
    pop  ebx
    ret
GameTick ENDP

;----------------------------------------------------------
TogglePause PROC
;
; Switches between PLAYING and PAUSED. In any other state it does nothing.
; Receives: nothing
; Returns: nothing
;----------------------------------------------------------
    cmp  gameState, STATE_PLAYING   ; is the game running?
    je   DoPause                    ; yes -> pause it
    cmp  gameState, STATE_PAUSED    ; is the game paused?
    je   DoResume                   ; yes -> resume it
    jmp  ToggleDone                 ; menu or game over -> do nothing

DoPause:
    mov  gameState, STATE_PAUSED    ; PLAYING -> PAUSED
    jmp  ToggleDone

DoResume:
    mov  gameState, STATE_PLAYING   ; PAUSED -> PLAYING

ToggleDone:
    ret
TogglePause ENDP

;----------------------------------------------------------
LoadHighScore PROC
;
; Reads the high score (4 bytes) from highscore.dat.
; If the file is missing or the read fails, highScore becomes 0.
; Receives: nothing
; Returns: nothing (sets highScore; registers are kept)
;----------------------------------------------------------
    push eax                        ; save registers (Irvine file procedures change them)
    push ecx
    push edx

    mov  highScore, 0               ; default: 0 (stays 0 if anything goes wrong)

    mov  edx, OFFSET highScoreFile  ; EDX = address of the file name
    call OpenInputFile              ; EAX = file handle, or INVALID_HANDLE_VALUE if it failed
    cmp  eax, INVALID_HANDLE_VALUE  ; could the file be opened?
    je   LoadDone                   ; no (missing file) -> keep highScore = 0
    mov  fileHandle, eax            ; remember the handle (EAX will be overwritten)

    mov  edx, OFFSET readBuffer     ; EDX = where the data should be put
    mov  ecx, SIZEOF readBuffer     ; ECX = how many bytes to read (4)
    call ReadFromFile               ; EAX = bytes read; carry flag = 1 if the read failed
    jc   CloseTheFile               ; read error -> keep 0, just close the file
    cmp  eax, SIZEOF readBuffer     ; did we get all 4 bytes?
    jne  CloseTheFile               ; short/empty file -> keep 0
    mov  eax, readBuffer            ; the number we read
    mov  highScore, eax             ; store it as the high score

CloseTheFile:
    mov  eax, fileHandle            ; CloseFile needs the handle in EAX
    call CloseFile                  ; always close a file we opened

LoadDone:
    pop  edx                        ; restore registers
    pop  ecx
    pop  eax
    ret
LoadHighScore ENDP

;----------------------------------------------------------
SaveHighScore PROC
;
; Writes highScore (4 bytes) into highscore.dat. If the file cannot
; be created or written, it just returns quietly.
; Receives: nothing
; Returns: nothing (registers are kept)
;----------------------------------------------------------
    push eax                        ; save registers
    push ecx
    push edx

    mov  edx, OFFSET highScoreFile  ; EDX = address of the file name
    call CreateOutputFile           ; EAX = handle (creates the file, or empties an old one)
    cmp  eax, INVALID_HANDLE_VALUE  ; could the file be created?
    je   SaveDone                   ; no -> return quietly
    mov  fileHandle, eax            ; remember the handle (EAX will be overwritten)

    mov  edx, OFFSET highScore      ; EDX = address of the data to write
    mov  ecx, SIZEOF highScore      ; ECX = number of bytes to write (4)
    call WriteToFile                ; EAX = number of bytes written

    mov  eax, fileHandle            ; CloseFile needs the handle in EAX
    call CloseFile                  ; close the file so the data is saved

SaveDone:
    pop  edx                        ; restore registers
    pop  ecx
    pop  eax
    ret
SaveHighScore ENDP

END                                 ; Game.asm has no main, so just END
