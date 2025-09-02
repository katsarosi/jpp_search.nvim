local config = require("jpp_search.config")
local runner = require("jpp_search.runner")

local M = {}

local function set_buf_keymaps(bufnr, opts)
  local km = opts.keymaps or {}
  if km.normal and km.normal ~= "" then
    vim.keymap.set("n", km.normal, function() runner.prompt("buffer") end,
      { buffer = bufnr, desc = "jpp: query current JSON buffer" })
  end
  if km.visual and km.visual ~= "" then
    vim.keymap.set("x", km.visual, function() runner.prompt("visual") end,
      { buffer = bufnr, desc = "jpp: query visual selection" })
  end
end

local function create_buf_commands(bufnr)
  vim.api.nvim_buf_create_user_command(bufnr, "JppSearch", function(cmd)
    local q = table.concat(cmd.fargs or {}, " ")
    if q == "" then
      return require("jpp_search.runner").prompt("buffer")
    else
      return require("jpp_search.runner").run(q, "buffer")
    end
  end, {
    desc = "Run jpp query on current JSON buffer (prompts if no args)",
    nargs = "*",
  })

  vim.api.nvim_buf_create_user_command(bufnr, "JppSearchVisual", function(cmd)
    local q = table.concat(cmd.fargs or {}, " ")
    if q == "" then
      return require("jpp_search.runner").prompt("visual")
    else
      return require("jpp_search.runner").run(q, "visual")
    end
  end, {
    desc = "Run jpp query on current visual selection",
    nargs = "*",
    range = true,
  })

  vim.api.nvim_buf_create_user_command(bufnr, "JppSearchLast", function()
    require("jpp_search.runner").rerun_last()
  end, { desc = "Re-run the last jpp query" })
end

-- Attach behavior only on JSON buffers
local function on_json_ft(args)
  local bufnr = args.buf
  set_buf_keymaps(bufnr, config.get())
  create_buf_commands(bufnr)
end

function M.setup(opts)
  config.setup(opts)

  -- Only attach to JSON buffers; safe to set once.
  local aug = vim.api.nvim_create_augroup("JppSearchJSON", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = { "json", "jsonc" },
    callback = on_json_ft,
  })
end

-- Expose for testing or manual attach
M._on_json_ft = on_json_ft

return M
