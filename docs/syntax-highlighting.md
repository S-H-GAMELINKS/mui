---
title: Syntax Highlighting
layout: default
nav_order: 7
---

# Syntax Highlighting
{: .no_toc }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

Mui includes built-in syntax highlighting for 9 programming languages. Highlighting is automatic based on file extension.

## Supported Languages

| Language | Extensions |
|----------|------------|
| Ruby | `.rb`, `.rake`, `.gemspec` |
| C | `.c`, `.h`, `.y` |
| Go | `.go` |
| Rust | `.rs` |
| JavaScript | `.js`, `.mjs`, `.cjs`, `.jsx` |
| TypeScript | `.ts`, `.tsx`, `.mts`, `.cts` |
| Markdown | `.md`, `.markdown` |
| HTML | `.html`, `.htm`, `.xhtml` |
| CSS | `.css`, `.scss`, `.sass` |

## Configuration

### Enable/Disable

```ruby
# ~/.muirc
Mui.set :syntax, true   # Enable (default)
Mui.set :syntax, false  # Disable
```

## Language Features

### Ruby

- Keywords (`def`, `class`, `module`, `if`, `end`, etc.)
- Strings (single, double, heredoc)
- Comments (`#`, `=begin`/`=end`)
- Numbers
- Symbols (`:symbol`)
- Constants (`CONSTANT`, `ClassName`)
- Instance variables (`@foo`, `@@bar`)
- Global variables (`$stdout`)
- Method calls (`.to_s`, `.each`)

### C

- Keywords (`int`, `char`, `struct`, `if`, `for`, etc.)
- Strings and character literals
- Comments (`//`, `/* */`)
- Numbers
- Preprocessor directives (`#include`, `#define`)

### Go

- Keywords (`func`, `package`, `import`, `go`, `defer`, etc.)
- Types (`int`, `string`, `bool`, etc.)
- Constants (`true`, `false`, `nil`, `iota`)
- Strings (regular and raw backtick strings)
- Comments (`//`, `/* */`)

### Rust

- Keywords (`fn`, `let`, `mut`, `impl`, `trait`, etc.)
- Macros (`println!`, `vec!`)
- Lifetimes (`'a`, `'static`)
- Attributes (`#[derive]`, `#[cfg]`)
- Doc comments (`///`, `//!`)
- Raw strings (`r#"..."#`)

### JavaScript

- ES6+ keywords (`const`, `let`, `async`, `await`, `class`)
- Template literals (`` `template ${expr}` ``)
- Regex literals (`/pattern/flags`)
- BigInt (`123n`)
- Strings and comments

### TypeScript

All JavaScript features plus:
- Type keywords (`interface`, `type`, `enum`, `declare`, `abstract`)
- Type annotations

### Markdown

- Headings (`#`, `##`, etc.)
- Emphasis (`*italic*`, `**bold**`)
- Code blocks (fenced and indented)
- Links (`[text](url)`)
- Lists (ordered and unordered)
- Blockquotes (`>`)

### HTML

- Tags (`<div>`, `</div>`, `<br/>`)
- Attributes (`class="..."`, `id="..."`)
- Comments (`<!-- -->`)
- DOCTYPE
- Entities (`&amp;`, `&lt;`)

### CSS

- Selectors (`.class`, `#id`, `:pseudo`, `::pseudo-element`)
- Properties and values
- Hex colors (`#fff`, `#ffffff`)
- At-rules (`@media`, `@import`, `@keyframes`)
- Functions (`calc()`, `rgb()`, `var()`)

## Theme Colors

Syntax colors are defined per theme. All 8 built-in themes include syntax highlighting colors:

- `mui` (default)
- `solarized_dark`
- `solarized_light`
- `monokai`
- `nord`
- `gruvbox_dark`
- `dracula`
- `tokyo_night`

Each theme defines colors for:

| Element | Description |
|---------|-------------|
| `syntax_keyword` | Language keywords |
| `syntax_string` | String literals |
| `syntax_comment` | Comments |
| `syntax_number` | Numeric literals |
| `syntax_type` | Types and classes |
| `syntax_function` | Function names |
| `syntax_function_definition` | Function definition names |
| `syntax_variable` | Variables |
| `syntax_constant` | Constants |
| `syntax_operator` | Operators |
| `diagnostic_error` | LSP diagnostic errors |
| `diagnostic_warning` | LSP diagnostic warnings |
| `diagnostic_info` | LSP diagnostic information |
| `diagnostic_hint` | LSP diagnostic hints |
| `floating_window` | Floating window background |
