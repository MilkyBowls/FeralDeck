local _, F = ...
-- Only immutable card snapshots enter the match. Wire decks carry roles because
-- the first observed creature traits can differ between collectors.
function F.snapshot(deck, solo, catalog)
    local hand={}
    for i,id in ipairs(deck) do
        local c=(not catalog and F.db.cards[id]) or F.elwynn[id] or {}
        local internal=c.lifetime==nil
        hand[i]={id=id, name=c.name or c[1] or F.speciesOf(id)[4] or ("NPC "..id), role=c.role or F.roles[id%3+1], power=c.power or 2+math.floor(id/3)%2,
            tier=solo and not internal and F.tier(c) or 0, rank=c.prestige or 0}
        hand[i].types=F.typesOf(id,c)
        hand[i].moveset=F.loadout(hand[i])
    end
    return hand
end
function F.board(a,b)
    local function team(cards) return {cards=cards,hp=34,shield=0,focus=1} end
    return {team(a),team(b),turn=1,seq=0,log={},events={}}
end
local roleSpeed={Hunter=9,Hexer=8,Keeper=7}
function F.cardSpeed(card)
    return roleSpeed[card.role] or 8
end
local function nextActor(queue,after)
    local best=after%#queue+1
    for offset=1,#queue-1 do
        local key=(after+offset)%#queue+1
        if queue[key]<queue[best] then best=key end
    end
    return best
end
local function actorKey(side,slot)
    return (slot-1)*2+side
end
local function actorPosition(key)
    return (key-1)%2+1,math.floor((key-1)/2)+1
end
function F.nextRivalSlot(b,side)
    local after=b.lastActor or 0
    local best
    for offset=0,#b.queue-1 do
        local key=(after+offset)%#b.queue+1
        local team,slot=actorPosition(key)
        if team~=side and b.queue[key]<math.huge and (not best or b.queue[key]<b.queue[best]) then
            best=key
        end
    end
    if best then return math.floor((best-1)/2)+1 end
end
function F.turnTimeline(b)
    local queue={unpack(b.queue)}
    local order={}
    local after=b.lastActor or 0
    for i=1,6 do
        local key=nextActor(queue,after)
        if queue[key]==math.huge then break end
        after=key
        local side,slot=actorPosition(key)
        order[i]={key=key,side=side,slot=slot}
        queue[key]=queue[key]+16-F.cardSpeed(b[side].cards[slot])
    end
    return order
end
function F.speedEffect(card,move,repeatedBrace)
    if card.role=="Hunter" and move=="B" and not repeatedBrace then return 2,0 end
    if card.role=="Hexer" and move=="S" then return 0,2 end
    return 0,0
end
function F.moveDefinition(card,move,typed)
    if typed then return (card.moveset or F.loadout(card))[move] end
end

local function tacticPile(b,side)
    if side==b.me then return b end
    return b.rivalTactics
end

local function tacticsFor(b,side)
    local pile=tacticPile(b,side)
    return pile and pile.hand
end

local function refillTactics(pile)
    if not pile or not pile.hand or #pile.hand>=F.maxTactics then return end
    if #pile.draw==0 then pile.draw,pile.discard=pile.discard,{} end
    if #pile.draw>0 then pile.hand[#pile.hand+1]=table.remove(pile.draw,1) end
end

function F.moveTargetsRival(definition)
    return not not (definition.power or definition.mark or definition.delay or definition.shatter or definition.drain)
end

function F.requiresTarget(b,move,tactic,side,slot)
    if not b.arena then return false end
    local hand=tacticsFor(b,side)
    local aid=tactic and hand and hand[tactic]
    if aid==2 or aid==3 then return true end
    local d=F.moveDefinition(b[side].cards[slot],move,b.movesets)
    if d then return F.moveTargetsRival(d) end
    return move~="B"
end
function F.legal(b, side, slot, move, tactic, target)
    if b.winner~=nil or b.aborted or side~=b.turn then return false,"Wait for your turn." end
    local p=b[side]
    if not p.cards[slot] then return false,"Unknown card." end
    if b.arena and target and (not b[3-side].units[target] or b[3-side].units[target].hp<=0) then
        return false,"Choose a living rival."
    end
    if b.arena and p.units[slot].hp<=0 then return false,"This creature is knocked out." end
    if b.timeline and slot~=b.actor then return false,"This creature is waiting for its timeline slot." end
    if not b.timeline and p.last==slot then return false,"Resting until another card acts." end
    local hand=tacticsFor(b,side)
    if tactic and (not hand or not hand[tactic]) then return false,"Choose a tactic in hand." end
    local study=tactic and hand[tactic]==1 and 1 or 0
    local definition=F.moveDefinition(p.cards[slot],move,b.movesets)
    if not definition and move~="A" and move~="B" and move~="S" then return false,"Choose a move." end
    local cost=definition and math.max(0,-definition.focus) or (move=="S" and 2 or 0)
    if p.focus+study<cost then return false,("Requires %d Focus."):format(cost) end
    return true
end
F.moves={A="Strike",B="Brace",S="Signature"}
local beats={Hunter="Hexer",Hexer="Keeper",Keeper="Hunter"}
function F.moveStats(c,move,targetRole,solo)
    local damage,shield,focus,edge=0,0,1,0
    local pierce,mark=false,false
    if move=="B" then
        shield=3+(c.tier>=2 and 1 or 0)
        if solo and c.rank>0 then focus=2 end
    elseif move=="A" then
        damage=c.power+(c.tier>=1 and 1 or 0)+(c.tier>=4 and 1 or 0)
    else
        focus=-2
        edge=beats[c.role]==targetRole and 1 or (beats[targetRole]==c.role and -1 or 0)
        damage=c.power+(c.tier>=3 and 1 or 0)+edge
        if c.role=="Hunter" then pierce=true damage=damage+1
        elseif c.role=="Keeper" then shield=3
        else mark=true end
    end
    return damage,shield,focus,edge,pierce,mark
end
function F.moveName(c,move,expansion,typed)
    local definition=F.moveDefinition(c,move,typed)
    if definition then return definition.name end
    if move~="S" then return F.moves[move] end
    local entry=expansion and F.elwynn[c.id]
    return entry and entry[2] or ({Hunter="Pounce",Keeper="Bulwark",Hexer="Brand"})[c.role]
end
function F.moveDescription(card,move,expansion,typed)
    local d=F.moveDefinition(card,move,typed)
    if not d then
        if move=="A" then return "Deal damage and gain 1 Focus." end
        if move=="B" then
            return expansion and "Gain shield and Focus. Consecutive Braces grant less shield."
                or "Gain 3 shield and 1 Focus."
        end
        return (expansion and F.elwynn[card.id] and F.elwynn[card.id][3]) or F.skills[card.role]
    end
    local notes={}
    if d.power then notes[#notes+1]="Deal damage." end
    if d.guard then notes[#notes+1]=("Gain %d shield."):format(d.guard) end
    if d.guarded then notes[#notes+1]=("Gain %d extra shield if already shielded."):format(d.guarded) end
    if d.carry then notes[#notes+1]="Carry unused shield through your next action." end
    if d.mark then notes[#notes+1]="Mark the rival for the next hit." end
    if d.marked then notes[#notes+1]=("Deal +%d damage against a marked rival."):format(d.marked) end
    if d.unguarded then notes[#notes+1]=("Deal +%d damage if the rival has no shield when damage resolves."):format(d.unguarded) end
    if d.shatter then notes[#notes+1]=("Break up to %d shield before damage."):format(d.shatter) end
    if d.pierce then notes[#notes+1]="Pierce shields." end
    if d.drain then notes[#notes+1]=("Drain %d rival Focus."):format(d.drain) end
    if d.refund then notes[#notes+1]=("Refund %d Focus."):format(d.refund) end
    if d.haste then notes[#notes+1]=("Recover %d tick sooner on a non-consecutive guard."):format(d.haste) end
    if d.delay then notes[#notes+1]=("Delay the rival by %d %s."):format(d.delay,d.delay==1 and "tick" or "ticks") end
    if move=="B" then
        notes[#notes+1]="Consecutive guard moves grant less shield."
        notes[#notes+1]="After taking HP damage, a non-consecutive guard builds at least 2 Focus if your team has less than 2."
    end
    notes[#notes+1]=d.focus<0 and ("Costs %d Focus."):format(-d.focus) or ("Builds %d Focus."):format(d.focus)
    return table.concat(notes," ")
end

local function typedStats(c,move,d,ally,rival)
    local damage=d.power and math.max(1,c.power+d.power) or 0
    local shield,focus=d.guard or 0,d.focus+(d.refund or 0)
    if move=="A" then
        damage=damage+(c.tier>=1 and 1 or 0)
    elseif move=="B" then
        shield=shield+(c.tier>=2 and 1 or 0)
        if c.rank>0 then focus=focus+1 end
    elseif move=="S" and c.tier>=3 or move=="X" and damage>0 and c.tier>=4 then
        damage=damage+1
    end
    if rival.mark then damage=damage+(d.marked or 0) end
    if ally.shield>0 then shield=shield+(d.guarded or 0) end
    return damage,shield,focus
end
local function followMoves(card,rule)
    local names={}
    if F.hasType(card,rule.types[2]) then
        for _,move in ipairs(F.actions(true)) do
            local d=F.moveDefinition(card,move,true)
            if F.moveHasEffect(d,rule.follow) then names[#names+1]=d.name end
        end
    end
    return names
end

local function hasFollowUp(team,source,rule)
    for slot,card in ipairs(team.cards) do
        if card.id~=source and (not team.units or team.units[slot].hp>0) and #followMoves(card,rule)>0 then
            return true
        end
    end
    return false
end

function F.play(b,side,slot,move,tactic,target)
    if not F.legal(b,side,slot,move,tactic,target) then return false end
    local p,e=b[side],b[3-side]
    local c=p.cards[slot]
    local targetSlot=e.last or 1
    local targetKey
    if b.timeline then
        targetSlot=(b.arena and target) or F.nextRivalSlot(b,side) or targetSlot
        targetKey=actorKey(3-side,targetSlot)
    end
    local ally=b.arena and p.units[slot] or p
    local rival=b.arena and e.units[targetSlot] or e
    local oldShield,oldFocus,enemyShield=ally.shield,p.focus,rival.shield
    local pile=tactic and tacticPile(b,side)
    local aid=pile and table.remove(pile.hand,tactic)
    if aid then pile.discard[#pile.discard+1]=aid end
    if aid==1 then p.focus=math.min(3,p.focus+1)
    elseif aid==2 then rival.mark=true rival.markWolf=nil
    elseif aid==3 then rival.shield=math.max(0,rival.shield-3) end
    local damage,shield,focus,edge,pierce,mark
    local definition=F.moveDefinition(c,move,b.movesets)
    local entry=not definition and b.expansion and move=="S" and F.elwynn[c.id]
    local special=entry and entry[4]
    local shieldAfterTactic,focusAfterTactic=rival.shield,e.focus
    if not definition then
        damage,shield,focus,edge,pierce,mark=F.moveStats(c,move,e.cards[targetSlot].role,b.solo)
    end
    local technique=definition and move=="X" and c.tier>=4 and F.techniqueMastery(definition)
    if definition then
        damage,shield,focus=typedStats(c,move,definition,ally,rival)
        edge,pierce,mark=0,definition.pierce,definition.mark
        if technique=="shield" then shield=shield+1 end
        if technique=="focus" then focus=focus+1 end
        if definition.shatter then
            rival.shield=math.max(0,rival.shield-definition.shatter-(technique=="shatter" and 1 or 0))
        end
        if definition.drain then e.focus=math.max(0,e.focus-definition.drain-(technique=="drain" and 1 or 0)) end
    elseif special then
        damage=c.power+(c.tier>=3 and 1 or 0)+edge
        shield,pierce,mark=0,false,false
        if special=="wolf" and rival.mark then damage=damage+2
        elseif special=="bear" then shield=3
        elseif special=="miner" then rival.shield=math.max(0,rival.shield-4)
        elseif special=="boar" and rival.shield==0 then damage=damage+2
        elseif special=="prowler" then mark=true
        elseif special=="murloc" then focus=-1
        elseif special=="defias" then e.focus=math.max(0,e.focus-1)
        elseif special=="laborer" then shield=ally.shield>0 and 4 or 2 end
    end
    local setups,payoffs={},{}
    local moveBrokeShield=rival.shield<shieldAfterTactic
    local moveDrainedFocus=e.focus<focusAfterTactic
    local previous=p.last and p.cards[p.last]
    local previousSetup=p.synergySetup
    local active=b.solo and p.synergies or {}
    local packActive=false
    local synergyHaste,synergyDelay,synergyShieldBreak=0,0,0
    local tunnel,whiteout=p.tunnelPrimer,p.whiteoutPrimer
    for _,key in ipairs(active) do
        local rule=F.synergies[key]
        local prime,fire
        if key=="pack" then
            packActive=F.hasType(c,"Pack")
            prime=mark and packActive and hasFollowUp(p,c.id,rule)
            fire=damage>0 and rival.mark and rival.markWolf and rival.markWolf~=c.id and packActive
            if fire then damage=damage+rule.amount end
        elseif key=="tunnel" and F.hasType(c,"Burrow") then
            prime=moveBrokeShield and hasFollowUp(p,c.id,rule)
            fire=tunnel and tunnel~=c.id and shield>0
            if fire then shield=shield+rule.amount tunnel=nil end
            if prime then tunnel=c.id end
        elseif key=="whiteout" and F.hasType(c,"Frost") then
            prime=shield>0 and hasFollowUp(p,c.id,rule)
            fire=damage>0 and whiteout and whiteout~=c.id and rival.shield>0
            if fire then rival.shield=math.max(0,rival.shield-rule.amount) whiteout=nil end
            if prime then whiteout=c.id end
        elseif rule.bonus and previousSetup and previous and previous.id~=c.id then
            fire=previousSetup[rule.setup] and F.hasType(previous,rule.types[1])
                and F.hasType(c,rule.types[2]) and F.moveHasEffect(definition,rule.follow)
                and (not rule.sameTarget or targetSlot==previousSetup.target)
                and (rule.setup~="mark" or rival.mark and aid~=2)
                and (rule.bonus~="breakShield" or rival.shield>0)
            if fire then
                if rule.bonus=="damage" then damage=damage+rule.amount
                elseif rule.bonus=="shield" then shield=shield+rule.amount
                elseif rule.bonus=="haste" then synergyHaste=math.max(synergyHaste,rule.amount)
                elseif rule.bonus=="delay" then synergyDelay=math.max(synergyDelay,rule.amount)
                elseif rule.bonus=="breakShield" then synergyShieldBreak=math.max(synergyShieldBreak,rule.amount) end
            end
        end
        if prime then setups[#setups+1]=key end
        if fire then payoffs[#payoffs+1]=key end
    end
    p.tunnelPrimer,p.whiteoutPrimer=tunnel,whiteout
    rival.shield=math.max(0,rival.shield-synergyShieldBreak)
    if aid==4 then shield=shield+2 end
    if aid==5 and move=="A" then damage=damage+2 end
    if aid==6 and move=="S" then focus=focus+1 end
    local masteryHaste,masteryDelay=0,0
    if b.solo and b.arena and c.tier>4 then
        local perks=F.masteryEffects(c.tier)
        if move=="A" then
            if rival.hp<=(perks.finish or 0) then damage=damage+1 end
        elseif move=="X" and definition and F.moveTargetsRival(definition) then
            local stripped=math.max(0,(perks.breakShield or 0)-(shieldAfterTactic-rival.shield))
            rival.shield=math.max(0,rival.shield-stripped)
        elseif move=="B" then
            if ally.hp<=(perks.guard or 0) then shield=shield+1 end
            if not p.braced and ally.hp<=(perks.haste or 0) then masteryHaste=1 end
        elseif move=="S" then
            if ally.hp<=(perks.recover or 0) then shield=shield+1 end
            if rival.hp<=(perks.focus or 0) then focus=focus+1 end
            if rival.hp<=(perks.delay or 0) then masteryDelay=1 end
        end
    end
    if definition and rival.shield==0 then damage=damage+(definition.unguarded or 0) end
    local repeatedBrace=p.braced
    if b.arena and definition and move=="B" and not repeatedBrace and p.focus<2
        and (ally.lastHit or 0)>(ally.lastAction or 0) then
        focus=math.max(focus,2)
    end
    if b.expansion then
        local rivalActed=(e.lastAction or 0)>(ally.lastAction or 0)
        if not ally.carry and (not b.timeline or rivalActed) then ally.shield=math.max(0,ally.shield-2) end
        ally.carry=(definition and definition.carry) or special=="bear"
        if move=="B" and p.braced then shield=math.max(0,shield-2) end
        p.braced=move=="B"
    end
    local beforeHit=rival.shield
    local focusBeforeMove=p.focus
    p.focus=math.min(3,p.focus+focus)
    local old=rival.hp
    local combo=damage>0 and rival.mark or false
    if damage>0 then
        damage=damage+(rival.mark and 3 or 0)
        rival.mark=nil
        rival.markWolf=nil
        if not pierce then
            local absorbed=math.min(rival.shield,damage)
            rival.shield=rival.shield-absorbed
            damage=damage-absorbed
        end
        rival.hp=math.max(0,rival.hp-damage)
    end
    mark=mark and rival.hp>0
    if mark then rival.mark=true rival.markWolf=packActive and c.id or nil end
    if rival.hp==0 then rival.mark,rival.markWolf=nil,nil end
    if not mark then
        for i=#setups,1,-1 do
            if setups[i]=="pack" then table.remove(setups,i) end
        end
    end
    ally.shield=math.min(6,ally.shield+shield)
    if b.solo and definition then
        local setup={
            target=targetSlot,
            shatter=moveBrokeShield,
            drain=moveDrainedFocus,
            mark=definition.mark and rival.hp>0,
            delay=definition.delay and rival.hp>0,
            guard=definition.guard and shield>0,
            channel=definition.focus>=2 and p.focus-focusBeforeMove>=2,
        }
        for _,key in ipairs(active) do
            local rule=F.synergies[key]
            if rule.bonus and setup[rule.setup] and F.hasType(c,rule.types[1]) and hasFollowUp(p,c.id,rule) then
                setups[#setups+1]=key
            end
        end
        p.synergySetup=setup
    else
        p.synergySetup=nil
    end
    p.last,p.lastMove=slot,move
    b.seq=b.seq+1
    p.lastAction=b.seq
    ally.lastAction=b.seq
    if b.arena then
        e.hp=e.hp-(old-rival.hp)
        if old>rival.hp then rival.lastHit=b.seq end
    end
    local bonus=b.solo and (technique or (move=="A" and c.tier>=1) or (move=="S" and c.tier>=3) or (move=="B" and (c.tier>=2 or c.rank>0)))
    b.log[#b.log+1]=("%d. %s %s / %d hit%s%s%s"):format(b.seq,c.name,F.moveName(c,move,b.expansion,b.movesets),old-rival.hp,
        ally.shield>oldShield and (" / "..(ally.shield-oldShield).." guard") or "",mark and " / marked" or "",bonus and " / upgraded" or "")
    for _,key in ipairs(setups) do b.log[#b.log]=b.log[#b.log].." / "..F.synergies[key].name.." primed" end
    for _,key in ipairs(payoffs) do b.log[#b.log]=b.log[#b.log].." / "..F.synergies[key].name.." triggered" end
    local haste,delay=0,0
    if b.solo and b.timeline then
        if definition then
            haste,delay=not repeatedBrace and (definition.haste or 0) or 0,definition.delay or 0
        else
            haste,delay=F.speedEffect(c,move,repeatedBrace)
        end
        haste,delay=haste+masteryHaste+synergyHaste,rival.hp>0 and (delay+masteryDelay+synergyDelay+(technique=="delay" and 1 or 0)) or 0
        local key=actorKey(side,slot)
        b.queue[key]=b.queue[key]+16-F.cardSpeed(c)-haste
        b.queue[targetKey]=rival.hp==0 and math.huge or (b.queue[targetKey]+delay)
        b.lastActor=key
        b.turn,b.actor=actorPosition(nextActor(b.queue,key))
    else
        b.turn=3-side
    end
    if b.events then
        local event={side=side,slot=slot,targetSlot=targetSlot,move=move,hit=old-rival.hp,absorbed=beforeHit-rival.shield,broken=enemyShield-beforeHit,tactic=aid,
            haste=haste,delay=delay,knockout=b.arena and rival.hp==0,setup=setups[1],payoff=payoffs[1],setups=setups,payoffs=payoffs,combo=combo,edge=edge,guard=ally.shield-oldShield,focus=p.focus-oldFocus,mark=mark,drained=focusAfterTactic-e.focus}
        for i=1,2 do
            local t=b[i]
            event[i]={hp=t.hp,shield=t.shield,focus=t.focus,mark=t.mark,markWolf=t.markWolf,last=t.last,whiteoutPrimer=t.whiteoutPrimer,tunnelPrimer=t.tunnelPrimer,synergySetup=t.synergySetup}
            if b.arena then
                event[i].units={}
                for j,unit in ipairs(t.units) do
                    event[i].units[j]={hp=unit.hp,maxHP=unit.maxHP,shield=unit.shield,mark=unit.mark,markWolf=unit.markWolf}
                end
            end
        end
        if b.solo and b.timeline then event.timeline=F.turnTimeline(b) end
        b.events[b.seq]=event
    end
    if e.hp==0 then b.winner=side
    elseif b.seq>=(b.arena and 60 or 48) then b.winner=p.hp==e.hp and 0 or (p.hp>e.hp and side or 3-side) end
    if b.winner==nil then refillTactics(tacticPile(b,3-side)) end
    return true
end
-- Use the same move eligibility as resolution, including either live
-- state or the after-action snapshot being shown during playback.
function F.comboWindows(b,side,state)
    local own,rival=state[side],state[3-side]
    local windows={}
    if not (b.solo and own.units and rival.units) then return windows end
    local function add(key,source,target,expires,shielded)
        local rule=F.synergies[key]
        local counter=target and rival.units[target]
        if counter and counter.hp<=0 then return end
        if rule.setup=="mark" and target and not counter.mark then return end
        local targetName=target and b[3-side].cards[target].name or shielded and "a shielded rival" or nil
        for slot,card in ipairs(b[side].cards) do
            if card.id~=source and own.units[slot].hp>0 then
                local moves=followMoves(card,rule)
                if #moves>0 then
                    windows[#windows+1]={key=key,card=card.name,moves=moves,target=targetName,expires=expires}
                end
            end
        end
    end
    for _,key in ipairs(b[side].synergies or {}) do
        local rule=F.synergies[key]
        if key=="pack" then
            for target,unit in ipairs(rival.units) do
                if unit.markWolf then add(key,unit.markWolf,target,"Until that mark is consumed.") end
            end
        elseif key=="tunnel" and own.tunnelPrimer then
            add(key,own.tunnelPrimer,nil,"Until a partner uses a shield move or a new setup replaces it.")
        elseif key=="whiteout" and own.whiteoutPrimer then
            add(key,own.whiteoutPrimer,nil,"Until a partner hits a shielded rival or a new setup replaces it.",true)
        elseif rule.bonus and own.synergySetup and own.last and own.synergySetup[rule.setup] then
            local source=b[side].cards[own.last]
            if F.hasType(source,rule.types[1]) then
                add(key,source.id,rule.sameTarget and own.synergySetup.target or nil,"Expires after this team's next action.")
            end
        end
    end
    return windows
end

function F.preview(b,side,slot,move,tactic,target)
    if b.winner~=nil or b.aborted then return end
    local trial=F.board(b[1].cards,b[2].cards)
    for i=1,2 do for k,v in pairs(b[i]) do trial[i][k]=v end end
    trial.turn,trial.seq,trial.solo,trial.expansion,trial.me=b.turn,b.seq,b.solo,b.expansion,b.me
    trial.arena,trial.movesets=b.arena,b.movesets
    if b.arena then
        for i=1,2 do
            trial[i].units={}
            for j,unit in ipairs(b[i].units) do
                local copy={}
                for key,value in pairs(unit) do copy[key]=value end
                trial[i].units[j]=copy
            end
        end
    end
    trial.timeline,trial.actor,trial.lastActor=b.timeline,b.actor,b.lastActor
    if b.queue then trial.queue={unpack(b.queue)} end
    if b.hand then
        trial.hand,trial.draw,trial.discard={unpack(b.hand)},{unpack(b.draw)},{unpack(b.discard)}
    end
    if b.rivalTactics then
        local rival=b.rivalTactics
        trial.rivalTactics={hand={unpack(rival.hand)},draw={unpack(rival.draw)},discard={unpack(rival.discard)}}
    end
    if F.play(trial,side,slot,move,tactic,target) then return trial.events[trial.seq],trial end
end
-- Neutral solo readings use the same resolver as an actual turn.
function F.cardMovePreview(id,move,withoutMastery)
    local cards=F.snapshot({id},true)
    if withoutMastery then cards[1].tier=0 end
    local board=F.board(cards,cards)
    board.solo,board.expansion,board.movesets,board.me=true,true,true,1
    local definition=F.moveDefinition(cards[1],move,true)
    board[1].focus=definition and math.max(0,-definition.focus) or 0
    return F.preview(board,1,1,move)
end
local soloBoard,chooseAction
-- Rank solo rosters by move value and usable two-card synergies.
local function synergyWeight(key)
    return key=="pack" and 3 or 2
end
local function openingValue(deck,strategy,hand,focus,guard)
    local board=soloBoard(deck,strategy,hand)
    board[1].focus=focus
    for _,unit in ipairs(board[2].units) do unit.shield=guard end
    F.advanceSoloRival(board)
    local choice=chooseAction(board,"Balanced",#hand>0)
    return choice and choice.score or 0
end

local function optimizeTactics(deck)
    local scores={}
    for id in ipairs(F.tactics) do scores[id]={id=id,value=0} end
    for _,scenario in ipairs({{"Prowler",1,0},{"Sentinel",2,3}}) do
        local strategy,focus,guard=unpack(scenario)
        local baseline=openingValue(deck,strategy,{},focus,guard)
        for _,score in ipairs(scores) do
            score.value=score.value+openingValue(deck,strategy,{score.id},focus,guard)-baseline
        end
    end
    table.sort(scores,function(a,b)
        return a.value>b.value or (a.value==b.value and a.id<b.id)
    end)
    local tactics={}
    for i=1,F.maxTactics do tactics[i]=scores[i].id end
    return tactics
end
function F.optimizeDeck()
    local owned=F.owned()
    if #owned<3 then return nil end
    local groups={}
    for _,id in ipairs(owned) do
        local c=F.db.cards[id]
        local types=F.typesOf(id,c)
        local kit=F.loadout({id=id,types=types})
        local technique=F.cardMovePreview(id,"X")
        local strike=F.cardMovePreview(id,"A")
        local brace=F.cardMovePreview(id,"B")
        local signature=F.cardMovePreview(id,"S")
        local score=strike.hit*4+brace.guard*2+brace.focus+signature.hit*2
            +signature.guard+signature.focus+(signature.mark and 3 or 0)+(F.cardSpeed(c)-8)*2+math.max(0,F.tier(c)-4)*.35
        score=score+technique.hit+technique.broken+(technique.mark and 1 or 0)
        local key=F.synergyProfileKey({id=id,types=types,moveset=kit})
        local group=groups[key] or {}
        groups[key]=group
        group[#group+1]={id=id,score=score}
    end
    -- Three cards from a profile are enough for any roster of size three.
    local candidates={}
    for _,group in pairs(groups) do
        table.sort(group,function(a,b)
            return a.score>b.score or (a.score==b.score and a.id<b.id)
        end)
        for i=1,math.min(3,#group) do candidates[#candidates+1]=group[i] end
    end
    table.sort(candidates,function(a,b) return a.id<b.id end)

    local pairBonuses={}
    for i,a in ipairs(candidates) do
        pairBonuses[i]={}
        for j=i+1,#candidates do
            local b=candidates[j]
            local bonuses={}
            for _,key in ipairs(F.activeSynergies({a.id,b.id})) do
                bonuses[key]=synergyWeight(key)
            end
            pairBonuses[i][j]=bonuses
        end
    end
    local finalists={}
    for i=1,#candidates-2 do
        for j=i+1,#candidates-1 do
            local first,second=candidates[i],candidates[j]
            local firstPair=pairBonuses[i][j]
            for k=j+1,#candidates do
                local third=candidates[k]
                local secondPair,thirdPair=pairBonuses[i][k],pairBonuses[j][k]
                local score=first.score+second.score+third.score
                for _,key in ipairs(F.synergyOrder) do
                    score=score+(firstPair[key] or secondPair[key] or thirdPair[key] or 0)
                end
                local index=#finalists+1
                while index>1 and score>finalists[index-1].score do index=index-1 end
                if index<=5 then
                    table.insert(finalists,index,{deck={first.id,second.id,third.id},score=score})
                    finalists[6]=nil
                end
            end
        end
    end
    local best,bestScore
    for _,entry in ipairs(finalists) do
        local score=entry.score+openingValue(entry.deck,"Prowler",{},1,0)
            +openingValue(entry.deck,"Sentinel",{},2,3)
        if not bestScore or score>bestScore then best,bestScore=entry.deck,score end
    end
    return best,optimizeTactics(best)
end
local function eachAction(b,useTactics,visit)
    if b.winner~=nil then return end
    local side=b.turn
    local hand=tacticsFor(b,side)
    local tacticCount=useTactics and b.solo and hand and #hand or 0
    local first,last=1,#b[side].cards
    if b.timeline then first,last=b.actor,b.actor end
    for slot=first,last do
        for _,move in ipairs(F.actions(b.movesets)) do
            for pick=0,tacticCount do
                local tactic=pick>0 and pick or nil
                local targeted=F.requiresTarget(b,move,tactic,side,slot)
                for index=1,targeted and #b[3-side].cards or 1 do
                    local target=targeted and index or nil
                    local event,trial=F.preview(b,side,slot,move,tactic,target)
                    if event then visit(event,trial,tactic,target) end
                end
            end
        end
    end
end

local function actionValue(b,side,strategy,event,trial,tactic)
    -- Preserve terminal ordering even when a move would otherwise score highly.
    local rank=trial.winner==side and 3 or trial.winner==0 and 2 or trial.winner==nil and 1 or 0
    local guardWeight=strategy=="Sentinel" and 1.35 or .9
    local score=event.hit*2+math.max(0,event.guard)*guardWeight+event.focus*.65
        +(event.mark and 2.8 or 0)+(event.drained or 0)*1.45+(event.knockout and 6 or 0)
    if b.arena and event.focus>0 and b[side].focus<2 and trial[side].focus>=2 then
        score=score+.8
    end
    if b.arena and trial.turn~=side and event.guard>0 then
        local unit=b[side].units[event.slot]
        if unit.hp<=4 then score=score+math.min(event.guard,4)*.55 end
    end
    if b.timeline then
        score=score+(event.haste+event.delay)*.9+event.broken*.8
            +(trial.turn==side and .6 or 0)+#event.payoffs*.6
    end
    return rank,score-(tactic and .9 or 0)
end

local function better(a,b)
    return not b or a.rank>b.rank or (a.rank==b.rank and a.score>b.score)
end

local function greedyChoice(b,strategy,useTactics)
    local best
    eachAction(b,useTactics,function(event,trial,tactic,target)
        local rank,score=actionValue(b,b.turn,strategy,event,trial,tactic)
        local choice={rank=rank,score=score,event=event,trial=trial,tactic=tactic,target=target}
        if better(choice,best) then best=choice end
    end)
    return best
end

local function followUpValue(trial,side,strategy,useTactics,setups)
    -- Follow the actual timeline, allowing up to two rival replies before
    -- the next ally. This bounds the work done by each AI decision.
    for _=1,2 do
        if trial.winner~=nil or trial.turn==side then break end
        local reply=greedyChoice(trial,trial.turn==trial.me and "Balanced" or trial.strategy,
            tacticsFor(trial,trial.turn)~=nil)
        if not reply then return 0 end
        trial=reply.trial
    end
    if trial.winner~=nil or trial.turn~=side then return 0 end
    local wanted={}
    for _,key in ipairs(setups) do wanted[key]=true end
    local best,bestFollow
    eachAction(trial,useTactics,function(event,after,tactic)
        local rank,score=actionValue(trial,side,strategy,event,after,tactic)
        local choice={rank=rank,score=score}
        if better(choice,best) then best=choice end
        for _,key in ipairs(event.payoffs) do
            if wanted[key] and better(choice,bestFollow) then bestFollow=choice end
        end
    end)
    if not bestFollow or bestFollow.rank<best.rank then return 0 end
    return math.max(0,math.min(4,3+(bestFollow.score-best.score)*.6+(bestFollow.rank==3 and 1 or 0)))
end

chooseAction=function(b,strategy,useTactics)
    local best,shortlist=nil,{}
    eachAction(b,useTactics,function(event,trial,tactic,target)
        local rank,score=actionValue(b,b.turn,strategy,event,trial,tactic)
        local choice={rank=rank,score=score,event=event,trial=trial,tactic=tactic,target=target}
        if better(choice,best) then best=choice end
        if rank==1 and b.timeline and #event.setups>0 then
            local i=1
            while shortlist[i] and not better(choice,shortlist[i]) do i=i+1 end
            if i<=3 then table.insert(shortlist,i,choice) shortlist[4]=nil end
        end
    end)
    if best and best.rank==1 then
        -- Compute all bonuses against a stable unadjusted choice.
        local baseline=best.score
        for _,choice in ipairs(shortlist) do
            if choice.score+4>=baseline then
                local bonus=followUpValue(choice.trial,b.turn,strategy,useTactics,choice.event.setups)
                local planned={rank=choice.rank,score=choice.score+bonus,event=choice.event,trial=choice.trial,
                    tactic=choice.tactic,target=choice.target}
                if better(planned,best) then best=planned end
            end
        end
    end
    return best
end

function F.ai(b,strategy,useTactics)
    local choice=chooseAction(b,strategy,useTactics)
    if choice then return choice.event.slot,choice.event.move,choice.tactic,choice.target end
end

function F.advanceSoloRival(b)
    while not b.winner and b.turn~=b.me do
        local slot,move,tactic,target=F.ai(b,b.strategy,b.rivalTactics~=nil)
        if not slot or not F.play(b,b.turn,slot,move,tactic,target) then break end
    end
end
local function recordCardBattle(b,result)
    local mode=b.solo and "solo" or "duel"
    local records,matchDamage,acted={},{},{}
    for slot,card in ipairs(b[b.me].cards) do
        local c=F.db.cards[card.id]
        if c and c.lifetime>0 then
            c.fieldStats=c.fieldStats or {}
            local stats=c.fieldStats[mode] or {}
            c.fieldStats[mode]=stats
            records[slot]=stats
            stats.matches=(stats.matches or 0)+1
            stats[result]=(stats[result] or 0)+1
            stats.streak=result=="wins" and (stats.streak or 0)+1 or 0
            stats.bestStreak=math.max(stats.bestStreak or 0,stats.streak)
            stats.lastBattle=GetServerTime and GetServerTime() or stats.lastBattle
        end
    end
    for _,event in ipairs(b.events or {}) do
        if event.side==b.me then
            local slot=event.slot
            local stats=records[slot]
            if stats then
                stats.actions=(stats.actions or 0)+1
                if not acted[slot] then
                    acted[slot]=true
                    stats.activeMatches=(stats.activeMatches or 0)+1
                end
                local hit=event.hit or 0
                stats.damage=(stats.damage or 0)+hit
                matchDamage[slot]=(matchDamage[slot] or 0)+hit
                stats.biggestHit=math.max(stats.biggestHit or 0,hit)
                stats.biggestBattle=math.max(stats.biggestBattle or 0,matchDamage[slot])
                stats.shieldBroken=(stats.shieldBroken or 0)+(event.broken or 0)
                stats.shieldGained=(stats.shieldGained or 0)+math.max(0,event.guard or 0)
                stats.marks=(stats.marks or 0)+(event.mark and 1 or 0)
                stats.combos=(stats.combos or 0)+(event.combo and 1 or 0)
                stats.knockouts=(stats.knockouts or 0)+(event.knockout and 1 or 0)
                stats.tactics=(stats.tactics or 0)+(event.tactic and 1 or 0)
                stats.haste=(stats.haste or 0)+(event.haste or 0)
                stats.delay=(stats.delay or 0)+(event.delay or 0)
                stats.setups=(stats.setups or 0)+#(event.setups or {})
                stats.payoffs=(stats.payoffs or 0)+#(event.payoffs or {})
                stats[event.move]=(stats[event.move] or 0)+1
            end
        elseif b.arena and records[event.targetSlot] then
            local stats=records[event.targetSlot]
            stats.damageTaken=(stats.damageTaken or 0)+(event.hit or 0)
            stats.damageBlocked=(stats.damageBlocked or 0)+(event.absorbed or 0)
            stats.knockedOut=(stats.knockedOut or 0)+(event.knockout and 1 or 0)
        end
    end
end
function F.finish(b)
    if b.winner==nil or b.recorded then return end
    b.recorded=true
    local key=b.winner==0 and "draws" or (b.winner==b.me and "wins" or "losses")
    F.db.stats[key]=(F.db.stats[key] or 0)+1
    if not b.aborted then recordCardBattle(b,key) end
    if b.solo and b.winner==b.me and not b.aborted then
        local credited={}
        b.awards={}
        for _,event in ipairs(b.events or {}) do
            if event.side==b.me then
                local id=b[b.me].cards[event.slot].id
                local c=F.db.cards[id]
                if c and c.lifetime>0 and not credited[id] then
                    local before,tier=c.mastery or 0,F.tier(c)
                    c.mastery=before+F.balance.victoryMastery
                    b.awards[#b.awards+1]={id=id,before=before,after=c.mastery,
                        perk=F.tier(c)>tier and F.perks[F.tier(c)] or nil}
                    local stats=c.fieldStats and c.fieldStats.solo
                    if stats then stats.masteryEarned=(stats.masteryEarned or 0)+F.balance.victoryMastery end
                    credited[id]=true
                end
            end
        end
    end
end
F.soloOpponents={
    Prowler={roster={118,299,113},detail="Pack Hunt and Cornered Prey",art="Woodland"},
    Sentinel={roster={724,704,1553},detail="Whiteout and Rime Shot",art="Snow"},
    Veteran={roster={724,1512,3124},detail="Rime Shot and Corrosive Dive with tactics",art="Highlands",tactics={1,2,4}},
}

soloBoard=function(deck,strategy,tactics)
    local opponent=F.soloOpponents[strategy]
    local b=F.board(F.snapshot(deck,true),F.snapshot(opponent.roster,false,true))
    b.me,b.solo,b.strategy,b.expansion,b.movesets=1,true,strategy,true,true
    b[1].synergies=F.activeSynergies(deck)
    b[2].synergies=F.activeSynergies(opponent.roster)
    b.hand,b.draw,b.discard={unpack(tactics)},{},{}
    if opponent.tactics then
        b.rivalTactics={hand={unpack(opponent.tactics)},draw={},discard={}}
        local total=0
        for _,card in ipairs(b[1].cards) do total=total+card.tier end
        local tier=math.max(4,math.floor(total/#b[1].cards))
        for _,card in ipairs(b[2].cards) do card.tier=tier end
    end
    b.timeline,b.arena=true,true
    for side=1,2 do
        local team=b[side]
        team.hp=0
        team.units={}
        for slot,card in ipairs(team.cards) do
            local hp=({Hunter=11,Hexer=11,Keeper=12})[card.role]
            team.units[slot]={hp=hp,maxHP=hp,shield=0}
            team.hp=team.hp+hp
        end
    end
    b.queue={}
    for slot=1,3 do
        for side=1,2 do
            b.queue[actorKey(side,slot)]=16-F.cardSpeed(b[side].cards[slot])
        end
    end
    b.turn,b.actor=actorPosition(nextActor(b.queue,0))
    b.initialTimeline=F.turnTimeline(b)
    return b
end

function F.solo(strategy)
    local deck=F.db.decks[F.db.active]
    local ok,msg=F.validate(deck,true)
    if not ok then return false,msg end
    local b=soloBoard(deck,F.soloOpponents[strategy] and strategy or "Prowler",F.tacticDeck(F.db.active))
    F.advanceSoloRival(b)
    F.finish(b)
    F.match=b
    return true
end
