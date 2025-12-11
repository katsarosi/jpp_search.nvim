# jpp-search.nvim

Run `jpp` queries against the current JSON buffer (or visual selection) without blocking Neovim. Results can be shown in the quickfix list, a floating window, or Telescope (if installed).

> Minimal, reliable, Lazy.nvim-compatible. Scopes to `json`/`jsonc` only.

---

## Features

- Prompt for a `jpp` query and run against the **current buffer** or **current visual selection**
- Non-blocking execution via `jobstart` with streaming input (handles large files gracefully)
- Multiple render targets: **quickfix** (default), **floating window**, **Telescope** (auto-detected)
- Buffer-local commands & keymaps attached only on `FileType=json,jsonc`
- Friendly errors for missing `jpp` or invalid queries

---

## Requirements

- **Neovim** ≥ 0.8
- **Lazy.nvim** already installed & configured (you can open `:Lazy` inside Neovim)
- **`jpp` CLI** available on `$PATH` (or configured via `opts.bin`)

### Verify Lazy.nvim is installed

Your config should call `require("lazy").setup({ ... })`. In Neovim, run:

```vim
:Lazy
```

If the Lazy UI opens, you’re set.

### Verify `jpp` is installed

> This plugin **does not** ship or install `jpp`. It shells out to your local `jpp` binary.

Check in a terminal:

```bash
which jpp
# (example-only) you might also try:
jpp --version
```

If `which jpp` returns nothing, install `jpp` via your system’s method, **or** point the plugin at an explicit path:
```bash
# Installation: npm global
npm install -g @jsware/jsonpath-cli
```

```lua
require("jpp_search").setup({ bin = "/path/to/jpp" })
```

---

## Installation (Lazy.nvim)

```lua
{
  -- Replace with your repo path if forked
  "katsarosi/jpp-search.nvim",
  ft = { "json", "jsonc" },
  opts = {
    -- bin = "/usr/local/bin/jpp",  -- if not on PATH
    target = "quickfix",            -- "quickfix" | "float" | "telescope"
    flags = {},                     -- forwarded to jpp (example-only if your jpp supports flags)
    keymaps = { normal = "<leader>jp", visual = "<leader>jp" },
    float = { border = "rounded", width = 0.6, height = 0.6, winblend = 0 },
  },
}
```

The plugin self-attaches on JSON buffers. If `jpp` is missing, you’ll get a clear notification with a setup hint.

---

## Usage

**Keymap defaults (on JSON buffers):**
- Normal: `<leader>jp` → prompt, run on buffer
- Visual: `<leader>jp` → prompt, run on selection

**Commands:**
- `:JppSearch [query]` → run on buffer; prompts if omitted
- `:JppSearchVisual [query]` → run on selection; prompts if omitted
- `:JppSearchLast` → re-run the last query

**Prompt tip:** `<Esc>` cancels the prompt cleanly.

### Examples (example-only queries)

Open a JSON file and try:

```vim
:JppSearch .foo
```

Visual-select a region first, then:

```vim
:JppSearchVisual .items[0]
```

Change the render target at runtime:

```lua
require("jpp_search").setup({ target = "float" })
```

If Telescope is installed:

```lua
require("jpp_search").setup({ target = "telescope" })
```

---

## Configuration

All options (with defaults):

```lua
require("jpp_search").setup({
  bin = "jpp",              -- path or name on $PATH
  flags = {},               -- e.g. { "--compact" } (example-only)
  target = "quickfix",      -- "quickfix" | "float" | "telescope"
  keymaps = {
    normal = "<leader>jp",  -- prompt & run on current buffer
    visual = "<leader>jp",  -- prompt & run on visual selection
  },
  float = {
    border = "rounded",
    width = 0.6,
    height = 0.6,
    winblend = 0,
  },
  telescope = {
    theme = "dropdown",     -- best-effort hint; used if Telescope is present
    attach_mappings = nil,  -- optional function(bufnr, map) -> boolean
  },
  messages = {
    missing_bin = "jpp binary not found. Set require('jpp_search').setup{ bin = '/path/to/jpp' } or put it on $PATH.",
  },
})
```

> **Notes**
> - We call `jpp` as `{ bin, unpack(flags), query }` and stream the buffer/selection to **stdin**. If your `jpp` uses different argv semantics, adjust in `lua/jpp_search/runner.lua` (`build_cmd`).
> - We avoid shell string concatenation to reduce quoting issues, especially on Windows.

---

## Output Targets

- **quickfix** *(default)*: results populate the quickfix list (`:copen`).
- **float**: results shown in a centered, read-only floating window (`q` or `<Esc>` to close).
- **telescope**: if Telescope is installed, results open in a picker; `<CR>` copies the entry into a scratch buffer. Falls back to quickfix if Telescope isn’t available.

---

## Performance

- Uses `jobstart` + streaming `chansend` in chunks to avoid UI stalls.
- Approach scales to buffers ≥ **10k lines**. If you still see lag, reduce `chunk_size` in `runner.lua` (search for `chunk_size = 1000`).

---

## Troubleshooting & FAQ

**“jpp binary not found”**  
The plugin checks `vim.fn.executable(bin)`. Install `jpp` or configure:
```lua
require("jpp_search").setup({ bin = "/absolute/path/to/jpp" })
```

**I get an error with an exit code**  
We surface `jpp`’s non-zero exit status and the first ~20 lines of stderr. This usually means invalid JSON input or a query error.

**Empty results**  
Confirm your query and that the input buffer/selection is valid JSON. For `jsonc`, comments are allowed but your `jpp` must accept them (many do not); consider removing comments before querying if needed.

**Windows quoting**  
We spawn jobs with list-form args (`jobstart({cmd, arg1, ...})`) to avoid quoting pitfalls. If your `jpp` still requires special quoting, adjust `build_cmd()`.

**Can this plugin install `jpp` for me?**  
No—out of scope. This plugin is a thin Neovim wrapper around your local `jpp` CLI.

---

## Security & Privacy

- Buffer content is piped **locally** to `jpp` via Neovim’s job APIs.
- The plugin does **not** send your data over the network.

---

## Development

### File tree

```
lua/jpp_search/init.lua     -- setup, autocommands, buf-local commands/keymaps
lua/jpp_search/config.lua   -- defaults + user opts
lua/jpp_search/runner.lua   -- jobstart runner, stdin streaming, callbacks
lua/jpp_search/render.lua   -- quickfix/float/telescope output
plugin/jpp_search.lua       -- runtime entrypoint (self-setup)
```

### Local dev tips

- Format: add a `stylua.toml` and run `stylua .` (optional)
- Lint: `luacheck .` (optional)
- Reload changed modules inside Neovim with a reload helper or restart Neovim

### Release

- Tag with semver: `v0.1.0`, `v0.2.0`, …
- Keep a short changelog in GitHub Releases

---

## License

MIT © [Iasonas Katsaros](LICENSE)

---

## Acknowledgments

- Inspired by the ergonomics of jq-like CLIs and the Neovim job API
- Telescope integration is best-effort and optional
