local D2K = {}
local root = "."
local consolePrint = print
local checks = 0
local function eq(actual, expected, message)
    checks = checks + 1
    assert(actual == expected, (message or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function load(name) assert(loadfile(root .. "/" .. name .. ".lua"))("D2K", D2K) end
local SECRET = {}
issecretvalue = function(v) return rawequal(v, SECRET) end
local now = 0
local Frame = {}
function Frame:SetScript(kind, fn) self.scripts[kind] = fn end
function Frame:HookScript(kind, fn)
    local old = self.scripts[kind]
    self.scripts[kind] = function(...) if old then old(...) end; fn(...) end
end
function Frame:RegisterEvent(name) self.events[name] = true end
function Frame:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function Frame:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function Frame:IsShown() return self.shown end
function Frame:SetText(t) self.text = t end
function Frame:GetText() return self.text end
function Frame:SetChecked(v) self.checked = v end
function Frame:GetChecked() return self.checked end
function Frame:SetValue(v) self.value = v; if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end end
function Frame:GetValue() return self.value end
function Frame:SetColorTexture(...) self.color = {...} end
function Frame:SetVertexColor(...) self.color = {...} end
function Frame:SetTexture(value) self.texture=value;return value ~= "missing" end
function Frame:SetTextColor(...) self.color = {...} end
function Frame:SetPoint(...) self.point = {...} end
function Frame:GetStringWidth() return #(self.text or "") * 5 end
function Frame:GetStringHeight() return 30 end
function Frame:IsForbidden() return self.forbidden end
for _, name in ipairs({"SetSize", "SetAllPoints", "EnableMouse", "SetFont", "SetJustifyH", "SetShadowColor", "SetShadowOffset", "SetAlpha", "SetWordWrap", "ClearAllPoints", "SetClampedToScreen", "SetMovable", "RegisterForDrag", "SetBackdrop", "SetBackdropColor", "SetFrameStrata", "SetWidth", "SetHeight", "SetOrientation", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "StartMoving", "StopMovingOrSizing", "SetThickness", "SetStartPoint", "SetEndPoint", "SetAutoFocus", "SetMaxLetters", "ClearFocus"}) do Frame[name] = function() end end
local function frame()
    return setmetatable({scripts={}, events={}, shown=true}, {__index=Frame})
end
CreateFrame = function(kind, name, parent) local f = frame(); f.parent=parent; if name then _G[name]=f end; return f end
function Frame:CreateTexture() return frame() end
function Frame:CreateLine() return frame() end
function Frame:CreateFontString() return frame() end
function Frame:SetThumbTexture() self.thumb=frame() end
function Frame:GetThumbTexture() return self.thumb end
UIParent = frame(); GameTooltip = frame(); UISpecialFrames = {}; SlashCmdList = {}
GameTooltip.SetSpellByID = function() end
GameTooltip.SetSpellBookItem = function() end
GameTooltip.SetAction = function() end
local hooks = {}
hooksecurefunc = function(object, method, callback)
    local old=object[method]
    object[method] = function(...) local result=old(...); callback(...); return result end
end
Enum = {SpellBookSpellBank={Player=0}, TooltipDataType={Spell=0, Unit=1, Item=2}}
local tooltipCallbacks = {}
TooltipDataProcessor = {AddTooltipPostCall=function(kind, fn) tooltipCallbacks[kind]=fn end}
local spells = {
    [116]={name="Frostbolt", minRange=0, maxRange=30, harmful=true},
    [133]={name="Fireball", minRange=0, maxRange=35, harmful=true},
    [2136]={name="Fire Blast", minRange=0, maxRange=20, harmful=true},
    [1459]={name="Arcane Intellect", minRange=0, maxRange=30},
    [122]={name="Frost Nova", minRange=0, maxRange=0, harmful=true},
    [999]={name="Minimum range spell", minRange=8, maxRange=30, harmful=true},
}
local spellResults, itemResults, unitDistances = {}, {}, {nameplate1=24, nameplate2=37}
C_Spell = {
    GetSpellInfo=function(id) if id==SECRET then error("secret id passed") end; return spells[id] end,
    IsSpellHarmful=function(id) return spells[id] and spells[id].harmful or false end,
    IsSpellHelpful=function(id) return id==1459 end,
    IsSpellPassive=function() return false end,
    IsSpellInRange=function(id, unit)
        if spellResults[id] ~= nil then
            if spellResults[id]=="nil" then return nil end
            if spellResults[id]=="error" then error("restricted") end
            return spellResults[id]
        end
        local spell, distance=spells[id], unitDistances[unit]
        if spell and distance then return distance>=spell.minRange and distance<=spell.maxRange end
    end,
}
C_SpellBook = {
    GetNumSpellBookSkillLines=function() return 1 end,
    GetSpellBookSkillLineInfo=function() return {itemIndexOffset=0,numSpellBookItems=6} end,
    GetSpellBookItemInfo=function(slot) return {spellID=({116,133,2136,1459,122,999})[slot]} end,
}
local itemRanges = {[8149]=5,[22432]=5,[17626]=10,[10699]=10,[10645]=20,[1191]=20,[13289]=25,[835]=30,[7734]=30,[18904]=35,[4945]=40,[8348]=40}
C_Item = {
    RequestLoadItemDataByID=function() end,
    IsItemDataCachedByID=function() return true end,
    IsItemInRange=function(id, unit)
        if itemResults[id] then return itemResults[id] end
        if unitDistances[unit] then return unitDistances[unit]<=itemRanges[id] end
    end,
}
local plates = {nameplate1=frame(),nameplate2=frame()}
for unit, plate in pairs(plates) do plate.namePlateUnitToken=unit; plate.UnitFrame={HealthBarsContainer=frame()} end
C_NamePlate = {
    GetNamePlateForUnit=function(unit) return plates[unit] end,
    GetNamePlates=function() return {plates.nameplate1,plates.nameplate2} end,
}
local hostile=true
UnitCanAttack=function() return hostile end
UnitCanAssist=function(_, unit) return unit=="friendly1" end
UnitIsUnit=function(a,b) return a==b end
UnitIsDeadOrGhost=function() return false end
InCombatLockdown=function() return false end
GetBuildInfo=function() return "1.60.1", "71091", "", 16001 end
GetActionInfo=function(slot)
    if slot==1 then return "spell",116 elseif slot==2 then return "macro",10 end
    return "item",123
end
GetMacroSpell=function() return 2136 end
local messages={}
print=function(message) messages[#messages+1]=message end
Settings={RegisterCanvasLayoutCategory=function() return {} end,RegisterAddOnCategory=function() end}
ColorPickerFrame=frame()
function ColorPickerFrame:SetupColorPickerAndShow(info) self.info=info end
function ColorPickerFrame:GetColorRGB() return 0.2,0.4,0.8 end

load("Model"); load("Icons"); load("IconCatalog"); load("Range"); load("Options"); load("Core")
local db=D2K.Sanitize({fontSize=999,opacity=0/0,anchor="BAD",inColor={2,-1,0.5}})
eq(db.fontSize,32,"clamp size");eq(db.opacity,1,"reject NaN");eq(db.anchor,"BELOW","invalid anchor")
eq(db.inColor[1],1);eq(db.inColor[2],0)
eq(D2K.Boolean(SECRET),nil,"secret stays unknown");eq(D2K.Boolean(0),false,"numeric false")
eq(D2K.Call(function() error("restricted") end),nil,"API errors stay unknown")
local low,high=D2K.Bounds({{range=20,answer=false},{range=30,answer=true},{range=25,answer=SECRET}})
eq(low,20);eq(high,30)
eq(D2K.Bounds({{range=20,answer=nil}}),nil,"all unknown")
eq(D2K.Bounds({{range=30,answer=false},{range=20,answer=true}}),nil,"conflicting bounds")
eq(D2K.DistanceLabel(20,26),"30","round upper bound up to five")
eq(D2K.DistanceLabel(nil,nil),"?");eq(D2K.DistanceLabel(20,30),"30")
eq(D2K.DistanceLabel(30,nil),"?");eq(D2K.DistanceLabel(0,5),"5")

D2K.events.scripts.OnEvent(D2K.events,"ADDON_LOADED","D2K")
D2K.events.scripts.OnEvent(D2K.events,"PLAYER_LOGIN")
D2K.db.status=true -- Exercise the optional explicit status text below.
eq(D2K.GetSelection(),nil,"no invented default spell")
eq(D2K.active.nameplate1~=nil,true,"existing plates picked up at login")
local function castEvent(event, id, guid, unit)
    D2K.events.scripts.OnEvent(D2K.events,event,unit or "player",guid or "cast-A",id)
end
castEvent("UNIT_SPELLCAST_START",116)
eq(D2K.GetSelection(),116,"first cast selected before any success")
eq(select(2,D2K.GetSelection()),"casting","active cast source")
eq(D2K.active.nameplate1.text.color[1],D2K.db.inColor[1],"cast start updates label immediately")
eq(D2KCharacterDB.lastSpell,nil,"cast start does not save success")
D2K.SetHover(2136);eq(D2K.GetSelection(),2136,"hover overrides current cast")
D2K.SetHover(nil);eq(D2K.GetSelection(),116,"leaving hover restores active cast")
castEvent("UNIT_SPELLCAST_INTERRUPTED",116)
eq(D2K.GetSelection(),nil,"interrupted first cast returns to no selection")
castEvent("UNIT_SPELLCAST_START",133,"other","party1")
eq(D2K.GetSelection(),nil,"other player's cast start ignored")
castEvent("UNIT_SPELLCAST_START",SECRET)
eq(D2K.GetSelection(),nil,"hidden spell start ignored")
D2K.RecordCast(116);eq(D2K.GetSelection(),116,"successful cast selected")
D2K.SetHover(2136);local id,source=D2K.GetSelection();eq(id,2136,"hover overrides");eq(source,"hover")
D2K.RecordCast(133);eq(D2K.GetSelection(),2136,"cast during hover stays preview")
D2K.SetHover(nil);eq(D2K.GetSelection(),133,"leaving hover restores latest cast")
D2K.RecordCast(1459);eq(D2K.GetSelection(),133,"buff ignored")
D2K.RecordCast(122);eq(D2K.GetSelection(),133,"self AoE ignored")
D2K.RecordCast(SECRET);eq(D2K.GetSelection(),133,"hidden cast ignored")
D2K.events.scripts.OnEvent(D2K.events,"UNIT_SPELLCAST_FAILED","player","guid",116)
eq(D2K.GetSelection(),133,"failed cast ignored")
D2K.events.scripts.OnEvent(D2K.events,"UNIT_SPELLCAST_SUCCEEDED","party1","guid",116)
eq(D2K.GetSelection(),133,"other player ignored")
D2K.events.scripts.OnEvent(D2K.events,"UNIT_SPELLCAST_SUCCEEDED","player","guid",116)
eq(D2K.GetSelection(),116,"player cast event works")
eq(D2KCharacterDB.lastSpell,116,"selection saved per character")
castEvent("UNIT_SPELLCAST_START",133,"cast-B")
eq(D2K.GetSelection(),133,"new active spell supersedes last success")
castEvent("UNIT_SPELLCAST_FAILED",133,"cast-B")
eq(D2K.GetSelection(),116,"failure restores previous success")
castEvent("UNIT_SPELLCAST_START",116,"old")
castEvent("UNIT_SPELLCAST_START",133,"new")
castEvent("UNIT_SPELLCAST_STOP",116,"old")
eq(D2K.GetSelection(),133,"stale stop cannot clear newer cast")
castEvent("UNIT_SPELLCAST_INTERRUPTED",133,"new")
eq(D2K.GetSelection(),116,"interruption restores previous spell")
castEvent("UNIT_SPELLCAST_CHANNEL_START",2136,"channel")
eq(D2K.GetSelection(),2136,"channel start selects immediately")
castEvent("UNIT_SPELLCAST_STOP",2136,"channel")
eq(select(2,D2K.GetSelection()),"casting","cast stop does not clear channel")
castEvent("UNIT_SPELLCAST_SUCCEEDED",2136,"channel")
castEvent("UNIT_SPELLCAST_CHANNEL_STOP",2136,"channel")
eq(D2K.GetSelection(),2136,"successful channel remains selected")
eq(select(2,D2K.GetSelection()),"last cast","channel stop clears active state")
D2K.RecordCast(116)

GameTooltip:Show();GameTooltip:SetAction(2);eq(D2K.GetSelection(),2136,"macro tooltip resolves spell")
GameTooltip:Hide();eq(D2K.GetSelection(),116,"hide restores last cast")
GameTooltip:Show();GameTooltip:SetAction(1);eq(select(2,D2K.GetSelection()),"hover","action preview")
tooltipCallbacks[Enum.TooltipDataType.Unit](GameTooltip,{});eq(select(2,D2K.GetSelection()),"last cast","unit tooltip clears preview")
tooltipCallbacks[Enum.TooltipDataType.Spell](GameTooltip,{id=2136});eq(D2K.GetSelection(),2136)
tooltipCallbacks[Enum.TooltipDataType.Item](GameTooltip,{});eq(D2K.GetSelection(),116)
D2K.db.hover=false;D2K.SetHover(2136);eq(D2K.GetSelection(),116,"hover toggle")
D2K.db.hover=true;D2K.SetHover(nil)

low,high=D2K.Distance("nameplate1",116);eq(low,20,"distance lower band");eq(high,25,"distance upper band")
D2K.UpdateAll()
local first=D2K.active.nameplate1;local second=D2K.active.nameplate2
eq(first:IsShown(),true,"first plate visible");eq(second:IsShown(),true,"second visible without target")
eq(first.text.text:find("IN",1,true)~=nil,true,"inside label")
eq(second.text.text:find("OUT",1,true)~=nil,true,"outside label preserves false")
unitDistances.nameplate1=34;D2K.UpdateAll();eq(first.pulseUntil~=nil,true,"boundary crossing pulses")
spellResults[116]=SECRET;D2K.UpdateAll();eq(first.previous,nil,"secret result clears prior status")
eq(first.text.color[1],D2K.db.unknownColor[1],"secret result neutral")
spellResults[116]="error";D2K.UpdateAll();eq(first.previous,nil,"restricted result neutral")
spellResults[116]="nil";D2K.UpdateAll();eq(first.previous,nil,"nil never inferred out")
spellResults[116]=false;D2K.UpdateAll();eq(first.previous,false,"explicit false remains outside")
spellResults[116]=nil
-- Distance probes must ignore uncached/hidden items and minimum-range misses.
local cachedFunction=C_Item.IsItemDataCachedByID
C_Item.IsItemDataCachedByID=function() return false end
unitDistances.nameplate1=24
low,high=D2K.Distance("nameplate1",116);eq(low,20,"spell-only low");eq(high,30,"uncached items ignored")
C_Item.IsItemDataCachedByID=cachedFunction
local oldProbes=D2K.probes
D2K.probes={}
low,high=D2K.Distance("nameplate1",999);eq(low,nil,"minimum-range spell omitted from estimates")
spellResults[116]=SECRET
low,high=D2K.Distance("nameplate1",116);eq(low,nil,"hidden selected spell yields no distance")
D2K.db.hideUnknown=true;D2K.UpdateAll();eq(first:IsShown(),false,"entirely unknown label hidden")
D2K.db.hideUnknown=false;D2K.UpdateAll();eq(first:IsShown(),true,"unknown label restored")
spellResults[116]=nil;D2K.probes=oldProbes
hostile=false;D2K.UpdateAll();eq(first:IsShown(),false,"friendly plates hidden")
hostile=SECRET;D2K.UpdateAll();eq(first:IsShown(),false,"hidden hostility safely skipped")
hostile=true
D2K.RemovePlate("nameplate1");eq(first:IsShown(),false);eq(D2K.active.nameplate1,nil,"removed unit cleared")
plates.nameplate3=plates.nameplate1;plates.nameplate1=nil;unitDistances.nameplate3=12
D2K.AddPlate("nameplate3");eq(D2K.active.nameplate3,first,"pooled holder reused")
eq(first.previous,nil,"pooled state cleared")
plates.nameplate4=frame();plates.nameplate4.forbidden=true
D2K.AddPlate("nameplate4");eq(D2K.active.nameplate4,nil,"forbidden plate untouched")
SlashCmdList.D2K("off");eq(first:IsShown(),false,"disable hides overlays")
SlashCmdList.D2K("on");eq(first:IsShown(),true,"enable restores overlays")
D2K.OpenOptions();eq(D2K.options~=nil,true,"settings open")
local options=D2K.options
D2K.db.fontSize=27;D2K.db.offsetX=100;D2K.Reset();eq(D2K.db.fontSize,9);eq(D2K.db.offsetX,0)
eq(D2K.options,options,"reset reuses settings frame")
D2K.OpenOptions();SlashCmdList.D2K("debug")
-- Range glyphs share a centered layout and can be hidden or replaced by
-- standalone shapes, native game icons, and optional library textures.
eq(#D2K.iconCatalog,823,"six shapes, eight game markers, 809 library paths")
D2K.OpenIconOptions();eq(D2K.iconOptions~=nil,true,"icon chooser opens")
D2K.db.iconChoice="circle";D2K.SettingsChanged()
eq(first.icon.entryKey,"circle","shape selection applied to nameplate")
eq(first.icon.visibleLines,0,"circle avoids subpixel line segments")
eq(first.icon.image.texture,"Interface\\AddOns\\D2K\\Media\\circle.tga","circle uses bundled texture")
local firstImage=first.icon.image
D2K.UpdateAll();eq(first.icon.image,firstImage,"texture reused between updates")
D2K.db.iconChoice="bullseye";D2K.SettingsChanged()
eq(first.icon.image.texture,"Interface\\AddOns\\D2K\\Media\\bullseye.tga","bullseye uses bundled rings and center")
D2K.db.iconEnabled=false;D2K.SettingsChanged();eq(first.icon:IsShown(),false,"icon can be disabled")
D2K.db.iconEnabled=true;D2K.db.iconChoice="marker2";D2K.db.iconTint=false;D2K.SettingsChanged()
eq(first.icon.image.texture,137002,"game icon file ID")
eq(first.icon.image.color[1],1,"native colors preserved when tint is off")
D2K.db.iconChoice="custom";D2K.db.iconCustom="missing";D2K.SettingsChanged()
eq(first.icon.image.texture,"Interface\\AddOns\\D2K\\Media\\crosshair.tga","missing texture falls back to bundled crosshair")
D2K.db.iconCustom="137001";D2K.SettingsChanged()
eq(first.icon.image.texture,137001,"custom numeric file ID accepted")
D2K.db.iconChoice="fa:Assets/ring.tga";D2K.SettingsChanged()
eq(first.icon.image.texture,"Interface\\AddOns\\ForeverAuras\\Media\\Icons\\Assets\\ring.tga","library path used without copied assets")
D2K.db.distance=false;D2K.SettingsChanged();eq(first:IsShown(),false,"empty label and its icon hidden when distance text is off")
D2K.db.distance=true;D2K.Reset();eq(D2K.db.iconChoice,"crosshair","reset restores default icon")
eq(D2K.db.iconScaleWithText,true,"icons scale with text by default")
D2K.db.fontSize=18;D2K.SettingsChanged();eq(first.icon.drawSize,20,"doubling text doubles icon")
D2K.db.iconScaleWithText=false;D2K.SettingsChanged();eq(first.icon.drawSize,10,"unlinked icon stays fixed")
D2K.Reset()
-- Friendly nameplates use helpful spells, skip hostile spell feedback, and
-- do not query friendly items while in combat.
plates.friendly1=frame();plates.friendly1.UnitFrame={HealthBarsContainer=frame()}
unitDistances.friendly1=23
hostile=false;D2K.AddPlate("friendly1");D2K.UpdateAll()
local friend=D2K.active.friendly1
eq(friend:IsShown(),true,"friendly nameplate enabled by default")
eq(friend.text.text,"25","friendly estimate is a bare five-yard upper bound")
eq(friend.text.color[1],D2K.db.unknownColor[1],"no offensive coloring on friends")
D2K.db.spellName=true;D2K.db.status=true;D2K.UpdateAll()
eq(friend.text.text,"25","friendly labels omit offensive spell name and status")
local oldItemCheck=C_Item.IsItemInRange
local friendlyItemCalls=0
C_Item.IsItemInRange=function(...) friendlyItemCalls=friendlyItemCalls+1;return oldItemCheck(...) end
InCombatLockdown=function() return true end
D2K.UpdateAll();eq(friend.text.text,"30","friendly spell-only combat upper bound")
eq(friendlyItemCalls,0,"friendly items never queried in combat")
spellResults[1459]=SECRET;D2K.UpdateAll();eq(friend.text.text,"?","restricted friendly spell is unknown")
D2K.db.friendly=false;D2K.UpdateAll();eq(friend:IsShown(),false,"friendly toggle")
D2K.db.friendly=true;D2K.db.hideUnknown=true;D2K.UpdateAll();eq(friend:IsShown(),false,"unknown friendly data hidden on request")
D2K.db.hideUnknown=false;D2K.UpdateAll();eq(friend:IsShown(),true,"unknown friendly label can be shown")
spellResults[1459]=nil;InCombatLockdown=function() return false end
C_Item.IsItemInRange=oldItemCheck
-- Town regression: friendly item probes are unavailable and the only buff
-- check is 40 yards. Positive interactions must tighten that broad estimate.
spells[1459].maxRange=40;D2K.RebuildProbes()
C_Item.IsItemInRange=function() return nil end
UnitRace=function() return "Human","Human" end
local interactCalls=0
CheckInteractDistance=function(unit,index)
    interactCalls=interactCalls+1
    return unitDistances[unit] <= (index==3 and 8 or 28)
end
UnitDistanceSquared=function() return 99999,false end
unitDistances.friendly1=3;D2K.UpdateAll();eq(friend.text.text,"10","nearby town ally no longer reads 40")
unitDistances.friendly1=16;D2K.UpdateAll();eq(friend.text.text,"30","nearby interaction tightens buff estimate")
unitDistances.friendly1=36;D2K.UpdateAll();eq(friend.text.text,"40","far ally retains confirmed forty bound")
UnitDistanceSquared=function() return 49,true end
D2K.UpdateAll();eq(friend.text.text,"10","valid group distance used first")
UnitDistanceSquared=function() return 0,true end
D2K.UpdateAll();eq(friend.text.text,"5","zero-distance group member within five")
UnitDistanceSquared=function() return SECRET,true end
unitDistances.friendly1=3;D2K.UpdateAll();eq(friend.text.text,"10","hidden distance safely falls back to proximity")
UnitDistanceSquared=function() return 1,SECRET end
unitDistances.friendly1=36;D2K.UpdateAll();eq(friend.text.text,"40","hidden checked flag does not validate group distance")
local before=interactCalls
InCombatLockdown=function() return true end
D2K.UpdateAll();eq(interactCalls,before,"friendly interactions skipped in combat")
eq(friend.text.text,"40","combat falls back to available buff range")
InCombatLockdown=function() return false end
UnitDistanceSquared=nil;CheckInteractDistance=nil;UnitRace=nil
spells[1459].maxRange=30;D2K.RebuildProbes()
C_Item.IsItemInRange=oldItemCheck;hostile=true
SlashCmdList.D2K("clear");eq(D2K.GetSelection(),nil,"clear last spell")
D2K.events.scripts.OnUpdate(D2K.events,0.2)
assert(#messages>=4)
consolePrint("D2K: " .. checks .. " behavior assertions passed")
return checks
