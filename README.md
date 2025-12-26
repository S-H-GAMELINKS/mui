# Mui (無為)

A Vim-like TUI text editor written in Ruby.

> **無為 (むい, mui)** - "Effortless action" from Taoist philosophy.
> *"Form without forcing, existing as it is. Yet from nothing, something is born."*

## Installation

```bash
gem install mui
```

## Usage

```bash
mui [file]
```

## Features

### Modal Editing

Vim-like modal editing with five modes:

- **Normal mode**: Navigation and text manipulation
- **Insert mode**: Text input with auto-completion
- **Command mode**: Ex commands (`:w`, `:q`, `:e`, etc.)
- **Visual mode** (`v`): Character-wise selection
- **Visual Line mode** (`V`): Line-wise selection

### Tab Pages and Window Splits

- **Tab pages**: `:tabnew`, `:tabclose`, `gt`/`gT` to switch
- **Horizontal split**: `:sp [file]`
- **Vertical split**: `:vs [file]`
- **Window navigation**: `Ctrl-w h/j/k/l` or `Ctrl-w w`

### Syntax Highlighting

Supports 9 languages:

- Ruby (`.rb`, `.rake`, `.gemspec`)
- C (`.c`, `.h`, `.y`)
- Go (`.go`)
- Rust (`.rs`)
- JavaScript (`.js`, `.mjs`, `.cjs`, `.jsx`)
- TypeScript (`.ts`, `.tsx`, `.mts`, `.cts`)
- Markdown (`.md`, `.markdown`)
- HTML (`.html`, `.htm`, `.xhtml`)
- CSS (`.css`, `.scss`, `.sass`)

### Search

- Forward search: `/pattern`
- Backward search: `?pattern`
- Next/previous match: `n`/`N`
- Word under cursor: `*` (forward), `#` (backward)
- Incremental search with real-time highlighting

### Undo/Redo

- Undo: `u`
- Redo: `Ctrl-r`
- Insert mode changes grouped as single undo unit

### Named Registers

- Named registers: `"a` - `"z`
- Unnamed register: `""`
- Yank register: `"0`
- Delete history: `"1` - `"9`
- Black hole register: `"_`

### Clipboard Integration

System clipboard integration (Vim's `clipboard` option):

```ruby
# Enable clipboard integration in ~/.muirc
Mui.set :clipboard, :unnamedplus
```

- Yank/delete operations sync to system clipboard
- Paste operations sync from system clipboard
- Named registers (`"a`-`"z`) are not affected
- Supports WSL, macOS, and Linux (X11/Wayland)

### Completion

- Command-line completion with popup
- Buffer word completion in Insert mode (`Ctrl-n`/`Ctrl-p`)
- LSP completion support (via [mui-lsp](https://github.com/S-H-GAMELINKS/mui-lsp) gem)

### Multi-key Sequences and Leader Key

```ruby
# Set leader key (default: backslash)
Mui.set :leader, " "  # Space as leader

# Define multi-key mappings
Mui.keymap :normal, "<Leader>ff" do |ctx|
  # Find file
end
```

Supports:
- `<Leader>` notation
- Control keys: `<C-x>`, `<C-S-x>`
- Special keys: `<Space>`, `<Tab>`, `<CR>`, `<Esc>`, `<BS>`

### Other Features

- Japanese and multibyte character support (UTF-8)
- Floating windows for hover info
- Asynchronous job execution
- External shell command execution (`:!cmd`)
- Command history with persistence

## Key Bindings

### Normal Mode

| Key | Action |
|-----|--------|
| `h`, `j`, `k`, `l` | Cursor movement |
| `w`, `b`, `e` | Word movement |
| `0`, `^`, `$` | Line movement |
| `gg`, `G` | File start/end |
| `f{char}`, `t{char}` | Find character |
| `i`, `a`, `o`, `O` | Enter Insert mode |
| `v`, `V` | Enter Visual mode |
| `d`, `c`, `y` | Delete/Change/Yank operators |
| `p`, `P` | Paste after/before |
| `u`, `Ctrl-r` | Undo/Redo |
| `/`, `?` | Search forward/backward |
| `n`, `N` | Next/previous match |
| `*`, `#` | Search word under cursor |
| `gt`, `gT` | Next/previous tab |
| `gv` | Reselect last visual selection |
| `Ctrl-w` + `h/j/k/l` | Window navigation |

### Visual Mode

| Key | Action |
|-----|--------|
| `d` | Delete selection |
| `c` | Change selection |
| `y` | Yank selection |
| `>`, `<` | Indent/unindent |
| `Esc` | Exit to Normal mode |

### Command Mode

| Command | Action |
|---------|--------|
| `:w` | Save file |
| `:q` | Quit |
| `:wq` | Save and quit |
| `:e <file>` | Open file |
| `:sp [file]` | Horizontal split |
| `:vs [file]` | Vertical split |
| `:tabnew [file]` | New tab |
| `:!cmd` | Run shell command |

## Configuration

Mui can be configured via `~/.muirc` (global) or `.lmuirc` (project-local).

```ruby
# ~/.muirc

# Color scheme
Mui.set :colorscheme, "tokyo_night"

# Editor settings
Mui.set :tabstop, 4
Mui.set :shiftwidth, 4
Mui.set :expandtab, true
Mui.set :syntax, true

# Leader key
Mui.set :leader, " "

# YJIT (enabled by default on Ruby 3.3+)
Mui.set :use_yjit, true

# Custom keymaps
Mui.keymap :normal, "<Leader>w" do |ctx|
  ctx.editor.execute_command("w")
end

# Custom commands
Mui.command :hello do |ctx|
  ctx.set_message("Hello, World!")
end

# Autocmd
Mui.autocmd :BufWritePre, pattern: "*.rb" do |ctx|
  # Before saving Ruby files
end
```

### Available Themes

- `mui` (default)
- `solarized_dark`
- `solarized_light`
- `monokai`
- `nord`
- `gruvbox_dark`
- `dracula`
- `tokyo_night`

## Plugin System

Mui supports plugins via Ruby gems.

### Official Plugins

- [mui-lsp](https://github.com/S-H-GAMELINKS/mui-lsp) - LSP (Language Server Protocol) support
- [mui-git](https://github.com/S-H-GAMELINKS/mui-git) - Git integration
- [mui-fzf](https://github.com/S-H-GAMELINKS/mui-fzf) - Fuzzy finder integration with fzf

### Using Plugins

```ruby
# ~/.muirc
Mui.use "mui-lsp"
Mui.use "mui-git"
Mui.use "mui-fzf"
```

### Creating Plugins

```ruby
# Class-based plugin
class MyPlugin < Mui::Plugin
  name :my_plugin

  def setup
    command :greet do |ctx|
      ctx.set_message("Hello from MyPlugin!")
    end

    keymap :normal, "<Leader>g" do |ctx|
      ctx.editor.execute_command("greet")
    end

    autocmd :BufEnter, pattern: "*.txt" do |ctx|
      ctx.set_message("Opened a text file")
    end
  end
end
```

### Asynchronous Job Execution

Plugins can run background tasks without blocking the editor:

```ruby
class MyAsyncPlugin < Mui::Plugin
  name :my_async_plugin

  def setup
    # Run a shell command asynchronously
    command :run_tests do |ctx|
      ctx.run_shell_command("bundle exec rake test") do |result|
        if result[:success]
          ctx.open_scratch_buffer("[Test Results]", result[:stdout])
        else
          ctx.set_error("Tests failed: #{result[:stderr]}")
        end
      end
    end

    # Run a Ruby block asynchronously
    command :fetch_data do |ctx|
      ctx.run_async do
        # This runs in a background thread
        sleep 2  # Simulate long operation
        "Data fetched!"
      end
    end

    # Check if jobs are running
    command :job_status do |ctx|
      if ctx.jobs_running?
        ctx.set_message("Jobs are running...")
      else
        ctx.set_message("No jobs running")
      end
    end
  end
end
```

Available job methods:
- `ctx.run_async { ... }` - Run a Ruby block in background
- `ctx.run_shell_command(cmd) { |result| ... }` - Run shell command asynchronously
- `ctx.jobs_running?` - Check if any jobs are active
- `ctx.cancel_job(id)` - Cancel a running job
- `ctx.open_scratch_buffer(name, content)` - Display results in a scratch buffer

Autocmd events for jobs:
- `JobStarted` - When a job begins
- `JobCompleted` - When a job finishes successfully
- `JobFailed` - When a job fails
- `JobCancelled` - When a job is cancelled

### Interactive Command Execution

Plugins can run interactive external commands:

```ruby
class FzfPlugin < Mui::Plugin
  name :fzf

  def setup
    command :Files do |ctx|
      if ctx.command_exists?("fzf")
        result = ctx.run_interactive_command("fzf")
        ctx.editor.execute_command("e #{result}") if result && !result.empty?
      else
        ctx.set_error("fzf is not installed")
      end
    end
  end
end
```

### LSP Configuration

```ruby
# ~/.muirc
Mui.use "mui-lsp"

Mui.lsp do
  use :ruby  # Use preset configuration

  # Or custom server
  server :custom_lsp,
    command: ["my-lsp", "--stdio"],
    filetypes: ["mylang"]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

```bash
git clone https://github.com/S-H-GAMELINKS/mui.git
cd mui
bin/setup
rake test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/S-H-GAMELINKS/mui.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
