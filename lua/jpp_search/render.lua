local M = {}

local function ensure_list(lines)
  if type(lines) == "string" then
    lines = vim.split(lines, "\n", { plain = true })
  end
  lines = lines or {}
  -- Drop a possible trailing empty line from job callbacks
  if #lines > 0 and lines[#lines] == "" then
    lines[#lines] = nil
  end
  return lines
end

-- QUICKFIX --------------------------------------------------------------------
function M.to_quickfix(lines, title)
  lines = ensure_list(lines)
  local items = {}
  local fname = vim.api.nvim_buf_get_name(0)
  for i, l in ipairs(lines) do
    items[i] = { filename = fname ~= "" and fname or "[JSON]", lnum = 1, col = 1, text = l }
  end
  vim.fn.setqflist({}, " ", { title = title or "jpp results", items = items })
  -- Open quickfix if there are items; close if empty
  if #items > 0 then
    vim.cmd.copen()
  else
    vim.cmd.cclose()
  end
end

-- FLOAT -----------------------------------------------------------------------
local function make_float_buf_win(width, height, border, winblend)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "json"

  local ui = vim.api.nvim_list_uis()[1]
  local win_w = math.floor((ui and ui.width or 120) * (width or 0.6))
  local win_h = math.floor((ui and ui.height or 40) * (height or 0.6))
  local row = math.floor(((ui and ui.height or 40) - win_h) / 2)
  local col = math.floor(((ui and ui.width or 120) - win_w) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = border or "rounded",
    width = win_w,
    height = win_h,
    row = row,
    col = col,
  })
  if winblend and winblend > 0 then
    vim.wo[win].winblend = winblend
  end
  return buf, win
end

function M.to_float(lines, opts)
  lines = ensure_list(lines)
  opts = opts or {}
  local buf, _ = make_float_buf_win(opts.width, opts.height, opts.border, opts.winblend)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  -- Basic mappings for UX
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true })
end

-- TELESCOPE -------------------------------------------------------------------
local function telescope_ok()
  local ok, _ = pcall(require, "telescope")
  return ok
end

function M.to_telescope(lines, title, tel_opts)
  lines = ensure_list(lines)
  if not telescope_ok() then
    -- fallback to quickfix if telescope missing
    return M.to_quickfix(lines, title)
  end
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local picker = pickers.new(tel_opts or {}, {
    prompt_title = title or "jpp results",
    finder = finders.new_table(lines),
    sorter = conf.generic_sorter(tel_opts or {}),
    attach_mappings = function(bufnr, map)
      -- Enter copies the entry into a new scratch split for inspection
      map("i", "<CR>", function()
        local entry = action_state.get_selected_entry()
        actions.close(bufnr)
        vim.cmd.new()
        local b = vim.api.nvim_get_current_buf()
        vim.bo[b].bufhidden = "wipe"
        vim.bo[b].filetype = "json"
        vim.api.nvim_buf_set_lines(b, 0, -1, false, { entry[1] })
      end)
      if tel_opts and type(tel_opts.attach_mappings) == "function" then
        return tel_opts.attach_mappings(bufnr, map)
      end
      return true
    end,
  })
  picker:find()
end

-- ERROR/INFO ------------------------------------------------------------------
function M.notify(msg, level)
  vim.notify("[jpp] " .. msg, level or vim.log.levels.INFO, { title = "jpp_search" })
end

function M.error(err)
  M.notify(err, vim.log.levels.ERROR)
end

return M
