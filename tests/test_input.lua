local T = MiniTest.new_set()

local config = require("editprompt.config")
local history = require("editprompt.history")
local input = require("editprompt.modes.input")

local function create_buffer(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or {})
  vim.api.nvim_set_current_buf(bufnr)
  return bufnr
end

local function with_stubbed_system(fn)
  local original_system = vim.system
  local calls = {}

  vim.system = function(args, opts, callback)
    table.insert(calls, {
      args = vim.deepcopy(args),
      opts = vim.deepcopy(opts),
    })
    callback({ code = 0, stdout = "", stderr = "" })
  end

  local ok, err = pcall(fn, calls)
  vim.system = original_system
  if not ok then
    error(err)
  end
end

T["execute()"] = MiniTest.new_set()

T["execute()"]["stores successful sends in history"] = function()
  config._reset()
  history._reset()

  with_stubbed_system(function(calls)
    local bufnr = create_buffer({ "sent text" })

    input.execute()

    vim.wait(100, function()
      return #calls == 1
        and vim.deep_equal(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {})
    end)

    MiniTest.expect.equality(calls[1].args, {
      "editprompt",
      "input",
      "--always-copy",
      "--",
      "sent text",
    })

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "draft" })

    history.prev()
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "sent text" }
    )

    history.next()
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "draft" }
    )
  end)
end

T["execute_visual()"] = MiniTest.new_set()

T["execute_visual()"]["sends touched lines and removes them on success"] = function()
  config._reset()
  history._reset()

  with_stubbed_system(function(calls)
    local bufnr = create_buffer({ "alpha beta" })

    input.execute_visual({
      start_pos = { 0, 1, 7, 0 },
      end_pos = { 0, 1, 10, 0 },
    })

    vim.wait(100, function()
      return #calls == 1
        and vim.deep_equal(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {})
    end)

    MiniTest.expect.equality(calls[1].args, {
      "editprompt",
      "input",
      "--always-copy",
      "--",
      "alpha beta",
    })
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      {}
    )
  end)
end

return T
