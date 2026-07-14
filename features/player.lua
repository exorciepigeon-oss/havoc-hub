-- HAVOC HUB : Player - Camera Noclip
local Hub=_G.HavocHub if not Hub then return end
-- Not persisted (movement toggle): stays off across reloads
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

    local fakePart=nil local savedSubject=nil local savedType=nil local controls=nil
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
        if fakePart then return end
        local c=getControls() if c then pcall(function() c:Disable() end) end
        savedSubject=cam.CameraSubject
        savedType=cam.CameraType
        fakePart=Instance.new("Part")
        fakePart.Anchored=true fakePart.CanCollide=false fakePart.Transparency=1
        fakePart.Size=Vector3.new(1,1,1) fakePart.CFrame=CFrame.new(cam.CFrame.Position)
        fakePart.Name="HavocHub_NoclipAnchor" fakePart.Parent=workspace
        cam.CameraSubject=fakePart
    end
    local function disableNoclip()
        if not fakePart then return end
        -- Restore CameraSubject en priorisant Humanoid vivant (savedSubject peut être stale si respawn)
        local char=lp.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        cam.CameraSubject=(hum and hum) or savedSubject
        cam.CameraType=savedType or Enum.CameraType.Custom
        -- Snap CFrame derrière la tête pour éviter cam-dans-tête
        local head=char and char:FindFirstChild("Head")
        if head then cam.CFrame=CFrame.new(head.Position-head.CFrame.LookVector*8+Vector3.new(0,2,0),head.Position) end
        savedSubject=nil savedType=nil
        pcall(function() fakePart:Destroy() end) fakePart=nil
        local c=getControls() if c then pcall(function() c:Enable() end) end
    end

    -- Sync state each frame + move fakePart via WASD/Space/Shift
    RunS.RenderStepped:Connect(function(dt)
        if Hub.G.HAVOC_STOP then if fakePart then disableNoclip() end return end
        local want=Hub.Get("CAM_NOCLIP",false)
        if want and not fakePart then enableNoclip()
        elseif not want and fakePart then disableNoclip() end
        if fakePart then
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
                fakePart.CFrame=fakePart.CFrame+mv.Unit*sp*dt
            end
        end
    end)

    -- Note: KeyBind Callback handles press events (mode-aware: Toggle/Hold/Always via right-click on picker)
    Hub.On("shutdown",function() disableNoclip() end)
    Hub.RegisterModule("player",{Start=function() end})
    print("[Hub Player] loaded (Cam Noclip)")
end)
