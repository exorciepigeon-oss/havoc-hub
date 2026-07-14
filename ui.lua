-- HAVOC HUB UI v2 : sidebar icons + sharp corners + purple accent (compat API)
local Hub=_G.HavocHub if not Hub then warn("[UI] core not loaded") return end
local T=Hub.Theme local mk=Hub.mk
local UIS=Hub.UIS local Tween=Hub.Tween

-- Override theme: noir absolu + violet
T.BG0=Color3.fromRGB(0,0,0)
T.BG1=Color3.fromRGB(15,15,15)
T.BG2=Color3.fromRGB(22,22,22)
T.BG3=Color3.fromRGB(30,30,30)
T.ACC=Color3.fromRGB(170,60,220)
T.ACC2=Color3.fromRGB(220,80,255)
T.TXT=Color3.fromRGB(230,230,230)
T.TXT2=Color3.fromRGB(120,120,120)
T.LINE=Color3.fromRGB(40,20,50)
T.HP_LOW=Color3.fromRGB(255,0,0)

if Hub.UI and Hub.UI.Gui then pcall(function() Hub.UI.Gui:Destroy() end) end
Hub.UI={}
local UI=Hub.UI

UI.Gui=mk("ScreenGui",{Name="HavocHub",ResetOnSpawn=false},game:GetService("CoreGui"))

local function drag(h,tgt) local on,st,sp=false,nil,nil
    h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=true st=i.Position sp=tgt.Position end end)
    UIS.InputChanged:Connect(function(i) if on and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-st tgt.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=false end end)
end

-- RGB animated accents (top bar + picker top strip)
local RunS=game:GetService("RunService")
local rgbTargets={}
RunS.RenderStepped:Connect(function()
    if Hub.G and Hub.G.HAVOC_STOP then return end
    local hueNow=(tick()*0.35)%1
    local col=Color3.fromHSV(hueNow,1,1)
    for i=#rgbTargets,1,-1 do local f=rgbTargets[i]
        if f.Parent then f.BackgroundColor3=col else table.remove(rgbTargets,i) end
    end
end)

-- Color picker (angular)
local pk=mk("Frame",{Size=UDim2.new(0,240,0,230),Position=UDim2.new(0.5,-120,0.5,-115),BackgroundColor3=T.BG1,BorderSizePixel=0,Visible=false,ZIndex=30},UI.Gui)
local pkTop=mk("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=T.ACC,BorderSizePixel=0,ZIndex=31},pk)
table.insert(rgbTargets,pkTop)
local pkT=mk("TextLabel",{Size=UDim2.new(1,-30,0,26),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,Text="COLOR",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=31},pk)
local pkX=mk("TextButton",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-26,0,6),BackgroundColor3=T.BG2,Text="X",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=11,ZIndex=31,BorderSizePixel=0},pk)
local sv=mk("Frame",{Size=UDim2.new(0,160,0,130),Position=UDim2.new(0,12,0,40),BackgroundColor3=Color3.fromRGB(255,0,0),BorderSizePixel=0,ZIndex=31},pk)
local wo=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=31},sv)
mk("UIGradient",{Rotation=0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})},wo)
local bo=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=31},sv)
mk("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})},bo)
local svSel=mk("Frame",{Size=UDim2.new(0,8,0,8),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=32,Stroke=Color3.new(0,0,0)},sv)
local hue=mk("Frame",{Size=UDim2.new(0,20,0,130),Position=UDim2.new(0,180,0,40),BorderSizePixel=0,ZIndex=31},pk)
mk("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(0.33,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(0.83,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))})},hue)
local hueSel=mk("Frame",{Size=UDim2.new(1,4,0,3),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=32,Stroke=Color3.new(0,0,0)},hue)
mk("TextLabel",{Size=UDim2.new(0,50,0,14),Position=UDim2.new(0,12,0,178),BackgroundTransparency=1,Text="ALPHA",TextColor3=T.TXT2,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=31},pk)
local alphaBar=mk("Frame",{Size=UDim2.new(0,188,0,10),Position=UDim2.new(0,12,0,194),BackgroundColor3=T.BG3,BorderSizePixel=0,ZIndex=31},pk)
local alphaFill=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=T.ACC,BorderSizePixel=0,ZIndex=32},alphaBar)
local prv=mk("Frame",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(0,206,0,188),BorderSizePixel=0,ZIndex=31,Stroke=T.ACC},pk)

local cH,cS,cV,cA,setter,setterA=0,1,1,1,nil,nil
local function pkUp() sv.BackgroundColor3=Color3.fromHSV(cH,1,1) local col=Color3.fromHSV(cH,cS,cV)
    prv.BackgroundColor3=col svSel.Position=UDim2.new(cS,0,1-cV,0) hueSel.Position=UDim2.new(0.5,0,cH,0) alphaFill.Size=UDim2.new(cA,0,1,0)
    if setter then setter(col) end if setterA then setterA(cA) end end
local dS,dH,dA=false,false,false
sv.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dS=true local a,z=sv.AbsolutePosition,sv.AbsoluteSize cS=math.clamp((i.Position.X-a.X)/z.X,0,1) cV=1-math.clamp((i.Position.Y-a.Y)/z.Y,0,1) pkUp() end end)
hue.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dH=true local a,z=hue.AbsolutePosition,hue.AbsoluteSize cH=math.clamp((i.Position.Y-a.Y)/z.Y,0,1) pkUp() end end)
alphaBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dA=true local a,z=alphaBar.AbsolutePosition,alphaBar.AbsoluteSize cA=math.clamp((i.Position.X-a.X)/z.X,0,1) pkUp() end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then
    if dS then local a,z=sv.AbsolutePosition,sv.AbsoluteSize cS=math.clamp((i.Position.X-a.X)/z.X,0,1) cV=1-math.clamp((i.Position.Y-a.Y)/z.Y,0,1) pkUp()
    elseif dH then local a,z=hue.AbsolutePosition,hue.AbsoluteSize cH=math.clamp((i.Position.Y-a.Y)/z.Y,0,1) pkUp()
    elseif dA then local a,z=alphaBar.AbsolutePosition,alphaBar.AbsoluteSize cA=math.clamp((i.Position.X-a.X)/z.X,0,1) pkUp() end end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dS=false dH=false dA=false end end)
pkX.MouseButton1Click:Connect(function() pk.Visible=false setter=nil setterA=nil end)
function UI.OpenPicker(label,getC,setC,getA,setA)
    pkT.Text=(label or "COLOR"):upper() local h,s,v=Color3.toHSV(getC()) cH,cS,cV=h,s,v cA=getA and getA() or 1 setter=setC setterA=setA
    pk.Visible=true pkUp()
end

-- Main window (sized to content)
local WIN_W,WIN_H=540,360
UI.Root=mk("Frame",{Size=UDim2.new(0,WIN_W,0,WIN_H),Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),BackgroundColor3=T.BG0,BorderSizePixel=0},UI.Gui)

-- Top RGB accent (animated)
local rainbowLine=mk("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=T.ACC,BorderSizePixel=0},UI.Root)
table.insert(rgbTargets,rainbowLine)

-- Header
local hdr=mk("Frame",{Size=UDim2.new(1,0,0,38),Position=UDim2.new(0,0,0,2),BackgroundColor3=T.BG1,BorderSizePixel=0},UI.Root)
mk("TextLabel",{Size=UDim2.new(0,200,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1,Text="HAVOC HUB",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},hdr)
mk("TextLabel",{Size=UDim2.new(0,100,1,0),Position=UDim2.new(0,110,0,0),BackgroundTransparency=1,Text=Hub.Version,TextColor3=T.TXT2,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},hdr)
drag(hdr,UI.Root)

local closeB=mk("TextButton",{Size=UDim2.new(0,32,0,24),Position=UDim2.new(1,-38,0.5,-12),BackgroundColor3=T.BG2,Text="X",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0},hdr)
local minB=mk("TextButton",{Size=UDim2.new(0,32,0,24),Position=UDim2.new(1,-74,0.5,-12),BackgroundColor3=T.BG2,Text="_",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0},hdr)
local reo=mk("TextButton",{Size=UDim2.new(0,52,0,52),Position=UDim2.new(0,20,0,20),BackgroundColor3=T.BG1,Text="H",TextColor3=T.ACC,Font=Enum.Font.GothamBold,TextSize=22,Visible=false,BorderSizePixel=0,Stroke=T.ACC},UI.Gui)
drag(reo,reo)
minB.MouseButton1Click:Connect(function() UI.Root.Visible=false reo.Visible=true end)
reo.MouseButton1Click:Connect(function() UI.Root.Visible=true reo.Visible=false end)
closeB.MouseButton1Click:Connect(function() Hub.G.HAVOC_STOP=true Hub.Emit("shutdown") UI.Gui:Destroy() end)

-- Sidebar (icons)
local SIDE_W=52
UI.Sidebar=mk("Frame",{Size=UDim2.new(0,SIDE_W,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=T.BG1,BorderSizePixel=0},UI.Root)
mk("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BackgroundColor3=T.LINE,BorderSizePixel=0},UI.Sidebar)

UI.Host=mk("Frame",{Size=UDim2.new(1,-SIDE_W,1,-40),Position=UDim2.new(0,SIDE_W,0,40),BackgroundColor3=T.BG0,BorderSizePixel=0,ClipsDescendants=true},UI.Root)

UI.Tabs={} UI.TabY=12
UI.CurrentTab=nil

-- Icones auto par nom de tab (fallback texte si asset absent)
local iconMap={esp="◉",world="◈",weapon="▲",player="P",misc="M",inventory="i",config="*"}
-- Icons map: si l'asset PNG est downloade par le loader, on l'utilise (ImageLabel)
local Icons=getgenv().HAVOC_ICONS or {}
-- Loot.lua cree le tab "world", donc on partage l'icone
Icons.loot=Icons.world
Icons.inventory=Icons.inventory or Icons.misc
Icons.player=Icons.player or Icons.misc

function UI.ShowTab(n) for k,tt in pairs(UI.Tabs) do local a=(k==n) tt.c.Visible=a
    if a then tt.b.BackgroundColor3=T.BG3 tt.line.Visible=true
        if tt.isImage then tt.icon.ImageColor3=T.ACC else tt.icon.TextColor3=T.ACC end
        UI.CurrentTab=n
        tt.c.Position=UDim2.new(0,-30,0,0)
        Tween:Create(tt.c,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
    else tt.b.BackgroundColor3=T.BG1 tt.line.Visible=false
        if tt.isImage then tt.icon.ImageColor3=T.TXT2 else tt.icon.TextColor3=T.TXT2 end
    end
end end

function UI.AddTab(name,label,customIcon)
    local c=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},UI.Host)
    local b=mk("TextButton",{Size=UDim2.new(1,-4,0,44),Position=UDim2.new(0,2,0,UI.TabY),BackgroundColor3=T.BG1,Text="",BorderSizePixel=0,AutoButtonColor=false},UI.Sidebar)
    local line=mk("Frame",{Size=UDim2.new(0,2,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=T.ACC,BorderSizePixel=0,Visible=false},b)
    local iconLbl
    local iconAsset=Icons[name]
    if iconAsset then
        -- ImageLabel avec tint (violet quand actif, gris quand inactif)
        iconLbl=mk("ImageLabel",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(0.5,-12,0.5,-12),BackgroundTransparency=1,Image=iconAsset,ImageColor3=T.TXT2,ScaleType=Enum.ScaleType.Fit,BorderSizePixel=0},b)
    else
        local ico=customIcon or iconMap[name] or "?"
        iconLbl=mk("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=ico,TextColor3=T.TXT2,Font=Enum.Font.GothamBold,TextSize=18},b)
    end
    UI.Tabs[name]={b=b,c=c,line=line,icon=iconLbl,label=label,isImage=iconAsset~=nil}
    b.MouseButton1Click:Connect(function() UI.ShowTab(name) end)
    UI.TabY=UI.TabY+48
    if not UI.CurrentTab then UI.ShowTab(name) end
    return c
end

-- === API compat avec ancienne signature (par, x, y, w, ...) ===

-- Header = titre centré + auto-rectangle gris (compat: features passent x/y/w)
-- Height rectangle deduit du prochain call ou default 200; feature peut passer h en 6e arg
function UI.Header(par,x,y,w,txt,h)
    h=h or 34 -- default: juste ligne titre (compat ancienne API)
    if h>34 then
        -- Rectangle gris fin autour de la sous-categorie
        local box=mk("Frame",{Size=UDim2.new(0,w,0,h),Position=UDim2.new(0,x+8,0,y+8),BackgroundTransparency=1,BorderSizePixel=0},par)
        local stroke=Instance.new("UIStroke") stroke.Color=T.LINE stroke.Thickness=1 stroke.Parent=box
        -- Titre encoche sur bord haut (fond noir pour breakout du stroke)
        local lbg=mk("Frame",{Size=UDim2.new(0,#txt*6+16,0,12),Position=UDim2.new(0,12,0,-6),BackgroundColor3=T.BG0,BorderSizePixel=0,ZIndex=3},box)
        mk("TextLabel",{Size=UDim2.new(1,-4,1,0),Position=UDim2.new(0,2,0,-1),BackgroundTransparency=1,Text=txt:upper(),TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=4},lbg)
    else
        -- Compat: juste titre centré sans underline
        mk("TextLabel",{Size=UDim2.new(0,w,0,14),Position=UDim2.new(0,x+8,0,y+4),BackgroundTransparency=1,Text=txt:upper(),TextColor3=T.TXT2,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},par)
    end
end

-- UI.Group : creer un container borde avec titre au-dessus (comme ta ref)
-- Usage: local group=UI.Group(par,x,y,w,h,"GUN MODS") puis ajouter rows dans group
function UI.Group(par,x,y,w,h,title)
    local g=mk("Frame",{Size=UDim2.new(0,w,0,h),Position=UDim2.new(0,x+8,0,y+16),BackgroundColor3=T.BG1,BorderSizePixel=0},par)
    local stroke=Instance.new("UIStroke") stroke.Color=T.LINE stroke.Thickness=1 stroke.Parent=g
    -- Titre encoche sur bord (fond BG0 pour breakout)
    if title then
        local lbg=mk("Frame",{Size=UDim2.new(0,#title*6+18,0,12),Position=UDim2.new(0,14,0,-6),BackgroundColor3=T.BG0,BorderSizePixel=0,ZIndex=3},g)
        mk("TextLabel",{Size=UDim2.new(1,-4,1,0),Position=UDim2.new(0,2,0,-1),BackgroundTransparency=1,Text=title:upper(),TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=4},lbg)
    end
    return g
end

function UI.Row(par,x,y,w,label,gT,sT,gC,sC,gA,sA)
    -- String-key detection: gT="KEY", sT=default -> auto Hub.Get/Set
    if type(gT)=="string" then local key=gT local default=sT
        gT=function() return Hub.Get(key,default) end
        sT=function(v) Hub.Set(key,v) end
    end
    local r=mk("Frame",{Size=UDim2.new(0,w,0,24),Position=UDim2.new(0,x+8,0,y+8),BackgroundTransparency=1},par)
    -- checkbox with neon glow when active
    local box=mk("TextButton",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,4,0.5,-7),BackgroundColor3=T.BG3,BorderSizePixel=0,Text="",AutoButtonColor=false},r)
    local stroke=Instance.new("UIStroke") stroke.Color=T.LINE stroke.Thickness=1 stroke.Parent=box
    local fill=mk("Frame",{Size=UDim2.new(1,-4,1,-4),Position=UDim2.new(0,2,0,2),BackgroundColor3=T.ACC,BorderSizePixel=0,Visible=false},box)
    local glow=Instance.new("UIStroke") glow.Color=T.ACC2 glow.Thickness=2 glow.Transparency=0.3 glow.Enabled=false glow.Parent=box
    mk("TextLabel",{Size=UDim2.new(1,-64,1,0),Position=UDim2.new(0,26,0,0),BackgroundTransparency=1,Text=label,TextColor3=T.TXT,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},r)
    local function paint() local on=gT() fill.Visible=on glow.Enabled=on stroke.Color=on and T.ACC or T.LINE end paint()
    box.MouseButton1Click:Connect(function() sT(not gT()) paint() end)
    if gC then
        local sw=mk("TextButton",{Size=UDim2.new(0,30,0,14),Position=UDim2.new(1,-38,0.5,-7),BackgroundColor3=gC(),Text="",BorderSizePixel=0,Stroke=T.LINE},r)
        sw.MouseButton1Click:Connect(function() UI.OpenPicker(label,gC,function(c) sC(c) sw.BackgroundColor3=c end,gA,sA) end)
    end
end

function UI.Stepper(par,x,y,w,label,gV,sV,st,mn,mx,fmt)
    -- Compat: si gV est un string, c'est une key (auto wrap avec Hub.Get/Set)
    if type(gV)=="string" then local key=gV local default=sV
        gV=function() return Hub.Get(key,default) end
        sV=function(v) Hub.Set(key,v) end
    end
    local r=mk("Frame",{Size=UDim2.new(0,w,0,24),Position=UDim2.new(0,x+8,0,y+8),BackgroundTransparency=1},par)
    local lb=mk("TextLabel",{Size=UDim2.new(1,-52,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TXT,TextXAlignment=Enum.TextXAlignment.Left},r)
    local function rf() lb.Text=label.."   "..(fmt and fmt(gV()) or tostring(gV())) end rf()
    mk("TextButton",{Size=UDim2.new(0,20,0,16),Position=UDim2.new(1,-46,0.5,-8),BackgroundColor3=T.BG3,Text="-",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0},r).MouseButton1Click:Connect(function() sV(math.max(mn,gV()-st)) rf() end)
    mk("TextButton",{Size=UDim2.new(0,20,0,16),Position=UDim2.new(1,-22,0.5,-8),BackgroundColor3=T.BG3,Text="+",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0},r).MouseButton1Click:Connect(function() sV(math.min(mx,gV()+st)) rf() end)
end

function UI.Step(par,x,y,w,label,gV,sV,st,mn,mx,fmt) UI.Stepper(par,x,y,w,label,gV,sV,st,mn,mx,fmt) end

-- KeyBind: click button, presses next key = bind. Supports keyboard + mouse buttons.
function UI.KeyBind(par,x,y,w,label,getKey,setKey)
    if type(getKey)=="string" then local key=getKey local default=setKey
        getKey=function() return Hub.Get(key,default) end
        setKey=function(v) Hub.Set(key,v) end
    end
    local r=mk("Frame",{Size=UDim2.new(0,w,0,24),Position=UDim2.new(0,x+8,0,y+8),BackgroundTransparency=1},par)
    mk("TextLabel",{Size=UDim2.new(1,-96,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,Text=label,TextColor3=T.TXT,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},r)
    local b=mk("TextButton",{Size=UDim2.new(0,88,0,18),Position=UDim2.new(1,-92,0.5,-9),BackgroundColor3=T.BG3,BorderSizePixel=0,Text=tostring(getKey()),TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=10,Stroke=T.LINE},r)
    local waiting=false
    b.MouseButton1Click:Connect(function()
        if waiting then return end waiting=true b.Text="[press key]"
        local conn conn=UIS.InputBegan:Connect(function(i,gpe)
            if gpe then return end
            local name=nil
            if i.UserInputType==Enum.UserInputType.Keyboard then name=i.KeyCode.Name
            elseif i.UserInputType==Enum.UserInputType.MouseButton2 then name="MouseButton2"
            elseif i.UserInputType==Enum.UserInputType.MouseButton3 then name="MouseButton3" end
            if name then setKey(name) b.Text=name waiting=false conn:Disconnect() end
        end)
    end)
end
function UI.Toggle(par,x,y,w,label,gT,sT) UI.Row(par,x,y,w,label,gT,sT) end
function UI.ToggleColor(par,x,y,w,label,keyT,defT,keyC,defC,keyA,defA)
    UI.Row(par,x,y,w,label,function() return Hub.Get(keyT,defT) end,function(v) Hub.Set(keyT,v) end,
        function() return Hub.Get(keyC,defC) end,function(c) Hub.Set(keyC,c) end,
        keyA and function() return Hub.Get(keyA,defA or 1) end or nil,
        keyA and function(a) Hub.Set(keyA,a) end or nil)
end

-- Config tab (loaded delayed after all features)
task.spawn(function()
    task.wait(1.5)
    local cfg=UI.AddTab("config","Config","*")
    UI.Header(cfg,0,0,340,"CONFIGURATION")
    UI.Row(cfg,0,36,340,"Reset all saved settings",function() return false end,function()
        for k,_ in pairs(Hub.Config) do Hub.Config[k]=nil end
        if writefile then pcall(function() writefile(Hub.CFG_FILE,"{}") end) end
        print("[Hub] Config reset - relaunch to apply")
    end)
    mk("TextLabel",{Size=UDim2.new(0,600,0,120),Position=UDim2.new(0,16,0,80),BackgroundTransparency=1,Text="Havoc Hub "..Hub.Version.."\n\nModular hub with auto-saved config.\nCombat toggles never persist (safety).\nModify features via GitHub, reload in Volt.",TextColor3=T.TXT2,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true},cfg)
end)

Hub.Emit("ui_ready")
print("[Hub UI v2] loaded (dark purple)")
