-- HAVOC HUB : Weapon v3 (silent aim + no recoil + no spread + no sway + aimbot + FOV circle)
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

    -- NO SWAY: reset humanoid.CameraOffset + Motor6D grip transforms en boucle
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

    -- Namecall hook: NO RECOIL + SILENT AIM + NO SPREAD (defensif, cache-only)
    Hub.AddNamecallHook(function(self,method,args)
        if method~="FireServer" then return end
        local ok,n=pcall(function() return self.Name end) if not ok then return end

        -- NO RECOIL: SetLookAngles reduit
        if Hub.Get("NO_RECOIL",false) and n=="SetLookAngles" then
            if type(args[1])=="number" and type(args[2])=="number" then
                args[1]=args[1]*0.05 args[2]=args[2]*0.05 return args
            end
            return
        end

        -- SILENT AIM + NO SPREAD: shoot remote (empty name, 3 args)
        if n=="" and #args==3 then
            local a1,a2,a3=args[1],args[2],args[3]
            if typeof(a1)~="Instance" then return end
            local okT=pcall(function() return a1:IsA("Tool") end) if not okT or not a1:IsA("Tool") then return end
            if typeof(a2)~="Vector3" or typeof(a3)~="Vector3" then return end

            -- SILENT AIM prioritaire (redirige vers ennemi cible)
            if Hub.Get("SILENT_AIM",false) then
                local head=cached.head local hpos=cached.pos
                if head and hpos then
                    local dir=hpos-a2
                    if dir.Magnitude>=0.1 then
                        local nd=dir.Unit
                        if nd.X==nd.X then args[3]=nd return args end
                    end
                end
            end

            -- NO SPREAD: force direction = look de la camera (annule le random spread)
            if Hub.Get("NO_SPREAD",false) then
                local ok2,camDir=pcall(function() return cam.CFrame.LookVector end)
                if ok2 and typeof(camDir)=="Vector3" and camDir.Magnitude>0.1 then
                    args[3]=camDir.Unit return args
                end
            end
        end
    end)

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
    print("[Hub Weapon v3] loaded")
end)
