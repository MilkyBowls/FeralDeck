local _, F = ...
function F.plain(v) return not issecretvalue or not issecretvalue(v) end
function F.read(fn,...)
    if not fn then return end
    local ok,v=pcall(fn,...)
    if ok and F.plain(v) then return v end
end
function F.creatureID(guid)
    if not F.plain(guid) or type(guid)~="string" then return end
    local kind,id=guid:match("^(%a+)%-%w+%-%w+%-%w+%-%w+%-(%d+)%-%x+$")
    if kind=="Creature" then return F.id(id) end
end
local function recordHabitat(id,c,trait)
    local curated=F.species[id]
    if curated then
        if curated[2]=="Unknown family" and trait and (not c.sighting or c.sighting[2]=="Unknown family") then
            c.sighting={curated[1],trait,curated[3],curated[4],curated[5]}
        end
        return
    end
    if c.sighting and c.sighting[1]~="Unknown habitat" then
        if c.sighting[2]=="Unknown family" and trait then c.sighting[2]=trait end
        return
    end
    local zone=F.read(GetRealZoneText)
    if type(zone)=="string" and zone~="" then c.sighting={zone,trait or "Unknown family"} end
end
local function discover(id,c)
    F.copy(c)
    F.db.latest=id
    F.db.discoveryCount=(F.db.discoveryCount or 0)+1
    c.unseen=F.db.discoveryCount
    if F.discovered then F.discovered(id) end
    F.say(c.name.." discovered. Open /fd to inspect your card.")
end
local function recordKill(id,c)
    c.overworldVerified=true
    c.kills=(c.kills or 0)+1
    if GetServerTime then c.lastKillAt=GetServerTime() end
    if c.lifetime==0 then
        local chance=F.repeatOdds(c)
        if c.kills>=F.balance.firstCopyLimit or math.random()<chance then discover(id,c) end
        return true
    end
    local previous=F.tier(c)
    c.mastery=(c.mastery or 0)+F.balance.killMastery
    if F.discovered and F.tier(c)>previous then F.discovered(id,F.perks[F.tier(c)]) end
end
local function creditKill(guid,id,c)
    if F.db.seen[guid] or F.db.unlootedKills[guid] then return end
    -- Reserve the GUID before notifying the UI. Corpse loot can still roll
    -- for a repeat copy when the creature was already collected.
    F.db.unlootedKills[guid]=c.lifetime==0 and "firstCopy" or true
    recordKill(id,c)
    return true
end
local function inOverworld()
    if not IsInInstance then return true end
    local inside=F.read(IsInInstance)
    return inside==false
end
local function eligibleUnit(unit,id,checkAttackable)
    local faction=F.read(UnitFactionGroup,unit)
    if F.read(UnitPlayerControlled,unit)==true then return false end
    if (faction=="Alliance" or faction=="Horde") and not F.isFactionCombatant(id,faction) then return false end
    return not checkAttackable or not UnitCanAttack or F.read(UnitCanAttack,"player",unit)==true
end
-- Sighting evidence lives for the session. Only eligible loot or kill credit saves a card.
local combatSightings={}
local function combatTraits(unit)
    local trait=F.read(UnitCreatureType,unit)
    local family=F.read(UnitCreatureFamily,unit)
    local humanoid=trait=="Humanoid" or (trait and trait==CREATURE_TYPE_HUMANOID)
    local reaction=humanoid and F.read(UnitReaction,unit,"player")
    local hostileHumanoid=type(reaction)=="number" and reaction>=1 and reaction<=3
    if hostileHumanoid or trait=="Beast" or (trait and trait==CREATURE_TYPE_BEAST)
        or (not humanoid and type(family)=="string" and family~="" and trait~="Critter" and (not CREATURE_TYPE_CRITTER or trait~=CREATURE_TYPE_CRITTER)) then
        return {name=F.read(UnitName,unit),trait=trait or "Beast",
            family=type(family)=="string" and family~="" and family or trait,
            classification=F.read(UnitClassification,unit)}
    end
end
function F.observeCreature(unit)
    if not inOverworld() then return end
    local id=F.creatureID(F.read(UnitGUID,unit))
    if not id or not eligibleUnit(unit,id,true) then return end
    local evidence=combatTraits(unit)
    if not F.eligibleCreature(id,true,evidence~=nil) then return end
    if evidence then combatSightings[id]=evidence end
    return id
end
local watched={}
local function unitDead(unit)
    return F.read(UnitIsDead or UnitIsDeadOrGhost,unit)
end

function F.watchKillUnit(unit)
    watched[unit]=nil
    if not inOverworld() or unitDead(unit)~=false then return end
    local guid=F.read(UnitGUID,unit)
    local id=F.creatureID(guid)
    if not id or not eligibleUnit(unit,id,true) then return end
    local evidence=combatTraits(unit)
    watched[unit]={guid=guid,id=id,evidence=evidence}
end

function F.checkKillUnit(unit)
    if not inOverworld() then return end
    local sighting=watched[unit]
    local guid=F.read(UnitGUID,unit)
    if not sighting or (guid and guid~=sighting.guid) then
        F.watchKillUnit(unit)
        sighting=watched[unit]
    end
    if not sighting then return end
    local tapped=F.read(UnitIsTapDenied,unit)
    local dead=unitDead(unit)
    if dead==false then
        if tapped==true then
            sighting.engaged=nil
        elseif tapped==false and (type(F.read(UnitThreatSituation,"player",unit))=="number"
            or type(F.read(UnitThreatSituation,"pet",unit))=="number"
            or F.read(UnitIsUnit,unit.."target","player")==true
            or F.read(UnitIsUnit,unit.."target","pet")==true) then
            sighting.engaged=true
        end
        return
    end
    if dead~=true then return end
    watched[unit]=nil
    if not sighting.engaged or tapped~=false then return end
    local id=sighting.id
    local evidence=sighting.evidence or combatSightings[id]
    if not F.eligibleCreature(id,true,evidence~=nil) then return end
    local card=F.define(id,evidence and evidence.name,evidence and evidence.trait)
    if evidence then F.classify(card,evidence.classification) end
    recordHabitat(id,card,evidence and evidence.family)
    return creditKill(sighting.guid,id,card)
end

function F.dropKillUnit(unit)
    local credited=F.checkKillUnit(unit)
    watched[unit]=nil
    return credited
end

function F.resetKillUnits()
    watched={}
    F.clearStagedLoot()
end

local function source(guid,amount)
    if not F.plain(amount) or type(amount)~="number" or amount<=0 then return end
    local id=F.creatureID(guid)
    if not id then return end
    local evidence=combatSightings[id]
    local name,trait,classification,family
    for _,unit in ipairs({"target","softinteract","mouseover"}) do
        if F.read(UnitGUID,unit)==guid then
            if unitDead(unit)~=true or not eligibleUnit(unit,id) then return end
            evidence=combatTraits(unit) or evidence
            name=F.read(UnitName,unit)
            classification=F.read(UnitClassification,unit)
            trait=F.read(UnitCreatureType,unit)
            break
        end
    end
    if not F.eligibleCreature(id,true,evidence~=nil) then return end
    if evidence then
        name,trait,classification=name or evidence.name,trait or evidence.trait,classification or evidence.classification
        family=evidence.family
    end
    local c=F.define(id,name,trait)
    F.classify(c,classification)
    recordHabitat(id,c,family or trait)
    if F.db.seen[guid] then return end
    local pending=F.db.unlootedKills[guid]
    F.db.unlootedKills[guid]=nil
    F.db.seen[guid]=true
    c.rolls=(c.rolls or 0)+1
    if not pending and recordKill(id,c) then return end
    -- An unowned kill has already had its first-copy roll, even if it missed.
    if pending=="firstCopy" or pending=="discovery" or c.lifetime==0 then return end
    c.repeatRolls=(c.repeatRolls or 0)+1
    local chance,limit=F.repeatOdds(c)
    if math.random()<chance or c.repeatRolls>=limit then
        local tier=F.tier(c)
        F.copy(c)
        if F.discovered and F.tier(c)>tier then F.discovered(id,F.perks[F.tier(c)]) end
        F.say(c.name.." / "..c.lifetime.." copies")
    end
end
local stagedLoot={}
local function lootAllowed()
    return inOverworld() and (not IsFishingLoot or F.read(IsFishingLoot)==false)
end
local function scanLoot(add)
    local function inspect(...)
        for i=1,select("#",...),2 do add(select(i,...)) end
    end
    local n=F.read(GetNumLootItems)
    if type(n)~="number" then return end
    for i=1,n do
        local ok,_,_,_,_,_,locked=pcall(GetLootSlotInfo,i)
        if ok and F.plain(locked) and not locked then
            pcall(function() inspect(GetLootSourceInfo(i)) end)
        end
    end
end

function F.stageLoot()
    stagedLoot={}
    if not lootAllowed() then return end
    scanLoot(function(guid,amount)
        if F.creatureID(guid) and F.plain(amount) and type(amount)=="number" and amount>0 then
            stagedLoot[guid]=amount
        end
    end)
end

function F.clearStagedLoot()
    stagedLoot={}
end

function F.loot(fromItem)
    local staged=stagedLoot
    F.clearStagedLoot()
    if not F.plain(fromItem) or fromItem or not lootAllowed() then return end
    scanLoot(source)
    for guid,amount in pairs(staged) do source(guid,amount) end
end

function F.killCredit()
    if not inOverworld() or not CombatLogGetCurrentEventInfo then return end
    local ok,_,event,_,killer,_,_,_,guid,name=pcall(CombatLogGetCurrentEventInfo)
    if not ok or not F.plain(event) or event~="PARTY_KILL" or not F.plain(killer)
        or type(killer)~="string" or not F.plain(guid) or type(guid)~="string" then return end
    if killer~=F.read(UnitGUID,"player") and killer~=F.read(UnitGUID,"pet") then return end
    local id=F.creatureID(guid)
    if not id then return end
    local evidence=combatSightings[id]
    for _,unit in ipairs({"target","softinteract","mouseover"}) do
        if F.read(UnitGUID,unit)==guid then
            if not eligibleUnit(unit,id) then return end
            evidence=combatTraits(unit) or evidence
            break
        end
    end
    if not F.eligibleCreature(id,true,evidence~=nil) or F.db.seen[guid] or F.db.unlootedKills[guid] then return end
    local c=F.define(id,F.plain(name) and type(name)=="string" and name or (evidence and evidence.name),
        evidence and evidence.trait)
    if evidence then F.classify(c,evidence.classification) end
    recordHabitat(id,c,evidence and (evidence.family or evidence.trait))
    return creditKill(guid,id,c)
end

function F.ownershipStatus(unit)
    if not F.db then return end
    local id=F.observeCreature(unit)
    if not id then return end
    local card=F.db.cards[id]
    return card~=nil and card.lifetime>0,card
end

local function ownershipBadge(owned)
    return F.media..(owned and "OwnershipGold.tga" or "OwnershipDark.tga")
end

function F.enableOwnershipTooltip()
    local function annotate(tooltip)
        if tooltip~=GameTooltip or not tooltip.GetUnit then return end
        local ok,_,unit=pcall(tooltip.GetUnit,tooltip)
        if not ok or not F.plain(unit) or type(unit)~="string" then return end
        local owned,card=F.ownershipStatus(unit)
        if owned==nil then return end
        local emblem=("|T%s:14:14:0:0|t"):format(ownershipBadge(owned))
        local status=owned and F.uiColors.gold.."Collected" or F.uiColors.muted.."Uncollected"
        tooltip:AddLine(emblem.."  FeralDeck  /  "..status.."|r",.92,.95,.99)
        if not owned then
            local limit=F.balance.firstCopyLimit
            local kills=card and card.kills or 0
            tooltip:AddLine(("First-copy progress: %d / %d credited kills"):format(math.min(kills,limit),limit),.74,.80,.86)
        end
    end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,annotate)
    elseif GameTooltip and GameTooltip.HookScript then
        pcall(GameTooltip.HookScript,GameTooltip,"OnTooltipSetUnit",annotate)
    end
end

local badges,activePlates={},{}
function F.updateOwnershipPlate(unit)
    activePlates[unit]=true
    local badge=badges[unit]
    if badge then badge:Hide() end
    local owned=F.ownershipStatus(unit)
    if owned==nil or F.read(UnitCanAttack,"player",unit)~=true then return end
    local plate=C_NamePlate and F.read(C_NamePlate.GetNamePlateForUnit,unit)
    if not plate or F.read(plate.IsForbidden,plate)==true then return end
    local name=F.read(function()
        local frame=plate.UnitFrame
        if not frame then return end
        local text=frame.name or frame.Name or frame.NameText or frame.nameText
        if text and text.GetStringWidth then return text end
    end)
    if not name or F.read(name.IsShown,name)==false then return end
    -- Some nameplates center the text in a fixed-width label. Use the end
    -- of the rendered name, rather than the edge of that label.
    local offset=5
    local width,textWidth=F.read(name.GetWidth,name),F.read(name.GetStringWidth,name)
    if type(width)=="number" and type(textWidth)=="number" and textWidth>0 then
        local slack=math.max(0,width-textWidth)
        local alignment=F.read(name.GetJustifyH,name)
        if alignment=="CENTER" then offset=offset-slack/2
        elseif alignment=="LEFT" then offset=offset-slack end
    end
    if not badge then
        badge=UIParent:CreateTexture(nil,"OVERLAY",nil,7)
        badge:SetSize(12,12)
        badges[unit]=badge
    end
    badge:ClearAllPoints()
    if not pcall(badge.SetPoint,badge,"LEFT",name,"RIGHT",offset,0) then return end
    badge:SetTexture(ownershipBadge(owned))
    badge:SetAlpha(owned and .86 or .73)
    badge:Show()
end

function F.hideOwnershipPlate(unit)
    activePlates[unit]=nil
    if badges[unit] then badges[unit]:Hide() end
end

function F.refreshOwnershipPlates()
    for unit in pairs(activePlates) do F.updateOwnershipPlate(unit) end
end
