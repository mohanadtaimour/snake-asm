; =====================================================================
; TestSnake.asm  -  TEMPORARY test program for Snake.asm (Member 1)
;
; It has its own "main" and tests ONLY the Snake Engine procedures.
; It prints every result as:   name   expected=..   actual=..   PASS/FAIL
; When the real game's main is ready, REMOVE this file from the project
; (a project can only have ONE main).
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

; ---------------------------------------------------------------------
; MACROS (small "copy-paste helpers" that the assembler expands for us)
; ---------------------------------------------------------------------

; PrintText "some text"  -> prints the text with WriteString (keeps EDX safe)
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

; CheckDword "name", actual, expected -> compares two 32-bit values.
; "actual" may be any DWORD variable or register.
CheckDword MACRO testName, actualVal, expectedVal
    LOCAL nameStr
    .data
    nameStr BYTE testName, 0
    .code
    mov eax, actualVal                  ; EAX = actual value (read it FIRST)
    mov ebx, expectedVal                ; EBX = expected value
    mov edx, OFFSET nameStr             ; EDX = text with the test name
    call ReportTest
ENDM

; CheckByte "name", actual, expected -> same, but "actual" is a BYTE
; variable or an 8-bit register (it is zero-extended into EAX).
CheckByte MACRO testName, actualVal, expectedVal
    LOCAL nameStr
    .data
    nameStr BYTE testName, 0
    .code
    movzx eax, actualVal                ; EAX = actual byte (read it FIRST)
    mov ebx, expectedVal                ; EBX = expected value
    mov edx, OFFSET nameStr             ; EDX = text with the test name
    call ReportTest
ENDM

; WallCase: test CheckWallHit for the cell (xVal, yVal)
WallCase MACRO caseName, xVal, yVal, expectedVal
    mov dl, xVal                        ; DL = column to test
    mov dh, yVal                        ; DH = row to test
    call CheckWallHit                   ; EAX = 1 (outside) or 0 (inside)
    CheckDword caseName, eax, expectedVal
ENDM

; OnCase: test IsOnSnake for the cell (xVal, yVal)
OnCase MACRO caseName, xVal, yVal, expectedVal
    mov dl, xVal
    mov dh, yVal
    call IsOnSnake                      ; EAX = 1 (on snake) or 0
    CheckDword caseName, eax, expectedVal
ENDM

; SelfCase: test CheckSelfHit for cell (xVal, yVal) with grow flag growVal
SelfCase MACRO caseName, xVal, yVal, growVal, expectedVal
    mov dl, xVal
    mov dh, yVal
    mov bl, growVal                     ; BL = 1 growing, 0 not growing
    call CheckSelfHit                   ; EAX = 1 (hit) or 0
    CheckDword caseName, eax, expectedVal
ENDM

; NextCase: set a direction, call GetNextHead, check column and row
NextCase MACRO colName, rowName, dirVal, expCol, expRow
    mov currentDir, dirVal              ; pretend the snake faces this way
    call GetNextHead                    ; DL = next column, DH = next row
    movzx esi, dl                       ; save the column (the checks below use EDX)
    movzx edi, dh                       ; save the row
    CheckDword colName, esi, expCol
    CheckDword rowName, edi, expRow
ENDM

.data
passCount   DWORD 0                     ; how many checks passed
failCount   DWORD 0                     ; how many checks failed
txtExpected BYTE "   expected=", 0
txtActual   BYTE "   actual=", 0
txtPass     BYTE "   PASS", 0
txtFail     BYTE "   *** FAIL ***", 0

.code

;---------------------------------------------------------------------
ReportTest PROC USES eax ebx edx esi edi
;
; Prints one test line and counts PASS / FAIL.
; Receives: EDX = offset of the test name, EAX = actual value,
;           EBX = expected value
; Returns:  nothing
;---------------------------------------------------------------------
    mov esi, eax                        ; keep the actual value safe
    mov edi, ebx                        ; keep the expected value safe
    call WriteString                    ; print the test name (EDX)
    mov edx, OFFSET txtExpected
    call WriteString
    mov eax, edi                        ; print the expected value
    call WriteDec
    mov edx, OFFSET txtActual
    call WriteString
    mov eax, esi                        ; print the actual value
    call WriteDec
    cmp esi, edi                        ; are they equal?
    jne ReportFailed
    inc passCount                       ; equal -> one more pass
    mov edx, OFFSET txtPass
    jmp ReportPrint
ReportFailed:
    inc failCount                       ; different -> one more fail
    mov edx, OFFSET txtFail
ReportPrint:
    call WriteString                    ; print PASS or FAIL
    call Crlf
    ret
ReportTest ENDP

;---------------------------------------------------------------------
ShowSnake PROC USES eax ecx edx esi
;
; Prints the length, tailErased and every segment as (column,row).
; Receives: nothing      Returns: nothing
;---------------------------------------------------------------------
    PrintText "   length="
    mov eax, snakeLength
    call WriteDec
    PrintText "  tailErased="
    movzx eax, tailErased
    call WriteDec
    PrintText "  segments: "
    mov esi, 0                          ; ESI = segment index
    mov ecx, snakeLength                ; ECX = how many to print
    cmp ecx, 0
    je ShowSnakeDone
ShowSegLoop:
    PrintText "("
    movzx eax, snakeX[esi]
    call WriteDec                       ; column
    PrintText ","
    movzx eax, snakeY[esi]
    call WriteDec                       ; row
    PrintText ") "
    inc esi
    loop ShowSegLoop
ShowSnakeDone:
    call Crlf
    ret
ShowSnake ENDP

;---------------------------------------------------------------------
TestInitSnake PROC
; TEST 1: InitSnake gives length 3, head in the middle, body to the left
;---------------------------------------------------------------------
    call Crlf
    PrintText "TEST 1: InitSnake"
    call Crlf
    call InitSnake
    call ShowSnake
    CheckDword "T1 length", snakeLength, START_LENGTH
    CheckByte  "T1 head column", snakeX[0], BOARD_WIDTH/2
    CheckByte  "T1 head row", snakeY[0], BOARD_HEIGHT/2
    CheckByte  "T1 segment 1 column", snakeX[1], BOARD_WIDTH/2-1
    CheckByte  "T1 segment 2 column", snakeX[2], BOARD_WIDTH/2-2
    CheckByte  "T1 segment 1 row", snakeY[1], BOARD_HEIGHT/2
    CheckByte  "T1 segment 2 row", snakeY[2], BOARD_HEIGHT/2
    CheckDword "T1 currentDir is RIGHT", currentDir, DIR_RIGHT
    CheckByte  "T1 tailErased is 0", tailErased, 0
    ret
TestInitSnake ENDP

;---------------------------------------------------------------------
TestMoveRight PROC
; TEST 2: moving right 3 times moves every segment correctly
;---------------------------------------------------------------------
    call Crlf
    PrintText "TEST 2: move right 3 times (no growing)"
    call Crlf
    call InitSnake
    call ShowSnake                      ; before the first move
    mov ecx, 3                          ; ECX = number of steps
StepRightLoop:
    call GetNextHead                    ; DL,DH = cell in front of the head
    mov bl, 0                           ; not growing
    call MoveSnake                      ; ECX is safe: all procedures keep it
    call ShowSnake                      ; show the snake after each step
    loop StepRightLoop
    CheckDword "T2 length still 3", snakeLength, START_LENGTH
    CheckByte  "T2 head column", snakeX[0], BOARD_WIDTH/2+3
    CheckByte  "T2 segment 1 column", snakeX[1], BOARD_WIDTH/2+2
    CheckByte  "T2 segment 2 column", snakeX[2], BOARD_WIDTH/2+1
    CheckByte  "T2 head row", snakeY[0], BOARD_HEIGHT/2
    CheckByte  "T2 segment 1 row", snakeY[1], BOARD_HEIGHT/2
    CheckByte  "T2 segment 2 row", snakeY[2], BOARD_HEIGHT/2
    ret
TestMoveRight ENDP

;---------------------------------------------------------------------
TestSetDirection PROC
; TEST 3, 4, 5: SetDirection safety rules
;---------------------------------------------------------------------
    ; ---- TEST 3: the opposite direction is ignored ----
    call Crlf
    PrintText "TEST 3: opposite direction is ignored"
    call Crlf
    call InitSnake                      ; snake faces RIGHT
    mov eax, DIR_LEFT                   ; LEFT is the opposite of RIGHT
    call SetDirection
    CheckDword "T3 LEFT ignored, still RIGHT", currentDir, DIR_RIGHT
    mov eax, DIR_DOWN                   ; DOWN is a normal turn
    call SetDirection
    CheckDword "T3 DOWN accepted", currentDir, DIR_DOWN

    ; ---- TEST 4: quick Up-then-Left trick (the lastMovedDir bug) ----
    call Crlf
    PrintText "TEST 4: quick UP then LEFT before the next move"
    call Crlf
    call InitSnake                      ; snake faces RIGHT, lastMovedDir = RIGHT
    mov eax, DIR_UP
    call SetDirection
    CheckDword "T4 UP accepted", currentDir, DIR_UP
    mov eax, DIR_LEFT                   ; opposite of the LAST REAL move (right)
    call SetDirection
    CheckDword "T4 LEFT ignored, still UP", currentDir, DIR_UP

    ; ---- TEST 4b: after a REAL move up, lastMovedDir is UP ----
    call Crlf
    PrintText "TEST 4b: after a real move UP, lastMovedDir becomes UP"
    call Crlf
    call GetNextHead                    ; currentDir is UP
    mov bl, 0
    call MoveSnake                      ; the snake really moves up now
    mov eax, DIR_DOWN                   ; opposite of UP -> must be ignored
    call SetDirection
    CheckDword "T4b DOWN ignored, still UP", currentDir, DIR_UP
    mov eax, DIR_LEFT                   ; LEFT is allowed now
    call SetDirection
    CheckDword "T4b LEFT accepted", currentDir, DIR_LEFT

    ; ---- TEST 5: invalid values are ignored ----
    call Crlf
    PrintText "TEST 5: invalid direction values are ignored"
    call Crlf
    mov eax, 7                          ; 7 is not a direction
    call SetDirection
    CheckDword "T5 value 7 ignored", currentDir, DIR_LEFT
    mov eax, DIR_LEFT + 1               ; 4 is the first invalid value
    call SetDirection
    CheckDword "T5 value 4 ignored", currentDir, DIR_LEFT
    mov eax, 0FFFFFFFFh                 ; -1 is also invalid
    call SetDirection
    CheckDword "T5 value -1 ignored", currentDir, DIR_LEFT
    ret
TestSetDirection ENDP

;---------------------------------------------------------------------
TestGetNextHead PROC
; TEST 6: GetNextHead for all 4 directions + the 255 wrap
;---------------------------------------------------------------------
    call Crlf
    PrintText "TEST 6: GetNextHead (head is in the middle)"
    call Crlf
    call InitSnake
    NextCase "T6 UP column",    "T6 UP row",    DIR_UP,    BOARD_WIDTH/2,   BOARD_HEIGHT/2-1
    NextCase "T6 RIGHT column", "T6 RIGHT row", DIR_RIGHT, BOARD_WIDTH/2+1, BOARD_HEIGHT/2
    NextCase "T6 DOWN column",  "T6 DOWN row",  DIR_DOWN,  BOARD_WIDTH/2,   BOARD_HEIGHT/2+1
    NextCase "T6 LEFT column",  "T6 LEFT row",  DIR_LEFT,  BOARD_WIDTH/2-1, BOARD_HEIGHT/2
    mov snakeX[0], 0                    ; put the head in column 0 ...
    mov snakeY[0], 0                    ; ... and row 0 (top-left corner)
    NextCase "T6 wrap: LEFT from column 0 gives column", "T6 wrap: LEFT keeps row", DIR_LEFT, 0FFh, 0
    NextCase "T6 wrap: UP keeps column", "T6 wrap: UP from row 0 gives row", DIR_UP, 0, 0FFh
    ret
TestGetNextHead ENDP

;---------------------------------------------------------------------
TestGrowAndNormal PROC
; TEST 7: growing, TEST 8: normal move, TEST 9: maximum length
;---------------------------------------------------------------------
    ; ---- TEST 7: growing ----
    call Crlf
    PrintText "TEST 7: one move WITH growing"
    call Crlf
    call InitSnake
    call GetNextHead
    mov bl, 1                           ; grow
    call MoveSnake
    call ShowSnake
    CheckDword "T7 length is 4", snakeLength, START_LENGTH+1
    CheckByte  "T7 tailErased is 0", tailErased, 0
    CheckByte  "T7 head column", snakeX[0], BOARD_WIDTH/2+1
    CheckByte  "T7 segment 1 column", snakeX[1], BOARD_WIDTH/2
    CheckByte  "T7 segment 2 column", snakeX[2], BOARD_WIDTH/2-1
    CheckByte  "T7 old tail stays as segment 3", snakeX[3], BOARD_WIDTH/2-2
    CheckByte  "T7 segment 3 row", snakeY[3], BOARD_HEIGHT/2

    ; ---- TEST 8: normal move ----
    call Crlf
    PrintText "TEST 8: one move WITHOUT growing"
    call Crlf
    call InitSnake
    call GetNextHead
    mov bl, 0                           ; do not grow
    call MoveSnake
    call ShowSnake
    CheckDword "T8 length still 3", snakeLength, START_LENGTH
    CheckByte  "T8 tailErased is 1", tailErased, 1
    CheckByte  "T8 lastTailX", lastTailX, BOARD_WIDTH/2-2
    CheckByte  "T8 lastTailY", lastTailY, BOARD_HEIGHT/2
    CheckByte  "T8 head column", snakeX[0], BOARD_WIDTH/2+1
    CheckByte  "T8 new tail column", snakeX[2], BOARD_WIDTH/2-1

    ; ---- TEST 9: growing at maximum length ----
    call Crlf
    PrintText "TEST 9: grow request when the snake is already at MAX_SNAKE_LEN"
    call Crlf
    call InitSnake
    mov snakeLength, MAX_SNAKE_LEN      ; pretend the snake is full
    mov dl, 1                           ; any new head cell
    mov dh, 1
    mov bl, 1                           ; ask to grow
    call MoveSnake
    CheckDword "T9 length stays at maximum", snakeLength, MAX_SNAKE_LEN
    CheckByte  "T9 tailErased is 1 (acts like a normal move)", tailErased, 1
    CheckByte  "T9 head column", snakeX[0], 1
    ret
TestGrowAndNormal ENDP

;---------------------------------------------------------------------
TestWallHit PROC
; TEST 10: CheckWallHit at all 4 edges (inside and outside)
;---------------------------------------------------------------------
    call Crlf
    PrintText "TEST 10: CheckWallHit"
    call Crlf
    WallCase "T10 middle of board", BOARD_WIDTH/2, BOARD_HEIGHT/2, 0
    WallCase "T10 left edge, column 0 is inside", 0, 5, 0
    WallCase "T10 left of board, column 255 (wrapped -1)", 0FFh, 5, 1
    WallCase "T10 right edge, last column is inside", BOARD_WIDTH-1, 5, 0
    WallCase "T10 right of board, column BOARD_WIDTH", BOARD_WIDTH, 5, 1
    WallCase "T10 top edge, row 0 is inside", 5, 0, 0
    WallCase "T10 above board, row 255 (wrapped -1)", 5, 0FFh, 1
    WallCase "T10 bottom edge, last row is inside", 5, BOARD_HEIGHT-1, 0
    WallCase "T10 below board, row BOARD_HEIGHT", 5, BOARD_HEIGHT, 1
    ret
TestWallHit ENDP

;---------------------------------------------------------------------
TestIsOnSnake PROC
; TEST 11: IsOnSnake on body cells and on empty cells
;---------------------------------------------------------------------
    call Crlf
    PrintText "TEST 11: IsOnSnake (fresh snake in the middle)"
    call Crlf
    call InitSnake
    OnCase "T11 head cell", BOARD_WIDTH/2, BOARD_HEIGHT/2, 1
    OnCase "T11 middle body cell", BOARD_WIDTH/2-1, BOARD_HEIGHT/2, 1
    OnCase "T11 tail cell", BOARD_WIDTH/2-2, BOARD_HEIGHT/2, 1
    OnCase "T11 empty cell far away", 5, 5, 0
    OnCase "T11 empty cell just behind the tail", BOARD_WIDTH/2-3, BOARD_HEIGHT/2, 0
    OnCase "T11 same column as head, other row", BOARD_WIDTH/2, BOARD_HEIGHT/2+1, 0
    OnCase "T11 cell 0,0 (unused array slots hold 0)", 0, 0, 0
    ret
TestIsOnSnake ENDP

;---------------------------------------------------------------------
TestSelfHit PROC
; TEST 12: CheckSelfHit, including the "tail cell" rule
; Snake used (a 2x2 loop), head = index 0, tail = index 3:
;      col 10  col 11
; row 10  HEAD    TAIL
; row 11  seg1    seg2
;---------------------------------------------------------------------
    call Crlf
    PrintText "TEST 12: CheckSelfHit (snake curled in a 2x2 square)"
    call Crlf
    mov snakeLength, 4
    mov snakeX[0], 10                   ; head (10,10)
    mov snakeY[0], 10
    mov snakeX[1], 10                   ; segment 1 (10,11)
    mov snakeY[1], 11
    mov snakeX[2], 11                   ; segment 2 (11,11)
    mov snakeY[2], 11
    mov snakeX[3], 11                   ; tail (11,10)
    mov snakeY[3], 10
    call ShowSnake
    SelfCase "T12 into TAIL cell, not growing = safe", 11, 10, 0, 0
    SelfCase "T12 into TAIL cell, growing = hit", 11, 10, 1, 1
    SelfCase "T12 into middle body, not growing = hit", 11, 11, 0, 1
    SelfCase "T12 into segment 1, not growing = hit", 10, 11, 0, 1
    SelfCase "T12 empty cell, not growing = safe", 12, 10, 0, 0
    SelfCase "T12 empty cell, growing = safe", 12, 10, 1, 0
    ret
TestSelfHit ENDP

;---------------------------------------------------------------------
TestRegisters PROC
; TEST 13: the procedures must keep EBX, ECX, ESI, EDI unchanged
;---------------------------------------------------------------------
    call Crlf
    PrintText "TEST 13: registers are preserved by all procedures"
    call Crlf
    mov ebx, 12345600h                  ; BL = 0 (also "do not grow")
    mov ecx, 22222222h
    mov esi, 33333333h
    mov edi, 44444444h
    call InitSnake
    mov eax, DIR_UP
    call SetDirection
    call GetNextHead                    ; DL,DH = new head cell
    call CheckWallHit
    call IsOnSnake
    call CheckSelfHit
    call MoveSnake
    ; NOTE: CheckDword itself overwrites EAX, EBX and EDX, so EBX is checked FIRST
    CheckDword "T13 EBX unchanged", ebx, 12345600h
    CheckDword "T13 ECX unchanged", ecx, 22222222h
    CheckDword "T13 ESI unchanged", esi, 33333333h
    CheckDword "T13 EDI unchanged", edi, 44444444h
    ret
TestRegisters ENDP

;---------------------------------------------------------------------
main PROC
;---------------------------------------------------------------------
    PrintText "===== Snake.asm unit tests ====="
    call Crlf
    call TestInitSnake
    call TestMoveRight
    call TestSetDirection
    call TestGetNextHead
    call TestGrowAndNormal
    call TestWallHit
    call TestIsOnSnake
    call TestSelfHit
    call TestRegisters

    call Crlf
    PrintText "===== RESULT:  passed = "
    mov eax, passCount
    call WriteDec
    PrintText "   failed = "
    mov eax, failCount
    call WriteDec
    call Crlf
    call WaitMsg                        ; keep the window open
    exit
main ENDP

END main
