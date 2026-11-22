; =====================================================================
; SnakeDefs.inc - Shared definitions for the Snake game
; Included by EVERY .asm file in the project.
; DO NOT change anything here without agreeing with your teammate.
; =====================================================================

; ---------- Board size (playable cells, walls are OUTSIDE this area) ----------
BOARD_WIDTH   = 40          ; columns 0 .. 39
BOARD_HEIGHT  = 20          ; rows    0 .. 19
MAX_SNAKE_LEN = 200         ; maximum number of snake segments
MAX_OBSTACLES = 15          ; maximum number of fixed obstacles
OBSTACLE_COUNT = 8          ; number of obstacles placed each round
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

; ---------- Pause menu choices ----------
PAUSE_RESUME  = 0
PAUSE_RESTART = 1
PAUSE_QUIT    = 2

; ---------- Results returned by GameTick ----------
TICK_OK     = 0             ; snake moved normally
TICK_ATE    = 1             ; snake moved and ate the food
TICK_DIED   = 2             ; snake crashed, game over
TICK_BONUS  = 3             ; snake collected a bonus item
TICK_POISON = 4             ; snake collected a poison item

; ---------- Timed special items ----------
SPECIAL_NONE = 0
SPECIAL_BONUS = 1
SPECIAL_POISON = 2
SPECIAL_EVERY = 3
SPECIAL_LIFETIME = 6000
BONUS_POINTS = 50
POISON_PENALTY = 20

; ---------- Scoring and speed ----------
POINTS_PER_FOOD = 10        ; points per food (multiplied by level)
FOOD_NORMAL = 0             ; standard food type
FOOD_GOLDEN = 1             ; bonus food type
GOLDEN_MULTIPLIER = 3       ; golden food is worth three times the normal points
GOLDEN_CHANCE = 5           ; one golden food chance per five food spawns
FOODS_PER_LEVEL = 5         ; level goes up every 5 foods
START_DELAY     = 150       ; ms between moves at level 1
DELAY_STEP      = 15        ; ms faster per level
MIN_DELAY       = 50        ; fastest allowed speed (ms)
DIFF_EASY       = 0         ; easiest speed setting
DIFF_NORMAL     = 1         ; standard speed setting
DIFF_HARD       = 2         ; fastest speed setting

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
EXTERNDEF foodType:BYTE       ; FOOD_NORMAL or FOOD_GOLDEN
EXTERNDEF specialType:BYTE    ; SPECIAL_NONE, SPECIAL_BONUS or SPECIAL_POISON
EXTERNDEF specialX:BYTE       ; special item column
EXTERNDEF specialY:BYTE       ; special item row
EXTERNDEF specialTimeLeft:DWORD ; milliseconds until the item expires
EXTERNDEF obstacleX:BYTE      ; array[MAX_OBSTACLES], obstacle columns
EXTERNDEF obstacleY:BYTE      ; array[MAX_OBSTACLES], obstacle rows
EXTERNDEF obstacleCount:DWORD ; number of obstacles placed
EXTERNDEF score:DWORD
EXTERNDEF highScore:DWORD
EXTERNDEF gameLevel:DWORD
EXTERNDEF foodsEaten:DWORD
EXTERNDEF tickDelay:DWORD     ; ms to wait between moves (used later by the main loop)
EXTERNDEF gameState:DWORD
EXTERNDEF difficulty:DWORD  ; selected DIFF_ value
EXTERNDEF startDelay:DWORD  ; milliseconds before the first level tick
EXTERNDEF delayStep:DWORD   ; milliseconds removed for each level

InitGame      PROTO
PlaceObstacles PROTO
IsObstacle    PROTO
IsCellBlocked PROTO
SpawnFood     PROTO
SpawnSpecial  PROTO
GameTick      PROTO
TogglePause   PROTO
LoadHighScore PROTO
SaveHighScore PROTO
SetDifficulty PROTO

; ---------- Sound ----------
PlayEatSound PROTO
PlayDieSound PROTO
PlayBonusSound PROTO
PlayPoisonSound PROTO
PlayCountdownBeep PROTO
PlayGoBeep PROTO
StartMusic PROTO
ToggleMusic PROTO

; ---------- Screen layout (console is 80 columns x 25 rows) ----------
; Board cell (x, y) is drawn at screen column (x + OFFSET_X), row (y + OFFSET_Y).
OFFSET_X = 1
OFFSET_Y = 3
HUD_ROW = 0
MSG_ROW = 24
; The border is drawn on screen columns 0 and BOARD_WIDTH+1, and on screen rows OFFSET_Y-1 and OFFSET_Y+BOARD_HEIGHT.

; ---------- Results returned by ReadInput ----------
INPUT_NONE = 0
INPUT_QUIT = 1

; ---------- Results returned by WaitMenuChoice ----------
MENU_QUIT = 0
MENU_PLAY = 1

; ---------- Frontend procedures ----------
DrawBorder PROTO
DrawHUD PROTO
DrawSnake PROTO
DrawFood PROTO
DrawSpecial PROTO
DrawObstacles PROTO
DrawAll PROTO
DrawCountdown PROTO
DrawFrame PROTO
DrawMenu PROTO
DrawDifficulty PROTO
DrawGameOver PROTO
DrawPaused PROTO
DrawPauseMenu PROTO
RunPauseMenu PROTO
ParkCursor PROTO
ReadInput PROTO
WaitMenuChoice PROTO
WaitGameOverChoice PROTO
MenuInput PROTO
