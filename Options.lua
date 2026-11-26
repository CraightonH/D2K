local _, D2K = ...
local function label(parent, text, x, y, size)
    local font = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    font:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 12, "")
    font:SetPoint("TOPLEFT", x, y); font:SetText(text); font:SetJustifyH("LEFT")
    return font
end
local function button(parent, text, x, y, width, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT", x, y); b:SetSize(width, 24); b:SetText(text)
    b:SetScript("OnClick", callback); return b
end
local function check(parent, key, text, x, y)
    local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    b:SetPoint("TOPLEFT", x, y); b:SetSize(24, 24); b:SetChecked(D2K.db[key])
    local t = label(b, text, 28, -5); t:SetWidth(210)
    b:SetScript("OnClick", function(self) D2K.db[key] = not not self:GetChecked(); D2K.SettingsChanged() end)
    parent.controls[#parent.controls + 1] = function() b:SetChecked(D2K.db[key]) end
end
local function slider(parent, key, text, x, y, low, high, step)
    local title = label(parent, text, x, y)
    local s = CreateFrame("Slider", nil, parent)
    s:SetPoint("TOPLEFT", x, y - 22); s:SetSize(214, 16); s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(low, high); s:SetValueStep(step); s:SetObeyStepOnDrag(true)
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0.22, 0.25, 0.3, 1); track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(5)
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    s:GetThumbTexture():SetSize(28, 28)
    local function caption(value)
        title:SetText(text .. ": " .. (step < 1 and ("%.2f"):format(value) or tostring(math.floor(value + 0.5))))
    end
    s:SetValue(D2K.db[key]); caption(D2K.db[key])
    s:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value / step + 0.5) * step
        caption(value); D2K.db[key] = value; D2K.SettingsChanged()
    end)
    parent.controls[#parent.controls + 1] = function() s:SetValue(D2K.db[key]); caption(D2K.db[key]) end
end
local function colorButton(parent, key, text, x, y)
    local b
    local function paint()
        local c = D2K.db[key]
        b.swatch:SetColorTexture(c[1], c[2], c[3], 1)
    end
    b = button(parent, text, x, y, 148, function()
        if not ColorPickerFrame or not ColorPickerFrame.SetupColorPickerAndShow then
            D2K.Print("The color picker is unavailable on this client."); return
        end
        local previous = D2K.Copy(D2K.db[key])
        local c = D2K.db[key]
        ColorPickerFrame:SetupColorPickerAndShow({
            r = c[1], g = c[2], b = c[3], hasOpacity = false,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                D2K.db[key] = {r, g, b}; paint(); D2K.SettingsChanged()
            end,
            cancelFunc = function() D2K.db[key] = previous; paint(); D2K.SettingsChanged() end,
        })
    end)
    b.swatch = b:CreateTexture(nil, "OVERLAY")
    b.swatch:SetPoint("LEFT", 8, 0); b.swatch:SetSize(12, 12); paint()
    parent.controls[#parent.controls + 1] = paint
end
function D2K.RefreshOptions()
    if not D2K.options then return end
    local id, source = D2K.GetSelection()
    local info = id and D2K.SpellInfo(id)
    D2K.options.selection:SetText("Selected: " .. (info and info.name or "none") .. "  (" .. (source or "none") .. ")")
    local color = D2K.db.inColor
    local preview = D2K.options.preview
    preview:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", D2K.db.fontSize, D2K.db.outline)
    preview:SetTextColor(color[1], color[2], color[3], D2K.db.opacity)
    local parts = {}
    if D2K.db.distance then parts[#parts + 1] = "30" end
    if D2K.db.status then parts[#parts + 1] = "IN" end
    local text = table.concat(parts, "  ")
    if D2K.db.spellName then text = text .. (text ~= "" and "\n" or "") .. (info and info.name or "Frostbolt") end
    preview:SetText(text ~= "" and text or "(all label parts hidden)")
    D2K.options.previewHolder.text = preview
    D2K.LayoutIcon(D2K.options.previewHolder, color, D2K.db)
    D2K.options.previewHolder.icon:SetAlpha(D2K.db.opacity)
    D2K.options.previewBG:SetColorTexture(0.025, 0.035, 0.045, D2K.db.background * D2K.db.opacity)
    if D2K.RefreshIconOptions then D2K.RefreshIconOptions() end
end
local function build()
    local f = CreateFrame("Frame", "D2KOptions", UIParent, "BackdropTemplate")
    D2K.options = f
    f.controls = {}
    f:SetSize(530, 680); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = {left=4, right=4, top=4, bottom=4}})
    f:SetBackdropColor(0.08, 0.1, 0.13, 0.98)
    label(f, "D2K", 20, -18, 20)
    label(f, "Nameplate range coach", 20, -44)
    button(f, "Range icon...", 300, -42, 200, D2K.OpenIconOptions)
    button(f, "Close", 440, -18, 68, function() f:Hide() end)
    f.selection = label(f, "", 20, -70); f.selection:SetWidth(490)
    local preview = CreateFrame("Frame", nil, f)
    f.previewHolder = preview
    preview:SetPoint("TOPLEFT", 20, -96); preview:SetSize(488, 54)
    f.previewBG = preview:CreateTexture(nil, "BACKGROUND"); f.previewBG:SetAllPoints()
    f.preview = preview:CreateFontString(nil, "OVERLAY"); f.preview:SetPoint("CENTER")
    check(f, "enabled", "Enable nameplate overlay", 18, -162)
    check(f, "hover", "Hovered spell takes priority", 278, -162)
    check(f, "lastCast", "Use last successful ranged cast", 18, -192)
    check(f, "spellName", "Show selected spell name", 278, -192)
    check(f, "distance", "Show distance number", 18, -222)
    check(f, "status", "Show IN / OUT / ?", 278, -222)
    check(f, "hideUnknown", "Hide entirely unknown labels", 18, -252)
    check(f, "pulse", "Pulse on range boundary crossing", 278, -252)
    check(f, "friendly", "Show friendly nameplates", 18, -282)
    check(f, "enemies", "Show enemy nameplates", 278, -282)
    slider(f, "fontSize", "Text size", 24, -324, 4, 32, 0.1)
    slider(f, "opacity", "Overlay opacity", 284, -324, 0.1, 1, 0.05)
    slider(f, "offsetX", "Horizontal offset", 24, -380, -150, 150, 1)
    slider(f, "offsetY", "Vertical offset", 284, -380, -150, 150, 1)
    slider(f, "background", "Background opacity", 24, -436, 0, 1, 0.05)
    slider(f, "interval", "Update interval (seconds)", 284, -436, 0.05, 1, 0.05)
    local position = button(f, "Position: " .. D2K.db.anchor, 24, -492, 214, function(self)
        local nextAnchor = {RIGHT="BELOW", BELOW="LEFT", LEFT="ABOVE", ABOVE="RIGHT"}
        D2K.db.anchor = nextAnchor[D2K.db.anchor]; self:SetText("Position: " .. D2K.db.anchor); D2K.SettingsChanged()
    end)
    local outline = button(f, "Outline: " .. (D2K.db.outline == "" and "NONE" or D2K.db.outline), 284, -492, 214, function(self)
        local nextOutline = {OUTLINE="THICKOUTLINE", THICKOUTLINE="", [""]="OUTLINE"}
        D2K.db.outline = nextOutline[D2K.db.outline]
        self:SetText("Outline: " .. (D2K.db.outline == "" and "NONE" or D2K.db.outline)); D2K.SettingsChanged()
    end)
    f.controls[#f.controls + 1] = function() position:SetText("Position: " .. D2K.db.anchor) end
    f.controls[#f.controls + 1] = function() outline:SetText("Outline: " .. (D2K.db.outline == "" and "NONE" or D2K.db.outline)) end
    colorButton(f, "inColor", "In range", 24, -532)
    colorButton(f, "outColor", "Out of range", 187, -532)
    colorButton(f, "unknownColor", "Unknown", 350, -532)
    label(f, "Number = within that many yards, rounded up to the next 5.\nPriority: hovered spell, current cast, then last successful cast.\nUtility, self-only AoE, failed casts, and hidden results do not change it.", 24, -576, 11)
    button(f, "Reset settings", 24, -638, 148, function() D2K.Reset(); D2K.OpenOptions() end)
    button(f, "Print diagnostics", 187, -638, 148, function() SlashCmdList.D2K("debug") end)
    button(f, "Clear last spell", 350, -638, 148, function() SlashCmdList.D2K("clear") end)
    f:SetScript("OnShow", D2K.RefreshOptions)
    if UISpecialFrames then
        local exists = false; for _, name in ipairs(UISpecialFrames) do if name == "D2KOptions" then exists = true end end
        if not exists then table.insert(UISpecialFrames, "D2KOptions") end
    end
    D2K.RefreshOptions()
    return f
end
function D2K.OpenIconOptions()
    if D2K.iconOptions then D2K.iconOptions:Show(); return end
    local f = CreateFrame("Frame", "D2KIconOptions", UIParent, "BackdropTemplate")
    D2K.iconOptions = f; f.controls = {}
    f:SetSize(550, 700); f:SetPoint("CENTER"); f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(true); f:SetMovable(true); f:SetClampedToScreen(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}})
    f:SetBackdropColor(.08,.1,.13,.98)
    label(f,"Range icon",24,-18,20)
    button(f,"Close",450,-18,76,function() f:Hide() end)
    local selected=label(f,"",24,-55,12); selected:SetWidth(500)
    check(f,"iconEnabled","Show icon beside distance",18,-87)
    check(f,"iconTint","Match the range text color",278,-87)
    check(f,"iconScaleWithText","Scale icon with text",18,-115)
    slider(f,"iconSize","Base icon size",24,-151,6,32,1)
    slider(f,"iconGap","Space before number",284,-151,0,16,1)
    label(f,"Search",24,-199)
    local search=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    search:SetPoint("TOPLEFT",100,-193);search:SetSize(265,24);search:SetAutoFocus(false)
    search:SetMaxLetters(100)
    local page,source=1,"All"
    local filtered,buttons={},{}
    local pageLabel=label(f,"",219,-570,12)
    local function render()
        local pages=math.max(1,math.ceil(#filtered/40));page=math.max(1,math.min(page,pages))
        pageLabel:SetText(("%d / %d  (%d icons)"):format(page,pages,#filtered))
        for i,b in ipairs(buttons) do
            local entry=filtered[(page-1)*40+i];b.entry=entry
            if entry then
                b.caption:SetText(entry.name)
                D2K.DrawIcon(b.symbol,entry,28,{1,1,1},false)
                local picked=D2K.db.iconChoice==entry.key
                b.background:SetColorTexture(picked and .12 or .03,picked and .4 or .05,picked and .55 or .07,.95)
                b:Show()
            else b:Hide() end
        end
    end
    local function filter()
        local query=(search:GetText() or ""):lower();filtered={}
        local library=D2K.Call(C_AddOns and C_AddOns.GetAddOnInfo,"ForeverAuras")
        for _,entry in ipairs(D2K.iconCatalog) do
            local isLibrary=entry.group:find("ForeverAuras",1,true)~=nil
            local inSource=source=="All" or entry.group:find(source,1,true)~=nil
            local haystack=(entry.name .. " " .. entry.group .. " " .. tostring(entry.texture or "")):lower()
            if inSource and (not isLibrary or library) and haystack:find(query,1,true) then
                filtered[#filtered+1]=entry
            end
        end
        page=1;render()
    end
    button(f,"Source: All",380,-193,146,function(self)
        source=({All="Shapes",Shapes="Game",Game="ForeverAuras",ForeverAuras="All"})[source]
        self:SetText("Source: " .. source);filter()
    end)
    for i=1,40 do
        local b=CreateFrame("Button",nil,f)
        b:SetSize(60,60);b:SetPoint("TOPLEFT",20+((i-1)%8)*64,-229-math.floor((i-1)/8)*64)
        b.background=b:CreateTexture(nil,"BACKGROUND");b.background:SetAllPoints()
        b.symbol=CreateFrame("Frame",nil,b);b.symbol:SetSize(28,28);b.symbol:SetPoint("TOP",0,-3)
        b.caption=label(b,"",4,-36,9);b.caption:SetWidth(52);b.caption:SetHeight(22)
        b:SetScript("OnClick",function(self)
            if self.entry then D2K.db.iconChoice=self.entry.key;D2K.SettingsChanged();render() end
        end)
        buttons[i]=b
    end
    search:SetScript("OnTextChanged",filter)
    search:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    button(f,"Previous",24,-563,90,function() page=page-1;render() end)
    button(f,"Next",432,-563,90,function() page=page+1;render() end)
    label(f,"Custom texture path or file ID",24,-604,12)
    local custom=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    custom:SetPoint("TOPLEFT",28,-623);custom:SetSize(365,24);custom:SetAutoFocus(false)
    custom:SetMaxLetters(512);custom:SetText(D2K.db.iconCustom)
    f.controls[#f.controls+1]=function() custom:SetText(D2K.db.iconCustom) end
    local function apply()
        local value=(custom:GetText() or ""):match("^%s*(.-)%s*$")
        if value=="" then D2K.Print("Enter a texture path or numeric file ID.");return end
        D2K.db.iconCustom=value;D2K.db.iconChoice="custom";custom:ClearFocus();D2K.SettingsChanged();render()
    end
    button(f,"Apply",410,-623,112,apply);custom:SetScript("OnEnterPressed",apply)
    label(f,"Library icons use installed ForeverAuras files. Missing files use crosshairs.\nLinked icons scale proportionally from their size at 9 pt text.",24,-660,10)
    D2K.RefreshIconOptions=function()
        local entry=D2K.ResolveIcon(D2K.db)
        selected:SetText("Selected: " .. entry.name .. (entry.group and ("  / " .. entry.group) or ""))
        for _,b in ipairs(buttons) do
            if b.entry then
                local picked=D2K.db.iconChoice==b.entry.key
                b.background:SetColorTexture(picked and .12 or .03,picked and .4 or .05,picked and .55 or .07,.95)
            end
        end
    end
    f:SetScript("OnShow",function() filter();D2K.RefreshIconOptions() end)
    if UISpecialFrames then table.insert(UISpecialFrames,"D2KIconOptions") end
    filter();D2K.RefreshIconOptions();f:Show()
end
function D2K.OpenOptions()
    local f = D2K.options or build()
    f:Show(); D2K.RefreshOptions()
end
function D2K.RegisterSettings()
    if not Settings or not Settings.RegisterCanvasLayoutCategory then return end
    local panel = CreateFrame("Frame", nil, UIParent)
    label(panel, "D2K", 20, -20, 20)
    label(panel, "Friendly and enemy nameplate distances with enemy spell-range feedback.", 20, -58)
    button(panel, "Open D2K settings", 20, -95, 245, D2K.OpenOptions)
    local category = Settings.RegisterCanvasLayoutCategory(panel, "D2K")
    Settings.RegisterAddOnCategory(category)
end
