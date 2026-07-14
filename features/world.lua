-- HAVOC HUB : World FX (Full Bright, Time, World Color)
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    -- attendre que loot.lua ait cree le tab WORLD
    while not (Hub.UI.Tabs and Hub.UI.Tabs.world) do task.wait(0.05) end
    local UI=Hub.UI local Lighting=Hub.Lighting local RunS=Hub.RunS
    local cW="world"

    local savedAmb,savedGS,savedOut,savedBright=nil,nil,nil,nil
    local savedFogStart,savedFogEnd,savedFogColor=nil,nil,nil
    local savedClockTime=nil
    local ccEffect
    local Terrain=workspace:FindFirstChildOfClass("Terrain")
    local savedDeco=nil

    local function applyFullBright()
        if Hub.Get("FULLBRIGHT",false) then
            if not savedAmb then savedAmb=Lighting.Ambient savedOut=Lighting.OutdoorAmbient savedBright=Lighting.Brightness savedGS=Lighting.GlobalShadows end
            if Lighting.Ambient~=Color3.new(1,1,1) then Lighting.Ambient=Color3.new(1,1,1) end
            if Lighting.OutdoorAmbient~=Color3.new(1,1,1) then Lighting.OutdoorAmbient=Color3.new(1,1,1) end
            if Lighting.GlobalShadows then Lighting.GlobalShadows=false end
            if Lighting.Brightness~=2 then Lighting.Brightness=2 end
        else
            if savedAmb then Lighting.Ambient=savedAmb Lighting.OutdoorAmbient=savedOut Lighting.Brightness=savedBright Lighting.GlobalShadows=(savedGS~=nil and savedGS or true) savedAmb=nil savedOut=nil savedBright=nil savedGS=nil end
        end
    end
    local savedAtmoDensity,savedAtmoHaze,savedAtmoGlare=nil,nil,nil
    local function applyFog()
        local atmo=Lighting:FindFirstChildOfClass("Atmosphere")
        if Hub.Get("NO_FOG",false) then
            if not savedFogStart then savedFogStart=Lighting.FogStart savedFogEnd=Lighting.FogEnd savedFogColor=Lighting.FogColor end
            if Lighting.FogEnd<100000 then Lighting.FogEnd=100000 end
            if Lighting.FogStart<100000 then Lighting.FogStart=100000 end
            -- Atmosphere (postprocess moderne utilisé par Havoc)
            if atmo then
                if savedAtmoDensity==nil then savedAtmoDensity=atmo.Density savedAtmoHaze=atmo.Haze savedAtmoGlare=atmo.Glare end
                if atmo.Density~=0 then atmo.Density=0 end
                if atmo.Haze~=0 then atmo.Haze=0 end
                if atmo.Glare~=0 then atmo.Glare=0 end
            end
        else
            if savedFogStart then Lighting.FogStart=savedFogStart Lighting.FogEnd=savedFogEnd Lighting.FogColor=savedFogColor savedFogStart=nil savedFogEnd=nil savedFogColor=nil end
            if atmo and savedAtmoDensity~=nil then atmo.Density=savedAtmoDensity atmo.Haze=savedAtmoHaze atmo.Glare=savedAtmoGlare savedAtmoDensity=nil savedAtmoHaze=nil savedAtmoGlare=nil end
        end
    end
    local function applyGrass()
        if not Terrain then return end
        if Hub.Get("NO_GRASS",false) then
            pcall(function() if savedDeco==nil then savedDeco=Terrain.Decoration end Terrain.Decoration=false end)
            if sethiddenproperty then pcall(sethiddenproperty,Terrain,"Decoration",false) end
        else
            pcall(function() if savedDeco~=nil then Terrain.Decoration=savedDeco savedDeco=nil end end)
            if sethiddenproperty then pcall(sethiddenproperty,Terrain,"Decoration",true) end
        end
    end
    local function applyTime()
        if Hub.Get("TIME_ON",false) then
            if savedClockTime==nil then savedClockTime=Lighting.ClockTime end
            local target=Hub.Get("TIME",14)
            if math.abs(Lighting.ClockTime-target)>0.01 then Lighting.ClockTime=target end
        else
            -- OFF: restore le ClockTime que Havoc avait avant qu'on override (pas de cycle => nécessaire)
            if savedClockTime~=nil then Lighting.ClockTime=savedClockTime savedClockTime=nil end
        end
    end
    local function applyColor()
        if Hub.Get("COLOR_ON",false) then
            if not ccEffect or not ccEffect.Parent then ccEffect=Instance.new("ColorCorrectionEffect") ccEffect.Name="HavocHub_CC" ccEffect.Parent=Lighting end
            local target=Hub.Get("WORLD_C",Color3.fromRGB(255,255,255))
            if ccEffect.TintColor~=target then ccEffect.TintColor=target end
        else
            -- Reset tint puis destroy (au cas où qqch pointe encore dessus)
            if ccEffect then pcall(function() ccEffect.TintColor=Color3.new(1,1,1) ccEffect:Destroy() end) ccEffect=nil end
        end
    end

    local COLW=232 local LX,RX=0,COLW+8
    UI.Header(cW,0,130,COLW*2+8,"Environment",220)
    UI.Row(cW,LX+4,140,COLW-8,"Full Bright",function() return Hub.Get("FULLBRIGHT",false) end,function(v) Hub.Set("FULLBRIGHT",v) applyFullBright() end)
    UI.Row(cW,LX+4,174,COLW-8,"No Fog",function() return Hub.Get("NO_FOG",false) end,function(v) Hub.Set("NO_FOG",v) applyFog() end)
    UI.Row(cW,LX+4,208,COLW-8,"No Grass",function() return Hub.Get("NO_GRASS",false) end,function(v) Hub.Set("NO_GRASS",v) applyGrass() end)
    UI.Row(cW,LX+4,242,COLW-8,"Custom Time",function() return Hub.Get("TIME_ON",false) end,function(v) Hub.Set("TIME_ON",v) applyTime() end)
    UI.Step(cW,0,276,COLW*2+8,"Time",function() return Hub.Get("TIME",14) end,function(v) Hub.Set("TIME",v) applyTime() end,1,0,24)
    UI.Row(cW,LX+4,310,COLW-8,"Custom Color",function() return Hub.Get("COLOR_ON",false) end,function(v) Hub.Set("COLOR_ON",v) applyColor() end,function() return Hub.Get("WORLD_C",Color3.fromRGB(255,255,255)) end,function(c) Hub.Set("WORLD_C",c) applyColor() end)

    -- Safety net Heartbeat SEUL (pas de property signals -> pas de fight loops)
    RunS.Heartbeat:Connect(function()
        if Hub.G.HAVOC_STOP then return end
        applyFullBright() applyFog() applyGrass() applyTime() applyColor()
    end)

    -- ZOOM (hold key -> reduit FOV)
    UI.Header(cW,0,320,COLW*2+8,"Zoom",90)
    UI.Row(cW,LX+4,330,COLW-8,"Zoom Enabled","ZOOM_EN",false)
    -- Zoom = juste un flag; player.lua triple-hook FOV force la valeur ZOOM_FOV quand flag actif
    UI.KeyBind(cW,RX+4,330,COLW-8,"Zoom Key","ZOOM_KEY","C",function(state)
        if Hub.Get("ZOOM_EN",false) then Hub.G._ZOOM_ACTIVE=state
        else Hub.G._ZOOM_ACTIVE=false end
    end,"Hold")
    UI.Step(cW,0,364,COLW*2+8,"Zoom FOV","ZOOM_FOV",30,5,5,70)

    Hub.On("shutdown",function()
        Hub.G._ZOOM_ACTIVE=false
        if ccEffect then pcall(function() ccEffect:Destroy() end) ccEffect=nil end
        if savedAmb then pcall(function() Lighting.Ambient=savedAmb Lighting.OutdoorAmbient=savedOut Lighting.Brightness=savedBright Lighting.GlobalShadows=true end) end
        if savedFogEnd then pcall(function() Lighting.FogStart=savedFogStart Lighting.FogEnd=savedFogEnd Lighting.FogColor=savedFogColor end) end
        if savedDeco~=nil and Terrain then pcall(function() Terrain.Decoration=savedDeco end) end
    end)
    Hub.RegisterModule("world",{Start=function() end})
    print("[Hub World] loaded (+ zoom)")
end)
