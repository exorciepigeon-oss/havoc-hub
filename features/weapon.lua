-- HAVOC HUB : Weapon v6 (auto-detect remotes by signature on first call)
local Hub=_G.HavocHub if not Hub then return end
Hub.UnsafeKeys.INSTANT_RELOAD=true
Hub.UnsafeKeys.AUTO_FILL=true
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

    -- ===== PRO TRACER SPAWNER =====
    -- Reusable par shootRemote hook + Test button + futurs features
    local TS=game:GetService("TweenService")
    local function mkAnchor(pos)
        local p=Instance.new("Part") p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false
        p.Transparency=1 p.Size=Vector3.new(0.1,0.1,0.1) p.CFrame=CFrame.new(pos) p.Parent=workspace
        return p
    end
    local function mkAtt(parent,localPos) local a=Instance.new("Attachment") a.Parent=parent a.Position=localPos return a end
    local function mkBeam(a0,a1,cfg)
        local b=Instance.new("Beam")
        b.Attachment0=a0 b.Attachment1=a1 b.FaceCamera=true b.LightInfluence=0 b.LightEmission=1
        b.Segments=cfg.segments or 20 b.Width0=cfg.width0 or 0.5 b.Width1=cfg.width1 or (cfg.width0 or 0.5)
        if cfg.color then b.Color=cfg.color end
        if cfg.texture then b.Texture=cfg.texture b.TextureLength=cfg.textureLength or 2 b.TextureSpeed=cfg.textureSpeed or 3 b.TextureMode=Enum.TextureMode.Stretch end
        if cfg.curve0 then b.CurveSize0=cfg.curve0 end
        if cfg.curve1 then b.CurveSize1=cfg.curve1 end
        if cfg.transparency then b.Transparency=cfg.transparency end
        return b
    end

    function Hub._SpawnTracer(origin,dirVec)
        local dist=Hub.Get("TRACER_DIST",300)
        local dir=dirVec.Unit if dir~=dir then return end
        local endPt=origin+dir*dist
        local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances={Hub.lp.Character} rp.IgnoreWater=true
        local res=workspace:Raycast(origin,dir*dist,rp) if res then endPt=res.Position end
        local len=(endPt-origin).Magnitude if len<0.5 then return end

        local anchor=mkAnchor(origin)
        local a0=mkAtt(anchor,Vector3.zero)
        local a1=mkAtt(anchor,endPt-origin)

        local col=Hub.Get("TRACER_C",Color3.fromRGB(255,80,255))
        local thick=Hub.Get("TRACER_THICK",6)/10
        local fx=Hub.Get("TRACER_FX","Laser")
        local dur=Hub.Get("TRACER_DUR",500)/1000
        local beams={}
        local liveHook -- optional per-frame anim callback

        if fx=="Laser" then
            -- Halo large translucide + core fin bright => effet laser propre
            table.insert(beams,mkBeam(a0,a1,{width0=thick*3,color=ColorSequence.new(col),transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(1,0.85)})}))
            table.insert(beams,mkBeam(a0,a1,{width0=thick*0.6,color=ColorSequence.new(Color3.new(1,1,1),col)}))
        elseif fx=="Bolt" then
            -- Éclair jagged intense
            local seg=32
            table.insert(beams,mkBeam(a0,a1,{width0=thick*2.5,color=ColorSequence.new(col),transparency=NumberSequence.new(0.6),segments=seg}))
            local core=mkBeam(a0,a1,{width0=thick*0.8,color=ColorSequence.new(Color3.new(1,1,1),col),segments=seg,
                curve0=(math.random()*2-1)*len*0.2,curve1=(math.random()*2-1)*len*0.2})
            table.insert(beams,core)
        elseif fx=="Trail" then
            -- Ribbon wide->narrow taper, fade quick
            table.insert(beams,mkBeam(a0,a1,{width0=thick*4,width1=thick*0.3,color=ColorSequence.new(col)}))
        elseif fx=="Plasma" then
            -- ColorSequence cycle animé pendant vie du beam
            local core=mkBeam(a0,a1,{width0=thick*1.2,curve0=len*0.08,curve1=-len*0.08,segments=28})
            local halo=mkBeam(a0,a1,{width0=thick*3.5,transparency=NumberSequence.new(0.75)})
            table.insert(beams,halo) table.insert(beams,core)
            liveHook=function(t)
                local h=(tick()*3)%1
                local c1=Color3.fromHSV(h,1,1) local c2=Color3.fromHSV((h+0.4)%1,1,1)
                local cs=ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,c2)})
                core.Color=cs halo.Color=cs
            end
        elseif fx=="Glow" then
            -- Beam très épais LightEmission max, aura douce
            table.insert(beams,mkBeam(a0,a1,{width0=thick*6,color=ColorSequence.new(col),transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.85),NumberSequenceKeypoint.new(0.5,0.7),NumberSequenceKeypoint.new(1,0.85)})}))
            table.insert(beams,mkBeam(a0,a1,{width0=thick*1.5,color=ColorSequence.new(Color3.new(1,1,1),col)}))
        elseif fx=="Neon" then
            table.insert(beams,mkBeam(a0,a1,{width0=thick,color=ColorSequence.new(col)}))
        elseif fx=="Lightning" then
            table.insert(beams,mkBeam(a0,a1,{width0=thick,color=ColorSequence.new(col),segments=32,
                curve0=(math.random()*2-1)*len*0.15,curve1=(math.random()*2-1)*len*0.15}))
        elseif fx=="Fire" then
            local cs=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,220,0)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,120,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,20,0))})
            table.insert(beams,mkBeam(a0,a1,{width0=thick*2,color=cs,curve0=len*0.05}))
        elseif fx=="Rainbow" then
            local cs=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.2,Color3.fromRGB(255,200,0)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,200,255)),ColorSequenceKeypoint.new(0.8,Color3.fromRGB(80,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,220))})
            table.insert(beams,mkBeam(a0,a1,{width0=thick*1.2,color=cs}))
        elseif fx=="Ghost" then
            table.insert(beams,mkBeam(a0,a1,{width0=thick,color=ColorSequence.new(col),transparency=NumberSequence.new(0.6)}))
        else
            table.insert(beams,mkBeam(a0,a1,{width0=thick,color=ColorSequence.new(col)}))
        end
        for _,b in ipairs(beams) do b.Parent=anchor end

        -- Fade + live anim
        task.spawn(function()
            local start=tick()
            while tick()-start<dur do
                local t=(tick()-start)/dur
                for _,b in ipairs(beams) do
                    local base=b.Transparency and b.Transparency.Keypoints[1].Value or 0
                    b.Transparency=NumberSequence.new(math.min(1,base+t*(1-base)))
                end
                if liveHook then liveHook(t) end
                RunS.RenderStepped:Wait()
            end
            anchor:Destroy()
        end)
    end

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
            -- Bullet tracer via Beam (via fn factorisée, reusable par Test button)
            if Hub.Get("TRACER_ON",false) and typeof(a2)=="Vector3" and typeof(a3)=="Vector3" then
                task.spawn(function() Hub._SpawnTracer(a2,a3) end)
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

    UI.Header(cW,0,172,COLW*2+8,"Bullet Tracer",220)
    UI.ToggleColor(cW,LX+4,182,COLW-8,"Bullet Tracer","TRACER_ON",false,"TRACER_C",Color3.fromRGB(255,60,255))
    UI.Dropdown(cW,RX+4,182,COLW-8,"Effect","TRACER_FX","Laser",{"Laser","Bolt","Trail","Plasma","Glow","Neon","Lightning","Fire","Rainbow","Ghost"})
    UI.Stepper(cW,LX+4,216,COLW-8,"Thickness","TRACER_THICK",6,1,1,30)
    UI.Stepper(cW,RX+4,216,COLW-8,"Duration (ms)","TRACER_DUR",500,50,100,2000)
    UI.Stepper(cW,0,250,COLW*2+8,"Max Distance","TRACER_DIST",300,25,50,1500)
    UI.Button(cW,0,286,COLW*2+8,"Test Tracer",function()
        if Hub._SpawnTracer then Hub._SpawnTracer(cam.CFrame.Position+cam.CFrame.RightVector*3,cam.CFrame.LookVector) end
    end)

    UI.Header(cW,0,320,COLW*2+8,"Weapon Assist",90)
    UI.Row(cW,LX+4,330,COLW-8,"Instant Reload","INSTANT_RELOAD",false)
    UI.Row(cW,RX+4,330,COLW-8,"Auto Fill Mags","AUTO_FILL",false)

    -- Loop: cible tool équipé, force values de _data (Havoc client-side)
    local watchedTool=nil local reloadConn=nil
    local function forceCompleteReload(data)
        local ammoC=data:FindFirstChild("ammoCurrent") local ammoS=data:FindFirstChild("ammoSize")
        local cl=data:FindFirstChild("cl_complete") local sv=data:FindFirstChild("sv_complete")
        local rl=data:FindFirstChild("reload") local rling=data:FindFirstChild("reloading")
        if ammoC and ammoS then ammoC.Value=ammoS.Value end
        if cl then cl.Value=true end if sv then sv.Value=true end
        if rl then rl.Value=false end if rling then rling.Value=false end
    end
    local function bindTool(tool)
        if watchedTool==tool then return end
        watchedTool=tool
        if reloadConn then reloadConn:Disconnect() reloadConn=nil end
        if not tool then return end
        local data=tool:FindFirstChild("_data")
        if not data then return end
        local rling=data:FindFirstChild("reloading")
        if rling then
            reloadConn=rling:GetPropertyChangedSignal("Value"):Connect(function()
                if Hub.Get("INSTANT_RELOAD",false) and rling.Value then
                    task.wait() -- laisse Havoc set le state
                    forceCompleteReload(data)
                end
            end)
        end
    end
    Hub.lp.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(c) if c:IsA("Tool") then bindTool(c) end end)
        char.ChildRemoved:Connect(function(c) if c==watchedTool then bindTool(nil) end end)
    end)
    if Hub.lp.Character then
        Hub.lp.Character.ChildAdded:Connect(function(c) if c:IsA("Tool") then bindTool(c) end end)
        Hub.lp.Character.ChildRemoved:Connect(function(c) if c==watchedTool then bindTool(nil) end end)
        local t=Hub.lp.Character:FindFirstChildOfClass("Tool") if t then bindTool(t) end
    end
    -- Auto fill heartbeat
    RunS.Heartbeat:Connect(function()
        if Hub.G.HAVOC_STOP then return end
        if not Hub.Get("AUTO_FILL",false) then return end
        local tool=Hub.lp.Character and Hub.lp.Character:FindFirstChildOfClass("Tool")
        if not tool then return end
        local data=tool:FindFirstChild("_data") if not data then return end
        local ammoC=data:FindFirstChild("ammoCurrent") local ammoS=data:FindFirstChild("ammoSize")
        if ammoC and ammoS and ammoC.Value~=ammoS.Value then ammoC.Value=ammoS.Value end
    end)

    Hub.On("shutdown",function() pcall(function() fovCirc:Remove() RunS:UnbindFromRenderStep("HubAim") end) end)
    Hub.RegisterModule("weapon",{Start=function() end})
    print("[Hub Weapon v6] loaded")
end)
