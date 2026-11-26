local _, F = ...
local media,fonts,colors = F.media,F.fonts,F.uiColors
F.arenaPaintings={Snow="ArenaHighlands",Peak="ArenaHighlands",Woodland="ArenaWoodland"}

-- The scenery is stored as square textures. Crop around their center to
-- fill banners, wide battle portraits and narrow cards without distortion.
function F.coverArt(texture,width,height,zoom,dx,dy)
    local spanX=math.min(1,width/height)/(zoom or 1)*.98
    local spanY=math.min(1,height/width)/(zoom or 1)*.98
    local x=.5-spanX/2+(dx or 0)*(1-spanX)
    local y=.5-spanY/2+(dy or 0)*(1-spanY)
    texture:SetTexCoord(x,x+spanX,y,y+spanY)
end

local reward={discovery=true,reveal=true,perk=true,victory=true,defeat=true,draw=true,interrupted=true}
function F.sound(cue)
    local setting=(cue=="discovery" or cue=="reveal") and "discoveryCues"
        or reward[cue] and "rewardCues" or cue=="place" and "placementCues" or "battleCues"
    if F.db and F.db[setting]~=false
        and (F.db.audioMode=="Full" or F.db.audioMode=="Rewards Only" and reward[cue]) and PlaySoundFile then
        PlaySoundFile(media .. cue .. ".mp3", F.db.audioChannel or "SFX")
    end
end

local synergyCues={pack="pack",tunnel="tunnel",whiteout="whiteout"}
local hitCues={"hit","hit2","hit3"}
function F.battleSound(event,index)
    local cue=synergyCues[event.payoff]
    if not cue then
        if event.payoff or event.combo then cue="combo"
        elseif event.move=="S" then cue="signature"
        elseif event.broken>0 then cue="break"
        elseif event.absorbed>0 then cue="shield"
        elseif event.hit>0 then cue=hitCues[index%#hitCues+1]
        elseif event.mark then cue="mark"
        elseif event.move=="B" or event.guard>0 then cue="guard"
        else cue="technique" end
    end
    F.sound(cue)
end

local function texture(parent, layer, file)
    local t = parent:CreateTexture(nil, layer)
    if file then t:SetTexture(media .. file) end
    return t
end
local function caption(parent, font)
    local s = parent:CreateFontString(nil, "OVERLAY")
    s:SetFontObject(font or fonts.body)
    s:SetJustifyH("CENTER")
    return s
end
-- Use texture tags so type names and their badges wrap and align together.
function F.typeBadges(id,card,size,withLabels)
    local badges={}
    for i,kind in ipairs(card.types or F.typesOf(id,card)) do
        local icon=("|T%sTypes\\%s.tga:%d:%d:0:0|t"):format(media,kind,size,size)
        badges[i]=withLabels and (icon.." "..kind) or icon
    end
    return table.concat(badges,withLabels and " / " or " ")
end
local edges = {{1,.70,.30},{.45,.90,.67},{.83,.65,1},{.54,.83,1}}
-- Atlas cells follow F.typeOrder. The first type supplies the corners and metal,
-- while each badge keeps its own color on a dual-type card.
local typeColors={
    Pack={.83,.63,.41}, Feral={.63,.79,.44}, Brute={.91,.58,.40}, Burrow={.81,.67,.46},
    Martial={.72,.78,.86}, Trickster={.76,.60,.91}, Tide={.47,.82,.90}, Shell={.54,.82,.74},
    Venom={.73,.84,.42}, Winged={.70,.76,.96}, Frost={.60,.86,1}, Ember={1,.51,.30},
    Stone={.73,.72,.65}, Storm={.73,.70,1}, Verdant={.49,.84,.63}, Arcane={.82,.61,1},
    Undead={.66,.83,.76}, Fel={.66,.88,.38},
}
local typeCells={}
for i,kind in ipairs(F.typeOrder) do typeCells[kind]=i-1 end
local cornerPoints={"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}
local shortZones={["Dun Morogh"]="Morogh",["Elwynn Forest"]="Elwynn",["Tirisfal Glades"]="Tirisfal",["Unknown habitat"]="Unknown"}

local function newCardIdentity(w,glass)
    local rail=CreateFrame("Frame",nil,glass,"BackdropTemplate")
    rail:SetAllPoints(w.art)
    rail:EnableMouse(false)
    rail:SetFrameLevel(glass:GetFrameLevel())
    rail:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    w.portraitRail=rail
    w.corners={}
    for i,point in ipairs(cornerPoints) do
        local corner=texture(glass,"ARTWORK","TypeCorners.tga")
        corner:SetPoint(point,w.art,point)
        w.corners[i]=corner
    end
    w.footerArt=texture(glass,"BACKGROUND")
    w.footerArt:SetPoint("TOPLEFT",w.art,"BOTTOMLEFT")
    w.namePlate=texture(glass,"BORDER","CardNameplate.tga")
    w.namePlate:SetPoint("TOP",w.art,"BOTTOM",0,-2)
    w.nameText=caption(glass,fonts.card)
    w.nameText:SetPoint("CENTER",w.namePlate)
    w.zone=caption(glass,fonts.small)
    w.zone:SetMaxLines(1)
    w.zoneBand=texture(glass,"BORDER")
    w.zoneBand:SetPoint("BOTTOM",0,4)
    w.roleText=caption(glass,fonts.small)
    w.roleText:SetMaxLines(1)
    w.typeBadges={}
    for i=1,2 do
        local badge=CreateFrame("Frame",nil,glass)
        badge:EnableMouse(false)
        badge.fill=texture(badge,"BACKGROUND","CardNameplate.tga")
        badge.fill:SetAllPoints()
        badge.icon=texture(badge,"ARTWORK")
        badge.label=caption(badge,fonts.strongSmall)
        badge.label:SetPoint("LEFT",badge.icon,"RIGHT",2,0)
        w.typeBadges[i]=badge
    end
end

local function bindBadges(w,types,width,large,mini,arena)
    local iconSize=large and 18 or mini and 11 or 12
    local badgeH=large and 22 or 15
    local sizes,total={},0
    for i=1,math.min(#types,#w.typeBadges) do
        sizes[i]=math.ceil(iconSize+12+#types[i]*(large and 6.3 or 5.5))
        total=total+sizes[i]+(i==1 and 0 or 4)
    end
    local named=not mini and not arena and total<=width-16
    if not named then total=#sizes*(iconSize+8)+math.max(0,#sizes-1)*4 end
    local x=arena and 8 or (width-6-total)/2
    for i,badge in ipairs(w.typeBadges) do
        local kind=sizes[i] and types[i]
        badge:SetShown(kind~=nil)
        if kind then
            local color=typeColors[kind] or typeColors.Martial
            local badgeW=named and sizes[i] or iconSize+8
            badge:ClearAllPoints()
            badge:SetPoint("TOPLEFT",w.art,"BOTTOMLEFT",x,large and -48 or mini and -19 or arena and -24 or -31)
            badge:SetSize(badgeW,badgeH)
            badge.fill:SetVertexColor(color[1],color[2],color[3],.96)
            badge.icon:ClearAllPoints()
            badge.icon:SetPoint("LEFT",badge,"LEFT",named and 5 or 4,0)
            badge.icon:SetSize(iconSize,iconSize)
            badge.icon:SetTexture(media.."Types\\"..kind..".tga")
            badge.label:SetShown(named)
            badge.label:SetText(kind)
            badge.label:SetTextColor(.44+color[1]*.56,.44+color[2]*.56,.44+color[3]*.56)
            x=x+badgeW+4
        end
    end
end

local function centerArt(w, dx, dy)
    w.model:SetPoint("CENTER",w.art,"CENTER",dx,dy)
    w.model:SetFacing(.36 + dx * .08 + dy * .01)
    w.foil:SetPoint("CENTER",w.art,"CENTER",dx*2,dy)
end
local function rest(w)
    w.dx,w.dy,w.drag=0,0,nil
    centerArt(w,0,0)
    w.back:Hide()
    w.newText:Hide()
    w.back:SetAlpha(1)
    w.flash:Hide()
    w:SetScript("OnUpdate",nil)
end
function F.newFace(parent)
    local w=CreateFrame("Button",nil,parent,"BackdropTemplate")
    w:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
    w:SetBackdropColor(.045,.092,.058,1)
    w.art=texture(w,"BORDER","Landscape.tga")
    w.icon=texture(w,"ARTWORK")
    w.icon:SetDrawLayer("ARTWORK",1)
    w.icon:SetPoint("CENTER",w.art)
    w.model=CreateFrame("PlayerModel",nil,w)
    w.model:EnableMouse(false)
    w.model:SetScript("OnModelLoaded",function()
        local file=w.model.GetModelFileID and w.model:GetModelFileID()
        if type(file)=="number" and file>0 then w.icon:Hide() end
    end)
    local glass=CreateFrame("Frame",nil,w)
    glass:SetAllPoints()
    glass:EnableMouse(false)
    glass:SetFrameLevel((w.model:GetFrameLevel() or 1)+1)
    local sealText=CreateFrame("Frame",nil,glass)
    sealText:SetAllPoints()
    sealText:EnableMouse(false)
    sealText:SetFrameLevel(glass:GetFrameLevel()+2)
    w.newText=caption(sealText,fonts.small)
    w.newText:SetPoint("TOP",0,-14)
    w.newText:SetText("New")
    w.newText:SetTextColor(1,.89,.67)
    w.newText:Hide()
    newCardIdentity(w,glass)
    w.rarityPlate=texture(glass,"ARTWORK","CardNameplate.tga")
    w.rarityText=caption(glass,fonts.strongSmall)
    w.rarityText:SetPoint("TOP",w.art,"TOP",0,-8)
    w.rarityText:SetSize(96,20)
    w.rarityPlate:SetPoint("CENTER",w.rarityText,"CENTER")
    w.rarityPlate:SetSize(104,22)
    w.rankText=caption(glass,fonts.small)
    w.rankText:SetPoint("TOPRIGHT",w,"TOPRIGHT",-12,-10)
    w.rankText:SetTextColor(1,.88,.64)
    w.foil=texture(glass,"BACKGROUND","Foil.tga")
    w.foil:SetBlendMode("ADD")
    w.health=texture(glass,"ARTWORK")
    w.health:SetDrawLayer("ARTWORK",1)
    w.healthGhost=texture(glass,"ARTWORK")
    w.healthGhost:SetDrawLayer("ARTWORK",2)
    w.healthCaption=caption(glass,fonts.bold)
    w.targetPlate=texture(glass,"ARTWORK")
    w.targetPlate:SetDrawLayer("ARTWORK",4)
    w.targetPlate:SetPoint("BOTTOM",w.art,"BOTTOM",0,6)
    w.targetPlate:SetSize(130,22)
    w.targetPlate:SetColorTexture(.035,.075,.11,.96)
    w.targetCue=caption(glass,fonts.bold)
    w.targetCue:SetPoint("CENTER",w.targetPlate,"CENTER")
    w.targetCue:SetTextColor(.79,.92,1)
    w.back=texture(sealText,"ARTWORK","WolfSeal.tga")
    w.back:SetAllPoints()
    w.flash=texture(sealText,"OVERLAY","Foil.tga")
    w.flash:SetDrawLayer("OVERLAY",3)
    w.flash:SetBlendMode("ADD")
    w:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    w:SetScript("OnHide",rest)
    return w
end
local rarityTints={
    Common={.74,.83,.80}, Elite={.42,.90,.62},
    Rare={.37,.69,1}, ["Rare elite"]={.73,.49,1}, Legendary={1,.64,.24},
}

local function bindCardIdentity(w,c,types,width,footer,zone,habitat,o,rank)
    local primary=typeColors[types[1]] or habitat.edge
    local metal={.39+primary[1]*.61,.36+primary[2]*.64,.33+primary[3]*.67}
    local large=o.full and not o.arenaFace
    local cornerSize=large and 55 or o.arenaFace and 25 or o.mini and 16 or math.min(32,width*.23)
    local cell=typeCells[types[1]] or typeCells.Martial
    local left,top=(cell%8)*64,math.floor(cell/8)*64
    local u1,u2,v1,v2=(left+.5)/512,(left+63.5)/512,(top+.5)/256,(top+63.5)/256
    for i,corner in ipairs(w.corners) do
        local right,bottom=i%2==0,i>2
        corner:SetTexCoord(right and u2 or u1,right and u1 or u2,bottom and v2 or v1,bottom and v1 or v2)
        corner:SetSize(cornerSize,cornerSize)
        corner:SetVertexColor(metal[1],metal[2],metal[3],bottom and .74 or .98)
        corner:SetShown(c~=nil and F.db.cardOrnaments~=false)
    end
    w.portraitRail:SetBackdropBorderColor(primary[1],primary[2],primary[3],c and .64 or .28)
    w.footerArt:SetSize(width-6,footer)
    w.footerArt:SetColorTexture(.026+primary[1]*.040,.026+primary[2]*.040,.028+primary[3]*.042,1)
    local nameHeight=large and 42 or o.mini and 16 or o.arenaFace and 21 or 28
    local nameWidth=width-(large and 24 or o.mini and 8 or 12)
    w.namePlate:SetSize(nameWidth,nameHeight)
    w.namePlate:SetVertexColor(metal[1],metal[2],metal[3],1)
    w.nameText:SetFontObject(large and fonts.cardTitle or o.mini and fonts.strongSmall or o.arenaFace and fonts.bold or fonts.card)
    w.nameText:SetSize(nameWidth-(large and 32 or o.mini and 6 or 10),nameHeight)
    w.nameText:SetMaxLines((large or not (o.mini or o.arenaFace)) and 2 or 1)
    w.nameText:SetText(c and c.name or "Empty slot")
    w.nameText:SetTextColor(1,.96,.87)
    bindBadges(w,types,width,large,o.mini,o.arenaFace)

    local showRarity=c~=nil and large==true
    local rarity=c and (c.rarity or "Common")
    local accent=rarityTints[rarity] or rarityTints.Common
    w.rarityPlate:SetShown(showRarity)
    w.rarityPlate:SetVertexColor(accent[1],accent[2],accent[3],1)
    w.rarityText:SetShown(showRarity)
    w.rarityText:SetText(rarity or "")
    w.rarityText:SetTextColor(accent[1],accent[2],accent[3])
    w.rankText:SetText(rank>0 and ("Foil "..rank) or "")
    w.flash:SetVertexColor(unpack(primary))

    w.zone:ClearAllPoints()
    w.zone:SetPoint("BOTTOM",0,large and 13 or 5)
    w.zone:SetSize(width-16,14)
    w.zone:SetTextColor(.76+primary[1]*.22,.76+primary[2]*.22,.76+primary[3]*.22)
    local location=width<112 and shortZones[zone] or zone
    if c and large then location=("|T%s%s.tga:13:13:0:-1|t  %s"):format(media,habitat.crest,zone) end
    w.zone:SetText(c and not (o.unit or o.mini or o.state) and location or "")
    w.zoneBand:SetShown(o.unit~=nil)
    w.roleText:ClearAllPoints()
    if o.unit then
        w.roleText:SetPoint("TOPRIGHT",w.art,"BOTTOMRIGHT",-8,-24)
        w.roleText:SetSize(width-65,15)
        w.roleText:SetJustifyH("RIGHT")
    else
        w.roleText:SetPoint("BOTTOM",0,large and 13 or 5)
        w.roleText:SetSize(width-16,14)
        w.roleText:SetJustifyH("CENTER")
    end
    w.roleText:SetTextColor(.84,.87,.90)
    w.roleText:SetText(not (o.mini or o.unit) and (o.state or (not c and "Choose creature")) or "")
end
-- The card owns its art layers. Only the art moves; labels stay anchored.
function F.bindFace(w,id,c,width,height,options)
    local o=options or {}
    rest(w)
    w:SetSize(width,height)
    w:EnableMouseWheel(false)
    w:SetScript("OnMouseWheel",nil)
    local zone=F.speciesOf(id)[1]
    local habitat=F.habitatStyle(zone)
    local painting=(o.arenaFace or o.ornate or o.showcase) and F.arenaPaintings[habitat.art]
    local cardArt=painting or habitat.art..((o.ornate or o.arenaFace) and "" or "Depth")
    w.art:SetTexture(media..(c and cardArt or "WolfSeal")..".tga")
    local tint=c and (painting and .94 or o.arenaFace and .72 or o.ornate and .87 or 1) or .60
    if c and F.db.cardScenery=="Off" then
        w.art:SetColorTexture(.065,.085,.11,1)
    else
        if c and F.db.cardScenery=="Dim" then tint=tint*.54 end
        w.art:SetVertexColor(tint,tint,tint)
    end
    local rank=c and (c.prestige or c.rank or 0) or 0
    local types=c and (c.types or F.typesOf(id,c)) or {}
    local edge=rank>0 and edges[(rank-1)%4+1] or typeColors[types[1]] or habitat.edge
    if o.invalid then edge={.92,.45,.36}
    elseif o.selected then edge={1,.75,.29}
    elseif o.targetable then edge={.89,.53,.42}
    elseif o.unit then edge=o.rival and {.46,.25,.24} or {.26,.46,.43} end
    w:SetBackdropBorderColor(edge[1],edge[2],edge[3],1)
    local footer=o.arenaFace and 57 or o.full and 96 or (o.mini and 36 or 64)
    local artH=height-footer-6
    w.art:SetPoint("TOPLEFT",3,-3)
    w.art:SetSize(width-6,artH)
    if c and painting then
        local aspect=(width-6)/(2*artH)
        local spanX=.96*math.min(1,aspect)
        local spanY=.96*math.min(1,1/aspect)
        w.art:SetTexCoord(.5-spanX/2,.5+spanX/2,.42-spanY*.42,.42+spanY*.58)
    elseif c then
        F.coverArt(w.art,width-6,artH)
    else
        w.art:SetTexCoord(0,1,0,1)
    end
    bindCardIdentity(w,c,types,width,footer,zone,habitat,o,rank)
    w.model:SetSize(width-18,math.max(1,artH-4))
    w.icon:SetSize(math.min(artH*.68,width*.68),math.min(artH*.68,width*.68))
    w.foil:SetSize(width*.70,math.max(1,artH-8))
    w.foil:SetAlpha(rank>0 and F.db.cardFoil~=false and .42 or 0)
    local unit=o.unit
    w.health:SetShown(unit~=nil)
    w.healthGhost:Hide()
    w.targetPlate:Hide()
    w.targetCue:Hide()
    w.healthCaption:SetShown(unit~=nil)
    if unit then
        w.zone:SetText("")
        w.zoneBand:SetColorTexture(.11,.16,.17,1)
        w.zoneBand:SetSize(width-16,16)
        w.health:SetPoint("BOTTOMLEFT",8,4)
        w.health:SetSize(math.max(1,(width-16)*unit.hp/unit.maxHP),16)
        if o.rival then w.health:SetColorTexture(.65,.24,.23,1) else w.health:SetColorTexture(.20,.51,.35,1) end
        w.health:SetShown(unit.hp>0)
        w.healthCaption:SetPoint("BOTTOM",0,4)
        w.healthCaption:SetSize(width-16,16)
        w.healthCaption:SetText(unit.hp>0 and ("%d / %d HP"):format(unit.hp,unit.maxHP) or "Knocked out")
        local traits={}
        if o.arenaFace and c then traits[1]="Speed "..F.cardSpeed(c) end
        if unit.shield>0 then traits[#traits+1]=colors.shield.."Shield "..unit.shield.."|r" end
        if unit.mark then traits[#traits+1]=colors.damage.."Marked|r" end
        w.roleText:SetText(unit.hp>0 and table.concat(traits,"  /  ") or "")
    end
    w:SetAlpha(o.muted and .61 or 1)
    w:SetEnabled(o.click~=nil)
    w:SetScript("OnClick",o.click)
    w.icon:SetTexture(c and ((F.overrides[id] or {}).icon or F.icons[c.role]))
    w.icon:SetShown(c~=nil and not o.sealed)
    if c and not o.sealed then
        w.model:Show()
        if w.model.SetPaused then w.model:SetPaused(F.db.staticCards==true or (F.db.pauseModels==true and not o.arenaFace)) end
        if w.boundID~=id then
            w.model:ClearModel()
            w.model.arenaBeat=nil
            w.model:SetCreature(id)
            w.boundID=id
        end
        if w.model.SetPortraitZoom then w.model:SetPortraitZoom(o.arenaFace and .06 or .18) end
        if o.arenaFace then
            w.model:SetFacing(o.rival and -.72 or .72)
        elseif w.model.arenaBeat then
            w.model:SetAnimation(0)
            w.model.arenaBeat=nil
        end
        local file=w.model.GetModelFileID and w.model:GetModelFileID()
        if type(file)=="number" and file>0 then w.icon:Hide() end
    else w.model:Hide() end
    if o.sealed then
        w.back:Show()
        w.model:Hide()
        w.newText:Show()
    end
    if o.reveal and F.db.staticCards then F.sound("reveal") end
    if not (o.inspect or o.place or o.reveal) or F.db.staticCards then return end
    local age,landed=0,false
    if o.reveal then w.model:Hide() w.back:Show() w.back:SetAlpha(1) end
    w:SetScript("OnUpdate",function(self,dt)
        age=age+dt
        if o.reveal and age<.28 then
            w.back:SetAlpha(1-math.max(0,(age-.15)/.13))
            return
        end
        if o.reveal and not landed then F.sound("reveal") landed=true end
        if o.place then centerArt(w,-7*math.max(0,1-age/.18),0) end
        w.back:Hide()
        if c and not w.model:IsShown() then w.model:Show() end
        if (o.place or o.reveal) and age<.75 then
            w.flash:Show()
            w.flash:SetSize(width*.40,height-6)
            w.flash:SetPoint("TOPLEFT",3+width*.53*math.min(1,age/.75),-3)
            w.flash:SetAlpha(.85*(1-age/.75))
        else w.flash:Hide() end
        if not o.inspect then
            if age>=.75 then rest(w) end
            return
        end
        if not GetCursorPosition then return end
        local x,y=GetCursorPosition()
        local scale=self:GetEffectiveScale()
        x,y=x/scale,y/scale
        local over=self:IsMouseOver()
        local down=IsMouseButtonDown("LeftButton")
        if not down then self.drag=nil elseif over and not self.drag then self.drag=x end
        local cx,cy=self:GetCenter()
        local tx=self.drag and (x-self.drag)/8 or (over and (x-cx)/width*12 or 0)
        local ty=over and (y-cy)/height*8 or 0
        local k=math.min(1,dt*12)
        self.dx=self.dx+(math.max(-6,math.min(6,tx))-self.dx)*k
        self.dy=self.dy+(math.max(-4,math.min(4,ty))-self.dy)*k
        centerArt(self,self.dx,self.dy)
    end)
end

local queue,toast={},nil
local toastTheme
local function themeToast()
    local palette=F.theme()
    if toastTheme==palette then return end
    toastTheme=palette
    toast:SetBackdrop({bgFile=F.themeTexture("JournalShell",palette),edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    toast:SetBackdropColor(unpack(palette.textureTint))
    toast:SetBackdropBorderColor(unpack(palette.primaryEdge))
    toast.rule:SetColorTexture(unpack(palette.accent))
end

local function toastEnabled(perk)
    if perk then return F.db.perkToasts~=false end
    return F.db.discoveryToasts~=false
end
local function showNext()
    local entry=table.remove(queue,1)
    while entry and not toastEnabled(entry.perk) do entry=table.remove(queue,1) end
    if not entry then if toast then toast:Hide() toast:SetScript("OnUpdate",nil) end return end
    if not toast then
        toast=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
        toast:SetFrameStrata("HIGH")
        toast:SetPoint("TOP",UIParent,"TOP",0,-64)
        toast:SetSize(326,112)
        toast.rule=texture(toast,"ARTWORK")
        toast.rule:SetPoint("TOPLEFT",90,-21)
        toast.rule:SetSize(26,1)
        toast.face=F.newFace(toast)
        toast.face:SetPoint("LEFT",11,0)
        toast:EnableMouse(false)
        toast.face:EnableMouse(false)
        toast.msg=caption(toast,fonts.bold)
        toast.msg:SetPoint("TOPLEFT",90,-33)
        toast.msg:SetWidth(218)
        toast.msg:SetJustifyH("LEFT")
        toast.msg:SetJustifyV("TOP")
    end
    themeToast()
    local id=entry.id
    local c=F.db.cards[id]
    F.bindFace(toast.face,id,c,66,92,{mini=true,showcase=true})
    toast.face:EnableMouse(false)
    toast.msg:SetText(colors.gold..(entry.perk and "Perk unlocked" or "Field discovery").."|r\n"..c.name
        .."\n"..(entry.perk and colors.success..entry.perk or colors.muted..F.speciesOf(id)[1].."  /  Open /fd").."|r")
    toast.group=not entry.perk and 1 or nil
    toast.perk=entry.perk
    toast:Show()
    F.sound(entry.perk and "perk" or "discovery")
    local elapsed=0
    toast:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        toast.face:SetScale(F.db.staticCards and 1 or .86+.14*math.min(1,elapsed/.15))
        if elapsed>=2.8 then showNext() end
    end)
end
function F.refreshDiscoverySettings()
    if toast and toast:IsShown() then
        if toastEnabled(toast.perk) then themeToast() else showNext() end
    end
end
function F.discovered(id,perk)
    if not toastEnabled(perk) then F.sound(perk and "perk" or "discovery") return end
    if not perk and toast and toast:IsShown() and toast.group then
        toast.group=toast.group+1
        F.bindFace(toast.face,id,F.db.cards[id],66,92,{mini=true,showcase=true})
        toast.face:EnableMouse(false)
        toast.msg:SetText(colors.gold..toast.group.." discoveries|r\n"..F.db.cards[id].name
            .."\n"..colors.muted.."Open /fd to reveal each card.|r")
        return
    end
    queue[#queue+1]={id=id,perk=perk}
    if not toast or not toast:IsShown() then showNext() end
end
