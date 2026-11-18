; =====================================================================
; TestInput.asm - TEMPORARY test program for Input.asm
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This program prints the direction and game state after each key.
; It does not use Display.asm and is excluded from the final build.
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

.data
guide1 BYTE "Test Input: try arrows or W/A/S/D",0
guide2 BYTE "Try P twice, then try P in a menu/game-over state",0
guide3 BYTE "Press ESC to end this test",0
directionText BYTE " direction=",0
stateText BYTE " state=",0
resultText BYTE " inputResult=",0
prevDirection DWORD 0FFFFFFFFh
prevState DWORD 0FFFFFFFFh
prevInput DWORD 0FFFFFFFFh

.code

;---------------------------------------------------------------------
PrintTextLine PROC USES eax edx
;
; Prints a stored line of guide text and moves to the next line.
; Receives: EDX = text address
; Returns:  nothing
;---------------------------------------------------------------------
	call WriteString                   ; print the guide or status text
	call Crlf                          ; move to the next line
	ret                                ; USES restores all registers
PrintTextLine ENDP

;---------------------------------------------------------------------
main PROC
;
; Reads keys until ESC and prints the resulting direction and state.
; Receives: nothing
; Returns:  nothing
;---------------------------------------------------------------------
	call InitGame                      ; initialize playing state and snake

	mov edx, OFFSET guide1             ; EDX points to the first guide line
	call PrintTextLine                 ; print the first test instruction
	mov edx, OFFSET guide2             ; EDX points to the second guide line
	call PrintTextLine                 ; print the second test instruction
	mov edx, OFFSET guide3             ; EDX points to the ESC instruction
	call PrintTextLine                 ; print the ESC instruction

TestInputLoop:
	call ReadInput                     ; read and apply all waiting keys
	mov ebx, eax                       ; EBX saves the input result

	mov eax, currentDir                ; EAX holds the current direction
	cmp eax, prevDirection             ; did the direction change?
	jne PrintInputStatus               ; yes: print a status line
	mov eax, gameState                 ; EAX holds the current state
	cmp eax, prevState                 ; did the state change?
	jne PrintInputStatus               ; yes: print a status line
	cmp ebx, prevInput                 ; did the input result change?
	je SkipInputStatus                 ; no: do not print a status line

PrintInputStatus:
	mov eax, currentDir                ; EAX holds current direction
	mov prevDirection, eax             ; remember the printed direction
	mov eax, gameState                 ; EAX holds current state
	mov prevState, eax                 ; remember the printed state
	mov prevInput, ebx                 ; remember the printed input result

	mov edx, OFFSET directionText      ; EDX points to direction label
	call WriteString                   ; print direction label
	mov eax, currentDir                ; EAX holds current direction
	call WriteDec                      ; print direction

	mov edx, OFFSET stateText          ; EDX points to state label
	call WriteString                   ; print state label
	mov eax, gameState                 ; EAX holds game state
	call WriteDec                      ; print game state

	mov edx, OFFSET resultText         ; EDX points to input-result label
	call WriteString                   ; print input-result label
	mov eax, ebx                       ; EAX holds the saved input result
	call WriteDec                      ; print INPUT_NONE or INPUT_QUIT
	call Crlf                          ; move to the next status line

SkipInputStatus:
	cmp ebx, INPUT_QUIT                ; did ESC stop the test?
	je TestInputDone                   ; yes: finish the test
	mov eax, 30                        ; Delay receives milliseconds in EAX
	call Delay                         ; wait before checking the keyboard again
	jmp TestInputLoop                  ; read the next key

TestInputDone:
	call WaitMsg                       ; keep the result window open
	exit                               ; end the test program
main ENDP

END main
