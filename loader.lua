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

fetch("core.lua")
fetch("ui.lua")
-- DIAGNOSTIC: weapon.lua desactive temporairement pour tester si les degats reviennent
for _,f in ipairs({"esp","loot","player","world","inventory"}) do
    fetch("features/"..f..".lua")
end
if _G.HavocHub and _G.HavocHub.Start then _G.HavocHub.Start() end
print("[Hub] loader done")
