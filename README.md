# Snake Game - 32-bit x86 MASM

Computer Architecture 26EEC5303 Snake game using 32-bit x86 MASM and Irvine32.

## Features

- Main menu with Easy, Normal and Hard difficulty.
- 3-2-1 countdown before every round.
- Normal food, golden food (3x points), timed bonus and poison items, and fixed obstacles.
- Pause menu (Resume, Restart, Quit to menu) and an R key to play again after game over.
- Game-over stats screen with a NEW HIGH SCORE message and a saved high score.
- Sound effects and looping background music using the Win32 Beep function.
- Cartoon look made only from plain ASCII characters and colors.

## Requirements

- Visual Studio 2026 (toolset v145) is required, or retarget the project for another installed Visual Studio version: right-click the project, choose Properties, open General, and change Platform Toolset.
- Irvine32 must be installed at c:\Irvine.

## Build and run

1. Open Project.sln.
2. Choose Debug and Win32.
3. Press Ctrl+F5 to build and run.

## Files

The backend folder holds the snake engine, game rules and sound with their tests. The frontend folder holds drawing, keyboard input, the main loop and their tests. SnakeDefs.inc stays at the repository root as the shared contract.

- SnakeDefs.inc - shared contract. Used by the whole team.
- backend\Snake.asm - Member 1 owns the snake engine.
- backend\TestSnake.asm - Member 1 owns the snake-engine unit tests.
- frontend\Display.asm - Member 1 owns drawing and display.
- frontend\TestDisplay.asm - Member 1 owns the visual display tests.
- backend\Game.asm - Member 2 owns game rules, difficulty, obstacles, food and special items, and high-score handling.
- backend\Sound.asm - sound effects and background music. It must stay included in every build.
- frontend\Input.asm - Member 2 owns keyboard input, menus and the pause menu.
- frontend\Main.asm - Member 2 owns the real main loop and entry point.
- backend\TestGame.asm - Member 2 owns the game-rule unit tests.
- frontend\TestInput.asm - Member 2 owns the keyboard input test.
- docs\TestCases.txt - test plan with expected results.
- highscore.dat is created next to the running program.

## Tests

For each test file, temporarily set Excluded From Build to No for that test file and set Excluded From Build to Yes for Main.asm. Build and run the test file. There can only be one main in the build. Restore the final settings afterward: every test file is excluded in Debug and Release, and Main.asm is included. Sound.asm is never excluded.

TestGame.asm resets obstacleCount, foodType and specialType after every InitGame call, so its results do not depend on the random board.

## Controls

Main menu:
- ENTER: play
- 1, 2, 3: choose Easy, Normal or Hard
- ESC: quit

During play:
- Arrow keys or WASD: move
- P: open the pause menu
- M: turn the background music on or off
- ESC: quit the game and return to the menu (the high score is saved)

Pause menu:
- Up/Down arrows or W/S: move the selection
- ENTER: choose Resume, Restart or Quit to menu
- P or ESC: resume

Game over:
- ENTER or R: play again
- ESC: back to the menu

## Game rules

Difficulty sets the move delay. The delay shrinks every level and never goes below 50 ms.

| Difficulty | Start delay | Faster per level |
| --- | --- | --- |
| Easy | 200 ms | 10 ms |
| Normal | 150 ms | 15 ms |
| Hard | 100 ms | 12 ms |

Food and items:
- Normal food (red @): 10 points times the level.
- Golden food (yellow $): about one food in five, worth 3 times the normal points.
- Every third food eaten, a timed special item appears for 6 seconds and blinks in its last 2 seconds:
  - Bonus (cyan %): 50 points times the level.
  - Poison (magenta X): minus 20 points, never below 0.
  - Special items do not grow the snake and do not count toward levels.
- The level goes up every 5 normal or golden foods.
- Eight fixed obstacles (gray blocks) are placed each round. The three rows around the snake's start row are kept clear. Hitting an obstacle, a wall or your own body ends the game.

## Score file

The game creates highscore.dat next to where the program runs. Visual Studio uses the project folder as the working directory.
