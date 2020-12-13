local ui = require "flutter-tools/ui"
local utils = require "flutter-tools/utils"

local api = vim.api
local jobstart = vim.fn.jobstart

local M = {}

-----------------------------------------------------------------------------//
-- Devices
-----------------------------------------------------------------------------//

function M.parse(line)
  local parts = vim.split(line, "•")
  if #parts == 4 then
    return {
      name = vim.trim(parts[1]),
      device_id = vim.trim(parts[2]),
      platform = vim.trim(parts[3]),
      system = vim.trim(parts[4])
    }
  end
end

---@param result table
local function get_device(result)
  return function(_, data, _)
    for _, line in pairs(data) do
      local device = M.parse(line)
      if device then
        table.insert(result.devices, device)
      end
      table.insert(result.data, line)
    end
  end
end

local function setup_devices_win(result)
  return function(buf, _)
    if #result.devices > 0 then
      api.nvim_buf_set_var(buf, "devices", result.devices)
    end
    api.nvim_buf_set_keymap(
      buf,
      "n",
      "<CR>",
      ":lua __flutter_tools_select_device()<CR>",
      {silent = true, noremap = true}
    )
  end
end

---@param result table list of devices
local function show_devices(result)
  return function(_, _, _)
    local formatted = {}
    local has_devices = #result.devices > 0
    if has_devices then
      for _, item in pairs(result.devices) do
        table.insert(formatted, utils.display_name(item.name))
      end
    else
      for _, item in pairs(result.data) do
        table.insert(formatted, item)
      end
    end
    if #formatted > 0 then
      ui.popup_create("Flutter devices", formatted, setup_devices_win(result))
    end
  end
end

function M.list()
  local result = {
    data = {},
    devices = {}
  }
  jobstart(
    "flutter devices",
    {
      on_stdout = get_device(result),
      on_exit = show_devices(result),
      on_stderr = function(_, data, _)
        if data and data[1] ~= "" then
          utils.echomsg(data[1])
        end
      end
    }
  )
end

return M
