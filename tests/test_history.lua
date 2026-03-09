local T = MiniTest.new_set()

local history = require("editprompt.history")

local function create_buffer(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or {})
  vim.api.nvim_set_current_buf(bufnr)
  return bufnr
end

T["navigate()"] = MiniTest.new_set()

T["navigate()"]["restores previous sent texts and latest draft"] = function()
  history._reset()

  local bufnr = create_buffer({ "draft" })

  history.push("first")
  history.push("second")

  history.prev()
  MiniTest.expect.equality(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "second" }
  )

  history.prev()
  MiniTest.expect.equality(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "first" }
  )

  history.next()
  MiniTest.expect.equality(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "second" }
  )

  history.next()
  MiniTest.expect.equality(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "draft" }
  )
end

return T
