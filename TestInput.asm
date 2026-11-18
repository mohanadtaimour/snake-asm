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

	cmp ebx, INPUT_QUIT                ; did ESC stop the test?
	je TestInputDone                   ; yes: finish the test
	jmp TestInputLoop                  ; no: read the next key

TestInputDone:
	call WaitMsg                       ; keep the result window open
	exit                               ; end the test program
main ENDP

END main
