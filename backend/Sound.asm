; =====================================================================
; Sound.asm - GAME SOUND EFFECTS
; Computer Architecture (26EEC5303) - Snake game, 32-bit x86 MASM
;
; This file plays short sound effects using the Win32 Beep function.
; Every procedure preserves all registers for its caller.
; =====================================================================

INCLUDE Irvine32.inc
INCLUDE SnakeDefs.inc

Beep PROTO, dwFreq:DWORD, dwDuration:DWORD
CreateThread PROTO STDCALL, lpThreadAttributes:DWORD, dwStackSize:DWORD, lpStartAddress:DWORD, lpParameter:DWORD, dwCreationFlags:DWORD, lpThreadId:DWORD
Sleep PROTO STDCALL, dwMilliseconds:DWORD

.data
musicEnabled DWORD 1                  ; music starts enabled
musicThread DWORD 0                   ; zero means no music thread has started
melodyFrequencies DWORD 523, 659, 784, 659, 587, 784, 880, 784 ; C, E, G, E, D, G, A, G
                  DWORD 523, 587, 659, 784, 880, 784, 659, 523 ; C, D, E, G, A, G, E, C
melodyDurations DWORD 140, 140, 180, 140, 140, 140, 180, 140
                 DWORD 140, 140, 180, 160, 180, 140, 140, 200

.code

;---------------------------------------------------------------------
MusicThreadProc PROC lpParam:DWORD
;
; Plays the melody while enabled and the game is in the playing state.
; Receives: lpParam = unused thread parameter
; Returns:  never returns (the music worker loops for the process lifetime)
;---------------------------------------------------------------------
    pushad                             ; save all registers for the thread procedure
    mov ebx, lpParam                   ; use the initial note index passed by StartMusic
MusicThreadLoop:
    cmp musicEnabled, 1                ; is background music enabled?
    jne MusicThreadSleep               ; no: pause the melody
    cmp gameState, STATE_PLAYING       ; is an active game running?
    jne MusicThreadSleep               ; no: pause in menu, pause or game-over

    mov eax, melodyFrequencies[ebx * 4] ; EAX holds this note frequency
    mov edx, melodyDurations[ebx * 4]  ; EDX holds this note duration
    INVOKE Beep, eax, edx              ; play the note on the worker thread
    inc ebx                            ; advance to the next melody note
    cmp ebx, LENGTHOF melodyFrequencies ; did the melody reach its end?
    jb MusicThreadLoop                 ; no: continue with the next note
    mov ebx, 0                         ; yes: wrap back to the first note
    jmp MusicThreadLoop                ; repeat the melody

MusicThreadSleep:
    INVOKE Sleep, 50                   ; yield while music is disabled or not playing
    jmp MusicThreadLoop                ; check music and state again

MusicThreadExit:
    popad                              ; restore all registers for the thread procedure
    mov eax, 0                         ; return a zero thread exit code
    ret                                ; provide the standard thread return path
MusicThreadProc ENDP

;---------------------------------------------------------------------
StartMusic PROC
;
; Starts the background music worker once.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
    pushad                             ; save all registers for the caller
    cmp musicThread, 0                 ; has the music thread already started?
    jne StartMusicDone                 ; yes: do not create another thread
    INVOKE CreateThread, 0, 0, ADDR MusicThreadProc, 0, 0, 0 ; start worker
    mov musicThread, eax               ; remember the thread handle
StartMusicDone:
    popad                              ; restore all registers for the caller
    ret                                ; return to the main program
StartMusic ENDP

;---------------------------------------------------------------------
ToggleMusic PROC
;
; Toggles background music on or off.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
    pushad                             ; save all registers for the caller
    xor musicEnabled, 1                ; flip the enabled flag between zero and one
    popad                              ; restore all registers for the caller
    ret                                ; return to the input handler
ToggleMusic ENDP

;---------------------------------------------------------------------
PlayEatSound PROC
;
; Plays a short high tone when the snake eats food.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                          ; save all registers for the caller
	INVOKE Beep, 880, 40             ; play the 880 Hz eat tone for 40 ms
	popad                           ; restore all registers
	ret                             ; return to the caller
PlayEatSound ENDP

;---------------------------------------------------------------------
PlayDieSound PROC
;
; Plays three descending tones when the snake dies.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                          ; save all registers for the caller
	INVOKE Beep, 400, 120            ; play the first descending tone
	INVOKE Beep, 300, 120            ; play the second descending tone
	INVOKE Beep, 200, 200            ; play the final low tone
	popad                           ; restore all registers
	ret                             ; return to the caller
PlayDieSound ENDP

;---------------------------------------------------------------------
PlayBonusSound PROC
;
; Plays two rising tones for a bonus event.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                          ; save all registers for the caller
	INVOKE Beep, 1200, 60            ; play the first rising tone
	INVOKE Beep, 1500, 60            ; play the second rising tone
	popad                           ; restore all registers
	ret                             ; return to the caller
PlayBonusSound ENDP

;---------------------------------------------------------------------
PlayPoisonSound PROC
;
; Plays a low tone for a poison event.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                          ; save all registers for the caller
	INVOKE Beep, 200, 150            ; play the low poison tone
	popad                           ; restore all registers
	ret                             ; return to the caller
PlayPoisonSound ENDP

;---------------------------------------------------------------------
PlayCountdownBeep PROC
;
; Plays a short countdown tone.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                          ; save all registers for the caller
	INVOKE Beep, 600, 100            ; play the countdown tone
	popad                           ; restore all registers
	ret                             ; return to the caller
PlayCountdownBeep ENDP

;---------------------------------------------------------------------
PlayGoBeep PROC
;
; Plays the go tone after a countdown.
; Receives: nothing
; Returns:  nothing (all registers are preserved)
;---------------------------------------------------------------------
	pushad                          ; save all registers for the caller
	INVOKE Beep, 1000, 250           ; play the go tone
	popad                           ; restore all registers
	ret                             ; return to the caller
PlayGoBeep ENDP

END
