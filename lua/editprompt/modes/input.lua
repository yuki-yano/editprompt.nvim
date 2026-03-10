local config = require("editprompt.config")
local history = require("editprompt.history")
local utils = require("editprompt.utils")

local M = {}

local function exit_to_normal()
  vim.cmd("stopinsert")
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
end

local function normalize_rows(start_pos, end_pos)
  local start_row = start_pos[2] - 1
  local end_row = end_pos[2] - 1

  if start_row > end_row then
    start_row, end_row = end_row, start_row
  end

  return start_row, end_row
end

local function get_selected_lines(start_pos, end_pos)
  start_pos = start_pos or vim.fn.getpos("'<")
  end_pos = end_pos or vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  local start_row, end_row = normalize_rows(start_pos, end_pos)
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  local text = table.concat(lines, "\n")

  return text,
    function()
      vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, {})
    end
end

--- Execute input command with specified flag
---@param flag string "--always-copy" or "--auto-send"
---@param content? string
---@param on_success? fun()
local function execute_input(flag, content, on_success)
  utils.save_buffer()
  content = content or utils.get_buffer_content()

  if content == "" then
    return
  end

  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "input", flag, "--", content })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        if on_success then
          on_success()
        else
          utils.clear_buffer()
        end
        local ok, render_ui = pcall(require, "render-markdown.core.ui")
        if ok then
          vim.api.nvim_buf_clear_namespace(0, render_ui.ns, 0, -1)
        end
        history.push(content)
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Execute input with --always-copy
function M.execute()
  execute_input("--always-copy")
end

--- Execute input with --auto-send
function M.execute_auto_send()
  execute_input("--auto-send")
end

--- Execute visual input with --always-copy
---@param opts? table
function M.execute_visual(opts)
  opts = opts or {}

  local content, delete_selected_lines =
    get_selected_lines(opts.start_pos, opts.end_pos)
  if not content then
    return
  end

  exit_to_normal()
  execute_input("--always-copy", content, function()
    delete_selected_lines()
    exit_to_normal()
  end)
end

--- Execute visual input with --auto-send
---@param opts? table
function M.execute_visual_auto_send(opts)
  opts = opts or {}

  local content, delete_selected_lines =
    get_selected_lines(opts.start_pos, opts.end_pos)
  if not content then
    return
  end

  exit_to_normal()
  execute_input("--auto-send", content, function()
    delete_selected_lines()
    exit_to_normal()
  end)
end

return M
