local _, F = ...
local prefix,version="FeralDeck","3"
local recent={}
local function changed(s)
    F.notice=s
    if F.refresh then F.refresh() end
end
local function stop(s)
    if F.net and F.net.phase=="play" and F.match and not F.match.recorded then
        F.match.aborted=s
    end
    F.net=nil
    changed(s)
end
local function blocked()
    if not F.registered then return "Addon whispers unavailable. Enable Feral Deck and reload." end
    if F.read(IsInInstance) or F.read(C_ChatInfo.InChatMessagingLockdown) then
        return "Leave the instance or encounter and challenge again in the open world."
    end
    if F.read(IsTrialAccount) or F.read(IsVeteranTrialAccount) then return "Addon whispers require an unrestricted account." end
end
function F.register()
    local api=C_ChatInfo
    local result=api and api.SendAddonMessage and F.read(api.RegisterAddonMessagePrefix,prefix)
    F.registered=result==true or result==0 or result==1
end
local function emit(peer,id,kind,payload)
    local why=blocked()
    if why then return false,why end
    local packet=table.concat({version,id,kind,payload or "-"},"|")
    local ok,r=pcall(C_ChatInfo.SendAddonMessage,prefix,packet,"WHISPER",peer)
    if not ok or not F.plain(r) or r~=(Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success or 0) then
        return false,"Whisper failed. Check account access, player name and open-world location."
    end
    return true
end
local function send(kind,data)
    local n=F.net
    local ok,why=emit(n.peer,n.id,kind,data)
    if not ok then stop(why) end
    return ok
end
local roles={R="Hunter",K="Keeper",X="Hexer"}
local function wire(cards)
    local parts={}
    for i,c in ipairs(cards) do
        local token=c.role=="Hunter" and "R" or (c.role=="Keeper" and "K" or "X")
        parts[i]=c.id..":"..token..":"..math.min(c.rank,999999)
    end
    return table.concat(parts,",")
end
local function decode(s)
    local out,ids={},{}
    for part in (s..","):gmatch("(.-),") do
        local id,r,k=part:match("^(%d+):([RKX]):(%d+)$")
        id=F.id(id)
        if not id or #k>6 or #out==3 then return end
        ids[#ids+1]=id
        local c=F.db.cards[id]
        out[#out+1]={id=id,name=c and c.name or ("NPC "..id),role=roles[r],
            power=2+math.floor(id/3)%2,tier=0,rank=tonumber(k)}
    end
    if F.validate(ids,false) then return out end
end
local function localCards()
    local deck=F.db.decks[F.db.active]
    local ok,why=F.validate(deck,true)
    if not ok then return nil,why end
    return F.snapshot(deck,false)
end
local function canon(name)
    name=name:lower()
    local realm=F.read(GetNormalizedRealmName)
    if realm and realm~="" and not name:find("-",1,true) then name=name.."-"..realm:lower() end
    return name
end
function F.challenge(peer)
    if F.net or F.match and not (F.match.recorded or F.match.aborted) then return end
    if not peer or peer=="" or #peer>100 or peer:find("[%s|]") then return changed("Enter a character name, optionally with realm.") end
    local myName=F.read(UnitName,"player")
    if myName and canon(peer)==canon(myName) then return changed("Choose another player.") end
    local cards,why=localCards()
    if not cards then return changed(why) end
    local id=("%d.%06d"):format(GetServerTime(),math.random(0,999999))
    F.net={phase="offered",id=id,peer=peer,mine=cards,deadline=GetTime()+45}
    if send("I",wire(cards)) then changed("Invitation sent to "..peer..".") end
end
function F.accept()
    local n=F.net
    if not n or n.phase~="invited" then return end
    local cards,why=localCards()
    if not cards then return changed(why) end
    n.mine,n.phase,n.deadline=cards,"waiting",GetTime()+45
    if send("Y",wire(cards)) then changed("Waiting for challenger.") end
end
local function start(n,me)
    n.phase,n.deadline="play",GetTime()+120
    F.match=F.board(me==1 and n.mine or n.other, me==1 and n.other or n.mine)
    F.match.me=me
    F.match.peer=n.peer
    changed("Duel with "..n.peer)
end
function F.leave()
    local n=F.net
    if n then
        if n.phase=="play" then
            if not send("Q",tostring(F.match.seq)) then return end
        else send("N") stop("Invitation closed.") return end
    end
    local b=F.match
    if b and not b.recorded and not b.aborted then
        b.conceded=b.me
        b.winner=3-b.me
        F.finish(b)
    end
    F.net=nil
    changed("Conceded.")
end
function F.act(slot,move,tactic,target)
    local b=F.match
    if not b or b.aborted or not F.legal(b,b.me,slot,move,tactic,target) then return end
    if not b.solo and (not F.net or not send("M",(b.seq+1)..":"..slot..":"..move)) then return end
    F.play(b,b.me,slot,move,tactic,target)
    if b.solo then F.advanceSoloRival(b) end
    F.finish(b)
    if b.recorded then F.net=nil elseif F.net then F.net.deadline=GetTime()+120 end
    changed(nil)
end
function F.receive(p,msg,channel,peer)
    if not (F.plain(p) and F.plain(msg) and F.plain(channel) and F.plain(peer)) then return end
    if p~=prefix or channel~="WHISPER" or type(msg)~="string" or #msg>200 or type(peer)~="string" or #peer>100 then return end
    local v,id,kind,data=msg:match("^(%d+)|(%d+%.%d+)|([A-Z])|([^|]+)$")
    if not id or #id>20 then return end
    local n=F.net
    if kind=="I" then
        local stamp=tonumber(id:match("^%d+"))
        local key=canon(peer).."/"..id
        if math.abs(GetServerTime()-stamp)>45 or recent[key] then return end
        recent[key]=GetTime()+95
        if v~=version then emit(peer,id,"V") return changed("Incompatible Feral Deck versions. Update both addons.") end
        if n or F.match and not (F.match.recorded or F.match.aborted) then emit(peer,id,"N") return end
        local cards=decode(data)
        if not cards or blocked() then return end
        F.net={phase="invited",peer=peer,id=id,other=cards,deadline=GetTime()+45}
        F.say(peer.." challenges you. Open /fd -> Battle to accept.")
        changed("Challenge from "..peer)
        return
    end
    if not n or n.id~=id or canon(n.peer)~=canon(peer) then return end
    if kind=="V" then return stop("Version mismatch. Update both addons.") end
    if v~=version then return end
    if kind=="N" and n.phase~="play" then return stop("Invitation declined or cancelled.") end
    if kind=="Y" and n.phase=="offered" then
        local cards=decode(data)
        if cards then n.other=cards if send("G") then start(n,1) end end
    elseif kind=="G" and n.phase=="waiting" and data=="-" then start(n,2)
    elseif n.phase=="play" then
        local b=F.match
        if kind=="Q" and tonumber(data)==b.seq then b.conceded=3-b.me b.winner=b.me
        elseif kind=="M" then
            local seq,i,m=data:match("^(%d+):([123]):([ABS])$")
            if tonumber(seq)~=b.seq+1 or not F.play(b,3-b.me,tonumber(i),m) then return end
        else return end
        F.finish(b)
        n.deadline=GetTime()+120
        if b.recorded then F.net=nil end
        changed(nil)
    end
end
function F.tick()
    local now=GetTime()
    for key,t in pairs(recent) do if now>t then recent[key]=nil end end
    if F.net then
        local why=blocked()
        if why then stop(why)
        elseif now>F.net.deadline then stop("Peer offline or timer expired. Challenge again when both players are ready.") end
    end
end
