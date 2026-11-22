; =====================================================================
; Input.asm - MEMBER 2: KEYBOARD INPUT
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This file reads the console keyboard and sends direction or pause
; commands to the backend. It does not draw anything.
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

VK_LEFT = 25h
VK_UP = 26h
VK_RIGHT = 27h
VK_DOWN = 28h
KEY_ESC = 27
KEY_ENTER = 13

.code

;---------------------------------------------------------------------
ReadInput PROC
;
; Drains the keyboard buffer and applies all waiting input keys.
; Receives: nothing
; Returns:  EAX = INPUT_NONE or INPUT_QUIT
;---------------------------------------------------------------------
	push ebx                           ; save EBX used for the result
	push ecx                           ; save ECX used by called procedures
	push edx                           ; save EDX used by ReadKey
	push esi                           ; save ESI for caller use
	push edi                           ; save EDI for caller use
	push ebp                           ; save EBP for caller use

	mov ebx, INPUT_NONE                ; assume no quit key was found
ReadKeyLoop:
	call ReadKey                       ; Irvine checks one key without waiting
	jz ReadInputDone                   ; ZF = 1 means no key remains

	cmp al, KEY_ESC                    ; is this the ESC ASCII key?
	je ReadEscape                      ; yes: quit the game

	cmp dx, VK_LEFT                    ; is the virtual key LEFT?
	je ReadLeft                        ; yes: map it to left
	cmp dx, VK_UP                      ; is the virtual key UP?
	je ReadUp                          ; yes: map it to up
	cmp dx, VK_RIGHT                   ; is the virtual key RIGHT?
	je ReadRight                       ; yes: map it to right
	cmp dx, VK_DOWN                    ; is the virtual key DOWN?
	je ReadDown                        ; yes: map it to down

	cmp al, 'W'                        ; is the key uppercase W?
	je ReadUp                          ; yes: map W to up
	cmp al, 'w'                        ; is the key lowercase w?
	je ReadUp                          ; yes: map W to up
	cmp al, 'A'                        ; is the key uppercase A?
	je ReadLeft                        ; yes: map A to left
	cmp al, 'a'                        ; is the key lowercase a?
	je ReadLeft                        ; yes: map A to left
	cmp al, 'S'                        ; is the key uppercase S?
	je ReadDown                        ; yes: map S to down
	cmp al, 's'                        ; is the key lowercase s?
	je ReadDown                        ; yes: map S to down
	cmp al, 'D'                        ; is the key uppercase D?
	je ReadRight                       ; yes: map D to right
	cmp al, 'd'                        ; is the key lowercase d?
	je ReadRight                       ; yes: map D to right

	cmp al, 'M'                        ; is the key uppercase M?
	je ReadMusic                       ; yes: toggle background music
	cmp al, 'm'                        ; is the key lowercase m?
	je ReadMusic                       ; yes: toggle background music

	cmp al, 'P'                        ; is the key uppercase P?
	je ReadPause                       ; yes: toggle pause
	cmp al, 'p'                        ; is the key lowercase p?
	je ReadPause                       ; yes: toggle pause
	jmp ReadKeyLoop                    ; ignored key: drain the next key

ReadEscape:
	mov ebx, INPUT_QUIT                ; remember that ESC was pressed
	jmp ReadInputDone                  ; stop reading and return

ReadLeft:
	cmp gameState, STATE_PLAYING       ; direction keys work only while playing
	jne ReadKeyLoop                    ; paused or menu: ignore this key
	mov eax, DIR_LEFT                  ; EAX receives the direction argument
	call SetDirection                  ; ask the snake engine to set it
	jmp ReadKeyLoop                    ; drain the next key

ReadUp:
	cmp gameState, STATE_PLAYING       ; direction keys work only while playing
	jne ReadKeyLoop                    ; paused or menu: ignore this key
	mov eax, DIR_UP                    ; EAX receives the direction argument
	call SetDirection                  ; ask the snake engine to set it
	jmp ReadKeyLoop                    ; drain the next key

ReadRight:
	cmp gameState, STATE_PLAYING       ; direction keys work only while playing
	jne ReadKeyLoop                    ; paused or menu: ignore this key
	mov eax, DIR_RIGHT                 ; EAX receives the direction argument
	call SetDirection                  ; ask the snake engine to set it
	jmp ReadKeyLoop                    ; drain the next key

ReadDown:
	cmp gameState, STATE_PLAYING       ; direction keys work only while playing
	jne ReadKeyLoop                    ; paused or menu: ignore this key
	mov eax, DIR_DOWN                  ; EAX receives the direction argument
	call SetDirection                  ; ask the snake engine to set it
	jmp ReadKeyLoop                    ; drain the next key

ReadMusic:
	call ToggleMusic                   ; enable or disable background music
	jmp ReadKeyLoop                    ; continue draining waiting keys

ReadPause:
	cmp gameState, STATE_PLAYING       ; P works in the playing state
	je ReadTogglePause                 ; toggle to paused
	cmp gameState, STATE_PAUSED        ; P also works in the paused state
	jne ReadKeyLoop                    ; menu or game over: ignore P
ReadTogglePause:
	call TogglePause                   ; switch between playing and paused
	jmp ReadKeyLoop                    ; drain the next key

ReadInputDone:
	mov eax, ebx                       ; EAX receives the return value
	pop ebp                            ; restore EBP
	pop edi                            ; restore EDI
	pop esi                            ; restore ESI
	pop edx                            ; restore EDX
	pop ecx                            ; restore ECX
	pop ebx                            ; restore EBX
	ret                                ; only EAX holds the requested result
ReadInput ENDP

;---------------------------------------------------------------------
WaitMenuChoice PROC
;
; Blocks until ENTER or ESC is read from the console.
; Receives: nothing
; Returns:  EAX = MENU_PLAY or MENU_QUIT
;---------------------------------------------------------------------
	push ebx                           ; save EBX used for the result
	push ecx                           ; save ECX for caller use
	push edx                           ; save EDX for caller use
	push esi                           ; save ESI for caller use
	push edi                           ; save EDI for caller use
	push ebp                           ; save EBP for caller use

WaitChoiceLoop:
	call ReadChar                      ; block until the user presses a character
	cmp al, KEY_ENTER                  ; is the character ENTER?
	je WaitPlayChoice                  ; yes: select play
	cmp al, KEY_ESC                    ; is the character ESC?
	je WaitQuitChoice                  ; yes: select quit
	jmp WaitChoiceLoop                 ; any other character is ignored

WaitPlayChoice:
	mov ebx, MENU_PLAY                 ; remember the play menu choice
	jmp WaitChoiceDone                 ; return the menu result

WaitQuitChoice:
	mov ebx, MENU_QUIT                 ; remember the quit menu choice

WaitChoiceDone:
	mov eax, ebx                       ; EAX receives the menu result
	pop ebp                            ; restore EBP
	pop edi                            ; restore EDI
	pop esi                            ; restore ESI
	pop edx                            ; restore EDX
	pop ecx                            ; restore ECX
	pop ebx                            ; restore EBX
	ret                                ; only EAX holds the requested result
WaitMenuChoice ENDP

;---------------------------------------------------------------------
WaitGameOverChoice PROC
;
; Blocks until ENTER, R, or ESC is read from the console.
; Receives: nothing
; Returns:  EAX = MENU_PLAY or MENU_QUIT
;---------------------------------------------------------------------
	push ebx                           ; save EBX used for the result
	push ecx                           ; save ECX for caller use
	push edx                           ; save EDX for caller use
	push esi                           ; save ESI for caller use
	push edi                           ; save EDI for caller use
	push ebp                           ; save EBP for caller use

WaitGameOverChoiceLoop:
	call ReadChar                      ; block until the user presses a character
	cmp al, KEY_ENTER                  ; is the character ENTER?
	je WaitGameOverPlay                ; yes: select play
	cmp al, 'R'                        ; is the character uppercase R?
	je WaitGameOverPlay                ; yes: select play
	cmp al, 'r'                        ; is the character lowercase r?
	je WaitGameOverPlay                ; yes: select play
	cmp al, KEY_ESC                    ; is the character ESC?
	je WaitGameOverQuit                ; yes: select quit
	jmp WaitGameOverChoiceLoop         ; any other character is ignored

WaitGameOverPlay:
	mov ebx, MENU_PLAY                 ; remember the play choice
	jmp WaitGameOverChoiceDone         ; return the game-over result

WaitGameOverQuit:
	mov ebx, MENU_QUIT                 ; remember the quit choice

WaitGameOverChoiceDone:
	mov eax, ebx                       ; EAX receives the menu result
	pop ebp                            ; restore EBP
	pop edi                            ; restore EDI
	pop esi                            ; restore ESI
	pop edx                            ; restore EDX
	pop ecx                            ; restore ECX
	pop ebx                            ; restore EBX
	ret                                ; only EAX holds the requested result
WaitGameOverChoice ENDP

;---------------------------------------------------------------------
MenuInput PROC
;
; Waits for ENTER, ESC or a difficulty selection in the menu.
; Receives: nothing
; Returns:  EAX = MENU_PLAY or MENU_QUIT
;---------------------------------------------------------------------
	push ebx                           ; save EBX used for the menu result
	push ecx                           ; save ECX for caller use
	push edx                           ; save EDX for caller use
	push esi                           ; save ESI for caller use
	push edi                           ; save EDI for caller use
	push ebp                           ; save EBP for caller use

MenuInputLoop:
	call ReadChar                      ; wait for one menu key
	cmp al, KEY_ENTER                  ; did the player choose to play?
	je MenuPlayChoice                  ; yes: return MENU_PLAY
	cmp al, KEY_ESC                    ; did the player choose to quit?
	je MenuQuitChoice                  ; yes: return MENU_QUIT
	cmp al, '1'                         ; did the player select Easy?
	je MenuChooseEasy                  ; yes: update and redraw difficulty
	cmp al, '2'                         ; did the player select Normal?
	je MenuChooseNormal                ; yes: update and redraw difficulty
	cmp al, '3'                         ; did the player select Hard?
	je MenuChooseHard                  ; yes: update and redraw difficulty
	jmp MenuInputLoop                  ; ignore any other key

MenuChooseEasy:
	mov eax, DIFF_EASY                  ; EAX selects Easy
	call SetDifficulty                 ; store Easy speed settings
	call DrawDifficulty                ; update the highlighted choice
	jmp MenuInputLoop                  ; continue waiting for a menu choice

MenuChooseNormal:
	mov eax, DIFF_NORMAL                ; EAX selects Normal
	call SetDifficulty                 ; store Normal speed settings
	call DrawDifficulty                ; update the highlighted choice
	jmp MenuInputLoop                  ; continue waiting for a menu choice

MenuChooseHard:
	mov eax, DIFF_HARD                  ; EAX selects Hard
	call SetDifficulty                 ; store Hard speed settings
	call DrawDifficulty                ; update the highlighted choice
	jmp MenuInputLoop                  ; continue waiting for a menu choice

MenuPlayChoice:
	mov ebx, MENU_PLAY                  ; remember the play choice
	jmp MenuInputDone                  ; return the menu result

MenuQuitChoice:
	mov ebx, MENU_QUIT                  ; remember the quit choice

MenuInputDone:
	mov eax, ebx                        ; EAX receives the menu result
	pop ebp                             ; restore EBP
	pop edi                             ; restore EDI
	pop esi                             ; restore ESI
	pop edx                             ; restore EDX
	pop ecx                             ; restore ECX
	pop ebx                             ; restore EBX
	ret                                 ; only EAX holds the requested result
MenuInput ENDP

;---------------------------------------------------------------------
RunPauseMenu PROC
;
; Handles pause-menu navigation and returns the selected action.
; Receives: nothing
; Returns:  EAX = PAUSE_RESUME, PAUSE_RESTART, or PAUSE_QUIT
;---------------------------------------------------------------------
	push ebx                           ; save EBX for the selected result
	push ecx                           ; save ECX for caller use
	push edx                           ; save EDX for keyboard input
	push esi                           ; save ESI for the current selection
	push edi                           ; save EDI for caller use
	push ebp                           ; save EBP for caller use
	mov esi, PAUSE_RESUME              ; start with Resume selected
	mov eax, esi                       ; EAX selects the first menu item
	call DrawPauseMenu                 ; draw the pause menu
RunPauseMenuLoop:
	call ReadKey                       ; read one key without blocking
	jz RunPauseMenuNoKey                ; no key is waiting
	cmp al, KEY_ENTER                  ; did the player activate the selection?
	je RunPauseMenuSelected            ; yes: return the selected item
	cmp al, KEY_ESC                    ; did the player press ESC?
	je RunPauseMenuResume              ; ESC resumes the game
	cmp al, 'P'                        ; did the player press uppercase P?
	je RunPauseMenuResume              ; P resumes the game
	cmp al, 'p'                        ; did the player press lowercase p?
	je RunPauseMenuResume              ; P resumes the game
	cmp dx, VK_UP                      ; did the player press the up arrow?
	je RunPauseMenuUp                  ; yes: move selection upward
	cmp al, 'W'                        ; did the player press uppercase W?
	je RunPauseMenuUp                  ; yes: move selection upward
	cmp al, 'w'                        ; did the player press lowercase w?
	je RunPauseMenuUp                  ; yes: move selection upward
	cmp dx, VK_DOWN                    ; did the player press the down arrow?
	je RunPauseMenuDown                ; yes: move selection downward
	cmp al, 'S'                        ; did the player press uppercase S?
	je RunPauseMenuDown                ; yes: move selection downward
	cmp al, 's'                        ; did the player press lowercase s?
	je RunPauseMenuDown                ; yes: move selection downward
	jmp RunPauseMenuDelay              ; ignore other keys after the delay
RunPauseMenuNoKey:
	mov eax, 10                        ; Delay receives ten milliseconds
	call Delay                         ; wait briefly before checking again
	jmp RunPauseMenuLoop               ; continue waiting for menu input
RunPauseMenuUp:
	cmp esi, PAUSE_RESUME              ; is Resume currently selected?
	jne RunPauseMenuMoveUp             ; no: decrement the selection
	mov esi, PAUSE_QUIT                ; wrap upward to Quit to menu
	jmp RunPauseMenuRedraw             ; redraw the selected item
RunPauseMenuMoveUp:
	dec esi                            ; move to the previous menu item
	jmp RunPauseMenuRedraw             ; redraw the selected item
RunPauseMenuDown:
	cmp esi, PAUSE_QUIT                ; is Quit to menu currently selected?
	jne RunPauseMenuMoveDown           ; no: increment the selection
	mov esi, PAUSE_RESUME              ; wrap downward to Resume
	jmp RunPauseMenuRedraw             ; redraw the selected item
RunPauseMenuMoveDown:
	inc esi                            ; move to the next menu item
RunPauseMenuRedraw:
	mov eax, esi                       ; EAX holds the current selection
	call DrawPauseMenu                 ; redraw the highlighted item
RunPauseMenuDelay:
	mov eax, 10                        ; Delay receives ten milliseconds
	call Delay                         ; wait briefly before the next key check
	jmp RunPauseMenuLoop               ; continue waiting for menu input
RunPauseMenuSelected:
	mov ebx, esi                       ; return the selected menu action
	jmp RunPauseMenuDone               ; finish the pause-menu routine
RunPauseMenuResume:
	mov ebx, PAUSE_RESUME              ; P or ESC selects Resume
RunPauseMenuDone:
	mov eax, ebx                       ; EAX receives the selected action
	pop ebp                            ; restore EBP
	pop edi                            ; restore EDI
	pop esi                            ; restore ESI
	pop edx                            ; restore EDX
	pop ecx                            ; restore ECX
	pop ebx                            ; restore EBX
	ret                                ; return the pause-menu action in EAX
RunPauseMenu ENDP

END
