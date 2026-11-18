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
score       DWORD 0                 ; current score
highScore   DWORD 0                 ; best score ever (kept in a file)
gameLevel   DWORD 1                 ; current level, starts at 1
foodsEaten  DWORD 0                 ; foods eaten in this game
tickDelay   DWORD START_DELAY       ; ms to wait between moves
gameState   DWORD STATE_MENU        ; one of the STATE_ constants

; ---- Private data (only this file uses these) ----
highScoreFile BYTE "highscore.dat",0 ; name of the high-score file
fileHandle    DWORD 0                ; handle of the file we are using
readBuffer    DWORD 0                ; the 4 bytes read from the file go here

; ---------------------------------------------------------------------
.code

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

    mov  score, 0                   ; new game -> score starts at 0
    mov  foodsEaten, 0              ; no food eaten yet
    mov  gameLevel, 1               ; start at level 1
    mov  tickDelay, START_DELAY     ; level 1 speed
    mov  gameState, STATE_PLAYING   ; the game is now running

    call SpawnFood                  ; place the first food (after InitSnake, so it avoids the snake)

    popad                           ; restore all registers
    ret
InitGame ENDP

;----------------------------------------------------------
SpawnFood PROC
;
; Puts the food on a random cell that is NOT on the snake.
; It picks a random column and row; if the cell is on the snake
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

    call IsOnSnake                  ; Member 1: EAX = 1 if that cell is on the snake (DL/DH are kept)
    cmp  eax, 0                     ; is the cell free?
    jne  TryAgain                   ; no -> it is on the snake, pick another cell

    mov  foodX, dl                  ; free cell found: store the food column
    mov  foodY, dh                  ; and the food row

    pop  edx                        ; restore registers
    pop  eax
    ret
SpawnFood ENDP

;----------------------------------------------------------
GameTick PROC
;
; Runs ONE frame of the game. Order matters: first look where the
; head WILL go, check for crashes, and only then move the snake.
; Receives: nothing
; Returns: EAX = TICK_OK, TICK_ATE or TICK_DIED
;          (EBX, ECX, EDX are kept unchanged)
;----------------------------------------------------------
    push ebx                        ; save the registers we use
    push ecx
    push edx

    ; ---- Step 1: do nothing unless the game is running ----
    cmp  gameState, STATE_PLAYING   ; is the game being played?
    jne  NotPlaying                 ; paused / menu / game over -> do nothing

    ; ---- Step 2: where would the head go next? ----
    call GetNextHead                ; DL = next column, DH = next row (snake is NOT moved)

    ; ---- Step 3: wall check ----
    push edx                        ; save DL/DH (so we do not depend on the callee keeping them)
    call CheckWallHit               ; EAX = 1 if the cell is outside the board
    pop  edx                        ; get DL/DH back (pop does not change EAX)
    cmp  eax, 1                     ; did we hit a wall?
    je   PlayerDied                 ; yes -> game over

    ; ---- Step 4: will the snake eat the food on this move? ----
    mov  bl, 0                      ; assume NO food here (BL = grow flag = 0)
    cmp  dl, foodX                  ; same column as the food?
    jne  NoFoodHere                 ; no -> not eating
    cmp  dh, foodY                  ; same row as the food?
    jne  NoFoodHere                 ; no -> not eating
    mov  bl, 1                      ; both match -> the snake will eat and GROW

NoFoodHere:
    ; ---- Step 5: self-collision check (needs BL, because a growing snake keeps its tail) ----
    push edx                        ; save the new head cell
    push ebx                        ; save BL (the grow flag)
    call CheckSelfHit               ; EAX = 1 if the head hits the body
    pop  ebx                        ; restore BL
    pop  edx                        ; restore DL/DH
    cmp  eax, 1                     ; did we hit ourselves?
    je   PlayerDied                 ; yes -> game over

    ; ---- Step 6: all checks passed, now it is safe to move the snake ----
    push edx                        ; save the new head cell
    push ebx                        ; save BL (the grow flag)
    call MoveSnake                  ; Member 1: move one step (and grow if BL = 1)
    pop  ebx                        ; restore BL (we need it just below)
    pop  edx                        ; restore DL/DH

    ; ---- Step 7: did we eat? ----
    cmp  bl, 1                      ; BL = 1 means the snake ate the food
    jne  NotEaten                   ; no -> normal move

    inc  foodsEaten                 ; one more food eaten

    ; score = score + POINTS_PER_FOOD * gameLevel  (level BEFORE the level-up)
    mov  eax, gameLevel             ; EAX = current level
    imul eax, eax, POINTS_PER_FOOD  ; EAX = level * points per food
    add  score, eax                 ; add it to the score

    ; gameLevel = foodsEaten / FOODS_PER_LEVEL + 1
    mov  eax, foodsEaten            ; DIV divides EDX:EAX, so put the number in EAX
    xor  edx, edx                   ; clear EDX (the upper half), otherwise DIV gives wrong results
    mov  ecx, FOODS_PER_LEVEL       ; ECX = the divisor
    div  ecx                        ; EAX = foodsEaten / 5 (quotient), EDX = remainder (not used)
    inc  eax                        ; +1 because levels start at 1
    mov  gameLevel, eax             ; store the new level

    ; tickDelay = START_DELAY - (gameLevel - 1) * DELAY_STEP, never below MIN_DELAY
    mov  eax, gameLevel             ; EAX = level
    dec  eax                        ; EAX = level - 1
    imul eax, eax, DELAY_STEP       ; EAX = (level - 1) * DELAY_STEP
    mov  ecx, START_DELAY           ; ECX = 150
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
