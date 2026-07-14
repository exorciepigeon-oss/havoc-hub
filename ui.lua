-- HAVOC HUB UI : Obsidian adapter (features API unchanged)
local Hub=_G.HavocHub if not Hub then warn("[UI] core not loaded") return end
print("[UI] step 1: Hub found")

-- Nuke prior UIs on reload
pcall(function()
    for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do
        local n=g.Name
        if n=="LinoriaLib" or n=="Obsidian" or n=="FluentRenewedInterface" or n=="Fluent" or n=="HavocHub" or n=="Library" or n=="HavocHub_ESPNative" then g:Destroy() end
    end
end)

-- Unload previous Library instance if present
if Hub.UI and Hub.UI.Library then pcall(function() Hub.UI.Library:Unload() end) end

print("[UI] step 2: fetching Obsidian")
local repo="https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local okFetch,body=pcall(function() return game:HttpGet(repo.."Library.lua") end)
if not okFetch or type(body)~="string" or #body<1000 then
    warn("[UI] Obsidian HttpGet failed. Err: "..tostring(body):sub(1,200)) return
end
local libFn,compileErr=loadstring(body,"Obsidian.Library")
if not libFn then warn("[UI] Obsidian compile fail: "..tostring(compileErr)) return end
local okRun,Library=pcall(libFn)
if not okRun or not Library then warn("[UI] Obsidian run fail: "..tostring(Library)) return end
print("[UI] step 3: Obsidian loaded")

Hub.UI={}
local UI=Hub.UI
UI.Library=Library

local okWin,Window=pcall(function()
    return Library:CreateWindow({
        Title="Havoc Hub",
        Footer=Hub.Version or "v13",
        Center=true,
        AutoShow=true,
        Size=UDim2.fromOffset(700,580),
        Font=Enum.Font.Code,
    })
end)
if not okWin or not Window then warn("[UI] CreateWindow failed: "..tostring(Window)) return end
UI.Window=Window
print("[UI] step 4: window created")

-- Apply persisted menu toggle key (guard against old bad-format saves)
local savedKey=Hub.Get("MENU_KEY","RightControl")
-- Strip legacy "Enum.KeyCode." prefix if present
if type(savedKey)=="string" then savedKey=savedKey:gsub("^Enum%.KeyCode%.","") end
local okKC,kc=pcall(function() return Enum.KeyCode[savedKey] end)
if okKC and kc then Library.ToggleKeybind=kc Hub.Set("MENU_KEY",kc.Name)
else Hub.Set("MENU_KEY","RightControl") end

-- Force show in case AutoShow race
task.spawn(function() task.wait(0.1) pcall(function() if not Library.Toggled then Library:Toggle() end end) end)

local iconMap={esp="eye",world="globe",weapon="crosshair",misc="wrench",config="settings",player="user",inventory="backpack",loot="globe"}

UI.Tabs={} -- name -> {tab=Tab, curLeft=Groupbox, curRight=Groupbox, current=Groupbox}
local uid=0 local function nid() uid=uid+1 return "hh_"..uid end

function UI.AddTab(name,label,customIcon)
    local okT,tab=pcall(function() return Window:AddTab(label or name,iconMap[name] or "circle") end)
    if not okT or not tab then warn("[UI] AddTab fail "..tostring(name)..": "..tostring(tab)) return name end
    UI.Tabs[name]={tab=tab,curLeft=nil,curRight=nil,current=nil}
    print("[UI] AddTab OK: "..tostring(name))
    return name
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
    local e=entry(par) if not e or not e.tab then warn("[UI] Header no tab for "..tostring(par)) return end
    local side=(x and x<120) and "Left" or "Right"
    local box
    local okB,err
    if side=="Left" then okB,err=pcall(function() box=e.tab:AddLeftGroupbox(txt or "") end) e.curLeft=box
    else okB,err=pcall(function() box=e.tab:AddRightGroupbox(txt or "") end) e.curRight=box end
    if not okB then warn("[UI] Groupbox fail: "..tostring(err)) end
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

-- UI.KeyBind(par,x,y,w,label, getKeyOrString, setKeyOrDefault, onChange, defaultMode)
-- Poll GetState() car Obsidian ne fire pas Callback pour Hold mode
function UI.KeyBind(par,x,y,w,label,getKey,setKey,onChange,defaultMode)
    local g=tgt(par) if not g then return end
    if type(getKey)=="string" then local k=getKey local d=setKey
        getKey=function() return Hub.Get(k,d) end setKey=function(v) Hub.Set(k,v) end
    end
    local kStr=getKey() or "C"
    local pickerId=nid()
    g:AddLabel(label):AddKeyPicker(pickerId,{Default=kStr,Mode=defaultMode or "Hold",Text=label,
        ChangedCallback=function(new) if typeof(new)=="EnumItem" then setKey(new.Name) end end})
    if onChange then
        local kp=Library.Options and Library.Options[pickerId]
        if kp then
            local lastState=false
            game:GetService("RunService").Heartbeat:Connect(function()
                if Hub.G and Hub.G.HAVOC_STOP then return end
                local ok,st=pcall(function() return kp:GetState() end)
                if ok then st=st and true or false
                    if st~=lastState then lastState=st onChange(st) end
                end
            end)
        else warn("[UI] KeyBind poll fail: KeyPicker not in Library.Options["..pickerId.."]") end
    end
end

function UI.OpenPicker() end

-- Config tab (delayed so features register first)
task.spawn(function()
    task.wait(1.5)
    if Hub.G and Hub.G.HAVOC_STOP then return end
    local cfg=UI.AddTab("config","Config")
    local e=UI.Tabs.config
    local left=e.tab:AddLeftGroupbox("Menu") e.curLeft=left e.current=left
    -- Menu toggle key picker (fix: ChangedCallback receives Enum.KeyCode)
    local curKey=Hub.Get("MENU_KEY","RightControl")
    left:AddLabel("Menu Toggle Key"):AddKeyPicker(nid(),{Default=curKey,Mode="Toggle",Text="Menu Key",
        ChangedCallback=function(new)
            if typeof(new)~="EnumItem" then return end
            Library.ToggleKeybind=new
            Hub.Set("MENU_KEY",new.Name)
        end})
    left:AddButton({Text="Unload Script",Risky=true,Func=function()
        Hub.G.HAVOC_STOP=true
        Hub.Emit("shutdown")
        task.wait(0.1)
        pcall(function() Library:Unload() end)
        pcall(function()
            for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do
                if g.Name=="HavocHub_ESPNative" or g.Name=="HavocHub" then g:Destroy() end
            end
        end)
        getgenv().HAVOC_LOADED=false
        print("[Hub] fully unloaded")
    end})

    -- CONFIGS (profiles named)
    local right=e.tab:AddRightGroupbox("Configs") e.curRight=right e.current=right
    local CFG_DIR="havoc_hub_configs"
    local function ensureDir() if makefolder and not (isfolder and isfolder(CFG_DIR)) then pcall(makefolder,CFG_DIR) end end
    local function listCfgs()
        ensureDir()
        local out={}
        if listfiles and isfolder and isfolder(CFG_DIR) then
            for _,f in ipairs(listfiles(CFG_DIR)) do
                local nm=f:match("([^/\\]+)%.json$") if nm then table.insert(out,nm) end
            end
        end
        table.sort(out) return out
    end
    local function jsonEncode(t) return game:GetService("HttpService"):JSONEncode(t) end
    local function jsonDecode(s) local ok,r=pcall(function() return game:GetService("HttpService"):JSONDecode(s) end) return ok and r or nil end
    local function saveCfg(name)
        if not name or name=="" then Library:Notify("Empty config name",3) return end
        ensureDir()
        local snap={}
        for k,v in pairs(Hub.Config) do
            if not Hub.UnsafeKeys or not Hub.UnsafeKeys[k] then
                if typeof(v)=="Color3" then snap[k]={__c3=true,R=v.R,G=v.G,B=v.B}
                else snap[k]=v end
            end
        end
        pcall(function() writefile(CFG_DIR.."/"..name..".json",jsonEncode(snap)) end)
        Library:Notify("Saved: "..name,3)
    end
    local function loadCfg(name)
        if not name or name=="" then return end
        local p=CFG_DIR.."/"..name..".json"
        if not (isfile and isfile(p)) then Library:Notify("Not found: "..name,3) return end
        local raw=readfile(p) local data=jsonDecode(raw) if not data then Library:Notify("Corrupt config",3) return end
        for k,v in pairs(data) do
            if not Hub.UnsafeKeys or not Hub.UnsafeKeys[k] then
                if type(v)=="table" and v.__c3 then Hub.Config[k]=Color3.new(v.R,v.G,v.B)
                else Hub.Config[k]=v end
            end
        end
        pcall(function() writefile(Hub.CFG_FILE,jsonEncode(Hub.Config)) end)
        Library:Notify("Loaded "..name.." - relaunch to apply",4)
    end
    local function delCfg(name)
        if not name or name=="" then return end
        local p=CFG_DIR.."/"..name..".json"
        if delfile then pcall(delfile,p) end
        Library:Notify("Deleted "..name,3)
    end

    local nameInput=right:AddInput(nid(),{Text="Config Name",Default="",Placeholder="my_config",Finished=false})
    right:AddButton({Text="Save Current",Func=function() saveCfg(nameInput.Value) end})

    local dd=right:AddDropdown(nid(),{Text="Select Config",Values=listCfgs(),Default=1,AllowNull=true})
    right:AddButton({Text="Refresh List",Func=function() dd:SetValues(listCfgs()) end})
    right:AddButton({Text="Load Selected",Func=function() loadCfg(dd.Value) end})
    right:AddButton({Text="Delete Selected",Risky=true,Func=function() delCfg(dd.Value) dd:SetValues(listCfgs()) end})

    right:AddButton({Text="Reset ALL settings",Risky=true,Func=function()
        for k,_ in pairs(Hub.Config) do Hub.Config[k]=nil end
        if writefile then pcall(function() writefile(Hub.CFG_FILE,"{}") end) end
        Library:Notify("Config reset - relaunch to apply",3)
    end})
    right:AddLabel("Havoc Hub "..(Hub.Version or "").." | Combat toggles never persist.",true)
end)

Library:Notify("Havoc Hub "..(Hub.Version or "").." loaded",3)
Hub.Emit("ui_ready")
print("[Hub UI Obsidian] loaded")
