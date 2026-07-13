-- HAVOC HUB : Weapon v5 (per-instance shoot hook + no recoil)
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

    -- Trouve les 2 remotes cibles (shoot + SetLookAngles)
    local shootRemote,recoilRemote
    task.spawn(function()
        while not shootRemote or not recoilRemote do
            pcall(function()
                local events=Hub.RS:FindFirstChild("Communication")
                events=events and events:FindFirstChild("Events")
                if events then
                    for _,c in ipairs(events:GetChildren()) do
                        if c:IsA("RemoteEvent") then
                            if c.Name=="" and not shootRemote then shootRemote=c end
                            if c.Name=="SetLookAngles" and not recoilRemote then recoilRemote=c end
                        end
                    end
                end
            end)
            if shootRemote and recoilRemote then break end
            task.wait(0.5)
        end
        if shootRemote then print("[Hub] shootRemote =",shootRemote:GetFullName()) end
        if recoilRemote then print("[Hub] recoilRemote =",recoilRemote:GetFullName()) end
    end)

    -- HOOK PAR INSTANCE (safe): ne touche QUE nos 2 remotes cibles, passthrough total pour le reste
    local mt=getrawmetatable(game)
    local oldNC=mt.__namecall
    setreadonly(mt,false)
    mt.__namecall=newcclosure(function(self,...)
        if Hub.G.HAVOC_STOP then return oldNC(self,...) end
        -- Fast path: si self n'est pas un de nos remotes cibles => passthrough IMMEDIAT
        if self~=shootRemote and self~=recoilRemote then return oldNC(self,...) end
        if getnamecallmethod()~="FireServer" then return oldNC(self,...) end

        -- NO RECOIL: reduit les angles envoyes
        if self==recoilRemote and Hub.Get("NO_RECOIL",false) then
            local a1,a2=select(1,...),select(2,...)
            if type(a1)=="number" and type(a2)=="number" then
                return oldNC(self,a1*0.05,a2*0.05,select(3,...))
            end
            return oldNC(self,...)
        end

        -- SILENT AIM: reecrit direction du tir
        if self==shootRemote then
            local a1,a2,a3=select(1,...),select(2,...),select(3,...)
            if typeof(a1)=="Instance" and typeof(a2)=="Vector3" and typeof(a3)=="Vector3" then
                if Hub.Get("SILENT_AIM",false) then
                    local head=cached.head local hpos=cached.pos
                    if head and hpos then
                        local dir=hpos-a2
                        if dir.Magnitude>=0.1 then
                            local nd=dir.Unit
                            if nd.X==nd.X then
                                return oldNC(self,a1,a2,nd,select(4,...))
                            end
                        end
                    end
                end
                if Hub.Get("NO_SPREAD",false) then
                    local ok,camDir=pcall(function() return cam.CFrame.LookVector end)
                    if ok and typeof(camDir)=="Vector3" and camDir.Magnitude>0.1 then
                        return oldNC(self,a1,a2,camDir.Unit,select(4,...))
                    end
                end
            end
            return oldNC(self,...)
        end

        return oldNC(self,...)
    end)
    setreadonly(mt,true)

    local cW=UI.AddTab("weapon","WEAPON") local COLW=232 local LX,RX=0,COLW+8
    UI.Row(cW,LX,0,COLW,"Aimbot (right click)",function() return Hub.Get("AIMBOT",false) end,function(v) Hub.Set("AIMBOT",v) end)
    UI.ToggleColor(cW,RX,0,COLW,"FOV Circle","FOV_CIRCLE",false,"FOV_C",Color3.new(1,1,1))
    UI.Row(cW,LX,34,COLW,"Silent Aim",function() return Hub.Get("SILENT_AIM",false) end,function(v) Hub.Set("SILENT_AIM",v) end)
    UI.Row(cW,RX,34,COLW,"No Recoil",function() return Hub.Get("NO_RECOIL",false) end,function(v) Hub.Set("NO_RECOIL",v) end)
    UI.Row(cW,LX,68,COLW,"No Spread",function() return Hub.Get("NO_SPREAD",false) end,function(v) Hub.Set("NO_SPREAD",v) end)
    UI.Row(cW,RX,68,COLW,"No Sway",function() return Hub.Get("NO_SWAY",false) end,function(v) Hub.Set("NO_SWAY",v) end)
    UI.Stepper(cW,0,102,COLW*2+8,"FOV Size (px)","FOV_SIZE",150,10,20,600)
    UI.Step(cW,0,138,COLW*2+8,"Aim Smooth x100",function() return math.floor(Hub.Get("AIM_SMOOTH",0.35)*100) end,function(v) Hub.Set("AIM_SMOOTH",v/100) end,5,5,100)

    Hub.On("shutdown",function() pcall(function() fovCirc:Remove() RunS:UnbindFromRenderStep("HubAim") end) end)
    Hub.RegisterModule("weapon",{Start=function() end})
    print("[Hub Weapon v5] loaded (per-instance hook)")
end)
