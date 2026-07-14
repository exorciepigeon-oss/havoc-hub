-- HAVOC HUB : Loot ESP + Mines
local Hub=_G.HavocHub if not Hub then return end
task.spawn(function()
    while not Hub.UI or not Hub.UI.AddTab do task.wait(0.05) end
    local UI=Hub.UI local T=Hub.Theme local RunS=Hub.RunS local cam=Hub.cam

    local LT,MH={},{}
    local function newTxt(sz) local t=Drawing.new("Text") t.Size=sz or 11 t.Center=true t.Outline=true t.Transparency=1 t.Visible=false return t end

    local weapKW={"rifle","pistol","gun","ak","m4","sr","glock","mp","sniper","shotgun","smg","carbine","launcher","grenade","c4"}
    local valKW={"gold","money","cash","rolex","diamond","key","valuable","jewel","watch","ruby","artifact","bitcoin"}
    local function lootCat(n) n=(n or ""):lower()
        for _,k in ipairs(weapKW) do if n:find(k) then return "w" end end
        for _,k in ipairs(valKW) do if n:find(k) then return "v" end end
        return "s" end
    local function loots() local out={} local ok,lr=pcall(function() return workspace.Buildings.Loots end)
        if not ok or not lr then return out end
        local o=Hub.MyPos() local maxD=Hub.Get("LOOT_DIST",500)
        for _,cat in ipairs(lr:GetChildren()) do pcall(function()
            for _,it in ipairs(cat:GetChildren()) do
                if it:IsA("Model") then local p=it.PrimaryPart or it:FindFirstChildWhichIsA("BasePart",true)
                    if p then local d=(p.Position-o).Magnitude
                        if d<=maxD then table.insert(out,{n=it.Name,pos=p.Position,dist=d,c=lootCat(it.Name)}) end end end
            end
        end) end return out end
    local function partOf(inst) if inst:IsA("BasePart") then return inst end if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart end return inst:FindFirstChildWhichIsA("BasePart",true) end
    local function mines() local out={} local o=Hub.MyPos() local maxD=Hub.Get("LOOT_DIST",500)
        pcall(function() local tm=workspace.Buildings.EnvInteractable.Mines.Tripmines for _,t in ipairs(tm:GetChildren()) do local p=partOf(t) if p then local d=(p.Position-o).Magnitude if d<=maxD then table.insert(out,{n="TRIPMINE",pos=p.Position,dist=d}) end end end end)
        pcall(function() local eb=workspace.Buildings.EventObjects.ExplosiveBarrels for _,b in ipairs(eb:GetChildren()) do local p=partOf(b) if p then local d=(p.Position-o).Magnitude if d<=maxD then table.insert(out,{n="BARREL",pos=p.Position,dist=d}) end end end end)
        pcall(function() local mf=workspace.Buildings.EventObjects.Minefields for _,p in ipairs(mf:GetChildren()) do local hb=p:FindFirstChild("MineHitbox") local t=hb or partOf(p) if t then local d=(t.Position-o).Magnitude if d<=maxD then table.insert(out,{n="MINEFIELD",pos=t.Position,dist=d}) end end end end)
        return out end

    -- UI tab
    local cW=UI.AddTab("world","WORLD") local COLW=232 local LX,RX=0,COLW+8
    UI.Header(cW,0,0,COLW*2+8,"LOOT ESP",120)
    UI.ToggleColor(cW,LX+4,10,COLW-8,"Weapons","LOOT_W",false,"LOOT_W_C",Color3.fromRGB(255,100,50))
    UI.ToggleColor(cW,RX+4,10,COLW-8,"Valuables","LOOT_V",false,"LOOT_V_C",Color3.fromRGB(255,215,0))
    UI.ToggleColor(cW,LX+4,44,COLW-8,"Simple Items","LOOT_S",false,"LOOT_S_C",Color3.fromRGB(120,200,255))
    UI.ToggleColor(cW,RX+4,44,COLW-8,"Mines / Barrels","MINE_ESP",false,"MINE_C",Color3.fromRGB(255,60,60))
    UI.Stepper(cW,0,78,COLW*2+8,"Loot Distance","LOOT_DIST",500,50,50,2000)

    RunS.RenderStepped:Connect(function()
        if Hub.G.HAVOC_STOP then return end
        pcall(function()
            for _,d in ipairs(LT) do d.Visible=false end
            local W,V,S=Hub.Get("LOOT_W",false),Hub.Get("LOOT_V",false),Hub.Get("LOOT_S",false)
            if W or V or S then local i=0
                for _,it in ipairs(loots()) do
                    local ok=(it.c=="w" and W) or (it.c=="v" and V) or (it.c=="s" and S)
                    if ok then i=i+1 if not LT[i] then LT[i]=newTxt(11) end
                        local sp=cam:WorldToViewportPoint(it.pos)
                        if sp.Z>0 then LT[i].Text=it.n.." ["..math.floor(it.dist).."m]" LT[i].Position=Vector2.new(sp.X,sp.Y)
                            LT[i].Color=(it.c=="w" and Hub.Get("LOOT_W_C",Color3.fromRGB(255,100,50)) or it.c=="v" and Hub.Get("LOOT_V_C",Color3.fromRGB(255,215,0)) or Hub.Get("LOOT_S_C",Color3.fromRGB(120,200,255)))
                            LT[i].Visible=true end
                    end
                end
            end
            for _,d in ipairs(MH) do d.Visible=false end
            if Hub.Get("MINE_ESP",false) then local i=0 for _,it in ipairs(mines()) do i=i+1 if not MH[i] then MH[i]=newTxt(12) end
                local sp=cam:WorldToViewportPoint(it.pos)
                if sp.Z>0 then MH[i].Text="⚠ "..it.n.." ["..math.floor(it.dist).."m]" MH[i].Position=Vector2.new(sp.X,sp.Y) MH[i].Color=Hub.Get("MINE_C",Color3.fromRGB(255,60,60)) MH[i].Visible=true end end end
        end)
    end)

    Hub.On("shutdown",function() for _,d in ipairs(LT) do pcall(function() d:Remove() end) end for _,d in ipairs(MH) do pcall(function() d:Remove() end) end end)
    Hub.RegisterModule("loot",{Start=function() end})
    print("[Hub Loot] loaded")
end)
