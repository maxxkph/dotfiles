-- Helpers for reading colours out of whatever colorscheme is active, so that
-- nothing in this config has to hardcode a hex value and go stale the moment
-- the theme changes.
--
-- Used by config/options.lua (Snacks indent + diff highlights) and
-- plugins/bufferline.lua (the buffer tabs).

local M = {}

-- Resolved highlight for `name`, or nil when the group is empty.
function M.hl(name)
  local h = vim.api.nvim_get_hl(0, { name = name, link = false })
  return (h and next(h)) and h or nil
end

-- First of `groups` that actually defines `key` ("fg" or "bg"), else `fallback`.
function M.pick(key, groups, fallback)
  for _, name in ipairs(groups) do
    local h = M.hl(name)
    if h and h[key] then
      return h[key]
    end
  end
  return fallback
end

-- Mix `fg` into `bg` at `alpha` (0 = bg, 1 = fg). Both are 24-bit ints, which
-- is what nvim_get_hl returns under termguicolors.
function M.blend(fg, bg, alpha)
  local function channel(shift)
    local a, b = math.floor(fg / shift) % 256, math.floor(bg / shift) % 256
    return math.min(255, math.max(0, math.floor(b + (a - b) * alpha + 0.5)))
  end
  return channel(65536) * 65536 + channel(256) * 256 + channel(1)
end

-- Move `color` toward black by `amount`.
function M.darken(color, amount)
  return M.blend(0x000000, color, amount)
end

return M
