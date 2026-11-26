local _, D2K = ...
-- Vanilla item-use ranges, also catalogued by LibRangeCheck-3.0.
-- These checks do not use or equip the items. Missing/uncached answers are ignored.
local items = {
    {5, 8149, 22432}, {10, 17626, 10699}, {20, 10645, 1191},
    {25, 13289}, {30, 835, 7734}, {35, 18904}, {40, 4945, 8348},
}
local friendlyItems = {
    {5, 8149, 1970}, {10, 17626, 21267}, {15, 1251, 2581},
    {20, 21519, 12450}, {25, 13289}, {30, 1180, 954},
    {35, 18904}, {40, 18662, 11562},
}
D2K.probes = {}
D2K.friendlyProbes = {}
function D2K.SpellInfo(id, friendly)
    id = D2K.Plain(id)
    if not D2K.Finite(id) or id <= 0 then return nil end
    local spell = D2K.Call(C_Spell and C_Spell.GetSpellInfo, id)
    if type(spell) ~= "table" then return nil end
    local name, maxRange, minRange = D2K.Plain(spell.name), D2K.Plain(spell.maxRange), D2K.Plain(spell.minRange)
    if type(name) ~= "string" or not D2K.Finite(maxRange) or maxRange <= 0 then return nil end
    local classification
    if C_Spell then
        if friendly then classification = C_Spell.IsSpellHelpful
        else classification = C_Spell.IsSpellHarmful end
    end
    if D2K.Boolean(D2K.Call(classification, id)) ~= true then return nil end
    if D2K.Boolean(D2K.Call(C_Spell and C_Spell.IsSpellPassive, id)) == true then return nil end
    return {id = id, name = name, maxRange = maxRange, minRange = D2K.Finite(minRange) and minRange or 0}
end
function D2K.SpellRange(id, unit)
    return D2K.Boolean(D2K.Call(C_Spell and C_Spell.IsSpellInRange, id, unit))
end
function D2K.RebuildProbes()
    local groups, seen = {enemy={}, friendly={}}, {enemy={}, friendly={}}
    local petNames = {}
    -- Pet-only spells can ignore the supplied unit and answer for the pet.
    for _, id in ipairs({136, 2641, 982, 1002, 6991, 19574, 755}) do
        local info = D2K.Call(C_Spell and C_Spell.GetSpellInfo, id)
        local name = type(info) == "table" and D2K.Plain(info.name)
        if type(name) == "string" then petNames[name] = true end
    end
    local function group(range, category)
        local list = groups[category]
        if not list[range] then list[range] = {range = range, spells = {}, items = {}} end
        return list[range]
    end
    local function add(id, friendly)
        local category = friendly and "friendly" or "enemy"
        local info = D2K.SpellInfo(id, friendly)
        -- A miss on a spell with a minimum range is ambiguous, so omit it from yardage estimates.
        if info and not petNames[info.name] and info.minRange == 0 and info.maxRange <= 100 and not seen[category][info.name] then
            seen[category][info.name] = true
            local list = group(info.maxRange, category).spells
            if #list < 3 then list[#list + 1] = info.id end
        end
    end
    if C_SpellBook and Enum and Enum.SpellBookSpellBank then
        local count = D2K.Call(C_SpellBook.GetNumSpellBookSkillLines)
        if D2K.Finite(count) then
            for line = 1, count do
                local skill = D2K.Call(C_SpellBook.GetSpellBookSkillLineInfo, line)
                local offSpec = type(skill) == "table" and D2K.Plain(skill.offSpecID)
                if type(skill) == "table" and (not offSpec or offSpec == 0) then
                    local offset, num = D2K.Plain(skill.itemIndexOffset), D2K.Plain(skill.numSpellBookItems)
                    if D2K.Finite(offset) and D2K.Finite(num) then
                        -- Newer ranks come later in the book.
                        for slot = offset + num, offset + 1, -1 do
                            local entry = D2K.Call(C_SpellBook.GetSpellBookItemInfo, slot, Enum.SpellBookSpellBank.Player)
                            if type(entry) == "table" and not D2K.Plain(entry.isPassive) and not D2K.Plain(entry.isOffSpec) then
                                add(D2K.Plain(entry.spellID))
                                add(D2K.Plain(entry.spellID), true)
                            end
                        end
                    end
                end
            end
        end
    end
    for category, rows in pairs({enemy=items, friendly=friendlyItems}) do
        for _, row in ipairs(rows) do
            local list = group(row[1], category).items
            for i = 2, #row do
                list[#list + 1] = row[i]
                D2K.Call(C_Item and C_Item.RequestLoadItemDataByID, row[i])
            end
        end
    end
    D2K.probes, D2K.friendlyProbes = {}, {}
    for category, list in pairs({enemy=D2K.probes, friendly=D2K.friendlyProbes}) do
        for _, probe in pairs(groups[category]) do list[#list + 1] = probe end
        table.sort(list, function(a, b) return a.range < b.range end)
    end
end
function D2K.Distance(unit, selected, friendly)
    local answers = {}
    local allowItems = not friendly or not InCombatLockdown()
    if friendly then
        -- Direct distance is only usable when the client explicitly confirms it
        -- (normally group members outdoors). Never trust the number alone.
        if type(UnitDistanceSquared) == "function" then
            local ok, squared, checked = pcall(UnitDistanceSquared, unit)
            squared, checked = D2K.Plain(squared), D2K.Boolean(checked)
            if ok and checked == true and D2K.Finite(squared) and squared >= 0 then
                local distance = math.sqrt(squared)
                return 0, distance, {{range=distance, answer=true, source="group distance"}}
            end
        end
        -- Item checks often return nil for friendly players. Add the near/nearby
        -- interaction checks rather than letting a long-range buff be the only
        -- successful upper bound. These calls are prohibited on friends in combat.
        if allowItems then
            local near, nearby = 8, 28
            if type(UnitRace) == "function" then
                local ok, _, race = pcall(UnitRace, "player")
                race = D2K.Plain(race)
                if ok and race == "Tauren" then near, nearby = 6, 25
                elseif ok and race == "Scourge" then near, nearby = 7, 27 end
            end
            for _, probe in ipairs({{3, near}, {4, nearby}}) do
                local answer = D2K.Boolean(D2K.Call(CheckInteractDistance, unit, probe[1]))
                -- Only positive proximity answers are reliable evidence here:
                -- a negative answer may mean the interaction is inapplicable.
                if answer == true then
                    answers[#answers + 1] = {range=probe[2], answer=true, source="interaction"}
                end
            end
        end
    end
    for _, group in ipairs(friendly and D2K.friendlyProbes or D2K.probes) do
        local result
        for _, id in ipairs(group.spells) do
            result = D2K.SpellRange(id, unit)
            if result ~= nil then break end
        end
        if result == nil and allowItems then
            for _, id in ipairs(group.items) do
                local cached = not (C_Item and C_Item.IsItemDataCachedByID)
                    or D2K.Boolean(D2K.Call(C_Item.IsItemDataCachedByID, id)) == true
                if cached then result = D2K.Boolean(D2K.Call(C_Item and C_Item.IsItemInRange, id, unit)) end
                if result ~= nil then break end
            end
        end
        answers[#answers + 1] = {range = group.range, answer = result}
    end
    local info = not friendly and selected and D2K.SpellInfo(selected)
    if info and info.minRange == 0 then
        answers[#answers + 1] = {range = info.maxRange, answer = D2K.SpellRange(selected, unit)}
    end
    local low, high = D2K.Bounds(answers)
    return low, high, answers
end
