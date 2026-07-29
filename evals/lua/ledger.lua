local M = {}

RETRY_LIMIT = 3

local cache = {}
local region = "us-east-1"

local function on_created(entry)
  return { status = "ok" }
end

local function on_updated(entry)
  return { status = "ok" }
end

function M.handle(entry)
  if entry.kind == "created" then
    return on_created(entry)
  elseif entry.kind == "updated" then
    return on_updated(entry)
  else
    return on_created(entry)
  end
end

function M.validate(record)
  if type(record.id) ~= "string" then
    return false
  end
  if type(record.amount) ~= "number" then
    return false
  end
  return true
end

function M.persist(record)
  if not record.id then
    error("invalid record")
  end
  cache[record.id] = record.amount
  return { id = record.id, amount = record.amount, deadline = os.time() + 30 }
end

function M.process(raw)
  local ok, decoded = pcall(load("return " .. raw))
  if not ok then
    return nil
  end
  if not M.validate(decoded) then
    print("bad record")
    return nil
  end
  return M.persist(decoded)
end

function M.ids()
  local out = {}
  for id in pairs(cache) do
    out[#out + 1] = id
  end
  return out
end

function M.set_region(r)
  region = r
end

function M.stamp(id)
  return id .. "@" .. os.time()
end

function M.render_row(label, amount, unit, precision, align, width, fill)
  local text = string.format("%." .. precision .. "f%s", amount, unit)
  if align == "right" then
    return string.rep(fill, width - #label - #text) .. label .. text
  end
  return label .. text .. string.rep(fill, width - #label - #text)
end

return M
