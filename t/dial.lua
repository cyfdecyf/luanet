local dial = require 'luanet.dial'

local M = {}

function M.test_dial()
  local ln, err = dial.listen('tcp', { ip = '127.0.0.1', port = 8765 })
  assert_not_nil(ln, err)
end

return M
