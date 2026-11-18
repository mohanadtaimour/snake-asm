; =====================================================================
; SnakeDefs.inc - Shared definitions for the Snake game
; Included by EVERY .asm file in the project.
; DO NOT change anything here without agreeing with your teammate.
; =====================================================================

; ---------- Board size (playable cells, walls are OUTSIDE this area) ----------
BOARD_WIDTH   = 40          ; columns 0 .. 39
BOARD_HEIGHT  = 20          ; rows    0 .. 19
MAX_SNAKE_LEN = 200         ; maximum number of snake segments
START_LENGTH  = 3           ; snake length at the start of a game

; ---------- Directions ----------
DIR_UP    = 0
DIR_RIGHT = 1
DIR_DOWN  = 2
DIR_LEFT  = 3
; Note: opposite direction = (dir + 2) AND 3

; ---------- Game states ----------
STATE_MENU     = 0
STATE_PLAYING  = 1
STATE_PAUSED   = 2
STATE_GAMEOVER = 3

; ---------- Results returned by GameTick ----------
TICK_OK   = 0               ; snake moved normally
TICK_ATE  = 1               ; snake moved and ate the food
TICK_DIED = 2               ; snake crashed, game over

; ---------- Scoring and speed ----------
POINTS_PER_FOOD = 10        ; points per food (multiplied by level)
FOODS_PER_LEVEL = 5         ; level goes up every 5 foods
START_DELAY     = 150       ; ms between moves at level 1
DELAY_STEP      = 15        ; ms faster per level
MIN_DELAY       = 50        ; fastest allowed speed (ms)

; =====================================================================
; MEMBER 1 - Snake.asm (Snake Engine)
; =====================================================================
EXTERNDEF snakeX:BYTE         ; array[MAX_SNAKE_LEN], column of each segment (index 0 = head)
EXTERNDEF snakeY:BYTE         ; array[MAX_SNAKE_LEN], row of each segment    (index 0 = head)
EXTERNDEF snakeLength:DWORD   ; current number of segments
EXTERNDEF currentDir:DWORD    ; direction the snake will move next
EXTERNDEF lastTailX:BYTE      ; column of the cell the tail just left
EXTERNDEF lastTailY:BYTE      ; row of the cell the tail just left
EXTERNDEF tailErased:BYTE     ; 1 = tail left a cell (screen must erase it), 0 = snake grew

InitSnake    PROTO
SetDirection PROTO
GetNextHead  PROTO
CheckWallHit PROTO
IsOnSnake    PROTO
CheckSelfHit PROTO
MoveSnake    PROTO

; =====================================================================
; MEMBER 2 - Game.asm (Game State & Rules)
; =====================================================================
EXTERNDEF foodX:BYTE          ; food column
EXTERNDEF foodY:BYTE          ; food row
EXTERNDEF score:DWORD
EXTERNDEF highScore:DWORD
EXTERNDEF gameLevel:DWORD
EXTERNDEF foodsEaten:DWORD
EXTERNDEF tickDelay:DWORD     ; ms to wait between moves (used later by the main loop)
EXTERNDEF gameState:DWORD

InitGame      PROTO
SpawnFood     PROTO
GameTick      PROTO
TogglePause   PROTO
LoadHighScore PROTO
SaveHighScore PROTO
