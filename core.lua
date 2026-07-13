-- HAVOC HUB CORE
_G.HavocHub=_G.HavocHub or {}
local Hub=_G.HavocHub
Hub.Version="v13" Hub.Modules={} Hub.Config={} Hub.CFG_FILE="havoc_hub_cfg.json"
Hub.Signals={} Hub.NamecallHooks={} Hub.G=getgenv()

Hub.Players=game:GetService("Players") Hub.RunS=game:GetService("RunService")
Hub.UIS=game:GetService("UserInputService") Hub.Tween=game:GetService("TweenService")
Hub.RS=game:GetService("ReplicatedStorage") Hub.Lighting=game:GetService("Lighting")
Hub.HttpService=game:GetService("HttpService")
Hub.lp=Hub.Players.LocalPlayer Hub.cam=workspace.CurrentCamera

Hub.Theme={
    BG0=Color3.fromRGB(10,10,10), BG1=Color3.fromRGB(16,16,16), BG2=Color3.fromRGB(23,23,23),
    ACC=Color3.fromRGB(245,197,24), TXT=Color3.fromRGB(222,222,222), TXT2=Color3.fromRGB(125,125,125),
    HP_LOW=Color3.fromRGB(255,0,0),
}

function Hub.mk(cls,p,par)
    local o=Instance.new(cls)
    for k,v in pairs(p or {}) do
        if k=="Corner" then local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,v) c.Parent=o
        elseif k=="Round" then local c=Instance.new("UICorner") c.CornerRadius=UDim.new(1,0) c.Parent=o
        elseif k=="Stroke" then local s=Instance.new("UIStroke") s.Color=v s.Parent=o
        else o[k]=v end
    end
    if par then o.Parent=par end return o
end

-- Config persistante
function Hub.LoadConfig()
    pcall(function()
        if isfile and isfile(Hub.CFG_FILE) then
            local raw=readfile(Hub.CFG_FILE)
            local ok,data=pcall(function() return Hub.HttpService:JSONDecode(raw) end)
            if ok and type(data)=="table" then
                for k,v in pairs(data) do
                    if type(v)=="table" and v.__color then Hub.Config[k]=Color3.fromRGB(v.r,v.g,v.b)
                    else Hub.Config[k]=v end
                end
            end
        end
    end)
end
function Hub.SaveConfig()
    pcall(function()
        if not writefile then return end
        local dump={}
        for k,v in pairs(Hub.Config) do
            if typeof(v)=="Color3" then dump[k]={__color=true,r=math.floor(v.R*255),g=math.floor(v.G*255),b=math.floor(v.B*255)}
            else dump[k]=v end
        end
        writefile(Hub.CFG_FILE,Hub.HttpService:JSONEncode(dump))
    end)
end
function Hub.Get(key,default)
    if Hub.Config[key]==nil then Hub.Config[key]=default end
    return Hub.Config[key]
end
function Hub.Set(key,val) Hub.Config[key]=val Hub.SaveConfig() end

-- Module registry
function Hub.RegisterModule(name,mod) Hub.Modules[name]=mod end

-- Pub/sub events
function Hub.On(evt,cb) Hub.Signals[evt]=Hub.Signals[evt] or {} table.insert(Hub.Signals[evt],cb) end
function Hub.Emit(evt,...) if not Hub.Signals[evt] then return end for _,cb in ipairs(Hub.Signals[evt]) do pcall(cb,...) end end

-- Shared helpers
function Hub.MyPos() local c=Hub.lp.Character local r=c and c:FindFirstChild("HumanoidRootPart") return r and r.Position or Hub.cam.CFrame.Position end
function Hub.IsPlayer(m) return Hub.Players:GetPlayerFromCharacter(m)~=nil end
function Hub.RealId(m) local plr=Hub.Players:GetPlayerFromCharacter(m) if plr then return "P:"..plr.UserId,plr end
    local uuid=m:GetAttribute("AI_UUID") if uuid then return "A:"..uuid,nil end
    return "M:"..m.Name,nil end
function Hub.Enemies(maxDist)
    maxDist=maxDist or Hub.Get("MAX_DIST",3400)
    local mc=Hub.lp.Character local cont=mc and mc.Parent or workspace local o=Hub.MyPos() local byId={}
    for _,m in ipairs(cont:GetChildren()) do
        if m~=mc and m:IsA("Model") then
            local h=m:FindFirstChildOfClass("Humanoid")
            local r=m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
            local hd=m:FindFirstChild("Head")
            if h and r and hd and h.Health>0 then
                local d=(r.Position-o).Magnitude
                if d<=maxDist then
                    local id,plr=Hub.RealId(m)
                    if not (plr and plr.Character~=m) then
                        local p=byId[id]
                        if not p or d<p.dist then byId[id]={m=m,hrp=r,hd=hd,hum=h,dist=d} end
                    end
                end
            end
        end
    end
    return byId
end

-- Global namecall hook (features register callbacks)
if not Hub._namecallInstalled then
    Hub._namecallInstalled=true
    local mt=getrawmetatable(game)
    local old=mt.__namecall
    setreadonly(mt,false)
    mt.__namecall=newcclosure(function(self,...)
        if Hub.G.HAVOC_STOP then return old(self,...) end
        local method=getnamecallmethod()
        local args={...}
        for _,hook in ipairs(Hub.NamecallHooks) do
            local ok,res=pcall(hook,self,method,args)
            if ok and res=="BLOCK" then return end
            if ok and type(res)=="table" then args=res end
        end
        return old(self,unpack(args))
    end)
    setreadonly(mt,true)
end
function Hub.AddNamecallHook(fn) table.insert(Hub.NamecallHooks,fn) end

function Hub.Start()
    Hub.LoadConfig()
    for name,mod in pairs(Hub.Modules) do
        if type(mod.Start)=="function" then pcall(mod.Start) end
    end
    print("[Hub] started")
end

print("[Hub Core "..Hub.Version.."] loaded")
