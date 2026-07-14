-- HAVOC HUB : World FX (Full Bright, Time, World Color)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    -- attendre que loot.lua ait cree le tab WORLD
    while not (Hub.UI.Tabs and Hub.UI.Tabs.world) do task.wait(0.05) end
    local UI=Hub.UI local Lighting=Hub.Lighting local RunS=Hub.RunS
    local cW="world"

    local savedAmb,savedFogB,savedOut,savedBright=nil,nil,nil,nil
    local savedFogStart,savedFogEnd,savedFogColor=nil,nil,nil
    local ccEffect local applying=false
    local Terrain=workspace:FindFirstChildOfClass("Terrain")
    local savedDeco=nil

    local function applyFullBright()
        if Hub.Get("FULLBRIGHT",false) then
            if not savedAmb then savedAmb=Lighting.Ambient savedOut=Lighting.OutdoorAmbient savedBright=Lighting.Brightness savedFogB=Lighting.GlobalShadows end
            Lighting.Ambient=Color3.new(1,1,1) Lighting.OutdoorAmbient=Color3.new(1,1,1) Lighting.GlobalShadows=false Lighting.Brightness=2
        else
            if savedAmb then Lighting.Ambient=savedAmb Lighting.OutdoorAmbient=savedOut Lighting.Brightness=savedBright Lighting.GlobalShadows=(savedFogB~=nil and savedFogB or true) savedAmb=nil end
        end
    end
    local function applyFog()
        if Hub.Get("NO_FOG",false) then
            if not savedFogStart then savedFogStart=Lighting.FogStart savedFogEnd=Lighting.FogEnd savedFogColor=Lighting.FogColor end
            Lighting.FogStart=1e9 Lighting.FogEnd=1e9
        else
            if savedFogStart then Lighting.FogStart=savedFogStart Lighting.FogEnd=savedFogEnd Lighting.FogColor=savedFogColor savedFogStart=nil savedFogEnd=nil savedFogColor=nil end
        end
    end
    local function applyGrass()
        if not Terrain then return end
        if Hub.Get("NO_GRASS",false) then
            if savedDeco==nil then savedDeco=Terrain.Decoration end
            Terrain.Decoration=false
        else
            if savedDeco~=nil then Terrain.Decoration=savedDeco savedDeco=nil end
        end
    end
    local function applyTime()
        if Hub.Get("TIME_ON",false) then Lighting.ClockTime=Hub.Get("TIME",14) end
        -- OFF: on ne touche pas ClockTime, le jeu garde son cycle
    end
    local function applyColor()
        if not ccEffect or not ccEffect.Parent then ccEffect=Instance.new("ColorCorrectionEffect") ccEffect.Name="HavocHub_CC" ccEffect.Parent=Lighting end
        ccEffect.TintColor=Hub.Get("WORLD_C",Color3.fromRGB(255,255,255))
    end
    local function applyWorld()
        if applying then return end applying=true
        applyFullBright() applyFog() applyGrass() applyTime() applyColor()
        applying=false
    end
    -- Property-change guards (re-enforce si Havoc override)
    for _,prop in ipairs({"Ambient","OutdoorAmbient","Brightness","GlobalShadows","FogStart","FogEnd","FogColor","ClockTime"}) do
        Lighting:GetPropertyChangedSignal(prop):Connect(function()
            if applying or Hub.G.HAVOC_STOP then return end
            applyWorld()
        end)
    end
    if Terrain then Terrain:GetPropertyChangedSignal("Decoration"):Connect(function() if not applying and Hub.Get("NO_GRASS",false) then applyGrass() end end) end

    local COLW=232 local LX,RX=0,COLW+8
    UI.Header(cW,0,130,COLW*2+8,"Environment",180)
    UI.Row(cW,LX+4,140,COLW-8,"Full Bright",function() return Hub.Get("FULLBRIGHT",false) end,function(v) Hub.Set("FULLBRIGHT",v) applyWorld() end)
    UI.Row(cW,RX+4,140,COLW-8,"World Color",function() return true end,function() end,function() return Hub.Get("WORLD_C",Color3.fromRGB(255,255,255)) end,function(c) Hub.Set("WORLD_C",c) applyColor() end)
    UI.Row(cW,LX+4,174,COLW-8,"No Fog",function() return Hub.Get("NO_FOG",false) end,function(v) Hub.Set("NO_FOG",v) applyFog() end)
    UI.Row(cW,RX+4,174,COLW-8,"No Grass",function() return Hub.Get("NO_GRASS",false) end,function(v) Hub.Set("NO_GRASS",v) applyGrass() end)
    UI.Row(cW,LX+4,208,COLW-8,"Custom Time",function() return Hub.Get("TIME_ON",false) end,function(v) Hub.Set("TIME_ON",v) applyTime() end)
    UI.Step(cW,0,242,COLW*2+8,"Time",function() return Hub.Get("TIME",14) end,function(v) Hub.Set("TIME",v) applyTime() end,1,0,24)

    -- Safety net: réapplique chaque Heartbeat pour battre Havoc en continu
    RunS.Heartbeat:Connect(function()
        if Hub.G.HAVOC_STOP then return end
        applyFog() applyGrass() if Hub.Get("TIME_ON",false) then applyTime() end
    end)

    -- ZOOM (hold key -> reduit FOV)
    UI.Header(cW,0,320,COLW*2+8,"Zoom",90)
    UI.Row(cW,LX+4,330,COLW-8,"Zoom Enabled","ZOOM_EN",false)
    local cam=Hub.cam
    local savedFOV=nil local zooming=false
    local function setZoom(on)
        if on and not zooming then savedFOV=cam.FieldOfView zooming=true Hub.G._ZOOM_ACTIVE=true cam.FieldOfView=Hub.Get("ZOOM_FOV",30)
        elseif not on and zooming then zooming=false Hub.G._ZOOM_ACTIVE=false if savedFOV then cam.FieldOfView=savedFOV savedFOV=nil end end
    end
    -- KeyBind callback = mode-aware (Hold par défaut, right-click sur touche pour changer)
    UI.KeyBind(cW,RX+4,330,COLW-8,"Zoom Key","ZOOM_KEY","C",function(state)
        if Hub.Get("ZOOM_EN",false) then setZoom(state) end
    end,"Hold")
    UI.Step(cW,0,364,COLW*2+8,"Zoom FOV","ZOOM_FOV",30,5,5,70)
    -- Live update FOV pendant zoom si stepper change
    RunS.RenderStepped:Connect(function()
        if zooming and not Hub.G.HAVOC_STOP then cam.FieldOfView=Hub.Get("ZOOM_FOV",30) end
    end)

    Hub.On("shutdown",function()
        if zooming and savedFOV then cam.FieldOfView=savedFOV end
        if ccEffect then pcall(function() ccEffect:Destroy() end) end
        if savedAmb then pcall(function() Lighting.Ambient=savedAmb Lighting.OutdoorAmbient=savedOut Lighting.Brightness=savedBright Lighting.GlobalShadows=true end) end
        if savedFogEnd then pcall(function() Lighting.FogStart=savedFogStart Lighting.FogEnd=savedFogEnd Lighting.FogColor=savedFogColor end) end
        if savedDeco~=nil and Terrain then pcall(function() Terrain.Decoration=savedDeco end) end
    end)
    Hub.RegisterModule("world",{Start=function() end})
    print("[Hub World] loaded (+ zoom)")
end)
