-- Havoc Hub loader (paste this in Volt)
if getgenv().HAVOC_LOADED then getgenv().HAVOC_STOP=true task.wait(0.5) end
getgenv().HAVOC_LOADED=true getgenv().HAVOC_STOP=false

local base="https://raw.githubusercontent.com/exorciepigeon-oss/havoc-hub/main/"

local function fetch(path)
    local ok,body=pcall(function() return game:HttpGet(base..path.."?t="..tick(),true) end)
    if not ok then warn("[Hub] fetch fail "..path..": "..tostring(body)) return end
    local fn,err=loadstring(body,path)
    if not fn then warn("[Hub] compile "..path..": "..tostring(err)) return end
    local ok2,err2=pcall(fn)
    if not ok2 then warn("[Hub] run "..path..": "..tostring(err2)) end
end

-- Download icons to local disk pour ImageLabels via getcustomasset
getgenv().HAVOC_ICONS={}
local function fetchIcon(name)
    local ok,body=pcall(function() return game:HttpGet(base.."icons/"..name..".png",true) end)
    if not ok or not body then warn("[Hub] icon fail "..name) return end
    if writefile then
        pcall(function() writefile("havoc_hub_"..name..".png",body) end)
        local getAsset=getcustomasset or getsynasset
        if getAsset then
            local ok2,url=pcall(getAsset,"havoc_hub_"..name..".png")
            if ok2 then getgenv().HAVOC_ICONS[name]=url end
        end
    end
end
for _,n in ipairs({"esp","weapon","world","misc","config"}) do fetchIcon(n) end

fetch("core.lua")
fetch("ui.lua")
for _,f in ipairs({"esp","loot","weapon","player","world","inventory"}) do
    fetch("features/"..f..".lua")
end
if _G.HavocHub and _G.HavocHub.Start then _G.HavocHub.Start() end
print("[Hub] loader done")
