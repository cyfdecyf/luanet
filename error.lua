local M = {}

local OpError = setmetatable({}, {
  __call = function (self, op, data, err)
    return setmetatable({
      op = op,
      data = data,
      err = err,
    }, self)
  end
})
OpError.__index = OpError
M.OpError = OpError

function OpError:__tostring()
  return table.concat{self.op, ' ', tostring(self.data), ' ', tostring(self.err)}
end

function OpError.__concat(l, r)
  return tostring(l) .. tostring(r)
end

return M
