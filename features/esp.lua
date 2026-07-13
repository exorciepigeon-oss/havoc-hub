-- HAVOC HUB : ESP feature
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local T=Hub.Theme local RunS=Hub.RunS local cam=Hub.cam

    local B6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local B15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local function bones(m) return m:FindFirstChild("UpperTorso") and B15 or B6 end

    local E,hls={},{}
    local function newL() local l=Drawing.new("Line") l.Thickness=1 l.Transparency=1 l.Visible=false return l end
    local function newS(f) local s=Drawing.new("Square") s.Filled=f s.Thickness=1 s.Transparency=1 s.Visible=false return s end
    local function newT(sz) local t=Drawing.new("Text") t.Size=sz or 13 t.Center=true t.Outline=true t.Transparency=1 t.Visible=false return t end
    local function ensure(m) if not E[m] then E[m]={box=newS(false),lines={},hpbg=newS(true),hpfill=newS(true),name=newT(13),weapon=newT(11)} E[m].hpbg.Color=Color3.new(0,0,0) for i=1,14 do E[m].lines[i]=newL() end end return E[m] end
    local function hide(m) if E[m] then local e=E[m] e.box.Visible=false e.hpbg.Visible=false e.hpfill.Visible=false e.name.Visible=false e.weapon.Visible=false for _,l in ipairs(e.lines) do l.Visible=false end end end
    local function rem(m) if E[m] then local e=E[m] pcall(function() e.box:Remove() e.hpbg:Remove() e.hpfill:Remove() e.name:Remove() e.weapon:Remove() for _,l in ipairs(e.lines) do l:Remove() end end) E[m]=nil end
        if hls[m] then pcall(function() hls[m]:Destroy() end) hls[m]=nil end end
    local function eHL(m,col,alpha) if hls[m] and hls[m].Parent then hls[m].FillColor=col hls[m].FillTransparency=1-alpha return hls[m] end
        hls[m]=Hub.mk("Highlight",{OutlineColor=Color3.new(1,1,1),FillColor=col,FillTransparency=1-alpha,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Adornee=m},m) return hls[m] end
    local function kHL(m) if hls[m] then pcall(function() hls[m]:Destroy() end) hls[m]=nil end end
    local function equipped(m) for _,c in ipairs(m:GetChildren()) do if c:IsA("Tool") then return c end end end

    -- UI tab
    local cESP=UI.AddTab("esp","ESP")
    local COLW=232 local LX,RX=0,COLW+8
    UI.Header(cESP,LX,0,COLW,"PLAYER")
    UI.ToggleColor(cESP,LX,22,COLW,"Box","P_BOX",true,"P_BOX_C",Color3.fromRGB(255,50,80),"P_BOX_A",1)
    UI.ToggleColor(cESP,LX,56,COLW,"Skeleton","P_SKEL",true,"P_SKEL_C",Color3.fromRGB(255,120,140),"P_SKEL_A",1)
    UI.ToggleColor(cESP,LX,90,COLW,"Chams","P_CHAMS",true,"P_CHAMS_C",Color3.fromRGB(255,50,80),"P_CHAMS_A",0.5)
    UI.ToggleColor(cESP,LX,124,COLW,"Health Bar","P_HP",true,"P_HP_C",Color3.fromRGB(0,255,80),"P_HP_A",1)
    UI.ToggleColor(cESP,LX,158,COLW,"Name + Weapon","P_NAME",true,"P_NAME_C",Color3.fromRGB(255,255,255),"P_NAME_A",1)
    UI.Header(cESP,RX,0,COLW,"NPC")
    UI.ToggleColor(cESP,RX,22,COLW,"Box","N_BOX",true,"N_BOX_C",Color3.fromRGB(245,197,24),"N_BOX_A",1)
    UI.ToggleColor(cESP,RX,56,COLW,"Skeleton","N_SKEL",true,"N_SKEL_C",Color3.fromRGB(255,255,255),"N_SKEL_A",1)
    UI.ToggleColor(cESP,RX,90,COLW,"Chams","N_CHAMS",true,"N_CHAMS_C",Color3.fromRGB(245,197,24),"N_CHAMS_A",0.5)
    UI.ToggleColor(cESP,RX,124,COLW,"Health Bar","N_HP",true,"N_HP_C",Color3.fromRGB(0,255,80),"N_HP_A",1)
    UI.ToggleColor(cESP,RX,158,COLW,"Name + Weapon","N_NAME",true,"N_NAME_C",Color3.fromRGB(255,255,255),"N_NAME_A",1)
    UI.Stepper(cESP,0,206,COLW*2+8,"Distance","MAX_DIST",3400,100,100,8000)

    -- Render
    RunS.RenderStepped:Connect(function()
        if Hub.G.HAVOC_STOP then return end
        pcall(function()
            local list=Hub.Enemies() local seen={}
            for _,info in pairs(list) do
                local m,hrp,hd,hum=info.m,info.hrp,info.hd,info.hum seen[m]=true local e=ensure(m)
                local pl=Hub.IsPlayer(m)
                local T_BOX=Hub.Get(pl and "P_BOX" or "N_BOX",true)
                local T_SKEL=Hub.Get(pl and "P_SKEL" or "N_SKEL",true)
                local T_CHAMS=Hub.Get(pl and "P_CHAMS" or "N_CHAMS",true)
                local T_HP=Hub.Get(pl and "P_HP" or "N_HP",true)
                local T_NAME=Hub.Get(pl and "P_NAME" or "N_NAME",true)
                local C_BOX=Hub.Get(pl and "P_BOX_C" or "N_BOX_C",Color3.fromRGB(245,197,24)) local A_BOX=Hub.Get(pl and "P_BOX_A" or "N_BOX_A",1)
                local C_SKEL=Hub.Get(pl and "P_SKEL_C" or "N_SKEL_C",Color3.new(1,1,1)) local A_SKEL=Hub.Get(pl and "P_SKEL_A" or "N_SKEL_A",1)
                local C_CHAMS=Hub.Get(pl and "P_CHAMS_C" or "N_CHAMS_C",Color3.fromRGB(245,197,24)) local A_CHAMS=Hub.Get(pl and "P_CHAMS_A" or "N_CHAMS_A",0.5)
                local C_HP=Hub.Get(pl and "P_HP_C" or "N_HP_C",Color3.fromRGB(0,255,80)) local A_HP=Hub.Get(pl and "P_HP_A" or "N_HP_A",1)
                local C_NAME=Hub.Get(pl and "P_NAME_C" or "N_NAME_C",Color3.new(1,1,1)) local A_NAME=Hub.Get(pl and "P_NAME_A" or "N_NAME_A",1)
                if T_CHAMS then eHL(m,C_CHAMS,A_CHAMS) else kHL(m) end
                local Tp=cam:WorldToViewportPoint(hd.Position+Vector3.new(0,1,0))
                local Bp=cam:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
                if Tp.Z>0 and Bp.Z>0 then
                    local ht=math.abs(Bp.Y-Tp.Y) local w=ht*0.5 local cx=(Tp.X+Bp.X)/2 local topY=math.min(Tp.Y,Bp.Y)
                    if T_BOX then e.box.Position=Vector2.new(cx-w/2,topY) e.box.Size=Vector2.new(w,ht) e.box.Color=C_BOX e.box.Transparency=A_BOX e.box.Visible=true else e.box.Visible=false end
                    if T_NAME then local line=m.Name.."  ["..math.floor(info.dist).."m]" if T_HP then line=line.."  "..math.floor(hum.Health).."hp" end
                        e.name.Text=line e.name.Position=Vector2.new(cx,topY-30) e.name.Color=C_NAME e.name.Transparency=A_NAME e.name.Visible=true
                        local tl=equipped(m) if tl then e.weapon.Text=tl.Name e.weapon.Position=Vector2.new(cx,topY-16) e.weapon.Color=C_BOX e.weapon.Transparency=A_NAME e.weapon.Visible=true else e.weapon.Visible=false end
                    else e.name.Visible=false e.weapon.Visible=false end
                    if T_HP then local f=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1) local x=cx-w/2-6
                        e.hpbg.Position=Vector2.new(x-1,topY-1) e.hpbg.Size=Vector2.new(5,ht+2) e.hpbg.Transparency=A_HP e.hpbg.Visible=true
                        local fh=ht*f e.hpfill.Position=Vector2.new(x,topY+(ht-fh)) e.hpfill.Size=Vector2.new(3,fh)
                        e.hpfill.Color=C_HP:Lerp(Hub.Theme.HP_LOW,1-f) e.hpfill.Transparency=A_HP e.hpfill.Visible=true
                    else e.hpbg.Visible=false e.hpfill.Visible=false end
                else hide(m) end
                if T_SKEL then local bn=bones(m)
                    for i,b in ipairs(bn) do local a=m:FindFirstChild(b[1]) local d=m:FindFirstChild(b[2]) local ln=e.lines[i]
                        if ln and a and d then local A=cam:WorldToViewportPoint(a.Position) local D=cam:WorldToViewportPoint(d.Position)
                            if A.Z>0 and D.Z>0 then ln.From=Vector2.new(A.X,A.Y) ln.To=Vector2.new(D.X,D.Y) ln.Color=C_SKEL ln.Transparency=A_SKEL ln.Visible=true else ln.Visible=false end
                        elseif ln then ln.Visible=false end end
                    for i=#bn+1,14 do if e.lines[i] then e.lines[i].Visible=false end end
                else for _,ln in ipairs(e.lines) do ln.Visible=false end end
            end
            for m in pairs(E) do if not seen[m] then hide(m) if not m.Parent then rem(m) end end end
        end)
    end)

    Hub.On("shutdown",function() for m in pairs(E) do rem(m) end end)
    UI.ShowTab("esp")
    Hub.RegisterModule("esp",{Start=function() end})
    print("[Hub ESP] loaded")
end)
