local _, D2K = ...
D2K.iconCatalog, D2K.iconIndex = {}, {}
function D2K.AddIcon(entry)
    D2K.iconCatalog[#D2K.iconCatalog + 1] = entry
    D2K.iconIndex[entry.key] = entry
end
for _, shape in ipairs({"crosshair", "circle", "bullseye", "diamond", "brackets", "dot"}) do
    local round = shape == "crosshair" or shape == "circle" or shape == "bullseye"
    D2K.AddIcon({key=shape, name=shape:sub(1,1):upper() .. shape:sub(2),
        shape=not round and shape or nil,
        texture=round and ("Interface\\AddOns\\D2K\\Media\\" .. shape .. ".tga") or nil, group="Shapes"})
end
for i, name in ipairs({"Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull"}) do
    D2K.AddIcon({key="marker" .. i, name="Raid marker " .. name, texture=137000+i, group="Game"})
end
local geometry = {}
local function segments(shape)
    if geometry[shape] then return geometry[shape] end
    local result = {}
    local function line(x1,y1,x2,y2) result[#result+1]={x1,y1,x2,y2} end
    if shape == "diamond" then
        line(0,.44,.44,0);line(.44,0,0,-.44);line(0,-.44,-.44,0);line(-.44,0,0,.44)
    elseif shape == "brackets" then
        for _, x in ipairs({-1,1}) do for _, y in ipairs({-1,1}) do
            line(x*.44,y*.44,x*.18,y*.44);line(x*.44,y*.44,x*.44,y*.18)
        end end
    elseif shape == "dot" then
        for i=-2,2 do line(-.16,i*.065,.16,i*.065) end
    end
    geometry[shape]=result;return result
end
function D2K.ResolveIcon(db)
    if db.iconChoice == "custom" then
        local text=(db.iconCustom or ""):match("^%s*(.-)%s*$")
        if text ~= "" then return {key="custom:" .. text, name="Custom", texture=tonumber(text) or text} end
    end
    return D2K.iconIndex[db.iconChoice] or D2K.iconIndex.crosshair
end
function D2K.DrawIcon(frame, entry, size, color, tint)
    frame.lines = frame.lines or {}
    if not frame.image then frame.image=frame:CreateTexture(nil,"ARTWORK");frame.image:SetAllPoints() end
    if frame.entryKey ~= entry.key or frame.drawSize ~= size then
        for _, line in ipairs(frame.lines) do line:Hide() end
        frame.image:Hide()
        local shape=entry.shape
        if entry.texture then
            local ok, exists=pcall(frame.image.SetTexture,frame.image,entry.texture)
            if ok and exists ~= false then frame.image:Show()
            else
                frame.image:SetTexture(D2K.iconIndex.crosshair.texture)
                frame.image:Show();shape=nil
            end
        end
        frame.visibleLines=0
        if shape then
            for i, coords in ipairs(segments(shape)) do
                local line=frame.lines[i]
                if not line then line=frame:CreateLine(nil,"ARTWORK");frame.lines[i]=line end
                line:SetThickness(math.max(1,size/12))
                line:SetStartPoint("CENTER",frame,coords[1]*size,coords[2]*size)
                line:SetEndPoint("CENTER",frame,coords[3]*size,coords[4]*size)
                line:Show();frame.visibleLines=i
            end
        end
        frame.entryKey,frame.drawSize=entry.key,size
        frame.colorKey=nil
    end
    local r,g,b=1,1,1
    if tint then r,g,b=color[1],color[2],color[3] end
    local key=r .. ":" .. g .. ":" .. b
    if frame.colorKey ~= key then
        frame.image:SetVertexColor(r,g,b)
        for i=1,frame.visibleLines do frame.lines[i]:SetColorTexture(r,g,b,1) end
        frame.colorKey=key
    end
    frame:SetSize(size,size)
end
function D2K.IconSize(db)
    return db.iconSize * (db.iconScaleWithText and db.fontSize / 9 or 1)
end
function D2K.LayoutIcon(holder, color, db)
    if not holder.icon then holder.icon=CreateFrame("Frame",nil,holder);holder.icon:EnableMouse(false) end
    local span=0
    if db.iconEnabled and db.distance then
        local size=D2K.IconSize(db)
        span=size+db.iconGap
        D2K.DrawIcon(holder.icon,D2K.ResolveIcon(db),size,color,db.iconTint)
        holder.icon:ClearAllPoints()
        holder.icon:SetPoint("RIGHT",holder.text,"LEFT",-db.iconGap,0)
        holder.icon:Show()
    else holder.icon:Hide() end
    holder.text:ClearAllPoints()
    holder.text:SetPoint("CENTER",holder,"CENTER",span/2,0)
    return span
end
