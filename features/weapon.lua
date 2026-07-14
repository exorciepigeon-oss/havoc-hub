-- HAVOC HUB : Weapon v6 (auto-detect remotes by signature on first call)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local RunS=Hub.RunS local UIS=Hub.UIS local cam=Hub.cam

    local fovCirc=Drawing.new("Circle") fovCirc.Thickness=1 fovCirc.NumSides=48 fovCirc.Transparency=1 fovCirc.Visible=false fovCirc.Filled=false

    local cached={head=nil,pos=nil}
    local aiming=false
    UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false end end)

    pcall(function() RunS:UnbindFromRenderStep("HubAim") end)
    RunS:BindToRenderStep("HubAim",Enum.RenderPriority.Camera.Value+1,function()
        if Hub.G.HAVOC_STOP then cached.head=nil return end
        pcall(function()
            if Hub.Get("FOV_CIRCLE",false) then local ctr=cam.ViewportSize/2 fovCirc.Position=Vector2.new(ctr.X,ctr.Y) fovCirc.Radius=Hub.Get("FOV_SIZE",150) fovCirc.Color=Hub.Get("FOV_C",Color3.new(1,1,1)) fovCirc.Visible=true else fovCirc.Visible=false end
            local mouse=UIS:GetMouseLocation() local best,bd=nil,Hub.Get("FOV_SIZE",150)
            for _,info in pairs(Hub.Enemies()) do
                if info.hd and info.hd.Parent then
                    local sp=cam:WorldToViewportPoint(info.hd.Position)
                    if sp.Z>0 then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude if d<bd then bd=d best=info.hd end end
                end
            end
            if best and best.Parent then cached.head=best cached.pos=best.Position else cached.head=nil cached.pos=nil end
            if Hub.Get("AIMBOT",false) and aiming and mousemoverel and cached.head then
                local sp=cam:WorldToViewportPoint(cached.pos)
                if sp.Z>0 then local ctr=cam.ViewportSize/2 local sm=Hub.Get("AIM_SMOOTH",0.35)
                    mousemoverel((sp.X-ctr.X)*sm,(sp.Y-ctr.Y)*sm) end
            end
        end)
    end)

    -- NO SWAY loop
    task.spawn(function()
        while not Hub.G.HAVOC_STOP do
            if Hub.Get("NO_SWAY",false) then
                pcall(function()
                    local c=Hub.lp.Character
                    if c then
                        local h=c:FindFirstChildOfClass("Humanoid")
                        if h then h.CameraOffset=Vector3.zero end
                        local tool=c:FindFirstChildOfClass("Tool")
                        if tool then
                            for _,d in ipairs(tool:GetDescendants()) do
                                if d:IsA("Motor6D") then
                                    local n=d.Name:lower()
                                    if n:find("grip") or n:find("sway") or n:find("hold") then
                                        d.Transform=CFrame.new()
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            RunS.RenderStepped:Wait()
        end
    end)

    -- Auto-detect remotes: cache la 1ere instance qui match la signature
    local shootRemote,recoilRemote

    -- HOOK: identifie et intercepte
    local mt=getrawmetatable(game)
    local oldNC=mt.__namecall
    setreadonly(mt,false)
    mt.__namecall=newcclosure(function(self,...)
        if Hub.G.HAVOC_STOP then return oldNC(self,...) end
        -- Fast path: si pas RemoteEvent FireServer => passthrough total
        local ok,cls=pcall(function() return self.ClassName end)
        if not ok or cls~="RemoteEvent" then return oldNC(self,...) end
        if getnamecallmethod()~="FireServer" then return oldNC(self,...) end

        -- Detection auto par signature
        local n=select("#",...)
        if not shootRemote and n==3 then
            local a1,a2,a3=select(1,...),select(2,...),select(3,...)
            local isT=false pcall(function() isT=typeof(a1)=="Instance" and a1:IsA("Tool") end)
            if isT and typeof(a2)=="Vector3" and typeof(a3)=="Vector3" then
                shootRemote=self
                warn("[Hub] shootRemote detected:",self:GetFullName())
            end
        end
        if not recoilRemote then
            local ok2,name=pcall(function() return self.Name end)
            if ok2 and name=="SetLookAngles" then
                recoilRemote=self
                warn("[Hub] recoilRemote detected:",self:GetFullName())
            end
        end

        -- NO RECOIL sur recoilRemote
        if self==recoilRemote and Hub.Get("NO_RECOIL",false) then
            local a1,a2=select(1,...),select(2,...)
            if type(a1)=="number" and type(a2)=="number" then
                return oldNC(self,a1*0.05,a2*0.05,select(3,...))
            end
            return oldNC(self,...)
        end

        -- SILENT AIM / NO SPREAD / TRACER sur shootRemote
        if self==shootRemote and n==3 then
            local a1,a2,a3=select(1,...),select(2,...),select(3,...)
            -- Bullet tracer via Beam (smooth, rounded, effets via presets)
            if Hub.Get("TRACER_ON",false) and typeof(a2)=="Vector3" and typeof(a3)=="Vector3" then
                task.spawn(function()
                    local dist=Hub.Get("TRACER_DIST",300)
                    local dir=a3.Unit if dir~=dir then return end
                    local endPt=a2+dir*dist
                    local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
                    rp.FilterDescendantsInstances={Hub.lp.Character} rp.IgnoreWater=true
                    local res=workspace:Raycast(a2,dir*dist,rp)
                    if res then endPt=res.Position end
                    local len=(endPt-a2).Magnitude
                    if len<0.5 then return end

                    -- Anchor part invisible + 2 Attachments
                    local anchor=Instance.new("Part")
                    anchor.Anchored=true anchor.CanCollide=false anchor.CanQuery=false anchor.CanTouch=false
                    anchor.Transparency=1 anchor.Size=Vector3.new(0.1,0.1,0.1)
                    anchor.CFrame=CFrame.new(a2)
                    local att0=Instance.new("Attachment") att0.WorldPosition=a2 att0.Parent=anchor
                    local att1=Instance.new("Attachment") att1.WorldPosition=endPt att1.Parent=anchor

                    local beam=Instance.new("Beam")
                    beam.Attachment0=att0 beam.Attachment1=att1
                    beam.FaceCamera=true beam.LightInfluence=0
                    local thick=Hub.Get("TRACER_THICK",6)/10
                    beam.Width0=thick beam.Width1=thick
                    beam.Segments=12

                    local col=Hub.Get("TRACER_C",Color3.fromRGB(255,80,255))
                    local fx=Hub.Get("TRACER_FX","Neon")
                    print("[tracer] fx="..tostring(fx).." len="..tostring(len))
                    -- Preset par effet
                    if fx=="Neon" then
                        beam.LightEmission=1 beam.Color=ColorSequence.new(col)
                    elseif fx=="Lightning" then
                        beam.LightEmission=1 beam.Color=ColorSequence.new(col)
                        beam.CurveSize0=(math.random()*2-1)*len*0.15
                        beam.CurveSize1=(math.random()*2-1)*len*0.15
                        beam.Segments=24
                    elseif fx=="Wavy" then
                        beam.LightEmission=1 beam.Color=ColorSequence.new(col)
                        beam.CurveSize0=len*0.08 beam.CurveSize1=-len*0.08
                    elseif fx=="ForceField" then
                        beam.LightEmission=0.6 beam.Color=ColorSequence.new(col)
                        beam.Texture="rbxasset://textures/particles/sparkles_main.dds" beam.TextureLength=2 beam.TextureSpeed=2
                    elseif fx=="Fire" then
                        beam.LightEmission=1
                        beam.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,220,0)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,120,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,20,0))})
                        beam.CurveSize0=len*0.05
                    elseif fx=="Rainbow" then
                        beam.LightEmission=1
                        beam.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.2,Color3.fromRGB(255,200,0)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,200,255)),ColorSequenceKeypoint.new(0.8,Color3.fromRGB(80,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,220))})
                    elseif fx=="Plasma" then
                        beam.LightEmission=1
                        beam.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(180,0,255)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,200,255))})
                        beam.CurveSize0=len*0.1 beam.CurveSize1=-len*0.1
                    elseif fx=="Ghost" then
                        beam.LightEmission=0.5 beam.Color=ColorSequence.new(col)
                        beam.Transparency=NumberSequence.new(0.6)
                    else beam.LightEmission=1 beam.Color=ColorSequence.new(col) end
                    beam.Parent=anchor
                    anchor.Parent=workspace

                    -- Fade manuel (Transparency = NumberSequence, non-tweenable direct)
                    local dur=Hub.Get("TRACER_DUR",500)/1000
                    local start=tick()
                    while tick()-start<dur do
                        local t=(tick()-start)/dur
                        beam.Transparency=NumberSequence.new(t)
                        RunS.RenderStepped:Wait()
                    end
                    anchor:Destroy()
                end)
            end
            if Hub.Get("SILENT_AIM",false) then
                local head=cached.head local hpos=cached.pos
                if Hub.Get("DEBUG_SHOT",false) then
                    warn("[SHOT DEBUG] orig dir:",a3,"| cached head:",head and head.Parent and head.Parent.Name or "NIL","| cached pos:",hpos)
                end
                if head and hpos then
                    local dir=hpos-a2
                    if dir.Magnitude>=0.1 then
                        local nd=dir.Unit
                        if nd.X==nd.X then
                            if Hub.Get("DEBUG_SHOT",false) then warn("[SHOT DEBUG] rewritten dir:",nd) end
                            -- CAMERA SWAP: force camera to face head at moment of shot (beats server validation)
                            if Hub.Get("CAM_SWAP",true) then
                                local origCF=cam.CFrame
                                cam.CFrame=CFrame.new(origCF.Position,hpos)
                                local res=oldNC(self,a1,a2,nd)
                                cam.CFrame=origCF
                                return res
                            end
                            return oldNC(self,a1,a2,nd)
                        end
                    end
                end
                if Hub.Get("DEBUG_SHOT",false) then warn("[SHOT DEBUG] silent aim SKIPPED (no target in FOV)") end
            end
            if Hub.Get("NO_SPREAD",false) then
                local ok3,camDir=pcall(function() return cam.CFrame.LookVector end)
                if ok3 and typeof(camDir)=="Vector3" and camDir.Magnitude>0.1 then
                    return oldNC(self,a1,a2,camDir.Unit)
                end
            end
        end

        return oldNC(self,...)
    end)
    setreadonly(mt,true)

    local cW=UI.AddTab("weapon","Weapon") local COLW=232 local LX,RX=0,COLW+8
    UI.Row(cW,LX,0,COLW,"Aimbot (right click)",function() return Hub.Get("AIMBOT",false) end,function(v) Hub.Set("AIMBOT",v) end)
    UI.ToggleColor(cW,RX,0,COLW,"FOV Circle","FOV_CIRCLE",false,"FOV_C",Color3.new(1,1,1))
    UI.Row(cW,LX,34,COLW,"No Recoil",function() return Hub.Get("NO_RECOIL",false) end,function(v) Hub.Set("NO_RECOIL",v) end)
    UI.Row(cW,RX,34,COLW,"No Spread",function() return Hub.Get("NO_SPREAD",false) end,function(v) Hub.Set("NO_SPREAD",v) end)
    UI.Row(cW,LX,68,COLW,"No Sway",function() return Hub.Get("NO_SWAY",false) end,function(v) Hub.Set("NO_SWAY",v) end)
    UI.Stepper(cW,0,102,COLW*2+8,"FOV Size (px)","FOV_SIZE",150,10,20,600)
    UI.Step(cW,0,138,COLW*2+8,"Aim Smooth x100",function() return math.floor(Hub.Get("AIM_SMOOTH",0.35)*100) end,function(v) Hub.Set("AIM_SMOOTH",v/100) end,5,5,100)

    UI.Header(cW,0,172,COLW*2+8,"Bullet Tracer",180)
    UI.ToggleColor(cW,LX+4,182,COLW-8,"Bullet Tracer","TRACER_ON",false,"TRACER_C",Color3.fromRGB(255,255,0))
    UI.Dropdown(cW,RX+4,182,COLW-8,"Effect","TRACER_FX","Neon",{"Neon","Lightning","Wavy","ForceField","Fire","Rainbow","Plasma","Ghost"})
    UI.Stepper(cW,LX+4,216,COLW-8,"Thickness","TRACER_THICK",6,1,1,30)
    UI.Stepper(cW,RX+4,216,COLW-8,"Duration (ms)","TRACER_DUR",500,50,100,2000)
    UI.Stepper(cW,0,250,COLW*2+8,"Max Distance","TRACER_DIST",300,25,50,1500)

    Hub.On("shutdown",function() pcall(function() fovCirc:Remove() RunS:UnbindFromRenderStep("HubAim") end) end)
    Hub.RegisterModule("weapon",{Start=function() end})
    print("[Hub Weapon v6] loaded")
end)
