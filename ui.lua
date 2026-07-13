-- HAVOC HUB UI
local Hub=_G.HavocHub if not Hub then warn("[UI] core not loaded") return end
local T=Hub.Theme local mk=Hub.mk
local UIS=Hub.UIS local Tween=Hub.Tween

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

-- Color picker with alpha
local pk=mk("Frame",{Size=UDim2.new(0,230,0,220),Position=UDim2.new(0.5,-115,0.5,-110),BackgroundColor3=T.BG1,BorderSizePixel=0,Visible=false,ZIndex=30,Corner=10,Stroke=Color3.fromRGB(50,50,50)},UI.Gui)
local pkT=mk("TextLabel",{Size=UDim2.new(1,-30,0,26),Position=UDim2.new(0,12,0,4),BackgroundTransparency=1,Text="Color",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=31},pk)
local pkX=mk("TextButton",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-26,0,6),BackgroundColor3=T.BG2,Text="X",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=10,ZIndex=31,Corner=4},pk)
local sv=mk("Frame",{Size=UDim2.new(0,150,0,120),Position=UDim2.new(0,12,0,36),BackgroundColor3=Color3.fromRGB(255,0,0),BorderSizePixel=0,ZIndex=31,Corner=6},pk)
local wo=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=31,Corner=6},sv)
mk("UIGradient",{Rotation=0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})},wo)
local bo=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=31,Corner=6},sv)
mk("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})},bo)
local svSel=mk("Frame",{Size=UDim2.new(0,10,0,10),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=32,Round=true,Stroke=Color3.new(0,0,0)},sv)
local hue=mk("Frame",{Size=UDim2.new(0,20,0,120),Position=UDim2.new(0,172,0,36),BorderSizePixel=0,ZIndex=31,Corner=6},pk)
mk("UIGradient",{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(0.33,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(0.83,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))})},hue)
local hueSel=mk("Frame",{Size=UDim2.new(1,4,0,4),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0,0),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=32,Stroke=Color3.new(0,0,0)},hue)
mk("TextLabel",{Size=UDim2.new(0,50,0,14),Position=UDim2.new(0,12,0,158),BackgroundTransparency=1,Text="Alpha",TextColor3=T.TXT2,Font=Enum.Font.Gotham,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=31},pk)
local alphaBar=mk("Frame",{Size=UDim2.new(0,180,0,10),Position=UDim2.new(0,12,0,174),BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0,ZIndex=31,Corner=5},pk)
local alphaFill=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=32,Corner=5},alphaBar)
local prv=mk("Frame",{Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,200,0,169),BorderSizePixel=0,ZIndex=31,Corner=4},pk)

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
    pkT.Text=label local h,s,v=Color3.toHSV(getC()) cH,cS,cV=h,s,v cA=getA and getA() or 1 setter=setC setterA=setA
    pk.Visible=true pkUp()
end

-- Main window
UI.Root=mk("Frame",{Size=UDim2.new(0,520,0,540),Position=UDim2.new(0,20,0.5,-270),BackgroundColor3=T.BG0,BorderSizePixel=0,Corner=10,Stroke=Color3.fromRGB(40,40,40)},UI.Gui)
local hdr=mk("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=T.BG1,BorderSizePixel=0,Corner=10},UI.Root)
mk("Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BackgroundColor3=T.BG1,BorderSizePixel=0},hdr)
mk("Frame",{Size=UDim2.new(0,3,0,16),Position=UDim2.new(0,16,0.5,-8),BackgroundColor3=T.ACC,BorderSizePixel=0,Round=true},hdr)
mk("TextLabel",{Size=UDim2.new(0,300,1,0),Position=UDim2.new(0,28,0,0),BackgroundTransparency=1,Text="HAVOC HUB "..Hub.Version,TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left},hdr)
drag(hdr,UI.Root)
local closeB=mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-34,0.5,-13),BackgroundColor3=T.BG2,Text="X",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=13,Corner=6},hdr)
local minB=mk("TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-66,0.5,-13),BackgroundColor3=T.BG2,Text="-",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=18,Corner=6},hdr)
local reo=mk("TextButton",{Size=UDim2.new(0,44,0,44),Position=UDim2.new(0,20,0,20),BackgroundColor3=T.BG1,Text="H",TextColor3=T.ACC,Font=Enum.Font.GothamBold,TextSize=20,Visible=false,Corner=22,Stroke=T.ACC},UI.Gui)
drag(reo,reo)
minB.MouseButton1Click:Connect(function() UI.Root.Visible=false reo.Visible=true end)
reo.MouseButton1Click:Connect(function() UI.Root.Visible=true reo.Visible=false end)
closeB.MouseButton1Click:Connect(function() Hub.G.HAVOC_STOP=true Hub.Emit("shutdown") UI.Gui:Destroy() end)

UI.TabBar=mk("Frame",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,50),BackgroundTransparency=1},UI.Root)
UI.Host=mk("Frame",{Size=UDim2.new(1,-24,1,-96),Position=UDim2.new(0,12,0,88),BackgroundTransparency=1,ClipsDescendants=true},UI.Root)
UI.Tabs={} UI.TabX=0

function UI.ShowTab(n) for k,tt in pairs(UI.Tabs) do local a=(k==n) tt.c.Visible=a tt.b.TextColor3=a and T.ACC or T.TXT2 tt.u.Visible=a
    if a then tt.c.Position=UDim2.new(0,0,0,10) Tween:Create(tt.c,TweenInfo.new(0.15),{Position=UDim2.new(0,0,0,0)}):Play() end end end
function UI.AddTab(name,label)
    local c=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},UI.Host)
    local b=mk("TextButton",{Size=UDim2.new(0,88,1,0),Position=UDim2.new(0,UI.TabX,0,0),BackgroundTransparency=1,Text=label,TextColor3=T.TXT2,Font=Enum.Font.GothamBold,TextSize=12},UI.TabBar)
    local u=mk("Frame",{Size=UDim2.new(0,22,0,2),Position=UDim2.new(0.5,-11,1,-4),BackgroundColor3=T.ACC,BorderSizePixel=0,Visible=false,Round=true},b)
    UI.Tabs[name]={b=b,c=c,u=u} b.MouseButton1Click:Connect(function() UI.ShowTab(name) end) UI.TabX=UI.TabX+92
    return c
end

function UI.Row(par,x,y,w,label,gT,sT,gC,sC,gA,sA)
    local r=mk("Frame",{Size=UDim2.new(0,w,0,30),Position=UDim2.new(0,x,0,y),BackgroundColor3=T.BG2,Corner=6},par)
    local rb=mk("TextButton",{Size=UDim2.new(1,-46,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false},r)
    mk("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=label,TextColor3=T.TXT,Font=Enum.Font.GothamMedium,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},rb)
    local tr=mk("Frame",{Size=UDim2.new(0,26,0,12),Position=UDim2.new(1,-74,0.5,-6),BorderSizePixel=0,Round=true},r)
    local kn=mk("Frame",{Size=UDim2.new(0,8,0,8),BackgroundColor3=Color3.fromRGB(235,235,235),BorderSizePixel=0,Round=true},tr)
    local function paint(an) local on=gT() local ti=TweenInfo.new(0.15)
        if an then Tween:Create(tr,ti,{BackgroundColor3=on and T.ACC or Color3.fromRGB(48,48,48)}):Play() Tween:Create(kn,ti,{Position=on and UDim2.new(1,-10,0.5,-4) or UDim2.new(0,2,0.5,-4)}):Play()
        else tr.BackgroundColor3=on and T.ACC or Color3.fromRGB(48,48,48) kn.Position=on and UDim2.new(1,-10,0.5,-4) or UDim2.new(0,2,0.5,-4) end end
    paint(false) rb.MouseButton1Click:Connect(function() sT(not gT()) paint(true) end)
    if gC then local sw=mk("TextButton",{Size=UDim2.new(0,28,0,14),Position=UDim2.new(1,-36,0.5,-7),BackgroundColor3=gC(),Text="",Corner=3,Stroke=Color3.fromRGB(60,60,60)},r)
        sw.MouseButton1Click:Connect(function() UI.OpenPicker(label,gC,function(c) sC(c) sw.BackgroundColor3=c end,gA,sA) end) end
end
function UI.Step(par,x,y,w,label,gV,sV,st,mn,mx,fmt)
    local r=mk("Frame",{Size=UDim2.new(0,w,0,30),Position=UDim2.new(0,x,0,y),BackgroundColor3=T.BG2,Corner=6},par)
    local lb=mk("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Font=Enum.Font.GothamMedium,TextSize=11,TextColor3=T.TXT,TextXAlignment=Enum.TextXAlignment.Left},r)
    local function rf() lb.Text=label.."   "..(fmt and fmt(gV()) or tostring(gV())) end rf()
    mk("TextButton",{Size=UDim2.new(0,22,0,18),Position=UDim2.new(1,-50,0.5,-9),BackgroundColor3=Color3.fromRGB(36,36,36),Text="-",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=12,Corner=3},r).MouseButton1Click:Connect(function() sV(math.max(mn,gV()-st)) rf() end)
    mk("TextButton",{Size=UDim2.new(0,22,0,18),Position=UDim2.new(1,-26,0.5,-9),BackgroundColor3=Color3.fromRGB(36,36,36),Text="+",TextColor3=T.TXT,Font=Enum.Font.GothamBold,TextSize=12,Corner=3},r).MouseButton1Click:Connect(function() sV(math.min(mx,gV()+st)) rf() end)
end
function UI.Header(par,x,y,w,txt) mk("TextLabel",{Size=UDim2.new(0,w,0,20),Position=UDim2.new(0,x,0,y),BackgroundTransparency=1,Text=txt,TextColor3=T.ACC,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},par) end

-- Helper wrappers for feature devs
function UI.Toggle(par,x,y,w,label,key,default) UI.Row(par,x,y,w,label,function() return Hub.Get(key,default) end,function(v) Hub.Set(key,v) end) end
function UI.ToggleColor(par,x,y,w,label,keyT,defT,keyC,defC,keyA,defA)
    UI.Row(par,x,y,w,label,function() return Hub.Get(keyT,defT) end,function(v) Hub.Set(keyT,v) end,
        function() return Hub.Get(keyC,defC) end,function(c) Hub.Set(keyC,c) end,
        keyA and function() return Hub.Get(keyA,defA or 1) end or nil,
        keyA and function(a) Hub.Set(keyA,a) end or nil)
end
function UI.Stepper(par,x,y,w,label,key,default,st,mn,mx,fmt) UI.Step(par,x,y,w,label,function() return Hub.Get(key,default) end,function(v) Hub.Set(key,v) end,st,mn,mx,fmt) end

Hub.Emit("ui_ready")
print("[Hub UI] loaded")
