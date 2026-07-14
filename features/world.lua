-- HAVOC HUB : World FX (Full Bright, Time, World Color)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    -- attendre que loot.lua ait cree le tab WORLD
    while not (Hub.UI.Tabs and Hub.UI.Tabs.world) do task.wait(0.05) end
    local UI=Hub.UI local Lighting=Hub.Lighting local RunS=Hub.RunS
    local cW=Hub.UI.Tabs.world.c

    local savedAmb,savedFog,savedOut,savedBright=nil,nil,nil,nil
    local ccEffect local applying=false
    local function applyWorld()
        if applying then return end applying=true
        if Hub.Get("FULLBRIGHT",false) then
            if not savedAmb then savedAmb=Lighting.Ambient savedFog=Lighting.FogEnd savedOut=Lighting.OutdoorAmbient savedBright=Lighting.Brightness end
            Lighting.Ambient=Color3.new(1,1,1) Lighting.OutdoorAmbient=Color3.new(1,1,1) Lighting.FogEnd=1e6 Lighting.GlobalShadows=false Lighting.Brightness=2
        else
            if savedAmb then Lighting.Ambient=savedAmb Lighting.OutdoorAmbient=savedOut Lighting.FogEnd=savedFog Lighting.Brightness=savedBright Lighting.GlobalShadows=true savedAmb=nil end
        end
        Lighting.ClockTime=Hub.Get("TIME",14)
        if not ccEffect or not ccEffect.Parent then ccEffect=Instance.new("ColorCorrectionEffect") ccEffect.Name="HavocHub_CC" ccEffect.Parent=Lighting end
        ccEffect.TintColor=Hub.Get("WORLD_C",Color3.fromRGB(255,255,255))
        applying=false
    end
    for _,prop in ipairs({"ClockTime","Ambient","OutdoorAmbient","FogEnd","Brightness","GlobalShadows"}) do
        Lighting:GetPropertyChangedSignal(prop):Connect(function()
            if applying or Hub.G.HAVOC_STOP then return end
            if Hub.Get("FULLBRIGHT",false) or prop=="ClockTime" then applyWorld() end
        end)
    end

    local COLW=232 local LX,RX=0,COLW+8
    UI.Header(cW,0,130,COLW*2+8,"WORLD FX",90)
    UI.Row(cW,LX+4,140,COLW-8,"Full Bright",function() return Hub.Get("FULLBRIGHT",false) end,function(v) Hub.Set("FULLBRIGHT",v) applyWorld() end)
    UI.Row(cW,RX+4,140,COLW-8,"World Color",function() return true end,function() end,function() return Hub.Get("WORLD_C",Color3.fromRGB(255,255,255)) end,function(c) Hub.Set("WORLD_C",c) applyWorld() end)
    UI.Step(cW,0,174,COLW*2+8,"Time",function() return Hub.Get("TIME",14) end,function(v) Hub.Set("TIME",v) applyWorld() end,1,0,24)

    -- ZOOM (hold key -> reduit FOV)
    UI.Header(cW,0,220,COLW*2+8,"ZOOM",90)
    UI.Row(cW,LX+4,230,COLW-8,"Zoom Enabled","ZOOM_EN",false)
    UI.KeyBind(cW,RX+4,230,COLW-8,"Zoom Key","ZOOM_KEY","C")
    UI.Step(cW,0,264,COLW*2+8,"Zoom FOV","ZOOM_FOV",30,5,5,70)

    local cam=Hub.cam local UIS=Hub.UIS
    local savedFOV=nil local zooming=false
    local function setZoom(on)
        if on and not zooming then savedFOV=cam.FieldOfView zooming=true cam.FieldOfView=Hub.Get("ZOOM_FOV",30)
        elseif not on and zooming then zooming=false if savedFOV then cam.FieldOfView=savedFOV savedFOV=nil end end
    end
    local function keyMatches(input)
        local wanted=Hub.Get("ZOOM_KEY","C")
        if input.UserInputType==Enum.UserInputType.Keyboard then return input.KeyCode.Name==wanted end
        if input.UserInputType==Enum.UserInputType.MouseButton2 then return wanted=="MouseButton2" end
        if input.UserInputType==Enum.UserInputType.MouseButton3 then return wanted=="MouseButton3" end
        return false
    end
    UIS.InputBegan:Connect(function(i,gpe)
        if gpe or Hub.G.HAVOC_STOP then return end
        if Hub.Get("ZOOM_EN",false) and keyMatches(i) then setZoom(true) end
    end)
    UIS.InputEnded:Connect(function(i)
        if keyMatches(i) then setZoom(false) end
    end)
    -- Live update FOV pendant zoom si stepper change
    RunS.RenderStepped:Connect(function()
        if zooming and not Hub.G.HAVOC_STOP then cam.FieldOfView=Hub.Get("ZOOM_FOV",30) end
    end)

    Hub.On("shutdown",function()
        if zooming and savedFOV then cam.FieldOfView=savedFOV end
        if ccEffect then pcall(function() ccEffect:Destroy() end) end
        if savedAmb then pcall(function() Lighting.Ambient=savedAmb Lighting.OutdoorAmbient=savedOut Lighting.FogEnd=savedFog Lighting.Brightness=savedBright Lighting.GlobalShadows=true end) end
    end)
    Hub.RegisterModule("world",{Start=function() end})
    print("[Hub World] loaded (+ zoom)")
end)
