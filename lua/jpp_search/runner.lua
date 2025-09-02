local config = require("jpp_search.config")
local render = require("jpp_search.render")

local M = {}

local last_query = nil

local function check_bin(bin)
  if vim.fn.executable(bin) == 1 then
    return true
  end
  render.error(config.get().messages.missing_bin)
  return false
end

local function current_buf_json()
  return vim.api.nvim_get_current_buf()
end

local function read_entire_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- jobstart handles list-of-lines via chansend; keep as table
  return lines
end

local function read_visual_selection(buf)
  local a = vim.fn.getpos("'<")
  local b = vim.fn.getpos("'>")
  local sr, sc = a[2], a[3]
  local er, ec = b[2], b[3]
  -- Convert to 0-indexed, end col is inclusive in getpos('>')
  local lines = vim.api.nvim_buf_get_text(buf, sr - 1, sc - 1, er - 1, ec, {})
  if #lines == 0 then
    -- Fallback to entire line when marks are weird
    lines = vim.api.nvim_buf_get_lines(buf, sr - 1, er, false)
  end
  return lines
end

local function build_cmd(query)
  local opts = config.get()
  local cmd = { opts.bin }
  for _, f in ipairs(opts.flags or {}) do
    table.insert(cmd, f)
  end
  table.insert(cmd, query) -- {confirm flags}: jpp "<query>"
  return cmd
end

local function render_results(lines, title)
  local opts = config.get()
  if opts.target == "float" then
    return render.to_float(lines, opts.float)
  elseif opts.target == "telescope" then
    return render.to_telescope(lines, title, opts.telescope)
  else
    return render.to_quickfix(lines, title)
  end
end

--- Run jpp with string `query` on the given `source` ("buffer" | "visual")
function M.run(query, source)
  local opts = config.get()
  if not check_bin(opts.bin) then
    return
  end
  last_query = query

  local buf = current_buf_json()
  local input_lines = (source == "visual") and read_visual_selection(buf) or read_entire_buffer(buf)

  local out_lines, err_lines = {}, {}
  local title = ("jpp: %s"):format(query)

  local cmd = build_cmd(query)
  local jobid = vim.fn.jobstart(cmd, {
    stdin = "pipe",
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data, _)
      if type(data) == "table" then
        for _, l in ipairs(data) do
          if l ~= nil and l ~= "" then
            table.insert(out_lines, l)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if type(data) == "table" then
        for _, l in ipairs(data) do
          if l and l ~= "" then
            table.insert(err_lines, l)
          end
        end
      end
    end,
    on_exit = function(_, code, _)
      if code == 0 then
        if vim.in_fast_event() then
          vim.schedule(function() render_results(out_lines, title) end)
        else
          render_results(out_lines, title)
        end
      else
        local msg = ("jpp exited with code %d"):format(code)
        if #err_lines > 0 then
          -- Show only the first ~20 lines to avoid noise
          local max = math.min(#err_lines, 20)
          msg = msg .. "\n" .. table.concat(vim.list_slice(err_lines, 1, max), "\n")
        end
        if vim.in_fast_event() then
          vim.schedule(function() render.error(msg) end)
        else
          render.error(msg)
        end
      end
    end,
  })

  if jobid <= 0 then
    return render.error("Failed to start job for jpp")
  end

  -- Stream the buffer content to stdin in modest chunks to avoid UI stalls
  local chunk = {}
  local chunk_size = 1000
  for i, l in ipairs(input_lines) do
    table.insert(chunk, l)
    if (#chunk >= chunk_size) or (i == #input_lines) then
      vim.fn.chansend(jobid, chunk)
      chunk = {}
    end
  end
  vim.fn.chanclose(jobid, "stdin")
end

function M.prompt(mode)
  vim.ui.input({ prompt = "jpp query: ", default = last_query or "" }, function(q)
    if not q or q == "" then
      return
    end
    M.run(q, mode == "visual" and "visual" or "buffer")
  end)
end

function M.rerun_last(mode)
  if not last_query then
    return render.notify("No last query to re-run.")
  end
  M.run(last_query, mode == "visual" and "visual" or "buffer")
end

return M
