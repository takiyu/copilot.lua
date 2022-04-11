local util = require("copilot.util")
local request_handler = {}
local result_log = {}

local defaults = {
  handler = function(_, bufnr, response, _)
    if not result_log[bufnr] then result_log[bufnr] = {} end
    local loc = vim.api.nvim_win_get_cursor(0)[1]
    if response and not vim.tbl_isempty(response.completions) then
      result_log[bufnr][loc] = response.completions
    end
  end,
  trigger = {
    type = "timer",
    timer = { debounce = 400, start_delay = 0},
    autocmd = {"InsertChanged"},
  },
  cycling = true,
}

function request_handler:get_current_completions()
  local loc = vim.api.nvim_win_get_cursor(0)[1]
  local bufnr = vim.api.nvim_get_current_buf()
  if result_log[bufnr] and result_log[bufnr][loc] then
    return result_log[bufnr][loc]
  end
end
function request_handler:send_request()
  util.send_completion_request(self.cycling, self.handler)
end

function request_handler:register_autocmd()
  local event = self.params.trigger.autocmd
  event = type(event) == "table" and event or {event}
  vim.api.nvim_create_autocmd(event, {
    callback = vim.schedule_wrap(function() self:send_request() end),
    once = false,
  })
end

function request_handler:get_start_func()
  self.timer = self.params.trigger.type == "timer" and vim.loop.new_timer() or nil
  self.autocmd = self.params.trigger.type == "autocmd" and self.params.trigger.autocmd
  return self.timer and request_handler.start_request_loop or request_handler.register_autocmd
end

function request_handler:new(opts)
  opts = opts and  vim.tbl_extend("force", defaults, opts) or defaults
  setmetatable({}, self)
  self.params = opts
  self.start = function ()
    local start_func  = self:get_start_func()
    start_func(self)
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
  print(vim.inspect(self))
  local start_delay = self.params.trigger.timer.start_delay
  local debounce = self.params.trigger.timer.debounce
  self.timer:start(start_delay, debounce, vim.schedule_wrap(function()
    self:send_request()
  end))
end

return request_handler
