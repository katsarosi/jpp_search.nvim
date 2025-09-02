-- Runtime entry so the plugin self-configures when loaded.
-- If using Lazy.nvim, you can also load on ft = { "json", "jsonc" } and this will run then.

if vim.g.loaded_jpp_search_plugin then
  return
end
vim.g.loaded_jpp_search_plugin = true

-- Users can override options by calling require('jpp_search').setup{} earlier
-- in their config (before this file runs), e.g., via Lazy opts/config.
pcall(function()
  require("jpp_search").setup()
end)
