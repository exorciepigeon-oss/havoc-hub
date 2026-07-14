-- HAVOC HUB : Player - Camera Noclip (CFrame override, sans toucher CameraSubject)
local Hub=_G.HavocHub if not Hub then return end
Hub.UnsafeKeys.CAM_NOCLIP=true

task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local RunS=Hub.RunS local UIS=Hub.UIS local cam=Hub.cam local lp=Hub.lp

    local cP=UI.AddTab("player","Player")
    local COLW=232 local LX,RX=0,COLW+8
    UI.Header(cP,LX,0,COLW,"Camera Noclip",100)
    UI.Row(cP,LX+4,10,COLW-8,"Camera Noclip","CAM_NOCLIP",false)
    UI.KeyBind(cP,LX+4,44,COLW-8,"Toggle Key","CAM_NOCLIP_KEY","V",function(state) Hub.Set("CAM_NOCLIP",state) end,"Toggle")
    UI.Stepper(cP,LX+4,78,COLW-8,"Cam Speed","CAM_NOCLIP_SPEED",50,5,5,200)

    local noclipPos=nil local controls=nil
    local function getControls()
        if controls then return controls end
        local ok,mod=pcall(function()
            local pm=lp:WaitForChild("PlayerScripts",5) and lp.PlayerScripts:WaitForChild("PlayerModule",5)
            return require(pm):GetControls()
        end)
        if ok then controls=mod end
        return controls
    end
    local function enableNoclip()
        if noclipPos then return end
        noclipPos=cam.CFrame.Position
        local c=getControls() if c then pcall(function() c:Disable() end) end
    end
    local function disableNoclip()
        if not noclipPos then return end
        noclipPos=nil
        local c=getControls() if c then pcall(function() c:Enable() end) end
        -- Rien à toucher côté cam: Havoc reprend la main dès que on n'override plus
    end

    -- Sync state
    RunS.Heartbeat:Connect(function()
        if Hub.G.HAVOC_STOP then if noclipPos then disableNoclip() end return end
        local want=Hub.Get("CAM_NOCLIP",false)
        if want and not noclipPos then enableNoclip()
        elseif not want and noclipPos then disableNoclip() end
    end)

    -- Override CFrame APRÈS le camera controller de Havoc (Camera=200 → nous=201)
    RunS:BindToRenderStep("HavocNoclipCam",Enum.RenderPriority.Camera.Value+1,function(dt)
        if not noclipPos or Hub.G.HAVOC_STOP then return end
        local mv=Vector3.zero
        local look=cam.CFrame.LookVector local right=cam.CFrame.RightVector
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+look end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-look end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-right end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+right end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv=mv-Vector3.new(0,1,0) end
        if mv.Magnitude>0.01 then
            local sp=Hub.Get("CAM_NOCLIP_SPEED",50)
            noclipPos=noclipPos+mv.Unit*sp*dt
        end
        -- Overwrite cam position, preserve rotation set par Havoc controller
        cam.CFrame=cam.CFrame-cam.CFrame.Position+noclipPos
    end)

    Hub.On("shutdown",function()
        disableNoclip()
        pcall(function() RunS:UnbindFromRenderStep("HavocNoclipCam") end)
    end)
    Hub.RegisterModule("player",{Start=function() end})
    print("[Hub Player] loaded (Cam Noclip via CFrame override)")
end)
