-- HAVOC HUB : ESP v6 (native 3D adornments - zero projection, sync render pipeline)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local T=Hub.Theme local RunS=Hub.RunS local cam=Hub.cam

    local B6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local B15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local function bones(m) return m:FindFirstChild("UpperTorso") and B15 or B6 end

    -- Nuke previous adornment container on reload
    pcall(function() local old=game:GetService("CoreGui"):FindFirstChild("HavocHub_ESPAdorn") if old then old:Destroy() end end)
    local adornRoot=Instance.new("Folder") adornRoot.Name="HavocHub_ESPAdorn" adornRoot.Parent=game:GetService("CoreGui")

    local E,hl,hlOcc={},{},{}

    local function mkBoxBB(m,hrp)
        local bb=Instance.new("BillboardGui")
        bb.Adornee=hrp bb.AlwaysOnTop=true bb.Size=UDim2.fromScale(5,6.5)
        bb.LightInfluence=0 bb.MaxDistance=math.huge bb.ClipsDescendants=false
        bb.Parent=adornRoot
        local f=Instance.new("Frame") f.Size=UDim2.fromScale(1,1) f.BackgroundTransparency=1 f.BorderSizePixel=0 f.Parent=bb
        local s=Instance.new("UIStroke") s.Thickness=1 s.Color=Color3.new(1,1,1) s.Parent=f
        return bb,s
    end

    local function mkNameBB(m,hrp)
        local bb=Instance.new("BillboardGui")
        bb.Adornee=hrp bb.AlwaysOnTop=true
        -- Pixel size = taille écran constante
        bb.Size=UDim2.fromOffset(220,44)
        bb.StudsOffset=Vector3.new(0,2.5,0)
        -- SizeOffset(-1) => BB entièrement au-dessus point d'ancrage à toute distance
        bb.SizeOffset=Vector2.new(0,-1)
        bb.LightInfluence=0 bb.MaxDistance=math.huge
        bb.Parent=adornRoot
        local name=Instance.new("TextLabel") name.Size=UDim2.new(1,0,0.5,0) name.BackgroundTransparency=1
        name.Font=Enum.Font.Gotham name.TextSize=13 name.TextColor3=Color3.new(1,1,1)
        name.TextStrokeTransparency=0 name.Text="" name.Parent=bb
        local weap=Instance.new("TextLabel") weap.Size=UDim2.new(1,0,0.5,0) weap.Position=UDim2.new(0,0,0.5,0)
        weap.BackgroundTransparency=1 weap.Font=Enum.Font.Gotham weap.TextSize=11 weap.TextColor3=Color3.new(1,1,1)
        weap.TextStrokeTransparency=0.3 weap.Text="" weap.Parent=bb
        return bb,name,weap
    end

    local function mkHpBB(m,hrp)
        local bb=Instance.new("BillboardGui")
        bb.Adornee=hrp bb.AlwaysOnTop=true
        -- Hybrid: 8px de large fixe + 4 studs + 20px hauteur => toujours visible loin
        bb.Size=UDim2.new(0,8,4,20)
        bb.StudsOffset=Vector3.new(-2.5,0,0)
        bb.SizeOffset=Vector2.new(-0.5,0)
        bb.LightInfluence=0 bb.MaxDistance=math.huge
        bb.Parent=adornRoot
        local bg=Instance.new("Frame") bg.Size=UDim2.fromScale(1,1) bg.BackgroundColor3=Color3.new(0,0,0) bg.BorderSizePixel=0
        bg.BackgroundTransparency=0.4 bg.Parent=bb
        local fill=Instance.new("Frame") fill.AnchorPoint=Vector2.new(0,1) fill.Position=UDim2.fromScale(0,1)
        fill.Size=UDim2.fromScale(1,1) fill.BorderSizePixel=0 fill.BackgroundColor3=Color3.new(0,1,0) fill.Parent=bg
        return bb,bg,fill
    end

    local function mkLine(anchorPart)
        local ln=Instance.new("LineHandleAdornment")
        ln.AlwaysOnTop=true ln.ZIndex=1 ln.Thickness=2
        ln.Color3=Color3.new(1,1,1) ln.Transparency=0
        ln.Adornee=anchorPart ln.Parent=adornRoot
        return ln
    end

    local function ensure(m,hrp)
        if not E[m] then
            local boxBB,boxStroke=mkBoxBB(m,hrp)
            local nameBB,nameLbl,weapLbl=mkNameBB(m,hrp)
            local hpBB,hpBg,hpFill=mkHpBB(m,hrp)
            E[m]={boxBB=boxBB,boxStroke=boxStroke,nameBB=nameBB,nameLbl=nameLbl,weapLbl=weapLbl,hpBB=hpBB,hpBg=hpBg,hpFill=hpFill,lines={}}
        end
        return E[m]
    end

    local function killHL(m) if hl[m] then pcall(function() hl[m]:Destroy() end) hl[m]=nil end end
    -- Single Highlight sur modèle entier (comme user veut, chams marche bien)
    local function eHL(m,visCol,visAlpha,occOn,occCol,occAlpha)
        if not hl[m] or not hl[m].Parent then
            hl[m]=Instance.new("Highlight")
            hl[m].DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            hl[m].OutlineTransparency=1
            hl[m].Adornee=m hl[m].Parent=m
        end
        hl[m].FillColor=visCol hl[m].FillTransparency=1-visAlpha
        -- Occlusion split via 2e highlight
        if occOn then
            if not hlOcc[m] or not hlOcc[m].Parent then
                local h=Instance.new("Highlight")
                h.DepthMode=Enum.HighlightDepthMode.Occluded
                h.OutlineTransparency=1 h.Adornee=m h.Parent=m
                hlOcc[m]=h
            end
            hlOcc[m].FillColor=occCol hlOcc[m].FillTransparency=1-occAlpha
        elseif hlOcc[m] then pcall(function() hlOcc[m]:Destroy() end) hlOcc[m]=nil end
    end
    local kHL=function(m) killHL(m) if hlOcc[m] then pcall(function() hlOcc[m]:Destroy() end) hlOcc[m]=nil end end

    local function hide(e) e.boxBB.Enabled=false e.nameBB.Enabled=false e.hpBB.Enabled=false
        for _,ln in ipairs(e.lines) do ln.Visible=false end end

    local function rem(m) if E[m] then local e=E[m]
        pcall(function()
            e.boxBB:Destroy() e.nameBB:Destroy() e.hpBB:Destroy()
            for _,ln in ipairs(e.lines) do ln:Destroy() end
        end) E[m]=nil end
        kHL(m) end

    local function equipped(m) for _,c in ipairs(m:GetChildren()) do if c:IsA("Tool") then return c end end end

    -- UI
    local cESP=UI.AddTab("esp","ESP")
    local COLW=232 local LX,RX=0,COLW+8
    UI.Header(cESP,LX,0,COLW,"PLAYER",190)
    UI.ToggleColor(cESP,LX+4,10,COLW-8,"Box","P_BOX",true,"P_BOX_C",Color3.fromRGB(255,50,80),"P_BOX_A",1)
    UI.ToggleColor(cESP,LX+4,44,COLW-8,"Skeleton","P_SKEL",true,"P_SKEL_C",Color3.fromRGB(255,120,140),"P_SKEL_A",1)
    UI.ToggleColor(cESP,LX+4,78,COLW-8,"Chams","P_CHAMS",true,"P_CHAMS_C",Color3.fromRGB(255,50,80),"P_CHAMS_A",0.5)
    UI.ToggleColor(cESP,LX+4,112,COLW-8,"Health Bar","P_HP",true,"P_HP_C",Color3.fromRGB(0,255,80),"P_HP_A",1)
    UI.ToggleColor(cESP,LX+4,146,COLW-8,"Name + Weapon","P_NAME",true,"P_NAME_C",Color3.fromRGB(255,255,255),"P_NAME_A",1)
    UI.Header(cESP,RX,0,COLW,"NPC",190)
    UI.ToggleColor(cESP,RX+4,10,COLW-8,"Box","N_BOX",true,"N_BOX_C",Color3.fromRGB(245,197,24),"N_BOX_A",1)
    UI.ToggleColor(cESP,RX+4,44,COLW-8,"Skeleton","N_SKEL",true,"N_SKEL_C",Color3.fromRGB(255,255,255),"N_SKEL_A",1)
    UI.ToggleColor(cESP,RX+4,78,COLW-8,"Chams","N_CHAMS",true,"N_CHAMS_C",Color3.fromRGB(245,197,24),"N_CHAMS_A",0.5)
    UI.ToggleColor(cESP,RX+4,112,COLW-8,"Health Bar","N_HP",true,"N_HP_C",Color3.fromRGB(0,255,80),"N_HP_A",1)
    UI.ToggleColor(cESP,RX+4,146,COLW-8,"Name + Weapon","N_NAME",true,"N_NAME_C",Color3.fromRGB(255,255,255),"N_NAME_A",1)
    UI.Header(cESP,0,200,COLW*2+8,"CHAMS OCCLUSION SPLIT",56)
    UI.ToggleColor(cESP,LX+4,210,COLW-8,"Player Occluded","P_OCC",false,"P_OCC_C",Color3.fromRGB(100,100,100),"P_OCC_A",0.5)
    UI.ToggleColor(cESP,RX+4,210,COLW-8,"NPC Occluded","N_OCC",false,"N_OCC_C",Color3.fromRGB(100,100,100),"N_OCC_A",0.5)
    UI.Stepper(cESP,0,262,COLW*2+8,"Distance","MAX_DIST",3400,100,100,8000)

    -- Render loop: only update text/color/enabled. Positions auto-tracked par Roblox via Adornee.
    pcall(function() RunS:UnbindFromRenderStep("HubESP") end)
    RunS:BindToRenderStep("HubESP",Enum.RenderPriority.Last.Value+1,function()
        if Hub.G.HAVOC_STOP then return end
        pcall(function()
            local list=Hub.Enemies() local seen={}
            for _,info in pairs(list) do
                local m,hrp,hd,hum=info.m,info.hrp,info.hd,info.hum seen[m]=true
                if not hrp or not hd then continue end
                local e=ensure(m,hrp)
                local pl=Hub.IsPlayer(m)
                local T_BOX=Hub.Get(pl and "P_BOX" or "N_BOX",true) local T_SKEL=Hub.Get(pl and "P_SKEL" or "N_SKEL",true)
                local T_CHAMS=Hub.Get(pl and "P_CHAMS" or "N_CHAMS",true) local T_HP=Hub.Get(pl and "P_HP" or "N_HP",true) local T_NAME=Hub.Get(pl and "P_NAME" or "N_NAME",true)
                local OCC_ON=Hub.Get(pl and "P_OCC" or "N_OCC",false)
                local C_BOX=Hub.Get(pl and "P_BOX_C" or "N_BOX_C",Color3.fromRGB(245,197,24)) local A_BOX=Hub.Get(pl and "P_BOX_A" or "N_BOX_A",1)
                local C_SKEL=Hub.Get(pl and "P_SKEL_C" or "N_SKEL_C",Color3.new(1,1,1)) local A_SKEL=Hub.Get(pl and "P_SKEL_A" or "N_SKEL_A",1)
                local C_CHAMS=Hub.Get(pl and "P_CHAMS_C" or "N_CHAMS_C",Color3.fromRGB(245,197,24)) local A_CHAMS=Hub.Get(pl and "P_CHAMS_A" or "N_CHAMS_A",0.5)
                local C_HP=Hub.Get(pl and "P_HP_C" or "N_HP_C",Color3.fromRGB(0,255,80)) local A_HP=Hub.Get(pl and "P_HP_A" or "N_HP_A",1)
                local C_NAME=Hub.Get(pl and "P_NAME_C" or "N_NAME_C",Color3.new(1,1,1)) local A_NAME=Hub.Get(pl and "P_NAME_A" or "N_NAME_A",1)
                local C_OCC=Hub.Get(pl and "P_OCC_C" or "N_OCC_C",Color3.fromRGB(100,100,100))
                local A_OCC=Hub.Get(pl and "P_OCC_A" or "N_OCC_A",0.5)

                if T_CHAMS then eHL(m,C_CHAMS,A_CHAMS,OCC_ON,C_OCC,A_OCC) else kHL(m) end

                -- Box
                if T_BOX then
                    e.boxBB.Enabled=true e.boxStroke.Color=C_BOX e.boxStroke.Transparency=1-A_BOX
                else e.boxBB.Enabled=false end

                -- Name + Weapon
                if T_NAME then
                    e.nameBB.Enabled=true
                    local line=m.Name.."  ["..math.floor(info.dist).."m]" if T_HP then line=line.."  "..math.floor(hum.Health).."hp" end
                    e.nameLbl.Text=line e.nameLbl.TextColor3=C_NAME e.nameLbl.TextTransparency=1-A_NAME
                    local tl=equipped(m)
                    if tl then e.weapLbl.Text=tl.Name e.weapLbl.TextColor3=C_NAME e.weapLbl.TextTransparency=1-A_NAME e.weapLbl.Visible=true
                    else e.weapLbl.Visible=false end
                else e.nameBB.Enabled=false end

                -- HP bar
                if T_HP then
                    e.hpBB.Enabled=true
                    local f=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                    e.hpFill.Size=UDim2.fromScale(1,f)
                    e.hpFill.BackgroundColor3=C_HP:Lerp(Hub.Theme.HP_LOW,1-f)
                    e.hpFill.BackgroundTransparency=1-A_HP
                    e.hpBg.BackgroundTransparency=math.max(0.4,1-A_HP)
                else e.hpBB.Enabled=false end

                -- Skeleton via LineHandleAdornment natif (adornee=hrp, CFrame local)
                if T_SKEL then
                    local bn=bones(m)
                    local hrpCF=hrp.CFrame
                    for i,b in ipairs(bn) do
                        local a=m:FindFirstChild(b[1]) local d=m:FindFirstChild(b[2])
                        local ln=e.lines[i]
                        if a and d then
                            if not ln or not ln.Parent then ln=mkLine(hrp) e.lines[i]=ln end
                            if ln.Adornee~=hrp then ln.Adornee=hrp end
                            local aP,dP=a.Position,d.Position
                            local len=(dP-aP).Magnitude
                            if len>0.01 then
                                -- World CFrame lookAt(A->D), converted to hrp local space
                                ln.CFrame=hrpCF:ToObjectSpace(CFrame.lookAt(aP,dP))
                                ln.Length=len
                                ln.Color3=C_SKEL ln.Transparency=1-A_SKEL ln.Visible=true
                            else ln.Visible=false end
                        elseif ln then ln.Visible=false end
                    end
                    for i=#bn+1,14 do if e.lines[i] then e.lines[i].Visible=false end end
                else for _,ln in ipairs(e.lines) do if ln then ln.Visible=false end end end
            end
            -- Cleanup absent enemies
            for m,e in pairs(E) do if not seen[m] then hide(e) if not m.Parent then rem(m) end end end
        end)
    end)

    Hub.On("shutdown",function()
        for m in pairs(E) do rem(m) end
        pcall(function() RunS:UnbindFromRenderStep("HubESP") end)
        pcall(function() adornRoot:Destroy() end)
    end)
    UI.ShowTab("esp")
    Hub.RegisterModule("esp",{Start=function() end})
    print("[Hub ESP v6] loaded (native 3D adornments)")
end)
