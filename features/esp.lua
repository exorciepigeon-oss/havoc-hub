-- HAVOC HUB : ESP v5 (bind post-Last + occlusion split + bbox)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local T=Hub.Theme local RunS=Hub.RunS local cam=Hub.cam

    local B6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local B15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local function bones(m) return m:FindFirstChild("UpperTorso") and B15 or B6 end

    -- Native ScreenGui box + skeleton (sync render pipeline; Drawing lib lag fix)
    pcall(function() local old=game:GetService("CoreGui"):FindFirstChild("HavocHub_ESPNative") if old then old:Destroy() end end)
    local espGui=Hub.mk("ScreenGui",{Name="HavocHub_ESPNative",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=1e5},game:GetService("CoreGui"))
    local E,hlsV,hlsO={},{},{}
    local function newL() local f=Instance.new("Frame") f.AnchorPoint=Vector2.new(0.5,0.5) f.BorderSizePixel=0 f.Visible=false f.Parent=espGui return f end
    local function newBox() local f=Instance.new("Frame") f.BackgroundTransparency=1 f.BorderSizePixel=0 f.Visible=false f.Parent=espGui
        local s=Instance.new("UIStroke") s.Thickness=1 s.Parent=f return f,s end
    local function newT(sz) local t=Drawing.new("Text") t.Size=sz or 13 t.Center=true t.Outline=true t.Transparency=1 t.Visible=false return t end
    local function newS(f) local s=Drawing.new("Square") s.Filled=f s.Thickness=1 s.Transparency=1 s.Visible=false return s end
    local function ensure(m) if not E[m] then
        local box,boxStroke=newBox()
        E[m]={box=box,boxStroke=boxStroke,lines={},hpbg=newS(true),hpfill=newS(true),name=newT(13),weapon=newT(11)}
        E[m].hpbg.Color=Color3.new(0,0,0)
        for i=1,14 do E[m].lines[i]=newL() end
    end return E[m] end
    local function hide(m) if E[m] then local e=E[m] e.box.Visible=false e.hpbg.Visible=false e.hpfill.Visible=false e.name.Visible=false e.weapon.Visible=false for _,l in ipairs(e.lines) do l.Visible=false end end end
    local function killHL(m) if hlsV[m] then pcall(function() hlsV[m]:Destroy() end) hlsV[m]=nil end
        if hlsO[m] then pcall(function() hlsO[m]:Destroy() end) hlsO[m]=nil end end
    local function rem(m) if E[m] then local e=E[m] pcall(function() e.box:Destroy() e.hpbg:Remove() e.hpfill:Remove() e.name:Remove() e.weapon:Remove() for _,l in ipairs(e.lines) do l:Destroy() end end) E[m]=nil end
        killHL(m) end
    -- Double Highlight = split occlusion: AlwaysOnTop paint tout en visCol, Occluded overwrite portion cachee en occCol
    local function eHL(m,visCol,visAlpha,occOn,occCol,occAlpha)
        if not hlsV[m] or not hlsV[m].Parent then
            hlsV[m]=Hub.mk("Highlight",{FillColor=visCol,FillTransparency=1-visAlpha,OutlineTransparency=1,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Adornee=m},m)
        else hlsV[m].FillColor=visCol hlsV[m].FillTransparency=1-visAlpha end
        if occOn then
            if not hlsO[m] or not hlsO[m].Parent then
                hlsO[m]=Hub.mk("Highlight",{FillColor=occCol,FillTransparency=1-occAlpha,OutlineTransparency=1,DepthMode=Enum.HighlightDepthMode.Occluded,Adornee=m},m)
            else hlsO[m].FillColor=occCol hlsO[m].FillTransparency=1-occAlpha end
        elseif hlsO[m] then pcall(function() hlsO[m]:Destroy() end) hlsO[m]=nil end
    end
    local kHL=killHL
    local function equipped(m) for _,c in ipairs(m:GetChildren()) do if c:IsA("Tool") then return c end end end

    -- occlusion check: raycast camera -> target
    local function visible(target,parentModel)
        local o=cam.CFrame.Position local dir=target-o local dist=dir.Magnitude
        if dist<0.1 then return true end
        local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances={Hub.lp.Character,cam} rp.IgnoreWater=true
        local res=workspace:Raycast(o,dir,rp)
        if not res then return true end
        return res.Instance:IsDescendantOf(parentModel)
    end

    local cESP=UI.AddTab("esp","ESP")
    local COLW=232 local LX,RX=0,COLW+8
    -- Rectangles gris autour des sous-categories (Header avec hauteur = groupe)
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

    -- FIX jitter: manual projection avec GetRenderCFrame (bypass WorldToViewportPoint lag)
    pcall(function() RunS:UnbindFromRenderStep("HubESP") end)
    local function project(pos,camCF,vp,halfW,halfH)
        local rel=camCF:PointToObjectSpace(pos)
        if rel.Z>=0 then return Vector3.new(0,0,-1) end
        local ndcX=rel.X/(-rel.Z*halfW) local ndcY=-rel.Y/(-rel.Z*halfH)
        return Vector3.new((ndcX*0.5+0.5)*vp.X,(ndcY*0.5+0.5)*vp.Y,-rel.Z)
    end
    RunS:BindToRenderStep("HubESP",Enum.RenderPriority.Last.Value+1,function()
        if Hub.G.HAVOC_STOP then return end
        pcall(function()
            local list=Hub.Enemies() local seen={}
            local camCF=cam:GetRenderCFrame()
            local vp=cam.ViewportSize
            local halfH=math.tan(math.rad(cam.FieldOfView)/2)
            local halfW=halfH*(vp.X/vp.Y)
            for _,info in pairs(list) do
                local m,hrp,hd,hum=info.m,info.hrp,info.hd,info.hum seen[m]=true local e=ensure(m)
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
                -- POSITIONS: part.Position (render-synced) au lieu de CFrame.Position
                local hdPos=hd.Position local hrpPos=hrp.Position
                local Tp=project(hdPos+Vector3.new(0,1,0),camCF,vp,halfW,halfH)
                local Bp=project(hrpPos-Vector3.new(0,3,0),camCF,vp,halfW,halfH)
                if Tp.Z>0 and Bp.Z>0 then
                    local ht=math.abs(Bp.Y-Tp.Y) local w=ht*0.5 local cx=(Tp.X+Bp.X)/2 local topY=math.min(Tp.Y,Bp.Y)
                    if T_BOX then
                        e.box.Position=UDim2.fromOffset(cx-w/2,topY) e.box.Size=UDim2.fromOffset(w,ht)
                        e.boxStroke.Color=C_BOX e.boxStroke.Transparency=1-A_BOX e.box.Visible=true
                    else e.box.Visible=false end
                    if T_NAME then
                        local line=m.Name.."  ["..math.floor(info.dist).."m]" if T_HP then line=line.."  "..math.floor(hum.Health).."hp" end
                        e.name.Text=line e.name.Position=Vector2.new(cx,topY-30) e.name.Color=C_NAME e.name.Transparency=A_NAME e.name.Visible=true
                        local tl=equipped(m) if tl then e.weapon.Text=tl.Name e.weapon.Position=Vector2.new(cx,topY-16) e.weapon.Color=C_NAME e.weapon.Transparency=A_NAME e.weapon.Visible=true else e.weapon.Visible=false end
                    else e.name.Visible=false e.weapon.Visible=false end
                    if T_HP then local f=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1) local x=cx-w/2-6
                        e.hpbg.Position=Vector2.new(x-1,topY-1) e.hpbg.Size=Vector2.new(5,ht+2) e.hpbg.Transparency=A_HP e.hpbg.Visible=true
                        local fh=ht*f e.hpfill.Position=Vector2.new(x,topY+(ht-fh)) e.hpfill.Size=Vector2.new(3,fh)
                        e.hpfill.Color=C_HP:Lerp(Hub.Theme.HP_LOW,1-f) e.hpfill.Transparency=A_HP e.hpfill.Visible=true
                    else e.hpbg.Visible=false e.hpfill.Visible=false end
                else hide(m) end
                if T_SKEL then local bn=bones(m)
                    for i,b in ipairs(bn) do local a=m:FindFirstChild(b[1]) local d=m:FindFirstChild(b[2]) local ln=e.lines[i]
                        if ln and a and d then
                            local aP=a.Position local dP=d.Position
                            local A=project(aP,camCF,vp,halfW,halfH) local D=project(dP,camCF,vp,halfW,halfH)
                            if A.Z>0 and D.Z>0 then
                                local dx=D.X-A.X local dy=D.Y-A.Y
                                local len=math.sqrt(dx*dx+dy*dy)
                                ln.Position=UDim2.fromOffset((A.X+D.X)/2,(A.Y+D.Y)/2)
                                ln.Size=UDim2.fromOffset(len,1)
                                ln.Rotation=math.deg(math.atan2(dy,dx))
                                ln.BackgroundColor3=C_SKEL ln.BackgroundTransparency=1-A_SKEL ln.Visible=true
                            else ln.Visible=false end
                        elseif ln then ln.Visible=false end end
                    for i=#bn+1,14 do if e.lines[i] then e.lines[i].Visible=false end end
                else for _,ln in ipairs(e.lines) do ln.Visible=false end end
            end
            for m in pairs(E) do if not seen[m] then hide(m) if not m.Parent then rem(m) end end end
        end)
    end)

    Hub.On("shutdown",function() for m in pairs(E) do rem(m) end pcall(function() RunS:UnbindFromRenderStep("HubESP") end) pcall(function() espGui:Destroy() end) end)
    UI.ShowTab("esp")
    Hub.RegisterModule("esp",{Start=function() end})
    print("[Hub ESP v5] loaded")
end)
