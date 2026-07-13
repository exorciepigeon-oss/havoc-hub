-- HAVOC HUB : Weapon v4 (NO namecall hook - safe for damage)
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

    local cW=UI.AddTab("weapon","WEAPON") local COLW=232 local LX,RX=0,COLW+8
    UI.Row(cW,LX,0,COLW,"Aimbot (right click)",function() return Hub.Get("AIMBOT",false) end,function(v) Hub.Set("AIMBOT",v) end)
    UI.ToggleColor(cW,RX,0,COLW,"FOV Circle","FOV_CIRCLE",false,"FOV_C",Color3.new(1,1,1))
    UI.Row(cW,LX,34,COLW,"No Sway",function() return Hub.Get("NO_SWAY",false) end,function(v) Hub.Set("NO_SWAY",v) end)
    UI.Stepper(cW,0,68,COLW*2+8,"FOV Size (px)","FOV_SIZE",150,10,20,600)
    UI.Step(cW,0,104,COLW*2+8,"Aim Smooth x100",function() return math.floor(Hub.Get("AIM_SMOOTH",0.35)*100) end,function(v) Hub.Set("AIM_SMOOTH",v/100) end,5,5,100)

    Hub.mk("TextLabel",{Size=UDim2.new(1,0,0,80),Position=UDim2.new(0,0,0,148),BackgroundTransparency=1,Text="Silent Aim / No Recoil / No Spread: retires temporairement (necessitaient un namecall hook global qui cassait les degats). Solution alternative sera integree via hookmetamethod par-instance dans une prochaine version.",TextColor3=Hub.Theme.TXT2,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},cW)

    Hub.On("shutdown",function() pcall(function() fovCirc:Remove() RunS:UnbindFromRenderStep("HubAim") end) end)
    Hub.RegisterModule("weapon",{Start=function() end})
    print("[Hub Weapon v4] loaded (no namecall hook)")
end)
