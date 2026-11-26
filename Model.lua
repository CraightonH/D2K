local _, D2K = ...
D2K.defaults = {
    enabled = true, enemies = true, friendly = true, hover = true, lastCast = true, distance = true,
    spellName = false, status = false, hideUnknown = false, pulse = true,
    iconEnabled = true, iconChoice = "crosshair", iconSize = 10, iconGap = 3,
    iconTint = true, iconCustom = "", iconScaleWithText = true,
    fontSize = 9, opacity = 1, background = 0, offsetX = 0, offsetY = -2,
    interval = 0.15, anchor = "BELOW", outline = "OUTLINE",
    inColor = {0.3, 1, 0.45}, outColor = {1, 0.3, 0.25},
    unknownColor = {0.78, 0.8, 0.85},
}
local limits = {
    fontSize = {4, 32}, opacity = {0.1, 1}, background = {0, 1},
    iconSize = {6, 32}, iconGap = {0, 16},
    offsetX = {-150, 150}, offsetY = {-150, 150}, interval = {0.05, 1},
}
function D2K.Plain(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
function D2K.Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return D2K.Plain(value) end
end
function D2K.Boolean(value)
    value = D2K.Plain(value)
    if value == true or value == 1 then return true end
    if value == false or value == 0 then return false end
end
function D2K.Finite(value)
    value = D2K.Plain(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function D2K.Copy(value)
    if type(value) ~= "table" then return value end
    local out = {}; for k, v in pairs(value) do out[k] = D2K.Copy(v) end
    return out
end
function D2K.Sanitize(db)
    db = type(db) == "table" and db or {}
    for key, default in pairs(D2K.defaults) do
        local value = db[key]
        if limits[key] then
            db[key] = D2K.Finite(value) and math.max(limits[key][1], math.min(limits[key][2], value)) or default
        elseif type(default) == "table" then
            local color = {}
            for i = 1, 3 do
                local c = type(value) == "table" and value[i]
                color[i] = D2K.Finite(c) and math.max(0, math.min(1, c)) or default[i]
            end
            db[key] = color
        elseif type(value) ~= type(default) then db[key] = default end
    end
    if not ({RIGHT=true, LEFT=true, ABOVE=true, BELOW=true})[db.anchor] then db.anchor = "BELOW" end
    if not ({OUTLINE=true, THICKOUTLINE=true, [""]=true})[db.outline] then db.outline = "OUTLINE" end
    db.fontSize = math.floor(db.fontSize * 10 + 0.5) / 10
    return db
end
function D2K.ChooseSpell(hoverID, lastID, db, castingID)
    if db.hover and hoverID then return hoverID, "hover" end
    if castingID then return castingID, "casting" end
    if db.lastCast and lastID then return lastID, "last cast" end
    return nil, "none"
end
-- Only explicit false answers establish a lower bound. Nil is never a miss.
function D2K.Bounds(answers)
    local low, high, known = 0, nil, false
    for _, probe in ipairs(answers) do
        local answer = D2K.Boolean(probe.answer)
        if D2K.Finite(probe.range) and probe.range > 0 and answer ~= nil then
            known = true
            if answer then high = high and math.min(high, probe.range) or probe.range
            else low = math.max(low, probe.range) end
        end
    end
    if not known or (high and low >= high) then return nil, nil end
    return low, high
end
-- A bare number means within this many yards. Never imply an upper bound
-- when only a lower-bound or unknown result is available.
function D2K.DistanceLabel(low, high)
    if low == nil or not D2K.Finite(high) or high < 0 then return "?" end
    if high == 0 then return "5" end
    return tostring(math.ceil(high / 5) * 5)
end
function D2K.Status(inRange)
    if inRange == true then return "IN", "inColor" end
    if inRange == false then return "OUT", "outColor" end
    return "?", "unknownColor"
end
