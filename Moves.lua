local _, F = ...

-- Field types describe the creature. Relay roles still determine speed and HP.
local familyTypes={
    wolf="Pack", worg="Pack", hyena="Pack",
    cat="Feral", raptor="Feral", beast="Feral", crocolisk="Feral", devilsaur="Feral",
    bear="Brute", boar="Brute", trogg="Brute", quilboar="Brute", giant="Brute", ogre="Brute", gorilla="Brute",
    kobold="Burrow", worm="Burrow", burrower="Burrow", mole="Burrow",
    humanoid="Martial", human="Martial", orc="Martial", gnoll="Martial", troll="Martial",
    satyr="Fel", imp="Fel", demon="Fel", felguard="Fel", felhunter="Fel", infernal="Fel",
    murloc="Tide", naga="Tide", fish="Tide", shark="Tide", hydra="Tide",
    crab="Shell", turtle="Shell", beetle="Shell", crustacean="Shell", mechanical="Shell",
    spider="Venom", scorpid="Venom", scorpion="Venom", serpent="Venom", snake="Venom", wasp="Venom",
    bird="Winged", bat="Winged", owl="Winged", carrionbird="Winged", harpy="Winged", gryphon="Winged", hippogryph="Winged",
    elemental="Arcane", dragonkin="Arcane", dragon="Arcane", wyrm="Arcane",
    undead="Undead", skeleton="Undead", ghost="Undead", ghoul="Undead", zombie="Undead", wraith="Undead", banshee="Undead",
    plant="Verdant", treant="Verdant", bogbeast="Verdant", lasher="Verdant",
    golem="Stone", construct="Stone", rock="Stone",
}
local namedTypes={
    {"Frost","frost elemental|ice elemental|ice revenant|ice shard|frost revenant"},
    {"Ember","fire elemental|lava elemental|flame elemental|fire revenant|flamewalker|core hound|fireguard|flamewaker"},
    {"Storm","storm elemental|air elemental|wind elemental|dust devil|thunder lizard|lightning elemental"},
    {"Stone","earth elemental|rock elemental|stone elemental|earth revenant|rock golem"},
    {"Tide","water elemental|water revenant|sea elemental"},
    {"Trickster","cutpurse|pickpocket|nightblade|assassin|defias rogue|brigand|ambusher"},
    {"Undead","skeleton|skeletal|ghoul|zombie|banshee|revenant|wraith"},
    {"Verdant","treant|timberling|bog beast|lasher|fungal|moss elemental"},
    {"Arcane","mage|sorcerer|spellbinder|arcanist|mana wyrm"},
    {"Pack","wolf|worg|hyena|coyote"},
    {"Brute","bear|boar|trogg|ogre|skullthumper"},
    {"Burrow","kobold"},
    {"Tide","murloc|naga|hydra"},
    {"Shell","crawler|crab|turtle"},
    {"Venom","scorpid|scorpion|spider|venom|viper"},
    {"Winged","bat|duskbat|owl|vulture|buzzard|harpy"},
    {"Feral","raptor|crocolisk|tiger|panther"},
}
local typedCreatures={
    [94]={"Trickster"}, [724]={"Brute","Frost"}, [707]={"Brute","Frost"},
    [1115]={"Brute","Frost"}, [1117]={"Brute","Frost"}, [1125]={"Brute","Frost"},
    [704]={"Pack","Frost"}, [705]={"Pack","Frost"},
    [3106]={"Shell","Tide"}, [3107]={"Shell","Tide"}, [3108]={"Shell","Tide"},
    [3124]={"Venom","Shell"}, [275662]={"Tide","Martial"}, [275663]={"Tide","Martial"},
}
function F.typesOf(id,card)
    local known=typedCreatures[id]
    if known then return known end
    local species=F.speciesOf(id)
    local family=type(species[2])=="string" and species[2]:lower():gsub("[%s%-]","") or ""
    local stored=F.db and F.db.cards[id]
    local name=(species[4] or (card and card.name) or (stored and stored.name) or ""):lower()
    local kind=familyTypes[family]
    if kind and kind~="Martial" and kind~="Feral" and kind~="Arcane" then return {kind} end
    for _,rule in ipairs(namedTypes) do
        for token in rule[2]:gmatch("[^|]+") do
            if name:find("%f[%a]"..token.."%f[%A]") then return {rule[1]} end
        end
    end
    return {kind or "Martial"}
end

function F.hasType(card,kind)
    local types=card.types or F.typesOf(card.id,card)
    return types[1]==kind or types[2]==kind
end

function F.cardTypeText(id,card)
    local types=card and card.types or F.typesOf(id,card)
    return table.concat(types," / ")
end

local function attack(name,delta,effects)
    effects=effects or {}
    effects.name,effects.power,effects.focus=name,delta,1
    return effects
end
local function guard(name,shield,effects)
    effects=effects or {}
    effects.name,effects.guard,effects.focus=name,shield,effects.focus or 1
    return effects
end
local function technique(name,effects)
    effects.name,effects.focus=name,-1
    return effects
end
local function signature(name,delta,effects)
    effects=effects or {}
    effects.name,effects.power,effects.focus=name,delta,-2
    return effects
end

local kits={
    Pack={A=attack("Fang Snap",0), B=guard("Circle Back",3),
        X=technique("Hunting Cry",{mark=true}), S=signature("Pack Lunge",0,{marked=2})},
    Feral={A=attack("Raking Claw",-1,{unguarded=1}), B=guard("Coil to Spring",2,{haste=1}),
        X=technique("Hamstring",{power=-1,delay=2}), S=signature("Wild Pounce",1,{pierce=true})},
    Brute={A=attack("Heavy Swing",0), B=guard("Dig In",4),
        X=technique("Shoulder Check",{power=-1,shatter=2}), S=signature("Crushing Charge",1,{unguarded=2})},
    Burrow={A=attack("Chipping Blow",-1,{shatter=1}), B=guard("Bunker Down",3),
        X=technique("Tripwire",{power=-1,delay=2}), S=signature("Tunnel Collapse",0,{shatter=3})},
    Martial={A=attack("Measured Cut",0), B=guard("High Guard",3),
        X=technique("Feint",{power=-1,mark=true}), S=signature("Rallying Blow",0,{guard=2})},
    Trickster={A=attack("Quick Jab",0), B=guard("Fade Away",2,{haste=1}),
        X=technique("Pocket Sand",{mark=true,delay=1}), S=signature("Blindside",0,{marked=3})},
    Tide={A=attack("Water Lash",0), B=guard("Ebbguard",2,{carry=true}),
        X=technique("Undertow",{power=-1,delay=2}), S=signature("Breakwater",0,{guard=3})},
    Shell={A=attack("Pincer Crush",0), B=guard("Tuck In",4),
        X=technique("Seal Carapace",{guard=4,carry=true}), S=signature("Carapace Slam",0,{guard=3,carry=true})},
    Venom={A=attack("Needle Bite",-1,{shatter=1}), B=guard("Coiled Guard",3),
        X=technique("Corrode",{power=-1,shatter=2,mark=true}), S=signature("Venom Burst",0,{marked=2})},
    Winged={A=attack("Talon Sweep",0), B=guard("Updraft",2,{haste=1}),
        X=technique("Buffeting Wings",{power=-1,delay=2}), S=signature("Sky Dive",1,{pierce=true})},
    Frost={A=attack("Ice Shard",0), B=guard("Rime Cover",3),
        X=technique("Snap Freeze",{power=-1,delay=2}), S=signature("Glacial Break",0,{shatter=3,delay=1})},
    Ember={A=attack("Cinder Lash",0), B=guard("Smoke Veil",2,{haste=1}),
        X=technique("Singe",{power=-1,mark=true}), S=signature("Flashover",1,{unguarded=2})},
    Stone={A=attack("Stone Knuckle",0), B=guard("Bedrock",4),
        X=technique("Fault Line",{power=-1,shatter=2}), S=signature("Rockfall",1,{shatter=2})},
    Storm={A=attack("Static Arc",-1,{delay=1}), B=guard("Windbreak",2,{haste=1}),
        X=technique("Crosswind",{power=-1,delay=2}), S=signature("Thunderclap",0,{delay=2,mark=true})},
    Verdant={A=attack("Thorn Whip",0), B=guard("Bark Skin",3),
        X=technique("Grasping Roots",{mark=true,delay=1}), S=signature("Briar Bloom",0,{guard=3,mark=true})},
    Arcane={A=attack("Arcane Dart",0), B=guard("Spell Ward",2,{focus=2}),
        X=technique("Null Pulse",{power=-1,drain=1}), S=signature("Aether Lance",1,{pierce=true})},
    Undead={A=attack("Grave Claw",0), B=guard("Bone Ward",3),
        X=technique("Deathly Grasp",{power=-1,drain=1}), S=signature("Grave Chill",0,{delay=2,mark=true})},
    Fel={A=attack("Scorching Claw",0), B=guard("Fel Mantle",2,{focus=2}),
        X=technique("Siphon Spark",{power=-1,drain=1}), S=signature("Ruin Brand",0,{mark=true,shatter=2})},
}
F.typeOrder={"Pack","Feral","Brute","Burrow","Martial","Trickster","Tide","Shell","Venom","Winged",
    "Frost","Ember","Stone","Storm","Verdant","Arcane","Undead","Fel"}

local custom={
    [299]={S=signature("Scent of Blood",0,{marked=2})},
    [118]={A=attack("Stalker Bite",0), X=technique("Low Growl",{power=-1,drain=1}), S=signature("Pack Signal",0,{mark=true})},
    [822]={A=attack("Paw Swipe",0), S=signature("Den Guard",0,{guard=3,carry=true})},
    [40]={A=attack("Pickaxe Tap",0), S=signature("Pickaxe Split",0,{shatter=4})},
    [80]={S=signature("Reinforce",0,{guard=2,guarded=2})},
    [113]={A=attack("Tusk Jab",0), S=signature("Headlong Rush",0,{unguarded=2})},
    [735]={S=signature("Slipstream",0,{refund=1})},
    [94]={S=signature("Cut the Purse",0,{drain=1})},
    [724]={A=attack("Rockjaw Smash",0), B=guard("Hunker Down",4), S=signature("Rimebreaker",0,{shatter=2,delay=2})},
    [704]={S=signature("Timberwolf Ambush",0,{marked=2,delay=1,mark=true})},
    [705]={S=signature("Coldridge Howl",0,{mark=true})},
    [1115]={S=signature("Skull Rattle",0,{delay=2,mark=true})},
    [1125]={S=signature("Crag Charge",0,{shatter=2,unguarded=1})},
    [1553]={S=signature("Night Screech",0,{mark=true,delay=2})},
    [3107]={S=signature("Riptide Clamp",0,{guard=2,delay=2})},
    [3124]={S=signature("Stinger Vault",0,{pierce=true,mark=true})},
    [268530]={S=signature("Matriarch's Cry",0,{marked=2,mark=true})},
}
function F.techniqueMastery(definition)
    if definition.shatter then return "shatter","Breaks 1 extra shield." end
    if definition.delay then return "delay","Delays the rival 1 extra tick." end
    if definition.drain then return "drain","Drains 1 extra rival Focus." end
    if definition.guard then return "shield","Grants 1 extra shield." end
    return "focus","Refunds the 1 Focus cost."
end

local classicMoves,soloMoves={"A","B","S"},{"A","B","X","S"}
function F.actions(typed)
    return typed and soloMoves or classicMoves
end

function F.loadout(card)
    local types=card.types or F.typesOf(card.id,card)
    local kit=kits[types[1]]
    local alt=custom[card.id] or {}
    return {
        A=alt.A or kit.A, B=alt.B or kit.B, S=alt.S or kit.S,
        X=alt.X or (types[2] and kits[types[2]].X) or kit.X,
    }
end


-- Roles and slot letters do not qualify a pairing. The two cards must carry
-- the required types and each must have a move that can do its part.
local moveEffects={
    damage=function(d) return d.power~=nil end,
    guard=function(d) return d.guard~=nil end,
    mark=function(d) return d.mark end,
    markHit=function(d) return d.mark and d.power~=nil end,
    shatter=function(d) return d.shatter~=nil end,
    delay=function(d) return d.delay~=nil end,
    drain=function(d) return d.drain~=nil end,
    carry=function(d) return d.guard and d.carry end,
    channel=function(d) return d.focus>=2 end,
    finisher=function(d) return d.power and (d.marked or d.unguarded) end,
    pierce=function(d) return d.pierce end,
}
function F.moveHasEffect(definition,effect)
    return definition and moveEffects[effect](definition)
end

F.synergies={}
F.synergyOrder={}

local function pairing(key,name,from,to,setup,follow,bonus,amount,effect,sameTarget)
    F.synergies[key]={name=name,types={from,to},setup=setup,follow=follow,bonus=bonus,amount=amount,
        effect=effect,sameTarget=sameTarget,requirement=from==to and ("Two %s creatures"):format(from) or from.." + "..to}
    F.synergyOrder[#F.synergyOrder+1]=key
end

pairing("pack","Pack Hunt","Pack","Pack","mark","damage",nil,2,
    "Mark a rival with a Pack ally. A different Pack ally consuming that mark deals +2 damage.")
pairing("tunnel","Hold the Tunnel","Burrow","Burrow","shatter","guard",nil,2,
    "Remove shield with a Burrow ally's shield-breaking move. A different Burrow ally's next shield-granting move adds +2 shield.")
pairing("whiteout","Whiteout","Frost","Frost","guard","damage",nil,2,
    "Use a shield-granting move with a Frost ally. A different Frost ally's damaging move breaks up to 2 shield on a shielded rival.")
pairing("vanguard","Vanguard","Stone","Martial","shatter","damage","damage",1,
    "After a Stone ally breaks shield, the next allied action can be a Martial hit against that rival for +1 damage.",true)
pairing("ward","Warding Circle","Arcane","Shell","channel","guard","shield",2,
    "After an Arcane ally builds 2 Focus with a move, the next allied action can be a Shell shield move for +2 shield.")
pairing("hex","Hex Ambush","Trickster","Undead","mark","damage","damage",2,
    "After a Trickster marks a rival, the next allied action can be an Undead hit that consumes the mark for +2 damage.",true)
pairing("steam","Steam Burst","Tide","Ember","delay","finisher","breakShield",2,
    "After a Tide move delays a rival, the next allied action can be an Ember finisher against that rival to break up to 2 shield.",true)
pairing("tempest","Tailwind","Storm","Winged","delay","pierce","haste",2,
    "After a Storm move delays a rival, the next allied action can be a Winged piercing move to advance that ally's next turn by 2 ticks.")
pairing("briar","Briar Trap","Verdant","Venom","mark","shatter","delay",2,
    "After a Verdant ally marks a rival, the next allied action can be a Venom shield-breaking move against that marked rival to delay it by 2 ticks.",true)
pairing("stampede","Stampede","Brute","Feral","shatter","finisher","damage",1,
    "After a Brute ally breaks shield, the next allied action can be a Feral finisher against that rival for +1 damage.",true)
pairing("sear","Searing Hex","Fel","Ember","drain","markHit","damage",2,
    "After a Fel move drains rival Focus, the next allied action can be an Ember marking hit for +2 damage.")
pairing("silt","Silt Armor","Burrow","Tide","shatter","carry","shield",2,
    "After a Burrow move breaks shield, the next allied action can be a Tide move that carries shield for +2 shield.")
pairing("rime","Rime Shot","Frost","Winged","delay","damage","breakShield",2,
    "After a Frost move delays a rival, the next allied action can be a Winged hit against that rival to break up to 2 shield.",true)
pairing("static","Static Ward","Shell","Storm","guard","delay","delay",2,
    "After a Shell ally uses a shield move, the next allied action can be a Storm delay move for 2 extra ticks of delay.")
pairing("wake","Grave Wake","Undead","Fel","drain","shatter","damage",2,
    "After an Undead move drains rival Focus, the next allied action can be a Fel shield-breaking hit for +2 damage.")
pairing("corner","Cornered Prey","Pack","Brute","mark","finisher","damage",1,
    "After a Pack ally marks a rival, the next allied action can be a Brute finisher that consumes the mark for +1 damage.",true)
pairing("dive","Corrosive Dive","Venom","Winged","shatter","pierce","damage",1,
    "After a Venom ally breaks shield, the next allied action can be a Winged piercing hit against that rival for +1 damage.",true)

local function eligibleMoves(card,kind,effect)
    if not F.hasType(card,kind) then return end
    local matches={}
    for _,slot in ipairs(soloMoves) do
        local d=card.moveset[slot]
        if F.moveHasEffect(d,effect) then matches[#matches+1]=d.name end
    end
    if #matches>0 then return matches end
end

local function buildRoster(deck)
    local roster,seen={},{}
    for slot=1,3 do
        local id=deck[slot]
        if id and not seen[id] then
            seen[id]=true
            local card={id=id,types=F.typesOf(id)}
            card.moveset=F.loadout(card)
            roster[#roster+1]=card
        end
    end
    return roster
end

local function collectPairings(roster,rule,firstOnly)
    local pairs={}
    for i,from in ipairs(roster) do
        local setup=eligibleMoves(from,rule.types[1],rule.setup)
        if setup then
            for j,to in ipairs(roster) do
                local follow=i~=j and eligibleMoves(to,rule.types[2],rule.follow)
                if follow then
                    pairs[#pairs+1]={from=from.id,to=to.id,setup=setup,follow=follow}
                    if firstOnly then return pairs end
                end
            end
        end
    end
    return pairs
end

function F.qualifies(deck,key)
    local rule=F.synergies[key]
    return rule~=nil and #collectPairings(buildRoster(deck),rule,true)>0
end

function F.activeSynergies(deck)
    local active,roster={},buildRoster(deck)
    for _,key in ipairs(F.synergyOrder) do
        if #collectPairings(roster,F.synergies[key],true)>0 then active[#active+1]=key end
    end
    return active
end

function F.synergyPairings(deck)
    local results,roster={},buildRoster(deck)
    for _,key in ipairs(F.synergyOrder) do
        local matches=collectPairings(roster,F.synergies[key])
        if #matches>0 then results[#results+1]={key=key,matches=matches} end
    end
    return results
end

function F.synergyProfileKey(card)
    local profile={table.concat(card.types,":")}
    for _,key in ipairs(F.synergyOrder) do
        local rule=F.synergies[key]
        if eligibleMoves(card,rule.types[1],rule.setup) then profile[#profile+1]=key..">" end
        if eligibleMoves(card,rule.types[2],rule.follow) then profile[#profile+1]=key.."<" end
    end
    return table.concat(profile,"/")
end

