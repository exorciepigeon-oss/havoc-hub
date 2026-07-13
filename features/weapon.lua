-- HAVOC HUB : Weapon (defensive)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local RunS=Hub.RunS local UIS=Hub.UIS local cam=Hub.cam

    local fovCirc=Drawing.new("Circle") fovCirc.Thickness=1 fovCirc.NumSides=48 fovCirc.Transparency=1 fovCirc.Visible=false fovCirc.Filled=false

    -- helper: find target head near cursor
    local function nearHead()
        local ok,mouse=pcall(function() return UIS:GetMouseLocation() end)
        if not ok then return nil end
        local best,bd=nil,Hub.Get("FOV_SIZE",150)
        for _,info in pairs(Hub.Enemies()) do
            local sp=cam:WorldToViewportPoint(info.hd.Position)
            if sp.Z>0 then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude if d<bd then bd=d best=info.hd end end
        end
        return best
    end

    -- SILENT AIM + NO RECOIL hooks (super defensifs)
    Hub.AddNamecallHook(function(self,method,args)
        if method~="FireServer" then return end
        local ok,name=pcall(function() return tostring(self.Name) end) if not ok then return end
        -- NO RECOIL: SetLookAngles reduit
        if Hub.Get("NO_RECOIL",false) and name=="SetLookAngles" then
            local a1=args[1] local a2=args[2]
            if type(a1)=="number" and type(a2)=="number" then
                args[1]=a1*0.05 args[2]=a2*0.05 return args
            end
            return
        end
        -- SILENT AIM: shoot remote signature
        if Hub.Get("SILENT_AIM",false) and name=="" and #args==3 then
            local a1,a2,a3=args[1],args[2],args[3]
            local sigOk=pcall(function() return typeof(a1)=="Instance" and a1:IsA("Tool") and typeof(a2)=="Vector3" and typeof(a3)=="Vector3" end)
            if not sigOk then return end
            if typeof(a1)~="Instance" or not a1:IsA("Tool") then return end
            if typeof(a2)~="Vector3" or typeof(a3)~="Vector3" then return end
            local head=nearHead() if not head or not head.Parent then return end
            local hpos=head.Position
            local dir=(hpos-a2) if dir.Magnitude<0.1 then return end
            local newDir=dir.Unit
            if newDir.X~=newDir.X then return end -- NaN check
            args[3]=newDir return args
        end
    end)

    -- Aimbot
    local aiming=false
    UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then aiming=false end end)
    pcall(function() RunS:UnbindFromRenderStep("HubAim") end)
    RunS:BindToRenderStep("HubAim",Enum.RenderPriority.Camera.Value+1,function()
        if Hub.G.HAVOC_STOP then return end
        pcall(function()
            if Hub.Get("FOV_CIRCLE",false) then local ctr=cam.ViewportSize/2 fovCirc.Position=Vector2.new(ctr.X,ctr.Y) fovCirc.Radius=Hub.Get("FOV_SIZE",150) fovCirc.Color=Hub.Get("FOV_C",Color3.new(1,1,1)) fovCirc.Visible=true else fovCirc.Visible=false end
            if not Hub.Get("AIMBOT",false) or not aiming or not mousemoverel then return end
            local head=nearHead() if not head then return end
            local sp=cam:WorldToViewportPoint(head.Position) if sp.Z<0 then return end
            local ctr=cam.ViewportSize/2 local sm=Hub.Get("AIM_SMOOTH",0.35)
            mousemoverel((sp.X-ctr.X)*sm,(sp.Y-ctr.Y)*sm)
        end)
    end)

    -- UI tab
    local cW=UI.AddTab("weapon","WEAPON") local COLW=232 local LX,RX=0,COLW+8
    UI.Row(cW,LX,0,COLW,"Aimbot (right click)",function() return Hub.Get("AIMBOT",false) end,function(v) Hub.Set("AIMBOT",v) end)
    UI.ToggleColor(cW,RX,0,COLW,"FOV Circle","FOV_CIRCLE",false,"FOV_C",Color3.new(1,1,1))
    UI.Row(cW,LX,34,COLW,"Silent Aim",function() return Hub.Get("SILENT_AIM",false) end,function(v) Hub.Set("SILENT_AIM",v) end)
    UI.Row(cW,RX,34,COLW,"No Recoil",function() return Hub.Get("NO_RECOIL",false) end,function(v) Hub.Set("NO_RECOIL",v) end)
    UI.Stepper(cW,0,68,COLW*2+8,"FOV Size (px)","FOV_SIZE",150,10,20,600)
    UI.Step(cW,0,104,COLW*2+8,"Aim Smooth x100",function() return math.floor(Hub.Get("AIM_SMOOTH",0.35)*100) end,function(v) Hub.Set("AIM_SMOOTH",v/100) end,5,5,100)

    Hub.On("shutdown",function() pcall(function() fovCirc:Remove() RunS:UnbindFromRenderStep("HubAim") end) end)
    Hub.RegisterModule("weapon",{Start=function() end})
    print("[Hub Weapon] loaded")
end)
