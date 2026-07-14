-- HAVOC HUB UI : Obsidian adapter (features API unchanged)
local Hub=_G.HavocHub if not Hub then warn("[UI] core not loaded") return end

-- Nuke prior UIs on reload
pcall(function()
    for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do
        local n=g.Name
        if n=="LinoriaLib" or n=="Obsidian" or n=="FluentRenewedInterface" or n=="Fluent" or n=="HavocHub" then g:Destroy() end
    end
end)

local repo="https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local ok,Library=pcall(function() return loadstring(game:HttpGet(repo.."Library.lua"))() end)
if not ok or not Library then warn("[UI] Obsidian load fail: "..tostring(Library)) return end

if Hub.UI and Hub.UI.Window then pcall(function() Library:Unload() end) end
Hub.UI={}
local UI=Hub.UI
UI.Library=Library

local Window=Library:CreateWindow({
    Title="Havoc Hub",
    Footer=Hub.Version or "",
    Center=true,
    AutoShow=true,
    Size=UDim2.fromOffset(580,520),
    MenuFadeTime=0.15,
})
UI.Window=Window

local iconMap={esp="eye",world="globe",weapon="crosshair",misc="settings-2",config="sliders",player="user",inventory="backpack",loot="globe"}

UI.Tabs={} -- name -> {tab=Tab, curLeft=Groupbox, curRight=Groupbox, current=Groupbox}
local uid=0 local function nid() uid=uid+1 return "hh_"..uid end

function UI.AddTab(name,label,customIcon)
    local tab=Window:AddTab(label or name,iconMap[name] or "circle")
    UI.Tabs[name]={tab=tab,curLeft=nil,curRight=nil,current=nil}
    return name -- return NAME so features pass it as `par`
end

function UI.ShowTab(name)
    local t=UI.Tabs[name]
    if t and t.tab and t.tab.Show then pcall(function() t.tab:Show() end) end
end

-- Resolve tab entry from `par` (either string name or already tab-entry)
local function entry(par)
    if type(par)=="string" then return UI.Tabs[par] end
    return par
end

-- UI.Header: create groupbox on left or right column based on x. Sets current for subsequent widgets.
function UI.Header(par,x,y,w,txt,h)
    local e=entry(par) if not e then return end
    local side=(x and x<120) and "Left" or "Right"
    local box
    if side=="Left" then box=e.tab:AddLeftGroupbox(txt or "") e.curLeft=box
    else box=e.tab:AddRightGroupbox(txt or "") e.curRight=box end
    e.current=box
    return box
end
function UI.Group(par,x,y,w,h,title) return UI.Header(par,x,y,w,title) end

local function tgt(par) local e=entry(par) if not e then return nil end
    if not e.current then e.current=e.tab:AddLeftGroupbox("Main") e.curLeft=e.current end
    return e.current end

local function resolveTS(gT,sT)
    if type(gT)=="string" then local k=gT local d=sT
        return function() return Hub.Get(k,d) end,function(v) Hub.Set(k,v) end
    end
    return gT,sT
end

function UI.Row(par,x,y,w,label,gT,sT,gC,sC,gA,sA)
    local g=tgt(par) if not g then return end
    local get,set=resolveTS(gT,sT)
    local togg=g:AddToggle(nid(),{Text=label,Default=(get and get()) or false,Callback=function(v) if set then set(v) end end})
    if gC and togg.AddColorPicker then
        local opt={Default=gC(),Title=label,Callback=function(c) sC(c) end}
        if gA then opt.Transparency=1-gA() opt.TransparencyChanged=function(t) sA(1-t) end end
        togg:AddColorPicker(nid(),opt)
    end
    return togg
end

function UI.ToggleColor(par,x,y,w,label,keyT,defT,keyC,defC,keyA,defA)
    local g=tgt(par) if not g then return end
    local togg=g:AddToggle(keyT,{Text=label,Default=Hub.Get(keyT,defT),Callback=function(v) Hub.Set(keyT,v) end})
    if togg.AddColorPicker then
        local opt={Default=Hub.Get(keyC,defC),Title=label,Callback=function(c) Hub.Set(keyC,c) end}
        if keyA then opt.Transparency=1-Hub.Get(keyA,defA or 1) opt.TransparencyChanged=function(t) Hub.Set(keyA,1-t) end end
        togg:AddColorPicker(keyC,opt)
    end
end

function UI.Stepper(par,x,y,w,label,gV,sV,st,mn,mx,fmt)
    local g=tgt(par) if not g then return end
    if type(gV)=="string" then local k=gV local d=sV
        gV=function() return Hub.Get(k,d) end sV=function(v) Hub.Set(k,v) end
    end
    g:AddSlider(nid(),{Text=label,Default=gV(),Min=mn,Max=mx,Rounding=(st<1 and 2 or 0),Suffix="",Callback=function(v) sV(v) end})
end
UI.Step=UI.Stepper
function UI.Toggle(par,x,y,w,label,gT,sT) UI.Row(par,x,y,w,label,gT,sT) end

function UI.KeyBind(par,x,y,w,label,getKey,setKey)
    local g=tgt(par) if not g then return end
    if type(getKey)=="string" then local k=getKey local d=setKey
        getKey=function() return Hub.Get(k,d) end setKey=function(v) Hub.Set(k,v) end
    end
    local kStr=getKey() or "C"
    g:AddLabel(label):AddKeyPicker(nid(),{Default=kStr,SyncOnPress=true,Mode="Hold",Text=label,Callback=function() end,
        ChangedCallback=function(new) if new then setKey(tostring(new)) end end})
end

function UI.OpenPicker() end

-- Config tab (delayed so features register first)
task.spawn(function()
    task.wait(1.5)
    if Hub.G and Hub.G.HAVOC_STOP then return end
    local cfg=UI.AddTab("config","Config")
    local e=UI.Tabs.config
    local left=e.tab:AddLeftGroupbox("Configuration") e.curLeft=left e.current=left
    left:AddButton({Text="Reset all saved settings",Func=function()
        for k,_ in pairs(Hub.Config) do Hub.Config[k]=nil end
        if writefile then pcall(function() writefile(Hub.CFG_FILE,"{}") end) end
        Library:Notify("Config reset - relaunch to apply",3)
    end})
    left:AddLabel("Havoc Hub "..(Hub.Version or "").." | Combat toggles never persist (safety).",true)
end)

Library:Notify("Havoc Hub "..(Hub.Version or "").." loaded",3)
Hub.Emit("ui_ready")
print("[Hub UI Obsidian] loaded")
