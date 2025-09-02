local M = {}

-- Defaults are conservative; everything is buffer-local on JSON ft attach.
M.defaults = {
  bin = "jpp",              -- Path or name on $PATH
  flags = {},               -- e.g., { "--compact" }  -- {confirm flags}
  target = "quickfix",      -- one of: "quickfix" | "float" | "telescope"
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
    theme = "dropdown",     -- best-effort hint; used if Telescope found
    attach_mappings = nil,  -- optional function(pbufnr, map) -> boolean
  },
  messages = {
    missing_bin = "jpp binary not found. Set `require('jpp_search').setup{ bin = '/path/to/jpp' }` or put it on $PATH.",
  },
}

M.opts = vim.deepcopy(M.defaults)

function M.setup(user)
  if user and type(user) == "table" then
    -- deep extend without touching defaults
    M.opts = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user)
  end
  return M.opts
end

function M.get()
  return M.opts
end

return M
