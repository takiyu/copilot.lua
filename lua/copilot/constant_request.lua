local util = require("copilot.util")
local request_handler = {}
local result_log = {}

local defaults = {
  handler = function(_, bufnr, response, _)
    if not result_log[bufnr] then result_log[bufnr] = {} end
    result_log[bufnr][response.method] = response
    print(vim.inspect(response))
  end,
  trigger = {
    type = "timer",
    timer = { debounce = 400, start_delay = 0},
    autocmd = {"InsertChanged"},
  },
  cycling = true,
}

function request_handler:send_request()
  util.send_completion_request(self.cycling, self.handler)
end

function request_handler:register_autocmd()
  local event = self.trigger.autocmd
  event = type(event) == "table" and event or {event}
  vim.api.nvim_create_autocmd(event, {
    callback = vim.schedule_wrap(function() self:send_request() end),
    once = false,
  })
end

function request_handler:get_start_func()
  self.timer = self.trigger.type == "timer" and vim.loop.new_timer() or nil
  self.autocmd = self.trigger.type == "autocmd" and self.trigger.autocmd
  return self.timer and request_handler.start_request_loop or request_handler.register_autocmd
end

function request_handler:new(opts)
  opts = opts and  vim.tbl_extend("force", defaults, opts) or defaults
  setmetatable({}, self)
  self.start = function ()
    local start_func  = self:get_start_func()
    vim.schedule(start_func(self))
  end
  return self
end

function request_handler:close_request_loop()
  self.timer:close()
end

function request_handler:pause_request_loop()
  self.timer:stop()
end

function request_handler:start_request_loop()
    self.timer:start(self.start_delay, self.debounce, vim.schedule_wrap(function()
      self:send_request()
    end))
end

return request_handler
