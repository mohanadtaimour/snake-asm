# Snake Game - 32-bit x86 MASM

Computer Architecture 26EEC5303 Snake game using 32-bit x86 MASM and Irvine32.

## Requirements

- Visual Studio 2026 (toolset v145) is required, or retarget the project for another installed Visual Studio version: right-click the project, choose Properties, open General, and change Platform Toolset.
- Irvine32 must be installed at c:\Irvine.

## Build and run

1. Open Project.sln.
2. Choose Debug and Win32.
3. Press Ctrl+F5 to build and run.

ESC during play returns to the menu. The high score is saved on death and when quitting a game.

## Files

- SnakeDefs.inc - shared contract. Used by the whole team.
- Snake.asm - Member 1 owns the snake engine.
- TestSnake.asm - Member 1 owns the snake-engine unit tests.
- Display.asm - Member 1 owns drawing and display.
- TestDisplay.asm - Member 1 owns the visual display tests.
- Game.asm - Member 2 owns game rules and high-score handling.
- Input.asm - Member 2 owns keyboard input.
- Main.asm - Member 2 owns the real main loop and entry point.
- TestGame.asm - Member 2 owns the game-rule unit tests.
- TestInput.asm - Member 2 owns the keyboard input test.
- highscore.dat is created next to the running program.

## Tests

For each test file, temporarily set Excluded From Build to No for that test file and set Excluded From Build to Yes for Main.asm. Build and run the test file. There can only be one main in the build. Restore the final settings afterward: every test file is excluded in Debug and Release, and Main.asm is included.

## Controls

- Arrow keys or WASD: move
- P: pause or resume
- ESC: quit a game or choose menu/exit

## Score file

The game creates highscore.dat next to where the program runs. Visual Studio uses the project folder as the working directory.
