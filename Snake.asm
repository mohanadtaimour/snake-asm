; =====================================================================
; Snake.asm  -  MEMBER 1: THE SNAKE ENGINE
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This file owns ALL the data and logic of the snake's body:
;   - where every segment is,   - moving,   - growing,
;   - changing direction,       - detecting crashes.
; It does NOT draw anything and does NOT read the keyboard.
; It never prints to the screen. It only stores data and does logic.
; =====================================================================

INCLUDE Irvine32.inc          ; Irvine library (also sets .386, .model flat,stdcall, stack)
INCLUDE SnakeDefs.inc         ; shared contract: constants, EXTERNDEF, PROTO

.data
; ---------------------------------------------------------------------
; The snake is stored in TWO PARALLEL ARRAYS.
; Segment number i is at column snakeX[i] and row snakeY[i].
; Index 0 is the HEAD. Index (snakeLength - 1) is the TAIL.
; ---------------------------------------------------------------------
snakeX       BYTE MAX_SNAKE_LEN DUP(0)   ; column of every segment (0 = head)
snakeY       BYTE MAX_SNAKE_LEN DUP(0)   ; row of every segment    (0 = head)
snakeLength  DWORD 0                     ; how many segments the snake has now
currentDir   DWORD DIR_RIGHT             ; direction the snake will move NEXT
lastTailX    BYTE 0                      ; column of the cell the tail just left
lastTailY    BYTE 0                      ; row of the cell the tail just left
tailErased   BYTE 0                      ; 1 = tail left a cell, 0 = snake grew

; PRIVATE variable (not in SnakeDefs.inc): the direction the snake REALLY
; moved the last time MoveSnake ran. SetDirection compares with this one.
lastMovedDir DWORD DIR_RIGHT

.code

;---------------------------------------------------------------------
InitSnake PROC USES eax ecx esi
;
; Resets the snake for a brand new game. The snake gets START_LENGTH
; segments. The head is in the middle of the board and the other
; segments are to the LEFT of the head in the same row, so the snake
; starts facing right.
; Receives: nothing
; Returns:  nothing (snakeLength, snakeX, snakeY, currentDir,
;           lastMovedDir and tailErased are set)
;---------------------------------------------------------------------
    mov snakeLength, START_LENGTH       ; the snake starts with 3 segments
    mov esi, 0                          ; ESI = index of the segment we fill (0 = head)
    mov ecx, START_LENGTH               ; ECX = how many segments to fill (loop counter)

InitFillLoop:
    mov eax, BOARD_WIDTH / 2            ; EAX = middle column (where the head goes)
    sub eax, esi                        ; segment i is i cells to the LEFT of the head
    mov snakeX[esi], al                 ; store that column (a column fits in 1 byte, so use AL)
    mov snakeY[esi], BOARD_HEIGHT / 2   ; every segment is in the middle row
    inc esi                             ; go to the next segment
    loop InitFillLoop                   ; ECX = ECX - 1, repeat while ECX is not 0

    mov currentDir, DIR_RIGHT           ; the snake starts moving to the right
    mov lastMovedDir, DIR_RIGHT         ; and its last real move is also "right"
    mov tailErased, 0                   ; nothing has been erased yet
    ret                                 ; USES pops EAX, ECX, ESI for us
InitSnake ENDP

;---------------------------------------------------------------------
SetDirection PROC USES ebx
;
; Changes the direction of the snake, but only if the new direction is
; allowed. Two safety rules:
;   1) A value that is not 0..3 is ignored.
;   2) A direction that is the OPPOSITE of the direction the snake last
;      REALLY moved (lastMovedDir) is ignored. We compare with
;      lastMovedDir and NOT with currentDir, otherwise the player could
;      press Up then Left quickly (before the next move) and turn the
;      snake back into its own neck.
; Receives: EAX = new direction (0..3)
; Returns:  nothing (currentDir may change)
;---------------------------------------------------------------------
    cmp eax, DIR_LEFT                   ; DIR_LEFT (3) is the biggest valid direction
    ja SetDirDone                       ; unsigned "above": 4, 7, or even -1 are all invalid -> ignore

    mov ebx, eax                        ; copy the new direction so EAX stays unchanged
    add ebx, 2                          ; opposite direction = (dir + 2) ...
    and ebx, 3                          ; ... AND 3 (wraps 4 -> 0 and 5 -> 1)
    cmp ebx, lastMovedDir               ; is the new direction the opposite of the last real move?
    je SetDirDone                       ; yes -> a snake cannot turn straight back, ignore it

    mov currentDir, eax                 ; the direction is allowed, so save it
SetDirDone:
    ret                                 ; USES restores EBX
SetDirection ENDP

;---------------------------------------------------------------------
GetNextHead PROC USES eax
;
; Works out which cell the head WOULD enter next, using currentDir.
; It does NOT move the snake. Plain byte inc/dec is used on purpose:
; if the head is in column 0 and goes left, DL becomes 255 (0FFh). The
; same happens for row 0 and DH. CheckWallHit catches these values.
; Receives: nothing
; Returns:  DL = next column, DH = next row
;---------------------------------------------------------------------
    mov dl, snakeX[0]                   ; DL = column of the current head
    mov dh, snakeY[0]                   ; DH = row of the current head
    mov eax, currentDir                 ; EAX = direction we are going to move in

    cmp eax, DIR_UP                     ; going up?
    je NextHeadUp
    cmp eax, DIR_RIGHT                  ; going right?
    je NextHeadRight
    cmp eax, DIR_DOWN                   ; going down?
    je NextHeadDown
                                        ; if none matched, the direction is DIR_LEFT
    dec dl                              ; left: column - 1 (0 wraps to 255)
    jmp NextHeadDone

NextHeadUp:
    dec dh                              ; up: row - 1 (0 wraps to 255)
    jmp NextHeadDone

NextHeadRight:
    inc dl                              ; right: column + 1
    jmp NextHeadDone

NextHeadDown:
    inc dh                              ; down: row + 1

NextHeadDone:
    ret                                 ; USES restores EAX
GetNextHead ENDP

;---------------------------------------------------------------------
CheckWallHit PROC
;
; Tells whether a cell is OUTSIDE the board. The comparisons are
; UNSIGNED. A "negative" coordinate wraps around to a huge number
; (-1 becomes 255), so it is also "above or equal" to the board size.
; That means ONE check per axis catches both edges of that axis.
; Receives: DL = column, DH = row
; Returns:  EAX = 1 if the cell is outside the board, otherwise 0
;---------------------------------------------------------------------
    cmp dl, BOARD_WIDTH                 ; unsigned compare: column vs. board width
    jae WallHitFound                    ; column >= 40 (or wrapped from -1 to 255) -> outside
    cmp dh, BOARD_HEIGHT                ; unsigned compare: row vs. board height
    jae WallHitFound                    ; row >= 20 (or wrapped from -1 to 255) -> outside

    mov eax, 0                          ; both are inside -> no wall hit
    jmp WallHitDone
WallHitFound:
    mov eax, 1                          ; outside the board -> wall hit
WallHitDone:
    ret
CheckWallHit ENDP

;---------------------------------------------------------------------
ScanSegments PROC PRIVATE USES ecx esi
;
; PRIVATE helper used by IsOnSnake and CheckSelfHit (not in the .inc
; file, other files cannot call it). Looks at the FIRST ECX segments
; (index 0 up to ECX-1) and checks whether one of them is in cell DL,DH.
; Receives: DL = column, DH = row, ECX = how many segments to check
; Returns:  EAX = 1 if one of those segments is in that cell, else 0
;---------------------------------------------------------------------
    mov esi, 0                          ; ESI = index of the segment being checked
    cmp ecx, 0                          ; nothing to check?
    je ScanNotFound                     ; (also protects "loop" from running 4 billion times)

ScanLoop:
    cmp dl, snakeX[esi]                 ; same column as this segment?
    jne ScanNext                        ; no -> this segment cannot match, try the next one
    cmp dh, snakeY[esi]                 ; same row as this segment too?
    je ScanFound                        ; column AND row match -> found it
ScanNext:
    inc esi                             ; move to the next segment
    loop ScanLoop                       ; ECX = ECX - 1, repeat while ECX is not 0

ScanNotFound:
    mov eax, 0                          ; no segment was on that cell
    jmp ScanDone
ScanFound:
    mov eax, 1                          ; a segment is on that cell
ScanDone:
    ret                                 ; USES restores ECX and ESI
ScanSegments ENDP

;---------------------------------------------------------------------
IsOnSnake PROC USES ecx
;
; Tells whether ANY segment of the snake (index 0 to snakeLength-1) is
; on the given cell. Game.asm uses it so food never appears on the snake.
; Receives: DL = column, DH = row
; Returns:  EAX = 1 if a segment is on that cell, otherwise 0
;---------------------------------------------------------------------
    mov ecx, snakeLength                ; check ALL the segments
    call ScanSegments                   ; EAX = 1 or 0
    ret                                 ; USES restores ECX
IsOnSnake ENDP

;---------------------------------------------------------------------
CheckSelfHit PROC USES ecx
;
; Tells whether the new head cell would hit the snake's own body.
; If the snake is NOT growing, the tail leaves its cell during this
; same move, so entering the current tail cell is SAFE: we skip the
; last segment. If the snake IS growing, the tail stays, so we check
; ALL segments.
; Receives: DL = new head column, DH = new head row,
;           BL = 1 if the snake grows this move, 0 if not
; Returns:  EAX = 1 if the head would hit the body, otherwise 0
;---------------------------------------------------------------------
    mov ecx, snakeLength                ; start with "check all segments"
    cmp bl, 0                           ; is the snake growing?
    jne SelfHitScan                     ; yes (BL = 1) -> the tail stays, check every segment
    cmp ecx, 0                          ; safety: never subtract from an empty snake
    je SelfHitScan
    dec ecx                             ; not growing -> ignore the last segment (the tail)
SelfHitScan:
    call ScanSegments                   ; EAX = 1 if the head cell is on one of those segments
    ret                                 ; USES restores ECX
CheckSelfHit ENDP

;---------------------------------------------------------------------
MoveSnake PROC USES eax ecx esi
;
; Moves the whole snake ONE step. It does NOT check for crashes
; (GameTick checks first, then calls this).
;  - Growing (and not at MAX_SNAKE_LEN): the length goes up by 1, the
;    tail stays where it is, and tailErased = 0.
;  - Otherwise: the old tail cell is saved in lastTailX/lastTailY and
;    tailErased = 1, so the screen code knows which cell to erase.
;  - Then every segment is copied one place toward the back
;    (segment i goes to i+1), going from the BACK to the FRONT.
;  - The new head cell is written into index 0.
; Receives: DL = new head column, DH = new head row,
;           BL = 1 if the snake grows this move, 0 if not
; Returns:  nothing
;---------------------------------------------------------------------
    cmp bl, 0                           ; is the snake supposed to grow?
    je MoveNoGrow                       ; no -> normal move
    cmp snakeLength, MAX_SNAKE_LEN      ; yes, but is there still room in the arrays?
    jae MoveNoGrow                      ; already at maximum length -> behave like a normal move

    inc snakeLength                     ; the snake is one segment longer now
    mov tailErased, 0                   ; the tail stays, so the screen must not erase anything
    jmp MoveShift                       ; go and shift the segments

MoveNoGrow:
    mov esi, snakeLength                ; ESI = length ...
    dec esi                             ; ... minus 1 = index of the tail
    mov al, snakeX[esi]                 ; read the tail column
    mov lastTailX, al                   ; remember it, the screen must erase this cell
    mov al, snakeY[esi]                 ; read the tail row
    mov lastTailY, al                   ; remember it as well
    mov tailErased, 1                   ; tell the screen code there is a cell to erase

MoveShift:
    mov ecx, snakeLength                ; ECX = length (this is the NEW length if we grew)
    dec ecx                             ; copies needed = length - 1 (the head is written later)
    cmp ecx, 0                          ; a 1-segment snake has nothing to shift
    je MoveWriteHead
    mov esi, snakeLength                ; ESI = length ...
    dec esi                             ; ... minus 1 = index of the LAST segment (the destination)

ShiftLoop:
    mov al, snakeX[esi - 1]             ; read the column of the segment in FRONT of this one
    mov snakeX[esi], al                 ; copy it into this segment
    mov al, snakeY[esi - 1]             ; read the row of the segment in front
    mov snakeY[esi], al                 ; copy it into this segment
    dec esi                             ; go one step toward the front
    loop ShiftLoop                      ; ECX = ECX - 1, repeat while ECX is not 0

MoveWriteHead:
    mov snakeX[0], dl                   ; the new head column goes into index 0
    mov snakeY[0], dh                   ; the new head row goes into index 0
    mov eax, currentDir                 ; the direction we just moved in ...
    mov lastMovedDir, eax               ; ... is now the "last REAL move" (SetDirection uses it)
    ret                                 ; USES restores EAX, ECX, ESI
MoveSnake ENDP

END
