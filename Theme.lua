local _, F = ...

F.media = "Interface\\AddOns\\FeralDeck\\Media\\"

local function font(name, fallback, file, size, color, shadow)
    local face = CreateFont("FeralDeck" .. name .. "Font")
    -- Font objects can return nil on success. Check the installed face instead.
    local loaded = pcall(face.SetFont, face, F.media .. file, size, "")
    if not loaded or not face:GetFont() then return fallback end
    face:SetTextColor(unpack(color))
    if shadow then
        face:SetShadowColor(0, 0, 0, .67)
        face:SetShadowOffset(0, -1)
    end
    return face
end

local body, semibold, display = "Barlow-Medium.ttf", "Barlow-SemiBold.ttf", "Cinzel-Regular.ttf"
local ivory, gold = {.92,.95,.99}, {.96,.82,.60}
F.fonts = {
    body = font("Body","GameFontHighlight",body,13,ivory,true),
    bold = font("Bold","GameFontHighlight",semibold,13,ivory,true),
    italic = font("Italic","GameFontHighlightSmall","Barlow-MediumItalic.ttf",11,ivory,true),
    small = font("Small","GameFontHighlight",body,11,ivory,true),
    strongSmall = font("StrongSmall","GameFontHighlightSmall",semibold,11,ivory,true),
    card = font("Card","GameFontHighlight",semibold,13,ivory,true),
    cardTitle = font("CardTitle","GameFontNormalLarge",display,18,ivory,true),
    hover = font("Hover","GameFontNormal",body,13,{.79,.92,1},true),
    disabled = font("Disabled","GameFontDisable",body,13,{.59,.65,.74}),
    heading = font("Heading","GameFontNormalLarge",semibold,15,ivory,true),
    title = font("Title","GameFontNormalHuge",display,23,{1,.92,.76},true),
    metric = font("Metric","GameFontNormalLarge",semibold,28,{1,.86,.62},true),
    muted = font("Muted","GameFontHighlightSmall",body,12,{.77,.84,.92},true),
    brand = font("Brand","GameFontNormalHuge",display,19,gold,true),
}

F.uiColors={
    gold="|cfff1cd88", muted="|cffbdcadb", damage="|cffffa5aa",
    shield="|cff9dd2ff", focus="|cffd8baff", success="|cff99e6b5",
    synergy="|cff99e6db",
}

function F.showTooltip(owner,anchor,title,body)
    GameTooltip:SetOwner(owner,anchor)
    GameTooltip:SetText(title,1,.84,.56,1,true)
    for line in (body.."\n"):gmatch("([^\n]*)\n") do
        GameTooltip:AddLine(line=="" and " " or line,.92,.95,.99,true)
    end
    GameTooltip:Show()
end
