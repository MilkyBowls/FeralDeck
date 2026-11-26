local _, F = ...

-- Choices are ordered from the default. Existing saved keys retain their values.
F.settingGroups={
    {title="Display", rows={
        {"uiTheme","Theme","Change the panel, controls, and highlight palette.",{{"Azure Glass"},{"Dark Mode"},{"Forest Green"},{"Amber Forge"}}},
        {"largeUI","Size","Scale the addon window to your display.",{{false,"fit"},{true,"large"},{"compact","compact"}}},
        {"opaqueUI","Background","Choose the window surface.",{{false,"glass"},{true,"opaque"}}},
        {"cardScenery","Card scenery","Dim or hide the scenery behind creature models.",{{"Full"},{"Dim"},{"Off"}}},
        {"cardOrnaments","Engravings","Show the type-specific corners on card frames."},
        {"cardFoil","Foil effects","Show the foil sheen on prestiged cards."},
        {"pauseModels","Idle models","Keep creature models still while browsing cards.",{{false,"animated"},{true,"still"}}},
    }},
    {title="Collection", rows={
        {"discoveryToasts","Discovery popups","Show an on-screen card when a creature is first collected."},
        {"perkToasts","Perk popups","Show an on-screen card when a Mastery perk unlocks."},
        {"revealCards","Card reveals","Flip newly opened cards before showing the creature."},
        {"journalOrder","Journal sort","Choose the initial sort order for the Field Journal.",{{1,"New first"},{2,"Name A-Z"},{3,"Most mastery"},{4,"Most copies"}}},
        {"startTab","Opening tab","Choose which screen opens when you type /fd.",{{"Remember","Last used"},{"Collection","Field Journal"},{"Decks","Deck Builder"},{"Battle"}}},
        {"collectionChat","Collection messages","Show discovery and extra-copy messages in chat."},
    }},
    {title="Battle options", rows={
        {"fastBattle","Playback","Set the battle playback pace.",{{false,"normal"},{true,"fast"}}},
        {"battleMotion","Battle animation","Animate combat actions, the timeline, and results."},
        {"arenaScenery","Arena scenery","Show the habitat artwork behind the battlefield."},
        {"timelineModels","Initiative portraits","Use creature portraits or text names in the turn order.",{{true,"portraits"},{false,"names"}}},
        {"healthPreview","Damage preview","Overlay projected damage on the rival's health bar."},
        {"battleLogDefault","Open with combat log","Show the combat log when entering a new battle.",{{false,"off"},{true,"on"}}},
    }},
    {title="Nameplates", rows={
        {"ownershipBadges","Ownership icons","Show collected and uncollected badges on eligible enemies."},
        {"badgePosition","Icon placement","Choose where the icon sits on the enemy nameplate.",{{"Name right"},{"Name left"},{"Bar left"},{"Bar right"}}},
        {"badgeSize","Icon size","Set the size of the ownership icon.",{{12,"Small"},{16,"Medium"},{20,"Large"}}},
        {"badgeOpacity","Icon brightness","Set how strongly the icon stands out.",{{"Subtle"},{"Dim"},{"Bright"}}},
        {"ownershipTooltip","Ownership tooltip","Show FeralDeck details on the unit tooltip."},
        {"killTooltip","Kill progress","Show credited kills toward the first copy in the unit tooltip."},
    }},
    {title="Audio", rows={
        {"audioMode","Sound","Choose all cues, reward cues only, or silence.",{{"Full"},{"Rewards Only"},{"Off"}}},
        {"audioChannel","Sound channel","Choose which WoW volume control applies to FeralDeck.",{{"SFX"},{"Master"},{"Ambience"},{"Dialog"}}},
        {"battleCues","Combat sounds","Play hits, shields, signatures, and synergy cues."},
        {"discoveryCues","Discovery sounds","Play discovery and card reveal sounds."},
        {"rewardCues","Reward sounds","Play perk and battle result sounds."},
        {"placementCues","Placement sounds","Play sounds when placing cards or equipping a deck."},
    }},
    {title="Controls", rows={
        {"staticCards","Motion","Reduce card and battle motion throughout the addon.",{{false,"full"},{true,"reduced"}}},
        {"controllerNav","Controller","Use the D-pad and face buttons inside FeralDeck."},
        {"controllerHints","Controller hints","Show the controller shortcut legend at the bottom."},
    }},
}

local toggleChoices={{true,"on"},{false,"off"}}

function F.settingChoices(row)
    return row[4] or toggleChoices
end

function F.settingIndex(db,row)
    for i,choice in ipairs(F.settingChoices(row)) do
        if db[row[1]]==choice[1] then return i end
    end
    return 1
end

function F.setPreference(db,key,value)
    db[key]=value
    if key=="audioMode" then db.sounds=value~="Off" end
end

function F.initSettings(db)
    for _,group in ipairs(F.settingGroups) do
        for _,row in ipairs(group.rows) do
            local choice=F.settingChoices(row)[F.settingIndex(db,row)]
            F.setPreference(db,row[1],choice[1])
        end
    end
end
