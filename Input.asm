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

END
