local addonName, D2K = ...
local active, holders = {}, setmetatable({}, {__mode = "k"})
local hoverID, tooltipSpell, selectedID, selectedSource
local lastID, started, dirty = nil, false, false
local castingID, castingGUID, castingKind
local events = CreateFrame("Frame")
local elapsedTotal, clock = 0, 0
local errorReported = false
D2K.active = active

function D2K.Print(message) print("|cff60d5ffD2K|r: " .. message) end
function D2K.GetSelection() return selectedID, selectedSource end
local function choose()
    local id, source = D2K.ChooseSpell(hoverID, lastID, D2K.db, castingID)
    if id ~= selectedID or source ~= selectedSource then
        selectedID, selectedSource = id, source
        for _, holder in pairs(active) do holder.previous, holder.pulseUntil = nil, nil end
        if D2K.RefreshOptions then D2K.RefreshOptions() end
    end
end
function D2K.SetHover(id)
    local info = D2K.SpellInfo(id)
    hoverID = info and info.id or nil
    choose()
end
function D2K.RecordCast(id)
    local info = D2K.SpellInfo(id)
    if info then
        lastID = info.id
        D2K.character.lastSpell = lastID
        choose()
    end
end
local function beginCast(id, guid, kind)
    local info = D2K.SpellInfo(id)
    castingID, castingGUID, castingKind = nil, nil, nil
    if info then castingID, castingGUID, castingKind = info.id, D2K.Plain(guid), kind end
    choose(); D2K.UpdateAll()
end
local function endCast(id, guid, kind)
    if not castingID or (kind and castingKind ~= kind) then return end
    id, guid = D2K.Plain(id), D2K.Plain(guid)
    -- A delayed stop for a previous cast must not clear the next cast.
    local matches
    if castingGUID and guid then matches = castingGUID == guid
    else matches = id == castingID end
    if matches then
        castingID, castingGUID, castingKind = nil, nil, nil
        choose(); D2K.UpdateAll()
    end
end
local function tooltipCandidate(id)
    if not started then return end
    id = D2K.Plain(id)
    tooltipSpell = D2K.Finite(id) and id or nil
    D2K.SetHover(tooltipSpell)
end
local function setupHover()
    if not GameTooltip then return end
    -- Hooks observe Blizzard's tooltips; they never replace secure action scripts.
    GameTooltip:HookScript("OnHide", function()
        tooltipSpell = nil
        if started then D2K.SetHover(nil) end
    end)
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Spell, function(tooltip, data)
            if tooltip == GameTooltip then tooltipCandidate(data and D2K.Plain(data.id)) end
        end)
        for _, kind in ipairs({Enum.TooltipDataType.Unit, Enum.TooltipDataType.Item}) do
            pcall(TooltipDataProcessor.AddTooltipPostCall, kind, function(tooltip)
                if tooltip == GameTooltip then tooltipCandidate(nil) end
            end)
        end
    end
    if hooksecurefunc then
        if GameTooltip.SetSpellByID then
            hooksecurefunc(GameTooltip, "SetSpellByID", function(_, id) tooltipCandidate(id) end)
        end
        if GameTooltip.SetSpellBookItem then
            hooksecurefunc(GameTooltip, "SetSpellBookItem", function(_, slot, bank)
                local info = D2K.Call(C_SpellBook and C_SpellBook.GetSpellBookItemInfo, slot, bank)
                tooltipCandidate(type(info) == "table" and D2K.Plain(info.spellID))
            end)
        end
        if GameTooltip.SetAction then
            hooksecurefunc(GameTooltip, "SetAction", function(_, slot)
                local kind, id
                if GetActionInfo then
                    local ok, a, b = pcall(GetActionInfo, slot)
                    if ok then kind, id = D2K.Plain(a), D2K.Plain(b) end
                end
                if kind == "macro" then id = D2K.Call(GetMacroSpell, id)
                elseif kind ~= "spell" then id = nil end
                tooltipCandidate(id)
            end)
        end
    end
end
local function style(holder)
    local db = D2K.db
    holder.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", db.fontSize, db.outline)
    holder.text:SetJustifyH("CENTER")
    holder.text:SetShadowColor(0, 0, 0, 1)
    holder.text:SetShadowOffset(1, -1)
    holder.background:SetColorTexture(0.025, 0.035, 0.045, db.background)
    holder:SetAlpha(db.opacity)
    holder.anchor = nil
end
local function createHolder(plate)
    local holder = holders[plate]
    if holder then return holder end
    holder = CreateFrame("Frame", nil, plate)
    holder:SetSize(120, 36)
    holder:EnableMouse(false)
    holder.background = holder:CreateTexture(nil, "BACKGROUND")
    holder.background:SetAllPoints()
    holder.text = holder:CreateFontString(nil, "OVERLAY")
    holder.text:SetPoint("CENTER")
    holder.text:SetWordWrap(false)
    holder.plate = plate
    style(holder)
    holder:Hide()
    holders[plate] = holder
    return holder
end
local function allowedPlate(plate)
    if not plate then return false end
    if plate.IsForbidden and plate:IsForbidden() then return false end
    return true
end
function D2K.RemovePlate(unit)
    local holder = active[unit]
    if holder then
        holder:Hide(); holder.unit, holder.previous, holder.pulseUntil = nil, nil, nil
        active[unit] = nil
    end
end
function D2K.AddPlate(unit)
    unit = D2K.Plain(unit)
    if type(unit) ~= "string" then return end
    local plate = D2K.Call(C_NamePlate and C_NamePlate.GetNamePlateForUnit, unit)
    if not allowedPlate(plate) then return end
    local holder = createHolder(plate)
    if holder.unit then D2K.RemovePlate(holder.unit) end
    if active[unit] then D2K.RemovePlate(unit) end
    holder.unit, holder.anchor, holder.previous = unit, nil, nil
    active[unit] = holder
end
function D2K.Rescan()
    local units = {}; for unit in pairs(active) do units[#units + 1] = unit end
    for _, unit in ipairs(units) do D2K.RemovePlate(unit) end
    local plates = D2K.Call(C_NamePlate and C_NamePlate.GetNamePlates)
    for _, plate in ipairs(type(plates) == "table" and plates or {}) do
        if allowedPlate(plate) then
            local unit = D2K.Plain(plate.namePlateUnitToken)
            if not unit and plate.GetUnit then unit = D2K.Call(plate.GetUnit, plate) end
            if not unit and plate.UnitFrame then unit = D2K.Plain(plate.UnitFrame.unit) end
            if type(unit) == "string" then D2K.AddPlate(unit) end
        end
    end
end
local points = {
    RIGHT = {"LEFT", "RIGHT"}, LEFT = {"RIGHT", "LEFT"},
    ABOVE = {"BOTTOM", "TOP"}, BELOW = {"TOP", "BOTTOM"},
}
local function updateHolder(holder)
    local db, unit, plate = D2K.db, holder.unit, holder.plate
    local hostile = D2K.Boolean(D2K.Call(UnitCanAttack, "player", unit))
    local friendly = hostile == false and D2K.Boolean(D2K.Call(UnitCanAssist, "player", unit)) == true
    local wanted = (hostile == true and db.enemies) or (friendly and db.friendly)
    if not db.enabled or not wanted or D2K.Boolean(D2K.Call(UnitIsUnit, "player", unit)) == true
        or D2K.Boolean(D2K.Call(UnitIsDeadOrGhost, unit)) == true then
        holder:Hide(); holder.previous = nil; return
    end
    local uf = plate.UnitFrame
    local anchor = uf and (uf.HealthBarsContainer or uf.healthBar or uf) or plate
    if holder.anchor ~= anchor then
        holder:ClearAllPoints()
        local point = points[db.anchor]
        holder:SetPoint(point[1], anchor, point[2], db.offsetX, db.offsetY)
        holder.anchor = anchor
    end
    local inRange
    if hostile == true and selectedID then inRange = D2K.SpellRange(selectedID, unit) end
    -- `and` preserves false here: false must not become an unknown result.
    local status, colorKey = D2K.Status(inRange)
    local low, high
    if db.distance then low, high = D2K.Distance(unit, selectedID, friendly) end
    if db.hideUnknown and high == nil and inRange == nil then holder:Hide(); holder.previous = nil; return end
    local parts = {}
    if db.distance then parts[#parts + 1] = D2K.DistanceLabel(low, high) end
    if db.status and not friendly then parts[#parts + 1] = selectedID and status or "--" end
    local label = table.concat(parts, "  ")
    if db.spellName and not friendly then
        local info = selectedID and D2K.SpellInfo(selectedID)
        local name = info and info.name or "Hover or cast a ranged spell"
        label = label ~= "" and (label .. "\n" .. name) or name
    end
    if label == "" then holder:Hide(); return end
    local color = db[colorKey]
    holder.text:SetText(label)
    holder.text:SetTextColor(color[1], color[2], color[3])
    local iconSpan = D2K.LayoutIcon(holder, color, db)
    local width = math.min(450, math.max(60, holder.text:GetStringWidth() + iconSpan + 12))
    holder:SetSize(width, math.max(db.fontSize + 8, holder.text:GetStringHeight() + 8,
        iconSpan > 0 and D2K.IconSize(db) + 8 or 0))
    if db.pulse and holder.previous ~= nil and inRange ~= nil and holder.previous ~= inRange then
        holder.pulseUntil = clock + 0.65
    end
    -- Unknown breaks continuity. Restoring data must not look like crossing a boundary.
    holder.previous = inRange
    local pulse = holder.pulseUntil and math.max(0, (holder.pulseUntil - clock) / 0.65) or 0
    holder.background:SetColorTexture(0.025 + color[1] * pulse * 0.3,
        0.035 + color[2] * pulse * 0.3, 0.045 + color[3] * pulse * 0.3, db.background)
    holder:Show()
end
function D2K.UpdateAll()
    if not started then return end
    choose()
    for _, holder in pairs(active) do
        local ok, err = pcall(updateHolder, holder)
        if not ok then
            holder:Hide()
            if not errorReported then
                errorReported = true
                D2K.Print("A nameplate could not be updated. /d2k debug shows client details. " .. tostring(err))
            end
        end
    end
end
function D2K.SettingsChanged()
    D2K.Sanitize(D2K.db)
    for _, holder in pairs(holders) do style(holder) end
    choose(); D2K.UpdateAll()
    if D2K.RefreshOptions then D2K.RefreshOptions() end
end
function D2K.Reset()
    for key in pairs(D2K.db) do D2K.db[key] = nil end
    D2K.Sanitize(D2K.db); D2K.SettingsChanged()
    if D2K.options then
        for _, refresh in ipairs(D2K.options.controls) do refresh() end
    end
    if D2K.iconOptions then
        for _, refresh in ipairs(D2K.iconOptions.controls) do refresh() end
    end
end
local function debug()
    local version, build, _, interface = GetBuildInfo()
    D2K.Print(("Client %s / %s, interface %s; %d range groups."):format(version, build, interface, #D2K.probes))
    local info = selectedID and D2K.SpellInfo(selectedID)
    D2K.Print("Selected: " .. (info and info.name or "none") .. " (" .. (selectedSource or "none") .. ")")
    local count = 0; for _ in pairs(active) do count = count + 1 end
    D2K.Print("Visible tracked nameplates: " .. count)
    local hostile = D2K.Boolean(D2K.Call(UnitCanAttack, "player", "target")) == true
    local friendly = not hostile and D2K.Boolean(D2K.Call(UnitCanAssist, "player", "target")) == true
    if hostile or friendly then
        local low, high, probes = D2K.Distance("target", selectedID, friendly)
        local answer
        if hostile and selectedID then answer = D2K.SpellRange(selectedID, "target") end
        D2K.Print("Target: " .. D2K.DistanceLabel(low, high) .. "; selected spell: " .. D2K.Status(answer))
        if friendly then
            local report = {}
            for _, probe in ipairs(probes or {}) do
                report[#report+1] = tostring(probe.range) .. "=" .. (probe.answer == true and "in" or (probe.answer == false and "out" or "?"))
            end
            D2K.Print("Friendly checks: " .. table.concat(report, ", "))
        end
    end
end
local function start()
    if started then return end
    D2K.db = D2K.Sanitize(D2KDB); D2KDB = D2K.db
    D2K.character = type(D2KCharacterDB) == "table" and D2KCharacterDB or {}
    D2KCharacterDB = D2K.character
    local info = D2K.SpellInfo(D2K.character.lastSpell)
    lastID = info and info.id
    started = true
    D2K.RebuildProbes(); setupHover(); choose(); D2K.Rescan(); D2K.RegisterSettings()
    D2K.Print("Loaded. /d2k opens settings. Enable enemy nameplates with V.")
end
for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "NAME_PLATE_UNIT_ADDED",
    "NAME_PLATE_UNIT_REMOVED", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_INTERRUPTED",
    "SPELLS_CHANGED", "PLAYER_TALENT_UPDATE", "PLAYER_REGEN_ENABLED"}) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            D2K.db = D2K.Sanitize(D2KDB); D2KDB = D2K.db
        end
        return
    end
    if event == "PLAYER_LOGIN" then start(); return end
    if not started then return end
    if event == "NAME_PLATE_UNIT_ADDED" then D2K.AddPlate(...)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then D2K.RemovePlate(...)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, id = ...
        if D2K.Plain(unit) == "player" then D2K.RecordCast(D2K.Plain(id)); D2K.UpdateAll() end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unit, guid, id = ...
        if D2K.Plain(unit) == "player" then
            beginCast(D2K.Plain(id), D2K.Plain(guid), event == "UNIT_SPELLCAST_START" and "cast" or "channel")
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET"
        or event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit, guid, id = ...
        if D2K.Plain(unit) == "player" then
            local kind = event == "UNIT_SPELLCAST_STOP" and "cast"
                or (event == "UNIT_SPELLCAST_CHANNEL_STOP" and "channel" or nil)
            endCast(D2K.Plain(id), D2K.Plain(guid), kind)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        castingID, castingGUID, castingKind = nil, nil, nil
        choose(); D2K.Rescan(); dirty = true
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then dirty = true
    elseif event == "PLAYER_REGEN_ENABLED" then dirty = true end
end)
events:SetScript("OnUpdate", function(_, elapsed)
    if not started then return end
    clock, elapsedTotal = clock + elapsed, elapsedTotal + elapsed
    if elapsedTotal < D2K.db.interval then return end
    elapsedTotal = 0
    if dirty and not InCombatLockdown() then
        dirty = false; D2K.RebuildProbes()
        -- Range metadata can change when talents or spell ranks change.
        if lastID and not D2K.SpellInfo(lastID) then lastID = nil; D2K.character.lastSpell = nil end
    end
    if GameTooltip and not GameTooltip:IsShown() and hoverID then D2K.SetHover(nil) end
    D2K.UpdateAll()
end)
SLASH_D2K1 = "/d2k"
SlashCmdList.D2K = function(message)
    if not started then return end
    local command = (message or ""):lower():match("^%s*(%S*)")
    if command == "on" or command == "off" then
        D2K.db.enabled = command == "on"; D2K.SettingsChanged()
    elseif command == "reset" then D2K.Reset(); D2K.Print("Appearance and behavior reset.")
    elseif command == "debug" then debug()
    elseif command == "clear" then
        lastID, D2K.character.lastSpell = nil, nil; choose(); D2K.UpdateAll()
    elseif command == "" or command == "settings" then D2K.OpenOptions()
    else D2K.Print("/d2k settings | on | off | clear | reset | debug") end
end
D2K.events = events
