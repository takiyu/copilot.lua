---@class copilot_config
local default_config = {
  ---@class copilot_config_panel
  panel = {
    enabled = true,
    auto_refresh = false,
    ---@type table<'jump_prev'|'jump_next'|'accept'|'refresh'|'open', false|string>
    keymap = {
      jump_prev = "[[",
      jump_next = "]]",
      accept = "<CR>",
      refresh = "gr",
      open = "<M-CR>",
    },
    layout = {
      position = "bottom",
      ratio = 0.4,
    },
  },
  ---@class copilot_config_suggestion
  suggestion = {
    enabled = true,
    auto_trigger = false,
    hide_during_completion = true,
    debounce = 15,
    ---@type table<'accept'|'accept_word'|'accept_line'|'next'|'prev'|'dismiss', false|string>
    keymap = {
      accept = "<M-l>",
      accept_word = false,
      accept_line = false,
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
  },
  ---@class copilot_config_connection
  connection = {
    ---@type table<'copilot_proxy'|'copilot_proxy_strict_ssl', false|string>
    http = {
      copilot_proxy = false,
      copilot_proxy_strict_ssl = false,
    },
    ---@type false|string
    copilot_auth_provider_url = false,
  },
  ---@deprecated
  ft_disable = nil,
  ---@type table<string, boolean>
  filetypes = {},
  copilot_node_command = "node",
  server_opts_overrides = {},
}

local mod = {
  config = nil,
}

function mod.setup(opts)
  if mod.config then
    vim.notify("[Copilot] config is already set", vim.log.levels.WARN)
    return mod.config
  end

  local conn_opts = opts.connection and {
    proxy = opts.connection.http.copilot_proxy
      or vim.g.copilot_proxy or vim.NIL,
    proxyStrictSSL = opts.connection.http.copilot_proxy_strict_ssl
      or vim.g.copilot_proxy_strict_ssl or vim.NIL,
    ['github-enterprise'] = {
      url = opts.connection.copilot_auth_provider_url
        or vim.g.copilot_auth_provider_url or vim.NIL
    }
  } or nil

  if conn_opts then
    opts.server_opts_overrides = opts.server_opts_overrides or {}
    opts.server_opts_overrides.settings = vim.tbl_deep_extend(
      "force",
      conn_opts or {},
      opts.server_opts_overrides.settings or {}
    )
  end

  opts.server_opts_overrides = opts.server_opts_overrides or {}

  local config = vim.tbl_deep_extend("force", default_config, opts or {})

  --- for backward compatibility
  if config.ft_disable then
    for _, disabled_ft in ipairs(config.ft_disable) do
      config.filetypes[disabled_ft] = false
    end

    config.ft_disable = nil
  end

  mod.config = config

  return mod.config
end

---@param key? string
function mod.get(key)
  if not mod.config then
    error("[Copilot] not initialized")
  end

  if key then
    return mod.config[key]
  end

  return mod.config
end

return mod
