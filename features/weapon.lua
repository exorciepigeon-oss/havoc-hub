-- HAVOC HUB : Weapon (cached target, no re-entrancy)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local RunS=Hub.RunS local UIS=Hub.UIS local cam=Hub.cam

    local fovCirc=Drawing.new("Circle") fovCirc.Thickness=1 fovCirc.NumSides=48 fovCirc.Transparency=1 fovCirc.Visible=false fovCirc.Filled=false

    -- CACHE update HORS namecall (en RenderStepped)
    local cached={head=nil,pos=nil}
    local aiming=false

    UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false end end)

    pcall(function() RunS:UnbindFromRenderStep("HubAim") end)
    RunS:BindToRenderStep("HubAim",Enum.RenderPriority.Camera.Value+1,function()
        if Hub.G.HAVOC_STOP then cached.head=nil return end
        pcall(function()
            -- FOV circle
            if Hub.Get("FOV_CIRCLE",false) then local ctr=cam.ViewportSize/2 fovCirc.Position=Vector2.new(ctr.X,ctr.Y) fovCirc.Radius=Hub.Get("FOV_SIZE",150) fovCirc.Color=Hub.Get("FOV_C",Color3.new(1,1,1)) fovCirc.Visible=true else fovCirc.Visible=false end

            -- Compute + cache la target la plus proche du curseur (pour aimbot ET silent aim)
            local mouse=UIS:GetMouseLocation()
            local best,bd=nil,Hub.Get("FOV_SIZE",150)
            for _,info in pairs(Hub.Enemies()) do
                if info.hd and info.hd.Parent then
                    local sp=cam:WorldToViewportPoint(info.hd.Position)
                    if sp.Z>0 then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude if d<bd then bd=d best=info.hd end end
                end
            end
            if best and best.Parent then cached.head=best cached.pos=best.Position else cached.head=nil cached.pos=nil end

            -- Aimbot: bouge souris vers cache
            if Hub.Get("AIMBOT",false) and aiming and mousemoverel and cached.head then
                local sp=cam:WorldToViewportPoint(cached.pos)
                if sp.Z>0 then local ctr=cam.ViewportSize/2 local sm=Hub.Get("AIM_SMOOTH",0.35)
                    mousemoverel((sp.X-ctr.X)*sm,(sp.Y-ctr.Y)*sm) end
            end
        end)
    end)

    -- Hook __namecall : LIT le cache, ZERO method call
    Hub.AddNamecallHook(function(self,method,args)
        if method~="FireServer" then return end
        local name=rawget(getfenv(),"unused") -- placeholder
        local ok,n=pcall(function() return self.Name end) if not ok then return end
        -- NO RECOIL: reduit SetLookAngles
        if Hub.Get("NO_RECOIL",false) and n=="SetLookAngles" then
            if type(args[1])=="number" and type(args[2])=="number" then
                args[1]=args[1]*0.05 args[2]=args[2]*0.05 return args
            end
            return
        end
        -- SILENT AIM: shoot remote (empty name, 3 args)
        if Hub.Get("SILENT_AIM",false) and n=="" and #args==3 then
            local a1,a2,a3=args[1],args[2],args[3]
            if typeof(a1)~="Instance" then return end
            local okT=pcall(function() return a1:IsA("Tool") end) if not okT then return end
            if not a1:IsA("Tool") then return end
            if typeof(a2)~="Vector3" or typeof(a3)~="Vector3" then return end
            -- LIT le cache calcule dehors
            local head=cached.head local hpos=cached.pos
            if not head or not hpos then return end
            local dir=hpos-a2 if dir.Magnitude<0.1 then return end
            local newDir=dir.Unit
            if newDir.X~=newDir.X then return end
            args[3]=newDir return args
        end
    end)

    local cW=UI.AddTab("weapon","WEAPON") local COLW=232 local LX,RX=0,COLW+8
    UI.Row(cW,LX,0,COLW,"Aimbot (right click)",function() return Hub.Get("AIMBOT",false) end,function(v) Hub.Set("AIMBOT",v) end)
    UI.ToggleColor(cW,RX,0,COLW,"FOV Circle","FOV_CIRCLE",false,"FOV_C",Color3.new(1,1,1))
    UI.Row(cW,LX,34,COLW,"Silent Aim",function() return Hub.Get("SILENT_AIM",false) end,function(v) Hub.Set("SILENT_AIM",v) end)
    UI.Row(cW,RX,34,COLW,"No Recoil",function() return Hub.Get("NO_RECOIL",false) end,function(v) Hub.Set("NO_RECOIL",v) end)
    UI.Stepper(cW,0,68,COLW*2+8,"FOV Size (px)","FOV_SIZE",150,10,20,600)
    UI.Step(cW,0,104,COLW*2+8,"Aim Smooth x100",function() return math.floor(Hub.Get("AIM_SMOOTH",0.35)*100) end,function(v) Hub.Set("AIM_SMOOTH",v/100) end,5,5,100)

    Hub.On("shutdown",function() pcall(function() fovCirc:Remove() RunS:UnbindFromRenderStep("HubAim") end) end)
    Hub.RegisterModule("weapon",{Start=function() end})
    print("[Hub Weapon v2] loaded")
end)
