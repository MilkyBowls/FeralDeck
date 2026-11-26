-- Run from the directory containing FeralDeck with Lua 5.1 or 5.3.
local probe=io.open("FeralDeck.toc","r")
local root=probe and "" or "FeralDeck/"
if probe then probe:close() end
unpack=unpack or table.unpack
local function client(freshSave)
    local f={}
    for _,file in ipairs({"Cards","Moves","Relay","Loot","Duels"}) do
        assert(loadfile(root..file..".lua"))("FeralDeck",f)
    end
    f.migrate(freshSave and {} or {wins=0})
    -- The legacy suites use invented creature IDs. Keep the real policy for its own fixtures.
    f.realEligibility=f.eligibleCreature
    f.eligibleCreature=function(id,verify)
        return tonumber(id)~=nil
    end
    f.say=function() end
    return f
end
local strict=client(true)
local fixtureRandom=math.random
math.random=function() return 0 end
strict.eligibleCreature=strict.realEligibility
local durotarSpawns={[14]={{10,10}}}
local candidateRows={
    [3099]={189,"AH",nil,6,durotarSpawns},
    [3128]={123,"A",nil,5,durotarSpawns},
    [3129]={123,"A",nil,6,durotarSpawns},
    [3192]={123,"A",nil,8,durotarSpawns},
    [5809]={84,"A",2,9,durotarSpawns},
    [266849]={nil,nil,nil,5,durotarSpawns},
    [810001]={14,nil,0,8,{[1]={{10,10}}}},
    [810002]={12,"A",0,8,{[1]={{10,10}}}},
    [810003]={10,"H",0,8,{[1]={{10,10}}}},
    [810004]={14,"AH",1,8,{[1]={{10,10}}}},
}
LibQuestieDB={Npc={GetAll=function(id) return candidateRows[id] end}}
assert(strict.eligibleCreature(810001,true))
assert(not strict.eligibleCreature(810002,true) and not strict.eligibleCreature(810003,true))
assert(not strict.eligibleCreature(810004,true) and not strict.eligibleCreature(810005,true))
strict.db.areaCatalog={entries={[810002]={}},members={}}
assert(not strict.eligibleCreature(810002))
IsInInstance=function() return true end
GetNumLootItems=function() error("instance loot must not be scanned") end
strict.loot(false)
IsInInstance,GetNumLootItems=nil,nil
assert(strict.eligibleCreature(3099,true) and strict.eligibleCreature(266849,true))
assert(not strict.eligibleCreature(810002,true,true) and not strict.eligibleCreature(810004,true,true))

local id,visible,dead,faction,controlled=3099
local function corpse()
    return ("Creature-0-1-2-3-%d-0FF"):format(id)
end
UnitGUID=function(unit) if visible and unit=="target" then return corpse() end end
UnitCanAttack=function() return not dead end
UnitIsDeadOrGhost=function() return dead end
UnitFactionGroup=function() return faction end
UnitPlayerControlled=function() return controlled end
UnitCreatureType=function() return "Beast" end
UnitCreatureFamily=function() return id==3099 and "Boar" or "Spider" end
UnitName=function() return "Observed wild beast" end
GetRealZoneText=function() return "Durotar" end
GetNumLootItems=function() return 1 end
GetLootSlotInfo=function() end
GetLootSourceInfo=function() return corpse(),1 end
strict.loot(false)
assert(strict.db.cards[3099].name=="Dire Mottled Boar" and strict.db.cards[3099].lifetime==1)
id,visible,dead=266849,true,true
strict.loot(false)
assert(strict.db.cards[id].lifetime==1 and strict.speciesOf(id)[2]=="Spider")
local entries=strict.journalStats().zones.Durotar.ids
assert(entries[3099] and entries[266849] and entries[3128] and entries[3129] and entries[3192])

-- Reproduce the installed provider's incomplete rows without requiring a live target.
local crawlersAndBoars={3098,3100,3106,3107,3108,3124}
for _,npc in ipairs(crawlersAndBoars) do
    candidateRows[npc]={npc<3106 and 189 or 7,"AH",nil,5,durotarSpawns}
end
local incompleteCombatants={266850,268530,275662,275663,267308,267314,268624}
for _,npc in ipairs(incompleteCombatants) do
    candidateRows[npc]={nil,nil,nil,5,durotarSpawns}
end
visible=false
for _,group in ipairs({crawlersAndBoars,incompleteCombatants}) do
    for _,npc in ipairs(group) do
        id=npc
        assert(strict.eligibleCreature(id,true))
        strict.loot(false)
        assert(strict.db.cards[id].lifetime==1 and strict.db.cards[id].name==strict.speciesOf(id)[4])
    end
end
candidateRows[5951]={31,"AH",nil,1,durotarSpawns}
candidateRows[261368]={nil,"A",nil,16,{[17]={{10,10}}}}
assert(not strict.eligibleCreature(5951,true) and not strict.eligibleCreature(261368,true))

local reaction=2
UnitReaction=function() return reaction end
UnitCreatureFamily=function() end
UnitCreatureType=function() return "Humanoid" end
UnitName=function() end
for _,combatant in ipairs({3128,3129,3192}) do
    id,visible,dead,faction=combatant,true,false,"Alliance"
    assert(strict.eligibleCreature(id,true) and strict.ownershipStatus("target")==false)
    dead=true
    -- The sailor must also work when the corpse has no active unit token.
    if id==3128 then visible=false end
    strict.loot(false)
    assert(strict.db.cards[id].lifetime==1)
end
id,visible,dead,faction=5809,true,false,"Alliance"
assert(strict.ownershipStatus("target")==nil)
dead=true
strict.loot(false)
assert(not strict.db.cards[id])
id,visible,dead,faction=810009,true,false,nil
assert(strict.ownershipStatus("target")==false)
visible,dead=false,true
strict.loot(false)
assert(strict.db.cards[id].lifetime==1)
id,visible,dead,reaction=810010,true,false,4
assert(strict.ownershipStatus("target")==nil)
dead=true
strict.loot(false)
assert(not strict.db.cards[id])
id,visible,dead,reaction=810002,true,false,2
assert(strict.ownershipStatus("target")==nil)

UnitCreatureType=function() return "Beast" end
UnitCreatureFamily=function() return "Spider" end
UnitName=function() return "Observed wild beast" end
UnitReaction=nil

id,visible,dead=810005,true,false
assert(strict.ownershipStatus("target")==false and not strict.db.cards[id])
visible,dead=false,true
strict.loot(false)
assert(strict.db.cards[id].lifetime==1 and strict.eligibleCreature(id))
for _,denied in ipairs({810002,810004,810006,810007,810008}) do
    id,visible,dead=denied,true,false
    faction=denied==810006 and "Horde" or nil
    controlled=denied==810007
    if denied==810008 then
        UnitCreatureType=function() return "Critter" end
        UnitCreatureFamily=function() end
    end
    assert(strict.ownershipStatus("target")==nil)
    dead=true
    strict.loot(false)
    assert(not strict.db.cards[id])
end
UnitGUID,UnitCanAttack,UnitIsDeadOrGhost,UnitFactionGroup,UnitPlayerControlled=nil,nil,nil,nil,nil
UnitCreatureType,UnitCreatureFamily,UnitName,GetRealZoneText=nil,nil,nil,nil
GetNumLootItems,GetLootSlotInfo,GetLootSourceInfo,LibQuestieDB=nil,nil,nil,nil
math.random=fixtureRandom
print("PASS Durotar beasts and combatants, hostile humanoid discovery, faction and service NPC exclusions, stale cache and instance loot")

local F=client()
local old={collection={["123"]={copies=117,name="Echo"},["124"]={copies=75,name="Echo"}},
    equipped={"123","124","299"},wins=8,losses=3}
F.migrate(old)
local c=old.cards[123]
assert(c~=old.cards[124] and F.tier(c)>=4 and old.stats.wins==8 and old.stats.losses==3)
assert(F.validate(old.decks.Field,true) and F.prestige(c) and c.progress==17 and c.lifetime==117)
F.migrate(old)
assert(c==old.cards[123] and c.prestige==1 and c.progress==17 and old.decks.Field[1]==123)
for i=1,83 do F.copy(c) end
assert(F.prestige(c) and c.prestige==2 and c.progress==0 and not F.prestige(c))
local fresh=F.define(444)
for i=1,101 do
    F.copy(fresh)
    assert(fresh.mastery==i and fresh.progress==i)
end
assert(not F.validate({123,123,124},true))
assert(not F.validate({123,124,999},true))
assert(not F.validate({123,124},true))
print("PASS migration, four milestones, repeat prestige, ownership and deck validation")

local secret={}
issecretvalue=function(v) return v==secret end
local guid="Creature-0-1-2-3-444-000A"
local other="Creature-0-1-2-3-444-000B"
local rolls,win,locked,fishing,dead=0,true,false,false,true
local original=math.random
math.random=function() rolls=rolls+1 return win and 0.019 or 0.02 end
GetNumLootItems=function() return 3 end
IsFishingLoot=function() return fishing end
GetLootSlotInfo=function() return 1,"item",1,nil,1,locked end
UnitGUID=function() return guid end
UnitIsDeadOrGhost=function() return dead end
UnitName=function() return "Echo" end
GetLootSourceInfo=function() return guid,1,guid,1,secret,1 end
F.loot(false) F.loot(false)
assert(rolls==1 and fresh.lifetime==102)
win=false
GetLootSourceInfo=function() return other,2 end
F.loot(false)
F.migrate(old) F.loot(false)
assert(rolls==2 and fresh.lifetime==102)
guid="Creature-0-1-2-3-444-000C"
GetLootSourceInfo=function() return guid,1 end
dead=false F.loot(false)
dead=secret F.loot(false)
dead=true locked=secret F.loot(false)
locked=true F.loot(false)
locked=false fishing=true F.loot(false)
fishing=false F.loot(true) F.loot(secret)
GetLootSourceInfo=function() error("restricted") end
F.loot(false)
GetLootSourceInfo=function() return secret,1,guid,secret,"Item-0-1-2-3-444-000A",1 end
F.loot(false)
assert(rolls==2)
assert(fresh.kills==2)
local victim="Creature-0-1-2-3-444-000D"
CombatLogGetCurrentEventInfo=function() return 1,"PARTY_KILL",false,guid,nil,nil,nil,victim,"Echo" end
assert(F.killCredit() and not F.killCredit() and fresh.kills==3)
GetLootSourceInfo=function() return victim,1 end
F.loot(false)
assert(fresh.kills==3 and not F.db.unlootedKills[victim])
local migrated=client()
migrated.migrate({schema=2,cards={[444]={lifetime=1}},seen={[guid]=true,[other]=true}})
assert(migrated.db.cards[444].kills==2)
migrated.migrate(migrated.db)
assert(migrated.db.cards[444].kills==2 and migrated.db.cards[444].rolls==2)
assert(#F.tacticDeck("Field")==3 and old.stats.wins==8 and c.incompleteRolls)
F.classify(fresh,"rareelite") F.classify(fresh,nil)
assert(fresh.rarity=="Rare elite")
math.random=original
print("PASS per-corpse rolls, reload, exact chance boundary, fishing, containers, living and secret values")

do
    local discovery=client(true)
    local unitGUID,lootSource,killEvent=UnitGUID,GetLootSourceInfo,CombatLogGetCurrentEventInfo
    local player="Player-0-000A"
    local victim
    local randomCalls=0
    math.random=function() randomCalls=randomCalls+1 return .99 end
    UnitGUID=function(unit)
        if unit=="player" then return player end
    end
    GetLootSourceInfo=function() return victim,1,victim,1 end
    CombatLogGetCurrentEventInfo=function()
        return 1,"PARTY_KILL",false,player,nil,nil,nil,victim,"First-copy test"
    end
    for index,rarity in ipairs({"Common","Elite","Rare","Rare elite","Legendary"}) do
        local npc=900000+index
        local card=discovery.define(npc)
        card.rarity=rarity
        randomCalls=0
        for kill=1,10 do
            victim=("Creature-0-1-2-3-%d-%04X"):format(npc,kill)
            if (kill+index)%2==0 then
                assert(discovery.killCredit() and not discovery.killCredit())
                discovery.migrate(discovery.db)
                discovery.loot(false)
            else
                discovery.loot(false)
                assert(not discovery.killCredit())
            end
            discovery.loot(false)
            assert(card.kills==kill and card.rolls==kill and (card.repeatRolls or 0)==0)
            assert(card.lifetime==(kill==10 and 1 or 0))
            assert((card.mastery or 0)==card.lifetime)
        end
        assert(randomCalls==9 and card.unseen)
    end

    local card=discovery.define(900006)
    victim="Creature-0-1-2-3-900006-0001"
    assert(discovery.killCredit() and card.lifetime==0)
    math.random=function() return .019 end
    local missed=victim
    victim="Creature-0-1-2-3-900006-0002"
    assert(discovery.killCredit() and card.lifetime==1 and card.kills==2)
    victim=missed
    discovery.loot(false)
    assert(card.lifetime==1 and card.kills==2 and card.repeatRolls==0)
    math.random,UnitGUID,GetLootSourceInfo,CombatLogGetCurrentEventInfo=original,unitGUID,lootSource,killEvent
end
print("PASS first-copy odds, tenth-kill guarantee for every rarity, and delayed corpse-loot deduplication")

do
    local observed=client(true)
    local oldGUID,oldDead,oldThreat,oldTap=UnitGUID,UnitIsDeadOrGhost,UnitThreatSituation,UnitIsTapDenied
    local oldCount,oldSource=GetNumLootItems,GetLootSourceInfo
    local spawn="Creature-0-1-2-3-910001-0001"
    local visible,dead,threat,tapDenied=true,false,nil,false
    UnitGUID=function(unit)
        if visible and (unit=="target" or unit=="nameplate1") then return spawn end
    end
    UnitIsDeadOrGhost=function() return dead end
    UnitThreatSituation=function(unit) if unit=="pet" then return threat end end
    UnitIsTapDenied=function() return tapDenied end
    math.random=function() return .99 end
    observed.watchKillUnit("target")
    observed.watchKillUnit("nameplate1")
    visible,threat=false,0
    observed.checkKillUnit("target")
    observed.checkKillUnit("nameplate1")
    dead=true
    assert(observed.checkKillUnit("target"))
    assert(not observed.dropKillUnit("nameplate1"))
    local card=observed.db.cards[910001]
    assert(card.kills==1 and card.lifetime==0)
    GetLootSourceInfo=function() return spawn,1 end
    observed.loot(false)
    assert(card.kills==1 and card.rolls==1)

    spawn="Creature-0-1-2-3-910001-0002"
    visible,dead,threat=true,false,nil
    observed.watchKillUnit("target")
    dead=true
    assert(not observed.checkKillUnit("target") and card.kills==1)
    spawn="Creature-0-1-2-3-910001-0003"
    dead,threat=false,0
    observed.watchKillUnit("target")
    observed.checkKillUnit("target")
    dead,tapDenied=true,true
    assert(not observed.checkKillUnit("target") and card.kills==1)

    local slots=1
    GetNumLootItems=function() return slots end
    visible=false
    spawn="Creature-0-1-2-3-910001-0004"
    observed.stageLoot()
    slots=0
    observed.loot(false)
    observed.loot(false)
    assert(card.kills==2 and card.rolls==2)
    slots,spawn=1,"Creature-0-1-2-3-910001-0005"
    observed.stageLoot()
    slots=0
    observed.loot(true)
    observed.loot(false)
    assert(card.kills==2)
    UnitGUID,UnitIsDeadOrGhost,UnitThreatSituation,UnitIsTapDenied=oldGUID,oldDead,oldThreat,oldTap
    GetNumLootItems,GetLootSourceInfo,math.random=oldCount,oldSource,original
end
print("PASS witnessed deaths, hidden GUIDs, combat participation, contested taps, and early loot attribution")

for _,role in ipairs(F.roles) do
    local strengths={Hunter="Hexer",Hexer="Keeper",Keeper="Hunter"}
    for _,target in ipairs(F.roles) do
        local hand=F.snapshot(F.starters,false)
        hand[1].role=role
        hand[2].role=target
        local b=F.board(hand,hand)
        b[2].last=2
        b[1].focus=2
        local damage,_,_,edge=F.moveStats(hand[1],"S",target,false)
        assert(edge==(role==target and 0 or strengths[role]==target and 1 or -1))
        assert(F.play(b,1,1,"S") and b.events[1].hit==damage and b.events[1].edge==edge)
    end
end
for _,style in ipairs({"Sentinel","Prowler"}) do
    assert(F.solo(style))
    local b=F.match
    while b.winner==nil do
        local i,m=F.ai(b,style)
        assert(F.legal(b,b.turn,i,m))
        assert(F.play(b,b.turn,i,m))
        assert(b.seq<=48)
    end
    local key=b.winner==0 and "draws" or (b.winner==1 and "wins" or "losses")
    local before=F.db.stats[key] or 0
    F.finish(b) F.finish(b)
    assert(F.db.stats[key]==before+1)
end
for _,tier in ipairs({0,1,2,3,4}) do
    local hand=F.snapshot(F.starters,false)
    hand[1].tier=tier
    for _,move in ipairs({"A","B","S"}) do
        local b=F.board(hand,hand)
        b[1].focus=2
        assert(F.play(b,1,1,move))
        if move=="B" then assert(b[1].shield==3+(tier>=2 and 1 or 0))
        else assert(34-b[2].hp==hand[1].power+(move=="A" and ((tier>=1 and 1 or 0)+(tier>=4 and 1 or 0)) or 1+(tier>=3 and 1 or 0))) end
    end
end
print("PASS AI legality, terminal turn cap, idempotent results and solo upgrade effects")

local A,B=client(),client()
local now,out=1000000,{}
GetServerTime=function() return now end
GetTime=GetServerTime
Enum={SendAddonMessageResult={Success=0}}
C_ChatInfo={RegisterAddonMessagePrefix=function() return 0 end,
    SendAddonMessage=function(p,s,ch,peer) out[#out+1]={p,s,ch,peer} return 0 end}
A.register() B.register()
local function deliver(receiver,sender)
    local p=table.remove(out,1)
    assert(p)
    receiver.receive(p[1],p[2],p[3],sender)
    return p[2]
end
A.db.cards[299].lifetime=200 A.db.cards[299].prestige=2
A.challenge("Bob")
local invite=deliver(B,"Alice")
assert(B.net.phase=="invited" and not B.match)
B.accept() deliver(A,"Bob") deliver(B,"Alice")
assert(A.match.me==1 and B.match.me==2 and B.match[1].cards[1].rank==2 and A.match[1].cards[1].tier==0)
A.act(1,"A")
local packet=deliver(B,"Alice")
local id=B.net.id
local function receive(s,sender) B.receive("FeralDeck",s,"WHISPER",sender or "Alice") end
receive(packet)
receive("3|"..id.."|M|3:1:A")
receive("3|"..id.."|M|2:1:S")
receive(string.rep("x",201))
receive("3|"..id.."|Q|1","Mallory")
assert(B.match.seq==1 and not B.match.winner and A.match[2].hp==B.match[2].hp)
B.act(2,"B") deliver(A,"Bob")
assert(A.match.seq==2 and B.match.seq==2)
A.leave() deliver(B,"Alice")
assert(A.db.stats.losses==1 and B.db.stats.wins==1)
receive(invite)
assert(not B.net)
A.challenge("Bob") deliver(B,"Alice") B.leave() deliver(A,"Bob")
assert(not A.net and not B.net)
A.challenge("Bob") now=now+121 A.tick()
assert(not A.net and A.db.stats.losses==1)
out={}
receive("9|"..now..".222222|I|299:R:0,822:K:0,40:X:0")
assert(not B.net and out[1][2]:find("|V|",1,true))
print("PASS two-client handshake, normalized decks, ordering, rejection, decline, timeout and concession")

local elwynn=client(true)
assert(#elwynn.owned()==0 and not next(elwynn.db.cards) and not elwynn.db.active)
assert(not elwynn.solo("Sentinel"))
assert(F.db.cards[299].legacyLoaner and F.validate({299,822,40},true))
local oldRandom=math.random
math.random=function() return 0 end
GetLootSourceInfo=function() return guid,1,guid,1 end
for i,id in ipairs({113,822,40}) do
    guid=("Creature-0-1-2-3-%d-00A"):format(id)
    local function credit()
        return 1,"PARTY_KILL",false,guid,nil,nil,nil,guid,"Discovery "..id
    end
    CombatLogGetCurrentEventInfo=credit
    if i==1 then
        assert(elwynn.killCredit())
        assert(elwynn.db.cards[id].lifetime==1)
        elwynn.migrate(elwynn.db)
    end
    elwynn.loot(false)
    assert(not elwynn.killCredit())
    elwynn.loot(false)
    assert(elwynn.db.cards[id].lifetime==1 and elwynn.db.cards[id].kills==1)
end
math.random=function() return 0.99 end
for roll=1,10 do
    guid=("Creature-0-1-2-3-113-%04X"):format(roll)
    elwynn.loot(false)
    elwynn.loot(false)
    elwynn.migrate(elwynn.db)
    local boar=elwynn.db.cards[113]
    assert(boar.rolls==roll+1 and boar.mastery==roll+1+(roll==10 and 1 or 0))
    assert(boar.lifetime==(roll==10 and 2 or 1))
end
math.random=oldRandom
assert(elwynn.snapshot({113},true)[1].tier==3 and elwynn.snapshot({113},false)[1].tier==0)
elwynn.db.decks.Field={113,822,40}
elwynn.db.active="Field"
assert(elwynn.solo("Sentinel"))
local battle=elwynn.match
battle[1].focus=1
assert(#battle.hand==3 and #battle.draw==0)
assert(not elwynn.preview(battle,1,battle.actor,"S"))
assert(elwynn.preview(battle,1,battle.actor,"S",2))
assert(not elwynn.preview(battle,1,battle.actor,"S",4))
local masteryAtStart={}
for id,c in pairs(elwynn.db.cards) do masteryAtStart[id]=c.mastery or 0 end
while not battle.winner do
    local best
    for pos=1,3 do
        for _,move in ipairs({"A","S","B"}) do
            for pick=0,#battle.hand do
                local tactic=pick>0 and pick or nil
                local event=elwynn.preview(battle,1,pos,move,tactic)
                if event then
                    local score=event.hit*4+event.broken+event.focus+event.guard*0.5+(event.mark and 2 or 0)-(tactic and .25 or 0)
                    if not best or score>best.score then best={pos=pos,move=move,tactic=tactic,event=event,score=score} end
                end
            end
        end
    end
    local previous=battle.seq
    assert(best)
    elwynn.act(best.pos,best.move,best.tactic)
    local actual=battle.events[previous+1]
    assert(actual.hit==best.event.hit and actual.absorbed==best.event.absorbed and actual.tactic==best.event.tactic)
    local response=battle.events[previous+2]
    if response then
        assert(response.side~=battle.me)
        assert(#battle.hand<=3)
    end
    assert(#battle.draw+#battle.hand+#battle.discard==3)
end
assert(battle.winner==1)
local participants={}
for _,event in ipairs(battle.events) do
    if event.side==battle.me then participants[battle[1].cards[event.slot].id]=true end
end
local before={}
for id,c in pairs(elwynn.db.cards) do
    before[id]=c.mastery or 0
    assert(before[id]==masteryAtStart[id]+(participants[id] and 1 or 0))
end
elwynn.finish(battle)
for id,c in pairs(elwynn.db.cards) do assert((c.mastery or 0)==before[id]) end
local cycle=elwynn.board(elwynn.snapshot({113,822,40},true),elwynn.snapshot({80,118,735},false))
cycle.me,cycle.solo,cycle.expansion=1,true,true
cycle.hand,cycle.draw,cycle.discard={1,2,3},{},{}
for turn=1,4 do
    local slot=turn%2+1
    local tactic=cycle.hand[1]
    assert(elwynn.play(cycle,1,slot,"B",1))
    assert(#cycle.hand==2 and cycle.discard[#cycle.discard]==tactic)
    assert(not elwynn.play(cycle,1,3,"A",1) and #cycle.hand==2)
    assert(elwynn.play(cycle,2,slot,"B"))
    assert(#cycle.hand==3 and #cycle.hand+#cycle.draw+#cycle.discard==3)
end
assert(cycle.hand[3]==1 and #cycle.discard==0)
print("PASS first discoveries, event order, reload, mastery, repeat guarantee, solo isolation, tactics and previews")

-- The same legal move is evaluated on a copy before it is committed.
local H=client(true)
assert(H.speciesOf(999999)[1]=="Unknown habitat" and H.speciesOf(704)[2]=="Wolf")
H.migrate({schema=5,sounds=false})
assert(H.db.audioMode=="Off")
H.migrate({})
local function startTeam(ids)
    for _,id in ipairs(ids) do H.define(id).lifetime=1 end
    H.db.decks.Test=ids H.db.active="Test"
    assert(H.solo("Sentinel"))
    local b=H.match
    b.timeline,b.queue,b.arena=nil,nil,nil
    b[1].hp,b[2].hp=34,34
    b[1].last,b[2].last=nil,nil
    return b
end
local function commit(b,pos,move,aid)
    b.turn=1
    local primer,tunnel,seq,shield=b[1].whiteoutPrimer,b[1].tunnelPrimer,b.seq,b[2].shield
    local forecast=assert(H.preview(b,1,pos,move,aid))
    assert(b[1].whiteoutPrimer==primer and b[1].tunnelPrimer==tunnel and b.seq==seq and b[2].shield==shield)
    assert(H.play(b,1,pos,move,aid))
    local ev=b.events[b.seq]
    for _,key in ipairs({"hit","absorbed","broken","guard","setup","payoff"}) do assert(ev[key]==forecast[key],key) end
    return ev
end
local wolves={118,704,1125}
local pack=startTeam(wolves,"pack")
assert(H.qualifies(wolves,"whiteout") and H.qualifies(wolves,"pack"))
pack[1].focus=3
assert(commit(pack,1,"S").setup=="pack" and pack[2].markWolf==118)
pack[2].shield=2
local strike=commit(pack,2,"A")
assert(strike.payoff=="pack" and strike.absorbed==2 and strike.hit==pack[1].cards[2].power+3)
pack[1].focus=3
commit(pack,1,"S") assert(commit(pack,2,"A").payoff=="pack")
pack=startTeam(wolves,"pack") pack[1].focus=3
commit(pack,1,"S") pack.hand={2}
assert(not commit(pack,2,"A",1).payoff and not pack[2].markWolf)
pack=startTeam({118,704,735},"pack")
pack[1].focus=3
commit(pack,1,"S") commit(pack,3,"B")
assert(not commit(pack,1,"A").payoff)
local tunnel=startTeam({40,80,299},"tunnel")
tunnel[1].focus=3 tunnel[2].shield=3 tunnel.hand={3}
assert(not commit(tunnel,1,"S",1).setup)
commit(tunnel,3,"B") tunnel[1].focus=3 tunnel[2].shield=4
assert(commit(tunnel,1,"S").setup=="tunnel")
tunnel[1].focus=3 tunnel[1].shield=5
assert(commit(tunnel,2,"S").payoff=="tunnel" and tunnel[1].shield==6)
local snowy=startTeam(wolves,"whiteout")
local primed=commit(snowy,2,"B")
assert(primed.setup=="whiteout" and primed[1].whiteoutPrimer==704)
assert(not commit(snowy,1,"A").payoff and not commit(snowy,2,"A").payoff)
snowy[2].shield=4
local broke=commit(snowy,3,"A")
assert(broke.payoff=="whiteout" and broke.broken==2 and not broke[1].whiteoutPrimer and not snowy[1].whiteoutPrimer)
assert(commit(snowy,2,"B").setup=="whiteout")
for _,key in ipairs(startTeam({299,822,40})[1].synergies) do assert(key~="whiteout") end
startTeam({705,704,118})
H.db.cards[705].role="Keeper" H.db.cards[704].role="Hunter"
local stacked=startTeam({705,704,118})
assert(commit(stacked,1,"B").setup=="whiteout")
stacked[2].shield=4
local frostHit=commit(stacked,2,"A")
assert(frostHit.payoffs[1]=="whiteout" and not frostHit.payoffs[2])
do
    assert(#H.typeOrder==18 and #H.actions(true)==4)
    assert(table.concat(H.typesOf(724),"/")=="Brute/Frost")
    assert(not H.qualifies({724,724},"whiteout"))
    local typed=startTeam({724,1553,3124})
    assert(H.qualifies({724,1553},"rime"))
    assert(H.moveName(typed[1].cards[1],"X",true,true)=="Snap Freeze")
    assert(H.moveName(typed[1].cards[2],"X",true,true)=="Buffeting Wings")
    typed[1].focus=0
    assert(not H.legal(typed,1,1,"X"))
    typed[1].focus=2
    assert(commit(typed,1,"X").setup=="rime" and typed[1].focus==1)
    typed[2].shield=3
    local hit=commit(typed,2,"A")
    assert(hit.payoff=="rime" and hit.broken==2)

    -- Type alone cannot qualify a pairing. A Tide/Martial scout uses Feint,
    -- while the Streamrunner's Undertow can set up an Ember partner.
    local ember=88992
    H.species[ember]={"Test Shore","Elemental",nil,"Fire Elemental"}
    assert(not H.qualifies({275662,ember},"steam"))
    assert(H.qualifies({735,ember},"steam"))
    H.species[ember]=nil

    local pair=H.synergyPairings({724,1553})[1]
    assert(pair.key=="rime" and pair.matches[1].from==724 and pair.matches[1].to==1553)
    assert(table.concat(pair.matches[1].setup,",")=="Snap Freeze,Rimebreaker")
    local arena=H.board({typed[1].cards[1],typed[1].cards[2]},{typed[2].cards[1],typed[2].cards[2]})
    arena.solo,arena.movesets,arena.timeline,arena.arena=true,true,true,true
    arena.actor,arena.queue=1,{7,8,9,10}
    for i=1,2 do
        arena[i].hp=24
        arena[i].units={{hp=12,maxHP=12,shield=3},{hp=12,maxHP=12,shield=3}}
    end
    arena[1].focus,arena[1].synergies=3,{"rime"}
    assert(H.play(arena,1,1,"S",nil,1))
    assert(arena.events[1].setup=="rime")
    arena.turn,arena.actor,arena[1].focus=1,2,2
    arena[2].units[1].shield=3
    local wrong=assert(H.preview(arena,1,2,"S",nil,2))
    local right=assert(H.preview(arena,1,2,"S",nil,1))
    assert(not wrong.payoff and right.payoff=="rime" and right.broken==2)
    assert(arena[1].synergySetup.target==1 and arena[2].units[1].shield==3)

    typed.movesets=false
    assert(not H.legal(typed,1,1,"X"))
    local shell=startTeam({3107,1553,3124})
    shell.arena=true
    assert(not H.requiresTarget(shell,"B",nil,1,1))
    assert(H.requiresTarget(shell,"A",nil,1,1))
    assert(H.requiresTarget(shell,"X",nil,1,1))
    local turtle=H.define(88889,"Field Turtle")
    turtle.sighting={"Unknown habitat","Turtle"}
    H.species[88889]={"Test Shore","Turtle"}
    local single=H.board(H.snapshot({88889},true),H.snapshot({299},false))
    single.arena,single.movesets,single.me=true,true,1
    assert(not H.requiresTarget(single,"X",nil,1,1))
    single.hand={2}
    assert(H.requiresTarget(single,"X",1,1,1))
    assert(H.cardMovePreview(88889,"X").guard==4)
    H.species[88889]=nil
    for _,id in ipairs({88889,3107,724,1553,3124}) do H.db.cards[id]=nil end
end
local area=H.journalStats()
assert(area.total>=area.owned and #area.zones["Dun Morogh"].owned==3)
local testCard=H.define(88880)
local beforeCopies,beforeMastery=testCard.lifetime,testCard.mastery or 0
H.copy(testCard)
assert(testCard.lifetime==beforeCopies+1 and testCard.mastery==beforeMastery+1)
testCard.progress=100
assert(H.prestige(testCard) and testCard.mastery==beforeMastery+1 and testCard.lifetime==beforeCopies+1)
FieldGuideForever={API={
    Zones=function() return {{name="North"},{name="South"}} end,
    Species=function(zone) return {{id=88880,name="Shared",zone="North"},
        {id=zone=="North" and 88881 or 88882,name="Hidden"}} end,
}}
assert(H.speciesOf(707)[1]=="Dun Morogh")
assert(H.validTactics({}) and H.validTactics({1,2,3}) and not H.validTactics({1,1}) and not H.validTactics({1,2,3,4}))
H.db.tacticDecks.Old={2,2,6,4,3,1}
assert(table.concat(H.tacticDeck("Old"),",")=="2,6,4")
local expanded=H.journalStats()
assert(expanded.extended and expanded.zones.North.total==2 and expanded.zones.South.total==2)
assert(#expanded.zones.North.owned==1 and #expanded.zones.South.owned==1)
assert(expanded.total==area.total+3 and expanded.owned==area.owned+1)
FieldGuideForever=nil
local cachedClient=client(true)
cachedClient.db.areaCatalog=H.db.areaCatalog
local cached=cachedClient.journalStats()
assert(cached.zones.North.total==2 and #cached.zones.North.owned==0)
local areaLoader=client(true)
FieldGuideForever={API={
    Zones=function() return {{name="A"},{name="B"},{name="C"},{name="D"},{name="Empty"}} end,
    Species=function() return {} end,
}}
assert(areaLoader.catalogueProgress()=="waiting")
assert(areaLoader.loadCatalogue())
local state,done,expected=areaLoader.catalogueProgress()
assert(state=="loading" and done==4 and expected==5)
assert(areaLoader.loadCatalogue() and areaLoader.catalogueProgress()=="ready")
assert(areaLoader.journalStats().zones.Empty.total==0)
local restored=client(true)
restored.db.areaCatalog=areaLoader.db.areaCatalog
local originalZones=FieldGuideForever.API.Zones
FieldGuideForever.API.Zones=function() error("cached atlas must skip provider enumeration") end
assert(restored.loadCatalogue() and restored.catalogueProgress()=="ready")
assert(restored.journalStats().zones.Empty.total==0)
FieldGuideForever.API.Zones=originalZones
local refreshed=client(true)
refreshed.db.areaCatalog=restored.db.areaCatalog
local previousMetadata=C_AddOns
C_AddOns={GetAddOnMetadata=function() return "updated" end}
assert(refreshed.loadCatalogue() and refreshed.catalogueProgress()=="loading")
assert(refreshed.db.areaCatalog==restored.db.areaCatalog)
assert(refreshed.loadCatalogue() and refreshed.catalogueProgress()=="ready")
assert(refreshed.db.areaCatalog.key~=restored.db.areaCatalog.key)
C_AddOns=previousMetadata
FieldGuideForever=nil
local fallback=client(true)
C_Map={GetMapInfo=function(id) return id==27 and {name="Dun Morogh",mapType=3} end}
LibQuestieDB={
    Npc={GetAllIds=function() return {724,99998} end,GetAll=function(id)
        return {"NPC "..id,0,1,{[1]={{10,20}}}}
    end},
    Support={Get=function() return {private={areaIdToUiMapId="{ [1] = 27 }"}} end},
}
assert(fallback.loadCatalogue() and fallback.catalogueProgress()=="ready")
assert(fallback.journalStats().zones["Dun Morogh"].ids[99998])
assert(fallback.speciesOf(724)[3]=="Coldridge Valley")
assert(fallback.habitatStyle("Tirisfal Glades").art=="Gloom")
LibQuestieDB,C_Map=nil,nil
local oldGuid=UnitGUID
UnitGUID=function() return "Creature-0-1-2-3-88880-0FF" end
assert(H.ownershipStatus("target")==true)
UnitGUID=function() return "Creature-0-1-2-3-88882-0FF" end
assert(H.ownershipStatus("target")==false)
UnitGUID=function() return secret end
assert(H.ownershipStatus("target")==nil)
do
    local savedParent,savedPlates,savedAttack=UIParent,C_NamePlate,UnitCanAttack
    local justify="CENTER"
    local name={GetWidth=function() return 140 end,GetStringWidth=function() return 100 end,
        GetJustifyH=function() return justify end}
    local plate={UnitFrame={name=name,healthBar={}}}
    local badge={
        SetSize=function(_,width,height) assert(width==12 and height==12) end,
        SetAlpha=function(self,alpha) self.alpha=alpha end,
        ClearAllPoints=function() end,
        SetPoint=function(_,point,relative,side,x,y)
            assert(point=="LEFT" and relative==name and side=="RIGHT" and y==0)
            assert(x==(justify=="CENTER" and -15 or 5))
        end,
        SetTexture=function(self,asset) self.asset=asset end,
        Show=function(self) self.visible=true end,
        Hide=function(self) self.visible=false end,
    }
    local created=0
    UIParent={CreateTexture=function() created=created+1 return badge end}
    C_NamePlate={GetNamePlateForUnit=function() return plate end}
    UnitCanAttack=function() return true end
    H.media="Media/"
    UnitGUID=function() return "Creature-0-1-2-3-88882-0FF" end
    H.updateOwnershipPlate("nameplate1")
    assert(badge.visible and badge.asset=="Media/OwnershipDark.tga")
    local darkAlpha=badge.alpha
    UnitGUID=function() return "Creature-0-1-2-3-88880-0FF" end
    H.refreshOwnershipPlates()
    assert(badge.visible and badge.asset=="Media/OwnershipGold.tga" and created==1 and badge.alpha>darkAlpha and badge.alpha<1)
    justify="RIGHT"
    H.refreshOwnershipPlates()
    assert(badge.visible)
    plate.UnitFrame.name=nil
    H.refreshOwnershipPlates()
    assert(not badge.visible)
    plate.UnitFrame.Name=name
    UnitCanAttack=function() return false end
    H.refreshOwnershipPlates()
    assert(not badge.visible)
    H.hideOwnershipPlate("nameplate1")
    UnitCanAttack=function() return true end
    H.refreshOwnershipPlates()
    assert(not badge.visible)
    UIParent,C_NamePlate,UnitCanAttack=savedParent,savedPlates,savedAttack
end
UnitGUID=oldGuid
local wolf=H.db.cards[118]
local originalMastery,originalRank=wolf.mastery,wolf.prestige
wolf.mastery,wolf.prestige=20,1
assert(H.cardMovePreview(118,"A").hit==wolf.power+1)
assert(H.cardMovePreview(118,"S").hit==wolf.power+1)
local brace=H.cardMovePreview(118,"B")
assert(brace.guard==4 and brace.focus==2)
wolf.mastery,wolf.prestige=originalMastery,originalRank
local duelBoard=startTeam(wolves,"pack")
duelBoard.solo=false duelBoard[1].focus=3
assert(not commit(duelBoard,1,"S").setup and not commit(duelBoard,2,"A").payoff)
print("PASS habitat fallback, eligibility, wolf mark attribution, capped tunnel shield, Whiteout primer, preview parity and duel isolation")

do
    local client=client(true)
    local function arena(left,right)
        for _,group in ipairs({left,right}) do
            for _,id in ipairs(group) do client.define(id).lifetime=1 end
        end
        local b=client.board(client.snapshot(left,true),client.snapshot(right,false))
        b.me,b.solo,b.expansion,b.movesets,b.arena,b.timeline,b.actor=1,true,true,true,true,true,1
        b.queue={}
        for side,team in ipairs(b) do
            team.units,team.hp={},0
            team.synergies=client.activeSynergies(side==1 and left or right)
            for i,card in ipairs(team.cards) do
                team.units[i]={hp=11,maxHP=11,shield=0}
                team.hp=team.hp+11
                b.queue[(i-1)*2+side]=16-client.cardSpeed(card)
            end
        end
        return b
    end

    local cap=arena({299},{113})
    cap.turn,cap.seq,cap.queue=2,59,{7,6}
    cap[1].hp,cap[1].units[1].hp,cap[1].units[1].shield=4,4,2
    cap[2].hp,cap[2].units[1].hp,cap[2].focus,cap[2].cards[1].power=3,3,0,3
    local _,move=client.ai(cap,"Sentinel")
    assert(move=="A" and client.play(cap,2,1,move,nil,1) and cap.winner==0)
    assert(not client.preview(cap,cap.turn,1,"A",nil,1))

    local frost=arena({724,1553},{822,113})
    frost[1].focus=2
    local setup,trial=client.preview(frost,1,1,"S",nil,1)
    local windows=client.comboWindows(trial,1,setup)
    assert(setup.setup=="rime" and windows[1].moves[1]=="Talon Sweep")
    assert(windows[1].target==frost[2].cards[1].name and windows[1].expires:find("next action",1,true))
    frost[1].hp,frost[1].units[2].hp,frost.queue[3]=11,0,math.huge
    local noPartner=client.preview(frost,1,1,"S",nil,1)
    assert(#noPartner.setups==0 and #client.comboWindows(frost,1,frost)==0)
    frost[2].units[1].hp,frost[2].hp=1,12
    local knockout=client.preview(frost,1,1,"S",nil,1)
    assert(knockout.knockout and knockout.delay==0)

    local mastered=arena({724},{822})
    mastered[1].focus,mastered[1].cards[1].tier=1,4
    local technique=client.preview(mastered,1,1,"X",nil,1)
    assert(technique.delay==3 and technique.focus==-1)

    local pressure=arena({724},{822})
    pressure.seq=3
    pressure[1].units[1].lastHit,pressure[1].units[1].lastAction=3,2
    pressure[1].focus=0
    assert(client.preview(pressure,1,1,"B").focus==2)
    pressure[1].braced=true
    assert(client.preview(pressure,1,1,"B").focus==1)

    for name,opponent in pairs(client.soloOpponents) do
        assert(#client.activeSynergies(opponent.roster)==2,name)
    end
    client.db.decks.Audit,client.db.active={299,822,113},"Audit"
    assert(client.solo("Veteran"))
    local veteran=client.match
    veteran.turn,veteran.actor=2,1
    veteran.rivalTactics={hand={2},draw={},discard={}}
    local playerHand=#veteran.hand
    local event,projected=client.preview(veteran,2,1,"A",1,1)
    assert(event and event.tactic==2 and #projected.rivalTactics.hand==0)
    assert(#veteran.rivalTactics.hand==1 and #veteran.hand==playerHand)
    assert(client.play(veteran,2,1,"A",1,1))
    assert(#veteran.rivalTactics.hand==0 and veteran.rivalTactics.discard[1]==2)
end

local optimizer=client(true)
assert(optimizer.optimizeDeck()==nil)
for _,id in ipairs({118,299,704,822}) do
    local card=optimizer.define(id)
    card.role,card.power="Hunter",3
    optimizer.copy(card)
end
local optimized,recommended=optimizer.optimizeDeck()
assert(#recommended==optimizer.maxTactics and optimizer.validTactics(recommended))
assert(optimizer.validate(optimized,true))
assert(optimizer.qualifies(optimized,"pack"))
assert(table.concat(optimized,",")==table.concat(optimizer.optimizeDeck(),","))
assert(not optimizer.db.active and not next(optimizer.db.decks))

local hunter={id=118,role="Hunter",name="Hunter",power=3,tier=0,rank=0}
local hexer={id=94,role="Hexer",name="Hexer",power=3,tier=0,rank=0}
local tempo=optimizer.board({hunter,hexer},{hunter,hexer})
tempo.solo,tempo.timeline,tempo.me,tempo.actor=true,true,1,1
tempo.queue={7,7,8,8}
assert(optimizer.turnTimeline(tempo)[2].side==2)
assert(not optimizer.legal(tempo,1,2,"A"))
local haste,forecast=optimizer.preview(tempo,1,1,"B")
assert(haste.haste==2 and forecast.queue[1]==12 and tempo.queue[1]==7)
assert(optimizer.play(tempo,1,1,"B") and tempo.turn==2)
assert(optimizer.play(tempo,2,1,"B") and tempo.actor==2)
tempo[1].focus=2
assert(optimizer.play(tempo,1,2,"S") and tempo.queue[4]==10)

-- Equal timestamps wrap past the previous actor, and same-team actions preserve guard.
local balance=optimizer.board({hunter,hexer},{hunter,hexer})
balance.solo,balance.timeline,balance.expansion,balance.me,balance.actor=true,true,true,1,1
balance.queue={7,14,8,16}
assert(optimizer.play(balance,1,1,"B") and balance.turn==1 and balance.actor==2)
assert(optimizer.play(balance,1,2,"A") and balance[1].shield==3)
assert(optimizer.play(balance,1,1,"B") and balance[1].shield==6)
assert(optimizer.play(balance,2,1,"A"))
assert(balance[1].shield==3)
local followUp=assert(optimizer.preview(balance,1,balance.actor,"B"))
assert(followUp.haste==0)
balance.queue,balance.lastActor={22,22,22,22},3
assert(optimizer.turnTimeline(balance)[1].key==4)

-- Target previews keep live HP, statuses, and the initiative queue untouched.
assert(elwynn.solo("Prowler"))
local targeted=elwynn.match
local current=targeted.actor
assert(#elwynn.perks==25 and elwynn.tier({mastery=1399})==24 and elwynn.tier({mastery=1400})==25)
local chance,limit=elwynn.repeatOdds({rarity="Legendary"})
assert(chance==.01 and limit==22)
local attacker=targeted[1].cards[current]
local previousTier=attacker.tier
attacker.tier=25
targeted[2].units[1].shield=5
local previousFocus=targeted[1].focus
targeted[1].focus=1
local masteredHit=assert(elwynn.preview(targeted,1,current,"X",nil,1))
targeted[1].focus=previousFocus
assert(masteredHit.broken==3 and targeted[2].units[1].shield==5)
attacker.tier=previousTier

local enemies=targeted[2].units
enemies[1].shield=4
enemies[2].mark=true
enemies[3].hp=1
targeted[2].hp=enemies[1].hp+enemies[2].hp+enemies[3].hp
local shielded=assert(elwynn.preview(targeted,1,current,"A",nil,1))
local marked=assert(elwynn.preview(targeted,1,current,"A",nil,2))
local finish=assert(elwynn.preview(targeted,1,current,"A",nil,3))
assert(shielded.absorbed>0 and marked.combo and finish.knockout)
assert(enemies[1].shield==4 and enemies[2].mark and enemies[3].hp==1)
assert(elwynn.play(targeted,1,current,"A",nil,3))
assert(not targeted.winner and enemies[3].hp==0 and targeted.queue[6]==math.huge)
for _,turn in ipairs(elwynn.turnTimeline(targeted)) do assert(turn.key~=6) end

-- Exercise the real entry point and UI callbacks with a minimal widget surface.
F.match=nil
local widgets={}
local noop=function() end
local methods={}
local function widget(kind,name,parent)
    local w=setmetatable({kind=kind,name=name,parent=parent,scripts={},visible=true,enabled=true},{__index=function(_,k) return methods[k] or (k:match("^%u") and noop) end})
    widgets[#widgets+1]=w
    return w
end
methods.SetScript=function(w,event,fn) w.scripts[event]=fn end
methods.GetScript=function(w,event) return w.scripts[event] end
methods.EnableGamePadButton=function(w,enabled) w.padEnabled=enabled end
methods.GetFrameLevel=function() return 2 end
methods.GetModelFileID=function() return nil end
methods.SetText=function(w,s) w.text=s end
methods.GetText=function(w) return rawget(w,"text") or "" end
methods.SetEnabled=function(w,b) w.enabled=b end
methods.IsShown=function(w) return w.visible end
methods.Show=function(w) w.visible=true end
methods.Hide=function(w)
    local visible=w.visible
    w.visible=false
    if visible and w.name=="FeralDeckPanel" and w.scripts.OnHide then w.scripts.OnHide(w) end
end
methods.GetHighlightTexture=function(w) return widget("texture",nil,w) end
methods.SetFont=function(w,path,size,flags)
    assert(type(flags)=="string","SetFont requires explicit flags")
    if w.name=="FeralDeckDisabledFont" then error("test font could not load") end
    w.fontPath=path
end
methods.GetFont=function(w) return w.fontPath end
methods.CreateFontString=function(w) return widget("text",nil,w) end
methods.CreateTexture=function(w) return widget("texture",nil,w) end
local windowW,windowH=1280,800
methods.SetSize=function(w,x,y) w.width,w.height=x,y end
methods.SetWidth=function(w,x) w.width=x end
methods.SetHeight=function(w,y) w.height=y end
methods.SetScale=function(w,x) w.scale=x end
methods.SetPoint=function(w,anchor,parent,relative,x,y)
    if type(x)=="number" then w.x,w.y=x,-y end
end
methods.IsVisible=function(w)
    if not w.visible then return false end
    local parent=rawget(w,"parent")
    return not parent or parent:IsVisible()
end
local cues={}
PlaySoundFile=function(path) cues[path]=(cues[path] or 0)+1 end
local function countCue(name) return cues[F.media..name..".mp3"] or 0 end

methods.GetWidth=function() return windowW end
methods.GetHeight=function() return windowH end
CreateFrame=widget UIParent=widget() SlashCmdList={} UISpecialFrames={} C_Timer={NewTicker=noop}
CreateFont=function(name)
    local font=widget("font",name)
    font.name=name
    return font
end
assert(loadfile(root.."Theme.lua"))("FeralDeck",F)
assert(F.fonts.body:GetFont()==F.media.."Barlow-Medium.ttf")
assert(F.fonts.brand:GetFont()==F.media.."Cinzel-Regular.ttf")
assert(F.fonts.disabled=="GameFontDisable")
assert(loadfile(root.."JournalCard.lua"))("FeralDeck",F)
assert(loadfile(root.."Controller.lua"))("FeralDeck",F)
assert(loadfile(root.."Panel.lua"))("FeralDeck",F)
widgets[#widgets].scripts.OnEvent(nil,"ADDON_LOADED","FeralDeck")
local function click(text)
    for _,w in ipairs(widgets) do
        if w:IsVisible() and w.enabled and w:GetText():gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")==text and w.scripts.OnClick then w.scripts.OnClick() return end
    end
    error("missing button "..text)
end
assert(#F.owned()==0)
math.random=function() return 0 end
for _,id in ipairs({299,822,40}) do
    guid=("Creature-0-1-2-3-%d-0FF"):format(id)
    F.loot(false)
end
math.random=fixtureRandom
assert(countCue("discovery")==1 and F.db.cards[40].unseen)
local function tickVisible(dt)
    local callbacks={}
    for _,w in ipairs(widgets) do
        if w:IsVisible() and w.scripts.OnUpdate then callbacks[#callbacks+1]=w end
    end
    for _,w in ipairs(callbacks) do
        if w:IsVisible() and w.scripts.OnUpdate then w.scripts.OnUpdate(w,dt) end
    end
end
tickVisible(3) tickVisible(3) tickVisible(3)
assert(countCue("discovery")==1)
F.loot(false)
F.migrate(F.db)
assert(countCue("discovery")==1 and F.db.cards[40].unseen)
SlashCmdList.FERALDECK()
local function pad(button)
    for _,w in ipairs(widgets) do
        if w.name=="FeralDeckPanel" then
            assert(w:IsVisible() and w.padEnabled)
            w.scripts.OnGamePadButtonDown(w,button)
            return w
        end
    end
    error("missing controller input frame")
end
local function controllerVisible(text)
    for _,w in ipairs(widgets) do
        if w:IsVisible() and w:GetText():gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")==text then return true end
    end
end
do
    local panel=pad("PADRSHOULDER")
    assert(controllerVisible("Saved decks"))
    pad("PADRSHOULDER")
    assert(controllerVisible("Prowler"))
    pad("PADRSHOULDER")
    assert(controllerVisible("Cards"))
    pad("PADDDOWN")
    pad("PAD1")
    assert(controllerVisible("Done") and not controllerVisible("Cards"))
    pad("PAD1")
    assert(controllerVisible("1"))
    pad("PAD4")
    assert(controllerVisible("No discoveries match your filters."))
    click("Clear")
    pad("PAD2")
    assert(not panel:IsShown() and not panel.padEnabled)
    SlashCmdList.FERALDECK()
    assert(panel:IsShown() and panel.padEnabled)
    click("Settings")
    click("Controller: on")
    assert(F.db.controllerNav==false and not panel.padEnabled)
    panel.scripts.OnGamePadButtonDown(panel,"PADRSHOULDER")
    assert(controllerVisible("Controller: off"))
    click("Controller: off")
    assert(F.db.controllerNav and panel.padEnabled)
    pad("PAD2")
    assert(panel:IsVisible() and controllerVisible("Cards"))
end
click("Areas")
click("Elwynn Forest")
click("Statistics")
click("Cards")
local unread=0
local previousTooltip=GameTooltip
local tooltipText={}
GameTooltip={
    SetOwner=noop,Show=noop,
    SetText=function(_,value) tooltipText[#tooltipText+1]=value end,
    AddLine=function(_,value) tooltipText[#tooltipText+1]=value end,
}
for _,w in ipairs(widgets) do
    if w:IsVisible() and w:GetText():find("|cfff1cd88New|r",1,true) and w.scripts.OnClick then
        assert(w.scripts.OnMouseWheel)
        w.scripts.OnEnter()
        unread=unread+1
    end
end
GameTooltip=previousTooltip
assert(unread==3)
local tips=table.concat(tooltipText,"\n"):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
assert(tips:find(" Burrow\nHabitat  Elwynn Forest\nSolo signature  Pickaxe Split",1,true))
assert(tips:find(" Pack\nHabitat  Elwynn Forest\nSolo signature  Scent of Blood",1,true))
assert(not tips:find("Keeper",1,true))
click("Latest discovery")
local function inspected()
    for _,w in ipairs(widgets) do
        if rawget(w,"back") and w:IsVisible() and w.scripts.OnUpdate and w.scripts.OnClick then return w end
    end
end
local firstFace=assert(inspected())
assert(firstFace.back:IsShown())
firstFace.scripts.OnClick(firstFace)
assert(not inspected().back:IsShown())
F.refresh()
assert(not inspected().back:IsShown())
local over,down,px=true,false,140
GetCursorPosition=function() return px,100 end
IsMouseButtonDown=function() return down end
methods.GetEffectiveScale=function() return 1 end
methods.GetCenter=function() return 100,100 end
methods.IsMouseOver=function() return over end
tickVisible(.12)
local activeFace=assert(inspected())
assert(activeFace.dx>0)
down=true tickVisible(.05) px=180 tickVisible(.12)
assert(activeFace.dx>2)
over,down=false,false tickVisible(.12)
assert(activeFace.dx==0)
local function fieldMetricTips(expected)
    local original=GameTooltip
    local tips,title,count={},nil,0
    GameTooltip={
        SetOwner=noop,Show=noop,Hide=noop,
        SetText=function(_,value) title=value tips[title]={} end,
        AddLine=function(_,value) table.insert(tips[title],value) end,
    }
    for _,w in ipairs(widgets) do
        if w:IsVisible() and w.width==244 and w.height==30 and w.scripts.OnEnter then
            w.scripts.OnEnter(w)
            w.scripts.OnLeave(w)
            count=count+1
        end
    end
    GameTooltip=original
    assert(count==expected,("Expected %d field metrics, saw %d"):format(expected,count))
    for name,lines in pairs(tips) do
        assert(#lines==3 and lines[1]:match("^|c") and lines[2]==" ")
        tips[name]=lines[3]
    end
    return tips
end
click("Field notes")
assert(not inspected())
assert(fieldMetricTips(13)["Last credited kill"]:find("most recent kill",1,true))
click("Combat")
click("Battle stats")
assert(fieldMetricTips(19)["Damage blocked"]:find("absorbed",1,true))
click("Solo Battle")
assert(fieldMetricTips(10).Braces:find("defensive move",1,true))
click("Records")
assert(fieldMetricTips(11)["Win rate"]:find("including draws",1,true))
click("Friendly duels")
assert(fieldMetricTips(12)["Mastery XP from wins"]:find("Solo Battle",1,true))
local function guideText(text)
    for _,w in ipairs(widgets) do
        if w:IsVisible() and w:GetText():gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")==text then return true end
    end
    return false
end
click("Profile")
do
    local card=F.db.cards[40]
    local current={id=40,role=card.role}
    assert(guideText("Creature traits") and guideText("Habitat and sightings"))
    assert(guideText("Fargodeep Mine") and guideText("Solo Battle signature"))
    assert(guideText("Solo technique  "..F.moveName(current,"X",true,true)))
    assert(guideText(F.moveName(current,"S",true,true)))
    assert(guideText(F.moveDescription(current,"S",true,true)))
end
click("Collection")
local prestige,addToDraft
for _,w in ipairs(widgets) do
    if w:IsVisible() and w.scripts.OnClick then
        if w:GetText()=="Prestige" then prestige=w end
        if w:GetText()=="Add to draft" then addToDraft=w end
    end
end
assert(prestige and addToDraft and prestige.x+prestige.width<=addToDraft.x)
click("Overview")
assert(inspected())
local overviewCard=F.db.cards[40]
local oldMastery=overviewCard.mastery
overviewCard.mastery=0
F.refresh()
click("Earned perks (0)")
assert(guideText("No Mastery perks earned yet.") and not guideText("Attack +1 damage"))
overviewCard.mastery=7
F.refresh()
assert(guideText("Attack +1 damage") and guideText("Guard +1 shield"))
assert(not guideText("Signature +1 damage") and not guideText("12 XP"))
click("Overview")
assert(guideText("Mastery +1 damage") and guideText("Mastery +1 shield"))
click("Move details")
assert(guideText("Mastery adds +1 damage to the total above"))
assert(guideText("Mastery adds +1 shield to the total above"))
assert(not guideText("Attack +1 damage if the rival has 2 HP or less"))
overviewCard.mastery=1400
F.refresh()
assert(guideText("Technique Mastery: Adds 1 damage. Delays the rival 1 extra tick."))
assert(guideText("Targeted techniques break up to 3 shield"))
assert(guideText("Guard +1 shield if this card has 7 HP or less"))
assert(guideText("Signature refunds 1 Focus if the rival has 4 HP or less"))
assert(not guideText("Targeted techniques break up to 1 shield"))
click("Perks")
assert(guideText("25 unlocked") and guideText("3 XP"))
click("Next") click("Next") click("Next")
assert(guideText("1400 XP") and not guideText("3 XP"))
overviewCard.mastery=oldMastery
F.refresh()
click("Overview")

assert(not F.db.cards[40].unseen and F.db.cards[299].unseen)
assert(not guideText("Synergy partner"))
do
    local partner=F.define(80,"Kobold Laborer")
    partner.lifetime,partner.unseen=1,1
    click("Synergies")
    assert(guideText("Solo Battle effects") and guideText(partner.name))
    assert(guideText("Pickaxe Split  ->  Bunker Down"))
    local links=0
    for _,w in ipairs(widgets) do
        if w:IsVisible() and w:GetText()==partner.name and w.scripts.OnClick then
            links=links+1
        end
    end
    assert(links==1)
    click(partner.name)
    assert(inspected() and not partner.unseen)
    click(overviewCard.name)
    F.db.cards[80]=nil
    F.refresh()
end
click("Favorite")
assert(F.db.journalFavorites[40])
click("Favorites")
assert(inspected())
click("Filters (1)")
click("All rarities")
click("Clear")
click("Favorited")
assert(not F.db.journalFavorites[40])
click("Add to draft")
local function chooseFace(state)
    for _,w in ipairs(widgets) do
        local role=rawget(w,"roleText")
        if role and w:IsVisible() and role:GetText()==state and w.scripts.OnClick then
            w.scripts.OnClick(w) return
        end
    end
    error("missing face "..state)
end
chooseFace("Slot 2  /  Empty")
assert(countCue("place")==1 and not F.db.active)
click("Field Journal")
click("Equip first three")
click("Deck Builder")
click("Optimize solo roster")
assert(F.db.active=="Field Journal" and not F.db.decks["Optimized Solo"])
click("Tactics & recipes") click("Wolf Pack") click("Save and equip")
assert(F.db.active=="Wolf Pack" and F.db.decks["Wolf Pack"][2]==822 and F.db.tacticDecks["Wolf Pack"][1]==2)
click("Battle")
F.match=nil F.refresh()
local function clickAttack()
    local b=F.match
    click(F.moveName(b[b.me].cards[b.actor],"A",b.expansion,b.movesets))
end
local function strikeTarget()
    clickAttack()
    for _,w in ipairs(widgets) do
        local hp=rawget(w,"healthCaption")
        if hp and hp:IsVisible() and w:IsVisible() and w.enabled and w.scripts.OnClick then
            w.scripts.OnClick(w)
            return
        end
    end
    error("missing living rival target")
end
click("Prowler")
local initialSequence=F.match.seq
do
    local b=F.match
    local card=b[b.me].cards[b.actor]
    assert(b.movesets)
    assert(guideText("Initiative") and guideText("Team synergies"))
    local tactic=F.tactics[b.hand[1]][1]
    assert(guideText(tactic))
    click(tactic)
    assert(guideText("Queued: "..tactic))
    click(tactic)
    for _,move in ipairs(F.actions(true)) do
        assert(guideText(F.moveName(card,move,b.expansion,true)))
    end
end
clickAttack()
pad("PAD2")
assert(F.match.seq==initialSequence)
clickAttack()
for _,w in ipairs(widgets) do
    if w:IsVisible() and rawget(w,"x")==48 and rawget(w,"y")==339 and w:GetText()=="Preview target" and w.scripts.OnClick then
        w.scripts.OnClick(w)
        break
    end
end
assert(F.match.seq==initialSequence)
local showingForecast
for _,w in ipairs(widgets) do
    local cue=rawget(w,"targetCue")
    if cue and cue:IsVisible() and cue:GetText()~="" then
        assert(w.width>w.height and rawget(w,"model").kind=="PlayerModel")
        showingForecast=cue
        break
    end
end
assert(showingForecast)
pad("PAD1")
assert(not showingForecast:IsVisible())
assert(F.match.seq>=2 and F.match.events[1].targetSlot==1)
local playerMove,rivalMove=F.match.events[1],F.match.events[2]
assert(playerMove.side==F.match.me and playerMove.move=="A" and playerMove.hit>0)
assert(rivalMove.side~=playerMove.side and F.match.events[F.match.seq][1].hp==F.match[1].hp)
local function advance()
    for _,w in ipairs(widgets) do
        if w:IsVisible() and w.scripts.OnUpdate and w.kind=="Frame" then w.scripts.OnUpdate(w,1.1) return end
    end
    error("missing battle playback")
end
for _=1,F.match.seq do advance() end
local function visibleText(text)
    for _,w in ipairs(widgets) do if w:IsVisible() and w:GetText()==text then return true end end
end
local previousSynergies=F.match[1].synergies
F.match[1].synergies={"whiteout"}
F.refresh()
click("Whiteout")
assert(visibleText("Whiteout"))
click("Close details")
F.match[1].synergies=previousSynergies
F.refresh()
click("Show combat log")
assert(visibleText("|cfff1cd88Combat log|r") and visibleText("Older") and visibleText("Newer"))
assert(guideText("Initiative") and guideText(F.tactics[F.match.hand[1]][1]))
click("Concede")
assert(F.match.conceded==1 and F.match.presented and countCue("defeat")==1)
F.refresh() SlashCmdList.FERALDECK() SlashCmdList.FERALDECK()
assert(countCue("defeat")==1)
click("Rematch")
local win=F.match
F.db.cards[win[1].cards[win.actor].id].mastery=2
win[2].hp=1
for i,unit in ipairs(win[2].units) do
    unit.hp=i==1 and 1 or 0
    unit.shield=0
    if i~=1 then win.queue[i*2]=math.huge end
end
F.refresh()
strikeTarget() advance()
assert(win.winner==1 and win.presented and #win.awards==1 and countCue("victory")==1)
advance() advance()
local a=win.awards[1]
assert(a.perk=="Attack +1 damage" and countCue("perk")==1)
assert(a.after==a.before+1 and F.db.cards[a.id].mastery==a.after)
F.finish(win) F.refresh()
assert(countCue("victory")==1 and F.db.cards[a.id].mastery==a.after)
click("Rematch")
local lost=F.match
lost[1].hp=1
for i,unit in ipairs(lost[1].units) do
    unit.hp=i==lost.actor and 1 or 0
    unit.shield=0
    if i~=lost.actor then lost.queue[i*2-1]=math.huge end
end
F.refresh()

strikeTarget() advance() advance()
assert(lost.winner==2 and lost.presented and not lost.conceded and not lost.awards)
click("Back to matches") click("Sentinel")
local duel=F.board(F.match[1].cards,F.match[2].cards)
duel.me=2
F.match=duel
duel.peer="HarnessPeer"
F.net={phase="play",peer=duel.peer,id="1000000.789"}
F.refresh()
assert(not visibleText("Auto Battle") and not visibleText("Pause Auto Battle"))
F.receive("FeralDeck","3|1000000.789|M|1:1:A","WHISPER",duel.peer)
assert(duel.seq==1 and duel.events[1].sounded)
local heard=countCue("hit")
F.refresh()
assert(countCue("hit")==heard)
advance()
duel.aborted="Peer offline or timer expired."
F.net=nil F.refresh()
assert(duel.presented and visibleText("|cffb2cdf1DUEL INTERRUPTED|r"))
click("Back to matches") click("Sentinel")
local draw=F.match
for _=1,draw.seq do advance() end
draw.seq=59
draw[2].hp=draw[1].hp
assert(F.play(draw,1,draw.actor,"B"))
draw.events[60]=nil
F.finish(draw) F.refresh()
assert(draw.winner==0 and draw.presented and visibleText("|cffe1d4b4DRAW|r"))
click("Edit Deck") click("Field Journal") click("Settings") click("Motion: full") click("Sound: Full")
local n=countCue("place")
F.sound("place") assert(countCue("place")==n)
local chime=countCue("perk")
F.sound("perk") assert(countCue("perk")==chime+1)
click("Sound: Rewards Only")
assert(F.db.staticCards and F.db.sounds==false and not inspected())
F.sound("discovery") assert(countCue("discovery")==1)
click("Size: fit")
click("Background: glass")
assert(F.db.opaqueUI)
click("Back to Journal")
local preferredSize=F.db.largeUI
for _,large in ipairs({false,true}) do
    F.db.largeUI=large
    for _,size in ipairs({{800,600},{1280,720},{1920,1080},{3440,1440},{3840,2160}}) do
        windowW,windowH=size[1],size[2]
        for _,tab in ipairs({"Deck Builder","Battle","Field Journal"}) do
            click(tab)
            for _,w in ipairs(widgets) do
                local parent=rawget(w,"parent")
                if parent and rawget(parent,"scale") and w:IsVisible() and rawget(w,"x") then
                    assert(w.x>=0 and w.y>=0 and w.x+w.width<=parent.width and w.y+w.height<=parent.height)
                end
                if rawget(w,"scale") and w:IsVisible() then
                    assert(w.width*w.scale<=windowW-15 and w.height*w.scale<=windowH-15)
                    if w.name=="FeralDeckPanel" and windowH==2160 then
                        assert(w.scale==(large and 2.25 or 1.42))
                    end
                end
            end
        end
    end
end
F.db.largeUI=preferredSize
click("Battle")
F.match=nil F.refresh()
click("Prowler")
local automated=F.match
local beforeAuto=automated.seq
click("Auto Battle")
click("Pause Auto Battle")
assert(automated.seq==beforeAuto)
click("Auto Battle")
for _=1,100 do
    if automated.presented then break end
    advance()
end
assert(automated.presented and automated.recorded and automated.seq>beforeAuto)
local cardStats=F.db.cards[automated[automated.me].cards[1].id].fieldStats.solo
local matches=cardStats.matches
assert(matches>=1 and cardStats.lastBattle)
F.finish(automated)
assert(cardStats.matches==matches)

local usedTactic=false
for _,event in ipairs(automated.events) do
    if event.side==automated.me and event.tactic then usedTactic=true end
end
assert(usedTactic)
click("Rematch")
assert(visibleText("Auto Battle") and not visibleText("Pause Auto Battle"))
click("Deck Builder")
click("Saved decks")
click("All decks")
click("Delete")
assert(F.db.decks["Wolf Pack"] and F.db.active=="Wolf Pack")
click("Cancel delete")
click("Delete")
click("Confirm delete")
assert(not F.db.decks["Wolf Pack"] and not F.db.tacticDecks["Wolf Pack"] and not F.db.active)
assert(F.db.decks["Field Journal"])
print("PASS closed-panel discovery queue, persistent New, inspection, slot placement, named saving, playback, results, settings and window fit")
