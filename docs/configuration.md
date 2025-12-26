---
title: Configuration
layout: default
nav_order: 4
---

# Configuration
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Configuration Files

Mui supports two configuration files:

| File | Scope |
|------|-------|
| `~/.muirc` | Global settings (all projects) |
| `.lmuirc` | Local settings (current directory) |

Local settings (`.lmuirc`) override global settings (`~/.muirc`).

Configuration files are written in Ruby using Mui's DSL.

## Basic Settings

### Color Scheme

```ruby
Mui.set :colorscheme, "tokyo_night"
```

Available themes (all themes support 256-color palette with 8-color fallback):

| Theme | Description |
|-------|-------------|
| `mui` | Default theme with eye-friendly gray-based colors |
| `solarized_dark` | Solarized dark theme |
| `solarized_light` | Solarized light theme |
| `monokai` | Monokai theme |
| `nord` | Nord theme |
| `gruvbox_dark` | Gruvbox dark theme |
| `dracula` | Dracula theme |
| `tokyo_night` | Tokyo Night theme |

### 256-Color Support

All bundled themes utilize 256-color palettes for rich syntax highlighting and UI elements. Mui automatically detects your terminal's color capabilities:

- **256-color terminals**: Full color palette with all theme colors
- **8-color terminals**: Automatic fallback to basic 8-color equivalents

Most modern terminals (iTerm2, gnome-terminal, Windows Terminal, etc.) support 256 colors. If colors appear incorrect, ensure your terminal's `TERM` environment variable is set correctly (e.g., `xterm-256color`).

### Indentation

```ruby
# Number of spaces for Tab display
Mui.set :tabstop, 4

# Number of spaces for indent operations (>, <)
Mui.set :shiftwidth, 4

# Use spaces instead of tabs
Mui.set :expandtab, true
```

### Syntax Highlighting

```ruby
# Enable/disable syntax highlighting
Mui.set :syntax, true
```

### Leader Key

```ruby
# Set leader key (default: backslash)
Mui.set :leader, " "  # Space as leader
```

### Key Timeout

```ruby
# Timeout for multi-key sequences (milliseconds)
Mui.set :timeoutlen, 1000
```

### YJIT

```ruby
# Enable/disable YJIT (default: true, Ruby 3.3+ only)
Mui.set :use_yjit, true
```

YJIT is Ruby's Just-In-Time compiler that improves performance. When enabled, Mui automatically activates YJIT at startup if your Ruby version supports it (Ruby 3.3+). On older Ruby versions, this setting is safely ignored.

### Clipboard

```ruby
# Enable system clipboard integration
Mui.set :clipboard, :unnamedplus
```

| Value | Description |
|-------|-------------|
| `nil` | Disabled (default) |
| `:unnamed` | Sync with system clipboard |
| `:unnamedplus` | Sync with system clipboard (same as `:unnamed`) |

When enabled:
- **Yank** (`yy`, `yw`, `y` in Visual mode) copies to system clipboard
- **Delete** (`dd`, `dw`, `d` in Visual mode) copies to system clipboard
- **Paste** (`p`, `P`) reads from system clipboard
- **Named registers** (`"a`-`"z`) are not affected by clipboard sync
- **Black hole register** (`"_`) discards without clipboard sync

Platform support (via `clipboard` gem):
- **macOS**: Uses `pbcopy`/`pbpaste`
- **Linux**: Uses `xclip` or `xsel` (X11) / `wl-copy`/`wl-paste` (Wayland)
- **WSL**: Uses `clip.exe` and PowerShell

---

## Custom Key Mappings

Define custom key bindings with `Mui.keymap`:

```ruby
Mui.keymap :mode, "key" do |ctx|
  # action
end
```

### Modes

- `:normal` - Normal mode
- `:insert` - Insert mode
- `:visual` - Visual mode
- `:command` - Command mode

### Examples

```ruby
# Save with <Leader>w
Mui.keymap :normal, "<Leader>w" do |ctx|
  ctx.editor.execute_command("w")
end

# Quick escape in Insert mode
Mui.keymap :insert, "jk" do |ctx|
  ctx.change_mode(:normal)
end

# Close buffer with <Leader>q
Mui.keymap :normal, "<Leader>q" do |ctx|
  ctx.editor.execute_command("q")
end
```

### Special Key Notation

| Notation | Key |
|----------|-----|
| `<Leader>` | Leader key |
| `<Space>` | Space bar |
| `<Tab>` | Tab key |
| `<S-Tab>`, `<btab>` | Shift+Tab |
| `<CR>`, `<Enter>` | Enter key |
| `<Esc>` | Escape key |
| `<BS>` | Backspace |
| `<C-x>` | Ctrl+x |
| `<C-S-x>` | Ctrl+Shift+x |
| `<S-x>` | Shift+x |

### Multi-key Sequences

```ruby
# <Leader>ff for find files
Mui.keymap :normal, "<Leader>ff" do |ctx|
  ctx.editor.execute_command("Files")
end

# <Leader>fg for grep
Mui.keymap :normal, "<Leader>fg" do |ctx|
  ctx.editor.execute_command("Rg")
end

# Ctrl-x Ctrl-s to save (Emacs style)
Mui.keymap :normal, "<C-x><C-s>" do |ctx|
  ctx.editor.execute_command("w")
end
```

---

## Custom Commands

Define custom Ex commands with `Mui.command`:

```ruby
Mui.command :name do |ctx|
  # action
end
```

### Examples

```ruby
# Simple greeting
Mui.command :hello do |ctx|
  ctx.set_message("Hello, World!")
end

# Command with arguments
Mui.command :echo do |ctx, *args|
  ctx.set_message(args.join(" "))
end

# Open configuration file
Mui.command :config do |ctx|
  ctx.editor.execute_command("e ~/.muirc")
end
```

---

## Autocmd Events

Execute code when events occur with `Mui.autocmd`:

```ruby
Mui.autocmd :event, pattern: "*.ext" do |ctx|
  # action
end
```

### Available Events

| Event | Trigger |
|-------|---------|
| `BufEnter` | When entering a buffer |
| `BufLeave` | When leaving a buffer |
| `BufWrite` | When writing a buffer |
| `BufWritePre` | Before writing a buffer |
| `BufWritePost` | After writing a buffer |
| `ModeChanged` | When mode changes |
| `CursorMoved` | When cursor moves |
| `TextChanged` | When text is modified |
| `InsertEnter` | When entering Insert mode |
| `InsertLeave` | When leaving Insert mode |
| `InsertCompletion` | When completion is triggered |
| `JobStarted` | When a job starts |
| `JobCompleted` | When a job completes |
| `JobFailed` | When a job fails |
| `JobCancelled` | When a job is cancelled |

### Examples

```ruby
# Auto-save on leaving Insert mode
Mui.autocmd :InsertLeave do |ctx|
  ctx.editor.execute_command("w") if ctx.buffer.modified?
end

# Show message when opening Ruby files
Mui.autocmd :BufEnter, pattern: "*.rb" do |ctx|
  ctx.set_message("Ruby file loaded")
end

# Format before saving
Mui.autocmd :BufWritePre, pattern: "*.rb" do |ctx|
  # Run formatter
end
```

---

## Using Plugins

Load plugins with `Mui.use`:

```ruby
Mui.use "mui-lsp"
Mui.use "mui-git"
Mui.use "mui-fzf"
```

See [Plugins]({{ site.baseurl }}/plugins) for more details.

---

## Complete Example

```ruby
# ~/.muirc

# Appearance
Mui.set :colorscheme, "tokyo_night"
Mui.set :syntax, true

# Indentation
Mui.set :tabstop, 2
Mui.set :shiftwidth, 2
Mui.set :expandtab, true

# Leader key
Mui.set :leader, " "

# YJIT (Ruby 3.3+)
Mui.set :use_yjit, true

# Clipboard integration
Mui.set :clipboard, :unnamedplus

# Plugins
Mui.use "mui-lsp"
Mui.use "mui-fzf"

# Key mappings
Mui.keymap :normal, "<Leader>w" do |ctx|
  ctx.editor.execute_command("w")
end

Mui.keymap :normal, "<Leader>q" do |ctx|
  ctx.editor.execute_command("q")
end

Mui.keymap :normal, "<Leader>ff" do |ctx|
  ctx.editor.execute_command("Files")
end

# Custom commands
Mui.command :reload do |ctx|
  ctx.editor.execute_command("e")
  ctx.set_message("File reloaded")
end

# LSP configuration
Mui.lsp do
  use :ruby

  # TypeScript (requires typescript-language-server)
  server :typescript,
    command: ["typescript-language-server", "--stdio"],
    filetypes: ["typescript", "typescriptreact", "javascript", "javascriptreact"]
end
```
