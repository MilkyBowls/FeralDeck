local _, F = ...

local directions={
    PADDLEFT={-1,0}, PADDRIGHT={1,0}, PADDUP={0,-1}, PADDDOWN={0,1},
}

-- Compare edges on the perpendicular axis so irregular grids still feel like rows and columns.
local function directionalScore(from,to,dx,dy)
    local x=(to.x+to.w/2)-(from.x+from.w/2)
    local y=(to.y+to.h/2)-(from.y+from.h/2)
    local forward=x*dx+y*dy
    if forward<=0 then return end
    local cross=math.abs(y*dx+x*dy)
    local halfSpan=(math.abs(dx)*(from.h+to.h)+math.abs(dy)*(from.w+to.w))/2
    local gap=math.max(0,cross-halfSpan)
    return forward+cross*.35+gap*3
end

function F.controllerNavigation(panel,back,switchTab)
    local nav={controls={},active=false}
    local ring=CreateFrame("Frame",nil,panel,"BackdropTemplate")
    ring:EnableMouse(false)
    ring:SetFrameLevel(panel:GetFrameLevel()+16)
    ring:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=2})
    ring:SetBackdropBorderColor(1,.79,.36,1)
    ring:Hide()

    local hint=panel:CreateFontString(nil,"OVERLAY")
    hint:SetFontObject(F.fonts.small)
    hint:SetPoint("BOTTOM",panel,"BOTTOM",0,8)
    hint:Hide()

    local function clearHelp()
        local widget=nav.help
        nav.help=nil
        if widget and GameTooltip and GameTooltip:IsOwned(widget) then GameTooltip:Hide() end
    end

    local function preview(node)
        if nav.endPreview then nav.endPreview() nav.endPreview=nil end
        if nav.active and node and node.widget.fdPadPreview then
            node.widget.fdPadPreview()
            nav.endPreview=node.widget.fdPadEndPreview
        end
    end

    local function draw()
        local node=nav.focus
        if not (nav.active and node) then ring:Hide() hint:Hide() return end
        ring:ClearAllPoints()
        ring:SetPoint("TOPLEFT",panel,"TOPLEFT",node.x-2,2-node.y)
        ring:SetSize(node.w+4,node.h+4)
        ring:Show()
        hint:SetShown(not nav.hideHint)
    end

    local function focus(node)
        if node~=nav.focus then clearHelp() end
        nav.focus=node
        preview(node)
        draw()
    end

    local function showHelp(node)
        if nav.help==node.widget then clearHelp() return end
        clearHelp()
        local enter=node.widget:GetScript("OnEnter")
        if enter and GameTooltip then
            enter(node.widget)
            if GameTooltip:IsOwned(node.widget) then nav.help=node.widget end
        end
    end

    function nav:begin(context)
        self.previous=self.focus
        self.changed=self.context~=context
        self.context=context
        self.controls={}
        self.submit,self.preferred=nil,nil
    end

    function nav:add(widget,x,y,w,h,kind,action)
        self.controls[#self.controls+1]={
            widget=widget,x=x,y=y,w=w,h=h,kind=kind,action=action,
            key=table.concat({kind,x,y,w,h},":"),
        }
    end

    function nav:finish(hideHint)
        self.hideHint=hideHint
        local previous=self.previous
        self.previous=nil
        local nextNode,score
        for _,node in ipairs(self.controls) do
            if previous and not self.changed and node.key==previous.key then nextNode=node break end
            if (self.changed or not previous) and node.widget==self.preferred then nextNode=node break end
            if node.kind~="close" then
                local distance=previous and not self.changed
                    and (math.abs(previous.x-node.x)+math.abs(previous.y-node.y))
                    or ((node.y<70 and 1000 or 0)+(node.kind=="help" and 500 or 0)+node.y+node.x*.001)
                if not score or distance<score then nextNode,score=node,distance end
            end
        end
        focus(nextNode)
        hint:SetText(self.submit and "D-pad Move   /   A Type   /   B Cancel   /   Y Done"
            or "D-pad Move   /   A Select   /   B Back   /   X Help   /   LB/RB Tabs")
        if panel.EnableGamePadButton then panel:EnableGamePadButton(F.db.controllerNav~=false) end
    end

    function nav:hide()
        clearHelp()
        self.active,self.focus,self.previous=false,nil,nil
        self.controls={}
        preview(nil)
        if panel.EnableGamePadButton then panel:EnableGamePadButton(false) end
        draw()
    end

    function nav:mouse()
        if not self.active then return end
        self.active=false
        preview(nil)
        clearHelp()
        draw()
    end

    function nav:input(button)
        if F.db.controllerNav==false or not panel:IsShown() then return end
        local direction=directions[button]
        if not (direction or button=="PAD1" or button=="PAD2" or button=="PAD3"
            or button=="PADLSHOULDER" or button=="PADRSHOULDER" or button=="PAD4" and self.submit) then return end
        local alreadyActive=self.active
        self.active=true
        if not alreadyActive then preview(self.focus) end
        draw()
        if button=="PAD4" then self.submit:GetScript("OnClick")(self.submit,"LeftButton") return end
        if button=="PAD2" then back() return end
        if button=="PADLSHOULDER" or button=="PADRSHOULDER" then
            switchTab(button=="PADLSHOULDER" and -1 or 1)
            return
        end
        local node=self.focus
        if not node then return end
        if direction then
            if not alreadyActive then return end
            local nextNode,best
            for _,candidate in ipairs(self.controls) do
                local score=directionalScore(node,candidate,direction[1],direction[2])
                if score and (not best or score<best) then nextNode,best=candidate,score end
            end
            if nextNode then focus(nextNode) end
        elseif button=="PAD3" or node.kind=="help" then
            showHelp(node)
        elseif alreadyActive then
            clearHelp()
            local action=node.action or node.widget:GetScript("OnClick")
            if action then action(node.widget,"LeftButton") end
        end
    end

    if panel.EnableGamePadButton then
        panel:SetScript("OnGamePadButtonDown",function(_,button) nav:input(button) end)
    end
    return nav
end

