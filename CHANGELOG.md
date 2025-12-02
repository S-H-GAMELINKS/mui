## [Unreleased]

### Added
- Initial release of Mui, a Vim-like text editor written in Ruby
- Vim-like modal editing with five modes:
  - Normal mode: Navigation and text manipulation
  - Insert mode: Text input
  - Command mode: Ex commands
  - Visual mode (`v`): Character-wise selection
  - Visual Line mode (`V`): Line-wise selection
- Basic cursor movement with `h`, `j`, `k`, `l` and arrow keys in Normal mode
- Arrow key cursor movement in Insert mode
- Motion commands:
  - Word movements: `w` (word forward), `b` (word backward), `e` (word end)
  - Line movements: `0` (line start), `^` (first non-blank), `$` (line end)
  - File movements: `gg` (file start), `G` (file end)
  - Character search: `f{char}`, `F{char}`, `t{char}`, `T{char}`
- Text editing operations:
  - `i` to insert before cursor
  - `a` to append after cursor
  - `o` to open new line below
  - `O` to open new line above
  - `x` to delete character at cursor
  - Backspace to delete and join lines
- Ex commands:
  - `:w` to save file
  - `:w <filename>` to save as
  - `:q` to quit (with unsaved changes protection)
  - `:q!` to force quit
  - `:wq` to save and quit
- Curses-based terminal UI with:
  - Buffer management
  - Window with scrolling support
  - Status line display
  - Command line input
- Visual mode features:
  - Selection highlighting with reverse video
  - Toggle between Visual and Visual Line mode with `v`/`V`
  - All motion commands supported (h, j, k, l, w, b, e, 0, ^, $, gg, G, f, F, t, T)
  - Exit to Normal mode with `Esc`
- Comprehensive test suite for `Mui::Input` and `Mui::Editor` classes
  - Unit tests for Buffer, CommandLine, Input, Screen, Window, Selection, and Editor modes
  - Integration tests for component interactions
  - E2E tests with ScriptRunner DSL for Vim operation scenarios including Visual mode
- Test infrastructure with Curses mock and `MuiTestHelper` module

### Changed
- Reorganized test directory structure to follow standard gem conventions
  - Unit tests moved to `test/mui/`
  - Editor mode tests in `test/mui/editor/`
  - Integration tests in `test/integration/`
  - E2E tests in `test/e2e/`
- Refactored test files to use nested classes per method for better readability

## [0.1.0] - 2025-11-30

- Initial release
