-- HAVOC HUB UI : Fluent adapter (features API unchanged: AddTab/Header/Row/ToggleColor/Stepper/KeyBind)
local Hub=_G.HavocHub if not Hub then warn("[UI] core not loaded") return end

-- Nuke previous Fluent GUI on reload
pcall(function()
    for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if g.Name=="FluentRenewedInterface" or g.Name=="Fluent" or g.Name=="InterfaceManager" then g:Destroy() end
    end
end)

local ok,Fluent=pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not ok or not Fluent then warn("[UI] Fluent load fail: "..tostring(Fluent)) return end

if Hub.UI and Hub.UI.Window then pcall(function() Hub.UI.Window:Destroy() end) end
Hub.UI={}
local UI=Hub.UI
UI.Fluent=Fluent

local Window=Fluent:CreateWindow({
    Title="Havoc Hub",
    SubTitle=Hub.Version or "",
    TabWidth=140,
    Size=UDim2.fromOffset(560,420),
    Acrylic=true,
    Theme="Dark",
    MinimizeKey=Enum.KeyCode.RightShift
})
UI.Window=Window

local iconMap={esp="eye",world="globe",weapon="crosshair",misc="settings-2",config="sliders",player="user",inventory="backpack",loot="globe"}

UI.Tabs={}
UI.CurrentSection={} -- per Fluent tab: current section object (from UI.Header)
local uid=0
local function nid() uid=uid+1 return "hh_"..uid end
local function tgtOf(tab) return UI.CurrentSection[tab] or tab end

function UI.AddTab(name,label,customIcon)
    local tab=Window:AddTab({Title=label or name,Icon=iconMap[name] or "circle"})
    UI.Tabs[name]=tab
    return tab
end

function UI.ShowTab(name)
    local t=UI.Tabs[name]
    if t and t.Select then pcall(function() t:Select() end) end
end

-- UI.Header = Fluent Section (all subsequent widgets in this tab go into it until next Header)
function UI.Header(par,x,y,w,txt,h)
    if par and par.AddSection then
        UI.CurrentSection[par]=par:AddSection(txt or "")
    end
end
-- UI.Group compat: create standalone section, return it
function UI.Group(par,x,y,w,h,title)
    if par and par.AddSection then local s=par:AddSection(title or "") UI.CurrentSection[par]=s return s end
    return par
end

local function resolveTS(gT,sT)
    if type(gT)=="string" then local k=gT local d=sT
        return function() return Hub.Get(k,d) end,function(v) Hub.Set(k,v) end
    end
    return gT,sT
end

function UI.Row(par,x,y,w,label,gT,sT,gC,sC,gA,sA)
    local get,set=resolveTS(gT,sT)
    local tgt=tgtOf(par)
    local togg=tgt:AddToggle(nid(),{Title=label,Default=(get and get()) or false,Callback=function(v) if set then set(v) end end})
    if gC and togg.AddColorPicker then
        local cp=togg:AddColorPicker(nid(),{Default=gC(),Title=label.." Color",Callback=function(c) sC(c) end,
            Transparency=gA and (1-gA()) or nil,TransparencyChanged=gA and function(t) sA(1-t) end or nil})
    end
    return togg
end

function UI.ToggleColor(par,x,y,w,label,keyT,defT,keyC,defC,keyA,defA)
    local tgt=tgtOf(par)
    local togg=tgt:AddToggle(keyT,{Title=label,Default=Hub.Get(keyT,defT),Callback=function(v) Hub.Set(keyT,v) end})
    if togg.AddColorPicker then
        local optCP={Default=Hub.Get(keyC,defC),Title=label.." Color",Callback=function(c) Hub.Set(keyC,c) end}
        if keyA then optCP.Transparency=1-Hub.Get(keyA,defA or 1) optCP.TransparencyChanged=function(t) Hub.Set(keyA,1-t) end end
        togg:AddColorPicker(keyC,optCP)
    end
end

function UI.Stepper(par,x,y,w,label,gV,sV,st,mn,mx,fmt)
    if type(gV)=="string" then local k=gV local d=sV
        gV=function() return Hub.Get(k,d) end sV=function(v) Hub.Set(k,v) end
    end
    local tgt=tgtOf(par)
    tgt:AddSlider(nid(),{Title=label,Default=gV(),Min=mn,Max=mx,Rounding=(st<1 and 2 or 0),Callback=function(v) sV(v) end})
end
UI.Step=UI.Stepper
function UI.Toggle(par,x,y,w,label,gT,sT) UI.Row(par,x,y,w,label,gT,sT) end

function UI.KeyBind(par,x,y,w,label,getKey,setKey)
    if type(getKey)=="string" then local k=getKey local d=setKey
        getKey=function() return Hub.Get(k,d) end setKey=function(v) Hub.Set(k,v) end
    end
    local tgt=tgtOf(par)
    local kStr=getKey() or "C"
    local kc=Enum.KeyCode[kStr] or Enum.KeyCode.C
    tgt:AddKeybind(nid(),{Title=label,Default=kc,Mode="Hold",Callback=function() end,
        ChangedCallback=function(new) if new and new.Name then setKey(new.Name) end end})
end

function UI.OpenPicker() end -- legacy no-op (Fluent handles color inline)

-- Config tab (delayed)
task.spawn(function()
    task.wait(1.5)
    if Hub.G and Hub.G.HAVOC_STOP then return end
    local cfg=UI.AddTab("config","Config")
    UI.Header(cfg,0,0,0,"CONFIGURATION")
    cfg:AddButton({Title="Reset all saved settings",Description="Clears config file, relaunch to apply",Callback=function()
        for k,_ in pairs(Hub.Config) do Hub.Config[k]=nil end
        if writefile then pcall(function() writefile(Hub.CFG_FILE,"{}") end) end
        Fluent:Notify({Title="Havoc Hub",Content="Config reset",Duration=3})
    end})
    cfg:AddParagraph({Title="Havoc Hub "..(Hub.Version or ""),Content="Modular hub. Combat toggles never persist (safety). Reload via loader in Volt after GitHub updates."})
end)

Fluent:Notify({Title="Havoc Hub",Content=(Hub.Version or "").." loaded",Duration=3})
Hub.Emit("ui_ready")
print("[Hub UI Fluent] loaded")
