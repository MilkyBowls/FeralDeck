local _, F = ...
local panel,tab,selected,role,tier,ready=nil,"Collection",nil,0,-1,false
local query,peer,draftName="","",""
local draft,slot,confirm,history={},1,nil,0
local draftTactics,queued,fast,logOpen={},nil,false,false
local choosingDeck,deckPage=false,1
local deckTools=false
local settingsOpen=false
local navigation,closeButton,textEntry
local pools,used={},{}
local librarySort,journalSort,atlasSort,statsSort=1,1,1,1
local atlasFilter,statsFilter,deckFilter,deckSort=1,1,1,1
local areaCardSort,areaCardRole=1,0
local deckQuery,deleteDeck="",nil
local tacticSort,tacticFilter,logSort,logFilter=1,1,1,1
local colors,fonts=F.uiColors,F.fonts
local gold=colors.gold
local function rarity(c)
    local value=c.rarity or "Common"
    return (F.rarityColors[value] or "")..value.."|r"
end
local function item(kind)
    used[kind]=(used[kind] or 0)+1
    pools[kind]=pools[kind] or {}
    local w=pools[kind][used[kind]]
    if not w then
        if kind=="wheel" then
            w=CreateFrame("Frame",nil,panel)
            w:SetScript("OnHide",function(self)
                if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
            end)
        elseif kind=="face" then w=F.newFace(panel)
        elseif kind=="text" then w=panel:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        elseif kind=="icon" then w=panel:CreateTexture(nil,"ARTWORK")
        elseif kind=="model" then w=CreateFrame("PlayerModel",nil,panel)
        elseif kind=="edit" then
            w=CreateFrame("EditBox",nil,panel,"BackdropTemplate")
            w:SetBackdrop({bgFile=F.media.."GlassButton.tga",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
            w:SetBackdropColor(.063,.095,.141,1)
            w:SetBackdropBorderColor(.37,.49,.64,.55)
            w:SetScript("OnEditFocusGained",function(self)
                self:SetBackdropColor(.093,.14,.206,1)
                self:SetBackdropBorderColor(.63,.77,.94,.94)
            end)
            w:SetScript("OnEditFocusLost",function(self)
                self:SetBackdropColor(.063,.095,.141,1)
                self:SetBackdropBorderColor(.37,.49,.64,.55)
            end)
            w:SetTextInsets(9,9,0,0)
            w:SetAutoFocus(false)
            w:SetFontObject(fonts.body)
            w:SetMaxLetters(80)
            w:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
            w:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
            w:SetScript("OnHide",function(self) self:ClearFocus() end)
        else
            w=CreateFrame("Button",nil,panel,"BackdropTemplate")
            w:SetBackdrop({bgFile=F.media.."GlassButton.tga",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
            w:SetNormalFontObject(fonts.body)
            w:SetHighlightFontObject(fonts.hover)
            w:SetDisabledFontObject(fonts.disabled)
            w:SetHighlightTexture(F.media.."GlassButton.tga")
            local highlight=w:GetHighlightTexture()
            if highlight then highlight:SetVertexColor(.78,.88,1,.13) end
            w:SetPushedTexture(F.media.."GlassButton.tga")
            local pushed=w:GetPushedTexture()
            if pushed then pushed:SetVertexColor(.72,.81,.94,.16) end
        end
        pools[kind][used[kind]]=w
    end
    if kind=="wheel" then
        w:SetFrameLevel(panel:GetFrameLevel()+1)
        w:SetScript("OnMouseWheel",nil)
    end
    if kind=="icon" then
        w:SetAlpha(1)
        w:SetVertexColor(1,1,1,1)
        w:SetTexCoord(0,1,0,1)
    end
    w:ClearAllPoints()
    w:Show()
    return w
end
local function place(w,x,y,width,height)
    w:SetPoint("TOPLEFT",panel,"TOPLEFT",x,-y)
    w:SetSize(width,height)
end
local function label(x,y,width,height,s)
    local w=item("text")
    place(w,x,y,width,height)
    w:SetAlpha(1)
    w:SetFontObject(fonts.body)
    w:SetJustifyH("LEFT")
    w:SetJustifyV("TOP")
    w:SetMaxLines(0)
    w:SetText(s)
    return w
end
local function hoverHelp(x,y,width,height,title,description)
    local target=item("wheel")
    place(target,x,y,width,height)
    target:EnableMouse(true)
    target:EnableMouseWheel(false)
    target:SetScript("OnEnter",function(self)
        F.showTooltip(self,"ANCHOR_TOP",title,description)
    end)
    target:SetScript("OnLeave",function() GameTooltip:Hide() end)
    navigation:add(target,x,y,width,height,"help")
end
local function surface(x,y,width,height,r,g,b)
    local w=item("icon")
    place(w,x,y,width,height)
    w:SetDrawLayer("BACKGROUND",1)
    w:SetColorTexture(r,g,b,1)
    return w
end
local function section(x,y,width,height,title)
    local glass=item("icon")
    place(glass,x,y,width,height)
    glass:SetDrawLayer("BACKGROUND",1)
    glass:SetTexture(F.media..(width/height>=3 and "JournalStrip.tga" or "JournalPane.tga"))
    if title then
        label(x+14,y+11,width-28,22,gold..title.."|r"):SetFontObject(fonts.heading)
    end
end
local function creature(x,y,width,height,id,facing,zoom)
    local w=item("model")
    place(w,x,y,width,height)
    w:EnableMouse(false)
    w:SetAlpha(1)
    w:SetScript("OnModelLoaded",nil)
    if w.cardID~=id then
        w:ClearModel()
        w.beat=nil
        w:SetCreature(id)
        w.cardID=id
    end
    if w.SetPaused then w:SetPaused(F.db.staticCards==true) end
    w:SetFacing(facing)
    if w.SetPortraitZoom then w:SetPortraitZoom(zoom or 0) end
    return w
end
local function button(x,y,width,s,fn,tip,enabled,kind)
    local w=item(kind or "button")
    w:SetNormalFontObject(fonts.body)
    w:SetHighlightFontObject(fonts.hover)
    place(w,x,y,width,26)
    w:SetText(s)
    local text=w:GetFontString()
    if text then
        text:SetJustifyH("CENTER")
        text:SetWidth(width-14)
        text:SetMaxLines(1)
    end
    w:EnableMouseWheel(false)
    w:SetScript("OnMouseWheel",nil)
    w:SetBackdropColor(.123,.176,.243,enabled==false and .42 or .91)
    w:SetBackdropBorderColor(.48,.61,.76,enabled==false and .13 or .27)
    w:SetEnabled(enabled~=false)
    w:SetScript("OnClick",function() fn() F.refresh() end)
    w:SetScript("OnEnter",function(self)
        if tip then F.showTooltip(self,"ANCHOR_RIGHT",s,tip) end
    end)
    w:SetScript("OnLeave",function() GameTooltip:Hide() end)
    w:SetScript("OnHide",function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    if enabled~=false then navigation:add(w,x,y,width,26,"button") end
    return w
end
local function tone(w,kind)
    if w:IsEnabled()==false then return w end
    if kind=="primary" then
        w:SetBackdropColor(.43,.31,.17,1)
        w:SetBackdropBorderColor(.87,.71,.46,.79)
        w:SetNormalFontObject(fonts.bold)
    elseif kind=="danger" then
        w:SetBackdropColor(.28,.115,.14,1)
        w:SetBackdropBorderColor(.72,.35,.39,.75)
    else
        w:SetBackdropColor(.18,.26,.36,1)
        w:SetBackdropBorderColor(.62,.73,.85,.64)
        w:SetNormalFontObject(fonts.bold)
    end
    return w
end
local function meter(x,y,width,ratio)
    surface(x,y,width,5,.099,.145,.202)
    if ratio>0 then
        local filled=width*math.min(1,ratio)
        surface(x,y,filled,5,.77,.55,.28):SetDrawLayer("ARTWORK")
        surface(x,y,filled,1,.94,.78,.49):SetDrawLayer("ARTWORK",1)
    end
end
local moveColors={
    A={.48,.15,.17,"|cffffa5aa"},
    B={.41,.30,.08,"|cffffdf85"},
    S={.33,.19,.49,"|cffdfbbff"},
    X={.14,.38,.36,"|cff99e6db"},
    tactic={.12,.29,.51,"|cffaad9ff"},
}
local moveTypes={A="Attack",B="Guard",X="Technique",S="Signature"}
local function cycle(x,y,width,options,index,change,tip)
    return button(x,y,width,options[index],function() change(index%#options+1) end,tip)
end
local cardSorts={"Name A-Z","Most mastery","Most copies"}
local function cardLess(a,b,sort)
    local x,y=F.db.cards[a],F.db.cards[b]
    local first,second
    if sort==2 then first,second=x.mastery or 0,y.mastery or 0 end
    if sort==3 then first,second=x.lifetime,y.lifetime end
    if first~=second then return first>second end
    return x.name==y.name and a<b or x.name<y.name
end
local function areaLess(zones,a,b,sort)
    local x,y=zones[a],zones[b]
    local first,second
    if sort==2 then first,second=#x.owned/math.max(1,x.total),#y.owned/math.max(1,y.total) end
    if sort==3 then first,second=x.total-#x.owned,y.total-#y.owned end
    if first~=second then return first>second end
    return a<b
end
local function colorAction(widget,kind,enabled,selected)
    local c=moveColors[kind]
    widget:SetNormalFontObject(fonts.bold)
    widget:SetHighlightFontObject(fonts.bold)
    local strength=selected and 1.35 or 1
    widget:SetBackdropBorderColor(c[1]+.35,c[2]+.35,c[3]+.35,enabled==false and .36 or 1)
    widget:SetBackdropColor(c[1]*strength,c[2]*strength,c[3]*strength,enabled==false and .45 or 1)
    return widget
end
local function edit(x,y,width,s,cb,title)
    local w=item("edit")
    place(w,x,y,width,25)
    w:SetScript("OnTextChanged",nil)
    if w:GetText()~=s then w:SetText(s) end
    w:SetScript("OnTextChanged",function(self,user) if user then cb(self:GetText()) end end)
    navigation:add(w,x,y,width,25,"edit",function()
        w:ClearFocus()
        textEntry={value=w:GetText(),apply=cb,title=title or "Enter text"}
        F.refresh()
    end)
end
local picker
local function loadDraft(name)
    slot=1
    draftName=name or F.db.active or "Field"
    picker=nil
    draft={unpack(F.db.decks[draftName] or {})}
    draftTactics=F.tacticDeck(draftName)
end
local pending,placed,reveal
local function face(x,y,width,height,id,c,o)
    local w=item("face")
    place(w,x,y,width,height)
    w:SetScript("OnEnter",nil)
    w:SetScript("OnLeave",nil)
    w.fdPadPreview,w.fdPadEndPreview=nil,nil
    F.bindFace(w,id,c,width,height,o)
    if o.click then navigation:add(w,x,y,width,height,"card") end
    return w
end
local function paper(x,y,width,height,file,layer,shade)
    local w=item("icon")
    place(w,x,y,width,height)
    w:SetDrawLayer("BACKGROUND",layer or 0)
    w:SetTexture(F.media..file..".tga")
    F.coverArt(w,width,height)
    if shade then w:SetVertexColor(shade,shade,shade) end
    return w
end
local function banner(x,y,width,height,art)
    if art then
        local painting=F.arenaPaintings[art]
        local image=paper(x,y,width,height,painting or art,0,.87)
        if painting then
            local span=math.min(.95,height*2/width)
            image:SetTexCoord(.02,.98,.25-span*.23,.25+span*.77)
        end
        local shade=paper(x,y,width,height,"HeroShade",1)
        shade:SetTexCoord(0,1,0,1)
    else
        section(x,y,width,height)
    end
    surface(x,y+height-1,width,1,.49,.40,.26):SetDrawLayer("BACKGROUND",2)
end
local function equip(pos,id)
    if draft[pos]==id then slot,pending=pos,nil return end
    for i=1,3 do
        if draft[i]==id then draft[i]=draft[pos] break end
    end
    draft[pos]=id
    slot,placed,pending=pos,pos,nil
    F.sound("place")
end
local libraryQuery,libraryRole,libraryPage="",0,1
local function cardMatches(id,c,query)
    if c.name:lower():find(query,1,true) or tostring(id):find(query,1,true) then return true end
    for _,kind in ipairs(F.typesOf(id,c)) do
        if kind:lower():find(query,1,true) then return true end
    end
    return false
end
local function fieldCardInfo(id,card)
    local species=F.speciesOf(id)
    local moveCard={id=id,role=card.role}
    return gold.."Type|r  "..F.typeBadges(id,card,14,true)
        .."\n"..gold.."Habitat|r  "..species[1]
        .."\n"..gold.."Solo signature|r  "..moveColors.S[4]..F.moveName(moveCard,"S",true,true).."|r"
end

local function library()
    local search=libraryQuery:lower()
    label(646,112,150,24,"Owned library"):SetFontObject(fonts.heading)
    cycle(810,106,121,cardSorts,librarySort,function(i) librarySort,libraryPage=i,1 end,"Sort the library by name, mastery, or lifetime copies.")
    label(646,143,200,16,"Search name, type or NPC ID"):SetFontObject(fonts.muted)
    edit(646,161,177,libraryQuery,function(text) libraryQuery,libraryPage=text,1 F.refresh() end,"Search owned cards")
    button(831,161,100,F.roles[libraryRole] or "All roles",function() libraryRole=(libraryRole+1)%4 libraryPage=1 end,"Cycle combat roles, which determine speed and HP. Search by type for synergy pairings.")
    button(646,196,135,tier<0 and "All tiers" or ("Tier "..tier),function() tier=(tier+2)%(#F.balance.mastery+2)-1 libraryPage=1 end,"Filter by solo mastery tier.")
    button(792,196,139,ready and "Prestige ready" or "Any prestige",function() ready=not ready libraryPage=1 end,"Show cards with 100 copy progress available for prestige.")
    local ids={}
    for id,c in pairs(F.db.cards) do
        if F.eligibleCreature(id) and F.playable(c) and (libraryRole==0 or c.role==F.roles[libraryRole]) and (tier<0 or F.tier(c)==tier)
            and (not ready or c.progress>=100) and cardMatches(id,c,search) then
            ids[#ids+1]=id
        end
    end
    table.sort(ids,function(a,b) return cardLess(a,b,librarySort) end)
    local pages=math.max(1,math.ceil(#ids/6))
    libraryPage=math.min(libraryPage,pages)
    for i=(libraryPage-1)*6+1,math.min(libraryPage*6,#ids) do
        local id,k=ids[i],(i-1)%6
        local occupied
        for pos=1,3 do if draft[pos]==id then occupied=pos end end
        local card=F.db.cards[id]
        local tile=face(646+k%3*97,233+math.floor(k/3)*133,90,124,id,card,{
            mini=true,showcase=true,selected=occupied==slot,
            click=function()
                pending=nil
                if occupied then slot=occupied else
                    equip(slot,id)
                    for j=1,3 do if not draft[j] then slot=j break end end
                end
                F.refresh()
            end})
        tile:SetScript("OnEnter",function(self)
            local hint=occupied and ("Select slot "..occupied..".") or ("Add to slot "..slot..".")
            F.showTooltip(self,"ANCHOR_RIGHT",card.name,fieldCardInfo(id,card).."\n\n"..colors.muted..hint.."|r")
        end)
        tile:SetScript("OnLeave",function() GameTooltip:Hide() end)
        if occupied then
            label(646+k%3*97,239+math.floor(k/3)*133,89,16,gold.."Slot "..occupied.."|r"):SetJustifyH("CENTER")
        end
    end
    if #ids==0 then label(644,253,277,70,"No playable cards match. Discover creatures in the field or change your filters.") end
    button(646,502,85,"Previous",function() libraryPage=libraryPage-1 end,nil,libraryPage>1)
    label(738,509,91,20,libraryPage.." / "..pages):SetJustifyH("CENTER")
    button(846,502,85,"Next",function() libraryPage=libraryPage+1 end,nil,libraryPage<pages)
end
local function ink(x,y,w,h,text)
    return label(x,y,w,h,"|cffe5dfcc"..text.."|r")
end
local pendingCardScroll
local inspectorView="Overview"
local notesPage,notesMode=1,1
local perksPage,synergiesPage,showCombatStats=1,1,false
local function inspect(id)
    local c=F.db.cards[id]
    if not c or c.lifetime==0 or not F.eligibleCreature(id) then return end
    selected,confirm=id,nil
    perksPage,synergiesPage,showCombatStats=1,1,false
    inspectorView="Overview"
    reveal=c.unseen and id or nil
    c.unseen=nil
end
local habitatFilter,newOnly=0,false
local habitatOrder={0}
local function updateHabitatFilter(owned)
    local seen={}
    for _,id in ipairs(owned) do seen[F.speciesOf(id)[1]]=true end
    local zones={}
    for zone in pairs(seen) do zones[#zones+1]=zone end
    table.sort(zones)
    habitatOrder={0}
    for _,zone in ipairs(zones) do habitatOrder[#habitatOrder+1]=zone end
    if habitatFilter~=0 and not seen[habitatFilter] then habitatFilter=0 end
end
local journalRow,unreadOrder=0,{}
local function resetGrid()
    journalRow,unreadOrder=0,{}
end
local showCollectionFilters,collectionRarity,favoritesOnly=false,1,false
local collectionRarities={"All rarities","Common","Elite","Rare","Rare elite","Legendary"}
local function resetCollectionFilters()
    query,role,habitatFilter,newOnly="",0,0,false
    collectionRarity,favoritesOnly=1,false
    resetGrid()
end
local journalView,atlasZone,atlasPage,atlasCardPage="cards",nil,1,1
local function counter(x,y,w,title,value)
    section(x,y,w,84)
    label(x+14,y+12,w-28,20,title):SetFontObject(fonts.bold)
    label(x+14,y+33,w-28,42,tostring(value)):SetFontObject(fonts.metric)
end
local atlasQuery=""
local function atlas(stats)
    local names={}
    local searchTerm=atlasQuery:lower()
    for name,area in pairs(stats.zones) do
        if name:lower():find(searchTerm,1,true) and (atlasFilter==1 or (atlasFilter==2 and area.total>#area.owned)
            or (atlasFilter==3 and #area.owned>0)) then names[#names+1]=name end
    end
    table.sort(names,function(a,b) return areaLess(stats.zones,a,b,atlasSort) end)
    local pages=math.max(1,math.ceil(#names/10))
    atlasPage=math.min(atlasPage,pages)
    if atlasZone then
        local found=false
        for i,zone in ipairs(names) do
            if zone==atlasZone then
                atlasPage=math.ceil(i/10)
                found=true
                break
            end
        end
        if not found then atlasZone,atlasCardPage=nil,1 end
    end
    section(22,213,280,443)
    label(36,224,154,17,"Find an area"):SetFontObject(fonts.muted)
    edit(36,244,164,atlasQuery,function(value)
        atlasQuery,atlasPage,atlasZone,atlasCardPage=value,1,nil,1
        F.refresh()
    end,"Find an area")
    button(208,244,80,"Clear",function()
        atlasQuery,atlasPage,atlasZone,atlasCardPage="",1,nil,1
    end,"Clear the area search.",atlasQuery~="")
    local currentZone=F.read(GetRealZoneText)
    local canFind=currentZone and stats.zones[currentZone]~=nil
    button(786,171,150,"Current area",function()
        atlasZone,atlasFilter,atlasCardPage,atlasQuery=currentZone,1,1,""
    end,canFind and "Open your current area in the catalog." or "Your current area is not indexed yet.",canFind)
    cycle(36,278,120,{"All areas","Missing cards","Started areas"},atlasFilter,function(i)
        atlasFilter,atlasPage,atlasZone,atlasCardPage=i,1,nil,1
    end,"Show all areas, areas with missing cards, or areas where you own a card.")
    cycle(162,278,126,{"Name A-Z","Completion","Most missing"},atlasSort,function(i)
        atlasSort,atlasPage,atlasZone,atlasCardPage=i,1,nil,1
    end,"Sort the area list by name, completion percentage, or number of missing cards.")
    if #names==0 then label(35,326,253,36,"No areas match.") end
    local name=atlasZone or names[(atlasPage-1)*10+1]
    for i=(atlasPage-1)*10+1,math.min(atlasPage*10,#names) do
        local zone=names[i]
        local area=stats.zones[zone]
        local w=button(35,310+(i-1)%10*29,253,zone,function()
            atlasZone,atlasCardPage=zone,1
        end,("%d collected / %d uncollected"):format(#area.owned,area.total-#area.owned))
        if zone==name then tone(w,"active") end
    end
    button(35,617,89,"Previous",function() atlasPage=atlasPage-1 atlasZone=nil atlasCardPage=1 end,nil,atlasPage>1)
    button(199,617,89,"Next",function() atlasPage=atlasPage+1 atlasZone=nil atlasCardPage=1 end,nil,atlasPage<pages)
    label(139,624,50,17,atlasPage.." / "..pages):SetJustifyH("CENTER")
    local area=name and stats.zones[name]
    if not area then return end
    local profile=F.areaProfiles[name]
    local habitat=F.habitatStyle(name)
    banner(320,213,616,157,habitat.art)
    paper(338,230,34,34,habitat.crest,2)
    label(384,226,528,38,name):SetFontObject(fonts.title)
    label(385,260,505,20,profile and profile[1] or "Area catalog"):SetFontObject(fonts.muted)
    local description=profile and profile[2] or "Browse the creatures recorded for this area."
    label(339,289,395,47,description)
    if profile then label(339,339,525,25,gold.."Landmarks|r  "..profile[3]):SetFontObject(fonts.small) end
    local ratio=area.total>0 and #area.owned/area.total or 0
    section(320,378,616,49)
    label(337,388,580,18,("%d collected   /   %d catalogued   /   %d remaining"):format(#area.owned,area.total,area.total-#area.owned))
    meter(337,414,580,ratio)
    local owned={}
    for _,id in ipairs(area.owned) do
        if areaCardRole==0 or F.db.cards[id].role==F.roles[areaCardRole] then owned[#owned+1]=id end
    end
    table.sort(owned,function(a,b) return cardLess(a,b,areaCardSort) end)
    label(320,440,280,24,"Discovered creatures"):SetFontObject(fonts.heading)
    button(618,436,142,F.roles[areaCardRole] or "All roles",function()
        areaCardRole,atlasCardPage=(areaCardRole+1)%4,1
    end,"Filter this area's discovered creatures by role.")
    cycle(772,436,164,cardSorts,areaCardSort,function(i) areaCardSort,atlasCardPage=i,1 end,
        "Sort this area's discovered cards.")
    if #owned==0 then
        section(320,470,616,120)
        label(337,485,580,27,#area.owned==0 and "No cards collected in this area yet" or "No cards match this role"):SetFontObject(fonts.heading)
        label(337,520,580,36,#area.owned==0 and "Collect cards from eligible overworld creatures."
            or "Switch to All roles to see every creature you have collected here."):SetFontObject(fonts.small)
    end
    local cardPages=math.max(1,math.ceil(#owned/4))
    atlasCardPage=math.min(atlasCardPage,cardPages)
    for i=(atlasCardPage-1)*4+1,math.min(atlasCardPage*4,#owned) do
        local id=owned[i]
        local tile=face(337+((i-1)%4)*155,466,104,147,id,F.db.cards[id],{showcase=true,click=function()
            resetCollectionFilters()
            inspect(id)
            journalView="cards"
            F.refresh()
        end})
        local creature=F.db.cards[id]
        tile:SetScript("OnEnter",function(self)
            local landmark=F.speciesOf(id)[3]
            F.showTooltip(self,"ANCHOR_RIGHT",creature.name,fieldCardInfo(id,creature)
                ..(landmark and ("\n"..gold.."Recorded sightings|r  "..landmark) or "")
                .."\n\n"..colors.muted.."Open this card in the journal.|r")
        end)
        tile:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    button(320,625,100,"Previous",function() atlasCardPage=atlasCardPage-1 end,nil,atlasCardPage>1)
    button(432,625,100,"Next",function() atlasCardPage=atlasCardPage+1 end,nil,atlasCardPage<cardPages)
end
local statsPage=1
local function journalStats(stats)
    local record=F.db.stats
    local items={{"Collected",stats.owned},{"Uncollected",stats.total-stats.owned},
        {"Total mastery",stats.mastery},{"Wins",record.wins or 0}}
    for i,row in ipairs(items) do counter(24+(i-1)*230,222,218,row[1],row[2]) end
    section(24,322,912,57)
    local secondary={{stats.copies,"copies"},{stats.kills,"kills"},{stats.prestige,"prestige ranks"},
        {record.losses or 0,"losses"},{record.draws or 0,"draws"}}
    for i,stat in ipairs(secondary) do
        label(37+(i-1)*180,341,170,21,gold..stat[1].."|r "..stat[2]):SetJustifyH("CENTER")
    end
    section(24,392,912,263,"Area completion")
    local names={}
    for name,area in pairs(stats.zones) do
        if area.total>0 and (statsFilter==1 or (statsFilter==2 and #area.owned<area.total)
            or (statsFilter==3 and #area.owned==area.total)) then names[#names+1]=name end
    end
    table.sort(names,function(a,b) return areaLess(stats.zones,a,b,statsSort) end)
    cycle(660,397,122,{"All tracked","Incomplete","Complete"},statsFilter,function(i) statsFilter,statsPage=i,1 end,
        "Filter areas by collection completion.")
    cycle(793,397,129,{"Name A-Z","Completion","Most missing"},statsSort,function(i) statsSort,statsPage=i,1 end,
        "Sort completion rows by name, percentage, or missing cards.")
    if #names==0 then label(42,438,450,23,"No areas match.") end
    local pages=math.max(1,math.ceil(#names/5))
    statsPage=math.min(statsPage,pages)
    for i=(statsPage-1)*5+1,math.min(statsPage*5,#names) do
        local name=names[i]
        local area=stats.zones[name]
        local y=439+((i-1)%5)*32
        local progress=#area.owned/area.total
        button(42,y-3,278,name,function()
            atlasZone,atlasFilter,atlasCardPage,journalView,atlasQuery=name,1,1,"areas",""
        end,("%d of %d cards collected. Open this area."):format(#area.owned,area.total))
        meter(333,y+8,470,progress)
        label(818,y,98,23,("%.0f%%"):format(progress*100)):SetJustifyH("RIGHT")
    end
    button(42,611,100,"Previous",function() statsPage=statsPage-1 end,nil,statsPage>1)
    button(154,611,100,"Next",function() statsPage=statsPage+1 end,nil,statsPage<pages)
end
local function soloMoveDetails(id,c,move,tier)
    local event=F.cardMovePreview(id,move)
    local base=tier>0 and F.cardMovePreview(id,move,true) or event
    local stats={}
    if event.hit>0 then stats[#stats+1]=colors.damage..event.hit.." damage|r" end
    if event.guard>0 then stats[#stats+1]=colors.shield..event.guard.." shield|r" end
    stats[#stats+1]=colors.focus..("%+d Focus|r"):format(event.focus)

    local bonus
    if event.hit>base.hit then bonus=("+%d damage"):format(event.hit-base.hit)
    elseif event.guard>base.guard then bonus=("+%d shield"):format(event.guard-base.guard) end

    local card={id=id,role=c.role}
    return F.moveName(card,move,true,true),table.concat(stats," / "),bonus,F.moveDescription(card,move,true,true)
end

local function soloMoves(id,c,expanded)
    local tier=F.tier(c)
    local conditions=F.masteryEffectLabels(tier)
    if tier>=4 then
        local technique=F.loadout({id=id}).X
        if not F.moveTargetsRival(technique) then conditions.X={} end
        local _,effect=F.techniqueMastery(technique)
        if technique.power then effect="Adds 1 damage. "..effect end
        table.insert(conditions.X,1,"Technique Mastery: "..effect)
    end
    local x,y,width=736,227,192
    if expanded then
        label(420,248,496,22,"Solo moves"):SetFontObject(fonts.heading)
        x,y,width=420,273,496
    end
    for _,move in ipairs(F.actions(true)) do
        local name,stats,bonus,description=soloMoveDetails(id,c,move,tier)
        local effects=conditions[move]
        local perks={}
        if bonus and move~="X" then perks[1]="Mastery adds "..bonus.." to the total above" end
        for _,effect in ipairs(effects) do perks[#perks+1]=effect end
        local title=moveColors[move][4]..name.."|r"
        if expanded then
            local height=39+#perks*15
            section(x,y,width,height)
            label(x+12,y+6,width-24,17,title..gold.."  /  "..moveTypes[move].."|r"):SetFontObject(fonts.bold)
            label(x+12,y+22,width-24,16,stats)
            for i,perk in ipairs(perks) do
                label(x+12,y+36+(i-1)*15,width-24,15,gold..perk.."|r")
            end
            hoverHelp(x,y,width,height,name,stats.."\n\n"..description)
            y=y+height+4
        else
            local height=#perks>0 and 54 or 39
            section(x,y,width,height)
            label(x+9,y+3,width-18,16,title):SetFontObject(fonts.bold)
            label(x+9,y+20,width-18,16,stats):SetFontObject(fonts.small)
            if #perks>0 then
                local caption=bonus and ("Mastery "..bonus) or "Mastery effects"
                if bonus and #effects>0 then caption=caption.." / situational" end
                label(x+9,y+35,width-18,16,gold..caption.."|r"):SetFontObject(fonts.small)
                description=description.."\n\n"..table.concat(perks,"\n")
            end
            hoverHelp(x,y,width,height,name,stats.."\n\n"..description)
            y=y+height+5
        end
    end
    return y
end

local function earnedPerks(c)
    local tier=F.tier(c)
    section(420,248,496,45)
    label(432,260,330,20,"Earned Mastery perks"):SetFontObject(fonts.heading)
    label(780,261,124,20,tier.." unlocked"):SetJustifyH("RIGHT")
    if tier==0 then
        label(432,306,470,24,"No Mastery perks earned yet."):SetFontObject(fonts.muted)
        return
    end
    local perPage=8
    local pages=math.ceil(tier/perPage)
    perksPage=math.min(perksPage,pages)
    local first=(perksPage-1)*perPage+1
    for i=first,math.min(first+perPage-1,tier) do
        local y=302+(i-first)*36
        section(420,y,496,31)
        label(432,y+7,396,20,F.perks[i])
        local threshold=label(836,y+7,68,20,gold..F.balance.mastery[i].." XP|r")
        threshold:SetFontObject(fonts.strongSmall)
        threshold:SetJustifyH("RIGHT")
    end
    if pages>1 then
        button(420,601,96,"Previous",function() perksPage=perksPage-1 end,nil,perksPage>1)
        label(526,607,110,18,perksPage.." / "..pages):SetJustifyH("CENTER")
        button(646,601,96,"Next",function() perksPage=perksPage+1 end,nil,perksPage<pages)
    end
end

local function synergyMoveNotes(pairing)
    local lines={}
    for _,match in ipairs(pairing.matches) do
        local from,to=F.db.cards[match.from],F.db.cards[match.to]
        if from and to then
            lines[#lines+1]=from.name..": "..table.concat(match.setup,", ").."  ->  "
                ..to.name..": "..table.concat(match.follow,", ")
        end
    end
    return table.concat(lines,"\n")
end

local function cardSynergies(id,owned)
    local partners={}
    for _,other in ipairs(owned) do
        if other~=id then
            local rules=F.synergyPairings({id,other})
            if #rules>0 then partners[#partners+1]={id=other,rules=rules} end
        end
    end
    table.sort(partners,function(a,b)
        local first,second=F.db.cards[a.id].name,F.db.cards[b.id].name
        return first<second or (first==second and a.id<b.id)
    end)

    if #partners==0 then
        label(420,253,496,24,"No compatible partners in your collection."):SetFontObject(fonts.muted)
        return
    end
    label(431,250,222,20,"Partner"):SetFontObject(fonts.heading)
    label(670,250,245,20,"Solo Battle effects"):SetFontObject(fonts.heading)
    local perPage=7
    local pages=math.ceil(#partners/perPage)
    synergiesPage=math.min(synergiesPage,pages)
    local first=(synergiesPage-1)*perPage+1
    for i=first,math.min(first+perPage-1,#partners) do
        local partner=partners[i]
        local card=F.db.cards[partner.id]
        local names,details={},{}
        for _,pairing in ipairs(partner.rules) do
            local rule=F.synergies[pairing.key]
            names[#names+1]=rule.name
            details[#details+1]=colors.synergy..rule.name.."|r\n"..rule.effect.."\n"..synergyMoveNotes(pairing)
        end
        local featured=partner.rules[1].matches[1]
        local chain=featured.setup[1].."  ->  "..featured.follow[1]
        local tip=table.concat(details,"\n\n")
        local y=277+(i-first)*46
        section(420,y,496,43)
        button(430,y+2,222,card.name,function()
            resetCollectionFilters()
            inspect(partner.id)
            pendingCardScroll=true
        end,F.typeBadges(partner.id,card,14,true).."\n\n"..tip)
        label(670,y+5,232,19,table.concat(names," / ")):SetMaxLines(1)
        label(430,y+28,472,15,chain):SetFontObject(fonts.small)
        hoverHelp(661,y,255,43,card.name,tip)
    end
    if pages>1 then
        button(420,601,96,"Previous",function() synergiesPage=synergiesPage-1 end,nil,synergiesPage>1)
        label(526,607,110,18,synergiesPage.." / "..pages):SetJustifyH("CENTER")
        button(646,601,96,"Next",function() synergiesPage=synergiesPage+1 end,nil,synergiesPage<pages)
    end
end

local function noteDate(timestamp)
    return timestamp and date and date("%Y-%m-%d",timestamp) or "Not recorded"
end
local function creatureProfile(id,c,species)
    local x,width=416,513
    section(x,248,width,103,"Creature traits")
    label(431,282,228,18,gold.."Family|r  "..species[2]):SetFontObject(fonts.bold)
    label(681,282,232,18,gold.."NPC ID|r  "..id):SetFontObject(fonts.small)
    label(431,305,228,22,F.typeBadges(id,c,16,true)):SetFontObject(fonts.bold)
    label(681,305,232,22,gold.."Solo role|r  "..c.role.."   "..gold.."Speed|r  "..F.cardSpeed(c)):SetFontObject(fonts.small)
    local technique=F.moveName({id=id,role=c.role},"X",true,true)
    label(431,330,472,17,gold.."Solo technique|r  "..moveColors.X[4]..technique.."|r"):SetFontObject(fonts.small)

    section(x,360,width,114,"Habitat and sightings")
    label(431,394,472,22,species[1]):SetFontObject(fonts.bold)
    label(431,419,472,42,species[3] or colors.muted.."No specific landmarks recorded.|r")
    button(779,370,133,"View habitat",function()
        atlasZone,atlasFilter,atlasCardPage,journalView,atlasQuery=species[1],1,1,"areas",""
    end,"Open this creature's primary habitat in Areas.")

    section(x,483,width,133,"Solo Battle signature")
    local name,stats,_,description=soloMoveDetails(id,c,"S",F.tier(c))
    label(431,517,472,21,moveColors.S[4]..name.."|r"):SetFontObject(fonts.bold)
    label(431,541,472,18,colors.muted.."Preview|r  "..stats):SetFontObject(fonts.small)
    label(431,566,472,43,description)
    hoverHelp(427,512,489,96,name,description.."\n\n"..gold.."Preview|r  "..stats)
end

local function cardFieldNotes(id,c,species,owned)
    label(420,149,503,32,c.name):SetFontObject(fonts.title)
    label(420,181,493,21,rarity(c).." / "..species[2].." / "..species[1]):SetFontObject(fonts.small)
    local pages={"Collection","Combat","Records","Profile","Perks","Synergies"}
    local widths={91,75,81,72,66,101}
    local x=420
    for i,name in ipairs(pages) do
        local page=i
        local tab=button(x,211,widths[i],name,function()
            notesPage,confirm=page,nil
            if page==2 then showCombatStats=false end
        end)
        x=x+widths[i]+4
        if notesPage==i then tone(tab,"active") end
    end
    if notesPage==6 then
        cardSynergies(id,owned)
        return
    end
    if notesPage==5 then
        earnedPerks(c)
        return
    end
    if notesPage==2 and not showCombatStats then
        button(796,244,120,"Battle stats",function() showCombatStats=true end)
        soloMoves(id,c,true)
        return
    end
    local stats
    if notesPage==2 or notesPage==3 then
        cycle(766,242,150,{"Solo Battle","Friendly duels"},notesMode,function(i) notesMode=i end,
            "Switch between this card's solo and friendly-duel statistics.")
        stats=(c.fieldStats or {})[notesMode==1 and "solo" or "duel"] or {}
    end
    if notesPage==4 then
        creatureProfile(id,c,species)
        return
    end
    local rows={}
    local function metric(name,value,tip,valueColor)
        rows[#rows+1]={name,value,tip,valueColor}
    end
    if notesPage==1 then
        local builds=0
        for _,deck in pairs(F.db.decks) do
            for slot=1,3 do
                if deck[slot]==id then builds=builds+1 break end
            end
        end
        metric("Copies found",c.lifetime,"All copies collected, including those spent on prestige.")
        metric("Recorded kills",c.kills or 0,"Credited kills. Older collection history may be incomplete.")
        metric("Loot checks",c.rolls or 0,"Recorded eligible corpse loot checks.")
        local chance,limit=F.repeatOdds(c)
        metric("Repeat rolls",("%d / %d"):format(c.repeatRolls or 0,limit),
            ("Progress toward a guaranteed repeat copy. Chance per eligible roll: %.1f%%."):format(chance*100))
        metric("Mastery XP",c.mastery or 0,"Lifetime XP earned through copies, credited kills, and solo wins.")
        metric("Mastery perks",F.tier(c).." / "..#F.balance.mastery,"Unlocked perks out of all Mastery tiers. See Perks for the effects you have earned.")
        metric("Prestige rank",c.prestige,"Times you have prestiged this card. The first rank grants a foil treatment and adds 1 Focus to its Solo Battle guard move.")
        metric("Copy progress",c.progress.." / 100","Copies available for prestige. Each rank costs 100 copy progress and preserves lifetime copies and Mastery XP.")
        metric("Saved decks",builds,"Number of saved decks that include this creature.")
        metric("NPC ID",id,"The game ID of the creature that awards this card.")
        metric("First discovered",noteDate(c.firstCopyAt),"Date of your first recorded copy of this card.")
        metric("Last copy",noteDate(c.lastCopyAt),"Date of your most recent recorded copy of this card.")
        metric("Last credited kill",noteDate(c.lastKillAt),"Date of the most recent kill credited to this creature in the journal.")
        if species[3] then
            label(420,562,494,42,species[3]):SetFontObject(fonts.muted)
        end
        button(420,617,170,confirm==id and "Confirm prestige" or "Prestige",function()
            if confirm==id then if F.prestige(c) then F.sound("perk") end confirm=nil else confirm=id end
        end,"Spend 100 copy progress for a foil rank. Prestige 1 adds 1 Focus to the card's solo guard move.",c.progress>=100)
    elseif notesPage==2 then
        metric("Actions taken",stats.actions or 0,"Total moves this card used across recorded battles in the selected mode.")
        metric("Damage dealt",stats.damage or 0,"HP removed after shields. Overkill damage is excluded.",colors.damage)
        metric(notesMode==1 and "Attacks" or "Strikes",stats.A or 0,"Times this card used its basic offensive move.")
        metric(notesMode==1 and "Guard moves" or "Braces",stats.B or 0,"Times this card used its defensive move.")
        if notesMode==1 then metric("Techniques",stats.X or 0,"Times this card used its technique.") end
        metric("Signatures",stats.S or 0,"Times this card used its signature move.")
        metric("Tactics used",stats.tactics or 0,"Times a tactic was played with this card's action.")
        metric("Shield gained",stats.shieldGained or 0,"Total positive net shield from this card's actions.",colors.shield)
        metric("Shield broken",stats.shieldBroken or 0,"Shield removed before damage.",colors.shield)
        metric("Marks applied",stats.marks or 0,"Times this card marked a rival for a follow-up hit.")
        metric("Mark combos",stats.combos or 0,"Times this card consumed a rival's mark for bonus damage.")
        if notesMode==1 then
            metric("Synergies primed",stats.setups or 0,"Number of synergy setups this card created for a teammate to follow up.")
            metric("Synergies triggered",stats.payoffs or 0,"Number of synergy payoffs this card triggered after a setup.")
            metric("Knockouts scored",stats.knockouts or 0,"Rival creatures this card reduced to zero HP.")
            metric("Times knocked out",stats.knockedOut or 0,"Times a rival reduced this card to zero HP.")
            metric("Damage taken",stats.damageTaken or 0,"HP this card lost to rival actions after shield absorption.",colors.damage)
            metric("Damage blocked",stats.damageBlocked or 0,"Incoming damage absorbed by this card's shield.",colors.shield)
            metric("Haste ticks",stats.haste or 0,"Total initiative ticks advanced by haste from this card's moves.")
            metric("Delay ticks",stats.delay or 0,"Total initiative ticks added to rival turns by this card's moves.")
        end
    else
        local matches,wins=stats.matches or 0,stats.wins or 0
        metric("Battles fielded",matches,"Recorded results with this card in your roster, including concessions.")
        metric("Battles with an action",stats.activeMatches or 0,"Recorded battles in which this card used at least one move.")
        metric("Wins",wins,"Recorded victories with this card in the roster.",colors.success)
        metric("Losses",stats.losses or 0,"Recorded defeats with this card in the roster.",colors.damage)
        metric("Draws",stats.draws or 0,"Recorded draws with this card in the roster.")
        metric("Win rate",matches>0 and ("%d%%"):format(math.floor(wins*100/matches+.5)) or "No battles",
            "Wins divided by all recorded battles with this card in the roster, including draws.")
        metric("Current win streak",stats.streak or 0,"Consecutive wins in the current run of recorded battles with this card. A loss or draw resets the count.")
        metric("Best win streak",stats.bestStreak or 0,"Longest recorded run of consecutive wins with this card in the roster.")
        metric("Biggest hit",stats.biggestHit or 0,"Most HP this card removed from an opponent in a single action.")
        metric("Most damage in a battle",stats.biggestBattle or 0,"Highest total HP damage this card dealt in one recorded battle.")
        if notesMode==1 then metric("Mastery XP from wins",stats.masteryEarned or 0,"Mastery XP this card earned by acting in Solo Battle victories.") end
        metric("Last battle",noteDate(stats.lastBattle),"Date of the most recent recorded battle that fielded this card in the selected mode.")
    end
    local top=notesPage==1 and 249 or 275
    for i,row in ipairs(rows) do
        local x=420+(i-1)%2*252
        local y=top+math.floor((i-1)/2)*32
        section(x,y,244,30)
        local name,value,tip=row[1],tostring(row[2]),row[3]
        local title=label(x+7,y+2,131,26,name)
        title:SetFontObject(fonts.strongSmall)
        title:SetJustifyV("MIDDLE")
        local valueColor=(value=="Not recorded" or value=="No battles") and colors.muted or row[4] or gold
        local amount=label(x+143,y+2,94,26,valueColor..value.."|r")
        amount:SetFontObject(fonts.bold)
        amount:SetJustifyH("RIGHT")
        amount:SetJustifyV("MIDDLE")
        hoverHelp(x,y,244,30,name,valueColor..value.."|r\n\n"..tip)
    end
    if notesPage==2 or notesPage==3 then
        label(420,602,496,16,"Includes battles recorded since card tracking began."):SetFontObject(fonts.italic)
        if notesPage==2 then button(420,621,117,"Solo moves",function() showCombatStats=false end) end
    end
end
local function collection()
    local title=journalView=="areas" and "Areas" or journalView=="stats" and "Statistics" or "Field Journal"
    banner(22,91,journalView=="cards" and 356 or 914,108,"Woodland")
    ink(36,102,310,36,title):SetFontObject(fonts.title)
    local owned=F.owned()
    updateHabitatFilter(owned)
    local stats=F.journalStats()
    local loading,done,total,unit=F.catalogueProgress()
    if loading=="waiting" or loading=="loading" then
        local progress=done and total>0 and done/total or 0
        ink(36,153,326,17,done and ("Indexing %s: %d / %d (%.0f%%)"):format(unit,done,total,progress*100)
            or "Waiting for creature catalog...")
        surface(36,170,326,3,.32,.28,.19)
        if progress>0 then surface(36,170,326*progress,3,.32,.57,.82) end
    end
    local progressText=journalView=="cards" and ("%d cards collected"):format(#owned)
        or ("%d collected / %d uncollected"):format(stats.owned,stats.total-stats.owned)
    ink(36,(loading=="waiting" or loading=="loading") and 134 or 142,370,21,progressText)
    for i,entry in ipairs({{"cards","Cards"},{"areas","Areas"},{"stats","Statistics"}}) do
        local view=entry[1]
        local tips={cards="Browse your collection.",areas="Explore habitats and area progress.",stats="Review collection and Relay totals."}
        local w=button(36+(i-1)*110,178,103,entry[2],function() journalView=view end,tips[view])
        if journalView==view then tone(w,"active") end
    end
    if journalView~="cards" then
        if journalView=="areas" then atlas(stats) else journalStats(stats) end
        return
    end
    section(22,213,356,441)
    local latestCard=F.db.latest and F.db.cards[F.db.latest]
    if latestCard and latestCard.unseen and F.eligibleCreature(F.db.latest) then
        button(197,665,181,"Reveal latest discovery",function()
            resetCollectionFilters()
            inspect(F.db.latest)
            pendingCardScroll=true
        end,"Open your latest unread creature card.")
    end
    local favorites=F.db.journalFavorites or {}
    local filterCount=(role~=0 and 1 or 0)+(habitatFilter~=0 and 1 or 0)
        +(newOnly and 1 or 0)+(favoritesOnly and 1 or 0)+(collectionRarity~=1 and 1 or 0)
    edit(36,240,181,query,function(value) query=value resetGrid() F.refresh() end,"Search the Field Journal")
    label(36,221,200,16,"Search name, type or NPC ID"):SetFontObject(fonts.small)
    button(225,240,60,"Clear",function() resetCollectionFilters() end,
        "Clear search and collection filters.",query~="" or filterCount>0)
    button(292,240,72,filterCount>0 and ("Filters ("..filterCount..")") or "Filters",function()
        showCollectionFilters=not showCollectionFilters
    end,"Filter by combat role, habitat, rarity, or discovery status.")
    cycle(36,275,102,{"New first","Name A-Z","Most mastery","Most copies"},journalSort,function(i)
        journalSort=i resetGrid()
    end,"Sort your discovered cards.")
    local newButton=button(145,275,103,"New cards",function() newOnly=not newOnly resetGrid() end,
        "Show discoveries you have yet to inspect.")
    local favoriteButton=button(255,275,109,"Favorites",function() favoritesOnly=not favoritesOnly resetGrid() end,
        "Show the creatures you marked as favorites.")
    if newOnly then tone(newButton,"active") end
    if favoritesOnly then tone(favoriteButton,"active") end
    if showCollectionFilters then
        button(36,307,95,F.roles[role] or "All roles",function() role=(role+1)%4 resetGrid() end,"Cycle combat roles, which determine speed and HP. Search by type for synergy pairings.")
        button(138,307,122,habitatFilter==0 and "All areas" or habitatFilter,function()
            for i,zone in ipairs(habitatOrder) do
                if zone==habitatFilter then
                    habitatFilter=habitatOrder[i%#habitatOrder+1]
                    break
                end
            end
            resetGrid()
        end,"Cycle through habitats represented in your collection.")
        cycle(267,307,97,collectionRarities,collectionRarity,function(i)
            collectionRarity=i resetGrid()
        end,"Cycle rarity filters.")
    end
    local results={}
    local searchTerm=query:lower()
    for _,id in ipairs(owned) do
        local c=F.db.cards[id]
        if (not favoritesOnly or favorites[id]) and (collectionRarity==1 or collectionRarities[collectionRarity]==(c.rarity or "Common"))
            and (role==0 or c.role==F.roles[role]) and (habitatFilter==0 or F.speciesOf(id)[1]==habitatFilter) and (not newOnly or c.unseen or selected==id and unreadOrder[id])
            and cardMatches(id,c,searchTerm) then
            unreadOrder[id]=unreadOrder[id] or c.unseen
            results[#results+1]=id
        end
    end
    table.sort(results,function(a,b)
        if journalSort==1 and unreadOrder[a]~=unreadOrder[b] then return (unreadOrder[a] or 0)>(unreadOrder[b] or 0) end
        return cardLess(a,b,journalSort-1)
    end)
    local visibleRows=showCollectionFilters and 9 or 10
    local rowTop=showCollectionFilters and 340 or 308
    local maxRow=math.max(0,#results-visibleRows)
    journalRow=math.min(maxRow,journalRow)
    local function scroll(_,delta)
        journalRow=math.min(maxRow,math.max(0,journalRow-delta))
        F.refresh()
    end
    local wheel=item("wheel")
    place(wheel,34,rowTop,330,visibleRows*29)
    wheel:SetFrameLevel(panel:GetFrameLevel())
    wheel:EnableMouse(false)
    wheel:SetScript("OnEnter",nil)
    wheel:SetScript("OnLeave",nil)
    wheel:EnableMouseWheel(true)
    wheel:SetScript("OnMouseWheel",scroll)
    local id
    for i,candidate in ipairs(results) do
        if candidate==selected then
            id=candidate
            if pendingCardScroll then journalRow=math.min(maxRow,i-1) end
            break
        end
        if not id and not F.db.cards[candidate].unseen then id=candidate end
    end
    pendingCardScroll=nil
    for i=journalRow+1,math.min(journalRow+visibleRows,#results) do
        local rowID=results[i]
        local card=F.db.cards[rowID]
        local prefix=card.unseen and (gold.."New|r  ") or ""
        local row=button(36,rowTop+(i-journalRow-1)*29,321,prefix..card.name,function()
            inspect(rowID)
        end,fieldCardInfo(rowID,card),true,"collectionRow")
        local text=row:GetFontString()
        if text then
            text:ClearAllPoints()
            text:SetPoint("LEFT",row,"LEFT",53,0)
            text:SetSize(205,21)
            text:SetJustifyH("LEFT")
            text:SetMaxLines(1)
        end
        if not row.copyText then
            row.typeIcons=row:CreateFontString(nil,"OVERLAY")
            row.typeIcons:SetFontObject(fonts.small)
            row.typeIcons:SetPoint("LEFT",10,0)
            row.typeIcons:SetSize(40,21)
            row.typeIcons:SetJustifyH("LEFT")
            row.copyText=row:CreateFontString(nil,"OVERLAY")
            row.copyText:SetFontObject(fonts.small)
            row.copyText:SetPoint("RIGHT",-9,0)
            row.favoriteMark=row:CreateTexture(nil,"ARTWORK")
            row.favoriteMark:SetTexture(F.media.."Compass.tga")
            row.favoriteMark:SetPoint("RIGHT",row.copyText,"LEFT",-6,0)
            row.favoriteMark:SetSize(12,12)
        end
        row.typeIcons:SetText(F.typeBadges(rowID,card,17,false))
        row.favoriteMark:SetShown(favorites[rowID]==true)
        row.copyText:SetText("x"..card.lifetime)
        if id==rowID then
            tone(row,"active")
        else
            row:SetBackdropColor(.105,.151,.218,.88)
        end
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel",scroll)
    end
    if #results==0 then
        ink(38,rowTop+14,319,62,#owned==0 and ("Defeat and loot eligible creatures. Your first copy is guaranteed by %d credited kills of the same creature."):format(F.balance.firstCopyLimit) or "No discoveries match your filters.")
        if #owned>0 then button(40,rowTop+67,124,"Clear filters",resetCollectionFilters) end
    end
    if maxRow>0 then
        local trackHeight=visibleRows*29-3
        local thumbHeight=math.max(18,trackHeight*visibleRows/#results)
        surface(365,rowTop,3,trackHeight,.10,.16,.18)
        surface(365,rowTop+(trackHeight-thumbHeight)*journalRow/maxRow,3,thumbHeight,.63,.48,.28):SetDrawLayer("ARTWORK")
    end
    button(36,614,67,"Up",function() journalRow=journalRow-1 end,nil,journalRow>0)
    button(297,614,67,"Down",function() journalRow=journalRow+1 end,nil,journalRow<maxRow)
    label(110,621,180,19,#results==0 and "0 cards" or ("%d-%d of %d cards"):format(
        journalRow+1,math.min(journalRow+visibleRows,#results),#results)):SetJustifyH("CENTER")
    if #owned>=3 and not F.validate(F.db.decks[F.db.active],true) then
        button(22,665,164,"Equip first three",function()
            local name="Field Journal"
            while F.db.decks[name] do name=name.."+" end
            F.db.decks[name]={owned[1],owned[2],owned[3]}
            F.db.tacticDecks[name]=F.tacticDeck()
            F.db.active=name
            loadDraft()
            tab="Battle"
        end)
    end
    local c=id and F.db.cards[id]
    section(398,91,546,563)
    surface(415,138,512,1,.23,.29,.37)
    if not c or c.lifetime==0 then
        banner(415,154,512,210,"Woodland")
        label(438,218,450,45,"Creature studies"):SetFontObject(fonts.title)
        label(438,269,360,52,#owned>0 and "Select a creature from the list to inspect its card." or "Your first creature's portrait and field notes will appear here.")
        if F.db.latest and F.eligibleCreature(F.db.latest) then button(438,375,200,"Latest discovery",function() resetCollectionFilters() inspect(F.db.latest) pendingCardScroll=true end) end
        return
    end
    local opening=reveal==id
    reveal=nil
    for i,view in ipairs({"Overview","Field notes"}) do
        local dest=view
        local tabButton=button(416+(i-1)*119,103,111,dest,function()
            inspectorView,confirm=dest,nil
        end)
        if inspectorView==dest then tone(tabButton,"active") end
    end
    button(818,101,109,favorites[id] and "Favorited" or "Favorite",function()
        F.db.journalFavorites=favorites
        favorites[id]=not favorites[id] or nil
    end,"Add or remove this creature from your favorites.")
    local species=F.speciesOf(id)
    if inspectorView=="Field notes" then
        cardFieldNotes(id,c,species,owned)
    else
        surface(724,155,1,475,.20,.26,.33)
        face(418,155,290,406,id,c,{inspect=true,reveal=opening,full=true,ornate=true,
            click=function() if opening then F.refresh() end end})
        label(737,156,189,17,"Creature family"):SetFontObject(fonts.muted)
        label(737,178,189,19,species[2]):SetFontObject(fonts.bold)
        label(737,202,189,22,"Solo moves"):SetFontObject(fonts.heading)
        local afterMoves=soloMoves(id,c,false)
        button(737,afterMoves+3,189,"Move details",function()
            notesPage,inspectorView,showCombatStats=2,"Field notes",false
        end,"Review current move totals and Mastery effects.")
        local tier=F.tier(c)
        local threshold=F.balance.mastery[tier+1]
        local mastery=c.mastery or 0
        local y=afterMoves+42
        label(737,y,105,20,"Mastery XP"):SetFontObject(fonts.heading)
        label(837,y+2,89,18,("%d XP"):format(mastery)):SetJustifyH("RIGHT")
        local floor=F.balance.mastery[tier] or 0
        local fill=threshold and (mastery-floor)/(threshold-floor) or 1
        meter(737,y+25,189,fill)
        label(737,y+36,189,18,threshold and ("%d XP to next perk"):format(threshold-mastery)
            or "All Mastery perks unlocked"):SetFontObject(fonts.small)
        hoverHelp(736,y,192,54,"Mastery XP",
            "Earn 1 XP per copy, per credited kill after discovery, or per Solo Battle win where the card acted.")
        button(737,y+60,189,("Earned perks (%d)"):format(tier),function()
            notesPage,inspectorView,perksPage=5,"Field notes",1
        end,"Review the Mastery perks this creature has earned.")
        button(418,595,160,"Synergies",function()
            notesPage,inspectorView,synergiesPage=6,"Field notes",1
        end,"See which collected cards pair with this creature in Solo Battle.")
    end
    tone(button(737,617,189,"Add to draft",function()
        if panel.draftOpened~=true then loadDraft() end
        pending=id
        tab="Decks" choosingDeck,deckTools=false,false panel.draftOpened=true
    end,"Place this creature in your current deck draft."),"primary")

end
local function decks()
    if choosingDeck then
        banner(22,91,916,93,"Woodland")
        label(38,103,480,36,"Saved decks"):SetFontObject(fonts.title)
        label(39,146,206,17,"Search saved deck names"):SetFontObject(fonts.muted)
        section(22,196,507,401)
        section(546,196,392,401)
        edit(39,163,199,deckQuery,function(text) deckQuery,deckPage,deleteDeck=text,1,nil F.refresh() end,"Find a saved deck")
        cycle(255,158,126,{"All decks","Equipped only","Unequipped"},deckFilter,function(i) deckFilter,deckPage,deleteDeck=i,1,nil end,
            "Filter saved decks by equipped status.")
        cycle(390,158,126,{"Name A-Z","Name Z-A","Equipped first"},deckSort,function(i) deckSort,deckPage,deleteDeck=i,1,nil end,
            "Change the order of saved decks.")
        local names={}
        for name in pairs(F.db.decks) do
            local active=name==F.db.active
            if name:lower():find(deckQuery:lower(),1,true)
                and (deckFilter==1 or (deckFilter==2 and active) or (deckFilter==3 and not active)) then
                names[#names+1]=name
            end
        end
        table.sort(names,function(a,b)
            if deckSort==3 and (a==F.db.active or b==F.db.active) then return a==F.db.active end
            if deckSort==2 then return a>b end
            return a<b
        end)
        local pages=math.max(1,math.ceil(#names/8))
        deckPage=math.min(deckPage,pages)
        if #names==0 then label(38,217,460,26,"No saved decks match.") end
        for i=(deckPage-1)*8+1,math.min(deckPage*8,#names) do
            local name=names[i]
            local y=208+(i-1)%8*37
            local deck=button(38,y,342,name..(name==F.db.active and colors.success.."  (equipped)|r" or ""),function()
                loadDraft(name) choosingDeck,deleteDeck=false,nil
            end,"Open this roster and its tactics in the Deck Builder.")
            if name==F.db.active then tone(deck,"active") end
            local remove=button(388,y,126,deleteDeck==name and "Confirm delete" or "Delete",function()
                if deleteDeck~=name then deleteDeck=name return end
                F.db.decks[name],F.db.tacticDecks[name]=nil,nil
                if F.db.active==name then F.db.active=nil end
                if draftName==name then loadDraft() end
                deleteDeck=nil
                F.notice="Deleted "..name
            end,"Remove this saved deck and its tactic loadout. Deleting the equipped deck clears the equipped slot.")
            if deleteDeck==name then tone(remove,"danger") end
        end
        button(38,526,83,"Previous",function() deckPage=deckPage-1 deleteDeck=nil end,nil,deckPage>1)
        button(131,526,85,"Next",function() deckPage=deckPage+1 deleteDeck=nil end,nil,deckPage<pages)
        if deleteDeck then button(227,526,128,"Cancel delete",function() deleteDeck=nil end,"Keep the saved deck.") end
        label(564,215,352,20,"Equipped roster"):SetFontObject(fonts.heading)
        local equipped=F.db.decks[F.db.active] or {}
        label(564,245,352,25,F.db.active and colors.success..F.db.active.."|r" or "No deck equipped"):SetFontObject(fonts.muted)
        for i=1,3 do
            local id=equipped[i]
            face(564+(i-1)*119,284,110,151,id,id and F.db.cards[id],{mini=true,showcase=true})
        end
        tone(button(564,465,163,"New deck",function()
            draft={} draftTactics=F.tacticDeck() draftName="" slot=1 choosingDeck,deleteDeck=false,nil
        end,"Start a blank roster draft."),"primary")
        button(740,465,177,"Back to builder",function() choosingDeck,deleteDeck=false,nil end,"Return to your current draft.")
        return
    end
    if picker then
        banner(22,91,916,92,"Woodland")
        label(38,103,880,36,"Choose tactic for slot "..picker):SetFontObject(fonts.title)
        cycle(38,149,152,{"All tactics","Available only"},tacticFilter,function(i) tacticFilter=i end,
            "Hide tactics already assigned to another slot.")
        cycle(202,149,152,{"Default order","Name A-Z"},tacticSort,function(i) tacticSort=i end,"Change tactic order.")
        local choices,takenIds={},{}
        for slot=1,F.maxTactics do
            if slot~=picker and draftTactics[slot] then takenIds[draftTactics[slot]]=true end
        end
        for id in ipairs(F.tactics) do
            if tacticFilter==1 or not takenIds[id] then choices[#choices+1]=id end
        end
        if tacticSort==2 then table.sort(choices,function(a,b) return F.tactics[a][1]<F.tactics[b][1] end) end
        for i,aid in ipairs(choices) do
            local t=F.tactics[aid]
            local x=38+(i-1)%2*450
            local y=215+math.floor((i-1)/2)*102
            section(x-10,y-12,435,90)
            local taken=takenIds[aid]
            colorAction(button(x,y,415,t[1]..(taken and " (already selected)" or ""),function()
                draftTactics[picker]=aid picker=nil F.sound("place")
            end,t[2],not taken),"tactic",not taken)
            label(x+5,y+33,401,44,t[2])
        end
        button(204,540,175,"Clear tactic slot",function() draftTactics[picker]=nil picker=nil end,nil,draftTactics[picker]~=nil)
        button(38,540,150,"Cancel",function() picker=nil end)
        return
    end
    if deckTools then
        banner(22,91,916,92,"Woodland")
        section(22,198,916,141)
        section(22,354,916,235)
        label(38,111,410,34,"Deck options"):SetFontObject(fonts.title)
        button(746,111,174,"Back to roster",function() deckTools=false end)
        label(38,210,570,22,gold.."Tactics|r    /    Up to 3 distinct cards")
        for i=1,F.maxTactics do
            local pos=i
            local x=38+(i-1)*295
            local y=245
            local tactic=F.tactics[draftTactics[i]]
            colorAction(button(x,y+4,269,i.."   "..(tactic and tactic[1] or "Empty slot"),function() picker=pos end,tactic and tactic[2]),"tactic")
            label(x+4,y+37,266,37,tactic and tactic[2] or "")
        end
        label(38,367,570,22,gold.."Recipes|r")
        for i,recipe in ipairs(F.recipes) do
            button(38,401+(i-1)*44,243,recipe[1],function()
                draftName=recipe[1]
                draft,draftTactics={unpack(recipe[3])},{unpack(recipe[4])}
                pending,slot,deckTools=nil,1,false
            end,recipe[2])
            label(294,407+(i-1)*44,610,22,recipe[2]):SetFontObject(fonts.muted)
        end
        return
    end
    banner(22,91,592,82,"Woodland")
    section(22,188,592,253)
    section(22,454,592,67)
    section(630,91,316,451)
    section(22,572,924,100)
    library()
    label(38,104,406,34,"Deck Builder"):SetFontObject(fonts.title)
    local filled=0
    for i=1,3 do if draft[i] then filled=filled+1 end end
    label(442,112,151,21,("Creatures   %d / 3"):format(filled)):SetJustifyH("RIGHT")
    label(38,144,549,22,pending and ("Choose a slot for "..F.db.cards[pending].name) or "Select a slot, then choose a creature from the library.")
    for i=1,3 do
        local pos,id=i,draft[i]
        local c=id and F.db.cards[id]
        local valid=id and F.eligibleCreature(id) and F.playable(c)
        local x=38+(i-1)*190
        local tile=face(x+16,201,136,190,id,c,{showcase=true,selected=slot==pos,invalid=id and not valid,place=placed==pos,
            state=id and (valid and ("Slot "..pos) or "Undiscovered") or ("Slot "..pos.."  /  Empty"),
            click=function()
                if pending then equip(pos,pending) else slot=pos end
                F.refresh()
            end})
        if valid then
            tile:SetScript("OnEnter",function(self)
                F.showTooltip(self,"ANCHOR_RIGHT",c.name,fieldCardInfo(id,c))
            end)
            tile:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        if pending then
            label(x,403,168,26,(id==pending and "Already here" or c and ("Replace "..c.name) or "Place in empty slot"))
        else
            button(x,403,168,"Clear slot "..pos,function() draft[pos]=nil slot=pos end,nil,id~=nil)
        end
    end
    placed=nil
    local active=F.synergyPairings(draft)
    local names,details={},{}
    for _,pairing in ipairs(active) do
        local rule=F.synergies[pairing.key]
        names[#names+1]=rule.name
        details[#details+1]=colors.synergy..rule.name.."|r\n"..rule.requirement.."\n"..rule.effect
            .."\n"..synergyMoveNotes(pairing)
    end
    if #details==0 then details[1]="Pair typed creatures to activate synergies. See a card's Synergies page for compatible partners." end
    label(38,467,135,19,gold.."Solo synergies|r"):SetFontObject(fonts.bold)
    label(38,492,552,21,#active>0 and table.concat(names,"  /  ")
        or "Add compatible creatures to unlock team abilities."):SetFontObject(fonts.small)
    local synergyHelp=item("wheel")
    place(synergyHelp,29,455,573,64)
    synergyHelp:EnableMouse(true)
    synergyHelp:EnableMouseWheel(false)
    synergyHelp:SetScript("OnEnter",function(self)
        F.showTooltip(self,"ANCHOR_RIGHT","Solo synergies",table.concat(details,"\n\n"))
    end)
    synergyHelp:SetScript("OnLeave",function() GameTooltip:Hide() end)
    navigation:add(synergyHelp,29,455,573,64,"help")
    button(38,533,190,"Tactics & recipes",function() deckTools=true end,
        "Edit tactic slots or start from a recipe.")
    local canOptimize=#F.owned()>=3
    button(643,589,285,"Optimize solo roster",function()
        local optimized,tactics=F.optimizeDeck()
        if not optimized then return end
        local name,suffix="Optimized Solo",2
        while F.db.decks[name] do
            name="Optimized Solo "..suffix
            suffix=suffix+1
        end
        draftName,draft,draftTactics,pending,slot=name,optimized,tactics,nil,1
        local count=#F.activeSynergies(optimized)
        F.notice=("Draft ready. %d roster %s and three recommended tactics."):format(
            count,count==1 and "synergy" or "synergies")
    end,canOptimize and "Build a solo roster from your owned cards using move strength, mastery perks, and usable synergies. Recommends three tactics for the draft."
        or "Collect at least three distinct creature cards to optimize a roster.",canOptimize)
    label(38,594,77,27,"Deck name"):SetFontObject(fonts.bold)
    edit(115,588,175,draftName,function(s) draftName=s end,"Deck name")
    local ok,why=F.validate(draft,true)
    tone(button(302,588,151,"Save and equip",function()
        local name=draftName:match("^%s*(.-)%s*$")
        if name=="" then F.notice="Give your deck a name." return end
        F.db.decks[name]={unpack(draft)} local saved={}
        for i=1,F.maxTactics do if draftTactics[i] then saved[#saved+1]=draftTactics[i] end end
        F.db.tacticDecks[name]=saved F.db.active=name
        draftName=name F.notice="Equipped "..name F.sound("place")
    end,"Save this draft and equip it for battle.",ok and F.validTactics(draftTactics)),"primary")
    local savedRoster=F.db.decks[draftName]
    local savedTactics=F.tacticDeck(draftName)
    local dirty=not savedRoster
    local tacticIndex=0
    for i=1,3 do
        if savedRoster and savedRoster[i]~=draft[i] then dirty=true end
        if draftTactics[i] then
            tacticIndex=tacticIndex+1
            if savedTactics[tacticIndex]~=draftTactics[i] then dirty=true end
        end
    end
    if tacticIndex~=#savedTactics then dirty=true end
    local saveStatus=(dirty and "Unsaved draft" or "Saved draft").." / Equipped: "..(F.db.active or "None")
    label(38,625,570,19,saveStatus)
    if why then label(38,648,570,20,why):SetFontObject(fonts.small) end
    button(463,588,139,"Saved decks",function() pending,deleteDeck=nil,nil choosingDeck=true end,"Browse, edit, or delete saved decks.")
end
local arena,shown,actor,elapsed=nil,0,1,0
local battleSynergy,autoBattle,aimMove,selectedTarget
local battleSynergyPage=1
local arenaCardWidth,arenaCardHeight=198,143
local arenaHealthWidth=arenaCardWidth-16
local function feedback(event,card,expansion,typed,expanded)
    local effects={}
    for _,key in ipairs(event.setups or {}) do effects[#effects+1]=F.synergies[key].name.." primed" end
    for _,key in ipairs(event.payoffs or {}) do effects[#effects+1]=F.synergies[key].name.." triggered" end
    if (event.haste or 0)>0 then effects[#effects+1]=colors.success.."Haste +"..event.haste.."|r" end
    if (event.delay or 0)>0 then effects[#effects+1]="Rival delayed "..event.delay end
    if event.hit>0 then effects[#effects+1]=colors.damage..event.hit.." damage|r" end
    if event.absorbed>0 then effects[#effects+1]=colors.shield..event.absorbed.." blocked|r" end
    if event.broken>0 then effects[#effects+1]=colors.shield..event.broken.." shield broken|r" end
    if event.tactic then effects[#effects+1]=moveColors.tactic[4]..F.tactics[event.tactic][1].."|r" end
    if event.guard>0 then effects[#effects+1]=colors.shield.."+"..event.guard.." shield|r" end
    if event.focus~=0 then effects[#effects+1]=colors.focus..("%+d Focus|r"):format(event.focus) end
    if (event.drained or 0)>0 then effects[#effects+1]="Drained "..event.drained.." rival Focus" end
    if event.edge==1 then effects[#effects+1]="Strong" elseif event.edge==-1 then effects[#effects+1]="Resisted" end
    if event.mark then effects[#effects+1]="Marked" end
    if event.combo then effects[#effects+1]="Mark combo +3" end
    if #effects==0 then effects[1]="No HP, shield, or Focus change" end
    local move=F.moveName(card,event.move,expansion,typed)
    if event.knockout then effects[#effects+1]=colors.damage.."Knockout|r" end
    local heading=gold..card.name.."|r  /  "..moveColors[event.move][4]..move.."|r"
    if expanded then return heading.."\n\n"..table.concat(effects,"\n") end
    return heading.."    "..table.concat(effects,"   ")
end
local function comboText(window,short)
    local moves=short and window.moves[1] or table.concat(window.moves,", ")
    return F.synergies[window.key].name.." / "..window.card..": "..moves
        ..(window.target and " against "..window.target or "")
end

local function battleHabitat(b)
    for _,key in ipairs(b[b.me].synergies or {}) do
        if key=="whiteout" then
            for _,card in ipairs(b[b.me].cards) do
                local zone=F.speciesOf(card.id)[1]
                if F.hasType(card,"Frost") and zone~="Unknown habitat" then return zone end
            end
        end
    end
    return F.speciesOf(b[3-b.me].cards[1].id)[1]
end
local function outcome(b)
    local won=b.winner==b.me and not b.aborted
    local result=b.aborted and "Duel interrupted" or b.winner==0 and "Draw" or won and "Victory" or "Defeat"
    local first=not b.presented
    b.presented=true
    if first then F.sound(b.aborted and "interrupted" or b.winner==0 and "draw" or won and "victory" or "defeat") end
    local resultArt=b.arena and F.habitatStyle(battleHabitat(b)).art or "Woodland"
    banner(28,95,924,115,resultArt)
    local wash=paper(28,95,924,115,"ArenaVignette",2)
    wash:SetTexCoord(0,1,0,1)
    local resultColor=won and gold or b.aborted and "|cffb2cdf1" or b.winner==0 and "|cffe1d4b4" or "|cffffa5aa"
    local head=label(51,122,878,41,resultColor..result:upper().."|r")
    head:SetJustifyH("CENTER")
    head:SetFontObject(fonts.title)
    local summary=b.aborted or (b.conceded and (b.conceded==b.me and "You conceded." or "Your rival conceded.")) or
        ("Your team "..b[b.me].hp.." HP    /    Rival "..b[3-b.me].hp.." HP    /    "..b.seq.." actions")
    label(52,170,876,29,summary):SetJustifyH("CENTER")
    local blocked,loss=0,0
    for _,e in ipairs(b.events) do
        if e.side==b.me then blocked=blocked+e.absorbed else loss=loss+e.hit end
    end
    local awards=b.awards or {}
    if #awards==0 and #b.events>0 then
        label(52,238,823,40,blocked>0 and ((b.strategy or b.peer or "Your rival").." blocked "..blocked.." damage.") or ("Your team took "..loss.." HP damage."))
    end
    if #awards==0 then
        section(170,276,640,231)
        for i,c in ipairs(b[b.me].cards) do
            face(235+(i-1)*190,299,130,182,c.id,c,{showcase=true,state=not b.solo and c.role or nil})
        end
    end
    local fills,texts,hasPerk={},{},false
    local rewardWidth=#awards==1 and 540 or 240
    local rewardStart=(980-((#awards-1)*300+270))/2+12
    for i,a in ipairs(awards) do
        local x=rewardStart+(i-1)*300
        local single=#awards==1
        local meterX,meterY=single and 352 or x,single and 373 or 445
        if single then
            section(41,221,896,333)
            face(79,240,207,289,a.id,F.db.cards[a.id],{full=true,showcase=true,state="Earned mastery"})
            label(meterX,296,520,35,"Earned mastery"):SetFontObject(fonts.title)
        else
            section(x-12,217,270,342)
            face(x+43,229,144,201,a.id,F.db.cards[a.id],{showcase=true,state="Earned mastery"})
        end
        local cap=F.balance.mastery[F.tier({mastery=a.before})+1] or math.max(20,a.after)
        local start=first and not F.db.staticCards and a.before or a.after
        surface(meterX,meterY,rewardWidth,10,.21,.24,.17)
        fills[i]=surface(meterX,meterY,math.max(1,rewardWidth*math.min(1,start/cap)),10,.87,.60,.22)
        fills[i]:SetDrawLayer("ARTWORK")
        texts[i]=label(meterX,meterY+24,rewardWidth,35,("Mastery %d to %d"):format(a.before,a.after))
        texts[i]:SetFontObject(fonts.bold)
        if a.perk then
            hasPerk=true
            label(meterX,meterY+64,rewardWidth,38,gold.."Perk unlocked  /  "..a.perk.."|r")
        end
    end
    if first and (not F.db.staticCards or hasPerk) then
        local age=0
        panel:SetScript("OnUpdate",function(self,dt)
            age=age+dt
            local t=math.min(1,math.max(0,(age-(won and 1.22 or .15))/(F.db.staticCards and .001 or .50)))
            head:SetAlpha(F.db.staticCards and 1 or .62+.38*math.min(1,age/.22))
            for i,a in ipairs(awards) do
                local cap=F.balance.mastery[F.tier({mastery=a.before})+1] or math.max(20,a.after)
                local value=a.before+(a.after-a.before)*t
                fills[i]:SetWidth(math.max(1,rewardWidth*math.min(1,value/cap)))
                texts[i]:SetText(t==1 and ("Mastery "..a.before.."  ->  "..a.after) or "Mastery "..math.floor(value))
            end
            if t==1 then
                self:SetScript("OnUpdate",nil)
                if hasPerk then F.sound("perk") end
            end
        end)
    end
    section(246,569,590,59)
    if b.solo or b.peer then
        tone(button(265,583,177,"Rematch",function()
            if b.solo then local _,why=F.solo(b.strategy) F.notice=why else F.challenge(b.peer) end
        end,"Play this matchup again."),"primary")
    end
    button(454,583,172,"Edit Deck",function() loadDraft() panel.draftOpened=true pending=nil choosingDeck,deckTools=false,false tab="Decks" end)
    button(638,583,180,"Back to matches",function() F.match=nil F.notice=nil end)
end
local function battle()
    local b,n=F.match,F.net
    if n and n.phase~="play" then
        banner(22,91,916,127,"Woodland")
        label(40,109,610,35,"Friendly duel"):SetFontObject(fonts.title)
        section(22,237,916,149)
        label(42,255,650,27,n.phase=="invited" and ("Invitation from "..n.peer) or ("Waiting for "..n.peer)):SetFontObject(fonts.heading)
        label(42,291,631,22,n.phase=="invited" and "Accept to battle with your equipped roster."
            or "The match starts when the other player accepts."):SetFontObject(fonts.muted)
        if n.phase=="invited" then tone(button(42,335,133,"Accept",F.accept),"primary") end
        button(189,335,143,"Decline / cancel",F.leave)
        return
    end
    if not b then
        banner(22,91,916,121,"Woodland")
        label(40,107,609,44,"Solo Battle"):SetFontObject(fonts.title)
        label(41,161,625,29,"Choose an opponent for your equipped roster.")
        section(22,229,504,309)
        section(544,229,394,309)
        label(38,242,455,25,gold..(F.db.active or "No deck equipped").."|r"):SetFontObject(fonts.heading)
        local deck=F.db.decks[F.db.active] or {}
        for i=1,3 do
            local id=deck[i]
            face(44+(i-1)*160,278,136,190,id,id and F.db.cards[id],{showcase=true,state=id and "Equipped" or "Empty slot"})
        end
        button(38,489,207,"Edit Deck",function()
            loadDraft() panel.draftOpened=true pending=nil choosingDeck,deckTools=false,false tab="Decks"
        end,"Open your equipped roster in the Deck Builder.")
        label(562,242,350,27,"Solo opponents"):SetFontObject(fonts.heading)
        local rosterReady=F.validate(deck,true)
        for i,name in ipairs({"Prowler","Sentinel","Veteran"}) do
            local style=name
            local y=274+(i-1)*84
            local opponent=F.soloOpponents[style]
            banner(560,y,361,75,opponent.art)
            label(573,y+7,330,20,opponent.detail):SetFontObject(fonts.small)
            tone(button(573,y+34,141,name,function()
                local _,why=F.solo(style) F.notice=why history=0
            end,rosterReady and opponent.detail or "Equip a deck with three distinct collected cards first.",rosterReady),"primary")
        end
        section(22,553,504,102)
        section(544,553,394,102)
        label(38,569,353,19,"Friendly duel"):SetFontObject(fonts.heading)
        label(39,594,225,17,"Player name or Name-Realm"):SetFontObject(fonts.muted)
        edit(38,614,237,peer,function(value) peer=value end,"Duel opponent name")
        button(287,614,154,"Challenge",function() F.challenge(peer) end,"Invite a player to a friendly Relay duel.")
        local record=F.db.stats
        label(562,569,350,19,"Local record"):SetFontObject(fonts.heading)
        for i,stat in ipairs({{"Wins",record.wins},{"Losses",record.losses},{"Draws",record.draws}}) do
            local x=562+(i-1)*117
            label(x,592,102,31,tostring(stat[2] or 0)):SetFontObject(fonts.metric)
            label(x,627,102,18,stat[1]):SetFontObject(fonts.muted)
        end
        return
    end
    local p,e=b[b.me],b[3-b.me]
    local result=b.aborted or (b.winner==0 and "Draw" or b.winner and (b.winner==b.me and "Victory" or "Defeat"))
    if arena~=b then
        queued,logOpen,battleSynergy,autoBattle,aimMove,selectedTarget=nil,false,nil,false,nil,nil
        battleSynergyPage=1
        arena,shown,actor,elapsed=b,b.timeline and 0 or b.seq,1,0
    end
    local event=b.events[shown+1]
    local state=event or b
    if b.timeline then
        actor=b.actor
    elseif not event and actor==p.last then actor=p.last%3+1 end
    local friendlySlot=event and (state[b.me].last or 1) or actor
    if b.timeline and event then friendlySlot=event.side==b.me and event.slot or event.targetSlot end
    local friendly=p.cards[friendlySlot]
    local rivalSlot=state[3-b.me].last or 1
    if b.timeline then
        if event then rivalSlot=event.side~=b.me and event.slot or event.targetSlot
        else
            rivalSlot=F.nextRivalSlot(b,b.me) or rivalSlot
        end
    end
    local rival=e.cards[rivalSlot]
    local status=event and (event.side==b.me and "Ally action" or "Rival action") or result or (b.turn==b.me and (autoBattle and "Auto Battle choosing" or "Your turn") or "Rival turn")
    if result and not event then autoBattle=false aimMove=nil outcome(b) return end
    label(22,92,333,24,gold..status.."|r    /    "..(b.strategy or (n and n.peer) or "Friendly duel"))
    label(844,92,114,22,"Turn "..math.min(b.arena and 60 or 48,event and shown+1 or b.seq+(result and 0 or 1))..(b.arena and " / 60" or " / 48")):SetJustifyH("RIGHT")
    local function teamPanel(x,name,team,r,g,blue)
        label(x,120,185,20,name):SetFontObject(fonts.bold)
        label(x+190,120,122,20,team.hp.." / 34 HP"):SetJustifyH("RIGHT")
        local track=item("icon")
        place(track,x,141,312,9)
        track:SetDrawLayer("BACKGROUND")
        track:SetColorTexture(.15,.19,.19,1)
        if team.hp>0 then
            local fill=item("icon")
            place(fill,x,141,312*team.hp/34,9)
            fill:SetDrawLayer("ARTWORK")
            fill:SetColorTexture(r,g,blue,1)
        end
        label(x,157,320,22,colors.shield.."Shield "..team.shield.."/6|r   "..colors.focus.."Focus "..team.focus.."/3|r"
            ..(team.mark and "   "..colors.damage.."Marked +3|r" or ""))
    end
    if b.arena then
        local zone=battleHabitat(b)
        local scenery=F.habitatStyle(zone).art
        local painting=F.arenaPaintings[scenery]
        local backdrop=paper(22,175,660,356,painting or scenery,-1,painting and .81 or .71)
        if painting then backdrop:SetTexCoord(.035,.965,.05,.95) end
        if zone~="" and zone~="Unknown" then
            label(355,94,270,20,gold..zone.."|r"):SetJustifyH("CENTER")
            local fieldNotes=F.areaProfiles[zone]
            if fieldNotes then hoverHelp(355,91,270,20,zone,fieldNotes[2]) end
        end
        local shade=paper(22,175,660,356,"ArenaVignette",0)
        shade:SetTexCoord(0,1,0,1)
        section(22,117,660,55)
        section(698,117,260,163)
        section(698,290,260,241)
        if not (logOpen or battleSynergy) then
            label(36,177,218,16,gold.."Rivals|r"..(b.rivalTactics and "  /  Veteran tactics" or "")):SetFontObject(fonts.strongSmall)
            label(36,366,110,16,gold.."Allies|r"):SetFontObject(fonts.strongSmall)
        end
    else
        section(22,114,336,66)
        section(620,114,336,66)
        teamPanel(34,"Your team",state[b.me],.38,.72,.50)
        teamPanel(632,"Rival",state[3-b.me],.84,.46,.32)
    end
    local synergyDetail
    local allyCombos=F.comboWindows(b,b.me,state)
    local rivalCombos=F.comboWindows(b,3-b.me,state)
    if b.arena then
        label(714,299,220,23,gold.."Team synergies|r"):SetFontObject(fonts.heading)
        if not p.synergies or #p.synergies==0 then
            label(714,334,222,34,colors.muted.."No synergies in this roster|r"):SetFontObject(fonts.small)
        end
    end
    if b.solo and p.synergies and #p.synergies>0 then
        if not b.arena then label(31,404,103,19,gold.."Synergies|r"):SetFontObject(fonts.bold) end
        local pages=math.ceil(#p.synergies/5)
        battleSynergyPage=math.min(battleSynergyPage,pages)
        local first=(battleSynergyPage-1)*5+1
        for i=first,math.min(first+4,#p.synergies) do
            local key=p.synergies[i]
            local rule=F.synergies[key]
            local x=b.arena and 714 or (133+(i-first)*135)
            local y=b.arena and (329+(i-first)*32) or 398
            local title,detail=rule.name,rule.effect
            local ready={}
            for _,window in ipairs(allyCombos) do
                if window.key==key then ready[#ready+1]=comboText(window).."\n"..window.expires end
            end
            local primed=#ready>0
            if primed then detail=detail.."\n\n"..table.concat(ready,"\n\n") end
            local selectedSynergy=battleSynergy==key
            local badge=button(x,y,b.arena and 228 or 128,primed and "|cffb5ecff"..title.."  /  Primed|r" or title,function()
                aimMove,selectedTarget=nil,nil
                if selectedSynergy then battleSynergy=nil else battleSynergy=key logOpen=false end
            end,detail)
            if selectedSynergy or primed then badge:SetBackdropBorderColor(.47,.71,.78,1) end
            if selectedSynergy then
                local roster={}
                for slot,card in ipairs(p.cards) do roster[slot]=card.id end
                for _,pairing in ipairs(F.synergyPairings(roster)) do
                    if pairing.key==key then detail=detail.."\n\n"..synergyMoveNotes(pairing) break end
                end
                synergyDetail={title,detail}
            end
        end
        if pages>1 then
            button(b.arena and 830 or 808,b.arena and 491 or 398,112,battleSynergyPage.." / "..pages.."  >",function()
                battleSynergyPage=battleSynergyPage%pages+1
                battleSynergy=nil
            end,"See more active synergies.")
        end
    end
    local models={}
    if logOpen then
        local logWidth=b.arena and 660 or 929
        local logY=b.arena and 175 or 187
        section(22,logY,logWidth,b.arena and 356 or 185)
        label(40,logY+8,220,22,gold.."Combat log|r"):SetFontObject(fonts.heading)
        cycle(b.arena and 170 or 374,logY+6,128,{"All actions","Ally actions","Rival actions","Synergies"},logFilter,function(i) logFilter,history=i,0 end,
            "Filter the combat log by team or synergy events.")
        cycle(b.arena and 305 or 512,logY+6,132,{"Newest first","Oldest first"},logSort,function(i) logSort,history=i,0 end,"Change the order of combat log entries.")
        local entries={}
        for i=1,event and shown+1 or b.seq do
            local beat=b.events[i]
            if logFilter==1 or (logFilter==2 and beat.side==b.me) or (logFilter==3 and beat.side~=b.me)
                or (logFilter==4 and (beat.setup or beat.payoff)) then entries[#entries+1]=i end
        end
        history=math.min(history,math.max(0,math.floor((#entries-1)/4)*4))
        for row=1,math.min(4,#entries-history) do
            local position=history+row
            local i=entries[logSort==1 and #entries-position+1 or position]
            local beat=b.events[i]
            local y=logY+41+(row-1)*(b.arena and 60 or 32)
            local acting=b[beat.side].cards[beat.slot]
            label(40,y,logWidth-36,b.arena and 54 or 31,colors.muted..i.."|r   "..feedback(beat,acting,b.expansion,b.movesets))
            hoverHelp(38,y,logWidth-32,b.arena and 54 or 30,"Action "..i,feedback(beat,acting,b.expansion,b.movesets,true))
        end
        if #entries==0 then label(40,logY+41,logWidth-36,26,"No actions match.") end
        button(b.arena and 444 or 666,logY+6,109,logSort==1 and "Older" or "Later",function() history=history+4 end,"Open the next page of matching actions.",#entries>history+4)
        button(b.arena and 560 or 785,logY+6,109,logSort==1 and "Newer" or "Earlier",function() history=math.max(0,history-4) end,"Open the previous page.",history>0)
    elseif synergyDetail then
        local detailY=b.arena and 175 or 194
        local detailWidth=b.arena and 660 or 934
        local detailHeight=b.arena and 260 or 102
        section(22,detailY,detailWidth,b.arena and 356 or 167)
        label(44,detailY+20,detailWidth-190,27,synergyDetail[1]):SetFontObject(fonts.heading)
        label(44,detailY+55,detailWidth-52,detailHeight,synergyDetail[2]):SetJustifyV("TOP")
        hoverHelp(44,detailY+55,detailWidth-52,detailHeight,synergyDetail[1],synergyDetail[2])
        button(22+detailWidth-154,detailY+14,130,"Close details",function() battleSynergy=nil end)
    elseif not b.arena then
        paper(29,190,922,173,F.habitatStyle(F.speciesOf(rival.id)[1]).art,0,.60)
        local function battlePortrait(side,card,x,facing)
            section(x,197,242,159)
            local backdrop=F.habitatStyle(F.speciesOf(card.id)[1]).art.."Depth"
            paper(x+3,200,236,124,backdrop,2)
            models[side]=creature(x+8,202,226,120,card.id,facing)
            surface(x+3,325,236,28,.075,.133,.139):SetDrawLayer("BACKGROUND",2)
            label(x+10,332,222,19,gold..card.name.."|r"):SetJustifyH("CENTER")
        end
        battlePortrait(b.me,friendly,36,.95)
        battlePortrait(3-b.me,rival,702,-.95)
        if event then
            local cue=event.move=="S" and "signature" or event.combo and "combo" or event.absorbed>0 and "shield" or event.hit>0 and "hit" or "place"
            local word=({signature="Signature",combo="Mark combo",shield="Shield absorbed",hit="Clean hit",place=moveTypes[event.move]})[cue]
            if event.combo and cue~="combo" then word=word.." / Mark combo" end
            local tint=({shield="|cff9ad9f0",combo="|cfff7ad6e",signature="|cffe5b2f7",hit="|cfffae5bc"})[cue] or gold
            if event.payoff then word=F.synergies[event.payoff].name tint=({pack="|cffffd17a",whiteout="|cffb5ecff",tunnel="|cffeca77a"})[event.payoff] or gold end
            if b.timeline then
                label(298,308,384,22,tint..word.."|r"):SetJustifyH("CENTER")
            else
                section(342,220,296,103)
                local badge=label(351,234,278,34,tint..word.."|r")
                badge:SetFontObject(fonts.heading)
                badge:SetJustifyH("CENTER")
                local shieldText=event.broken>0 and (event.broken.." shield broken") or (event.absorbed.." blocked")
                label(351,276,278,33,event.hit.." HP loss / "..shieldText):SetJustifyH("CENTER")
            end
            if not F.db.staticCards then
                for side,m in pairs(models) do
                    if m.beat~=event then
                        m:SetAnimation(side==event.side and (event.move=="S" and 53 or event.move=="B" and 1 or 16) or 20)
                        m.beat=event
                    end
                end
            end
        else
            for _,m in pairs(models) do if m.beat then m:SetAnimation(0) m.beat=nil end end
        end
    end
    local animateTimeline,animateCards
    local playbackDuration=F.db.staticCards and .25 or .78
    if b.solo and b.timeline and (b.arena or not (logOpen or synergyDetail)) then
        local railX,railY,stride=b.arena and 212 or 302,b.arena and 123 or 264,b.arena and 72 or 63
        local order=event and event.timeline or F.turnTimeline(b)
        local title=label(b.arena and 36 or 298,b.arena and 123 or 227,b.arena and 166 or 384,22,b.arena and gold.."Initiative|r" or "Turn timeline")
        if not b.arena then title:SetJustifyH("CENTER") end
        title:SetFontObject(fonts.heading)
        if b.arena then label(36,146,166,15,colors.muted.."Next to act|r"):SetFontObject(fonts.small) end
        local slides={}
        local previous=b.events[shown]
        local oldOrder=event and (previous and previous.timeline or b.initialTimeline)
        local oldSlots={}
        if oldOrder then
            for i=2,#oldOrder do
                local key=oldOrder[i].key
                local slots=oldSlots[key] or {}
                oldSlots[key]=slots
                slots[#slots+1]=i
            end
        end
        local details={}
        for i,turn in ipairs(order) do
            local x=railX+(i-1)*stride
            local tile=surface(x,railY,58,40,.073,.123,.134)
            local edge=surface(x,railY,58,2,.27,.34,.35)
            edge:SetDrawLayer("ARTWORK")
            local card=b[turn.side].cards[turn.slot]
            local color=turn.side==b.me and "|cff9ee2bb" or "|cfff0a89e"
            local portrait
            if b.arena then
                portrait=creature(x+4,railY+2,50,36,card.id,turn.side==b.me and .38 or -.38,.48)
                if portrait.SetPaused then portrait:SetPaused(true) end
            end
            local caption=label(x+2,railY+5,54,31,color..card.name.."|r")
            if portrait then
                local function updateCaption()
                    if not portrait:IsVisible() then return end
                    local file=portrait.GetModelFileID and portrait:GetModelFileID()
                    caption:SetShown(type(file)~="number" or file==0)
                end
                portrait:SetScript("OnModelLoaded",updateCaption)
                updateCaption()
            end
            caption:SetJustifyH("CENTER")
            caption:SetFontObject(fonts.small)
            caption:SetMaxLines(2)
            if i==1 then edge:SetColorTexture(.96,.74,.38,1)
            elseif b.arena and turn.side==b.me then edge:SetColorTexture(.27,.59,.54,1)
            elseif b.arena then edge:SetColorTexture(.66,.33,.29,1) end
            local from=table.remove(oldSlots[turn.key] or {},1)
            slides[i]={edge=edge,tile=tile,caption=caption,portrait=portrait,x=x,from=railX+((from or #order)-1)*stride,fresh=not from}
            details[i]=("%d. %s (%s, Speed %d)"):format(i,card.name,turn.side==b.me and "Ally" or "Rival",F.cardSpeed(card))
        end
        if event and not F.db.staticCards then
            local progress=surface(railX,b.arena and 166 or 251,1,2,.41,.78,.73)
            animateTimeline=function(age)
                local t=math.min(1,age/.36)
                local ease=1-(1-t)^3
                for _,slide in ipairs(slides) do
                    local x=slide.from+(slide.x-slide.from)*ease
                    slide.edge:ClearAllPoints()
                    slide.tile:ClearAllPoints()
                    slide.caption:ClearAllPoints()
                    place(slide.edge,x,railY,58,2)
                    place(slide.tile,x,railY,58,40)
                    place(slide.caption,x+2,railY+5,54,31)
                    local alpha=slide.fresh and ease or 1
                    slide.edge:SetAlpha(alpha)
                    slide.tile:SetAlpha(alpha)
                    slide.caption:SetAlpha(alpha)
                    if slide.portrait then
                        slide.portrait:ClearAllPoints()
                        place(slide.portrait,x+4,railY+2,50,36)
                        slide.portrait:SetAlpha(alpha)
                    end
                end
                progress:SetWidth(math.max(1,(5*stride+58)*math.min(1,age/playbackDuration)))
            end
            animateTimeline(elapsed)
        end
        if not b.arena and event and ((event.haste or 0)>0 or (event.delay or 0)>0) then
            local team=event.side==b.me and "Your team" or "Rival"
            local message=event.haste>0 and (team.." advanced its creature by "..event.haste.." ticks") or (team.." delayed a rival by "..event.delay.." ticks")
            label(298,334,384,19,message):SetJustifyH("CENTER")
        elseif not event and not b.arena then
            label(298,318,384,18,"Speed effects can shift the next turns."):SetJustifyH("CENTER")
        end
        hoverHelp(b.arena and 26 or 298,b.arena and 118 or 224,b.arena and 652 or 384,b.arena and 52 or 130,"Turn timeline",
            table.concat(details,"\n").."\n\nThe timeline shows normal recovery. Haste from moves or synergies advances an ally, and delay pushes a rival back.")
    end
    if b.arena then
        local aiming=aimMove and not (event or result or autoBattle) and b.turn==b.me
        local armed=aiming and F.moveName(friendly,aimMove,b.expansion,b.movesets)
        local prompt=armed and (armed.." armed / Choose a rival")
            or (b.turn==b.me and friendly.name.." is ready" or "Waiting for rival")
        local action=prompt
        if not event and not aiming then
            local window=allyCombos[1] or rivalCombos[1]
            if window then
                action=(allyCombos[1] and "Your combo: " or "Rival combo: ")..comboText(window,true)
                local details={}
                for _,group in ipairs({{"Allies",allyCombos},{"Rivals",rivalCombos}}) do
                    for _,open in ipairs(group[2]) do
                        details[#details+1]=group[1].." / "..comboText(open).."\n"..open.expires
                    end
                end
                hoverHelp(24,536,932,21,"Open combo windows",table.concat(details,"\n\n"))
            end
        end
        if event then
            local acting=b[event.side].cards[event.slot]
            local parts={acting.name.." used "..F.moveName(acting,event.move,b.expansion,b.movesets)}
            if event.tactic then parts[#parts+1]=F.tactics[event.tactic][1] end
            if event.payoff then parts[#parts+1]=gold..F.synergies[event.payoff].name.."|r"
            elseif event.setup then parts[#parts+1]=F.synergies[event.setup].name.." primed" end
            if event.broken>0 then parts[#parts+1]=colors.shield..event.broken.." shield broken|r" end
            if event.hit>0 then parts[#parts+1]=colors.damage..event.hit.." damage|r" end
            if (event.haste or 0)>0 then parts[#parts+1]="Haste +"..event.haste end
            if (event.delay or 0)>0 then parts[#parts+1]="Delay +"..event.delay end
            if event.knockout then parts[#parts+1]=colors.damage.."Knockout|r" end
            action=table.concat(parts,"  /  ")
        end
        local stageText=label(26,535,928,23,action)
        stageText:SetFontObject(fonts.small)
        stageText:SetJustifyH("CENTER")
        local function commitTarget(target)
            if not F.legal(b,b.me,actor,aimMove,queued,target) then return end
            local move,tactic=aimMove,queued
            aimMove,queued,history,selectedTarget=nil,nil,0,nil
            F.act(actor,move,tactic,target)
        end
        if aiming then
            button(373,658,105,"Cancel target",function() aimMove,selectedTarget=nil,nil end)
            if selectedTarget then
                tone(button(485,658,108,"Confirm target",function() commitTarget(selectedTarget) end),"primary")
            end
        end
        local attacker,targetCard
        if not (logOpen or synergyDetail) then
            for side=1,2 do
                for i,card in ipairs(b[side].cards) do
                    local target=i
                    local unit=state[side].units[i]
                    local isRival=side~=b.me
                    local active=event and event.side==side and event.slot==i or
                        (not event and b.turn==side and b.actor==i)
                    local valid=aiming and isRival and unit.hp>0
                    local x,y=36+(i-1)*216,isRival and 195 or 384
                    local widget=face(x,y,arenaCardWidth,arenaCardHeight,card.id,card,{arenaFace=true,unit=unit,selected=active,targetable=valid,rival=isRival,muted=unit.hp<=0,
                        click=valid and function() commitTarget(target) end or nil})
                    local impacted=event and event.side~=side and event.targetSlot==i and
                        (event.hit>0 or event.absorbed>0 or event.broken>0 or event.mark or event.delay>0)
                    if event and active then attacker={widget,x,y,side} end
                    if impacted then targetCard={widget,x,y,unit} end
                    local model=widget.model
                    local animating=event and not F.db.staticCards and (active or impacted)
                    if animating and model.arenaBeat~=event then
                        model:SetAnimation(active and (event.move=="S" and 53 or event.move=="B" and 1 or 16) or 20)
                        model.arenaBeat=event
                    elseif not animating and model.arenaBeat then
                        model:SetAnimation(0)
                        model.arenaBeat=nil
                    end
                    if not valid then
                        widget:SetScript("OnEnter",function(self)
                            local details={gold.."Type|r  "..F.typeBadges(card.id,card,14,true),
                                colors.success..("Health  %d / %d|r"):format(unit.hp,unit.maxHP),
                                gold.."Speed|r  "..F.cardSpeed(card)}
                            if unit.shield>0 then details[#details+1]=colors.shield.."Shield  "..unit.shield.."|r" end
                            if unit.mark then details[#details+1]=colors.damage.."Marked|r  The next hit deals 3 extra damage." end
                            F.showTooltip(self,"ANCHOR_RIGHT",card.name,table.concat(details,"\n"))
                        end)
                        widget:SetScript("OnLeave",function() GameTooltip:Hide() end)
                    end
                    if valid then
                        navigation.preferred=navigation.preferred or widget
                        local preview=F.preview(b,b.me,actor,aimMove,queued,target)
                        if preview then
                            local message={card.name,preview.hit.." damage"}
                            if preview.knockout then message[#message+1]="Knockout" end
                            if preview.broken>0 then message[#message+1]="Breaks "..preview.broken.." shield" end
                            if preview.absorbed>0 then message[#message+1]=preview.absorbed.." absorbed" end
                            if preview.delay>0 then message[#message+1]="Delay +"..preview.delay end
                            for _,key in ipairs(preview.payoffs) do message[#message+1]=F.synergies[key].name end
                            local function showPreview()
                                stageText:SetText(table.concat(message," / "))
                                local payoff=preview.payoffs[1]
                                widget.targetCue:SetText(payoff and F.synergies[payoff].name
                                    or preview.knockout and "Knockout" or preview.broken>0 and ("Breaks "..preview.broken.." shield")
                                    or preview.absorbed>0 and preview.hit==0 and "Blocked" or (preview.hit.." damage"))
                                widget.targetCue:Show()
                                widget.targetPlate:Show()
                                if preview.hit>0 then
                                    widget.healthGhost:SetPoint("BOTTOMLEFT",widget,"BOTTOMLEFT",8+arenaHealthWidth*(unit.hp-preview.hit)/unit.maxHP,4)
                                    widget.healthGhost:SetSize(arenaHealthWidth*preview.hit/unit.maxHP,16)
                                    widget.healthGhost:SetColorTexture(.86,.34,.27,.85)
                                    widget.healthGhost:Show()
                                end
                            end
                            local selectTarget=button(x+12,339,arenaCardWidth-24,selectedTarget==target and "Target selected" or "Preview target",function()
                                selectedTarget=target
                            end,"Preview the move against "..card.name.." before confirming.")
                            if selectedTarget==target then
                                tone(selectTarget,"primary")
                                widget:SetBackdropBorderColor(.98,.79,.46,1)
                                showPreview()
                            end
                            widget:SetScript("OnEnter",function()
                                if not selectedTarget or selectedTarget==target then showPreview() end
                            end)
                            widget.fdPadPreview=showPreview
                            local function clearPreview()
                                if selectedTarget~=target then
                                    stageText:SetText(prompt)
                                    widget.healthGhost:Hide()
                                    widget.targetCue:Hide()
                                    widget.targetPlate:Hide()
                                end
                            end
                            widget.fdPadEndPreview=clearPreview
                            widget:SetScript("OnLeave",clearPreview)
                        end
                    end
                end
            end
        end
        if event and not F.db.staticCards and attacker then
            animateCards=function(age)
                local pulse=math.sin(math.pi*math.min(1,age/.38))
                local card=attacker[1]
                card:ClearAllPoints()
                place(card,attacker[2],attacker[3]+pulse*(attacker[4]==b.me and -4 or 4),arenaCardWidth,arenaCardHeight)
                if targetCard then
                    local hit=targetCard[1]
                    hit:ClearAllPoints()
                    place(hit,targetCard[2]+math.sin(age*55)*pulse*4,targetCard[3],arenaCardWidth,arenaCardHeight)
                    local unit=targetCard[4]
                    local progress=math.min(1,math.max(0,(age-.13)/.28))
                    local hp=unit.hp+event.hit*(1-progress)
                    hit.health:SetShown(hp>0)
                    hit.health:SetWidth(math.max(1,arenaHealthWidth*hp/unit.maxHP))
                    hit.healthCaption:SetText(hp>0 and ("%d / %d HP"):format(math.ceil(hp),unit.maxHP) or "Knocked out")
                    if unit.hp==0 then hit:SetAlpha(.61+.39*(1-progress)) end
                end
            end
            animateCards(elapsed)
        end
    else
        local latest=event or b.events[shown]
        if latest then
            local card=b[latest.side].cards[latest.slot]
            local recap=(latest.side==b.me and "Ally" or "Rival").." / "..card.name.." / "..F.moveName(card,latest.move,b.expansion,b.movesets)
            label(31,371,914,19,recap):SetFontObject(fonts.small)
            hoverHelp(30,368,920,26,"Last action",feedback(latest,card,b.expansion,b.movesets,true))
        else
            label(31,371,914,19,"Choose a ready ally, then a move."):SetFontObject(fonts.small)
        end
        section(22,437,315,146)
        for i,c in ipairs(p.cards) do
            local pos=i
            local resting=not b.timeline and i==state[b.me].last
            face(29+(i-1)*101,442,93,135,c.id,c,{selected=i==actor,muted=resting,
                state=b.timeline and ((not event and b.turn==b.me and i==actor and "Acting / " or "").."Speed "..F.cardSpeed(c)) or (resting and "Resting" or i==actor and "Selected" or "Ready"),
                click=not (b.timeline or event or result or resting) and function() actor=pos F.refresh() end or nil})
        end
    end
    if b.arena then
        section(22,563,936,80)
        label(36,578,128,22,colors.focus..("Focus %d / 3|r"):format(state[b.me].focus)):SetFontObject(fonts.heading)
        for i=1,3 do
            local filled=i<=state[b.me].focus
            local pip=surface(37+(i-1)*31,607,25,3,filled and .89 or .17,filled and .67 or .23,filled and .33 or .32)
            pip:SetDrawLayer("ARTWORK")
        end
    end
    for j,m in ipairs(F.actions(b.movesets)) do
        local move=m
        local x=b.arena and (164+(j-1)*196) or (342+(j-1)*207)
        local width=188
        local legal,reason=F.legal(b,b.me,actor,move,queued)
        local preview=not event and legal and F.preview(b,b.me,actor,move,queued)
        local name=F.moveName(friendly,move,b.expansion,b.movesets)
        local desc=F.moveDescription(friendly,move,b.expansion,b.movesets)
        local definition=F.moveDefinition(friendly,move,b.movesets)
        if not b.arena then section(x,437,199,146) end
        local cues,details={},{}
        if preview then
            for _,kind in ipairs({"payoffs","setups"}) do
                for _,key in ipairs(preview[kind] or {}) do
                    local rule=F.synergies[key]
                    local verb=kind=="payoffs" and "Triggers " or "Primes "
                    cues[#cues+1]=verb..rule.name
                    details[#details+1]=verb..rule.name..": "..rule.effect
                end
            end
        end
        local speed,speedLabel
        if b.solo and b.timeline and not b.movesets then
            local haste,delay=F.speedEffect(friendly,move,p.braced)
            if haste>0 then speedLabel="Haste +"..haste speed="This creature recovers "..haste.." ticks sooner."
            elseif delay>0 then speedLabel="Delay +"..delay speed="The next rival creature moves "..delay.." ticks later." end
        end
        local tip=moveColors[move][4]..moveTypes[move].."|r\n"..desc
        if speed then tip=tip.."\n"..colors.success..speed.."|r" end
        if not legal and reason then tip=tip.."\n\n"..colors.damage..reason.."|r" end
        if #details>0 then tip=tip.."\n\n"..colors.synergy.."Synergies|r\n"..table.concat(details,"\n") end
        local moveButton=colorAction(button(x+(b.arena and 0 or 8),b.arena and 577 or 451,b.arena and width or 183,
            moveColors[move][4]..name.."|r",function()
                local tactic=queued
                selectedTarget=nil
                local targeted=F.requiresTarget(b,move,tactic,b.me,actor)
                if targeted then
                    if aimMove==move then aimMove=nil else aimMove=move end
                    logOpen,battleSynergy=false,nil
                else
                    aimMove,queued,history=nil,nil,0
                    F.act(actor,move,tactic)
                end
            end,tip,legal and not event and not autoBattle),move,legal and not event and not autoBattle,aimMove==move)
        if not (aimMove or event or autoBattle or navigation.preferred) and legal then
            navigation.preferred=moveButton
        end
        if aimMove==move then
            moveButton:SetBackdropColor(.53,.36,.16,1)
            moveButton:SetBackdropBorderColor(.93,.72,.42,1)
        end
        if b.arena then
            local detail=event and "Resolving" or autoBattle and "Auto Battle" or not legal and reason
                or definition and (definition.focus<0
                    and ("%s / Needs %d Focus"):format(moveTypes[move],-definition.focus)
                    or ("%s / +%d Focus"):format(moveTypes[move],preview and preview.focus or definition.focus))
                or move=="S" and "Requires 2 Focus" or move=="B" and "Self shield / +Focus" or "Target rival / +Focus"
            local cue=label(x,607,width,23,detail)
            cue:SetFontObject(fonts.strongSmall)
            cue:SetJustifyH("CENTER")
            cue:SetMaxLines(1)
        else
        local forecast=event and "Resolving turn" or reason
        if preview then
            local summary={}
            if preview.hit>0 then summary[#summary+1]=preview.hit.." HP loss" end
            if preview.broken>0 then summary[#summary+1]=preview.broken.." shield broken" end
            if preview.absorbed>0 then summary[#summary+1]=preview.absorbed.." blocked" end
            if #summary==0 then summary[1]="No HP damage" end
            forecast=table.concat(summary," / ").."\n"..("%+d shield / %+d Focus"):format(preview.guard,preview.focus)
        end
        label(x+9,485,181,15,moveColors[move][4]..moveTypes[move].."|r"):SetFontObject(fonts.small)
        label(x+9,509,181,40,forecast):SetFontObject(fonts.bold)
        if speed then table.insert(cues,1,preview and preview.timeline and preview.timeline[1].side==b.me and "Speed / You move next" or speedLabel) end
        if #cues>0 then
            local more=#cues>1 and (" +"..(#cues-1)) or ""
            label(x+9,554,181,19,gold..cues[1]..more.."|r"):SetFontObject(fonts.bold)
        end
        end
    end
    if b.arena then
        label(714,126,228,23,gold.."Tactics|r"):SetFontObject(fonts.heading)
        local selected=queued and b.hand and F.tactics[b.hand[queued]]
        local instruction=selected and ("Queued: "..selected[1])
            or b.hand and #b.hand>0 and "Choose one to play with your move."
            or "No tactics in hand."
        label(714,252,226,18,colors.muted..instruction.."|r"):SetFontObject(fonts.small)
    end
    if b.hand then
        if not b.arena then
            section(22,598,936,50)
            local tactic=F.tactics[b.hand[queued]]
            label(34,615,280,20,gold.."Tactics|r"..(tactic and " / "..tactic[1] or ""))
        end
        for i,id in ipairs(b.hand) do
            local pos=i
            local x=b.arena and 714 or (341+(i-1)*207)
            local y=b.arena and (153+(i-1)*32) or 609
            local available=not event and not autoBattle and (not b.arena or b.turn==b.me)
            local w=button(x,y,b.arena and 228 or 198,F.tactics[id][1],function()
                queued=queued~=pos and pos or nil
                aimMove,selectedTarget=nil,nil
            end,F.tactics[id][2],available)
            colorAction(w,"tactic",available,queued==i)
        end
    end
    button(29,658,155,logOpen and "Hide combat log" or "Show combat log",function() logOpen=not logOpen battleSynergy,aimMove,selectedTarget=nil,nil,nil end,"Review completed actions, damage, and synergy triggers.")
    button(194,658,173,fast and "Playback: fast" or "Playback: normal",function() fast=not fast end,"Change playback speed without changing battle rules.")
    if b.solo then
        local auto=button(600,658,188,autoBattle and "Pause Auto Battle" or "Auto Battle",function()
            autoBattle=not autoBattle
            queued,aimMove,selectedTarget=nil,nil,nil
        end,"Let the AI choose moves and tactics for this Solo Battle. Pause at any time to take over.",not result)
        if autoBattle then auto:SetBackdropBorderColor(.45,.72,.61,1) end
    end
    tone(button(802,658,148,"Concede",function() shown=b.seq elapsed=0 F.leave() end,"End this match and record a loss.",not result),"danger")
    if event then
        if not event.sounded then
            event.sounded=true
            local synergyCue=({pack="pack",tunnel="tunnel",whiteout="whiteout"})[event.payoff or ""]
            F.sound(synergyCue or (event.payoff or event.combo) and "combo" or event.move=="S" and "signature" or event.absorbed>0 and "shield" or event.hit>0 and ({"hit","hit2","hit3"})[shown%3+1] or "shield")
        end
        panel:SetScript("OnUpdate",function(_,dt)
            elapsed=elapsed+dt*(fast and 3 or 1)
            if animateTimeline then animateTimeline(elapsed) end
            if animateCards then animateCards(elapsed) end
            if elapsed>=playbackDuration then
                shown=shown+1 elapsed=0 F.refresh()
            end
        end)
    elseif autoBattle and b.solo and not result and b.turn==b.me then
        local thinking=0
        panel:SetScript("OnUpdate",function(self,dt)
            thinking=thinking+dt
            if thinking<(fast and .12 or .36) then return end
            self:SetScript("OnUpdate",nil)
            if F.match~=b or not autoBattle then return end
            local slot,move,tactic,target=F.ai(b,"Balanced",true)
            if slot then
                queued,history=nil,0
                F.act(slot,move,tactic,target)
            else
                autoBattle=false
                F.notice="Auto Battle paused: no legal move."
                F.refresh()
            end
        end)
    end
end
local mainTabs={"Collection","Decks","Battle"}

local function openTab(dest)
    if dest~=tab then
        for _,box in ipairs(pools.edit or {}) do box:ClearFocus() end
    end
    settingsOpen=false
    picker=nil deckTools,choosingDeck=false,false tab=dest confirm=nil F.notice=nil pending=nil deleteDeck=nil
    if dest=="Decks" and panel.draftOpened~=true then loadDraft() panel.draftOpened=true end
end

local function switchTab(delta)
    if textEntry then return end
    for i,name in ipairs(mainTabs) do
        if name==tab then
            openTab(mainTabs[(i-1+delta)%#mainTabs+1])
            F.refresh()
            return
        end
    end
end

local function controllerBack()
    if textEntry then textEntry=nil
    elseif settingsOpen then settingsOpen=false
    elseif tab=="Decks" and deleteDeck then deleteDeck=nil
    elseif tab=="Decks" and choosingDeck then choosingDeck=false
    elseif tab=="Decks" and picker then picker=nil
    elseif tab=="Decks" and deckTools then deckTools=false
    elseif tab=="Decks" and pending then pending=nil
    elseif tab=="Battle" and F.match and aimMove then aimMove,selectedTarget=nil,nil
    elseif tab=="Battle" and F.match and logOpen then logOpen=false
    elseif tab=="Battle" and F.match and battleSynergy then battleSynergy=nil
    elseif tab=="Battle" and F.match and F.match.presented then F.match,F.notice=nil,nil
    elseif tab=="Collection" and journalView~="cards" then journalView="cards"
    elseif tab=="Collection" and confirm then confirm=nil
    elseif tab=="Collection" and inspectorView=="Field notes" then inspectorView="Overview"
    elseif tab=="Collection" and showCollectionFilters then showCollectionFilters=false
    else panel:Hide() return end
    F.refresh()
end

local function navigationContext()
    if textEntry then return "text" end
    if settingsOpen then return "settings" end
    if tab=="Decks" then
        if choosingDeck then return "saved" end
        if picker then return "tactic-picker" end
        return deckTools and "deck-tools" or "builder"
    end
    if tab=="Battle" then
        if aimMove and F.match and not F.match.winner then return "target" end
        if F.match and F.match.winner then return "results" end
        if F.net and F.net.phase~="play" then return "duel-invite" end
        if F.match then
            return logOpen and "combat-log" or battleSynergy and "battle-synergy" or "battle"
        end
        return "matches"
    end
    return "journal:"..journalView..":"..inspectorView..":"..notesPage
end

local function drawTextEntry(width)
    local entry=textEntry
    local x=math.floor((width-680)/2)
    section(x,117,680,477)
    label(x+34,140,610,34,entry.title):SetFontObject(fonts.title)
    section(x+32,192,616,56)
    local shown=entry.value~="" and entry.value or "(empty)"
    label(x+46,204,588,39,shown):SetFontObject(fonts.body)
    local rows={"1234567890","qwertyuiop","asdfghjkl","zxcvbnm-.'","@_"}
    for r,letters in ipairs(rows) do
        if entry.upper then letters=letters:upper() end
        for i=1,#letters do
            local letter=letters:sub(i,i)
            button(x+34+(i-1)*61,270+(r-1)*47,54,letter,function()
                if #entry.value<80 then entry.value=entry.value..letter end
            end)
        end
    end
    button(x+157,458,102,"Space",function()
        if #entry.value<80 then entry.value=entry.value.." " end
    end)
    button(x+268,458,105,entry.upper and "Lowercase" or "Uppercase",function() entry.upper=not entry.upper end)
    button(x+382,458,115,"Backspace",function()
        entry.value=entry.value:gsub("[\0-\127\194-\244][\128-\191]*$","")
    end)
    button(x+506,458,103,"Clear",function() entry.value="" end)
    button(x+34,532,120,"Cancel",function() textEntry=nil end)
    navigation.submit=tone(button(x+510,532,120,"Done",function()
        textEntry=nil
        entry.apply(entry.value)
    end),"primary")
end

function F.refresh()
    if not panel or not panel:IsShown() then return end
    panel:SetScript("OnUpdate",nil)
    local fighting=tab=="Battle" and F.match and (not F.net or F.net.phase=="play")
    local width,height=fighting and 980 or 960,fighting and 720 or 719
    panel:SetSize(width,height)
    local fit=math.min((UIParent:GetWidth()-16)/width,(UIParent:GetHeight()-16)/height)
    local preferred=F.db.largeUI and math.max(1.55,math.min(2.25,fit*.85))
        or math.max(1.12,math.min(1.42,fit*.68))
    panel:SetScale(math.min(fit,preferred))
    used={}
    navigation:begin(navigationContext())
    if F.db.opaqueUI then
        local backing=paper(0,0,width,height,"JournalOpaque",-4)
        backing:SetTexCoord(0,1,0,1)
    end
    local shell=paper(0,0,width,height,"JournalShell",-3)
    shell:SetTexCoord(0,1,0,1)
    surface(22,69,width-44,1,.43,.56,.69):SetAlpha(.28)
    section(214,19,382,43)
    section(width-178,19,166,43)
    paper(23,22,27,27,"Compass",0)
    label(60,23,151,37,gold.."FeralDeck|r"):SetFontObject(fonts.brand)
    if textEntry then
        drawTextEntry(width)
    else
        for i,name in ipairs(mainTabs) do
            local dest=name
            local x=221+(i-1)*126
            local display=({Collection="Field Journal",Decks="Deck Builder"})[name] or name
            local w=button(x,26,115,display,function() openTab(dest) end)
            if tab==name and not settingsOpen then
                tone(w,"active")
                surface(x+40,54,35,2,.86,.68,.40):SetDrawLayer("ARTWORK")
            else
                w:SetBackdropColor(.16,.22,.30,.34)
                w:SetBackdropBorderColor(.49,.61,.74,.13)
            end
        end
        local settingsButton=button(width-171,26,119,settingsOpen and "Back to "..(tab=="Collection" and "Journal" or tab) or "Settings",function()
            settingsOpen=not settingsOpen
            for _,box in ipairs(pools.edit or {}) do box:ClearFocus() end
        end,"Display, sound, motion, and panel opacity.")
        if settingsOpen then
            tone(settingsButton,"active")
            banner(22,91,width-44,114,"Woodland")
            label(42,107,482,37,"Settings"):SetFontObject(fonts.title)
            label(43,158,482,24,"Display, motion, and audio"):SetFontObject(fonts.muted)
            local preferences={
                {"Motion","Controls card reveals, model movement, and combat animation.",
                    F.db.staticCards and "Motion: reduced" or "Motion: full",
                    function() F.db.staticCards=not F.db.staticCards end},
                {"Sound","Plays all cues, rewards only, or mutes the addon.",
                    "Sound: "..F.db.audioMode,function()
                        F.db.audioMode=({Full="Rewards Only",["Rewards Only"]="Off",Off="Full"})[F.db.audioMode]
                        F.db.sounds=F.db.audioMode~="Off"
                    end},
                {"Interface size","Fit adapts to the window. Large uses more of the available space.",
                    F.db.largeUI and "Size: large" or "Size: fit",
                    function() F.db.largeUI=not F.db.largeUI end},
                {"Window background","Choose translucent glass or a solid background for busy scenes.",
                    F.db.opaqueUI and "Background: opaque" or "Background: glass",
                    function() F.db.opaqueUI=not F.db.opaqueUI end},
                {"Controller navigation","Use the D-pad and face buttons while FeralDeck is open.",
                    F.db.controllerNav~=false and "Controller: on" or "Controller: off",
                    function()
                        F.db.controllerNav=F.db.controllerNav==false
                        if not F.db.controllerNav then navigation:mouse() end
                    end},
            }
            local cardWidth=(width-58)/2
            for i,setting in ipairs(preferences) do
                local x=22+(i-1)%2*(cardWidth+14)
                local y=222+math.floor((i-1)/2)*142
                section(x,y,cardWidth,124)
                label(x+17,y+13,cardWidth-34,22,setting[1]):SetFontObject(fonts.heading)
                label(x+17,y+44,cardWidth-34,34,setting[2]):SetFontObject(fonts.muted)
                tone(button(x+17,y+84,197,setting[3],setting[4],setting[2]),"active")
            end
        elseif tab=="Collection" then collection() elseif tab=="Decks" then decks() else battle() end
    end
    if not textEntry then navigation:add(closeButton,width-42,26,26,26,"close") end
    if F.notice then
        section(22,height-33,width-44,25)
        local notice=label(33,height-29,width-66,21,F.notice)
        notice:SetFontObject(fonts.bold)
        notice:SetMaxLines(1)
    end
    for kind,pool in pairs(pools) do for i=(used[kind] or 0)+1,#pool do pool[i]:Hide() end end
    navigation:finish(F.notice~=nil)
end
local function toggle()
    if not panel then
        panel=CreateFrame("Frame","FeralDeckPanel",UIParent,"BackdropTemplate")
        panel:SetSize(698,560) panel:SetPoint("CENTER")
        panel:SetScale(math.min(1,(UIParent:GetWidth()-16)/698,(UIParent:GetHeight()-16)/560))
        panel:SetFrameStrata("DIALOG") panel:EnableMouse(true)
        panel:SetMovable(true) panel:SetClampedToScreen(true) panel:RegisterForDrag("LeftButton")
        panel:SetScript("OnDragStart",panel.StartMoving) panel:SetScript("OnDragStop",panel.StopMovingOrSizing)
        navigation=F.controllerNavigation(panel,controllerBack,switchTab)
        panel:SetScript("OnHide",function(self)
            textEntry=nil
            self:SetScript("OnUpdate",nil)
            navigation:hide()
        end)
        closeButton=CreateFrame("Button",nil,panel,"BackdropTemplate")
        closeButton:SetSize(26,26)
        closeButton:SetPoint("TOPRIGHT",-16,-26)
        closeButton:SetBackdrop({bgFile=F.media.."GlassButton.tga"})
        closeButton:SetBackdropColor(.12,.175,.24,.94)
        closeButton:SetNormalFontObject(fonts.bold)
        closeButton:SetHighlightFontObject(fonts.hover)
        closeButton:SetText("x")
        closeButton:SetScript("OnClick",function() panel:Hide() end)
        table.insert(UISpecialFrames,"FeralDeckPanel")
        panel:Hide()
    end
    if panel:IsShown() then panel:Hide() else panel:Show() F.refresh() end
end
local function refreshKillCredit()
    F.refreshOwnershipPlates()
    if tab=="Collection" then F.refresh() end
end
local killWatchers={}
local function watchKillUnit(unit)
    F.watchKillUnit(unit)
    if F.checkKillUnit(unit) then refreshKillCredit() end
    local watcher=killWatchers[unit]
    if not watcher then
        watcher=CreateFrame("Frame")
        if not watcher.RegisterUnitEvent then return end
        killWatchers[unit]=watcher
        watcher:SetScript("OnEvent",function()
            if F.db and F.checkKillUnit(unit) then refreshKillCredit() end
        end)
    end
    for _,event in ipairs({"UNIT_HEALTH","UNIT_FLAGS","UNIT_THREAT_SITUATION_UPDATE","UNIT_TARGET"}) do
        watcher:RegisterUnitEvent(event,unit)
    end
end
local function unwatchKillUnit(unit)
    if not killWatchers[unit] then return end
    killWatchers[unit]:UnregisterAllEvents()
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","LOOT_READY","LOOT_OPENED","LOOT_CLOSED","CHAT_MSG_ADDON","DISPLAY_SIZE_CHANGED","UI_SCALE_CHANGED","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED"}) do frame:RegisterEvent(event) end
-- Forever restricts combat-log registration itself. Use watched deaths and corpse loot there.
local interface=GetBuildInfo and select(4,GetBuildInfo())
if interface~=16001 and CombatLogGetCurrentEventInfo and not C_Secrets then
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
frame:SetScript("OnEvent",function(_,event,...)
    if event=="ADDON_LOADED" then
        if ...~="FeralDeck" then return end
        FeralDeckDB=FeralDeckDB or {}
        F.migrate(FeralDeckDB)
        F.register()
        if F.enableOwnershipTooltip then F.enableOwnershipTooltip() end
        SLASH_FERALDECK1="/fd"
        SlashCmdList.FERALDECK=toggle
        C_Timer.NewTicker(2,F.tick)
        C_Timer.NewTicker(.2,function(timer)
            local advance=F.loadCatalogue()
            local state=F.catalogueProgress()
            if advance and panel and panel:IsShown() and tab=="Collection" then F.refresh() end
            if state=="ready" or state=="local" then timer:Cancel() end
        end)
    elseif not F.db then return
    elseif event=="PLAYER_ENTERING_WORLD" then
        F.resetKillUnits()
        for unit in pairs(killWatchers) do unwatchKillUnit(unit) end
        watchKillUnit("target")
        local plates=C_NamePlate and F.read(C_NamePlate.GetNamePlates)
        for _,plate in ipairs(plates or {}) do
            local unit=plate.namePlateUnitToken
            if F.plain(unit) and type(unit)=="string" then watchKillUnit(unit) F.updateOwnershipPlate(unit) end
        end
    elseif event=="PLAYER_TARGET_CHANGED" then
        F.observeCreature("target")
        watchKillUnit("target")
    elseif event=="NAME_PLATE_UNIT_ADDED" then
        local unit=...
        watchKillUnit(unit)
        F.updateOwnershipPlate(unit)
    elseif event=="NAME_PLATE_UNIT_REMOVED" then
        local unit=...
        F.hideOwnershipPlate(unit)
        unwatchKillUnit(unit)
        if F.dropKillUnit(unit) then refreshKillCredit() end
    elseif event=="DISPLAY_SIZE_CHANGED" or event=="UI_SCALE_CHANGED" then F.refresh()
    elseif event=="COMBAT_LOG_EVENT_UNFILTERED" then
        if F.killCredit() then refreshKillCredit() end
    elseif event=="LOOT_READY" then F.stageLoot()
    elseif event=="LOOT_CLOSED" then F.clearStagedLoot()
    elseif event=="LOOT_OPENED" then F.loot(select(2,...)) F.refreshOwnershipPlates() F.refresh()
    else F.receive(...) end
end)
