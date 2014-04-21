local M = {}

local class = require 'pl.class'

M.OpError = class.OpError()

function OpError:_init(op, data, err)
  self.op = op
  self.data = data
  self.err = err
end

function OpError:__tostring()
  return table.concat{self.op, ' ', tostring(self.data), ' ', tostring(self.err)}
end

function OpError.__concat(l, r)
  return tostring(l) .. tostring(r)
end

return M
