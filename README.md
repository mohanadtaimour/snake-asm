# Snake ASM

## Visual Studio

The project is configured for Visual Studio 2026 with the v145 platform toolset. This machine has Visual Studio 2026 Community (VS 18) installed. The v145 toolset directory is not present in this installation, so teammates may need to retarget the project.

To retarget it, right-click the project in Solution Explorer, choose Properties, open General, and change Platform Toolset to the version installed with your Visual Studio.
## Tests

When Main.asm is added to the project, right-click TestSnake.asm, choose Properties, and set Excluded From Build to Yes for both Debug and Release. Keep the file in the repository because it is needed for the test report.
