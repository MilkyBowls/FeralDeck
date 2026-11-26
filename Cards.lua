local _, F = ...
F.balance = {dropChance = 0.02, firstCopyLimit=10, repeatLimit=10, mastery={3,7,12,20,35,55,80,110,145,185,230,280,335,395,460,530,605,685,770,860,955,1055,1160,1270,1400}, killMastery=1, victoryMastery=1, copyMastery=1}
F.roles = {"Hunter", "Keeper", "Hexer"}
F.icons = {Hunter = 132152, Keeper = 132110, Hexer = 136139}
F.overrides = {[10184] = {icon = 134153}, [11502] = {icon = 135830}}
F.starters = {299, 822, 40}
F.elwynn={
    [299]={ "Young Wolf","Scent of Blood","Deal +2 damage against a marked rival.","wolf" },
    [822]={ "Young Forest Bear","Den Guard","Hit and gain 3 shield. Carry unused shield through your next action.","bear" },
    [40]={ "Kobold Miner","Pickaxe Split","Break up to 4 rival shield before the hit.","miner" },
    [113]={ "Stonetusk Boar","Headlong Rush","Deal +2 damage against an unguarded rival.","boar" },
    [118]={ "Prowler","Pack Signal","Hit and mark the rival for the next attack.","prowler" },
    [735]={ "Murloc Streamrunner","Slipstream","Hit and refund 1 Focus.","murloc" },
    [94]={ "Defias Cutpurse","Cut the Purse","Hit and drain 1 rival Focus.","defias" },
    [80]={ "Kobold Laborer","Reinforce","Hit and gain 2 shield, or 4 if already guarded.","laborer" },
}
local forest,snow="Elwynn Forest","Dun Morogh"
F.habitats={
    [forest]={art="Woodland",crest="Leaf",edge={.84,.66,.32}},
    [snow]={art="Snow",crest="Peak",edge={.74,.88,1}},
    ["Tirisfal Glades"]={art="Gloom",crest="Compass",edge={.72,.68,.82}},
    ["Unknown habitat"]={art="Highlands",crest="Compass",edge={.63,.60,.50}},
}
local terrain={
    {"searing gorge|burning steppes|blackrock|molten|ragefire|emberstrife", "Volcanic", {.94,.62,.42}},
    {"dun morogh|winterspring|alterac mountains|frostmane|coldridge|kharanos|anvilmar|gol'bolar|iceflow|winterfall|snow", "Snow", {.74,.88,1}, "Peak"},
    {"tirisfal|silverpine|duskwood|plaguelands|deadwind|shadowfang|deathknell|darkshire|raven hill|cemetery|graveyard|scholomance|stratholme|ruins of lordaeron|undercity", "Gloom", {.72,.68,.82}},
    {"mine|deadmines|cavern|gnomeregan|stockade|chasm|burrow|cave|tunnel", "Mine", {.84,.66,.43}},
    {"wetlands|swamp|marsh|dustwallow|fen|bog|stonard", "Marsh", {.62,.82,.75}},
    {"stranglethorn|un'goro|feralas|zul'gurub|quel'danil|ungoro|jungle|grom'gol|kurzen", "Jungle", {.67,.85,.60}, "Leaf"},
    {"darkshore|longshore|kul tiras|azshara|booty bay|harbor|harbour|shore|coast|reef|lighthouse|cove|tide|beach|island|isle", "Coast", {.66,.81,.89}},
    {"durotar|barrens|badlands|blasted lands|desolace|tanaris|silithus|thousand needles|zul'farrak|ahn'qiraj|canyon|gorge|dunes", "Drylands", {.89,.70,.48}},
    {"teldrassil|ash envale|ashenvale|felwood|moonglade|darnassus|shadowglen|ameth'aran|darkwhisper|night song|night elf|dream", "Twilight", {.76,.73,.94}, "Leaf"},
    {"stormwind city|ironforge|orgrimmar|stormwind|trade district|old town|mage quarter|cathedral|dwarven district|city|capital", "City", {.83,.74,.58}},
    {"elwynn|northshire|goldshire|eastvale|crystal lake|stone cairn|forest's edge|ridgepoint|westbrook|azora|brackwell|vineyard|mirror lake|forest|woodland", "Woodland", {.84,.66,.32}, "Leaf"},
    {"westfall|loch modan|redridge|arathi|hinterlands|mulgore|hill sbrad|hillsbrad|silvermoon|stonetalon|thunder bluff|lakeshire|sentinel hill|moonbrook|thelsamar|valley|farm", "Highlands", {.82,.76,.51}},
}
local terrainFallback={art="Highlands",crest="Compass",edge={.76,.78,.66}}
function F.habitatStyle(zone)
    local known=F.habitats[zone]
    if known then return known end
    local name=(zone or ""):lower()
    for _,style in ipairs(terrain) do
        for token in style[1]:gmatch("[^|]+") do
            if name:find(token,1,true) then return {art=style[2],crest=style[4] or "Compass",edge=style[3]} end
        end
    end
    return terrainFallback
end
-- Primary habitat is curated by NPC ID; locations are field sightings.
F.species={
    [299]={forest,"Wolf","Goldshire"},
    [822]={forest,"Bear","Forest's Edge, Ridgepoint Tower, Tower of Azora"},
    [40]={forest,"Kobold","Fargodeep Mine"},
    [113]={forest,"Boar"}, [118]={forest,"Wolf","Ridgepoint Tower, Eastvale Logging Camp, Stone Cairn Lake"},
    [735]={forest,"Murloc","Crystal Lake"}, [94]={forest,"Humanoid"}, [80]={forest,"Kobold","Northshire Valley"},
    [704]={snow,"Wolf","Coldridge Valley","Ragged Timber Wolf"},
    [705]={snow,"Wolf","Coldridge Pass","Ragged Young Wolf"},
    [724]={snow,"Trogg","Coldridge Valley","Burly Rockjaw Trogg"},
    [1553]={"Tirisfal Glades","Bat",nil,"Greater Duskbat"},
    [1512]={"Tirisfal Glades","Bat","Deathknell","Duskbat"},
    [707]={snow,"Trogg",nil,"Rockjaw Trogg"},
    [1115]={snow,"Trogg","Gol'Bolar Quarry","Rockjaw Skullthumper"},
    [1117]={snow,"Trogg",nil,"Rockjaw Bonesnapper"},
    [1125]={snow,"Boar",nil,"Crag Boar"},
    -- Overworld enemies whose provider rows have neutral or incomplete faction data.
    [3098]={"Durotar","Boar",nil,"Mottled Boar"},
    [3099]={"Durotar","Boar",nil,"Dire Mottled Boar"},
    [3100]={"Durotar","Boar",nil,"Elder Mottled Boar"},
    [3106]={"Durotar","Crab",nil,"Pygmy Surf Crawler"},
    [3107]={"Durotar","Crab",nil,"Surf Crawler"},
    [3108]={"Durotar","Crab",nil,"Encrusted Surf Crawler"},
    [3124]={"Durotar","Scorpid",nil,"Scorpid Worker"},
    [266849]={"Durotar","Unknown family",nil,"Ridgeshade Lurker"},
    [266850]={"Durotar","Unknown family",nil,"Ridgeshade Creeper"},
    [268530]={"Durotar","Raptor",nil,"Bloodtalon Matriarch"},
    [275662]={"Durotar","Naga",nil,"Spitelash Scout"},
    [275663]={"Durotar","Naga",nil,"Spitelash Attendant"},
    [267308]={"The Barrens","Quilboar",nil,"Razormane Flesheater","Elite"},
    [267314]={"The Barrens","Quilboar",nil,"Razormane Berserker","Elite"},
    [268624]={"The Barrens","Quilboar",nil,"Razormane Raider"},
}
-- Durotar expedition encounters verified against the Forever NPC catalog.
local kulTirasExpedition={
    [3128]="Kul Tiras Sailor",
    [3129]="Kul Tiras Marine",
    [3192]="Lieutenant Benedict",
}
for id,name in pairs(kulTirasExpedition) do
    F.species[id]={"Durotar","Humanoid",nil,name}
end
local unknown={"Unknown habitat","Unknown family"}
local catalogue,zoneMembers
local function catalogueEntry(entry,zone)
    return {entry.zone or zone,entry.family or unknown[2],nil,entry.name,entry.rare and "Rare" or "Common"}
end
local catalogueJob
local catalogueSchema=2
local function catalogueKey(provider)
    local metadata=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local version=metadata and metadata(provider,"Version")
    local build=GetBuildInfo and select(2,GetBuildInfo())
    local locale=GetLocale and GetLocale()
    return table.concat({catalogueSchema,provider,version or "",build or "",locale or ""},":")
end
local function restoreCatalogue(key)
    local cached=F.db.areaCatalog
    if not (cached and cached.policy==catalogueSchema and cached.key==key and type(cached.entries)=="table" and type(cached.members)=="table") then return end
    catalogue,zoneMembers=cached.entries,cached.members
    return true
end
local function questieProvider()
    local lib=LibQuestieDB
    if not (lib and lib.Npc and lib.Npc.GetAllIds and lib.Npc.GetAll and C_Map and C_Map.GetMapInfo
        ) then return end
    local support=lib.Support and lib.Support.Get and lib.Support.Get("ZoneDB")
    local data=support and support.private
    data=data or {}
    local maps={}
    for _,source in ipairs({data.areaIdToUiMapId or "",data.areaIdToUiMapIdOverride or ""}) do
        for area,map in source:gmatch("%[%s*(%d+)%s*%]%s*=%s*(%d+)") do maps[tonumber(area)]=tonumber(map) end
    end
    if not next(maps) and not C_Map.GetAreaInfo then return end
    return lib.Npc,maps
end
function F.catalogueProgress()
    if catalogue then return "ready" end
    if catalogueJob then
        return "loading",catalogueJob.nextArea-1,#catalogueJob.areas,catalogueJob.npc and "creatures" or "areas"
    end
    local api=FieldGuideForever and FieldGuideForever.API
    if (api and api.Zones and api.Species) or LibQuestieDB then return "waiting" end
    return "local"
end
local excludedAreas={
    ["Arathi Basin"]=true,["Alterac Valley"]=true,["Warsong Gulch"]=true,
}
local eligibilityFields={"factionID","friendlyToFaction","npcFlags","minLevel","spawns"}
function F.isFactionCombatant(id,faction)
    return faction=="Alliance" and kulTirasExpedition[id]~=nil
end
function F.eligibleCreature(id,verifyNPC,observedCombatant)
    local npc=LibQuestieDB and LibQuestieDB.Npc
    if verifyNPC and npc and npc.GetAll then
        local row=npc.GetAll(id,eligibilityFields)
        if row then
            local factionID,friendly,flags,level,spawns=row[1],row[2],row[3],row[4],row[5]
            local faction=friendly=="A" and "Alliance" or friendly=="H" and "Horde"
            if (faction and not F.isFactionCombatant(id,faction))
                or (flags and flags~=0) or (type(level)=="number" and level<=0) then return false end
            if type(factionID)=="number" and factionID>0 and not friendly
                and type(level)=="number" and type(spawns)=="table" and next(spawns) then return true end
        end
    end
    -- An incomplete or neutral provider row can be backed by a curated encounter or live evidence.
    if F.species[id] or observedCombatant==true then return true end
    local card=F.db and F.db.cards[id]
    if card and card.overworldVerified then return true end
    local saved=F.db and F.db.areaCatalog
    return saved and saved.policy==catalogueSchema and saved.entries[id]~=nil or false
end
local function addCatalogue(job,zone,entry)
    if excludedAreas[zone] then return end
    local members=job.members[zone] or {}
    job.members[zone]=members
    if entry then
        members[entry.id]=true
        job.entries[entry.id]=job.entries[entry.id] or catalogueEntry(entry,zone)
    end
end
local npcFields={"name","rank","zoneID","spawns"}
local function indexNPC(job,id)
    local row=job.npc.GetAll(id,npcFields)
    if not row or not row[1] or not F.eligibleCreature(id,true) then return end
    local function areaName(area)
        local map=job.maps[tonumber(area)]
        local info=map and C_Map.GetMapInfo(map)
        local parent=info
        for _=1,8 do
            if not parent then break end
            if parent.mapType==4 or excludedAreas[parent.name] then return end
            if not parent.parentMapID or parent.parentMapID==0 then break end
            parent=C_Map.GetMapInfo(parent.parentMapID)
        end
        if info and (info.mapType==3 or info.mapType==5) then return info.name end
    end
    local entry={id=id,name=row[1],rare=row[2]==2 or row[2]==4}
    for area in pairs(row[4] or {}) do
        local name=areaName(area)
        if name then addCatalogue(job,name,entry) end
    end
end
function F.loadCatalogue()
    if catalogue then return end
    local api=FieldGuideForever and FieldGuideForever.API
    if not catalogueJob then
        local areas,npc,maps,key
        if api and api.Zones and api.Species then
            key=catalogueKey("FieldGuideForever")
            if restoreCatalogue(key) then return true end
            areas=api.Zones()
        end
        if not areas or #areas==0 then
            if not LibQuestieDB then return end
            key=catalogueKey("QuestieDB")
            if restoreCatalogue(key) then return true end
            npc,maps=questieProvider()
            areas=npc and npc.GetAllIds()
        end
        if not areas or #areas==0 then return end
        catalogueJob={areas=areas,nextArea=1,entries={},members={},npc=npc,maps=maps,api=api,key=key}
    end
    local job=catalogueJob
    local batch=job.npc and 80 or 4
    for i=job.nextArea,math.min(job.nextArea+batch-1,#job.areas) do
        if job.npc then
            indexNPC(job,job.areas[i])
        else
            local zone=job.areas[i].name
            local species,reason=job.api.Species(zone)
            if not species and reason~="none" then return end
            addCatalogue(job,zone)
            for _,entry in ipairs(species or {}) do
                if F.eligibleCreature(entry.id,true) then addCatalogue(job,zone,entry) end
            end
        end
        job.nextArea=i+1
    end
    if job.nextArea>#job.areas then
        catalogue,zoneMembers=job.entries,job.members
        F.db.areaCatalog={key=job.key,policy=catalogueSchema,entries=catalogue,members=zoneMembers}
        catalogueJob=nil
    end
    return true
end
function F.speciesOf(id)
    local c=F.db and F.db.cards[id]
    local cached=F.db and F.db.areaCatalog
    if cached and cached.policy~=catalogueSchema then cached=nil end
    local curated=F.species[id]
    if curated and (curated[2]~=unknown[2] or not (c and c.sighting)) then return curated end
    return (c and c.sighting and c.sighting[1]~=unknown[1] and c.sighting) or curated
        or (catalogue and catalogue[id]) or (cached and cached.entries[id]) or unknown
end
-- Editorial notes for the main early routes and the battleground guide.
F.areaProfiles={
    ["Arathi Basin"]={"Eastern Kingdoms / Battleground","A mountain-ringed valley where the League of Arathor and the Defilers fight for control of its resources.",
        "Stables, Farm, Blacksmith, Lumber Mill, Gold Mine"},
    ["Elwynn Forest"]={"Eastern Kingdoms / Woodland","The roads around Goldshire connect farms, lakes, logging camps, and the mines of Stormwind's wooded hinterland.",
        "Goldshire, Northshire Valley, Fargodeep Mine, Crystal Lake, Eastvale Logging Camp"},
    ["Dun Morogh"]={"Eastern Kingdoms / Alpine","A snowy stretch of Khaz Modan. The valleys below Ironforge are home to wolves and troggs, both represented in the field collection.",
        "Coldridge Valley, Coldridge Pass, Kharanos, Gol'Bolar Quarry"},
    ["Tirisfal Glades"]={"Eastern Kingdoms / Woodland","Deathknell and Brill lie among old farmsteads and the ruins of Lordaeron. The Field Journal records duskbat sightings in the region.",
        "Deathknell, Brill, Agamand Mills, Ruins of Lordaeron"},
}
function F.journalStats()
    if not catalogueJob then F.loadCatalogue() end
    local zones,tracked,total,owned,copies,kills,mastery,prestige={},{},0,0,0,0,0,0
    local function add(zone,id)
        zones[zone]=zones[zone] or {total=0,owned={},ids={}}
        local area=zones[zone]
        if area.ids[id] then return end
        area.ids[id]=true
        area.total=area.total+1
        local card=F.db.cards[id]
        if card and card.lifetime>0 then area.owned[#area.owned+1]=id end
    end
    local cached=F.db.areaCatalog
    if cached and cached.policy~=catalogueSchema then cached=nil end
    for zone,ids in pairs(zoneMembers or (cached and cached.members) or {}) do
        zones[zone]=zones[zone] or {total=0,owned={},ids={}}
        for id in pairs(ids) do tracked[id]=true add(zone,id) end
    end
    for id,species in pairs(F.species) do tracked[id]=true add(species[1],id) end
    for id,c in pairs(F.db.cards) do
        if c.lifetime>0 and F.eligibleCreature(id) then
            tracked[id]=true
            add(F.speciesOf(id)[1],id)
            copies=copies+c.lifetime
            kills=kills+(c.kills or 0)
            mastery=mastery+(c.mastery or 0)
            prestige=prestige+c.prestige
        end
    end
    for id in pairs(tracked) do
        total=total+1
        local c=F.db.cards[id]
        if c and c.lifetime>0 then owned=owned+1 end
    end
    return {zones=zones,total=total,owned=owned,copies=copies,kills=kills,mastery=mastery,prestige=prestige,extended=catalogue~=nil or cached~=nil}
end
F.tactics={
    {"Quick Study","Gain 1 Focus before acting."},
    {"Expose","Mark the rival before acting."},
    {"Sunder","Remove up to 3 rival shield before acting."},
    {"Cover","Gain 2 shield after your action."},
    {"Opening","Your basic attack deals 2 extra damage."},
    {"Reserve","Refund 1 Focus after a signature."},
}
F.recipes={
    {"Wolf Pack","Expose sets up Young Wolf's Scent of Blood.",{299,822,40},{2,1,5}},
    {"Mine Guard","Cover supports the bear. Sunder removes shield before the miner acts.",{822,40,299},{4,3,1}},
}
F.maxTactics=3
local function normalizeTactics(deck)
    local result,seen={},{}
    for i=1,6 do
        local id=deck[i]
        if F.tactics[id] and not seen[id] and #result<F.maxTactics then
            result[#result+1]=id
            seen[id]=true
        end
    end
    return result
end
function F.tacticDeck(name)
    return normalizeTactics((F.db.tacticDecks or {})[name] or F.recipes[1][4])
end
function F.validTactics(deck)
    local seen={}
    for slot,id in pairs(deck) do
        if type(slot)~="number" or slot%1~=0 or slot<1 or slot>F.maxTactics or not F.tactics[id] or seen[id] then return false end
        seen[id]=true
    end
    return true
end
local starterNames = {"Young Wolf", "Young Forest Bear", "Kobold Miner"}
local traits = {Beast="Hunter", Giant="Keeper", Elemental="Keeper", Undead="Hexer", Demon="Hexer"}
F.perks = {
    "Attack +1 damage", "Guard +1 shield", "Signature +1 damage", "Technique gains an effect upgrade",
}
-- Each track improves one conditional effect, so ranks broaden options without stacking flat damage.
local masteryTracks={
    {"finish","Attack +1 damage if the rival has %d HP or less",{2,3,4},"A"},
    {"guard","Guard +1 shield if this card has %d HP or less",{3,5,7},"B"},
    {"breakShield","Targeted techniques break up to %d shield",{1,2,3},"X"},
    {"recover","Signature +1 shield if this card has %d HP or less",{3,5,7},"S"},
    {"focus","Signature refunds 1 Focus if the rival has %d HP or less",{2,3,4},"S"},
    {"haste","Non-consecutive guard advances your turn 1 tick at %d HP or less",{3,5,7},"B"},
    {"delay","Signature delays the rival 1 extra tick if it has %d HP or less",{2,3,4},"S"},
}
local masteryValues={}
for rank=1,3 do
    for _,track in ipairs(masteryTracks) do
        F.perks[#F.perks+1]=track[2]:format(track[3][rank])
        masteryValues[#F.perks]={key=track[1],value=track[3][rank]}
    end
end
function F.masteryEffects(tier)
    local effects={}
    for i=5,tier do
        local perk=masteryValues[i]
        if perk then effects[perk.key]=perk.value end
    end
    return effects
end
function F.masteryEffectLabels(tier)
    local byMove={A={},B={},X={},S={}}
    local effects=F.masteryEffects(tier)
    for _,track in ipairs(masteryTracks) do
        local amount=effects[track[1]]
        if amount then
            local labels=byMove[track[4]]
            labels[#labels+1]=track[2]:format(amount)
        end
    end
    return byMove
end
function F.repeatOdds(c)
    local rarity=c.rarity
    if rarity=="Elite" then return .018,12 end
    if rarity=="Rare" then return .015,15 end
    if rarity=="Rare elite" then return .012,18 end
    if rarity=="Legendary" then return .01,22 end
    return F.balance.dropChance,F.balance.repeatLimit
end

F.skills = {Hunter="Pounce: pierce shield for Power + 1.", Keeper="Bulwark: deal Power and gain 3 shield.", Hexer="Brand: deal Power and mark for +3 on the next hit."}

function F.id(value)
    if type(value) ~= "string" and type(value) ~= "number" then return end
    local n = tonumber(value)
    if n and n >= 1 and n <= 2147483647 and n == math.floor(n) then return n end
end
local function count(v) return math.max(0, math.floor(tonumber(v) or 0)) end
function F.tier(c)
    local tier=0
    for i,threshold in ipairs(F.balance.mastery) do
        if (c.mastery or 0)>=threshold then tier=i end
    end
    return tier
end
function F.playable(c) return c and (c.lifetime>0 or c.legacyLoaner) end
function F.owned()
    local ids={}
    for id,c in pairs(F.db.cards) do if c.lifetime>0 and F.eligibleCreature(id) then ids[#ids+1]=id end end
    table.sort(ids)
    return ids
end
local function migrateJournal(db)
    for _,c in pairs(db.cards) do
        c.legacyLoaner=c.starter or nil
        c.starter=nil
        c.mastery=math.max(c.mastery or 0,F.balance.mastery[math.min(4,math.floor(c.lifetime/25))] or 0)
    end
    db.schema=5
end
function F.define(id, name, role)
    local c = F.db.cards[id]
    if not c then
        local api=FieldGuideForever and FieldGuideForever.API
        local entry=not F.species[id] and api and api.SpeciesById and api.SpeciesById(id)
        c = {role=traits[role] or F.roles[id % 3 + 1], power=2 + math.floor(id / 3) % 2,
             lifetime=0, progress=0, prestige=0, rarity=entry and entry.rare and "Rare" or F.speciesOf(id)[5] or "Common"}
        if entry then c.sighting=catalogueEntry(entry,unknown[1]) end
        F.db.cards[id] = c
    end
    if name then c.name = name end
    c.name = c.name or F.speciesOf(id)[4] or (F.elwynn[id] and F.elwynn[id][1]) or ("NPC "..id)
    return c
end
local rarities={normal="Common",minus="Common",trivial="Common",elite="Elite",
    rare="Rare",rareelite="Rare elite",worldboss="Legendary"}
F.rarityColors={Common="|cffc6cecf",Elite="|cff67db96",Rare="|cff79baff",
    ["Rare elite"]="|ffc99aff",Legendary="|cffffad55"}
function F.classify(c,classification)
    if rarities[classification] then c.rarity=rarities[classification] end
end
local function migrateKills(db)
    db.unlootedKills={}
    for guid in pairs(db.seen or {}) do
        local id=type(guid)=="string" and guid:match("^%a+%-%w+%-%w+%-%w+%-%w+%-(%d+)%-%x+$")
        local c=id and db.cards[tonumber(id)]
        if c then c.kills=(c.kills or 0)+1 end
    end
    for _,c in pairs(db.cards) do
        if c.lifetime>(c.kills or 0) then c.incompleteHistory=true end
    end
    db.schema=3
end
local function migrateExpansion(db)
    db.tacticDecks=db.tacticDecks or {}
    for name in pairs(db.decks or {}) do db.tacticDecks[name]=F.tacticDeck(name) end
    for guid in pairs(db.seen or {}) do
        local id=type(guid)=="string" and tonumber(guid:match("^%a+%-%w+%-%w+%-%w+%-%w+%-(%d+)%-%x+$"))
        local c=id and db.cards[id]
        if c then c.rolls=(c.rolls or 0)+1 end
    end
    for id,entry in pairs(F.elwynn) do if not db.cards[id] then F.define(id,entry[1]) end end
    for _,c in pairs(db.cards) do
        if c.incompleteHistory or c.lifetime>(c.rolls or 0) then c.incompleteRolls=true end
    end
    db.schema=4
end
local function migrate(db)
    local fresh=not next(db)
    F.db = db
    db.audioMode=db.audioMode or (db.sounds==false and "Off" or "Full")
    if db.schema==5 or db.schema==6 then return end
    if fresh then
        db.cards,db.decks,db.tacticDecks,db.stats,db.seen,db.unlootedKills={},{},{},{},{},{}
        db.schema=5
        return
    end
    if db.schema==4 then migrateJournal(db) return end
    if db.schema==3 then migrateExpansion(db) migrateJournal(db) return end
    if db.schema==2 then migrateKills(db) migrateExpansion(db) migrateJournal(db) return end
    local old = db.cards or db.collection or {}
    db.cards = {}
    for key, entry in pairs(old) do
        local v = type(entry) == "table" and entry or {copies=entry}
        local id = F.id(v.npcID or key)
        if id then
            local c = F.define(id, v.name)
            c.prestige = count(v.prestige)
            c.lifetime = count(v.lifetime or v.lifetimeCopies or v.copies)
            if c.lifetime>0 then c.incompleteHistory=true end
            c.progress = count(v.progress or v.prestigeProgress or (c.lifetime - 100*c.prestige))
            if F.skills[v.role] then c.role=v.role end
        end
    end
    for i,id in ipairs(F.starters) do
        local c = db.cards[id] or F.define(id, starterNames[i])
        c.starter = true
        if c.lifetime == 0 then c.role = F.roles[i] end
    end
    db.decks = db.decks or {Field = db.equipped or db.deck or {unpack(F.starters)}}
    for _, deck in pairs(db.decks) do
        for i,id in ipairs(deck) do deck[i]=F.id(id) or id end
    end
    db.active = db.active or next(db.decks)
    db.stats = db.stats or {wins=count(db.wins), losses=count(db.losses)}
    db.seen = db.seen or {}
    migrateKills(db)
    migrateExpansion(db)
    migrateJournal(db)
end
function F.migrate(db)
    migrate(db)
    if db.schema==6 then return end
    db.cards=db.cards or {}
    for _,c in pairs(db.cards) do
        c.mastery=(c.mastery or 0)+c.lifetime*F.balance.copyMastery
    end
    db.schema=6
end
function F.copy(c)
    c.repeatRolls=0
    if GetServerTime then
        local now=GetServerTime()
        if c.lifetime==0 then c.firstCopyAt=now end
        c.lastCopyAt=now
    end
    c.lifetime=c.lifetime+1
    c.progress=c.progress+1
    c.mastery=(c.mastery or 0)+F.balance.copyMastery
end
function F.reward(rank)
    local colors={"Amber","Jade","Violet","Azure"}
    return colors[(rank-1)%4+1].." foil "..rank..(rank==1 and " + Channel (solo guard move gains 1 Focus)" or " + numbered crest")
end
function F.prestige(c)
    if c.progress < 100 then return false end
    c.progress=c.progress-100
    c.prestige=c.prestige+1
    return true
end
function F.validate(deck, owned)
    if type(deck)~="table" or #deck~=3 then return false,"Equip exactly three cards." end
    local seen={}
    for i=1,3 do
        local id=deck[i]
        if not F.id(id) or id~=F.id(id) or seen[id] then return false,"Each slot needs a different NPC ID." end
        local c=F.db.cards[id]
        if owned and not F.eligibleCreature(id) then return false,"Use eligible overworld creature cards." end
        if owned and not F.playable(c) then return false,"Discover this card first." end
        seen[id]=true
    end
    return true
end
function F.say(s) print("|cffdfb45eFeral Deck|r  "..s) end
