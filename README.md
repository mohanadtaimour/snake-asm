# Snake Game - 32-bit x86 MASM

Computer Architecture 26EEC5303 Snake game using 32-bit x86 MASM and Irvine32.

## Requirements

- Visual Studio 2026 (VS 18) is the Visual Studio version detected on this machine. The project currently targets the v145 platform toolset. To use another Visual Studio version, right-click the project, choose Properties, open General, and change Platform Toolset to the installed version.
- Irvine32 installed at c:\Irvine.

## Build and run

1. Open Project.sln in Visual Studio.
2. Choose Debug and Win32.
3. Press Ctrl+F5 to build and run without debugging.

## Files

- SnakeDefs.inc - shared contract: constants, EXTERNDEF declarations, and prototypes.
- Snake.asm - snake engine.
- Game.asm - game rules and high-score handling.
- TestSnake.asm - unit tests for the snake engine.
- Display.asm - not added yet; will handle drawing and display.
- Input.asm - not added yet; will handle keyboard input.
- Main.asm - not added yet; will contain the main entry point.

## Tests

When Main.asm is added to the project, exclude TestSnake.asm from the build: right-click the file, choose Properties, and set Excluded From Build to Yes for both Debug and Release. Keep TestSnake.asm in the repository because it is needed for the test report.

## Controls

- Arrow keys or WASD: move
- P: pause
- ESC: quit

The game creates highscore.dat next to where the program runs. Visual Studio is configured to use the project folder as the working directory.
