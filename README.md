do
    if _G.__CELESTIAL_H_last_bind then pcall(function() game:GetService("RunService"):UnbindFromRenderStep(_G.__CELESTIAL_H_last_bind) end) end
    if _G.__CELESTIAL_H_vm_bind then pcall(function() game:GetService("RunService"):UnbindFromRenderStep(_G.__CELESTIAL_H_vm_bind) end) end
    if _G.__CELESTIAL_H_viewfov_bind then pcall(function() game:GetService("RunService"):UnbindFromRenderStep(_G.__CELESTIAL_H_viewfov_bind) end) end
    if _G.__CELESTIAL_H_last_connections then
        for _, c in ipairs(_G.__CELESTIAL_H_last_connections) do pcall(function() c:Disconnect() end) end
    end
    pcall(function()
        local par = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
        for _, c in ipairs(par:GetChildren()) do
            local n = c.Name
            if n == "CELESTIAL_H_UI" or n == "CELESTIAL_H_Visuals" or n == "CELESTIAL_H_FOV" or n == "CELESTIAL_H_Brain"
                or n == "CELESTIAL_H_Startup" or n == "CELESTIAL_H_Watermark" or n == "CELESTIAL_H_MobileOverlay"
                or n == "CELESTIAL_H_Discord" or n == "CELESTIAL_H_Premium" or n == "CELESTIAL_H_Picker"
                or n == "CELESTIAL_H_KeyUI" or n == "CELESTIAL_H_Popup" or n == "CELESTIAL_H_Crosshair"
                or n == "CELESTIAL_H_HUD" or n == "CELESTIAL_H_Keybinds" or n == "CELESTIAL_H_Graph" or n == "CELESTIAL_H_Visuals" then
                c:Destroy()
            end
        end
    end)
    _G.__CELESTIAL_H_last_bind = nil _G.__CELESTIAL_H_vm_bind = nil _G.__CELESTIAL_H_viewfov_bind = nil
    _G.__CELESTIAL_H_last_connections = nil _G.__CELESTIAL_H_CameraAssist = nil _G.__CELESTIAL_H_Weapon = nil
    _G.__CELESTIAL_H_ShowStartup = nil _G.__CELESTIAL_H_Diag = nil _G.__CELESTIAL_H_Mobile = nil _G.__CELESTIAL_H_StartupDone = nil
    _G.__CELESTIAL_H_INITIALIZED = nil
end

local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local function sget(f, d) local ok, v = pcall(f) if ok then return v end return d end

local function detectDevice()
    local o = _G.__CELESTIAL_H_ForceDevice
    if o == "mobile" then return {isMobile=true, isPC=false, isVR=false, platform="override"} end
    if o == "pc" then return {isMobile=false, isPC=true, isVR=false, platform="override"} end
    local p = sget(function() return UIS:GetPlatform() end, nil)
    local ps = tostring(p or "Unknown")
    local mp = ps:find("iOS") ~= nil or ps:find("Android") ~= nil or ps:find("UWP") ~= nil
    local t = sget(function() return UIS.TouchEnabled end, false)
    local k = sget(function() return UIS.KeyboardEnabled end, true)
    local m = sget(function() return UIS.MouseEnabled end, true)
    local v = sget(function() return UIS.VREnabled end, false)
    local im = false
    if v then im = false
    elseif mp then im = not k
    elseif t and not k and not m then im = true end
    return {isMobile=im, isPC=(not im) and (not v), isVR=v, platform=ps, touch=t, keyboard=k, mouse=m}
end

local DeviceInfo = detectDevice()

local SILENT = { Active = false, Mode = "none", HitCount = 0 }

if _G.__CELESTIAL_H_SILENT_REF then
    SILENT = _G.__CELESTIAL_H_SILENT_REF
    SILENT.Active = false
    SILENT.HitCount = 0
else
    _G.__CELESTIAL_H_SILENT_REF = SILENT

    local function current_lock()
        local ca = _G.__CELESTIAL_H_CameraAssist
        local lk = ca and ca.Lock
        if not lk or not lk.LastPos or not lk.Character or not lk.Character.Parent then return nil end
        return lk
    end

    pcall(function()
        if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
            SILENT.Mode = "unavailable"
            return
        end
        local oldNamecall
        local ok = pcall(function()
            oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                if not SILENT.Active then return oldNamecall(self, ...) end
                if self ~= workspace then return oldNamecall(self, ...) end
                if checkcaller() then return oldNamecall(self, ...) end
                local method = getnamecallmethod()
                if method ~= "Raycast" and method ~= "FindPartOnRay"
                    and method ~= "findPartOnRay"
                    and method ~= "FindPartOnRayWithIgnoreList"
                    and method ~= "FindPartOnRayWithWhitelist" then
                    return oldNamecall(self, ...)
                end
                local args = table.pack(...)
                local ok2, result = pcall(function()
                    if self == workspace then
                        local lk = current_lock()
                        if lk then
                            if method == "Raycast" then
                                local origin = args[1]
                                local dir = args[2]
                                if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" then
                                    local mag = dir.Magnitude
                                    if mag < 0.01 then mag = 1000 end
                                    local newDir = (lk.LastPos - origin).Unit * mag
                                    SILENT.HitCount = SILENT.HitCount + 1
                                    return oldNamecall(self, origin, newDir, args[3])
                                end
                            elseif method == "FindPartOnRay" or method == "findPartOnRay"
                                or method == "FindPartOnRayWithIgnoreList"
                                or method == "FindPartOnRayWithWhitelist" then
                                local ray = args[1]
                                if typeof(ray) == "Ray" then
                                    local mag = ray.Direction.Magnitude
                                    if mag < 0.01 then mag = 1000 end
                                    local newRay = Ray.new(ray.Origin, (lk.LastPos - ray.Origin).Unit * mag)
                                    SILENT.HitCount = SILENT.HitCount + 1
                                    if method == "FindPartOnRay" or method == "findPartOnRay" then
                                        return oldNamecall(self, newRay, args[2])
                                    else
                                        return oldNamecall(self, newRay, args[2], args[3])
                                    end
                                end
                            end
                        end
                    end
                    return oldNamecall(self, table.unpack(args, 1, args.n))
                end)
                if ok2 then return result end
                return oldNamecall(self, table.unpack(args, 1, args.n))
            end))
        end)
        if ok and oldNamecall then SILENT.Mode = "namecall" end
    end)
end

local CamControls = _G.__CELESTIAL_H_CamControls
if not CamControls then
    pcall(function()
        local plr = game:GetService("Players").LocalPlayer
        if not plr then return end
        local ps = plr:FindFirstChild("PlayerScripts")
        if not ps then return end
        local pm = ps:FindFirstChild("PlayerModule")
        if not pm then return end
        local mod = require(pm)
        if mod and mod.GetControls then
            CamControls = mod:GetControls()
            _G.__CELESTIAL_H_CamControls = CamControls
        end
    end)
end

local HEAD_AIM_OFFSET = 0
local AIM_DEAD_ZONE = 0.08

local Configuration = {
    ConfigVersion = 109,
    VisualsEnabled = true, ShowBoxes = true, ShowNames = true, ShowHealth = true,
    ShowDistance = true, ShowSkeleton = false, SkeletonColor = "Purple",
    BoxColor = "Purple", NameColor = "White",
    BoxColorMap = {
        Purple = Color3.fromRGB(255, 45, 92), Red = Color3.fromRGB(255, 60, 60),
        Blue = Color3.fromRGB(99, 102, 241), Green = Color3.fromRGB(60, 220, 90),
        Yellow = Color3.fromRGB(255, 220, 60), White = Color3.fromRGB(245, 243, 255),
        Black = Color3.fromRGB(25, 25, 30), Cyan = Color3.fromRGB(80, 220, 240),
        Orange = Color3.fromRGB(255, 140, 60), Pink = Color3.fromRGB(255, 100, 200),
        Lime = Color3.fromRGB(120, 255, 120), Teal = Color3.fromRGB(60, 200, 180),
    },
    VisualsRateHz = 60, ViewmodelSyncEnabled = false,
    LocalPlayerHighlightEnabled = false, LocalPlayerGlowColor = "Purple",
    LocalPlayerOutlineColor = "White", LocalPlayerFillTransparency = 0.82,
    LocalPlayerOutlineTransparency = 0.05, LocalPlayerDepthMode = "Occluded",
    ViewmodelMaterial = "Neon", ViewmodelColor = "Purple",
    ViewmodelCameraArms = true,
    ViewmodelTransparency = 0, ViewmodelCastShadows = false,
    ViewmodelRainbow = false, ViewmodelRainbowSpeed = 0.35,
    -- Local-only cosmetic skin preview
    SkinChangerEnabled = false, SkinPreset = "Celestial", SkinMaterial = "SmoothPlastic",
    SkinAccentEnabled = true, SkinAccentColor = "Purple", SkinTransparency = 0,
    SkinRainbow = false, SkinRainbowSpeed = 0.3,
    -- Local BHOP trainer / movement HUD (no movement automation)
    BhopTrainerEnabled = false, BhopShowSpeed = true, BhopShowJumps = true,
    BhopShowTiming = true, BhopPerfectWindow = 0.18,
    ScreenFXEnabled = false, ScreenFXSaturation = 0.05, ScreenFXContrast = 0.08,
    ScreenFXBrightness = 0, ScreenFXBlurEnabled = false, ScreenFXBlurSize = 2,
    CameraAssistEnabled = false, CameraAssistAlwaysOn = false,
    CameraAssistUseMouseWhileLocking = true, CameraAssistFOV = 35,
    CameraAssistDrawFOV = false, CameraAssistFOVColor = "White",
    CameraAssistSmoothing = 8, CameraAssistHitbox = "Head",
    CameraAssistHitboxMode = "Head", CameraAssistVisibleCheck = false,
    CameraAssistAcquisitionRadius = 300, CameraAssistPrediction = true,
    CameraAssistBulletSpeed = 400, CameraAssistLead = 0.06,
    CameraAssistScopeSpeed = 1.0, CameraAssistPxPerDeg = 3.0,
    CameraAssistMouseSensitivity = 1.0,
    CameraAssistPlayerSens = 0.15, CameraAssistRotateChar = true,
    CameraAssistFOVPriority = true,
    ViewFOVEnabled = false, ViewFOV = 90, ViewFOVIgnoreScope = true,
    ShotFeedbackEnabled = true, ShotTracerEnabled = true, ShotTracerColor = "Cyan",
    ShotTracerLifetime = 0.10, ShotTracerThickness = 2, ShotMaxDistance = 1200,
    ShotMuzzleFlashEnabled = true, ShotMuzzleFlashDuration = 0.08,
    ShotHitmarkerEnabled = true, ShotHitmarkerDuration = 0.18,
    ShotDamageNumbersEnabled = true, ShotDamagePopupDuration = 0.75,
    ShotShowCounter = true, ShotShowFireRate = true,
    LobbyGuardEnabled = true, LobbyStateOverride = "Auto",
    WeaponAutoDetect = true, WeaponProfilesEnabled = true,
    ScaleWithViewport = true, TeamCheck = true,
    AutoFireEnabled = false, AutoFireDelay = 0.06, AutoFireVisibleCheck = true,
    AutoFireMaxDistance = 1000, AutoFireProximityFallback = true,
    AutoFireProximityAngle = 2.5, AutoFireAlwaysOn = true,
    AutoFireBindType = "Mouse", AutoFireKeyCode = Enum.KeyCode.V,
    AutoFireMouseButton = Enum.UserInputType.MouseButton2,
    FlyEnabled = false, FlySpeed = 50, FlyLockWeapon = true,
    SpeedEnabled = false, SpeedValue = 60, SpeedLockWeapon = true,
    NightVisionEnabled = false,
    HitboxExpanderEnabled = false, HitboxExpanderSize = 1.5,
    NoRecoilEnabled = false,
    AntiFlashEnabled = true, FPSBoostEnabled = false,
    AutoStopOnKatanaDeflect = false,
    AimControllerButton = Enum.KeyCode.ButtonL2,
    AutoFireControllerButton = Enum.KeyCode.ButtonR2,
    WatermarkEnabled = true, WatermarkShowVersion = true, WatermarkShowTime = true, WatermarkShowPlace = true,
    HUDEnabled = true, HUDShowFPS = true, HUDShowPing = true, HUDShowScriptName = true,
    HUDShowKeybinds = true, HUDShowSession = true, HUDShowPlayers = true, HUDShowExecutor = true, HUDShowGraph = true,
    HUDShowClock = true, HUDShowServer = true, HUDShowMemory = false, HUDShowStatus = true,
    HUDCompact = false, HUDKeybindsOnlyActive = false,
    MenuBindType = "Key", MenuKey = Enum.KeyCode.RightShift,
    MenuMouseButton = Enum.UserInputType.MouseButton3,
    AimBindType = "Mouse", AimMouseButton = Enum.UserInputType.MouseButton2,
    AimKeyCode = Enum.KeyCode.LeftShift,
    PlayerListUpdateInterval = 0.5, MaxRenderDistance = 1000,
    SilentAimEnabled = false, SilentAimHitChance = 100,
    SilentAimFOV = 200, SilentAimHitbox = "Head",
    SilentAimDrawFOV = false, SilentAimFOVColor = "Cyan",
    AimLockEnabled = false, RagebotEnabled = false,
    RapidFireEnabled = false, MaxAccuracyEnabled = false,
    NoSpreadEnabled = false, AntiKatanaEnabled = false, SpinbotEnabled = false,
    ESPTargetVisEnabled = false, ViewmodelChamsEnabled = false,
    SkyChangerEnabled = false, FlyNoclipEnabled = false, InfJumpEnabled = false,
    -- Celestial H world renderer
    WorldVisualsEnabled = false, WorldPreset = "Celestial",
    WorldBrightness = 2, WorldExposure = 0.15, WorldClockTime = 14,
    WorldFogStart = 0, WorldFogEnd = 100000, WorldAtmosphereDensity = 0.18,
    WorldBloomEnabled = true, WorldColorCorrectionEnabled = true,
    WorldSunRaysEnabled = true, WorldDepthOfFieldEnabled = false,
    WorldFullbright = false, WorldShadows = true,
    WorldCloudsEnabled = false, WorldCloudCover = 0.35, WorldCloudDensity = 0.4,
    WorldCloudSpeed = 0.2, WorldCloudColor = "White",
    SkyPreset = "Celestial", SkyStableLock = true,
    HitSoundsEnabled = false, HitSoundChoice = "Vine Boom",
    HitSoundVolume = 0.5, HitSoundPitch = 1.0, HitSoundRandomPitch = 0.06,
    HitSoundPreviewOnSelect = false,
    -- GUI art / typography
    AnimeImageEnabled = true, AnimeImageId = "151001200", AnimeImageTransparency = 0.00, AnimeImageScale = "Fit",
    AnimeImageTitle = "CELESTIAL H", AnimeImageSubtitle = "THE SKY IS NOT THE LIMIT",
    UIFontBody = "GothamMedium", UIHeaderFont = "GothamBlack", UIAnimations = true,
    -- Local network telemetry (display only)
    NetworkMonitorEnabled = true, NetworkShowPing = true, NetworkShowJitter = true,
    HitSoundMap = {
        ["Vine Boom"] = "rbxassetid://6308606116",
        ["Mega Knight"] = "rbxassetid://1310127925561718",
        ["MLG Airhorn"] = "rbxassetid://678089961",
        ["Boom Headshot"] = "rbxassetid://7361085557",
        ["Taco Bell"] = "rbxassetid://5556082054",
        ["Anime SFX"] = "rbxassetid://78798011197804",
        ["Loud Anime"] = "rbxassetid://123530243268842",
        ["Hit Sound"] = "rbxassetid://97089699783241",
        ["Hit Punch"] = "rbxassetid://95379226925924",
        ["Hit Effect"] = "rbxassetid://5215573213",
        ["Hit SFX 2"] = "rbxassetid://105811443736029",
        ["Hit-Sound"] = "rbxassetid://118784328176572",
    },
    CustomCrosshairEnabled = false,
    AntibanEnabled = false, DeviceSpooferEnabled = false,
    IsPremium = false, PremiumTier = nil, PremiumExpiry = 0, PremiumKey = nil,
}

local ExecutorInfo = {
    Name = "Unknown",
    HasGethui = type(gethui) == "function",
    HasWritefile = type(writefile) == "function",
    HasReadfile = type(readfile) == "function",
    HasMakeFolder = type(makefolder) == "function",
    HasMouse1Click = type(mouse1click) == "function",
    HasMouse1Press = type(mouse1press) == "function" and type(mouse1release) == "function",
    HasKeyPress = type(keypress) == "function" and type(keyrelease) == "function",
    HasVIM = pcall(function() return game:GetService("VirtualInputManager") end),
}
pcall(function()
    if type(identifyexecutor) == "function" then
        local n = identifyexecutor()
        if n and n ~= "" then ExecutorInfo.Name = tostring(n) end
    end
end)

local function safeGuiParent()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
end

local Popup = {}
Popup.Active = nil
function Popup.Show(text, ok)
    local par = safeGuiParent()
    if not par then return end
    if Popup.Active and Popup.Active.Parent then pcall(function() Popup.Active:Destroy() end) end
    local sg = Instance.new("ScreenGui")
    sg.Name = "CELESTIAL_H_Popup" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true sg.DisplayOrder = 500
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg.Parent = par end)
    Popup.Active = sg
    local accent = ok and Color3.fromRGB(80, 220, 130) or Color3.fromRGB(255, 80, 100)
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0.5, 0) box.Position = UDim2.new(0.5, 0, 0, -80)
    box.Size = UDim2.fromOffset(340, 62) box.BackgroundColor3 = Color3.fromRGB(14, 12, 22)
    box.BackgroundTransparency = 0.03 box.BorderSizePixel = 0 box.Parent = sg
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = box
    local st = Instance.new("UIStroke") st.Color = accent st.Thickness = 1.5 st.Transparency = 0.15 st.Parent = box
    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(0, 4, 1, -18) stripe.Position = UDim2.new(0, 6, 0, 9)
    stripe.BackgroundColor3 = accent stripe.BorderSizePixel = 0 stripe.Parent = box
    local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 2) sc.Parent = stripe
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.fromOffset(30, 30) icon.Position = UDim2.new(0, 22, 0.5, -15)
    icon.BackgroundColor3 = accent icon.BackgroundTransparency = 0.82
    icon.BorderSizePixel = 0 icon.Font = Enum.Font.GothamBlack icon.TextSize = 18
    icon.TextColor3 = accent icon.Text = ok and "\226\156\147" or "\226\156\149" icon.Parent = box
    local ic = Instance.new("UICorner") ic.CornerRadius = UDim.new(1, 0) ic.Parent = icon
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -74, 1, 0) lbl.Position = UDim2.new(0, 62, 0, 0)
    lbl.BackgroundTransparency = 1 lbl.Font = Enum.Font.GothamBold lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(245, 243, 255) lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center lbl.TextWrapped = true lbl.Text = text lbl.Parent = box
    local T = game:GetService("TweenService")
    T:Create(box, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 24)}):Play()
    task.delay(ok and 2.4 or 3.0, function()
        T:Create(box, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -80)}):Play()
        T:Create(lbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        T:Create(icon, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        T:Create(st, TweenInfo.new(0.3), {Transparency = 1}):Play()
        T:Create(stripe, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.delay(0.5, function() pcall(function() sg:Destroy() end) end)
    end)
end

local KeySystem = {}
KeySystem.Authorized = false
KeySystem.ScreenGui = nil
KeySystem.KeyLink = "https://work.ink/2YDv/key-system"
KeySystem.DefaultExpiry = 24 * 60 * 60
KeySystem.PremiumTiers = {
    ["week"] = { name = "1 Week", seconds = 7 * 24 * 60 * 60 },
    ["month"] = { name = "1 Month", seconds = 30 * 24 * 60 * 60 },
    ["3month"] = { name = "3 Months", seconds = 90 * 24 * 60 * 60 },
}
KeySystem.PremiumWhitelist = {
    ["W-CELESTIAL_H-XK9M2A"] = "week", ["W-CELESTIAL_H-PL4N7B"] = "week", ["W-CELESTIAL_H-QR8T1C"] = "week",
    ["M-CELESTIAL_H-ZW3F6D"] = "month", ["M-CELESTIAL_H-HJ9K4E"] = "month", ["M-CELESTIAL_H-BN2M8F"] = "month",
    ["Q-CELESTIAL_H-VC5X1G"] = "3month", ["Q-CELESTIAL_H-RT7Y3H"] = "3month", ["Q-CELESTIAL_H-LM4Z9J"] = "3month",
}
function KeySystem.DetectTier(key)
    if not key or key == "" then return nil end
    local upper = key:upper():gsub("^%s+", ""):gsub("%s+$", "")
    local tier = KeySystem.PremiumWhitelist[upper]
    if tier then return tier, KeySystem.PremiumTiers[tier] end
    return nil
end
function KeySystem.CheckPremiumBinding(key, hwid)
    if not key or not hwid or hwid == "" then return true end
    if not ExecutorInfo.HasReadfile or not ExecutorInfo.HasWritefile then return true end
    if ExecutorInfo.HasMakeFolder then pcall(makefolder, "CELESTIAL_H") end
    local path = "CELESTIAL_H/PremiumBindings.json"
    local raw = nil
    for _, p in ipairs({"CELESTIAL_H/PremiumBindings.json", "CELESTIAL_H_PremiumBindings.json"}) do
        local ok, d = pcall(readfile, p)
        if ok and d and d ~= "" then raw = d path = p break end
    end
    local map = {}
    if raw then
        local okd, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
        if okd and type(decoded) == "table" then map = decoded end
    end
    map[key] = hwid
    pcall(function() writefile(path, HttpService:JSONEncode(map)) end)
    return true
end
local function ksHttpGet(url)
    if type(request) == "function" then
        local ok, res = pcall(request, { Url = url, Method = "GET" })
        if ok and res then return res end
    end
    if type(http_request) == "function" then
        local ok, res = pcall(http_request, { Url = url, Method = "GET" })
        if ok and res then return res end
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        local ok, res = pcall(syn.request, { Url = url, Method = "GET" })
        if ok and res then return res end
    end
    return nil
end
function KeySystem.Validate(key)
    key = tostring(key or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if #key < 6 then return false, "too-short" end
    local tier, info = KeySystem.DetectTier(key)
    if tier then
        local hwid = getgenv().CELESTIAL_H_HWID
        if not hwid then
            pcall(function()
                if type(get_hwid) == "function" then hwid = get_hwid() end
                if not hwid and type(gethwid) == "function" then hwid = gethwid() end
            end)
        end
        if hwid then KeySystem.CheckPremiumBinding(key:upper(), tostring(hwid)) end
        getgenv().SCRIPT_KEY = key
        Configuration.IsPremium = true
        Configuration.PremiumTier = info.name
        Configuration.PremiumExpiry = os.time() + info.seconds
        Configuration.PremiumKey = key
        return true, "premium:" .. info.name
    end
    local url = "https://work.ink/_api/v2/token/isValid/" .. key
    local res = ksHttpGet(url)
    if not res then return false, "http-unavailable" end
    local body = res.Body or res.body or ""
    if body == "" then return false, "empty-response" end
    local decoded
    local ok = pcall(function() decoded = HttpService:JSONDecode(body) end)
    if not ok or type(decoded) ~= "table" then return false, "bad-response" end
    if decoded.valid == true then
        getgenv().SCRIPT_KEY = key
        Configuration.IsPremium = false
        Configuration.PremiumTier = nil
        Configuration.PremiumExpiry = 0
        return true, "valid"
    end
    return false, tostring(decoded.error or "invalid")
end
function KeySystem.ReadSaved()
    if not ExecutorInfo.HasReadfile then return nil, nil end
    for _, p in ipairs({"CELESTIAL_H/Key.txt", "CELESTIAL_H_Key.txt"}) do
        local ok, d = pcall(readfile, p)
        if ok and d and d ~= "" then
            local key, ts = d:match("^([^|]+)|(%d+)$")
            if key and ts then return key, tonumber(ts) end
        end
    end
    return nil, nil
end
function KeySystem.WriteSaved(key, expiry)
    if not ExecutorInfo.HasWritefile then return false end
    if ExecutorInfo.HasMakeFolder then pcall(makefolder, "CELESTIAL_H") end
    local payload = tostring(key) .. "|" .. tostring(expiry)
    for _, p in ipairs({"CELESTIAL_H/Key.txt", "CELESTIAL_H_Key.txt"}) do
        if pcall(writefile, p, payload) then return true end
    end
    return false
end
function KeySystem.ClearSaved()
    if not ExecutorInfo.HasWritefile then return end
    for _, p in ipairs({"CELESTIAL_H/Key.txt", "CELESTIAL_H_Key.txt"}) do pcall(writefile, p, "") end
end

local function buildKeyUI(onAuthorized)
    local par = safeGuiParent()
    if not par then return nil end
    local T = game:GetService("TweenService")
    local sg = Instance.new("ScreenGui")
    sg.Name = "CELESTIAL_H_KeyUI" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true sg.DisplayOrder = 400
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg.Parent = par end)
    KeySystem.ScreenGui = sg
    local bd = Instance.new("Frame")
    bd.Size = UDim2.fromScale(1, 1) bd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bd.BackgroundTransparency = 0.4 bd.BorderSizePixel = 0 bd.ZIndex = 1 bd.Parent = sg
    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(360, 350) panel.BackgroundColor3 = Color3.fromRGB(15, 12, 24)
    panel.BorderSizePixel = 0 panel.ZIndex = 10 panel.Parent = sg
    local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(0, 16) pc.Parent = panel
    local ps = Instance.new("UIStroke") ps.Color = Color3.fromRGB(60, 50, 100) ps.Thickness = 1.5 ps.Transparency = 0.2 ps.Parent = panel
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 0, 52) logo.Position = UDim2.new(0, 0, 0, 20)
    logo.BackgroundTransparency = 1 logo.Font = Enum.Font.GothamBlack logo.Text = "CELESTIAL H"
    logo.TextSize = 42 logo.TextColor3 = Color3.fromRGB(255, 255, 255) logo.ZIndex = 11 logo.Parent = panel
    local lg = Instance.new("UIGradient")
    lg.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 190, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 100, 250)), ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 130, 245)) }
    lg.Parent = logo
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 16) sub.Position = UDim2.new(0, 0, 0, 76)
    sub.BackgroundTransparency = 1 sub.Font = Enum.Font.GothamBold
    sub.Text = "C E L E S T I A L   H   S U I T E" sub.TextSize = 9
    sub.TextColor3 = Color3.fromRGB(255, 135, 165) sub.ZIndex = 11 sub.Parent = panel
    local field = Instance.new("Frame")
    field.Size = UDim2.new(1, -60, 0, 46) field.Position = UDim2.new(0, 30, 0, 132)
    field.BackgroundColor3 = Color3.fromRGB(22, 18, 34) field.BorderSizePixel = 0 field.ZIndex = 11 field.Parent = panel
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 10) fc.Parent = field
    local fst = Instance.new("UIStroke") fst.Color = Color3.fromRGB(60, 50, 100) fst.Thickness = 1.5 fst.Parent = field
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -24, 1, 0) input.Position = UDim2.new(0, 12, 0, 0)
    input.BackgroundTransparency = 1 input.Font = Enum.Font.GothamMedium
    input.TextSize = 14 input.TextColor3 = Color3.fromRGB(245, 243, 255)
    input.PlaceholderText = "W-CELESTIAL_H-XXXXX or work.ink key"
    input.PlaceholderColor3 = Color3.fromRGB(110, 110, 130) input.Text = ""
    input.ClearTextOnFocus = false input.TextXAlignment = Enum.TextXAlignment.Left
    input.ZIndex = 12 input.Parent = field
    KeySystem.Input = input
    input.Focused:Connect(function() T:Create(fst, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 45, 92), Transparency = 0}):Play() end)
    input.FocusLost:Connect(function() T:Create(fst, TweenInfo.new(0.2), {Color = Color3.fromRGB(60, 50, 100), Transparency = 0}):Play() end)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -60, 0, 44) btn.Position = UDim2.new(0, 30, 0, 190)
    btn.BackgroundColor3 = Color3.fromRGB(255, 45, 92) btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold btn.Text = "Validate Key" btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255) btn.AutoButtonColor = false
    btn.ZIndex = 11 btn.Parent = panel
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 10) bc.Parent = btn
    local gk = Instance.new("TextButton")
    gk.Size = UDim2.new(1, -60, 0, 30) gk.Position = UDim2.new(0, 30, 0, 246)
    gk.BackgroundColor3 = Color3.fromRGB(22, 18, 34) gk.BorderSizePixel = 0
    gk.Font = Enum.Font.GothamBold gk.Text = "Get a Key  \226\134\146" gk.TextSize = 11
    gk.TextColor3 = Color3.fromRGB(255, 135, 165) gk.AutoButtonColor = false
    gk.ZIndex = 11 gk.Parent = panel
    local gkc = Instance.new("UICorner") gkc.CornerRadius = UDim.new(0, 8) gkc.Parent = gk
    gk.MouseButton1Click:Connect(function()
        if type(setclipboard) == "function" then
            pcall(setclipboard, KeySystem.KeyLink)
            gk.Text = "Link copied!"
            task.delay(1.5, function() if gk.Parent then gk.Text = "Get a Key  \226\134\146" end end)
        else gk.Text = KeySystem.KeyLink end
    end)
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -60, 0, 16) status.Position = UDim2.new(0, 30, 0, 286)
    status.BackgroundTransparency = 1 status.Font = Enum.Font.GothamMedium
    status.Text = "" status.TextSize = 10 status.TextColor3 = Color3.fromRGB(161, 161, 170)
    status.ZIndex = 11 status.Parent = panel
    local disc = Instance.new("TextLabel")
    disc.Size = UDim2.new(1, -60, 0, 16) disc.Position = UDim2.new(0, 30, 0, 308)
    disc.BackgroundTransparency = 1 disc.Font = Enum.Font.GothamMedium
    disc.Text = "Support / Bug Reports: discord.gg/K3vgcVsCsS" disc.TextSize = 10
    disc.TextColor3 = Color3.fromRGB(90, 100, 200) disc.ZIndex = 11 disc.Parent = panel
    local panelScale = Instance.new("UIScale")
    panelScale.Scale = 0.85 panelScale.Parent = panel
    panel.BackgroundTransparency = 1
    T:Create(panelScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    T:Create(panel, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
    local validating = false
    local function tryValidate()
        if validating then return end
        local key = tostring(input.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then Popup.Show("Enter a key first", false) return end
        validating = true
        btn.Text = "Validating..."
        status.Text = "Checking..."
        status.TextColor3 = Color3.fromRGB(255, 135, 165)
        task.spawn(function()
            local ok = false
            local reason = "invalid"
            local okc, r1, r2 = pcall(KeySystem.Validate, key)
            if okc then ok = r1 and true or false reason = r2 or reason else reason = "exception" end
            task.wait(0.3)
            validating = false
            btn.Text = "Validate Key"
            if ok then
                local expiry = Configuration.IsPremium and Configuration.PremiumExpiry or (os.time() + KeySystem.DefaultExpiry)
                KeySystem.WriteSaved(key, expiry)
                if Configuration.IsPremium then
                    status.Text = "Premium active: " .. tostring(Configuration.PremiumTier)
                    status.TextColor3 = Color3.fromRGB(255, 200, 40)
                    Popup.Show("\226\152\133 Premium activated - " .. tostring(Configuration.PremiumTier), true)
                else
                    status.Text = "Key valid - 24h access"
                    status.TextColor3 = Color3.fromRGB(80, 220, 130)
                    Popup.Show("Key valid - welcome", true)
                end
                task.wait(1.9)
                T:Create(bd, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
                for _, ch in ipairs(panel:GetDescendants()) do
                    if ch:IsA("TextLabel") or ch:IsA("TextBox") then T:Create(ch, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                    elseif ch:IsA("TextButton") then T:Create(ch, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
                    elseif ch:IsA("Frame") then T:Create(ch, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
                    elseif ch:IsA("UIStroke") then T:Create(ch, TweenInfo.new(0.3), {Transparency = 1}):Play() end
                end
                task.wait(0.5)
                pcall(function() sg:Destroy() end)
                KeySystem.Authorized = true
                if onAuthorized then pcall(onAuthorized) end
            else
                local msg = "Key doesn't exist"
                if reason == "http-unavailable" then msg = "Executor has no HTTP access"
                elseif reason == "bad-response" then msg = "Server rejected the request"
                elseif reason == "empty-response" then msg = "Server returned empty"
                elseif reason == "too-short" then msg = "Key is too short" end
                status.Text = msg
                status.TextColor3 = Color3.fromRGB(255, 80, 100)
                Popup.Show(msg, false)
                input.Text = ""
            end
        end)
    end
    btn.MouseButton1Click:Connect(tryValidate)
    input.FocusLost:Connect(function(enter) if enter then tryValidate() end end)
    btn.MouseEnter:Connect(function() T:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 135, 165)}):Play() end)
    btn.MouseLeave:Connect(function() T:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 45, 92)}):Play() end)
    return sg
end

local function makeScreenGui(name, order, ii)
    local par = safeGuiParent()
    if not par then return nil end
    local sg = Instance.new("ScreenGui")
    sg.Name = name sg.ResetOnSpawn = false sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = order or 1 sg.IgnoreGuiInset = ii ~= false
    pcall(function() sg.AutoLocalize = false end)
    pcall(function() sg.Parent = par end)
    return sg
end

local WeaponProfiles = {}
local ActiveWeaponName = "Default"

local PER_WEAPON_SETTINGS = {
    "CameraAssistSmoothing", "CameraAssistFOV",
    "CameraAssistMouseSensitivity", "CameraAssistPrediction", "CameraAssistBulletSpeed",
    "CameraAssistLead", "CameraAssistPlayerSens",
}
local function defaultProfiles()
    return {
        Default = {CameraAssistSmoothing=8, CameraAssistFOV=35, CameraAssistMouseSensitivity=1.0, CameraAssistPrediction=true, CameraAssistBulletSpeed=400, CameraAssistLead=0.06, CameraAssistPlayerSens=0.15},
        AR = {CameraAssistSmoothing=7, CameraAssistFOV=35, CameraAssistMouseSensitivity=1.0, CameraAssistPrediction=true, CameraAssistBulletSpeed=500, CameraAssistLead=0.06, CameraAssistPlayerSens=0.15},
        Sniper = {CameraAssistSmoothing=4, CameraAssistFOV=18, CameraAssistMouseSensitivity=0.8, CameraAssistPrediction=false, CameraAssistBulletSpeed=800, CameraAssistLead=0.02, CameraAssistPlayerSens=0.15},
        Shotgun = {CameraAssistSmoothing=5, CameraAssistFOV=55, CameraAssistMouseSensitivity=1.2, CameraAssistPrediction=false, CameraAssistBulletSpeed=250, CameraAssistLead=0.02, CameraAssistPlayerSens=0.15},
        SMG = {CameraAssistSmoothing=6, CameraAssistFOV=45, CameraAssistMouseSensitivity=1.0, CameraAssistPrediction=true, CameraAssistBulletSpeed=450, CameraAssistLead=0.05, CameraAssistPlayerSens=0.15},
        Pistol = {CameraAssistSmoothing=6, CameraAssistFOV=45, CameraAssistMouseSensitivity=1.0, CameraAssistPrediction=false, CameraAssistBulletSpeed=350, CameraAssistLead=0.03, CameraAssistPlayerSens=0.15},
        Melee = {},
    }
end
WeaponProfiles = defaultProfiles()

local function classifyWeaponName(name)
    if not name or name == "" then return "Default" end
    local n = name:lower()
    if n:find("knife") or n:find("melee") or n:find("sword") or n:find("bat") or n:find("hammer") or n:find("fist") or n:find("karambit") or n:find("cutlass") or n:find("katana") then return "Melee" end
    if n:find("sniper") or n:find("awp") or n:find("barrett") or n:find("hunt") or n:find("ranger") or n:find("longshot") then return "Sniper" end
    if n:find("shotgun") or n:find("judge") or n:find("spas") or n:find("pump") or n:find("double") then return "Shotgun" end
    if n:find("smg") or n:find("uzi") or n:find("mp5") or n:find("mp7") or n:find("vector") or n:find("mac") then return "SMG" end
    if n:find("pistol") or n:find("glock") or n:find("deagle") or n:find("revolver") or n:find("handgun") then return "Pistol" end
    if n:find("rifle") or n:find("scar") or n:find("ak") or n:find("m4") or n:find("m16") or n:find("fal") or n:find("burst") or n:find("auto") then return "AR" end
    return "Default"
end

local function detectWeapon()
    local lp = game:GetService("Players").LocalPlayer
    if not lp then return "Default", nil end
    local char = lp.Character
    if not char or not char.Parent then return "Default", nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool.Name and tool.Name ~= "" then return classifyWeaponName(tool.Name), tool.Name end
    return "Default", nil
end

local function applyProfile(pn)
    local prof = WeaponProfiles[pn] or WeaponProfiles.Default
    if not prof then return end
    if Configuration.SilentAimEnabled then return end
    for _, k in ipairs(PER_WEAPON_SETTINGS) do if prof[k] ~= nil then Configuration[k] = prof[k] end end
    Configuration.CameraAssistPlayerSens = 0.15
    Configuration.CameraAssistRotateChar = true
end

local function saveActiveProfile()
    local prof = WeaponProfiles[ActiveWeaponName]
    if not prof then prof = {} WeaponProfiles[ActiveWeaponName] = prof end
    for _, k in ipairs(PER_WEAPON_SETTINGS) do prof[k] = Configuration[k] end
end

local ENUM_KEYCODES = { MenuKey = true, AimKeyCode = true, AutoFireKeyCode = true, AimControllerButton = true, AutoFireControllerButton = true }
local ENUM_UITYPES = { MenuMouseButton = true, AimMouseButton = true, AutoFireMouseButton = true }
local LOAD_EXCLUDE = { FlyEnabled = true, SpeedEnabled = true, ViewmodelSyncEnabled = true, CameraAssistPlayerSens = true, CameraAssistRotateChar = true }

function Configuration:Save()
    if not ExecutorInfo.HasWritefile then return false end
    saveActiveProfile()
    local payload = {}
    for k, v in pairs(self) do
        if k == "BoxColorMap" or k == "HitSoundMap" then
        elseif k == "Save" or k == "Load" then
        elseif ENUM_KEYCODES[k] or ENUM_UITYPES[k] then
            if typeof(v) == "EnumItem" then payload[k] = tostring(v) end
        elseif typeof(v) == "Color3" then payload[k] = {r = v.R, g = v.G, b = v.B}
        else payload[k] = v end
    end
    local data
    local ok = pcall(function() data = HttpService:JSONEncode(payload) end)
    if not ok or not data then return false end
    local wrote = false
    for _, c in ipairs({{folder="CELESTIAL_H", file="CELESTIAL_H/Config.json"}, {folder=nil, file="CELESTIAL_H_Config.json"}}) do
        if c.folder and ExecutorInfo.HasMakeFolder then pcall(makefolder, c.folder) end
        if pcall(writefile, c.file, data) then wrote = true break end
    end
    local wpdata
    local ok2 = pcall(function() wpdata = HttpService:JSONEncode(WeaponProfiles) end)
    if ok2 and wpdata then
        for _, c in ipairs({{folder="CELESTIAL_H", file="CELESTIAL_H/Weapons.json"}, {folder=nil, file="CELESTIAL_H_Weapons.json"}}) do
            if pcall(writefile, c.file, wpdata) then break end
        end
    end
    return wrote
end

function Configuration:Load()
    if not ExecutorInfo.HasReadfile then return false end
    local data
    for _, p in ipairs({"CELESTIAL_H/Config.json", "CELESTIAL_H_Config.json"}) do
        local ok, d = pcall(readfile, p)
        if ok and d then data = d break end
    end
    if data then
        local decoded
        local ok = pcall(function() decoded = HttpService:JSONDecode(data) end)
        if ok and type(decoded) == "table" then
            for k, v in pairs(decoded) do
                if not LOAD_EXCLUDE[k] and self[k] ~= nil and k ~= "HitSoundMap" then
                    if ENUM_KEYCODES[k] and typeof(v) == "string" then
                        local name = v:gsub("Enum%.[%w_]+%.", "")
                        local ok2, enum = pcall(function() return Enum.KeyCode[name] end)
                        if ok2 and enum then self[k] = enum end
                    elseif ENUM_UITYPES[k] and typeof(v) == "string" then
                        local name = v:gsub("Enum%.[%w_]+%.", "")
                        local ok2, enum = pcall(function() return Enum.UserInputType[name] end)
                        if ok2 and enum then self[k] = enum end
                    elseif type(v) == "table" and v.r and v.g and v.b then
                        self[k] = Color3.new(v.r, v.g, v.b)
                    else self[k] = v end
                end
            end
        end
    end
    local wpdata
    for _, p in ipairs({"CELESTIAL_H/Weapons.json", "CELESTIAL_H_Weapons.json"}) do
        local ok, d = pcall(readfile, p)
        if ok and d and d ~= "" then wpdata = d break end
    end
    if wpdata then
        local decoded
        local ok = pcall(function() decoded = HttpService:JSONDecode(wpdata) end)
        if ok and type(decoded) == "table" then
            for cat, profile in pairs(decoded) do
                if type(profile) == "table" then
                    WeaponProfiles[cat] = WeaponProfiles[cat] or {}
                    for k, v in pairs(profile) do WeaponProfiles[cat][k] = v end
                end
            end
        end
    end
    self.AutoStopOnKatanaDeflect = false
    self.CameraAssistVisibleCheck = false
    self.CameraAssistPlayerSens = 0.15
    self.CameraAssistRotateChar = true
    if type(self.AnimeImageId) ~= "string" or not self.AnimeImageId:match("%d+") then
        self.AnimeImageId = "151001200"
    end
    if self.AnimeImageEnabled == nil then self.AnimeImageEnabled = true end
    self.AnimeImageTransparency = math.clamp(tonumber(self.AnimeImageTransparency) or 0, 0, 1)
    if self.AnimeImageScale ~= "Stretch" then self.AnimeImageScale = "Fit" end
    self.ViewmodelSyncEnabled = false
    self.FlyEnabled = false
    self.SpeedEnabled = false
    self.CameraAssistPrediction = true
    self.FlySpeed = math.clamp(tonumber(self.FlySpeed) or 50, 10, 80)
    self.SpeedValue = math.clamp(tonumber(self.SpeedValue) or 60, 16, 500)
    self.LocalPlayerFillTransparency = math.clamp(tonumber(self.LocalPlayerFillTransparency) or 0.82, 0, 1)
    self.LocalPlayerOutlineTransparency = math.clamp(tonumber(self.LocalPlayerOutlineTransparency) or 0.05, 0, 1)
    self.ViewmodelTransparency = math.clamp(tonumber(self.ViewmodelTransparency) or 0, 0, 1)
    self.ViewmodelRainbowSpeed = math.clamp(tonumber(self.ViewmodelRainbowSpeed) or 0.35, 0.05, 2)
    self.WorldCloudCover = math.clamp(tonumber(self.WorldCloudCover) or 0.35, 0, 1)
    self.WorldCloudDensity = math.clamp(tonumber(self.WorldCloudDensity) or 0.4, 0, 1)
    self.WorldCloudSpeed = math.clamp(tonumber(self.WorldCloudSpeed) or 0.2, 0, 10)
    self.ScreenFXSaturation = math.clamp(tonumber(self.ScreenFXSaturation) or 0.05, -1, 1)
    self.ScreenFXContrast = math.clamp(tonumber(self.ScreenFXContrast) or 0.08, -1, 1)
    self.ScreenFXBrightness = math.clamp(tonumber(self.ScreenFXBrightness) or 0, -1, 1)
    self.ScreenFXBlurSize = math.clamp(tonumber(self.ScreenFXBlurSize) or 2, 0, 24)
    self.ViewFOV = math.clamp(tonumber(self.ViewFOV) or 90, 60, 140)
    self.HitSoundVolume = math.clamp(tonumber(self.HitSoundVolume) or 0.5, 0, 1)
    self.HitSoundPitch = math.clamp(tonumber(self.HitSoundPitch) or 1.0, 0.5, 2.0)
    self.HitSoundRandomPitch = math.clamp(tonumber(self.HitSoundRandomPitch) or 0.06, 0, 0.25)
    self.ShotTracerLifetime = math.clamp(tonumber(self.ShotTracerLifetime) or 0.10, 0.03, 0.5)
    self.ShotTracerThickness = math.clamp(tonumber(self.ShotTracerThickness) or 2, 1, 6)
    self.ShotMaxDistance = math.clamp(tonumber(self.ShotMaxDistance) or 1200, 100, 5000)
    self.ShotMuzzleFlashDuration = math.clamp(tonumber(self.ShotMuzzleFlashDuration) or 0.08, 0.03, 0.3)
    self.ShotHitmarkerDuration = math.clamp(tonumber(self.ShotHitmarkerDuration) or 0.18, 0.05, 0.6)
    self.ShotDamagePopupDuration = math.clamp(tonumber(self.ShotDamagePopupDuration) or 0.75, 0.2, 2.0)
    return true
end

local Connections = {}
function Connections.Track(c) if c then table.insert(Connections, c) end return c end
function Connections.DisconnectAll()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
end

local Utility = {}
Utility.Players = game:GetService("Players")
Utility.RunService = game:GetService("RunService")
Utility.UserInputService = UIS
Utility.Workspace = game:GetService("Workspace")
Utility.VisibleCache = {}
Utility.VisibleCacheTimestamps = {}
Utility.VisibleCacheDuration = 0.02
Utility.MinRayDist = 0.1
Utility.RecentMaxFOV = 70
Utility.RecentMaxFOVTime = 0
Utility.TeamCache = {}
Utility.TeamCacheTime = {}
Utility.TeamCacheDuration = 0.15
Utility.RaycastParams = RaycastParams.new()
Utility.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
Utility.RaycastParams.IgnoreWater = true
Utility.LobbyCache = nil
Utility.LobbyCacheTime = 0
Utility.LobbyCacheDuration = 0.25
Utility._hbpCache = setmetatable({}, {__mode = "k"})

Utility.HitboxNamePatterns = {
    HitboxHead=true, HitboxHeadSmall=true, PhysicalHitboxHead=true,
    HitboxBody=true, HitboxBodySmall=true,
    Head=true, UpperTorso=true, LowerTorso=true, HumanoidRootPart=true, Torso=true,
    LeftUpperArm=true, RightUpperArm=true, LeftLowerArm=true, RightLowerArm=true,
    LeftUpperLeg=true, RightUpperLeg=true, LeftLowerLeg=true, RightLowerLeg=true,
    LeftFoot=true, RightFoot=true, LeftHand=true, RightHand=true,
}
Utility.HitboxModes = {}
Utility.HitboxModes.Head = {"Head", "HitboxHead", "PhysicalHitboxHead", "HitboxHeadSmall"}
Utility.HitboxModes.UpperTorso = {"HitboxBody", "HitboxBodySmall", "UpperTorso", "Torso", "HumanoidRootPart"}
Utility.HitboxModes.Chest = {"HitboxBody", "HitboxBodySmall", "UpperTorso", "Torso", "HumanoidRootPart"}
Utility.HitboxModes.LowerTorso = {"LowerTorso", "Torso", "HitboxBody", "HitboxBodySmall", "HumanoidRootPart"}
Utility.DeflectCache = {}
Utility.DeflectCacheTime = {}
Utility.DeflectCacheDuration = 0.016

function Utility.GetCamera() return Utility.Workspace.CurrentCamera end
function Utility.ViewportScale()
    if not Configuration.ScaleWithViewport then return 1 end
    local c = Utility.GetCamera()
    if not c then return 1 end
    local v = c.ViewportSize
    if not v or v.Y <= 0 then return 1 end
    return v.Y / 1080
end
function Utility.IsValidNumber(n) return n == n and n ~= math.huge and n ~= -math.huge end
function Utility.IsValidVector(v)
    if not v then return false end
    return Utility.IsValidNumber(v.X) and Utility.IsValidNumber(v.Y) and Utility.IsValidNumber(v.Z)
end
function Utility.WorldToViewport(pos)
    local c = Utility.GetCamera()
    if not c or not c.Parent then return Vector2.new(0, 0), false, 0 end
    local ok, r = pcall(function() return c:WorldToViewportPoint(pos) end)
    if not ok or not r then return Vector2.new(0, 0), false, 0 end
    if not Utility.IsValidNumber(r.X) or not Utility.IsValidNumber(r.Y) then return Vector2.new(0, 0), false, 0 end
    return Vector2.new(r.X, r.Y), r.Z > 0, r.Z
end
function Utility.IsLocalAirborne()
    local lp = Utility.Players.LocalPlayer
    if not lp or not lp.Character then return false end
    local h = lp.Character:FindFirstChildOfClass("Humanoid")
    if not h then return false end
    local s = h:GetState()
    if s == Enum.HumanoidStateType.Jumping then return true end
    if s == Enum.HumanoidStateType.Freefall then return true end
    if s == Enum.HumanoidStateType.FallingDown then return true end
    if s == Enum.HumanoidStateType.PlatformStanding then return true end
    return false
end
function Utility.GetPlayerTeam(p)
    if not p then return nil end
    local t = nil
    pcall(function() t = p.Team end)
    if t then return t end
    local now = tick()
    if Utility.TeamCacheTime[p] and (now - Utility.TeamCacheTime[p]) < Utility.TeamCacheDuration then return Utility.TeamCache[p] end
    local res = nil
    pcall(function()
        local a = p:GetAttributes()
        for n, v in pairs(a) do
            local l = n:lower()
            if l == "team" or l == "teamid" or l == "teamidentifier" or l == "teamindex" or l:find("teamid") then res = v break end
        end
    end)
    if not res and p.Character then
        pcall(function()
            local a = p.Character:GetAttributes()
            for n, v in pairs(a) do
                local l = n:lower()
                if l == "team" or l == "teamid" or l == "teamidentifier" or l == "teamindex" or l:find("teamid") then res = v break end
            end
        end)
    end
    Utility.TeamCache[p] = res
    Utility.TeamCacheTime[p] = now
    return res
end
function Utility.ClearTeamCache(p)
    Utility.TeamCache[p] = nil Utility.TeamCacheTime[p] = nil
    Utility._vpCacheTick = 0
end
function Utility.IsEnemy(a, b)
    if not a or not b then return true end
    if not Configuration.TeamCheck then return true end
    local ta = Utility.GetPlayerTeam(a)
    local tb = Utility.GetPlayerTeam(b)
    if ta == nil or tb == nil then return true end
    if typeof(ta) == "Instance" and typeof(tb) == "Instance" then return ta ~= tb end
    return tostring(ta) ~= tostring(tb)
end
Utility._vpCache = {}
Utility._vpCacheTick = 0
function Utility.GetValidPlayers()
    local t = tick()
    if (t - Utility._vpCacheTick) < 0.05 then return Utility._vpCache end
    Utility._vpCacheTick = t
    local ps = Utility._vpCache
    table.clear(ps)
    local lp = Utility.Players.LocalPlayer
    if not lp then return ps end
    for _, p in ipairs(Utility.Players:GetPlayers()) do
        if p ~= lp and Utility.IsEnemy(lp, p) then
            local c = p.Character
            if c and c.Parent then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then
                    local hd = c:FindFirstChild("Head")
                    local rt = c:FindFirstChild("HumanoidRootPart")
                    if hd and rt and Utility.IsValidVector(hd.Position) and Utility.IsValidVector(rt.Position) then
                        table.insert(ps, {Player=p, Character=c, Humanoid=h, UserId=p.UserId})
                    end
                end
            end
        end
    end
    return ps
end
function Utility.IsInGame()
    local now = tick()
    if Utility.LobbyCache ~= nil and (now - Utility.LobbyCacheTime) < Utility.LobbyCacheDuration then return Utility.LobbyCache end
    local function finish(s) Utility.LobbyCache = s Utility.LobbyCacheTime = now return s end
    local o = Configuration.LobbyStateOverride or "Auto"
    if o == "InGame" then return finish(true) end
    if o == "Lobby" then return finish(false) end
    local ws = Utility.Workspace
    local lp = Utility.Players.LocalPlayer
    if not lp then return finish(true) end
    local cc = ws:FindFirstChild("Characters")
    if cc then
        local c = lp.Character
        if c and c.Parent then
            local par = c.Parent
            if par.Parent == cc then return finish(true) end
            if par == ws or par == cc then return finish(false) end
            if par.Name and par.Name:lower():find("lobby") then return finish(false) end
        else return finish(false) end
    end
    return finish(true)
end
function Utility.InvalidateLobbyCache() Utility.LobbyCache = nil Utility.LobbyCacheTime = 0 end

function Utility.ResolveHitboxMode(mode)
    mode = mode or Configuration.CameraAssistHitboxMode or "Head"
    if mode == "Random" then
        local opts = {"Head", "UpperTorso", "Chest"}
        return opts[math.random(1, #opts)]
    end
    return mode
end

function Utility.GetHitboxPosition(c, hname, cachePart)
    if not c or not c.Parent then return nil, nil end
    if cachePart and cachePart.Parent and Utility.IsValidVector(cachePart.Position) then
        if hname == "Head" and cachePart:IsA("BasePart") then
            return cachePart.Position + Vector3.new(0, cachePart.Size.Y * 0.30, 0), cachePart
        end
        return cachePart.Position, cachePart
    end
    local mode = hname or Configuration.CameraAssistHitboxMode or "Head"
    if mode == "Random" then mode = Utility.ResolveHitboxMode("Random") end
    local cached = Utility._hbpCache[c]
    if cached and cached.mode == mode and cached.part and cached.part.Parent then
        local pos = cached.part.Position
        if mode == "Head" and cached.part:IsA("BasePart") then
            pos = pos + Vector3.new(0, cached.part.Size.Y * 0.30, 0)
        end
        if Utility.IsValidVector(pos) then return pos, cached.part end
    end
    local names = Utility.HitboxModes[mode] or Utility.HitboxModes.Head
    for _, n in ipairs(names) do
        local p = c:FindFirstChild(n)
        if p and p.Parent then
            local pos = p.Position
            if mode == "Head" and p:IsA("BasePart") then
                pos = pos + Vector3.new(0, p.Size.Y * 0.30, 0)
            end
            if Utility.IsValidVector(pos) then
                Utility._hbpCache[c] = { mode = mode, part = p }
                return pos, p
            end
        end
    end
    if mode ~= "Head" then
        for _, n in ipairs(Utility.HitboxModes.Head) do
            local p = c:FindFirstChild(n)
            if p and p.Parent then
                local pos = p.Position + Vector3.new(0, p.Size.Y * 0.30, 0)
                if Utility.IsValidVector(pos) then
                    Utility._hbpCache[c] = { mode = mode, part = p }
                    return pos, p
                end
            end
        end
    end
    return nil, nil
end

function Utility.IsTargetablePart(p)
    if not p then return false end
    if Utility.HitboxNamePatterns[p.Name] then return true end
    local l = p.Name:lower()
    if l:find("hitbox") or l:find("torso") or l:find("head") or l:find("hand") or l:find("foot")
        or l:find("leg") or l:find("arm") or l:find("body") or l:find("chest") then return true end
    return false
end

Utility._reloadCacheTick = 0
Utility._reloadCacheVal = false
function Utility.IsReloading()
    local t = tick()
    if (t - Utility._reloadCacheTick) < 0.12 then return Utility._reloadCacheVal end
    Utility._reloadCacheTick = t
    local val = false
    local lp = Utility.Players.LocalPlayer
    if lp and lp.Character then
        local c = lp.Character
        local tool = c:FindFirstChildOfClass("Tool")
        if tool then
            for _, ch in ipairs(tool:GetChildren()) do
                if ch:IsA("BoolValue") and ch.Name:lower():find("reload") then
                    if ch.Value then val = true break end
                end
            end
        end
        if not val then
            local an = c:FindFirstChildOfClass("Animator")
            if an then
                local ok, tr = pcall(function() return an:GetPlayingAnimationTracks() end)
                if ok and tr then
                    for _, tk in ipairs(tr) do
                        local a = tk and tk.Animation
                        if a and a.Name and a.Name:lower():find("reload") then val = true break end
                    end
                end
            end
        end
    end
    Utility._reloadCacheVal = val
    return val
end

local VISIBILITY_DISABLED = true
function Utility.IsPositionVisible(tp, il, ck, tpart)
    if VISIBILITY_DISABLED then return true end
    local cam = Utility.GetCamera()
    if not cam then return false end
    il = il or {}
    if ck then
        local ts = Utility.VisibleCacheTimestamps[ck]
        if ts and (tick() - ts) < Utility.VisibleCacheDuration then return Utility.VisibleCache[ck] end
    end
    local fl = Utility._filterScratch
    if not fl then fl = {} Utility._filterScratch = fl end
    table.clear(fl)
    for _, item in ipairs(il) do if item and item.Parent then table.insert(fl, item) end end
    local lp = Utility.Players.LocalPlayer
    if lp and lp.Character and lp.Character.Parent then
        local found = false
        for _, item in ipairs(fl) do if item == lp.Character then found = true break end end
        if not found then table.insert(fl, lp.Character) end
    end
    if cam and cam.Parent then table.insert(fl, cam) end
    local origin = cam.CFrame.Position
    local tc = tpart and tpart:FindFirstAncestorOfClass("Model") or nil
    local function rp(point)
        local d = point - origin
        local dist = d.Magnitude
        if dist < 0.01 then return true end
        local dir = d / dist
        Utility.RaycastParams.FilterDescendantsInstances = fl
        local ok, r = pcall(function() return Utility.Workspace:Raycast(origin, dir * dist, Utility.RaycastParams) end)
        if not ok then return false end
        if r == nil then return true end
        local hi = r.Instance
        if hi == tpart then return true end
        if tc and hi:IsDescendantOf(tc) then
            local hr = hi.Position - tp
            if hr.Magnitude <= 1.5 then return true end
        end
        local tr = 0
        if hi then
            local okT, t = pcall(function() return hi.Transparency end)
            if okT and typeof(t) == "number" then tr = t end
        end
        if tr >= 0.9 then return true end
        local hd = (r.Position - origin).Magnitude
        if hd >= dist - Utility.MinRayDist then return true end
        return false
    end
    local v = rp(tp)
    if not v and tc then
        local h = tc:FindFirstChild("Head")
        local rt = tc:FindFirstChild("HumanoidRootPart")
        if h then v = rp(h.Position) end
        if not v and rt then v = rp(rt.Position) end
    end
    if ck then
        Utility.VisibleCache[ck] = v
        Utility.VisibleCacheTimestamps[ck] = tick()
    end
    return v
end

function Utility.CameraRaycast(maxDist)
    local cam = Utility.GetCamera()
    if not cam then return nil end
    local fl = Utility._camRayFilter
    if not fl then fl = {} Utility._camRayFilter = fl end
    table.clear(fl)
    local lp = Utility.Players.LocalPlayer
    if lp and lp.Character then table.insert(fl, lp.Character) end
    if cam then table.insert(fl, cam) end
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Blacklist
    pr.FilterDescendantsInstances = fl
    pr.IgnoreWater = true
    local o = cam.CFrame.Position
    local d = cam.CFrame.LookVector * (maxDist or 1000)
    local ok, r = pcall(function() return Utility.Workspace:Raycast(o, d, pr) end)
    if not ok or not r then return nil end
    local i = r.Instance
    return i, r.Position, i and i:FindFirstAncestorOfClass("Model") or nil
end

function Utility.IsTargetDeflecting(p)
    return false
end

local Palette = {
    Primary = Color3.fromRGB(255, 45, 92), Accent3 = Color3.fromRGB(255, 135, 165),
    Bg = Color3.fromRGB(7, 6, 10), BgBottom = Color3.fromRGB(18, 8, 14),
    Panel = Color3.fromRGB(17, 12, 18), PanelLight = Color3.fromRGB(36, 20, 29),
    Card = Color3.fromRGB(24, 15, 22), Accent = Color3.fromRGB(255, 45, 92),
    Accent2 = Color3.fromRGB(216, 33, 78), Text = Color3.fromRGB(250, 245, 248),
    TextMuted = Color3.fromRGB(171, 157, 166), Border = Color3.fromRGB(72, 31, 45),
    Success = Color3.fromRGB(86, 225, 150), Danger = Color3.fromRGB(255, 80, 105),
    Discord = Color3.fromRGB(88, 101, 242),
}
local CELESTIAL_HUI = {
    Bg = Color3.fromRGB(7, 6, 10), BtnBg = Color3.fromRGB(23, 15, 21),
    Panel = Color3.fromRGB(17, 12, 18),
    Stroke = Color3.fromRGB(67, 30, 43), Accent = Color3.fromRGB(255, 45, 92),
    Accent2 = Color3.fromRGB(216, 33, 78), Accent3 = Color3.fromRGB(255, 135, 165),
    Text = Color3.fromRGB(250, 245, 248), TextMuted = Color3.fromRGB(171, 157, 166),
    Gold = Color3.fromRGB(255, 200, 40), Corner = 14,
}

-- Safe local-only presentation layer.
-- It never targets, modifies, or highlights other players.
local LocalVisuals = {
    Character = nil,
    Highlight = nil,
    Tool = nil,
    SavedToolParts = {},
    SavedCameraParts = {},
    Camera = nil,
    ToolAddedConnection = nil,
    CharacterConnections = {},
    ScreenFX = {},
}

local function disconnectLocalVisualConnections()
    if LocalVisuals.ToolAddedConnection then pcall(function() LocalVisuals.ToolAddedConnection:Disconnect() end) end
    LocalVisuals.ToolAddedConnection = nil
    for _, c in ipairs(LocalVisuals.CharacterConnections) do pcall(function() c:Disconnect() end) end
    LocalVisuals.CharacterConnections = {}
end

local function colorFromName(name)
    local map = Configuration.BoxColorMap or {}
    return map[tostring(name)] or Palette.Accent
end

local function materialFromName(name)
    local ok, mat = pcall(function() return Enum.Material[tostring(name)] end)
    if ok and mat then return mat end
    return Enum.Material.Neon
end

function LocalVisuals.RestoreTool()
    for part, state in pairs(LocalVisuals.SavedToolParts) do
        if part and part.Parent then
            pcall(function()
                part.Material = state.Material
                part.Color = state.Color
                part.Transparency = state.Transparency
                part.CastShadow = state.CastShadow
            end)
        end
    end
    table.clear(LocalVisuals.SavedToolParts)
    if LocalVisuals.ToolAddedConnection then pcall(function() LocalVisuals.ToolAddedConnection:Disconnect() end) end
    LocalVisuals.ToolAddedConnection = nil
    LocalVisuals.Tool = nil
end

local function applyToolPart(part)
    if not part or not part:IsA("BasePart") then return end
    if not LocalVisuals.SavedToolParts[part] then
        LocalVisuals.SavedToolParts[part] = {
            Material = part.Material,
            Color = part.Color,
            Transparency = part.Transparency,
            CastShadow = part.CastShadow,
        }
    end
    local targetColor = colorFromName(Configuration.ViewmodelColor or "Purple")
    if Configuration.ViewmodelRainbow then
        local hue = (os.clock() * (tonumber(Configuration.ViewmodelRainbowSpeed) or 0.35)) % 1
        targetColor = Color3.fromHSV(hue, 0.72, 1)
    end
    pcall(function()
        part.Material = materialFromName(Configuration.ViewmodelMaterial or "Neon")
        part.Color = targetColor
        part.Transparency = math.clamp(tonumber(Configuration.ViewmodelTransparency) or 0, 0, 1)
        part.CastShadow = Configuration.ViewmodelCastShadows == true
    end)
end

function LocalVisuals.ApplyTool(tool)
    if not tool or not tool.Parent then
        LocalVisuals.RestoreTool()
        return
    end
    if LocalVisuals.Tool ~= tool then
        LocalVisuals.RestoreTool()
        LocalVisuals.Tool = tool
        for _, d in ipairs(tool:GetDescendants()) do applyToolPart(d) end
        LocalVisuals.ToolAddedConnection = tool.DescendantAdded:Connect(function(d)
            if LocalVisuals.Tool == tool and Configuration.ViewmodelChamsEnabled then
                task.defer(function() applyToolPart(d) end)
            end
        end)
    else
        for part, _ in pairs(LocalVisuals.SavedToolParts) do
            if part and part.Parent then applyToolPart(part) end
        end
    end
end

function LocalVisuals.RestoreCamera()
    for part, state in pairs(LocalVisuals.SavedCameraParts) do
        if part and part.Parent then
            pcall(function()
                part.Material = state.Material
                part.Color = state.Color
                part.Transparency = state.Transparency
                part.CastShadow = state.CastShadow
            end)
        end
    end
    table.clear(LocalVisuals.SavedCameraParts)
    LocalVisuals.Camera = nil
end

function LocalVisuals.ApplyCamera()
    if not Configuration.ViewmodelCameraArms then
        if next(LocalVisuals.SavedCameraParts) then LocalVisuals.RestoreCamera() end
        return
    end
    local cam = Utility.GetCamera()
    if not cam or not cam.Parent then
        LocalVisuals.RestoreCamera()
        return
    end
    if LocalVisuals.Camera ~= cam then
        LocalVisuals.RestoreCamera()
        LocalVisuals.Camera = cam
    end
    for _, d in ipairs(cam:GetDescendants()) do
        if d:IsA("BasePart") then
            if not LocalVisuals.SavedCameraParts[d] then
                LocalVisuals.SavedCameraParts[d] = {
                    Material = d.Material,
                    Color = d.Color,
                    Transparency = d.Transparency,
                    CastShadow = d.CastShadow,
                }
            end
            local targetColor = colorFromName(Configuration.ViewmodelColor or "Purple")
            if Configuration.ViewmodelRainbow then
                local hue = (os.clock() * (tonumber(Configuration.ViewmodelRainbowSpeed) or 0.35)) % 1
                targetColor = Color3.fromHSV(hue, 0.72, 1)
            end
            pcall(function()
                d.Material = materialFromName(Configuration.ViewmodelMaterial or "Neon")
                d.Color = targetColor
                d.Transparency = math.clamp(tonumber(Configuration.ViewmodelTransparency) or 0, 0, 1)
                d.CastShadow = Configuration.ViewmodelCastShadows == true
            end)
        end
    end
end

function LocalVisuals.ClearHighlight()
    if LocalVisuals.Highlight then
        pcall(function() LocalVisuals.Highlight:Destroy() end)
        LocalVisuals.Highlight = nil
    end
end

function LocalVisuals.ApplyCharacter()
    local lp = Utility.Players.LocalPlayer
    local char = lp and lp.Character
    if not char or not char.Parent then
        LocalVisuals.ClearHighlight()
        return
    end
    LocalVisuals.Character = char
    if not Configuration.LocalPlayerHighlightEnabled then
        LocalVisuals.ClearHighlight()
        return
    end
    local h = LocalVisuals.Highlight
    if not h or not h.Parent or h.Adornee ~= char then
        LocalVisuals.ClearHighlight()
        h = Instance.new("Highlight")
        h.Name = "CELESTIAL_H_LocalHighlight"
        h.Adornee = char
        h.DepthMode = tostring(Configuration.LocalPlayerDepthMode) == "AlwaysOnTop" and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        h.Parent = char
        LocalVisuals.Highlight = h
    end
    h.FillColor = colorFromName(Configuration.LocalPlayerGlowColor or "Purple")
    h.OutlineColor = colorFromName(Configuration.LocalPlayerOutlineColor or "White")
    h.FillTransparency = math.clamp(tonumber(Configuration.LocalPlayerFillTransparency) or 0.82, 0, 1)
    h.OutlineTransparency = math.clamp(tonumber(Configuration.LocalPlayerOutlineTransparency) or 0.05, 0, 1)
end

function LocalVisuals.EnsureCharacterConnections()
    local lp = Utility.Players.LocalPlayer
    if not lp or LocalVisuals._boundPlayer == lp then return end
    LocalVisuals._boundPlayer = lp
    LocalVisuals.CharacterConnections[1] = lp.CharacterAdded:Connect(function(char)
        LocalVisuals.Character = char
        LocalVisuals.RestoreTool()
        task.defer(LocalVisuals.ApplyCharacter)
    end)
end

function LocalVisuals.ApplyScreenFX()
    local L = game:GetService("Lighting")
    local wanted = Configuration.ScreenFXEnabled == true
    local cc = L:FindFirstChild("CELESTIAL_H_ScreenFX")
    local blur = L:FindFirstChild("CELESTIAL_H_ScreenBlur")
    if not wanted then
        if cc then cc:Destroy() end
        if blur then blur:Destroy() end
        LocalVisuals.ScreenFX = {}
        return
    end
    if not cc or not cc:IsA("ColorCorrectionEffect") then
        if cc then cc:Destroy() end
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "CELESTIAL_H_ScreenFX"
        cc.Parent = L
    end
    cc.Saturation = tonumber(Configuration.ScreenFXSaturation) or 0
    cc.Contrast = tonumber(Configuration.ScreenFXContrast) or 0
    cc.Brightness = tonumber(Configuration.ScreenFXBrightness) or 0
    cc.Enabled = true
    if Configuration.ScreenFXBlurEnabled then
        if not blur or not blur:IsA("BlurEffect") then
            if blur then blur:Destroy() end
            blur = Instance.new("BlurEffect")
            blur.Name = "CELESTIAL_H_ScreenBlur"
            blur.Parent = L
        end
        blur.Size = math.clamp(tonumber(Configuration.ScreenFXBlurSize) or 2, 0, 24)
        blur.Enabled = true
    elseif blur then
        blur:Destroy()
    end
end

function LocalVisuals.Step()
    LocalVisuals.EnsureCharacterConnections()
    LocalVisuals.ApplyCharacter()
    if Configuration.ViewmodelChamsEnabled then
        local lp = Utility.Players.LocalPlayer
        local char = lp and lp.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then LocalVisuals.ApplyTool(tool) else LocalVisuals.RestoreTool() end
    else
        LocalVisuals.RestoreTool()
    end
    if Configuration.ViewmodelChamsEnabled and Configuration.ViewmodelCameraArms then
        LocalVisuals.ApplyCamera()
    else
        LocalVisuals.RestoreCamera()
    end
    LocalVisuals.ApplyScreenFX()
end

function LocalVisuals.Unload()
    disconnectLocalVisualConnections()
    LocalVisuals.RestoreTool()
    LocalVisuals.RestoreCamera()
    LocalVisuals.ClearHighlight()
    LocalVisuals.ApplyScreenFX()
    local L = game:GetService("Lighting")
    for _, n in ipairs({"CELESTIAL_H_ScreenFX", "CELESTIAL_H_ScreenBlur"}) do
        local e = L:FindFirstChild(n)
        if e then pcall(function() e:Destroy() end) end
    end
end


-- ============================================================================
-- CELESTIAL H / LOCAL SKIN PREVIEW
-- Cosmetic, local-only presentation. Does not modify other players.
-- ============================================================================
local SkinChanger = {
    Character = nil,
    Saved = {},
    Connections = {},
    LastSignature = nil,
    RainbowHue = 0,
    Presets = {
        Celestial = {Base=Color3.fromRGB(150,120,220), Accent=Color3.fromRGB(95,210,255), Dark=Color3.fromRGB(32,28,48)},
        Ice       = {Base=Color3.fromRGB(190,225,255), Accent=Color3.fromRGB(100,190,255), Dark=Color3.fromRGB(28,42,56)},
        Sunset    = {Base=Color3.fromRGB(255,175,120), Accent=Color3.fromRGB(255,100,170), Dark=Color3.fromRGB(58,30,38)},
        Mono      = {Base=Color3.fromRGB(210,210,220), Accent=Color3.fromRGB(120,125,145), Dark=Color3.fromRGB(38,38,44)},
        Void      = {Base=Color3.fromRGB(72,56,110), Accent=Color3.fromRGB(185,105,255), Dark=Color3.fromRGB(18,14,28)},
    },
}

local function skinDisconnect()
    for _, c in ipairs(SkinChanger.Connections) do pcall(function() c:Disconnect() end) end
    SkinChanger.Connections = {}
end

function SkinChanger.Restore()
    skinDisconnect()
    for inst, state in pairs(SkinChanger.Saved) do
        if inst and inst.Parent then
            pcall(function()
                if state.Kind == "part" then
                    inst.Color = state.Color
                    inst.Material = state.Material
                    inst.Transparency = state.Transparency
                elseif state.Kind == "body" then
                    inst.HeadColor3 = state.HeadColor3
                    inst.LeftArmColor3 = state.LeftArmColor3
                    inst.LeftLegColor3 = state.LeftLegColor3
                    inst.RightArmColor3 = state.RightArmColor3
                    inst.RightLegColor3 = state.RightLegColor3
                    inst.TorsoColor3 = state.TorsoColor3
                end
            end)
        end
    end
    table.clear(SkinChanger.Saved)
    SkinChanger.Character = nil
    SkinChanger.LastSignature = nil
end

local function skinSavePart(part)
    if not SkinChanger.Saved[part] then
        SkinChanger.Saved[part] = {
            Kind="part", Color=part.Color, Material=part.Material, Transparency=part.Transparency,
        }
    end
end

local function skinApplyPart(part, base, accent, dark)
    if not part or not part:IsA("BasePart") then return end
    skinSavePart(part)
    local n = string.lower(part.Name)
    local c = base
    if n:find("handle") or n:find("accessory") or n:find("grip") then c = accent
    elseif n:find("root") or n:find("torso") then c = dark end
    if Configuration.SkinRainbow then
        local h = (os.clock() * (tonumber(Configuration.SkinRainbowSpeed) or 0.3)) % 1
        c = Color3.fromHSV(h, 0.62, 1)
    end
    pcall(function()
        part.Color = c
        part.Material = materialFromName(Configuration.SkinMaterial or "SmoothPlastic")
        part.Transparency = math.clamp(tonumber(Configuration.SkinTransparency) or 0, 0, 1)
    end)
end

function SkinChanger.ApplyCharacter()
    local lp = Utility.Players.LocalPlayer
    local char = lp and lp.Character
    if not char or not char.Parent then
        SkinChanger.Restore()
        return
    end
    if not Configuration.SkinChangerEnabled then
        if SkinChanger.Character then SkinChanger.Restore() end
        return
    end
    local p = SkinChanger.Presets[tostring(Configuration.SkinPreset or "Celestial")] or SkinChanger.Presets.Celestial
    local sig = table.concat({Configuration.SkinPreset,Configuration.SkinMaterial,Configuration.SkinAccentColor,Configuration.SkinTransparency,Configuration.SkinRainbow,Configuration.SkinRainbowSpeed}, "|")
    if SkinChanger.Character ~= char then
        SkinChanger.Restore()
        SkinChanger.Character = char
        table.insert(SkinChanger.Connections, char.DescendantAdded:Connect(function(d)
            if Configuration.SkinChangerEnabled and d:IsA("BasePart") then task.defer(function() skinApplyPart(d, p.Base, p.Accent, p.Dark) end) end
        end))
    end
    SkinChanger.LastSignature = sig
    local accent = colorFromName(Configuration.SkinAccentColor or "Purple")
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then skinApplyPart(d, p.Base, Configuration.SkinAccentEnabled and accent or p.Accent, p.Dark) end
    end
    local bc = char:FindFirstChildOfClass("BodyColors")
    if bc then
        if not SkinChanger.Saved[bc] then
            SkinChanger.Saved[bc] = {
                Kind="body", HeadColor3=bc.HeadColor3, LeftArmColor3=bc.LeftArmColor3,
                LeftLegColor3=bc.LeftLegColor3, RightArmColor3=bc.RightArmColor3,
                RightLegColor3=bc.RightLegColor3, TorsoColor3=bc.TorsoColor3,
            }
        end
        pcall(function()
            bc.HeadColor3=p.Base; bc.LeftArmColor3=p.Base; bc.LeftLegColor3=p.Dark
            bc.RightArmColor3=p.Base; bc.RightLegColor3=p.Dark; bc.TorsoColor3=p.Base
        end)
    end
end

function SkinChanger.Unload()
    SkinChanger.Restore()
end

_G.__CELESTIAL_H_SkinChanger = SkinChanger

-- ============================================================================
-- CELESTIAL H / BHOP TRAINER HUD
-- Local movement telemetry only; no automatic jump/physics manipulation.
-- ============================================================================
local BhopTrainer = {
    Gui=nil, Label=nil, Character=nil, Humanoid=nil, Root=nil,
    StateConn=nil, CharacterConn=nil, JumpCount=0, LastJump=0, LastAir=0,
}

function BhopTrainer.Destroy()
    if BhopTrainer.StateConn then pcall(function() BhopTrainer.StateConn:Disconnect() end) end
    if BhopTrainer.CharacterConn then pcall(function() BhopTrainer.CharacterConn:Disconnect() end) end
    BhopTrainer.StateConn=nil; BhopTrainer.CharacterConn=nil
    if BhopTrainer.Gui then pcall(function() BhopTrainer.Gui:Destroy() end) end
    BhopTrainer.Gui=nil; BhopTrainer.Label=nil
    BhopTrainer.Character=nil; BhopTrainer.Humanoid=nil; BhopTrainer.Root=nil
end

function BhopTrainer.EnsureGui()
    if not Configuration.BhopTrainerEnabled then BhopTrainer.Destroy(); return false end
    if BhopTrainer.Gui and BhopTrainer.Gui.Parent and BhopTrainer.Label and BhopTrainer.Label.Parent then return true end
    if BhopTrainer.Gui then BhopTrainer.Destroy() end
    local par = safeGuiParent(); if not par then return false end
    local sg = Instance.new("ScreenGui")
    sg.Name="CELESTIAL_H_BhopTrainer"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.DisplayOrder=805
    sg.Parent=par; BhopTrainer.Gui=sg
    local box=Instance.new("Frame")
    box.AnchorPoint=Vector2.new(0,0); box.Position=UDim2.new(0,18,0.5,48)
    box.Size=UDim2.fromOffset(190,48); box.BackgroundColor3=Palette.Bg; box.BackgroundTransparency=0.12
    box.BorderSizePixel=0; box.Parent=sg
    local cr=Instance.new("UICorner"); cr.CornerRadius=UDim.new(0,10); cr.Parent=box
    local st=Instance.new("UIStroke"); st.Color=Palette.Border; st.Transparency=0.25; st.Parent=box
    local lab=Instance.new("TextLabel")
    lab.Size=UDim2.new(1,-18,1,-10); lab.Position=UDim2.fromOffset(9,5)
    lab.BackgroundTransparency=1; lab.Font=Enum.Font.GothamBold; lab.TextSize=10
    lab.TextColor3=Palette.Text; lab.TextXAlignment=Enum.TextXAlignment.Left; lab.TextYAlignment=Enum.TextYAlignment.Center
    lab.Text="BHOP TRAINER"; lab.Parent=box; BhopTrainer.Label=lab
    return true
end

function BhopTrainer.BindCharacter()
    local lp=Utility.Players.LocalPlayer; local char=lp and lp.Character
    if char==BhopTrainer.Character then return end
    if BhopTrainer.StateConn then pcall(function() BhopTrainer.StateConn:Disconnect() end) end
    BhopTrainer.StateConn=nil
    BhopTrainer.Character=char; BhopTrainer.JumpCount=0; BhopTrainer.LastJump=0
    BhopTrainer.Humanoid=char and char:FindFirstChildOfClass("Humanoid")
    BhopTrainer.Root=char and char:FindFirstChild("HumanoidRootPart")
    if BhopTrainer.Humanoid then
        BhopTrainer.StateConn=BhopTrainer.Humanoid.StateChanged:Connect(function(_, new)
            if new==Enum.HumanoidStateType.Jumping then
                BhopTrainer.JumpCount += 1
                BhopTrainer.LastJump=os.clock()
            end
        end)
    end
end

function BhopTrainer.Step()
    if not BhopTrainer.EnsureGui() then return end
    BhopTrainer.BindCharacter()
    local hum=BhopTrainer.Humanoid; local root=BhopTrainer.Root
    if not hum or not root then return end
    local vel=root.AssemblyLinearVelocity
    local speed=Vector3.new(vel.X,0,vel.Z).Magnitude
    local state=hum:GetState()
    local now=os.clock()
    local timing="GROUND"
    if state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping then
        local age=now-(BhopTrainer.LastJump or now)
        local window=math.clamp(tonumber(Configuration.BhopPerfectWindow) or 0.18,0.05,0.6)
        timing=age<=window and "WINDOW" or "AIR"
    end
    local parts={"BHOP", string.format("SPD %.0f",speed)}
    if Configuration.BhopShowJumps ~= false then parts[#parts+1]=string.format("JUMPS %d",BhopTrainer.JumpCount) end
    if Configuration.BhopShowTiming ~= false then parts[#parts+1]=timing end
    BhopTrainer.Label.Text=table.concat(parts,"   ")
end

function BhopTrainer.Init()
    local lp=Utility.Players.LocalPlayer
    if BhopTrainer.CharacterConn then pcall(function() BhopTrainer.CharacterConn:Disconnect() end) end
    if lp then
        BhopTrainer.CharacterConn=lp.CharacterAdded:Connect(function()
            BhopTrainer.Character=nil
            task.defer(function() BhopTrainer.BindCharacter() end)
        end)
    end
    BhopTrainer.BindCharacter()
end

function BhopTrainer.Unload() BhopTrainer.Destroy() end
_G.__CELESTIAL_H_BhopTrainer=BhopTrainer


-- ============================================================================
-- CELESTIAL H / SHOT FEEDBACK
-- Визуальный feedback оружия: tracer, вспышка, счётчик выстрелов,
-- hitmarker и damage-popup API. Не перехватывает remotes и не добавляет
-- автоматическую стрельбу.
-- ============================================================================
local ShotFX = {
    Gui = nil,
    Container = nil,
    Flash = nil,
    Stats = nil,
    Tool = nil,
    ToolConn = nil,
    CharConn = nil,
    ShotCount = 0,
    ShotTimes = {},
    LastShotAt = 0,
    TracerColorMap = {
        Purple = Palette.Primary, Cyan = Color3.fromRGB(80,220,240), Blue = Color3.fromRGB(99,102,241),
        Green = Color3.fromRGB(60,220,90), Orange = Color3.fromRGB(255,140,60), Pink = Color3.fromRGB(255,100,200),
        White = Color3.fromRGB(245,243,255), Red = Color3.fromRGB(255,80,90), Yellow = Color3.fromRGB(255,220,60),
    },
}

local function shotColor()
    return ShotFX.TracerColorMap[Configuration.ShotTracerColor or "Cyan"] or Palette.Primary
end

local function shotCorner(g, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = g
    return c
end

local function shotMakeGui(name, order)
    local par = safeGuiParent()
    if not par then return nil end
    pcall(function()
        for _, child in ipairs(par:GetChildren()) do
            if child.Name == name and child:IsA("ScreenGui") then child:Destroy() end
        end
    end)
    local sg = Instance.new("ScreenGui")
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = order or 800
    pcall(function() sg.Parent = par end)
    if not sg.Parent then
        pcall(function() sg:Destroy() end)
        return nil
    end
    return sg
end

function ShotFX.DestroyGui()
    if ShotFX.Gui then pcall(function() ShotFX.Gui:Destroy() end) end
    ShotFX.Gui = nil
    ShotFX.Container = nil
    ShotFX.Flash = nil
    ShotFX.Stats = nil
end

function ShotFX.EnsureGui()
    if not Configuration.ShotFeedbackEnabled then
        ShotFX.DestroyGui()
        return false
    end
    if ShotFX.Gui and ShotFX.Gui.Parent and ShotFX.Container and ShotFX.Container.Parent then return true end
    ShotFX.DestroyGui()
    local sg = shotMakeGui("CELESTIAL_H_ShotFX", 810)
    if not sg then return false end
    ShotFX.Gui = sg

    local container = Instance.new("Frame")
    container.Name = "TracerLayer"
    container.Size = UDim2.fromScale(1,1)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Parent = sg
    ShotFX.Container = container

    local flash = Instance.new("Frame")
    flash.Name = "MuzzleFlash"
    flash.AnchorPoint = Vector2.new(0.5,0.5)
    flash.Position = UDim2.fromScale(0.5,0.5)
    flash.Size = UDim2.fromOffset(26,26)
    flash.BackgroundColor3 = shotColor()
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.Parent = sg
    shotCorner(flash, 13)
    ShotFX.Flash = flash

    local stats = Instance.new("TextLabel")
    stats.Name = "ShotStats"
    stats.AnchorPoint = Vector2.new(1,1)
    stats.Position = UDim2.new(1,-18,1,-18)
    stats.Size = UDim2.fromOffset(220,22)
    stats.BackgroundTransparency = 1
    stats.Font = Enum.Font.GothamBold
    stats.TextSize = 9
    stats.TextColor3 = Palette.TextMuted
    stats.TextXAlignment = Enum.TextXAlignment.Right
    stats.Text = ""
    stats.Parent = sg
    ShotFX.Stats = stats
    return true
end

local function drawShotLine(a, b)
    if not Configuration.ShotTracerEnabled then return end
    if not ShotFX.EnsureGui() or not ShotFX.Container then return end
    local d = b - a
    local len = d.Magnitude
    if len < 2 then return end
    local line = Instance.new("Frame")
    line.Name = "Tracer"
    line.AnchorPoint = Vector2.new(0.5,0.5)
    line.Position = UDim2.fromOffset((a.X+b.X)/2, (a.Y+b.Y)/2)
    line.Size = UDim2.fromOffset(len, math.clamp(tonumber(Configuration.ShotTracerThickness) or 2, 1, 6))
    line.Rotation = math.deg(math.atan2(d.Y,d.X))
    line.BackgroundColor3 = shotColor()
    line.BackgroundTransparency = 0.12
    line.BorderSizePixel = 0
    line.Parent = ShotFX.Container
    shotCorner(line, 3)
    local tw = game:GetService("TweenService")
    local life = math.clamp(tonumber(Configuration.ShotTracerLifetime) or 0.10, 0.03, 0.5)
    tw:Create(line, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency=1
    }):Play()
    task.delay(life+0.03, function()
        if line and line.Parent then pcall(function() line:Destroy() end) end
    end)
end

local function showMuzzleFlash()
    if not Configuration.ShotMuzzleFlashEnabled then return end
    if not ShotFX.EnsureGui() or not ShotFX.Flash then return end
    local f = ShotFX.Flash
    f.BackgroundColor3 = shotColor()
    f.Size = UDim2.fromOffset(24,24)
    f.BackgroundTransparency = 0.25
    local tw = game:GetService("TweenService")
    local life = math.clamp(tonumber(Configuration.ShotMuzzleFlashDuration) or 0.08, 0.03, 0.3)
    tw:Create(f, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency=1, Size=UDim2.fromOffset(36,36)
    }):Play()
end

function ShotFX.RefreshStats()
    if not ShotFX.Stats or not ShotFX.Stats.Parent then return end
    local bits = {}
    if Configuration.ShotShowCounter ~= false then
        table.insert(bits, string.format("SHOTS %d", ShotFX.ShotCount))
    end
    if Configuration.ShotShowFireRate ~= false then
        local now = os.clock()
        local kept = {}
        for _, t in ipairs(ShotFX.ShotTimes) do
            if now-t < 3 then kept[#kept+1] = t end
        end
        ShotFX.ShotTimes = kept
        local rpm = #kept > 1 and (#kept/3*60) or 0
        table.insert(bits, string.format("RPM %.0f", rpm))
    end
    ShotFX.Stats.Text = table.concat(bits,"  •  ")
end

function ShotFX.FireVisual()
    if not Configuration.ShotFeedbackEnabled then return end
    local cam = Utility.GetCamera()
    if not cam or not cam.Parent then return end

    local now = os.clock()
    ShotFX.ShotCount += 1
    ShotFX.LastShotAt = now
    table.insert(ShotFX.ShotTimes, now)
    while #ShotFX.ShotTimes > 24 do table.remove(ShotFX.ShotTimes,1) end

    local origin = cam.CFrame.Position
    local direction = cam.CFrame.LookVector
    local maxDistance = math.clamp(tonumber(Configuration.ShotMaxDistance) or 1200, 100, 5000)
    local endpoint = origin + direction * maxDistance

    pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = {}
        local lp = Utility.Players.LocalPlayer
        if lp and lp.Character then ignore[#ignore+1] = lp.Character end
        params.FilterDescendantsInstances = ignore
        local hit = Utility.Workspace:Raycast(origin, direction*maxDistance, params)
        if hit and hit.Position then endpoint = hit.Position end
    end)

    local a = Utility.WorldToViewport(origin + direction*0.5)
    local b, bOn = Utility.WorldToViewport(endpoint)
    if bOn then drawShotLine(a,b) end
    showMuzzleFlash()
    ShotFX.RefreshStats()
end

function ShotFX.RecordHit()
    if not Configuration.ShotHitmarkerEnabled or not ShotFX.EnsureGui() then return end
    local sg = ShotFX.Gui
    if not sg then return end

    local holder = Instance.new("Frame")
    holder.Name = "Hitmarker"
    holder.AnchorPoint = Vector2.new(0.5,0.5)
    holder.Position = UDim2.fromScale(0.5,0.5)
    holder.Size = UDim2.fromOffset(34,34)
    holder.BackgroundTransparency = 1
    holder.Parent = sg

    local tw = game:GetService("TweenService")
    local duration = math.clamp(tonumber(Configuration.ShotHitmarkerDuration) or 0.18, 0.05, 0.6)
    for _, data in ipairs({
        {Vector2.new(-8,-8),-45},{Vector2.new(8,-8),45},
        {Vector2.new(-8,8),45},{Vector2.new(8,8),-45}
    }) do
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5,0.5)
        f.Position = UDim2.fromOffset(data[1].X,data[1].Y)
        f.Size = UDim2.fromOffset(10,2)
        f.Rotation = data[2]
        f.BackgroundColor3 = shotColor()
        f.BorderSizePixel = 0
        f.Parent = holder
        shotCorner(f,1)
        tw:Create(f,TweenInfo.new(duration),{BackgroundTransparency=1}):Play()
    end
    task.delay(duration+0.04,function()
        if holder and holder.Parent then pcall(function() holder:Destroy() end) end
    end)
end

function ShotFX.RecordDamage(amount, worldPosition)
    amount = tonumber(amount)
    if not amount or amount <= 0 or not Configuration.ShotDamageNumbersEnabled then return end
    if not worldPosition or not Utility.IsValidVector(worldPosition) then
        ShotFX.RecordHit()
        return
    end
    if not ShotFX.EnsureGui() then return end

    local pos, visible = Utility.WorldToViewport(worldPosition)
    if not visible then ShotFX.RecordHit(); return end

    local label = Instance.new("TextLabel")
    label.Name = "DamageNumber"
    label.AnchorPoint = Vector2.new(0.5,0.5)
    label.Position = UDim2.fromOffset(pos.X,pos.Y)
    label.Size = UDim2.fromOffset(90,28)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(255,235,235)
    label.TextStrokeTransparency = 0.35
    label.Text = string.format("-%g",amount)
    label.Parent = ShotFX.Gui

    local tw = game:GetService("TweenService")
    local life = math.clamp(tonumber(Configuration.ShotDamagePopupDuration) or 0.75, 0.2, 2)
    tw:Create(label,TweenInfo.new(life,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
        Position=UDim2.fromOffset(pos.X,pos.Y-42),
        TextTransparency=1,
        TextStrokeTransparency=1
    }):Play()
    ShotFX.RecordHit()
    task.delay(life+0.03,function()
        if label and label.Parent then pcall(function() label:Destroy() end) end
    end)
end

function ShotFX.BindTool(tool)
    if ShotFX.ToolConn then pcall(function() ShotFX.ToolConn:Disconnect() end) end
    ShotFX.ToolConn=nil
    ShotFX.Tool=tool
    if not tool or not tool:IsA("Tool") then return end
    ShotFX.ToolConn=tool.Activated:Connect(function()
        ShotFX.FireVisual()
    end)
end

function ShotFX.RefreshTool()
    local lp = Utility.Players.LocalPlayer
    local char = lp and lp.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool ~= ShotFX.Tool then ShotFX.BindTool(tool) end
end

function ShotFX.Init()
    ShotFX.EnsureGui()
    if ShotFX.CharConn then pcall(function() ShotFX.CharConn:Disconnect() end) end
    local lp = Utility.Players.LocalPlayer
    if lp then
        ShotFX.CharConn=lp.CharacterAdded:Connect(function()
            if ShotFX.ToolConn then pcall(function() ShotFX.ToolConn:Disconnect() end) end
            ShotFX.ToolConn=nil
            ShotFX.Tool=nil
            task.defer(function() ShotFX.RefreshTool() end)
        end)
    end
    ShotFX.RefreshTool()
end

function ShotFX.Step()
    if not Configuration.ShotFeedbackEnabled then
        if ShotFX.Gui then ShotFX.DestroyGui() end
        return
    end
    ShotFX.EnsureGui()
    ShotFX.RefreshTool()
    ShotFX.RefreshStats()
end

function ShotFX.Unload()
    if ShotFX.ToolConn then pcall(function() ShotFX.ToolConn:Disconnect() end) end
    if ShotFX.CharConn then pcall(function() ShotFX.CharConn:Disconnect() end) end
    ShotFX.ToolConn=nil
    ShotFX.CharConn=nil
    ShotFX.Tool=nil
    ShotFX.DestroyGui()
end

_G.__CELESTIAL_H_ShotFeedback = ShotFX

local FOVCircle = {}
FOVCircle.Container = nil FOVCircle.Ring = nil FOVCircle.Stroke = nil FOVCircle.Hue = 0
FOVCircle._lastSize = nil FOVCircle._lastColor = nil FOVCircle._lastVisible = nil
FOVCircle.ColorMap = {
    White = Color3.fromRGB(245, 243, 255), Red = Color3.fromRGB(255, 60, 60),
    Yellow = Color3.fromRGB(255, 220, 60), Blue = Palette.Accent2,
    Green = Color3.fromRGB(60, 220, 90), Black = Color3.fromRGB(25, 25, 30),
    Cyan = Color3.fromRGB(80, 220, 240),
}
function FOVCircle.Ensure()
    if FOVCircle.Container and FOVCircle.Container.Parent and FOVCircle.Ring and FOVCircle.Ring.Parent then return true end
    if FOVCircle.Container and not FOVCircle.Container.Parent then FOVCircle.Container = nil FOVCircle.Ring = nil FOVCircle.Stroke = nil end
    if not FOVCircle.Container then
        local sg = makeScreenGui("CELESTIAL_H_FOV", 120, true)
        if not sg then return false end
        FOVCircle.Container = sg
    end
    if not FOVCircle.Ring or not FOVCircle.Ring.Parent then
        local r = Instance.new("Frame")
        r.Name = "Ring" r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.new(0.5, 0, 0.5, 0) r.BackgroundTransparency = 1
        r.BorderSizePixel = 0 r.Visible = false r.ZIndex = 1 r.Parent = FOVCircle.Container
        local cr = Instance.new("UICorner") cr.CornerRadius = UDim.new(0.5, 0) cr.Parent = r
        local st = Instance.new("UIStroke") st.Thickness = 2 st.Color = Palette.Primary st.Transparency = 0.1 st.Parent = r
        FOVCircle.Ring = r FOVCircle.Stroke = st
    end
    return true
end
function FOVCircle.Update()
    pcall(function()
        FOVCircle.Ensure()
        if not FOVCircle.Ring then return end
        local cam = Utility.GetCamera()
        local showSilent = Configuration.SilentAimDrawFOV
        local showAimbot = Configuration.CameraAssistDrawFOV
        if not cam or (not showSilent and not showAimbot) then
            if FOVCircle._lastVisible ~= false then FOVCircle.Ring.Visible = false FOVCircle._lastVisible = false end
            return
        end
        local useSilent = showSilent
        local fovVal = useSilent and (Configuration.SilentAimFOV or 200) or (Configuration.CameraAssistFOV or 35)
        local colorName = useSilent and Configuration.SilentAimFOVColor or Configuration.CameraAssistFOVColor
        local sc = Utility.ViewportScale()
        local vp = cam.ViewportSize
        local maxDia = math.min(vp.X, vp.Y) - 40
        if maxDia < 40 then maxDia = 40 end
        local rad = math.clamp(fovVal * 10 * sc, 10, 4000)
        local dia = math.floor(rad * 2)
        if dia > maxDia then dia = maxDia end
        if FOVCircle._lastSize ~= dia then
            FOVCircle.Ring.Size = UDim2.new(0, dia, 0, dia)
            FOVCircle.Ring.Position = UDim2.new(0.5, 0, 0.5, 0)
            FOVCircle._lastSize = dia
        end
        if FOVCircle._lastVisible ~= true then FOVCircle.Ring.Visible = true FOVCircle._lastVisible = true end
        local st = FOVCircle.Stroke
        if not st then return end
        if colorName == "RGB" then
            FOVCircle.Hue = (FOVCircle.Hue + 0.002) % 1
            st.Color = Color3.fromHSV(FOVCircle.Hue, 1, 1)
            FOVCircle._lastColor = nil
        else
            local col = FOVCircle.ColorMap[colorName] or Palette.Primary
            if FOVCircle._lastColor ~= col then st.Color = col FOVCircle._lastColor = col end
        end
    end)
end
function FOVCircle.Destroy()
    if FOVCircle.Container then pcall(function() FOVCircle.Container:Destroy() end) end
    FOVCircle.Container = nil FOVCircle.Ring = nil FOVCircle.Stroke = nil
end

--// CELESTIAL H :: WORLD VISUALS
local WorldVisuals = {Active = false, LastSignature = nil, Saved = nil, Clouds = nil}
function WorldVisuals._lighting() return game:GetService("Lighting") end
function WorldVisuals._save()
    if WorldVisuals.Saved then return end
    local L = WorldVisuals._lighting()
    WorldVisuals.Saved = {Brightness=L.Brightness, ExposureCompensation=L.ExposureCompensation, ClockTime=L.ClockTime, FogStart=L.FogStart, FogEnd=L.FogEnd, GlobalShadows=L.GlobalShadows, Ambient=L.Ambient, OutdoorAmbient=L.OutdoorAmbient, EnvironmentDiffuseScale=L.EnvironmentDiffuseScale, EnvironmentSpecularScale=L.EnvironmentSpecularScale}
end
function WorldVisuals._effect(className, name)
    local L=WorldVisuals._lighting(); local e=L:FindFirstChild(name)
    if e and not e:IsA(className) then pcall(function() e:Destroy() end); e=nil end
    if not e then e=Instance.new(className); e.Name=name; e.Parent=L end
    return e
end
function WorldVisuals._preset()
    local p=tostring(Configuration.WorldPreset or "Celestial")
    if p=="Noir" then return {brightness=1.5,exposure=-0.15,clock=0,ambient=Color3.fromRGB(28,28,38),outdoor=Color3.fromRGB(45,45,60),tint=Color3.fromRGB(205,215,255),contrast=0.18,saturation=-0.2,atmosphere=Color3.fromRGB(145,155,205),density=0.28} end
    if p=="Sunset" then return {brightness=2.2,exposure=0.2,clock=17.8,ambient=Color3.fromRGB(95,60,50),outdoor=Color3.fromRGB(125,85,65),tint=Color3.fromRGB(255,215,185),contrast=0.08,saturation=0.08,atmosphere=Color3.fromRGB(255,185,145),density=0.16} end
    if p=="Clean" then return {brightness=2,exposure=0,clock=14,ambient=Color3.fromRGB(110,110,125),outdoor=Color3.fromRGB(135,135,150),tint=Color3.fromRGB(255,255,255),contrast=0.02,saturation=0,atmosphere=Color3.fromRGB(200,205,215),density=0.08} end
    return {brightness=2.1,exposure=0.15,clock=14,ambient=Color3.fromRGB(55,45,78),outdoor=Color3.fromRGB(85,72,112),tint=Color3.fromRGB(220,215,255),contrast=0.12,saturation=0.05,atmosphere=Color3.fromRGB(150,135,205),density=0.18}
end
function WorldVisuals._destroyOwnedEffects()
    local L=WorldVisuals._lighting()
    for _,n in ipairs({"CELESTIAL_H_Atmosphere","CELESTIAL_H_Bloom","CELESTIAL_H_ColorCorrection","CELESTIAL_H_SunRays","CELESTIAL_H_DepthOfField"}) do local e=L:FindFirstChild(n); if e then pcall(function() e:Destroy() end) end end
end
function WorldVisuals.Apply()
    local L=WorldVisuals._lighting()
    if not Configuration.WorldVisualsEnabled then if WorldVisuals.Active then WorldVisuals.Restore() end; return end
    WorldVisuals._save(); local p=WorldVisuals._preset()
    local sig=table.concat({Configuration.WorldPreset,Configuration.WorldBrightness,Configuration.WorldExposure,Configuration.WorldClockTime,Configuration.WorldFogStart,Configuration.WorldFogEnd,Configuration.WorldAtmosphereDensity,Configuration.WorldBloomEnabled,Configuration.WorldColorCorrectionEnabled,Configuration.WorldSunRaysEnabled,Configuration.WorldDepthOfFieldEnabled,Configuration.WorldFullbright,Configuration.WorldShadows,Configuration.WorldCloudsEnabled,Configuration.WorldCloudCover,Configuration.WorldCloudDensity,Configuration.WorldCloudSpeed,Configuration.WorldCloudColor},"|")
    if WorldVisuals.Active and WorldVisuals.LastSignature==sig then return end
    WorldVisuals.Active=true; WorldVisuals.LastSignature=sig
    L.Brightness=tonumber(Configuration.WorldBrightness) or p.brightness; L.ExposureCompensation=tonumber(Configuration.WorldExposure) or p.exposure; L.ClockTime=tonumber(Configuration.WorldClockTime) or p.clock
    L.FogStart=tonumber(Configuration.WorldFogStart) or 0; L.FogEnd=tonumber(Configuration.WorldFogEnd) or 100000; L.GlobalShadows=Configuration.WorldShadows~=false; L.Ambient=p.ambient; L.OutdoorAmbient=p.outdoor
    pcall(function() L.EnvironmentDiffuseScale=0.65 end); pcall(function() L.EnvironmentSpecularScale=0.45 end)
    local at=WorldVisuals._effect("Atmosphere","CELESTIAL_H_Atmosphere"); at.Color=p.atmosphere; at.Decay=p.atmosphere:Lerp(Color3.new(1,1,1),0.35); at.Density=math.clamp(tonumber(Configuration.WorldAtmosphereDensity) or p.density,0,1); at.Glare=0.05; at.Haze=0.8
    local bloom=WorldVisuals._effect("BloomEffect","CELESTIAL_H_Bloom"); bloom.Intensity=0.22; bloom.Size=24; bloom.Threshold=1.1; bloom.Enabled=Configuration.WorldBloomEnabled==true
    local cc=WorldVisuals._effect("ColorCorrectionEffect","CELESTIAL_H_ColorCorrection"); cc.TintColor=p.tint; cc.Contrast=p.contrast; cc.Saturation=p.saturation; cc.Brightness=Configuration.WorldFullbright and 0.08 or 0; cc.Enabled=Configuration.WorldColorCorrectionEnabled==true
    local rays=WorldVisuals._effect("SunRaysEffect","CELESTIAL_H_SunRays"); rays.Intensity=0.035; rays.Spread=0.82; rays.Enabled=Configuration.WorldSunRaysEnabled==true
    local dof=WorldVisuals._effect("DepthOfFieldEffect","CELESTIAL_H_DepthOfField"); dof.FarIntensity=0.05; dof.FocusDistance=70; dof.InFocusRadius=55; dof.NearIntensity=0; dof.Enabled=Configuration.WorldDepthOfFieldEnabled==true
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if Configuration.WorldCloudsEnabled and terrain then
        local clouds = terrain:FindFirstChild("CELESTIAL_H_Clouds")
        if not clouds or not clouds:IsA("Clouds") then
            if clouds then clouds:Destroy() end
            clouds = Instance.new("Clouds")
            clouds.Name = "CELESTIAL_H_Clouds"
            clouds.Parent = terrain
        end
        clouds.Cover = math.clamp(tonumber(Configuration.WorldCloudCover) or 0.35, 0, 1)
        clouds.Density = math.clamp(tonumber(Configuration.WorldCloudDensity) or 0.4, 0, 1)
        clouds.Speed = math.clamp(tonumber(Configuration.WorldCloudSpeed) or 0.2, 0, 10)
        clouds.Color = colorFromName(Configuration.WorldCloudColor or "White")
        WorldVisuals.Clouds = clouds
    elseif WorldVisuals.Clouds then
        pcall(function() WorldVisuals.Clouds:Destroy() end)
        WorldVisuals.Clouds = nil
    end
    if Configuration.WorldFullbright then L.Brightness=math.max(L.Brightness,2.5); L.Ambient=Color3.fromRGB(180,180,190); L.OutdoorAmbient=Color3.fromRGB(200,200,210) end
end
function WorldVisuals.Restore()
    local L=WorldVisuals._lighting(); local s=WorldVisuals.Saved
    if s then
        pcall(function() L.Brightness=s.Brightness end); pcall(function() L.ExposureCompensation=s.ExposureCompensation end); pcall(function() L.ClockTime=s.ClockTime end); pcall(function() L.FogStart=s.FogStart end); pcall(function() L.FogEnd=s.FogEnd end); pcall(function() L.GlobalShadows=s.GlobalShadows end); pcall(function() L.Ambient=s.Ambient end); pcall(function() L.OutdoorAmbient=s.OutdoorAmbient end); pcall(function() L.EnvironmentDiffuseScale=s.EnvironmentDiffuseScale end); pcall(function() L.EnvironmentSpecularScale=s.EnvironmentSpecularScale end)
    end
    if WorldVisuals.Clouds then pcall(function() WorldVisuals.Clouds:Destroy() end) WorldVisuals.Clouds=nil end
    WorldVisuals._destroyOwnedEffects(); WorldVisuals.Active=false; WorldVisuals.LastSignature=nil; WorldVisuals.Saved=nil
end

local Visuals = {}
Visuals.Objects = {} Visuals.Container = nil Visuals.ValidPlayersCache = {}
Visuals.LastPlayerListUpdate = 0 Visuals.LastUpdateTime = 0 Visuals.LastVisibleCount = 0
Visuals.BoneConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
function Visuals.EnsureContainer()
    if Visuals.Container and Visuals.Container.Parent then return true end
    local sg = makeScreenGui("CELESTIAL_H_Visuals", 5, true)
    if not sg then return false end
    Visuals.Container = sg
    return true
end
function Visuals.CreateSkeletonLines(player)
    local pid = player and player.UserId or "unknown"
    local lines = {}
    Visuals.EnsureContainer()
    if not Visuals.Container then return lines end
    local scm = Configuration.BoxColorMap or {}
    local baseCol = scm[Configuration.SkeletonColor] or Palette.Accent3
    for i = 1, #Visuals.BoneConnections do
        local l = Instance.new("Frame")
        l.Name = string.format("Skel_%s_%d", tostring(pid), i)
        l.BackgroundColor3 = baseCol l.BorderSizePixel = 0
        l.AnchorPoint = Vector2.new(0.5, 0.5)
        l.Size = UDim2.new(0, 0, 0, 1) l.Position = UDim2.new(0, -9999, 0, -9999)
        l.Visible = false l.ZIndex = 3 l.Parent = Visuals.Container
        table.insert(lines, l)
    end
    return lines
end
function Visuals.CreateElements(player)
    local pid = player and player.UserId
    if not pid or Visuals.Objects[pid] then return Visuals.Objects[pid] end
    Visuals.EnsureContainer()
    if not Visuals.Container then return nil end
    local fr = Instance.new("Frame")
    fr.Name = "Overlay_" .. tostring(pid)
    fr.Size = UDim2.new(0, 100, 0, 100) fr.Position = UDim2.new(0, -9999, 0, -9999)
    fr.BackgroundTransparency = 1 fr.BorderSizePixel = 0 fr.Visible = false fr.Parent = Visuals.Container
    local bx = Instance.new("Frame")
    bx.Size = UDim2.new(1, 0, 1, 0) bx.BackgroundTransparency = 1 bx.BorderSizePixel = 0 bx.ZIndex = 2 bx.Parent = fr
    local str = Instance.new("UIStroke")
    str.Color = Palette.Primary str.Thickness = 1.5
    str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border str.Parent = bx
    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, 0, 0, 14) nl.Position = UDim2.new(0, 0, 0, -16)
    nl.BackgroundTransparency = 1 nl.Font = Enum.Font.GothamMedium nl.TextSize = 11
    nl.TextColor3 = Palette.Text nl.TextStrokeTransparency = 0.4
    nl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) nl.TextXAlignment = Enum.TextXAlignment.Center
    nl.ZIndex = 4 nl.Parent = fr
    local hb = Instance.new("Frame")
    hb.Size = UDim2.new(0, 4, 1, 0) hb.Position = UDim2.new(-1, -6, 0, 0)
    hb.BackgroundColor3 = Color3.fromRGB(30, 28, 44) hb.BorderSizePixel = 0 hb.ZIndex = 2 hb.Parent = fr
    local hf = Instance.new("Frame")
    hf.Size = UDim2.new(1, 0, 1, 0) hf.BackgroundColor3 = Color3.fromRGB(0, 255, 100) hf.BorderSizePixel = 0 hf.Parent = hb
    local ht = Instance.new("TextLabel")
    ht.Size = UDim2.new(0, 32, 0, 12) ht.Position = UDim2.new(-1, -40, 0, -2)
    ht.BackgroundColor3 = Color3.fromRGB(0, 0, 0) ht.BackgroundTransparency = 0.35
    ht.Font = Enum.Font.GothamMedium ht.TextSize = 9 ht.TextColor3 = Palette.Text
    ht.TextStrokeTransparency = 0.5 ht.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ht.TextXAlignment = Enum.TextXAlignment.Left ht.ZIndex = 4 ht.Parent = fr
    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, 0, 0, 12) dl.Position = UDim2.new(0, 0, 1, 2)
    dl.BackgroundTransparency = 1 dl.Font = Enum.Font.GothamMedium dl.TextSize = 9
    dl.TextColor3 = Palette.TextMuted dl.TextStrokeTransparency = 0.5
    dl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) dl.TextXAlignment = Enum.TextXAlignment.Center
    dl.ZIndex = 4 dl.Parent = fr
    local skel = Visuals.CreateSkeletonLines(player)
    local vo = { Container = fr, Box = bx, Stroke = str, Name = nl, HealthBar = hb, HealthFill = hf, HealthText = ht, Distance = dl, SkeletonLines = skel, Player = player, Character = nil }
    Visuals.Objects[pid] = vo
    return vo
end
function Visuals.UpdateSkeleton(vo, c)
    if not vo or not vo.SkeletonLines then return end
    local hide = false
    if not Configuration.ShowSkeleton then hide = true end
    if not vo.Container or not vo.Container.Visible then hide = true end
    if not c or not c.Parent then hide = true end
    if hide then
        for _, l in ipairs(vo.SkeletonLines) do if l.Visible then l.Visible = false end end
        return
    end
    local scm = Configuration.BoxColorMap or {}
    local skelCol = scm[Configuration.SkeletonColor] or Palette.Accent3
    for i, pair in ipairs(Visuals.BoneConnections) do
        local l = vo.SkeletonLines[i]
        if l then
            if l.BackgroundColor3 ~= skelCol then l.BackgroundColor3 = skelCol end
            local pa = c:FindFirstChild(pair[1])
            local pb = c:FindFirstChild(pair[2])
            local skip = false
            if not pa or not pb then skip = true end
            if not skip then
                local pa2, onA = Utility.WorldToViewport(pa.Position)
                local pb2, onB = Utility.WorldToViewport(pb.Position)
                if not onA or not onB then skip = true end
                if not skip then
                    local dx = pb2.X - pa2.X
                    local dy = pb2.Y - pa2.Y
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len < 1 then skip = true end
                    if not skip then
                        local mx = (pa2.X + pb2.X) * 0.5
                        local my = (pa2.Y + pb2.Y) * 0.5
                        local ang = math.deg(math.atan2(dy, dx))
                        l.Size = UDim2.new(0, math.floor(len), 0, 1)
                        l.Position = UDim2.new(0, math.floor(mx), 0, math.floor(my))
                        l.Rotation = ang
                        if not l.Visible then l.Visible = true end
                    end
                end
            end
            if skip then if l.Visible then l.Visible = false end end
        end
    end
end

function Visuals.Step()
    if not Configuration.VisualsEnabled then
        for pid, vo in pairs(Visuals.Objects) do
            if vo.Container then pcall(function() vo.Container:Destroy() end) end
            if vo.SkeletonLines then
                for _, l in ipairs(vo.SkeletonLines) do if l then pcall(function() l:Destroy() end) end end
            end
        end
        Visuals.Objects = {}
        if Visuals.Container then
            for _, ch in ipairs(Visuals.Container:GetChildren()) do
                if ch.Name:sub(1, 7) == "Overlay" or ch.Name:sub(1, 5) == "Skel_" then pcall(function() ch:Destroy() end) end
            end
        end
        return
    end
    local now = tick()
    local lastCount = Visuals.LastVisibleCount or 0
    local targetHz
    if lastCount <= 6 then targetHz = 60
    elseif lastCount <= 12 then targetHz = 45
    elseif lastCount <= 24 then targetHz = 30
    else targetHz = 15 end
    local interval = 1.0 / targetHz
    if now - Visuals.LastUpdateTime < interval then return end
    Visuals.LastUpdateTime = now
    if now - Visuals.LastPlayerListUpdate > Configuration.PlayerListUpdateInterval then
        Visuals.LastPlayerListUpdate = now
        Visuals.ValidPlayersCache = Utility.GetValidPlayers()
    end
    local cam = Utility.GetCamera()
    if not cam or not cam.Parent then return end
    local lp = Utility.Players.LocalPlayer
    if not lp or not lp.Character then return end
    local lpRoot = lp.Character:FindFirstChild("HumanoidRootPart")
    local vpW = cam.ViewportSize.X
    local vpH = cam.ViewportSize.Y
    local active = {}
    local bcm = Configuration.BoxColorMap or {}
    for _, pd in ipairs(Visuals.ValidPlayersCache) do
        local player = pd.Player
        local c = pd.Character
        local h = pd.Humanoid
        if c and c.Parent and h and h.Parent then
            active[player.UserId] = true
            local vo = Visuals.Objects[player.UserId] or Visuals.CreateElements(player)
            if vo then
                local head = c:FindFirstChild("Head")
                local root = c:FindFirstChild("HumanoidRootPart")
                local vis = false
                if head and root then
                    local hS, hOn = Utility.WorldToViewport(head.Position)
                    local rS, rOn = Utility.WorldToViewport(root.Position)
                    if hOn and rOn then
                        local halfH = rS.Y - hS.Y
                        if halfH <= 0 then halfH = -halfH end
                        local bodyH = halfH * 2
                        local ht = math.max(math.floor(bodyH * 1.5 + 0.5), 30)
                        local wd = math.max(math.floor(ht * 0.45 + 0.5), 15)
                        local cx = math.floor(hS.X - wd * 0.5 + 0.5)
                        local cy = math.floor(hS.Y + halfH - ht * 0.5 + 0.5)
                        if cx > -wd and cx < vpW and cy > -ht and cy < vpH then
                            vo.Container.Position = UDim2.new(0, cx, 0, cy)
                            vo.Container.Size = UDim2.new(0, wd, 0, ht)
                            vo.Box.Visible = Configuration.ShowBoxes
                            vo.Stroke.Enabled = Configuration.ShowBoxes
                            vo.Stroke.Color = bcm[Configuration.BoxColor] or Palette.Primary
                            vo.Name.Visible = Configuration.ShowNames
                            vo.Name.TextColor3 = bcm[Configuration.NameColor] or Palette.Text
                            local nm = player.Name or "?"
                            if vo.Name.Text ~= nm then vo.Name.Text = nm end
                            if Configuration.ShowHealth then
                                vo.HealthBar.Visible = true
                                vo.HealthText.Visible = true
                                local hp = h.Health / math.max(h.MaxHealth, 1)
                                vo.HealthFill.Size = UDim2.new(1, 0, hp, 0)
                                local hpt = tostring(math.floor(h.Health))
                                if vo.HealthText.Text ~= hpt then vo.HealthText.Text = hpt end
                                local hc
                                if hp > 0.6 then hc = Color3.fromRGB(0, 255, 100)
                                elseif hp > 0.3 then hc = Color3.fromRGB(255, 255, 0)
                                else hc = Color3.fromRGB(255, 0, 0) end
                                if vo.HealthFill.BackgroundColor3 ~= hc then vo.HealthFill.BackgroundColor3 = hc end
                            else
                                if vo.HealthBar.Visible then vo.HealthBar.Visible = false end
                                if vo.HealthText.Visible then vo.HealthText.Visible = false end
                            end
                            if Configuration.ShowDistance and lpRoot then
                                if not vo.Distance.Visible then vo.Distance.Visible = true end
                                local d = (lpRoot.Position - root.Position).Magnitude
                                if d < Configuration.MaxRenderDistance then
                                    local dt = string.format("%dm", math.floor(d))
                                    if vo.Distance.Text ~= dt then vo.Distance.Text = dt end
                                else
                                    if vo.Distance.Visible then vo.Distance.Visible = false end
                                end
                            else
                                if vo.Distance.Visible then vo.Distance.Visible = false end
                            end
                            vis = true
                        end
                    end
                end
                if vis then
                    Visuals.UpdateSkeleton(vo, c)
                    if not vo.Container.Visible then vo.Container.Visible = true end
                else
                    if vo.Container.Visible then vo.Container.Visible = false end
                    if vo.SkeletonLines then
                        for _, l in ipairs(vo.SkeletonLines) do
                            if l.Visible then l.Visible = false end
                        end
                    end
                end
            end
        end
    end
    for pid, vo in pairs(Visuals.Objects) do
        if not active[pid] then
            if vo.Container then pcall(function() vo.Container:Destroy() end) end
            if vo.SkeletonLines then
                for _, l in ipairs(vo.SkeletonLines) do if l then pcall(function() l:Destroy() end) end end
            end
            Visuals.Objects[pid] = nil
        end
    end
    local n = 0
    for _ in pairs(active) do n = n + 1 end
    Visuals.LastVisibleCount = n
end
function Visuals.OnPlayerRemoving(player)
    local v = Visuals.Objects[player and player.UserId]
    if v then
        if v.Container then pcall(function() v.Container:Destroy() end) end
        if v.SkeletonLines then
            for _, l in ipairs(v.SkeletonLines) do if l then pcall(function() l:Destroy() end) end end
        end
        Visuals.Objects[player.UserId] = nil
    end
end

local CameraAssist = {}
CameraAssist.Lock = nil CameraAssist.Bound = false
CameraAssist.BindName = "CELESTIAL_H_Aim_" .. tostring(math.random(1, 999999))
CameraAssist.KeyHeld = false CameraAssist.ShuttingDown = false
CameraAssist.LastLockUserId = nil CameraAssist.LastAcquirePrint = 0
CameraAssist.SavedPostFX = {}
CameraAssist.MouseAccumX = 0 CameraAssist.MouseAccumY = 0
CameraAssist.PingEstimate = 0.06 CameraAssist.LastPingUpdate = 0
CameraAssist.WasScoped = false CameraAssist.PreferUserId = nil CameraAssist.PreferUntil = 0
CameraAssist.MissGrace = 12 CameraAssist.DesiredLook = nil CameraAssist.LastWrittenCF = nil
CameraAssist.CamSignalConn = nil CameraAssist.CamSwapConn = nil
CameraAssist.WasAirborne = false CameraAssist.AirborneUntil = 0
CameraAssist.LockedTargetWorldPos = nil CameraAssist.LastPriorityScan = 0
CameraAssist.LastLockSwitchTime = 0 CameraAssist.AimState = nil CameraAssist.AimStateChar = nil
CameraAssist.LastFactor = 0 CameraAssist.LastEffSmoothing = 0
CameraAssist.LastTargetPos = nil CameraAssist.LastTargetPosTime = 0
CameraAssist._lastAcqVis = 0
CameraAssist._deflectCooldownUntil = 0
CameraAssist._deflectCooldownUser = nil
CameraAssist.ViewFOVBindName = "CELESTIAL_H_ViewFOV_" .. tostring(math.random(1, 999999))
CameraAssist.ViewFOVBound = false
CameraAssist.ControllerFireHeld = false CameraAssist.LastInputWasController = false
CameraAssist.BlockFireTarget = nil
CameraAssist.SavedAutoRotate = nil

local MAX_PITCH = math.rad(85)
local SIN_MAX = math.sin(MAX_PITCH)

local function clampPitch(v)
    if not v or v.Magnitude < 1e-4 then return v end
    v = v.Unit
    local y = math.clamp(v.Y, -SIN_MAX, SIN_MAX)
    local hm = math.sqrt(math.max(0, 1 - y * y))
    local hl = math.sqrt(v.X * v.X + v.Z * v.Z)
    if hl < 1e-4 then return Vector3.new(0, y, -hm) end
    local s = hm / hl
    return Vector3.new(v.X * s, y, v.Z * s)
end

local function applyMouseDelta(dir, dyaw, dpitch)
    if not dir or dir.Magnitude < 1e-4 then return dir end
    dir = dir.Unit
    local yaw = math.atan2(-dir.X, -dir.Z)
    local pitch = math.asin(math.clamp(dir.Y, -1, 1))
    yaw = yaw + math.rad(dyaw)
    pitch = math.clamp(pitch + math.rad(dpitch), -MAX_PITCH, MAX_PITCH)
    local cy = math.cos(pitch)
    return Vector3.new(-math.sin(yaw) * cy, math.sin(pitch), -math.cos(yaw) * cy).Unit
end

local function smoothingToFactor(s, dt)
    if s <= 2 then return 1 end
    local rate
    if s <= 7 then
        rate = 8 + (7 - s) * 4
    else
        rate = 60 / s
    end
    local f = 1 - math.exp(-rate * dt)
    return math.clamp(f, 0, 1)
end

function CameraAssist.BindViewFOV()
    pcall(function() Utility.RunService:UnbindFromRenderStep(CameraAssist.ViewFOVBindName) end)
    CameraAssist.ViewFOVBound = false
    local ok = pcall(function()
        Utility.RunService:BindToRenderStep(CameraAssist.ViewFOVBindName, Enum.RenderPriority.Camera.Value + 10050, function()
            if CameraAssist.ShuttingDown then return end
            if not Configuration.ViewFOVEnabled then return end
            if not Configuration.ViewFOVIgnoreScope and CameraAssist.WasScoped then return end
            local c = Utility.GetCamera()
            if not c or not c.Parent then return end
            local t = math.clamp(tonumber(Configuration.ViewFOV) or 90, 60, 140)
            if math.abs((c.FieldOfView or t) - t) > 0.05 then
                pcall(function() c.FieldOfView = t end)
            end
        end)
    end)
    CameraAssist.ViewFOVBound = ok
    _G.__CELESTIAL_H_viewfov_bind = CameraAssist.ViewFOVBindName
end
function CameraAssist.UnbindViewFOV()
    CameraAssist.ViewFOVBound = false
    pcall(function() Utility.RunService:UnbindFromRenderStep(CameraAssist.ViewFOVBindName) end)
end
function CameraAssist.AttachCamWatcher()
    if CameraAssist.CamSignalConn then
        pcall(function() CameraAssist.CamSignalConn:Disconnect() end)
        CameraAssist.CamSignalConn = nil
    end
    local cam = Utility.GetCamera()
    if not cam then return end
    pcall(function()
        CameraAssist.CamSignalConn = cam:GetPropertyChangedSignal("CFrame"):Connect(function()
            if CameraAssist.ShuttingDown then return end
            if not CameraAssist.Lock then return end
            if not CameraAssist.DesiredLook then return end
            local lk = CameraAssist.Lock
            if not lk.Character or not lk.Character.Parent then return end
            local inc = cam.CFrame
            if CameraAssist.LastWrittenCF and inc == CameraAssist.LastWrittenCF then return end
            local ok, cf = pcall(function() return CFrame.lookAt(inc.Position, inc.Position + CameraAssist.DesiredLook, Vector3.new(0, 1, 0)) end)
            if not ok or not cf then return end
            CameraAssist.LastWrittenCF = cf
            pcall(function() cam.CFrame = cf end)
        end)
    end)
end
function CameraAssist.AttachCameraSwapHook()
    if CameraAssist.CamSwapConn then
        pcall(function() CameraAssist.CamSwapConn:Disconnect() end)
        CameraAssist.CamSwapConn = nil
    end
    pcall(function()
        CameraAssist.CamSwapConn = Utility.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            task.wait(0.05)
            CameraAssist.AttachCamWatcher()
        end)
    end)
end
function CameraAssist.InitFocusTracking()
    pcall(function()
        Connections.Track(Utility.UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                CameraAssist.MouseAccumX = CameraAssist.MouseAccumX + input.Delta.X
                CameraAssist.MouseAccumY = CameraAssist.MouseAccumY + input.Delta.Y
            end
        end))
    end)
    pcall(function()
        Connections.Track(Utility.UserInputService.InputBegan:Connect(function(input)
            if Configuration.AimBindType == "Mouse" then
                if input.UserInputType == Configuration.AimMouseButton then CameraAssist.KeyHeld = true end
            else
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Configuration.AimKeyCode then CameraAssist.KeyHeld = true end
            end
        end))
    end)
    pcall(function()
        Connections.Track(Utility.UserInputService.InputEnded:Connect(function(input)
            if Configuration.AimBindType == "Mouse" then
                if input.UserInputType == Configuration.AimMouseButton then CameraAssist.KeyHeld = false end
            else
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Configuration.AimKeyCode then CameraAssist.KeyHeld = false end
            end
        end))
    end)
    pcall(function()
        Connections.Track(Utility.UserInputService.InputBegan:Connect(function(input)
            local uit = input.UserInputType
            local isPad = uit == Enum.UserInputType.Gamepad1 or uit == Enum.UserInputType.Gamepad2 or uit == Enum.UserInputType.Gamepad3 or uit == Enum.UserInputType.Gamepad4
            if isPad then
                CameraAssist.LastInputWasController = true
                if input.KeyCode == Configuration.AimControllerButton then CameraAssist.KeyHeld = true end
                if input.KeyCode == Configuration.AutoFireControllerButton then CameraAssist.ControllerFireHeld = true end
            else
                if uit == Enum.UserInputType.MouseButton1 or uit == Enum.UserInputType.MouseMovement or uit == Enum.UserInputType.Keyboard then
                    CameraAssist.LastInputWasController = false
                end
            end
        end))
    end)
    pcall(function()
        Connections.Track(Utility.UserInputService.InputEnded:Connect(function(input)
            local uit = input.UserInputType
            local isPad = uit == Enum.UserInputType.Gamepad1 or uit == Enum.UserInputType.Gamepad2 or uit == Enum.UserInputType.Gamepad3 or uit == Enum.UserInputType.Gamepad4
            if isPad then
                if input.KeyCode == Configuration.AimControllerButton then CameraAssist.KeyHeld = false end
                if input.KeyCode == Configuration.AutoFireControllerButton then CameraAssist.ControllerFireHeld = false end
            end
        end))
    end)
end
function CameraAssist.MutePostFX()
    CameraAssist.SavedPostFX = {}
    local L = game:GetService("Lighting")
    for _, inst in ipairs(L:GetChildren()) do
        if inst:IsA("BlurEffect") or inst:IsA("DepthOfFieldEffect") then
            if inst.Enabled then
                CameraAssist.SavedPostFX[inst] = true
                pcall(function() inst.Enabled = false end)
            end
        end
    end
end
function CameraAssist.RestorePostFX()
    local s = CameraAssist.SavedPostFX
    CameraAssist.SavedPostFX = {}
    for inst, _ in pairs(s) do if inst and inst.Parent then pcall(function() inst.Enabled = true end) end end
end
function CameraAssist.ClearLock()
    if CamControls and CamControls.SetRotation then
        local cam = Utility.GetCamera()
        if cam then pcall(function() CamControls:SetRotation(cam.CFrame) end) end
    end
    if CameraAssist.Lock and CameraAssist.Lock.UserId then
        CameraAssist.PreferUserId = CameraAssist.Lock.UserId
        CameraAssist.PreferUntil = tick() + 0.6
    end
    CameraAssist.Lock = nil CameraAssist.LastLockUserId = nil
    CameraAssist.DesiredLook = nil CameraAssist.LastWrittenCF = nil
    CameraAssist.LockedTargetWorldPos = nil CameraAssist.AimState = nil CameraAssist.AimStateChar = nil
    CameraAssist.LastTargetPos = nil CameraAssist.LastTargetPosTime = 0
    pcall(function()
        local lp = Utility.Players.LocalPlayer
        local mc = lp and lp.Character
        if mc then
            local hum = mc:FindFirstChildOfClass("Humanoid")
            local my = mc:FindFirstChild("HumanoidRootPart")
            if hum and CameraAssist.SavedAutoRotate ~= nil then
                hum.AutoRotate = CameraAssist.SavedAutoRotate
                CameraAssist.SavedAutoRotate = nil
            end
            if my then
                local g = my:FindFirstChild("CELESTIAL_H_AimGyro")
                if g then g:Destroy() end
            end
        end
    end)
end
function CameraAssist.IsTargetSticky(lk)
    if not lk or not lk.Character or not lk.Character.Parent then return false end
    local cam = Utility.GetCamera()
    if not cam then return true end
    local res = lk.ResolvedHitbox or Configuration.CameraAssistHitboxMode or "Head"
    local pos = Utility.GetHitboxPosition(lk.Character, res, lk.HitboxPart)
    if not pos then return false end
    local cp = cam.CFrame.Position
    local look = cam.CFrame.LookVector
    local dl = pos - cp
    local dist = dl.Magnitude
    if dist < 0.1 then return true end
    local dir = dl / dist
    local dot = math.clamp(look:Dot(dir), -1, 1)
    local ad = math.deg(math.acos(dot))
    local activeFov = Configuration.SilentAimEnabled
        and (Configuration.SilentAimFOV or 200)
        or  (Configuration.CameraAssistFOV or 35)
    local sm = Configuration.CameraAssistSmoothing or 0
    local ss = 1.0 - (math.min(sm, 20) / 20) * 0.5
    local ba = math.max(activeFov * 0.9, 18)
    local sa = ba * 1.6 * ss
    if Utility.IsLocalAirborne() then sa = sa * 2.2 end
    return ad <= sa
end
function CameraAssist.MakeLock(pd, resolvedMode)
    local silent = Configuration.SilentAimEnabled
    local um = silent and (Configuration.SilentAimHitbox or "Head")
                        or (Configuration.CameraAssistHitboxMode or "Head")
    local res = resolvedMode or Utility.ResolveHitboxMode(um)
    local pos, part = Utility.GetHitboxPosition(pd.Character, res)
    if pos and res == "Head" and HEAD_AIM_OFFSET ~= 0 then
        pos = pos + Vector3.new(0, HEAD_AIM_OFFSET, 0)
    end
    local now = tick()
    return { UserId = pd.UserId, Player = pd.Player, Character = pd.Character,
             UserMode = um, ResolvedHitbox = res, HitboxPart = part,
             LastPos = pos, LastPosTime = pos and now or 0, Visible = true, MissFrames = 0 }
end
function CameraAssist.UpdateLock(lk)
    if not lk then return false end
    local silent = Configuration.SilentAimEnabled
    local expected = silent and (Configuration.SilentAimHitbox or "Head")
                            or (Configuration.CameraAssistHitboxMode or "Head")
    if lk.UserMode ~= expected then return false end
    local p = lk.Player
    if not p or not p.Parent then return false end
    local c = lk.Character
    if not c or not c.Parent then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    if Utility.IsTargetDeflecting(p) then
        CameraAssist._deflectCooldownUntil = tick() + 0.40
        CameraAssist._deflectCooldownUser = p.UserId
        return false
    end
    if CameraAssist._deflectCooldownUser == p.UserId
        and tick() < (CameraAssist._deflectCooldownUntil or 0) then
        return false
    end
    if lk.HitboxPart and lk.HitboxPart.Parent then
        local allowed = Utility.HitboxModes[lk.ResolvedHitbox] or Utility.HitboxModes.Head
        local okname = false
        for _, n in ipairs(allowed) do
            if lk.HitboxPart.Name == n then okname = true break end
        end
        if not okname then lk.HitboxPart = nil end
    else
        lk.HitboxPart = nil
    end
    local pos, part = Utility.GetHitboxPosition(c, lk.ResolvedHitbox, lk.HitboxPart)
    if pos then
        if lk.ResolvedHitbox == "Head" and HEAD_AIM_OFFSET ~= 0 then
            pos = pos + Vector3.new(0, HEAD_AIM_OFFSET, 0)
        end
        lk.LastPos = pos
        lk.LastPosTime = tick()
        if part then lk.HitboxPart = part end
    end
    if Configuration.CameraAssistVisibleCheck and lk.LastPos then
        lk.Visible = Utility.IsPositionVisible(lk.LastPos, {c}, tostring(lk.UserId), lk.HitboxPart)
    else lk.Visible = true end
    return true
end
function CameraAssist.AcquireLock()
    if Configuration.LobbyGuardEnabled and not Utility.IsInGame() then return nil end
    local cam = Utility.GetCamera()
    if not cam or not cam.Parent then return nil end
    local cx = cam.ViewportSize.X * 0.5
    local cy = cam.ViewportSize.Y * 0.5
    local sc = Utility.ViewportScale()
    local silent = Configuration.SilentAimEnabled
    local activeFov = silent and (Configuration.SilentAimFOV or 200)
                                or  (Configuration.CameraAssistFOV or 35)
    local br = math.max(activeFov * 10 * sc, 110 * sc)
    if not silent then
        local cap = (Configuration.CameraAssistAcquisitionRadius or 300) * sc
        if cap > 0 and br > cap then br = cap end
    end
    local brSq = br * br
    local pid = CameraAssist.PreferUserId
    local pa = pid and tick() < (CameraAssist.PreferUntil or 0)
    local prSq = (br * 1.8) * (br * 1.8)
    local best, bdSq = nil, math.huge
    local bp, bpdSq = nil, math.huge
    local bres, bpres = nil, nil
    local mode = silent and (Configuration.SilentAimHitbox or "Head")
                        or  (Configuration.CameraAssistHitboxMode or "Head")
    local lpPos = nil
    if silent then
        local lpC = Utility.Players.LocalPlayer and Utility.Players.LocalPlayer.Character
        if lpC then
            local r = lpC:FindFirstChild("HumanoidRootPart")
            if r then lpPos = r.Position end
        end
    end
    for _, pd in ipairs(Utility.GetValidPlayers()) do
        local c = pd.Character
        if c and c.Parent then
            local skip = false
            if CameraAssist._deflectCooldownUser == pd.UserId
                and tick() < (CameraAssist._deflectCooldownUntil or 0) then
                skip = true
            elseif Utility.IsTargetDeflecting(pd.Player) then
                skip = true
            end
            if not skip then
                local rm = mode
                if mode == "Random" then rm = Utility.ResolveHitboxMode("Random") end
                local pos, part = Utility.GetHitboxPosition(c, rm)
                if pos then
                    local el = true
                    if Configuration.CameraAssistVisibleCheck and not silent then
                        if not Utility.IsPositionVisible(pos, {c}, nil, part) then el = false end
                    end
                    if el then
                        local sp, on = Utility.WorldToViewport(pos)
                        if on then
                            local dx = sp.X - cx
                            local dy = sp.Y - cy
                            local dSq = dx * dx + dy * dy
                            if dSq <= brSq then
                                if silent and lpPos then
                                    local d3 = (pos - lpPos).Magnitude
                                    local d3sq = d3 * d3
                                    if pa and pd.UserId == pid and dSq <= prSq then
                                        if d3sq < bpdSq then bpdSq = d3sq bp = pd bpres = rm end
                                    end
                                    if d3sq < bdSq then bdSq = d3sq best = pd bres = rm end
                                else
                                    if pa and pd.UserId == pid and dSq <= prSq then
                                        if dSq < bpdSq then bpdSq = dSq bp = pd bpres = rm end
                                    end
                                    if dSq < bdSq then bdSq = dSq best = pd bres = rm end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if bp then best = bp bres = bpres end
    if not best then return nil end
    if silent and not CameraAssist.Lock then
        local chance = math.clamp(Configuration.SilentAimHitChance or 100, 0, 100)
        if chance < 100 then
            if math.random() * 100 > chance then return nil end
        end
    end
    return CameraAssist.MakeLock(best, bres)
end
function CameraAssist.FindCloserTarget(cl)
    if not Configuration.CameraAssistFOVPriority then return nil end
    if not cl then return nil end
    local switch_cooldown = 0.2
    if (Configuration.CameraAssistSmoothing or 8) <= 4 then switch_cooldown = 0.08 end
    if tick() - (CameraAssist.LastLockSwitchTime or 0) < switch_cooldown then return nil end
    local cam = Utility.GetCamera()
    if not cam or not cam.Parent then return nil end
    local cx = cam.ViewportSize.X * 0.5
    local cy = cam.ViewportSize.Y * 0.5
    local sc = Utility.ViewportScale()
    local br = math.max(Configuration.CameraAssistFOV * 10 * sc, 110 * sc)
    local cap = (Configuration.CameraAssistAcquisitionRadius or 300) * sc
    if cap > 0 and br > cap then br = cap end
    local brSq = br * br
    local mode = Configuration.CameraAssistHitboxMode or "Head"
    local cdSq = math.huge
    if cl.Character and cl.Character.Parent then
        local pos = Utility.GetHitboxPosition(cl.Character, cl.ResolvedHitbox, cl.HitboxPart)
        if pos then
            local sp, on = Utility.WorldToViewport(pos)
            if on then
                local dx = sp.X - cx
                local dy = sp.Y - cy
                cdSq = dx * dx + dy * dy
            end
        end
    end
    local best, bdSq, bres = nil, math.huge, nil
    for _, pd in ipairs(Utility.GetValidPlayers()) do
        if pd.UserId ~= cl.UserId then
            local c = pd.Character
            if c and c.Parent then
                local rm = mode
                local pos, part = Utility.GetHitboxPosition(c, rm)
                if pos then
                    local el = true
                    if Configuration.CameraAssistVisibleCheck then
                        if not Utility.IsPositionVisible(pos, {c}, nil, part) then el = false end
                    end
                    if el then
                        local sp, on = Utility.WorldToViewport(pos)
                        if on then
                            local dx = sp.X - cx
                            local dy = sp.Y - cy
                            local dSq = dx * dx + dy * dy
                            if dSq <= brSq and dSq < bdSq then bdSq = dSq best = pd bres = rm end
                        end
                    end
                end
            end
        end
    end
    if best and bdSq < cdSq * 0.85 then return CameraAssist.MakeLock(best, bres) end
    return nil
end
function CameraAssist.Apply(dt)
    if CameraAssist.ShuttingDown then return end
    if not Configuration.CameraAssistEnabled and not Configuration.SilentAimEnabled then return end
    local mdX = CameraAssist.MouseAccumX or 0
    local mdY = CameraAssist.MouseAccumY or 0
    CameraAssist.MouseAccumX = 0
    CameraAssist.MouseAccumY = 0
    local air = Utility.IsLocalAirborne()
    if air then CameraAssist.AirborneUntil = tick() + 0.35 end
    local inAir = air or tick() < (CameraAssist.AirborneUntil or 0)
    CameraAssist.WasAirborne = air
    local kh = CameraAssist.KeyHeld or (Configuration.CameraAssistAlwaysOn and Configuration.CameraAssistEnabled)
    local typing = false
    pcall(function() typing = Utility.UserInputService:GetFocusedTextBox() ~= nil end)
    if typing then kh = false end
    local cam = Utility.GetCamera()
    if not cam or not cam.Parent then return end
    local lp = Utility.Players.LocalPlayer
    local mc = lp and lp.Character
    if not mc or not mc.Parent then return end
    if Configuration.LobbyGuardEnabled and not Utility.IsInGame() then
        if CameraAssist.Lock then CameraAssist.ClearLock() end
        if next(CameraAssist.SavedPostFX) then CameraAssist.RestorePostFX() end
        CameraAssist.AimState = nil CameraAssist.AimStateChar = nil CameraAssist.BlockFireTarget = nil
        return
    end
    local myHum = mc:FindFirstChildOfClass("Humanoid")
    local subj = cam.CameraSubject
    local spectating = false
    if not myHum then spectating = true
    elseif myHum.Health <= 0 then spectating = true
    elseif subj and subj:IsA("Humanoid") and subj ~= myHum then spectating = true end
    if spectating then
        if CameraAssist.Lock then CameraAssist.ClearLock() end
        if next(CameraAssist.SavedPostFX) then CameraAssist.RestorePostFX() end
        CameraAssist.DesiredLook = nil CameraAssist.LastWrittenCF = nil CameraAssist.BlockFireTarget = nil
        return
    end
    if CameraAssist.Lock and CameraAssist.Lock.Player then
        local lkp = CameraAssist.Lock.Player
        if Utility.IsTargetDeflecting(lkp) then
            CameraAssist._deflectCooldownUntil = tick() + 0.40
            CameraAssist._deflectCooldownUser = lkp.UserId
            CameraAssist.ClearLock()
            CameraAssist.AimState = nil CameraAssist.AimStateChar = nil
            CameraAssist.BlockFireTarget = nil CameraAssist.DesiredLook = nil CameraAssist.LastWrittenCF = nil
            return
        end
        if CameraAssist._deflectCooldownUser == lkp.UserId
            and tick() < (CameraAssist._deflectCooldownUntil or 0) then
            CameraAssist.DesiredLook = nil CameraAssist.LastWrittenCF = nil CameraAssist.BlockFireTarget = nil
            return
        end
    end
    local scoped = false
    local fov = cam.FieldOfView
    if fov and fov >= 5 then
        local now2 = tick()
        if fov > Utility.RecentMaxFOV then Utility.RecentMaxFOV = fov Utility.RecentMaxFOVTime = now2
        else
            if (now2 - Utility.RecentMaxFOVTime) > 2.0 then
                Utility.RecentMaxFOV = math.max(Utility.RecentMaxFOV * 0.997, 40)
                Utility.RecentMaxFOVTime = now2
            end
        end
        local base = math.max(Utility.RecentMaxFOV, 40)
        if CameraAssist.WasScoped then scoped = fov < (base * 0.92)
        else scoped = fov < (base * 0.80) end
    end
    CameraAssist.WasScoped = scoped
    if Utility.IsReloading() then
        if CameraAssist.Lock then CameraAssist.ClearLock() end
        CameraAssist.AimState = nil CameraAssist.AimStateChar = nil CameraAssist.BlockFireTarget = nil
        return
    end
    if not kh then
        if CameraAssist.Lock then CameraAssist.ClearLock() end
        if next(CameraAssist.SavedPostFX) then CameraAssist.RestorePostFX() end
        CameraAssist.LockedTargetWorldPos = nil CameraAssist.AimState = nil
        CameraAssist.AimStateChar = nil CameraAssist.BlockFireTarget = nil
        return
    end
    if Configuration.CameraAssistFOVPriority and CameraAssist.Lock and not inAir and not Configuration.SilentAimEnabled then
        local cl = CameraAssist.FindCloserTarget(CameraAssist.Lock)
        if cl then
            CameraAssist.Lock = cl
            CameraAssist.AimState = nil CameraAssist.AimStateChar = nil
            CameraAssist.LastLockSwitchTime = tick()
            CameraAssist.UpdateLock(cl)
        end
    end
    if CameraAssist.Lock then
        local lk = CameraAssist.Lock
        local v = CameraAssist.UpdateLock(lk)
        if not v then CameraAssist.ClearLock()
        else
            local st = CameraAssist.IsTargetSticky(lk)
            local oc = false
            if Configuration.CameraAssistVisibleCheck and lk.Visible == false then oc = true end
            if st and not oc then lk.MissFrames = 0
            else
                if inAir then lk.MissFrames = 0 lk.Visible = true
                else
                    CameraAssist.DesiredLook = nil
                    lk.MissFrames = (lk.MissFrames or 0) + 1
                    local base_grace = CameraAssist.MissGrace
                    if (Configuration.CameraAssistSmoothing or 8) <= 4 then
                        base_grace = base_grace + 6
                    end
                    local grace = oc and 4 or base_grace
                    if lk.MissFrames > grace then CameraAssist.ClearLock() end
                end
            end
        end
    end
    if not CameraAssist.Lock then
        local nl = CameraAssist.AcquireLock()
        if nl then
            CameraAssist.Lock = nl
            CameraAssist.LastLockUserId = nl.UserId
            CameraAssist.LastAcquirePrint = tick()
            CameraAssist.AimState = nil CameraAssist.AimStateChar = nil
            CameraAssist.LastLockSwitchTime = tick()
            CameraAssist.MutePostFX()
            CameraAssist.UpdateLock(nl)
        end
        if not CameraAssist.Lock then
            CameraAssist.DesiredLook = nil CameraAssist.LastWrittenCF = nil
            CameraAssist.LockedTargetWorldPos = nil CameraAssist.AimState = nil
            CameraAssist.AimStateChar = nil CameraAssist.BlockFireTarget = nil
            if next(CameraAssist.SavedPostFX) then CameraAssist.RestorePostFX() end
            return
        end
    end
    local lk = CameraAssist.Lock
    if not lk or not lk.LastPos then return end
    local c = lk.Character
    if not c or not c.Parent then
        CameraAssist.ClearLock() CameraAssist.BlockFireTarget = nil
        return
    end
    CameraAssist.BlockFireTarget = lk.Player
    if lk.LastPos then CameraAssist.LockedTargetWorldPos = lk.LastPos end
    local ccf = cam.CFrame
    local cp = ccf.Position
    if not Utility.IsValidVector(cp) then return end
    local baseLook = ccf.LookVector
    if not Utility.IsValidVector(baseLook) or baseLook.Magnitude < 1e-4 then baseLook = Vector3.new(0, 0, -1) end
    baseLook = baseLook.Unit
    if not CameraAssist.AimState or CameraAssist.AimStateChar ~= c then
        CameraAssist.AimState = clampPitch(baseLook)
        CameraAssist.AimStateChar = c
    end
    local useMouse = Configuration.CameraAssistUseMouseWhileLocking ~= false
        and (Configuration.CameraAssistSmoothing or 8) > 3
    if useMouse and (mdX ~= 0 or mdY ~= 0) then
        local sens = 0.15
        baseLook = applyMouseDelta(baseLook, -mdX * sens, -mdY * sens)
    end
    local now = tick()
    if now - (CameraAssist.LastPingUpdate or 0) > 3.0 then
        CameraAssist.LastPingUpdate = now
        pcall(function()
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            if ping and ping > 0 then CameraAssist.PingEstimate = math.clamp(ping / 1000, 0.02, 0.20) end
        end)
    end
    local tp = lk.LastPos
    local ts = 0
    local tv = nil
    local rt = c:FindFirstChild("HumanoidRootPart")
    if rt then
        pcall(function() tv = rt.AssemblyLinearVelocity end)
        if not tv then pcall(function() tv = rt.Velocity end) end
        if tv and Utility.IsValidVector(tv) then ts = tv.Magnitude end
        if ts < 0.5 then
            local cpos = rt.Position
            if CameraAssist.LastTargetPos and CameraAssist.LastTargetPosTime > 0 then
                local ddt = now - CameraAssist.LastTargetPosTime
                if ddt > 0.001 and ddt < 0.5 then
                    local diff = (cpos - CameraAssist.LastTargetPos) / ddt
                    if Utility.IsValidVector(diff) then tv = diff ts = diff.Magnitude end
                end
            end
            CameraAssist.LastTargetPos = cpos
            CameraAssist.LastTargetPosTime = now
        else
            CameraAssist.LastTargetPos = rt.Position
            CameraAssist.LastTargetPosTime = now
        end
    end
    local predEnabled = Configuration.CameraAssistPrediction
        and (Configuration.CameraAssistSmoothing or 8) > 3
    if predEnabled and tv and ts > 4 then
        local dist = (tp - cp).Magnitude
        local bs = math.max(Configuration.CameraAssistBulletSpeed or 400, 50)
        local ow = math.clamp(CameraAssist.PingEstimate or 0.06, 0, 0.15) * 0.5
        local ul = math.max(Configuration.CameraAssistLead or 0.02, 0)
        local tr = math.min(dist / bs + ul + ow, 0.25)
        local flatVel = Vector3.new(tv.X, 0, tv.Z)
        local pr = flatVel * tr
        local mo = math.min(2.0, dist * 0.25)
        if pr.Magnitude > mo then pr = pr.Unit * mo end
        tp = tp + pr
    end
    local td = tp - cp
    local tdist = td.Magnitude
    if tdist < 0.01 then return end
    td = td.Unit
    local es = Configuration.CameraAssistSmoothing or 0
    if scoped then es = es / math.max(Configuration.CameraAssistScopeSpeed or 1.0, 0.1) end
    local source = useMouse and baseLook or (CameraAssist.AimState or baseLook)
    local dot = math.clamp(source:Dot(td), -1, 1)
    local ad = math.deg(math.acos(dot))
    local bd = AIM_DEAD_ZONE
    if lk.ResolvedHitbox == "Head" then bd = bd * 0.30 end
    local smooth_val = Configuration.CameraAssistSmoothing or 8
    if smooth_val <= 4 then bd = bd * 0.25
    elseif smooth_val <= 8 then bd = bd * 0.55 end
    local df = 1 + math.clamp(tdist / 500, 0, 1) * 0.4
    local dz = bd * df
    local skip = false
    if Configuration.CameraAssistVisibleCheck and lk.Visible == false and not inAir then skip = true end
    local finalAim
    if skip then finalAim = source
    elseif ad < dz then finalAim = source
    else
        local f = smoothingToFactor(es, dt)
        f = f * (Configuration.CameraAssistMouseSensitivity or 1)
        f = math.clamp(f, 0, 1)
        CameraAssist.LastFactor = f
        CameraAssist.LastEffSmoothing = es
        if f >= 1 then finalAim = td
        else
            local lp2 = source:Lerp(td, f)
            finalAim = (lp2.Magnitude > 1e-4) and lp2.Unit or td
        end
    end
    CameraAssist.AimState = clampPitch(finalAim)
    if Configuration.CameraAssistVisibleCheck and lk.Visible == false and not inAir then
        CameraAssist.DesiredLook = nil CameraAssist.LastWrittenCF = nil
        return
    end
    local fl = CameraAssist.AimState
    if not fl or fl.Magnitude < 1e-4 then return end
    fl = clampPitch(fl.Unit)
    if Configuration.SilentAimEnabled then
        CameraAssist.DesiredLook = nil
        CameraAssist.LastWrittenCF = nil
        if Configuration.CameraAssistRotateChar then
            pcall(function()
                local my = mc:FindFirstChild("HumanoidRootPart")
                if my then
                    local g = my:FindFirstChild("CELESTIAL_H_AimGyro")
                    if g then g:Destroy() end
                end
            end)
        end
        return
    end
    CameraAssist.DesiredLook = fl
    if Configuration.CameraAssistRotateChar and not air then
        local my = mc:FindFirstChild("HumanoidRootPart")
        local hum = mc:FindFirstChildOfClass("Humanoid")
        if my and hum then
            local flat = Vector3.new(fl.X, 0, fl.Z)
            if flat.Magnitude > 0.001 then
                flat = flat.Unit
                local ty = math.atan2(-flat.X, -flat.Z)
                pcall(function()
                    if CameraAssist.SavedAutoRotate == nil then
                        CameraAssist.SavedAutoRotate = hum.AutoRotate
                    end
                    hum.AutoRotate = false
                    local g = my:FindFirstChild("CELESTIAL_H_AimGyro")
                    if g then g:Destroy() end
                    local curYaw = math.atan2(-my.CFrame.LookVector.X, -my.CFrame.LookVector.Z)
                    local dy = math.atan2(math.sin(ty - curYaw), math.cos(ty - curYaw))
                    local sm = Configuration.CameraAssistSmoothing or 8
                    local maxStep
                    if sm <= 1 then maxStep = math.rad(180)
                    elseif sm <= 3 then maxStep = math.rad(90)
                    elseif sm <= 7 then maxStep = math.rad(45)
                    elseif sm <= 12 then maxStep = math.rad(25)
                    else maxStep = math.rad(15) end
                    dy = math.clamp(dy, -maxStep, maxStep)
                    local newYaw = curYaw + dy
                    my.CFrame = CFrame.new(my.Position) * CFrame.Angles(0, newYaw, 0)
                end)
            end
        end
    else
        pcall(function()
            local my = mc:FindFirstChild("HumanoidRootPart")
            local hum = mc:FindFirstChildOfClass("Humanoid")
            if my then
                local g = my:FindFirstChild("CELESTIAL_H_AimGyro")
                if g then g:Destroy() end
            end
            if hum and CameraAssist.SavedAutoRotate ~= nil then
                hum.AutoRotate = CameraAssist.SavedAutoRotate
                CameraAssist.SavedAutoRotate = nil
            end
        end)
    end
    local ncf
    local ok, res = pcall(function() return CFrame.lookAt(cp, cp + fl, Vector3.new(0, 1, 0)) end)
    if ok and res then ncf = res else ncf = CFrame.new(cp, cp + fl) end
    CameraAssist.LastWrittenCF = ncf
    pcall(function() cam.CFrame = ncf end)
    if CamControls and CamControls.SetRotation then
        pcall(function() CamControls:SetRotation(ncf) end)
    end
end
function CameraAssist.Bind()
    if CameraAssist.Bound then return end
    CameraAssist.Bound = true
    pcall(function() Utility.RunService:UnbindFromRenderStep(CameraAssist.BindName) end)
    pcall(function()
        Utility.RunService:BindToRenderStep(CameraAssist.BindName, Enum.RenderPriority.Camera.Value + 10000, function(dt)
            if CameraAssist.ShuttingDown then return end
            pcall(function() CameraAssist.Apply(dt) end)
        end)
    end)
    CameraAssist.AttachCamWatcher()
    CameraAssist.AttachCameraSwapHook()
    _G.__CELESTIAL_H_last_bind = CameraAssist.BindName
end
function CameraAssist.Unbind()
    if not CameraAssist.Bound then return end
    CameraAssist.Bound = false
    pcall(function() Utility.RunService:UnbindFromRenderStep(CameraAssist.BindName) end)
    if CameraAssist.CamSignalConn then pcall(function() CameraAssist.CamSignalConn:Disconnect() end) CameraAssist.CamSignalConn = nil end
    if CameraAssist.CamSwapConn then pcall(function() CameraAssist.CamSwapConn:Disconnect() end) CameraAssist.CamSwapConn = nil end
end
_G.__CELESTIAL_H_CameraAssist = CameraAssist

local function weaponWatcher()
    task.spawn(function()
        while true do
            task.wait(0.5)
            if CameraAssist.ShuttingDown then return end
            if Configuration.WeaponProfilesEnabled and Configuration.WeaponAutoDetect then
                local cat, raw = detectWeapon()
                if cat ~= ActiveWeaponName then
                    saveActiveProfile()
                    ActiveWeaponName = cat
                    applyProfile(cat)
                    if _G.__CELESTIAL_H_WeaponChanged then pcall(_G.__CELESTIAL_H_WeaponChanged, cat, raw) end
                end
            end
        end
    end)
end
weaponWatcher()

local AutoFire = {}
AutoFire.LastFireTime = 0 AutoFire.IsFiring = false AutoFire.FireStart = 0
AutoFire.LastWorkingMethod = nil AutoFire.KeyHeld = false

function AutoFire.RaycastCheck()
    if Configuration.LobbyGuardEnabled and not Utility.IsInGame() then return nil end
    local cam = Utility.GetCamera()
    if not cam then return nil end
    local lp = Utility.Players.LocalPlayer
    if not lp or not lp.Character then return nil end
    local hp, hpos, hm = Utility.CameraRaycast(Configuration.AutoFireMaxDistance or 1000)
    if hp and hm then
        local p = Utility.Players:GetPlayerFromCharacter(hm)
        if p and p ~= lp and Utility.IsEnemy(lp, p) then
            local h = hm:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and Utility.IsTargetablePart(hp) then
                if Utility.IsTargetDeflecting(p) then return nil end
                return p, hp.Name, hpos
            end
        end
    end
    if Configuration.AutoFireProximityFallback ~= false then
        local cp = cam.CFrame.Position
        local lk = cam.CFrame.LookVector
        local md = Configuration.AutoFireMaxDistance or 1000
        local at = math.rad(Configuration.AutoFireProximityAngle or 2.5)
        local bp2, bpart, bpos = nil, nil, nil
        local bs = math.huge
        local sm = Configuration.CameraAssistHitboxMode or "Head"
        if sm == "Random" then sm = Utility.ResolveHitboxMode("Random") end
        for _, pd in ipairs(Utility.GetValidPlayers()) do
            local c = pd.Character
            if c and c.Parent then
                if not Utility.IsTargetDeflecting(pd.Player) then
                    local pos, part = Utility.GetHitboxPosition(c, sm)
                    if pos then
                        local dl = pos - cp
                        local dist = dl.Magnitude
                        if dist > 0.5 and dist <= md then
                            local dir = dl / dist
                            local dot = lk:Dot(dir)
                            if dot > 0 then
                                local ang = math.acos(math.clamp(dot, -1, 1))
                                local ha = math.max(at, math.atan(0.7 / dist))
                                if ang <= ha then
                                    local sc2 = ang / ha + dist / md * 0.05
                                    if sc2 < bs then bs = sc2 bp2 = pd.Player bpart = part and part.Name or sm bpos = pos end
                                end
                            end
                        end
                    end
                end
            end
        end
        if bp2 then
            if Configuration.AutoFireVisibleCheck then
                local tc = bp2.Character
                if tc and tc.Parent then
                    local vp, vp_part = Utility.GetHitboxPosition(tc, sm)
                    if vp and not Utility.IsPositionVisible(vp, {tc}, tostring(bp2.UserId), vp_part) then return nil end
                end
            end
            return bp2, bpart, bpos
        end
    end
    return nil
end
function AutoFire.ShouldFire()
    if not Configuration.AutoFireEnabled then return false, nil end
    if not Configuration.AutoFireAlwaysOn then if not AutoFire.KeyHeld then return false, nil end end
    if Configuration.LobbyGuardEnabled and not Utility.IsInGame() then return false, nil end
    local cam = Utility.GetCamera()
    if not cam or not cam.Parent then return false, nil end
    local now = tick()
    if now - AutoFire.LastFireTime < Configuration.AutoFireDelay then return false, nil end
    if CameraAssist.LastInputWasController and not CameraAssist.ControllerFireHeld then return false, nil end
    if tick() < (CameraAssist._deflectCooldownUntil or 0) then return false, nil end
    local p, pn, hp = AutoFire.RaycastCheck()
    if p then return true, {player=p, part=pn, position=hp} end
    return false, nil
end
function AutoFire.FireOnce()
    local m = nil
    if ExecutorInfo.HasMouse1Click then
        local ok = pcall(mouse1click)
        if ok then m = "mouse1click" end
    end
    if not m and ExecutorInfo.HasMouse1Press then
        local ok = pcall(function() mouse1press() task.wait(0.02) mouse1release() end)
        if ok then m = "mouse1press" end
    end
    if not m and ExecutorInfo.HasVIM then
        local cam = Utility.GetCamera()
        local vp = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
        local cx = math.floor(vp.X * 0.5)
        local cy = math.floor(vp.Y * 0.5)
        local ok = pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.02)
            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end)
        if ok then m = "VIM" end
    end
    if not m and ExecutorInfo.HasKeyPress then
        local ok = pcall(function() keypress(0x01) task.wait(0.02) keyrelease(0x01) end)
        if ok then m = "keypress" end
    end
    if m and m ~= AutoFire.LastWorkingMethod then AutoFire.LastWorkingMethod = m end
    return m ~= nil
end
function AutoFire.Execute(fd)
    if not fd then return end
    if AutoFire.IsFiring then
        if tick() - AutoFire.FireStart > 0.5 then AutoFire.IsFiring = false
        else return end
    end
    local p = fd.player
    if not p or not p.Parent then return end
    local c = p.Character
    if not c or not c.Parent then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return end
    if Utility.IsTargetDeflecting(p) then return end
    if tick() < (CameraAssist._deflectCooldownUntil or 0) then return end
    if Configuration.AutoFireVisibleCheck then
        local pos, part = Utility.GetHitboxPosition(c, Configuration.CameraAssistHitboxMode or "Head")
        if pos and not Utility.IsPositionVisible(pos, {c}, nil, part) then return end
    end
    AutoFire.IsFiring = true
    AutoFire.FireStart = tick()
    AutoFire.FireOnce()
    AutoFire.LastFireTime = tick()
    AutoFire.IsFiring = false
end
function AutoFire.CheckAndFire()
    local s, d = AutoFire.ShouldFire()
    if s then AutoFire.Execute(d) end
end

local WatermarkControl = {Gui = nil, Enabled = true, Labels = {}, Connection = nil}
local HUDControl = {
    Root=nil, Stats=nil, Keybinds=nil, Graph=nil, Watermark=nil,
    Alive=false, StartedAt=os.clock(), Connection=nil, HealthConnection=nil,
    Rows=nil, BindWidgets=nil, Bars=nil, Status=nil,
}

local function guiParents()
    local out = {}
    local seen = {}
    local function add(x)
        if x and not seen[x] then seen[x]=true; table.insert(out,x) end
    end
    if type(gethui) == "function" then pcall(function() add(gethui()) end) end
    pcall(function() add(game:GetService("CoreGui")) end)
    pcall(function()
        local lp=Utility.Players.LocalPlayer
        if lp then add(lp:FindFirstChildOfClass("PlayerGui")) end
    end)
    return out
end

local function findGui(name)
    for _,par in ipairs(guiParents()) do
        local g=par:FindFirstChild(name)
        if g then return g end
    end
    return nil
end

local function destroyGuiEverywhere(name)
    for _,par in ipairs(guiParents()) do
        local g=par:FindFirstChild(name)
        if g then pcall(function() g:Destroy() end) end
    end
end

local function makeScreenGuiReliable(name, order)
    destroyGuiEverywhere(name)
    local sg=Instance.new("ScreenGui")
    sg.Name=name
    sg.ResetOnSpawn=false
    sg.IgnoreGuiInset=true
    sg.DisplayOrder=order or 100
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    pcall(function() sg.AutoLocalize=false end)
    local ok=false
    for _,par in ipairs(guiParents()) do
        if pcall(function() sg.Parent=par end) and sg.Parent then ok=true break end
    end
    if not ok then pcall(function() sg:Destroy() end); return nil end
    return sg
end

local function fmtPing(ms)
    return string.format("%d ms", math.max(0, math.floor((tonumber(ms) or 0)+0.5)))
end

local function fmtSession(sec)
    sec=math.max(0, math.floor(tonumber(sec) or 0))
    local h=math.floor(sec/3600); local m=math.floor((sec%3600)/60); local ss=sec%60
    return h>0 and string.format("%02d:%02d:%02d",h,m,ss) or string.format("%02d:%02d",m,ss)
end

local function safeKeyName(v)
    local s=tostring(v or "--"):gsub("Enum.KeyCode.",""):gsub("Enum.UserInputType.","")
    s=s:gsub("MouseButton","M"):gsub("LeftShift","LShift"):gsub("RightShift","RShift")
    s=s:gsub("ButtonL2","L2"):gsub("ButtonR2","R2")
    return s
end

local function keyState(bindType, keyCode, mouseButton)
    local u=Utility.UserInputService
    if bindType=="Mouse" then
        local ok,v=pcall(function() return u:IsMouseButtonPressed(mouseButton) end)
        return ok and v==true
    end
    local ok,v=pcall(function() return u:IsKeyDown(keyCode) end)
    return ok and v==true
end

local function keybindRows()
    local rows={
        {label="Menu", active=true, held=false, key=(Configuration.MenuBindType=="Mouse" and safeKeyName(Configuration.MenuMouseButton) or safeKeyName(Configuration.MenuKey))},
        {label="Aim", active=Configuration.CameraAssistEnabled==true, held=(CameraAssist and CameraAssist.KeyHeld==true) or keyState(Configuration.AimBindType,Configuration.AimKeyCode,Configuration.AimMouseButton), key=(Configuration.AimBindType=="Mouse" and safeKeyName(Configuration.AimMouseButton) or safeKeyName(Configuration.AimKeyCode))},
        {label="Trigger", active=Configuration.AutoFireEnabled==true, held=(AutoFire and AutoFire.KeyHeld==true) or keyState(Configuration.AutoFireBindType,Configuration.AutoFireKeyCode,Configuration.AutoFireMouseButton), key=(Configuration.AutoFireBindType=="Mouse" and safeKeyName(Configuration.AutoFireMouseButton) or safeKeyName(Configuration.AutoFireKeyCode))},
        {label="Silent", active=Configuration.SilentAimEnabled==true, held=false, key="TOGGLE"},
        {label="World", active=Configuration.WorldVisualsEnabled==true, held=false, key="TOGGLE"},
        {label="Visuals", active=Configuration.VisualsEnabled==true, held=false, key="TOGGLE"},
        {label="Night Vision", active=Configuration.NightVisionEnabled==true, held=false, key="TOGGLE"},
        {label="Menu Mode", active=true, held=false, key=safeKeyName(Configuration.MenuKey)},
    }
    if Configuration.HUDKeybindsOnlyActive then
        local out={}
        for _,r in ipairs(rows) do if r.active or r.held then table.insert(out,r) end end
        return out
    end
    return rows
end

local function createCard(parent, position, size)
    local card=Instance.new("Frame")
    card.AnchorPoint=Vector2.new(1,0)
    card.Position=position
    card.Size=size
    card.BackgroundColor3=CELESTIAL_HUI.Panel
    card.BackgroundTransparency=.08
    card.BorderSizePixel=0
    card.Parent=parent
    corner(card,10)
    stroke(card,CELESTIAL_HUI.Stroke,1,.20)
    return card
end

local function makeWatermark()
    if WatermarkControl.Gui and WatermarkControl.Gui.Parent then
        WatermarkControl.Gui.Enabled=Configuration.WatermarkEnabled~=false
        return WatermarkControl.Gui
    end
    destroyGuiEverywhere("CELESTIAL_H_Watermark")
    local sg=makeScreenGuiReliable("CELESTIAL_H_Watermark",700)
    if not sg then return nil end
    local bar=Instance.new("Frame")
    bar.AnchorPoint=Vector2.new(0,0)
    bar.Position=UDim2.new(0,16,0,16)
    bar.Size=UDim2.fromOffset(300,42)
    bar.BackgroundColor3=CELESTIAL_HUI.Panel
    bar.BackgroundTransparency=.07
    bar.BorderSizePixel=0
    bar.Parent=sg
    corner(bar,12); stroke(bar,CELESTIAL_HUI.Stroke,1,.18)
    local glow=Instance.new("Frame")
    glow.Size=UDim2.new(0,3,1,-12); glow.Position=UDim2.new(0,8,0,6)
    glow.BackgroundColor3=CELESTIAL_HUI.Accent; glow.BorderSizePixel=0; glow.Parent=bar; corner(glow,2)
    local logo=Instance.new("TextLabel")
    logo.Size=UDim2.fromOffset(150,18); logo.Position=UDim2.new(0,20,0,6)
    logo.BackgroundTransparency=1; logo.Font=Enum.Font.GothamBlack; logo.TextSize=12
    logo.Text="CELESTIAL H"; logo.TextColor3=CELESTIAL_HUI.Text; logo.TextXAlignment=Enum.TextXAlignment.Left; logo.Parent=bar
    local sub=Instance.new("TextLabel")
    sub.Size=UDim2.fromOffset(270,12); sub.Position=UDim2.new(0,20,0,24)
    sub.BackgroundTransparency=1; sub.Font=Enum.Font.GothamMedium; sub.TextSize=7
    sub.TextColor3=CELESTIAL_HUI.TextMuted; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Parent=bar
    local version=Instance.new("TextLabel")
    version.AnchorPoint=Vector2.new(1,0.5); version.Position=UDim2.new(1,-12,0,13)
    version.Size=UDim2.fromOffset(72,16); version.BackgroundTransparency=1; version.Font=Enum.Font.GothamBold
    version.TextSize=8; version.Text="V6"; version.TextColor3=CELESTIAL_HUI.Accent3; version.TextXAlignment=Enum.TextXAlignment.Right; version.Parent=bar
    WatermarkControl.Gui=sg; WatermarkControl.Labels={sub=sub,version=version,logo=logo}; WatermarkControl.Enabled=Configuration.WatermarkEnabled~=false; sg.Enabled=WatermarkControl.Enabled
    if WatermarkControl.Connection then pcall(function() WatermarkControl.Connection:Disconnect() end) end
    WatermarkControl.Connection=Utility.RunService.Heartbeat:Connect(function()
        if not WatermarkControl.Gui or not WatermarkControl.Gui.Parent then return end
        sg.Enabled=Configuration.WatermarkEnabled~=false
        local place="Roblox"
        pcall(function() place=game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or place end)
        local clock=os.date("%H:%M:%S")
        local parts={"CELESTIAL H"}
        if Configuration.WatermarkShowPlace~=false then table.insert(parts,place) end
        if Configuration.WatermarkShowTime~=false then table.insert(parts,clock) end
        sub.Text=table.concat(parts,"  •  ")
        version.Visible=Configuration.WatermarkShowVersion~=false
    end)
    Connections.Track(WatermarkControl.Connection)
    return sg
end

local function setWatermarkEnabled(on)
    Configuration.WatermarkEnabled=on and true or false
    local g=WatermarkControl.Gui
    if not g or not g.Parent then g=makeWatermark() end
    if g then g.Enabled=Configuration.WatermarkEnabled end
end

local function makeHUD()
    if HUDControl.Alive and HUDControl.Stats and HUDControl.Stats.Parent then return end
    destroyGuiEverywhere("CELESTIAL_H_HUD"); destroyGuiEverywhere("CELESTIAL_H_Keybinds"); destroyGuiEverywhere("CELESTIAL_H_Graph")
    if Configuration.HUDEnabled==false then HUDControl.Alive=false; return end
    local stats=makeScreenGuiReliable("CELESTIAL_H_HUD",680)
    local binds=makeScreenGuiReliable("CELESTIAL_H_Keybinds",679)
    local graph=makeScreenGuiReliable("CELESTIAL_H_Graph",678)
    if not stats or not binds or not graph then HUDControl.Alive=false; return end
    HUDControl.Stats=stats; HUDControl.Keybinds=binds; HUDControl.Graph=graph
    local compact=Configuration.HUDCompact==true
    local sw=compact and 205 or 238
    local sh=compact and 125 or 150
    local card=createCard(stats,UDim2.new(1,-18,0,68),UDim2.fromOffset(sw,sh))
    local accent=Instance.new("Frame"); accent.Size=UDim2.new(0,3,1,-18); accent.Position=UDim2.new(0,8,0,9); accent.BackgroundColor3=CELESTIAL_HUI.Accent; accent.BorderSizePixel=0; accent.Parent=card; corner(accent,2)
    local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-26,0,17); title.Position=UDim2.new(0,18,0,9); title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack; title.TextSize=12; title.TextColor3=CELESTIAL_HUI.Text; title.TextXAlignment=Enum.TextXAlignment.Left; title.Text="CELESTIAL H"; title.Parent=card
    local sub=Instance.new("TextLabel"); sub.Size=UDim2.new(1,-26,0,11); sub.Position=UDim2.new(0,18,0,25); sub.BackgroundTransparency=1; sub.Font=Enum.Font.GothamMedium; sub.TextSize=7; sub.Text="CLIENT MONITOR  •  LIVE"; sub.TextColor3=CELESTIAL_HUI.Accent3; sub.TextXAlignment=Enum.TextXAlignment.Left; sub.Parent=card
    local rows={}
    local rowNames={"FPS","PING","SESSION","PLAYERS","CLOCK","SERVER","EXECUTOR","MEMORY","STATUS"}
    for i,name in ipairs(rowNames) do
        local y=40+(i-1)*11
        local l=Instance.new("TextLabel"); l.Size=UDim2.fromOffset(72,11); l.Position=UDim2.new(0,18,0,y); l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold; l.TextSize=7; l.Text=name; l.TextColor3=CELESTIAL_HUI.TextMuted; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=card
        local v=Instance.new("TextLabel"); v.Size=UDim2.new(1,-96,0,11); v.Position=UDim2.new(0,78,0,y); v.BackgroundTransparency=1; v.Font=Enum.Font.GothamMedium; v.TextSize=7; v.Text="--"; v.TextColor3=CELESTIAL_HUI.Text; v.TextXAlignment=Enum.TextXAlignment.Right; v.Parent=card
        rows[name]=v
    end
    HUDControl.Rows=rows

    local kb=createCard(binds,UDim2.new(1,-18,0,216),UDim2.fromOffset(sw,230))
    local kt=Instance.new("TextLabel"); kt.Size=UDim2.new(1,-26,0,18); kt.Position=UDim2.new(0,18,0,10); kt.BackgroundTransparency=1; kt.Font=Enum.Font.GothamBlack; kt.TextSize=11; kt.Text="KEYBINDS"; kt.TextColor3=CELESTIAL_HUI.Text; kt.TextXAlignment=Enum.TextXAlignment.Left; kt.Parent=kb
    local ks=Instance.new("TextLabel"); ks.Size=UDim2.new(1,-26,0,12); ks.Position=UDim2.new(0,18,0,27); ks.BackgroundTransparency=1; ks.Font=Enum.Font.GothamMedium; ks.TextSize=7; ks.Text="STATE / BIND"; ks.TextColor3=CELESTIAL_HUI.TextMuted; ks.TextXAlignment=Enum.TextXAlignment.Left; ks.Parent=kb
    local bindContainer=Instance.new("Frame"); bindContainer.Size=UDim2.new(1,-26,1,-48); bindContainer.Position=UDim2.new(0,13,0,43); bindContainer.BackgroundTransparency=1; bindContainer.Parent=kb
    local bl=Instance.new("UIListLayout"); bl.Padding=UDim.new(0,4); bl.Parent=bindContainer
    local widgets={}
    for i=1,8 do
        local r=Instance.new("Frame"); r.Size=UDim2.new(1,0,0,18); r.BackgroundTransparency=1; r.Parent=bindContainer
        local dot=Instance.new("Frame"); dot.Size=UDim2.fromOffset(5,5); dot.Position=UDim2.new(0,1,.5,-2.5); dot.BackgroundColor3=CELESTIAL_HUI.TextMuted; dot.BorderSizePixel=0; dot.Parent=r; corner(dot,3)
        local rl=Instance.new("TextLabel"); rl.Size=UDim2.new(1,-74,1,0); rl.Position=UDim2.new(0,12,0,0); rl.BackgroundTransparency=1; rl.Font=Enum.Font.GothamMedium; rl.TextSize=8; rl.TextColor3=CELESTIAL_HUI.TextMuted; rl.TextXAlignment=Enum.TextXAlignment.Left; rl.Parent=r
        local rk=Instance.new("TextLabel"); rk.Size=UDim2.fromOffset(58,18); rk.Position=UDim2.new(1,-58,0,0); rk.BackgroundColor3=CELESTIAL_HUI.BtnBg; rk.BackgroundTransparency=.15; rk.BorderSizePixel=0; rk.Font=Enum.Font.GothamBold; rk.TextSize=7; rk.TextColor3=CELESTIAL_HUI.Text; rk.TextXAlignment=Enum.TextXAlignment.Center; rk.Parent=r; corner(rk,5); stroke(rk,CELESTIAL_HUI.Stroke,1,.28)
        widgets[i]={row=r,dot=dot,label=rl,key=rk}
    end
    HUDControl.BindWidgets=widgets

    local graphCard=Instance.new("Frame"); graphCard.AnchorPoint=Vector2.new(1,1); graphCard.Position=UDim2.new(1,-18,1,-18); graphCard.Size=UDim2.fromOffset(sw,76); graphCard.BackgroundColor3=CELESTIAL_HUI.Panel; graphCard.BackgroundTransparency=.08; graphCard.BorderSizePixel=0; graphCard.Parent=graph; corner(graphCard,10); stroke(graphCard,CELESTIAL_HUI.Stroke,1,.2)
    local gl=Instance.new("TextLabel"); gl.Size=UDim2.new(1,-22,0,14); gl.Position=UDim2.new(0,12,0,7); gl.BackgroundTransparency=1; gl.Font=Enum.Font.GothamBold; gl.TextSize=8; gl.Text="PERFORMANCE"; gl.TextColor3=CELESTIAL_HUI.TextMuted; gl.TextXAlignment=Enum.TextXAlignment.Left; gl.Parent=graphCard
    local statline=Instance.new("TextLabel"); statline.Size=UDim2.new(1,-22,0,12); statline.Position=UDim2.new(0,12,0,21); statline.BackgroundTransparency=1; statline.Font=Enum.Font.GothamMedium; statline.TextSize=7; statline.Text="-- fps  •  -- ms  •  -- frame"; statline.TextColor3=CELESTIAL_HUI.Text; statline.TextXAlignment=Enum.TextXAlignment.Left; statline.Parent=graphCard
    local area=Instance.new("Frame"); area.Size=UDim2.new(1,-24,0,31); area.Position=UDim2.new(0,12,0,38); area.BackgroundTransparency=1; area.ClipsDescendants=true; area.Parent=graphCard
    local bars={}
    for i=1,36 do local b=Instance.new("Frame"); b.AnchorPoint=Vector2.new(0,1); b.Size=UDim2.fromOffset(4,4); b.Position=UDim2.new((i-1)/36,0,1,0); b.BackgroundColor3=CELESTIAL_HUI.Accent; b.BackgroundTransparency=.15; b.BorderSizePixel=0; b.Parent=area; corner(b,2); bars[i]=b end
    HUDControl.Bars=bars
    HUDControl.Alive=true; HUDControl.StartedAt=os.clock()
    if HUDControl.Connection then pcall(function() HUDControl.Connection:Disconnect() end) end
    local acc,frames,fps=0,0,60
    HUDControl.Connection=Utility.RunService.RenderStepped:Connect(function(dt)
        if not HUDControl.Alive then return end
        if not stats.Parent or not binds.Parent or not graph.Parent then
            HUDControl.Alive=false
            task.defer(makeHUD)
            return
        end
        acc=acc+dt; frames=frames+1
        if acc<.25 then return end
        fps=math.clamp(math.floor(frames/acc+.5),1,1000); acc=0; frames=0
        local lp=Utility.Players.LocalPlayer
        local ping=0; pcall(function() ping=lp:GetNetworkPing()*1000 end)
        rows.FPS.Text=Configuration.HUDShowFPS==false and "--" or tostring(fps)
        rows.PING.Text=Configuration.HUDShowPing==false and "--" or fmtPing(ping)
        rows.SESSION.Text=Configuration.HUDShowSession==false and "--" or fmtSession(os.clock()-HUDControl.StartedAt)
        rows.PLAYERS.Text=Configuration.HUDShowPlayers==false and "--" or tostring(#Utility.Players:GetPlayers())
        rows.CLOCK.Text=Configuration.HUDShowClock==false and "--" or os.date("%H:%M:%S")
        rows.SERVER.Text=Configuration.HUDShowServer==false and "--" or tostring(game.JobId):sub(1,8)
        rows.EXECUTOR.Text=Configuration.HUDShowExecutor==false and "--" or tostring(ExecutorInfo.Name)
        local mem="--"
        if Configuration.HUDShowMemory==true then pcall(function() mem=string.format("%.1f MB", collectgarbage("count")/1024) end) end
        rows.MEMORY.Text=mem
        rows.STATUS.Text=Configuration.HUDShowStatus==false and "--" or ((Configuration.WorldVisualsEnabled and "WORLD ON") or (Configuration.VisualsEnabled and "VISUALS ON") or "IDLE")
        rows.STATUS.TextColor3 = Configuration.WorldVisualsEnabled and CELESTIAL_HUI.Success or (Configuration.VisualsEnabled and CELESTIAL_HUI.Accent3 or CELESTIAL_HUI.TextMuted)
        rows.CLOCK.TextColor3 = CELESTIAL_HUI.Text
        local pingNum=tonumber(ping) or 0
        rows.PING.TextColor3 = pingNum <= 80 and CELESTIAL_HUI.Success or (pingNum <= 150 and CELESTIAL_HUI.Accent3 or CELESTIAL_HUI.Danger)
        rows.FPS.TextColor3 = fps >= 120 and CELESTIAL_HUI.Success or (fps >= 60 and CELESTIAL_HUI.Accent3 or CELESTIAL_HUI.Danger)
        title.Text=Configuration.HUDShowScriptName==false and "STATUS" or "CELESTIAL H"
        sub.Text=Configuration.HUDShowScriptName==false and "CLIENT MONITOR  •  LIVE" or "CLIENT MONITOR  •  LIVE"
        local rb=keybindRows()
        for i,w in ipairs(widgets) do
            local d=rb[i]
            if d then
                w.row.Visible=true; w.label.Text=d.label; w.key.Text=d.held and "HELD" or d.key
                w.label.TextColor3=d.held and CELESTIAL_HUI.Text or (d.active and CELESTIAL_HUI.Text or CELESTIAL_HUI.TextMuted)
                w.key.TextColor3=d.held and CELESTIAL_HUI.Text or (d.active and CELESTIAL_HUI.Accent3 or CELESTIAL_HUI.TextMuted)
                w.dot.BackgroundColor3=d.held and CELESTIAL_HUI.Success or (d.active and CELESTIAL_HUI.Accent3 or CELESTIAL_HUI.TextMuted)
            else w.row.Visible=false end
        end
        kb.Visible=Configuration.HUDShowKeybinds~=false
        graph.Enabled=Configuration.HUDShowGraph~=false
        stats.Enabled=Configuration.HUDEnabled~=false
        binds.Enabled=Configuration.HUDEnabled~=false
        if Configuration.HUDShowGraph~=false then
            for i=#bars,2,-1 do bars[i].Size=UDim2.fromOffset(4,bars[i-1].Size.Y.Offset) end
            bars[1].Size=UDim2.fromOffset(4,math.floor(31*math.clamp(fps/144,.08,1)))
            statline.Text=string.format("%d fps  •  %s  •  %.1f ms frame",fps,fmtPing(ping),dt*1000)
        end
    end)
    Connections.Track(HUDControl.Connection)
    setWatermarkEnabled(Configuration.WatermarkEnabled~=false)
end

local function destroyHUD()
    HUDControl.Alive=false
    if HUDControl.Connection then pcall(function() HUDControl.Connection:Disconnect() end); HUDControl.Connection=nil end
    if WatermarkControl.Connection then pcall(function() WatermarkControl.Connection:Disconnect() end); WatermarkControl.Connection=nil end
    destroyGuiEverywhere("CELESTIAL_H_HUD"); destroyGuiEverywhere("CELESTIAL_H_Keybinds"); destroyGuiEverywhere("CELESTIAL_H_Graph"); destroyGuiEverywhere("CELESTIAL_H_Watermark")
    Interface._PageRoutes = {}
    HUDControl.Stats=nil; HUDControl.Keybinds=nil; HUDControl.Graph=nil; HUDControl.Rows=nil; HUDControl.BindWidgets=nil; HUDControl.Bars=nil
    WatermarkControl.Gui=nil
end

local function showStartup(onReveal)
    local par = safeGuiParent()
    if not par then if onReveal then pcall(onReveal) end return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "CELESTIAL_H_Startup" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true sg.DisplayOrder = 9999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local okP = pcall(function() sg.Parent = par end)
    if not okP or not sg.Parent then pcall(function() sg.Parent = game:GetService("CoreGui") end) end
    if not sg.Parent then
        pcall(function() sg.Parent = game:GetService("CoreGui") end)
    end
    if not sg.Parent then if onReveal then pcall(onReveal) end return end

    local dead = false
    local pc = Instance.new("Frame")
    pc.Size = UDim2.fromScale(1, 1) pc.BackgroundTransparency = 1 pc.ZIndex = 5 pc.Parent = sg

    local function kill()
        if dead then return end
        dead = true
        pcall(function()
            for _, ch in ipairs(pc:GetChildren()) do
                if ch:IsA("Frame") then ch:Destroy() end
            end
        end)
        pcall(function() sg:Destroy() end)
    end
    task.delay(10, kill)

    local TS = game:GetService("TweenService")

    local bd = Instance.new("Frame")
    bd.Size = UDim2.fromScale(1, 1) bd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bd.BorderSizePixel = 0 bd.ZIndex = 1 bd.Parent = sg

    local halo = Instance.new("Frame")
    halo.AnchorPoint = Vector2.new(0.5, 0.5) halo.Position = UDim2.fromScale(0.5, 0.42)
    halo.Size = UDim2.fromOffset(900, 900)
    halo.BackgroundColor3 = Color3.fromRGB(110, 50, 220)
    halo.BackgroundTransparency = 0.86
    halo.BorderSizePixel = 0 halo.ZIndex = 2 halo.Parent = sg
    local hc = Instance.new("UICorner") hc.CornerRadius = UDim.new(1, 0) hc.Parent = halo

    local function spawnParticle()
        if dead then return end
        local sz = math.random(2, 5)
        local sx = math.random(10, 90) / 100
        local sy = 1.1 + math.random() * 0.15
        local dx = sx + (math.random() - 0.5) * 0.15
        local ey = -0.15 - math.random() * 0.08
        local dr = 4 + math.random() * 2.5
        local p = Instance.new("Frame")
        p.AnchorPoint = Vector2.new(0.5, 0.5) p.Position = UDim2.fromScale(sx, sy)
        p.Size = UDim2.fromOffset(sz, sz) p.BackgroundColor3 = Color3.fromRGB(200, 160, 255)
        p.BackgroundTransparency = 1 p.BorderSizePixel = 0 p.ZIndex = 6 p.Parent = pc
        TS:Create(p, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()
        TS:Create(p, TweenInfo.new(dr, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(dx, ey)}):Play()
        task.delay(dr - 0.8, function()
            if p.Parent then TS:Create(p, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play() end
        end)
        task.delay(dr + 0.1, function() if p.Parent then p:Destroy() end end)
    end

    local lh = Instance.new("Frame")
    lh.Name = "VHolder"
    lh.AnchorPoint = Vector2.new(0.5, 0.5)
    lh.Position = UDim2.fromScale(0.5, 0.36)
    lh.Size = UDim2.fromOffset(400, 400)
    lh.BackgroundTransparency = 1
    lh.ZIndex = 30
    lh.Parent = sg

    local shadow = Instance.new("TextLabel")
    shadow.Size = UDim2.fromScale(1, 1)
    shadow.Position = UDim2.fromOffset(8, 10)
    shadow.BackgroundTransparency = 1
    shadow.Font = Enum.Font.GothamBlack
    shadow.Text = "V"
    shadow.TextSize = 240
    shadow.TextColor3 = Color3.fromRGB(40, 15, 90)
    shadow.TextTransparency = 0.4
    shadow.TextXAlignment = Enum.TextXAlignment.Center
    shadow.TextYAlignment = Enum.TextYAlignment.Center
    shadow.ZIndex = 30
    shadow.Parent = lh

    local vm = Instance.new("TextLabel")
    vm.Size = UDim2.fromScale(1, 1)
    vm.BackgroundTransparency = 1
    vm.Font = Enum.Font.GothamBlack
    vm.Text = "V"
    vm.TextSize = 240
    vm.TextColor3 = Color3.fromRGB(255, 255, 255)
    vm.TextXAlignment = Enum.TextXAlignment.Center
    vm.TextYAlignment = Enum.TextYAlignment.Center
    vm.ZIndex = 31
    vm.Parent = lh

    local vg = Instance.new("UIGradient")
    vg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 205, 255)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(160, 100, 250)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 130, 245)),
    }
    vg.Rotation = 90
    vg.Parent = vm

    local vs = Instance.new("UIStroke")
    vs.Color = Color3.fromRGB(210, 160, 255)
    vs.Thickness = 3
    vs.Transparency = 0.15
    vs.Parent = vm

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5) title.Position = UDim2.fromScale(0.5, 0.66)
    title.Size = UDim2.fromOffset(600, 60) title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack title.Text = "CELESTIAL_H" title.TextSize = 58
    title.TextColor3 = Color3.fromRGB(255, 255, 255) title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 32 title.Parent = sg
    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 210, 255)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(180, 130, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 160, 255)),
    }
    tg.Parent = title
    local ts2 = Instance.new("UIStroke")
    ts2.Color = Color3.fromRGB(170, 120, 255) ts2.Thickness = 1.5 ts2.Transparency = 0.4 ts2.Parent = title
    title.TextTransparency = 1 ts2.Transparency = 1

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0.5) sub.Position = UDim2.fromScale(0.5, 0.725)
    sub.Size = UDim2.fromOffset(600, 20) sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamBold sub.Text = "C E L E S T I A L   H   S U I T E"
    sub.TextSize = 12 sub.TextColor3 = Color3.fromRGB(180, 145, 255)
    sub.TextXAlignment = Enum.TextXAlignment.Center sub.TextTransparency = 1 sub.ZIndex = 32 sub.Parent = sg

    local bg = Instance.new("Frame")
    bg.AnchorPoint = Vector2.new(0.5, 0.5) bg.Position = UDim2.fromScale(0.5, 0.84)
    bg.Size = UDim2.fromOffset(340, 12) bg.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
    bg.BackgroundTransparency = 0.85 bg.BorderSizePixel = 0 bg.ZIndex = 31 bg.Parent = sg
    local bgc = Instance.new("UICorner") bgc.CornerRadius = UDim.new(1, 0) bgc.Parent = bg

    local bt = Instance.new("Frame")
    bt.AnchorPoint = Vector2.new(0.5, 0.5) bt.Position = UDim2.fromScale(0.5, 0.84)
    bt.Size = UDim2.fromOffset(300, 3) bt.BackgroundColor3 = Color3.fromRGB(40, 25, 70)
    bt.BorderSizePixel = 0 bt.ZIndex = 32 bt.Parent = sg
    local btc = Instance.new("UICorner") btc.CornerRadius = UDim.new(1, 0) btc.Parent = bt
    local bf = Instance.new("Frame")
    bf.Size = UDim2.new(0, 0, 1, 0) bf.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
    bf.BorderSizePixel = 0 bf.ZIndex = 33 bf.Parent = bt
    local bfc = Instance.new("UICorner") bfc.CornerRadius = UDim.new(1, 0) bfc.Parent = bf
    local bfg = Instance.new("UIGradient")
    bfg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 80, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 170, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 200, 255)),
    }
    bfg.Parent = bf

    task.spawn(function()
        while not dead do
            spawnParticle()
            task.wait(0.12 + math.random() * 0.06)
        end
    end)

    task.spawn(function()
        pcall(function()
            TS:Create(vm, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 300}):Play()
            TS:Create(shadow, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 300}):Play()
            task.wait(0.35)
            TS:Create(title, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
            TS:Create(ts2, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Transparency = 0.4}):Play()
            task.wait(0.22)
            TS:Create(sub, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 0.1}):Play()

            local barDur = 2.8
            TS:Create(bf, TweenInfo.new(barDur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
            TS:Create(bg, TweenInfo.new(barDur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(344, 5), BackgroundTransparency = 0.9}):Play()

            task.wait(barDur + 0.25)
            if onReveal then pcall(onReveal) end
            dead = true

            for _, p in ipairs(pc:GetChildren()) do
                if p:IsA("Frame") then
                    TS:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
                end
            end

            TS:Create(vm, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextSize = 340, TextTransparency = 0.5}):Play()
            TS:Create(shadow, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {TextSize = 340, TextTransparency = 1}):Play()

            task.delay(0.08, function()
                TS:Create(title, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
                TS:Create(ts2, TweenInfo.new(0.4), {Transparency = 1}):Play()
                TS:Create(sub, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
                TS:Create(vm, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
                TS:Create(vs, TweenInfo.new(0.5), {Transparency = 1}):Play()
                TS:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                TS:Create(bf, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                TS:Create(bt, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            end)

            TS:Create(halo, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                BackgroundTransparency = 1, Size = UDim2.fromOffset(400, 400),
            }):Play()

            task.wait(0.55)
            TS:Create(bd, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            task.wait(0.7)
        end)
        pcall(kill)
    end)
end
_G.__CELESTIAL_H_ShowStartup = function() pcall(showStartup) end

local DiscordPopup = {Gui = nil}
local function makeDiscordPopup()
    if DiscordPopup.Gui and DiscordPopup.Gui.Parent then return end
    local par = safeGuiParent()
    if not par then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "CELESTIAL_H_Discord" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true sg.DisplayOrder = 95 sg.Parent = par
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(0, 1) box.Position = UDim2.new(0, 14, 1, -50)
    box.Size = UDim2.fromOffset(340, 124) box.BackgroundColor3 = Color3.fromRGB(22, 20, 34)
    box.BackgroundTransparency = 0.05 box.BorderSizePixel = 0 box.Parent = sg
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = box
    local st = Instance.new("UIStroke") st.Color = Color3.fromRGB(88, 101, 242) st.Thickness = 1.5 st.Transparency = 0.3 st.Parent = box
    local ti = Instance.new("TextLabel")
    ti.Size = UDim2.new(1, -80, 0, 22) ti.Position = UDim2.new(0, 14, 0, 10)
    ti.BackgroundTransparency = 1 ti.Font = Enum.Font.GothamBold ti.TextSize = 12
    ti.TextColor3 = Color3.fromRGB(180, 170, 255) ti.TextXAlignment = Enum.TextXAlignment.Left
    ti.Text = "CELESTIAL_H - Community" ti.Parent = box
    local cb = Instance.new("TextButton")
    cb.Size = UDim2.fromOffset(22, 22) cb.Position = UDim2.new(1, -32, 0, 10)
    cb.BackgroundColor3 = Color3.fromRGB(40, 30, 60) cb.BorderSizePixel = 0
    cb.Font = Enum.Font.GothamBold cb.TextSize = 14 cb.TextColor3 = Color3.fromRGB(220, 210, 255)
    cb.Text = "x" cb.AutoButtonColor = false cb.Parent = box
    local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 5) cc.Parent = cb
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -28, 0, 62) msg.Position = UDim2.new(0, 14, 0, 36)
    msg.BackgroundTransparency = 1 msg.Font = Enum.Font.GothamMedium msg.TextSize = 11
    msg.TextColor3 = Color3.fromRGB(220, 215, 235) msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top msg.TextWrapped = true
    msg.Text = "If you like our script and dont want to miss out on any updates join our discord.\nFound a bug? Report it in the same server — we read every report."
    msg.Parent = box
    local lb = Instance.new("TextButton")
    lb.Size = UDim2.new(1, -28, 0, 22) lb.Position = UDim2.new(0, 14, 1, -30)
    lb.BackgroundColor3 = Color3.fromRGB(88, 101, 242) lb.BorderSizePixel = 0
    lb.Font = Enum.Font.GothamBold lb.TextSize = 11 lb.TextColor3 = Color3.fromRGB(255, 255, 255)
    lb.Text = "discord.gg/K3vgcVsCsS - tap to copy" lb.AutoButtonColor = false lb.Parent = box
    local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(0, 6) lc.Parent = lb
    local DU = "https://discord.gg/K3vgcVsCsS"
    lb.MouseButton1Click:Connect(function()
        if type(setclipboard) == "function" then pcall(setclipboard, DU) lb.Text = "Copied to clipboard"
        else lb.Text = "discord.gg/K3vgcVsCsS" end
        task.delay(1.5, function() if lb and lb.Parent then lb.Text = "discord.gg/K3vgcVsCsS - tap to copy" end end)
    end)
    local function dis()
        if DiscordPopup.Gui and DiscordPopup.Gui.Parent then pcall(function() sg:Destroy() end) end
        DiscordPopup.Gui = nil
    end
    cb.MouseButton1Click:Connect(dis)
    task.delay(20, dis)
    DiscordPopup.Gui = sg
end

local NightVision = {Active = false, Saved = nil, Effect = nil}
local function NVEnable()
    if NightVision.Active then return end
    NightVision.Active = true
    local L = game:GetService("Lighting")
    NightVision.Saved = { Ambient = L.Ambient, OutdoorAmbient = L.OutdoorAmbient, Brightness = L.Brightness, GlobalShadows = L.GlobalShadows, FogEnd = L.FogEnd, FogStart = L.FogStart }
    pcall(function()
        L.Ambient = Color3.fromRGB(170, 175, 180)
        L.OutdoorAmbient = Color3.fromRGB(180, 185, 190)
        L.Brightness = 3 L.GlobalShadows = false
        L.FogEnd = math.max(L.FogEnd, 2000) L.FogStart = math.max(L.FogStart, 500)
    end)
    if NightVision.Effect and NightVision.Effect.Parent then NightVision.Effect:Destroy() end
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "CELESTIAL_H_NightVision" cc.Brightness = 0.25 cc.Contrast = 0.1 cc.Saturation = 0.05
    cc.TintColor = Color3.fromRGB(210, 230, 210) cc.Parent = L
    NightVision.Effect = cc
end
local function NVDisable()
    if not NightVision.Active then return end
    NightVision.Active = false
    if NightVision.Saved then
        local L = game:GetService("Lighting")
        for k, v in pairs(NightVision.Saved) do pcall(function() L[k] = v end) end
        NightVision.Saved = nil
    end
    if NightVision.Effect and NightVision.Effect.Parent then NightVision.Effect:Destroy() end
    NightVision.Effect = nil
end
local function NVApply() if Configuration.NightVisionEnabled then NVEnable() else NVDisable() end end

local PerformanceTools = {}
PerformanceTools.Saved = {}
PerformanceTools._effectTask = nil
local EFFECT_CLASSES = {
    ParticleEmitter = true, Beam = true, Trail = true, Fire = true, Smoke = true, Sparkles = true,
    PointLight = true, SpotLight = true, SurfaceLight = true,
}
function PerformanceTools.EnableFPSBoost()
    local L = game:GetService("Lighting")
    local ws = game:GetService("Workspace")
    PerformanceTools.Saved = PerformanceTools.Saved or {}
    PerformanceTools.Saved.Lighting = {
        GlobalShadows = L.GlobalShadows, Brightness = L.Brightness,
        EnvironmentDiffuseScale = L.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = L.EnvironmentSpecularScale,
        FogEnd = L.FogEnd, FogStart = L.FogStart,
    }
    pcall(function()
        L.GlobalShadows = false
        L.Brightness = math.max(L.Brightness, 1)
        L.EnvironmentDiffuseScale = 0
        L.EnvironmentSpecularScale = 0
        L.FogEnd = 100000 L.FogStart = 100000
    end)
    PerformanceTools.Saved.PostFX = {}
    for _, e in ipairs(L:GetChildren()) do
        if e:IsA("PostEffect") and e.Name ~= "CELESTIAL_H_NightVision" then
            PerformanceTools.Saved.PostFX[e] = e.Enabled
            pcall(function() e.Enabled = false end)
        end
    end
    pcall(function()
        local us = UserSettings()
        if us and us.Rendering then
            PerformanceTools.Saved._quality = us.Rendering.QualityLevel
            us.Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
    end)
    PerformanceTools.Saved.WorkspaceEffects = {}
    local function cull(inst)
        if EFFECT_CLASSES[inst.ClassName] then
            local ok, en = pcall(function() return inst.Enabled end)
            if ok then
                PerformanceTools.Saved.WorkspaceEffects[inst] = en
                pcall(function() inst.Enabled = false end)
            end
        end
    end
    for _, d in ipairs(ws:GetDescendants()) do cull(d) end
    if PerformanceTools._effectTask then task.cancel(PerformanceTools._effectTask) end
    PerformanceTools._effectTask = task.spawn(function()
        local addedConn
        addedConn = ws.DescendantAdded:Connect(function(d)
            if not Configuration.FPSBoostEnabled then
                if addedConn then addedConn:Disconnect() end
                return
            end
            cull(d)
        end)
        PerformanceTools.Saved._addedConn = addedConn
    end)
end
function PerformanceTools.DisableFPSBoost()
    local L = game:GetService("Lighting")
    local saved = PerformanceTools.Saved or {}
    if saved.Lighting then
        for k, v in pairs(saved.Lighting) do pcall(function() L[k] = v end) end
        saved.Lighting = nil
    end
    if saved.PostFX then
        for inst, state in pairs(saved.PostFX) do
            if inst and inst.Parent then pcall(function() inst.Enabled = state end) end
        end
        saved.PostFX = nil
    end
    if saved.WorkspaceEffects then
        for inst, state in pairs(saved.WorkspaceEffects) do
            if inst and inst.Parent then pcall(function() inst.Enabled = state end) end
        end
        saved.WorkspaceEffects = nil
    end
    if saved._quality then
        pcall(function()
            local us = UserSettings()
            if us and us.Rendering then us.Rendering.QualityLevel = saved._quality end
        end)
        saved._quality = nil
    end
    if saved._addedConn then pcall(function() saved._addedConn:Disconnect() end) saved._addedConn = nil end
    if PerformanceTools._effectTask then
        pcall(function() task.cancel(PerformanceTools._effectTask) end)
        PerformanceTools._effectTask = nil
    end
    PerformanceTools.Saved = {}
end

local FeatureState = {}
local function FeatureApply(id, snapshot, onChange)
    if not FeatureState[id] then FeatureState[id] = { wasOn = false, saved = {} } end
    local st = FeatureState[id]
    local wantOn = snapshot.enabled
    if wantOn and not st.wasOn then
        st.wasOn = true st.saved = {}
        for k, _ in pairs(snapshot.set) do st.saved[k] = Configuration[k] end
        for k, v in pairs(snapshot.set) do Configuration[k] = v end
        if onChange then pcall(onChange, true) end
    elseif not wantOn and st.wasOn then
        st.wasOn = false
        for k, v in pairs(st.saved) do Configuration[k] = v end
        st.saved = {}
        if onChange then pcall(onChange, false) end
    end
end

-- Presence tracking removed for V1 release. The free abacus counter
-- could not handle 50 concurrent hits and was causing HTTP timeouts
-- that blocked the Lua VM in some executors. User counts are now
-- tracked via Discord analytics only.
local Presence = {
    Register = function() end,
    Tick = function() end,
}

local Interface = {}
Interface.ScreenGui = nil Interface.MainFrame = nil
Interface.TabContents = {} Interface.TabButtons = {} Interface.CurrentTab = nil
Interface.CloseButton = nil
Interface._PageRoutes = {}
Interface.TweenService = game:GetService("TweenService")

local C = Palette
local T = Interface.TweenService

local function corner(g, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = g return c end
local function stroke(g, col, th, tr) local s = Instance.new("UIStroke") s.Color = col or C.Border s.Thickness = th or 1 s.Transparency = tr or 0 s.Parent = g return s end

local function routeParent(parent)
    local st = Interface._PageRoutes and Interface._PageRoutes[parent]
    if not st then return parent end
    if st.body and st.body.Parent then return st.body end
    return st.columns[st.current] or parent
end

local function beginSection(parent, text, premium)
    local st = Interface._PageRoutes and Interface._PageRoutes[parent]
    if not st then return parent end
    if st.started then st.current = (st.current == 1) and 2 or 1 else st.started = true end
    local col = st.columns[st.current]
    local card = Instance.new("Frame")
    card.Name = tostring(text):gsub("%W", "_") .. "Card"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.Card
    card.BackgroundTransparency = 0.06
    card.BorderSizePixel = 0
    card.Parent = col
    corner(card, 9)
    stroke(card, C.Border, 1, 0.28)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundTransparency = 1
    header.Parent = card
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 12)
    accent.Position = UDim2.new(0, 10, 0.5, -6)
    accent.BackgroundColor3 = premium and Color3.fromRGB(255,200,40) or C.Accent
    accent.BorderSizePixel = 0
    accent.Parent = header
    corner(accent, 2)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -28, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 9
    title.TextColor3 = premium and Color3.fromRGB(255,210,90) or C.TextMuted
    title.Text = (premium and "★  " or "") .. tostring(text):upper()
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -20, 0, 0)
    body.Position = UDim2.new(0, 10, 0, 30)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.BackgroundTransparency = 1
    body.Parent = card
    local bl = Instance.new("UIListLayout")
    bl.Padding = UDim.new(0, 3)
    bl.SortOrder = Enum.SortOrder.LayoutOrder
    bl.Parent = body
    local bp = Instance.new("UIPadding")
    bp.PaddingBottom = UDim.new(0, 10)
    bp.Parent = body
    st.body = body
    return body
end

local function CSe(parent, text)
    return beginSection(parent, text, false)
end

local function CSeP(parent, text)
    return beginSection(parent, text, true)
end

local PNS = false
local LastPremShown = 0
local function showPrem(customTitle, customBody)
    local now = tick()
    if PNS then return end
    if now - LastPremShown < 0.4 then return end
    LastPremShown = now
    PNS = true
    local par = safeGuiParent()
    if not par then PNS = false return end
    local TT = game:GetService("TweenService")
    local sg = Instance.new("ScreenGui")
    sg.Name = "CELESTIAL_H_Premium" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true sg.DisplayOrder = 97
    pcall(function() sg.Parent = par end)
    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0) card.Position = UDim2.new(0.5, 0, 0, -100)
    card.Size = UDim2.fromOffset(380, 124) card.BackgroundColor3 = Color3.fromRGB(18, 14, 8)
    card.BackgroundTransparency = 1 card.BorderSizePixel = 0 card.ZIndex = 2 card.Parent = sg
    local cardC = Instance.new("UICorner") cardC.CornerRadius = UDim.new(0, 14) cardC.Parent = card
    local cardSt = Instance.new("UIStroke")
    cardSt.Color = Color3.fromRGB(255, 200, 40) cardSt.Thickness = 1.5 cardSt.Transparency = 0.15 cardSt.Parent = card
    local cardScale = Instance.new("UIScale") cardScale.Scale = 0.7 cardScale.Parent = card
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -90, 0, 16) header.Position = UDim2.new(0, 72, 0, 26)
    header.BackgroundTransparency = 1 header.Font = Enum.Font.GothamBlack
    header.Text = customTitle or "PREMIUM REQUIRED" header.TextSize = 12
    header.TextColor3 = Color3.fromRGB(255, 210, 70) header.TextXAlignment = Enum.TextXAlignment.Left
    header.ZIndex = 4 header.Parent = card
    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -90, 0, 30) body.Position = UDim2.new(0, 72, 0, 44)
    body.BackgroundTransparency = 1 body.Font = Enum.Font.GothamMedium
    body.Text = customBody or "This feature is reserved for CELESTIAL_H Premium.\nUnlock it in our Discord."
    body.TextSize = 11 body.TextColor3 = Color3.fromRGB(230, 220, 200)
    body.TextXAlignment = Enum.TextXAlignment.Left body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true body.ZIndex = 4 body.Parent = card
    local cta = Instance.new("TextButton")
    cta.Size = UDim2.new(1, -36, 0, 26) cta.Position = UDim2.new(0, 18, 1, -34)
    cta.BackgroundColor3 = Color3.fromRGB(255, 200, 40) cta.BorderSizePixel = 0
    cta.Font = Enum.Font.GothamBold cta.Text = "COPY DISCORD INVITE" cta.TextSize = 11
    cta.TextColor3 = Color3.fromRGB(28, 22, 10) cta.AutoButtonColor = false cta.ZIndex = 4 cta.Parent = card
    local ctaC = Instance.new("UICorner") ctaC.CornerRadius = UDim.new(0, 7) ctaC.Parent = cta
    local DU = "https://discord.gg/K3vgcVsCsS"
    cta.MouseButton1Click:Connect(function()
        if type(setclipboard) == "function" then pcall(setclipboard, DU) cta.Text = "COPIED" end
    end)
    TT:Create(cardScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    TT:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 14), BackgroundTransparency = 0,
    }):Play()
    task.delay(10, function()
        TT:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1,
        }):Play()
        for _, ch in ipairs(card:GetDescendants()) do
            if ch:IsA("TextLabel") or ch:IsA("TextButton") then
                TT:Create(ch, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
            elseif ch:IsA("UIStroke") then
                TT:Create(ch, TweenInfo.new(0.25), {Transparency = 1}):Play()
            end
        end
        task.delay(0.5, function() pcall(function() sg:Destroy() end) PNS = false end)
    end)
end

local PREMIUM_KEYS = {
    SilentAimEnabled = true, SilentAimHitChance = true,
    SilentAimFOV = true, SilentAimHitbox = true,
    SilentAimDrawFOV = true, SilentAimFOVColor = true,
    HitSoundsEnabled = true, HitSoundChoice = true,
    CustomCrosshairEnabled = true,
    HitboxExpanderEnabled = true, HitboxExpanderSize = true,
    SpinbotEnabled = true, RapidFireEnabled = true,
    MaxAccuracyEnabled = true, NoSpreadEnabled = true,
    ESPTargetVisEnabled = true, ViewmodelChamsEnabled = true,
    FlyNoclipEnabled = true,
    NightVisionEnabled = true, AimLockEnabled = true, RagebotEnabled = true,
}

local ToggleRegistry = {}

local function CTog(parent, text, key, cb)
    local isPrem = PREMIUM_KEYS[key] == true
    local locked = isPrem and not Configuration.IsPremium
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34) row.BackgroundTransparency = 1 row.Parent = routeParent(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -60, 1, 0)
    if isPrem then l.Position = UDim2.new(0, 16, 0, 0) end
    l.BackgroundTransparency = 1 l.Font = Enum.Font.GothamMedium
    l.Text = tostring(text) l.TextSize = 12 l.TextColor3 = C.Text
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = row
    if isPrem then
        local starIcon = Instance.new("TextLabel")
        starIcon.Size = UDim2.fromOffset(16, 14) starIcon.Position = UDim2.new(0, -2, 0.5, -7)
        starIcon.BackgroundTransparency = 1 starIcon.Font = Enum.Font.GothamBold
        starIcon.Text = "\226\152\133" starIcon.TextSize = 12
        starIcon.TextColor3 = Color3.fromRGB(255, 200, 40) starIcon.Parent = row
    end
    local p = Instance.new("Frame")
    p.Size = UDim2.new(0, 40, 0, 20) p.Position = UDim2.new(1, -40, 0.5, -10)
    p.BackgroundColor3 = locked and Color3.fromRGB(40, 30, 15) or C.PanelLight
    p.BorderSizePixel = 0 p.Parent = row
    corner(p, 10)
    stroke(p, locked and Color3.fromRGB(120, 90, 40) or C.Border, 1, 0.3)
    local k = Instance.new("Frame")
    k.Size = UDim2.new(0, 14, 0, 14) k.Position = UDim2.new(0, 3, 0.5, -7)
    k.BackgroundColor3 = locked and Color3.fromRGB(120, 90, 40) or C.TextMuted
    k.BorderSizePixel = 0 k.ZIndex = 2 k.Parent = p
    corner(k, 7)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0) btn.BackgroundTransparency = 1 btn.Text = "" btn.Parent = p
    local function setS(on, an)
        if locked then return end
        local info = TweenInfo.new(an and 0.2 or 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if on then
            T:Create(p, info, {BackgroundColor3 = C.Accent}):Play()
            T:Create(k, info, {Position = UDim2.new(1, -17, 0.5, -7), BackgroundColor3 = C.Text}):Play()
        else
            T:Create(p, info, {BackgroundColor3 = C.PanelLight}):Play()
            T:Create(k, info, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = C.TextMuted}):Play()
        end
    end
    btn.MouseButton1Click:Connect(function()
        if locked then pcall(showPrem) return end
        Configuration[key] = not Configuration[key]
        setS(Configuration[key], true)
        if cb then pcall(cb, Configuration[key]) end
        if key == "SilentAimEnabled" then
            if Configuration.SilentAimEnabled then
                _G.__CELESTIAL_H_AimbotBeforeSilent = Configuration.CameraAssistEnabled
                Configuration.CameraAssistEnabled = false
                if ToggleRegistry["CameraAssistEnabled"] then ToggleRegistry["CameraAssistEnabled"](false, true) end
            else
                if _G.__CELESTIAL_H_AimbotBeforeSilent then
                    Configuration.CameraAssistEnabled = true
                    if ToggleRegistry["CameraAssistEnabled"] then ToggleRegistry["CameraAssistEnabled"](true, true) end
                end
                _G.__CELESTIAL_H_AimbotBeforeSilent = false
                pcall(applyProfile, ActiveWeaponName)
            end
        elseif key == "CameraAssistEnabled" and Configuration.CameraAssistEnabled then
            Configuration.SilentAimEnabled = false
            if ToggleRegistry["SilentAimEnabled"] then ToggleRegistry["SilentAimEnabled"](false, true) end
            pcall(applyProfile, ActiveWeaponName)
        end
        Utility.InvalidateLobbyCache()
        saveActiveProfile()
    end)
    ToggleRegistry[key] = setS
    setS(Configuration[key], false)
    return row
end

local function CTogColor(parent, text, toggleKey, colorKey, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34) row.BackgroundTransparency = 1 row.Parent = routeParent(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -200, 1, 0) l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium l.Text = tostring(text) l.TextSize = 12
    l.TextColor3 = C.Text l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = row
    local cb2 = Instance.new("TextButton")
    cb2.Size = UDim2.new(0, 100, 0, 22) cb2.Position = UDim2.new(1, -146, 0.5, -11)
    cb2.BackgroundColor3 = C.Card cb2.BorderSizePixel = 0
    cb2.Font = Enum.Font.GothamMedium cb2.TextSize = 10 cb2.TextColor3 = C.Text
    cb2.Text = "Change colour" cb2.AutoButtonColor = false cb2.Parent = row
    corner(cb2, 6) stroke(cb2, C.Border, 1, 0.4)
    cb2.MouseButton1Click:Connect(function()
        local COLS = {
            {name="Purple", col=Color3.fromRGB(255, 45, 92)}, {name="Red", col=Color3.fromRGB(255, 60, 60)},
            {name="Blue", col=Color3.fromRGB(99, 102, 241)}, {name="Green", col=Color3.fromRGB(60, 220, 90)},
            {name="Yellow", col=Color3.fromRGB(255, 220, 60)}, {name="White", col=Color3.fromRGB(245, 243, 255)},
            {name="Black", col=Color3.fromRGB(25, 25, 30)}, {name="Cyan", col=Color3.fromRGB(80, 220, 240)},
            {name="Orange", col=Color3.fromRGB(255, 140, 60)}, {name="Pink", col=Color3.fromRGB(255, 100, 200)},
            {name="Lime", col=Color3.fromRGB(120, 255, 120)}, {name="Teal", col=Color3.fromRGB(60, 200, 180)},
        }
        local par = safeGuiParent()
        if not par then return end
        local psg = Instance.new("ScreenGui")
        psg.Name = "CELESTIAL_H_Picker" psg.ResetOnSpawn = false psg.IgnoreGuiInset = true
        psg.DisplayOrder = 6000 psg.Parent = par
        local bdp = Instance.new("TextButton")
        bdp.Size = UDim2.fromScale(1, 1) bdp.BackgroundColor3 = Color3.new(0, 0, 0)
        bdp.BackgroundTransparency = 0.5 bdp.BorderSizePixel = 0 bdp.Text = "" bdp.AutoButtonColor = false bdp.Parent = psg
        local panel = Instance.new("Frame")
        panel.AnchorPoint = Vector2.new(0.5, 0.5) panel.Position = UDim2.fromScale(0.5, 0.5)
        panel.Size = UDim2.fromOffset(300, 220) panel.BackgroundColor3 = C.Panel
        panel.BorderSizePixel = 0 panel.Parent = psg
        corner(panel, 10) stroke(panel, C.Border, 1, 0)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 0, 24) title.Position = UDim2.new(0, 14, 0, 10)
        title.BackgroundTransparency = 1 title.Font = Enum.Font.GothamBold
        title.TextSize = 12 title.TextColor3 = C.Text
        title.TextXAlignment = Enum.TextXAlignment.Left title.Text = "Pick a color" title.Parent = panel
        local closeB = Instance.new("TextButton")
        closeB.Size = UDim2.fromOffset(22, 22) closeB.Position = UDim2.new(1, -32, 0, 10)
        closeB.BackgroundColor3 = C.PanelLight closeB.BorderSizePixel = 0
        closeB.Font = Enum.Font.GothamBold closeB.TextSize = 13 closeB.TextColor3 = C.Text
        closeB.Text = "x" closeB.AutoButtonColor = false closeB.Parent = panel
        corner(closeB, 5)
        local grid = Instance.new("Frame")
        grid.Size = UDim2.new(1, -28, 1, -52) grid.Position = UDim2.new(0, 14, 0, 42)
        grid.BackgroundTransparency = 1 grid.Parent = panel
        local gl = Instance.new("UIGridLayout")
        gl.CellSize = UDim2.fromOffset(60, 34) gl.CellPadding = UDim2.fromOffset(6, 6)
        gl.SortOrder = Enum.SortOrder.LayoutOrder gl.Parent = grid
        local function cclose() pcall(function() psg:Destroy() end) end
        bdp.MouseButton1Click:Connect(cclose)
        closeB.MouseButton1Click:Connect(cclose)
        for _, info in ipairs(COLS) do
            local b = Instance.new("TextButton")
            b.BackgroundColor3 = info.col b.BorderSizePixel = 0 b.Text = "" b.AutoButtonColor = false b.Parent = grid
            corner(b, 6) stroke(b, C.Border, 1, 0.3)
            b.MouseButton1Click:Connect(function()
                Configuration[colorKey] = info.name
                saveActiveProfile()
                cclose()
            end)
        end
    end)
    local p = Instance.new("Frame")
    p.Size = UDim2.new(0, 40, 0, 20) p.Position = UDim2.new(1, -40, 0.5, -10)
    p.BackgroundColor3 = C.PanelLight p.BorderSizePixel = 0 p.Parent = row
    corner(p, 10) stroke(p, C.Border, 1, 0.3)
    local k = Instance.new("Frame")
    k.Size = UDim2.new(0, 14, 0, 14) k.Position = UDim2.new(0, 3, 0.5, -7)
    k.BackgroundColor3 = C.TextMuted k.BorderSizePixel = 0 k.ZIndex = 2 k.Parent = p
    corner(k, 7)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0) btn.BackgroundTransparency = 1 btn.Text = "" btn.Parent = p
    local function setS(on, an)
        local info = TweenInfo.new(an and 0.2 or 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if on then
            T:Create(p, info, {BackgroundColor3 = C.Accent}):Play()
            T:Create(k, info, {Position = UDim2.new(1, -17, 0.5, -7), BackgroundColor3 = C.Text}):Play()
        else
            T:Create(p, info, {BackgroundColor3 = C.PanelLight}):Play()
            T:Create(k, info, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = C.TextMuted}):Play()
        end
    end
    btn.MouseButton1Click:Connect(function()
        Configuration[toggleKey] = not Configuration[toggleKey]
        setS(Configuration[toggleKey], true)
        if cb then pcall(cb, Configuration[toggleKey]) end
        saveActiveProfile()
    end)
    setS(Configuration[toggleKey], false)
    return row
end

local function CSl(parent, text, key, mn, mx, step, bfn)
    local isPrem = PREMIUM_KEYS[key] == true
    local locked = isPrem and not Configuration.IsPremium
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, bfn and 64 or 44) c.BackgroundTransparency = 1 c.Parent = routeParent(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.7, 0, 0, 16)
    if isPrem then l.Position = UDim2.new(0, 16, 0, 0) end
    l.BackgroundTransparency = 1 l.Font = Enum.Font.GothamMedium l.Text = tostring(text)
    l.TextSize = 11 l.TextColor3 = C.Text l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = c
    if isPrem then
        local starIcon = Instance.new("TextLabel")
        starIcon.Size = UDim2.fromOffset(16, 14) starIcon.Position = UDim2.new(0, -2, 0, 1)
        starIcon.BackgroundTransparency = 1 starIcon.Font = Enum.Font.GothamBold
        starIcon.Text = "\226\152\133" starIcon.TextSize = 12
        starIcon.TextColor3 = Color3.fromRGB(255, 200, 40) starIcon.Parent = c
    end
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.3, 0, 0, 16) v.Position = UDim2.new(0.7, 0, 0, 0)
    v.BackgroundTransparency = 1 v.Font = Enum.Font.GothamBold v.TextSize = 11
    v.TextColor3 = C.Accent3 v.TextXAlignment = Enum.TextXAlignment.Right v.Parent = c
    local tr = Instance.new("Frame")
    tr.Size = UDim2.new(1, 0, 0, 4) tr.Position = UDim2.new(0, 0, 0, 26)
    tr.BackgroundColor3 = C.PanelLight tr.BorderSizePixel = 0 tr.Parent = c
    corner(tr, 2)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 0, 1, 0) f.BackgroundColor3 = C.Accent f.BorderSizePixel = 0 f.Parent = tr
    corner(f, 2)
    local h = Instance.new("Frame")
    h.Size = UDim2.new(0, 12, 0, 12) h.Position = UDim2.new(0, -6, 0.5, -6)
    h.BackgroundColor3 = C.Text h.BorderSizePixel = 0 h.ZIndex = 3 h.Parent = tr
    corner(h, 6) stroke(h, C.Accent, 2, 0)
    local bd = nil
    local bt = nil
    if bfn then
        bd = Instance.new("Frame")
        bd.Size = UDim2.new(0, 70, 0, 18) bd.Position = UDim2.new(0, 0, 0, 38)
        bd.BackgroundColor3 = C.Card bd.BorderSizePixel = 0 bd.Parent = c
        corner(bd, 4) stroke(bd, C.Accent, 1, 0.2)
        bt = Instance.new("TextLabel")
        bt.Size = UDim2.new(1, 0, 1, 0) bt.BackgroundTransparency = 1
        bt.Font = Enum.Font.GothamBold bt.TextSize = 10 bt.TextColor3 = C.Accent
        bt.TextXAlignment = Enum.TextXAlignment.Center bt.TextYAlignment = Enum.TextYAlignment.Center
        bt.Text = "" bt.Parent = bd
    end
    local fm = "%.0f"
    if step and step < 1 then fm = "%.2f" end
    local dg = false
    local function upd(x)
        if locked then return end
        local tp = tr.AbsolutePosition.X
        local ts = tr.AbsoluteSize.X
        if ts <= 0 then return end
        local pct = math.clamp((x - tp) / ts, 0, 1)
        local val = mn + (mx - mn) * pct
        if step and step > 0 then val = math.round(val / step) * step end
        Configuration[key] = val
        v.Text = string.format(fm, val)
        f.Size = UDim2.new(pct, 0, 1, 0)
        h.Position = UDim2.new(pct, -6, 0.5, -6)
        if bfn and bt then
            local ok, t, col = pcall(bfn, val)
            if ok and t then bt.Text = tostring(t) if col then bt.TextColor3 = col end end
        end
        saveActiveProfile()
    end
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 16) btn.Position = UDim2.new(0, 0, 0, 20)
    btn.BackgroundTransparency = 1 btn.Text = "" btn.Parent = c
    btn.InputBegan:Connect(function(input)
        if locked then pcall(showPrem) return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dg = true upd(input.Position.X)
        end
    end)
    Connections.Track(Utility.UserInputService.InputChanged:Connect(function(input)
        if dg and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then upd(input.Position.X) end
    end))
    Connections.Track(Utility.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dg = false end
    end))
    local ip = math.clamp((Configuration[key] - mn) / (mx - mn), 0, 1)
    v.Text = string.format(fm, Configuration[key])
    f.Size = UDim2.new(ip, 0, 1, 0)
    h.Position = UDim2.new(ip, -6, 0.5, -6)
    if bfn and bt then
        local ok, t, col = pcall(bfn, Configuration[key])
        if ok and t then bt.Text = tostring(t) if col then bt.TextColor3 = col end end
    end
    return c
end

local function CBut(parent, text, cb, styl)
    styl = styl or "default"
    local bc, hc, tc = C.Card, C.PanelLight, C.Text
    if styl == "danger" then bc = Color3.fromRGB(60, 22, 28) hc = Color3.fromRGB(90, 30, 38) tc = Color3.fromRGB(255, 200, 200)
    elseif styl == "accent" then bc = C.Accent hc = C.Accent:Lerp(Color3.new(1, 1, 1), 0.15)
    elseif styl == "discord" then bc = C.Discord hc = Color3.fromRGB(110, 122, 255) tc = Color3.fromRGB(255, 255, 255) end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30) b.BackgroundColor3 = bc b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamMedium b.Text = tostring(text) b.TextSize = 12
    b.TextColor3 = tc b.AutoButtonColor = false b.Parent = routeParent(parent)
    corner(b, 8)
    if styl ~= "accent" and styl ~= "discord" then stroke(b, C.Border, 1, 0.4) end
    b.MouseEnter:Connect(function() T:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = hc}):Play() end)
    b.MouseLeave:Connect(function() T:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = bc}):Play() end)
    b.MouseButton1Click:Connect(function() if cb then cb(b) end end)
    return b
end

local function CSeg(parent, lbl, key, opts)
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 48) c.BackgroundTransparency = 1 c.Parent = routeParent(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16) l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium l.Text = tostring(lbl) l.TextSize = 11
    l.TextColor3 = C.Text l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = c
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 24) h.Position = UDim2.new(0, 0, 0, 20)
    h.BackgroundColor3 = C.Card h.BorderSizePixel = 0 h.Parent = c
    corner(h, 6) stroke(h, C.Border, 1, 0.4)
    local sg = 1 / #opts
    local btns = {}
    for i, opt in ipairs(opts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(sg, 0, 1, 0) b.Position = UDim2.new(sg * (i - 1), 0, 0, 0)
        b.BackgroundTransparency = 1 b.Font = Enum.Font.GothamMedium b.TextSize = 10
        b.TextColor3 = C.TextMuted b.Text = tostring(opt) b.AutoButtonColor = false b.Parent = h
        b.MouseButton1Click:Connect(function()
            Configuration[key] = opt
            for o, bb in pairs(btns) do
                if o == opt then bb.TextColor3 = C.Text else bb.TextColor3 = C.TextMuted end
            end
            Utility.InvalidateLobbyCache()
            saveActiveProfile()
        end)
        btns[opt] = b
        if Configuration[key] == opt then b.TextColor3 = C.Text end
    end
    return c
end

local function CCS(parent, lbl, key, order, cmap)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34) row.BackgroundTransparency = 1 row.Parent = routeParent(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.4, 0, 1, 0) l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium l.Text = tostring(lbl) l.TextSize = 12
    l.TextColor3 = C.Text l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = row
    local h = Instance.new("Frame")
    h.Size = UDim2.new(0.6, 0, 1, 0) h.Position = UDim2.new(0.4, 0, 0, 0)
    h.BackgroundTransparency = 1 h.Parent = row
    local ly = Instance.new("UIListLayout")
    ly.FillDirection = Enum.FillDirection.Horizontal
    ly.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ly.VerticalAlignment = Enum.VerticalAlignment.Center
    ly.Padding = UDim.new(0, 6) ly.Parent = h
    local btns = {}
    local function rf()
        for nm, b in pairs(btns) do
            local st2 = b:FindFirstChildOfClass("UIStroke")
            if st2 then
                if Configuration[key] == nm then st2.Thickness = 2 st2.Color = C.Accent st2.Transparency = 0
                else st2.Thickness = 1 st2.Color = C.Border st2.Transparency = 0.4 end
            end
        end
    end
    for _, nm in ipairs(order) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 16, 0, 16) b.BackgroundColor3 = cmap[nm] or Color3.new(1, 1, 1)
        b.BorderSizePixel = 0 b.Text = "" b.AutoButtonColor = false b.Parent = h
        corner(b, 8)
        if nm == "RGB" then
            local rgbGrad = Instance.new("UIGradient")
            rgbGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
            }
            rgbGrad.Parent = b
        end
        local st2 = Instance.new("UIStroke")
        st2.Thickness = 1 st2.Color = C.Border st2.Transparency = 0.4 st2.Parent = b
        b.MouseButton1Click:Connect(function() Configuration[key] = nm rf() end)
        btns[nm] = b
    end
    rf()
    return row
end

local function CKB(parent, lbl, tKey, cKey, mKey)
    if DeviceInfo and DeviceInfo.isMobile then
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30) row.BackgroundTransparency = 1 row.Parent = routeParent(parent)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -130, 1, 0) l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamMedium l.Text = tostring(lbl) l.TextSize = 12
        l.TextColor3 = C.Text l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = row
        local stub = Instance.new("TextButton")
        stub.Size = UDim2.new(0, 110, 0, 22) stub.Position = UDim2.new(1, -110, 0.5, -11)
        stub.BackgroundColor3 = C.Card stub.BorderSizePixel = 0
        stub.Font = Enum.Font.GothamMedium stub.TextSize = 11 stub.TextColor3 = C.TextMuted
        stub.Text = "Touch Overlay" stub.AutoButtonColor = false stub.Parent = row
        corner(stub, 6)
        return row
    end
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30) row.BackgroundTransparency = 1 row.Parent = routeParent(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -130, 1, 0) l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium l.Text = tostring(lbl) l.TextSize = 12
    l.TextColor3 = C.Text l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = row
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 110, 0, 22) b.Position = UDim2.new(1, -110, 0.5, -11)
    b.BackgroundColor3 = C.Card b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamMedium b.TextSize = 11 b.TextColor3 = C.Text
    b.AutoButtonColor = false b.Parent = row
    corner(b, 6)
    local bs = stroke(b, C.Border, 1, 0.4)
    local function cur()
        if Configuration[tKey] == "Mouse" then return tostring(Configuration[mKey]):gsub("Enum.UserInputType.", "") end
        return tostring(Configuration[cKey]):gsub("Enum.KeyCode.", "")
    end
    local cap = false
    local cc = nil
    local function stop()
        cap = false b.Text = cur() b.BackgroundColor3 = C.Card
        if bs then bs.Color = C.Border end
        if cc then pcall(function() cc:Disconnect() end) cc = nil end
    end
    b.MouseButton1Click:Connect(function()
        if cap then stop() return end
        cap = true b.Text = "press any key..." b.BackgroundColor3 = C.Accent
        if bs then bs.Color = C.Accent2 end
        cc = Utility.UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                Configuration[tKey] = "Mouse" Configuration[mKey] = input.UserInputType
            else
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Configuration[tKey] = "Key" Configuration[cKey] = input.KeyCode
                else return end
            end
            stop()
        end)
    end)
    b.Text = cur()
    return row
end

local function formatTime(sec)
    if not sec or sec <= 0 then return "Expired" end
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    if d > 0 then return string.format("%dd %dh %dm", d, h, m) end
    if h > 0 then return string.format("%dh %dm %ds", h, m, s) end
    return string.format("%dm %ds", m, s)
end

function Interface.BuildVisualsTab(parent)
    CSe(parent, "ESP")
    CTog(parent, "Enable Visuals", "VisualsEnabled")
    CTogColor(parent, "Show Boxes", "ShowBoxes", "BoxColor")
    CTog(parent, "Show Names", "ShowNames")
    CTog(parent, "Show Health", "ShowHealth")
    CTog(parent, "Show Distance", "ShowDistance")
    CTogColor(parent, "Show Skeleton", "ShowSkeleton", "SkeletonColor")
    CSeP(parent, "Extras")
    CTog(parent, "ESP Target Visibility", "ESPTargetVisEnabled")
    CTog(parent, "Viewmodel Chams", "ViewmodelChamsEnabled")
    CTog(parent, "Local Player Glow", "LocalPlayerHighlightEnabled")
    CTog(parent, "Screen FX", "ScreenFXEnabled")
    CTog(parent, "Sky Changer", "SkyChangerEnabled")
    CTog(parent, "Night Vision", "NightVisionEnabled", NVApply)
    CSe(parent, "Shot Feedback")
    CTog(parent, "Shot Feedback Overlay", "ShotFeedbackEnabled")
    CTog(parent, "Tracer", "ShotTracerEnabled")
    CCS(parent, "Tracer Color", "ShotTracerColor", {"Cyan", "Purple", "Blue", "Green", "Orange", "Pink", "White", "Red", "Yellow"}, Configuration.BoxColorMap)
    CSl(parent, "Tracer Lifetime", "ShotTracerLifetime", 0.03, 0.5, 0.01)
    CSl(parent, "Tracer Thickness", "ShotTracerThickness", 1, 6, 1)
    CSl(parent, "Max Tracer Distance", "ShotMaxDistance", 100, 5000, 50)
    CTog(parent, "Muzzle Flash", "ShotMuzzleFlashEnabled")
    CSl(parent, "Flash Duration", "ShotMuzzleFlashDuration", 0.03, 0.3, 0.01)
    CTog(parent, "Hitmarker UI", "ShotHitmarkerEnabled")
    CSl(parent, "Hitmarker Duration", "ShotHitmarkerDuration", 0.05, 0.6, 0.01)
    CTog(parent, "Damage Numbers", "ShotDamageNumbersEnabled")
    CSl(parent, "Damage Popup Duration", "ShotDamagePopupDuration", 0.2, 2.0, 0.05)
    CTog(parent, "Shot Counter", "ShotShowCounter")
    CTog(parent, "Fire Rate", "ShotShowFireRate")
    CSe(parent, "Interface")
    CTog(parent, "Show Watermark", "WatermarkEnabled", function(on) pcall(setWatermarkEnabled, on) end)
end

function Interface.BuildCombatTab(parent)
    CSe(parent, "Aimbot")
    CTog(parent, "Enable Aimbot", "CameraAssistEnabled")
    CTog(parent, "Always On", "CameraAssistAlwaysOn")
    CTog(parent, "Use Mouse While Locking", "CameraAssistUseMouseWhileLocking")
    CTog(parent, "Rotate Character", "CameraAssistRotateChar")
    CSeP(parent, "Modes")
    CTog(parent, "Aim Lock", "AimLockEnabled")
    CTog(parent, "Ragebot", "RagebotEnabled")
    CSe(parent, "Aim FOV")
    CSl(parent, "Aim FOV", "CameraAssistFOV", 5, 65, 1)
    CTog(parent, "Draw FOV Circle", "CameraAssistDrawFOV")
    CCS(parent, "FOV Color", "CameraAssistFOVColor", {"White", "Red", "Yellow", "Blue", "Green", "Black", "RGB"}, FOVCircle.ColorMap)
    CSe(parent, "Keybind")
    CKB(parent, "Aim Key", "AimBindType", "AimKeyCode", "AimMouseButton")
    CSe(parent, "Smoothing")
    CSl(parent, "Smoothing", "CameraAssistSmoothing", 0, 20, 1, function(v)
        if v <= 1 then return "SNAP", Color3.fromRGB(80, 220, 130) end
        if v <= 3 then return "HARD", Color3.fromRGB(255, 90, 90) end
        if v <= 7 then return "FAST", Color3.fromRGB(255, 150, 90) end
        if v <= 11 then return "ASSIST", Color3.fromRGB(255, 190, 60) end
        if v <= 15 then return "SMOOTH", Color3.fromRGB(120, 200, 255) end
        return "GLIDE", Color3.fromRGB(120, 180, 220)
    end)
    CSe(parent, "Target")
    CSeg(parent, "Hitbox Mode", "CameraAssistHitboxMode", {"Head", "UpperTorso", "Chest", "Random"})
    CSe(parent, "Filters")
    CTog(parent, "Team Check", "TeamCheck")
    CTog(parent, "Visible Check", "CameraAssistVisibleCheck")
    CTog(parent, "FOV Priority", "CameraAssistFOVPriority")
    CTog(parent, "Auto Stop on Katana Deflect", "AutoStopOnKatanaDeflect")
    CSe(parent, "Weapon")
    CTog(parent, "Auto-Detect Weapon", "WeaponAutoDetect")
    CTog(parent, "Use Weapon Profiles", "WeaponProfilesEnabled")
    CSe(parent, "View FOV")
    CTog(parent, "Custom View FOV", "ViewFOVEnabled")
    CSl(parent, "View FOV", "ViewFOV", 70, 120, 1)
    CTog(parent, "Keep FOV Through Scope", "ViewFOVIgnoreScope")
end

function Interface.BuildSilentTab(parent)
    CSeP(parent, "Silent Aim")
    CTog(parent, "Enable Silent Aim", "SilentAimEnabled")
    CSl(parent, "Hit Chance (%)", "SilentAimHitChance", 0, 100, 1, function(v)
        if v >= 95 then return "ALWAYS", Color3.fromRGB(80, 220, 130) end
        if v >= 75 then return "HIGH", Color3.fromRGB(120, 220, 130) end
        if v >= 50 then return "MED", Color3.fromRGB(255, 190, 60) end
        return "LOW", Color3.fromRGB(255, 120, 90)
    end)
    CSeP(parent, "Silent FOV")
    CSl(parent, "Silent FOV", "SilentAimFOV", 5, 400, 1)
    CTog(parent, "Draw Silent FOV", "SilentAimDrawFOV")
    CCS(parent, "FOV Color", "SilentAimFOVColor", {"White", "Red", "Yellow", "Blue", "Green", "Black", "Cyan", "RGB"}, FOVCircle.ColorMap)
    CSeP(parent, "Range")
    CSl(parent, "Max Distance", "CameraAssistAcquisitionRadius", 100, 2000, 50)
    CSeP(parent, "Target")
    CSeg(parent, "Hitbox Mode", "SilentAimHitbox", {"Head", "UpperTorso", "Chest", "Random"})
    CSeP(parent, "Info")
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 70) info.BackgroundTransparency = 1
    info.Font = Enum.Font.GothamMedium info.TextSize = 11 info.TextColor3 = C.TextMuted
    info.TextWrapped = true info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Text = "Silent Aim redirects the game's outbound raycast to the target. Requires checkcaller + workspace guards. Premium only."
    info.Parent = parent
end

function Interface.BuildTriggerTab(parent)
    CSe(parent, "Triggerbot")
    CTog(parent, "Enable Triggerbot", "AutoFireEnabled")
    CTog(parent, "Always On", "AutoFireAlwaysOn")
    CSe(parent, "Keybind")
    CKB(parent, "Fire Key", "AutoFireBindType", "AutoFireKeyCode", "AutoFireMouseButton")
    CSe(parent, "Timing")
    CSl(parent, "Fire Delay", "AutoFireDelay", 0.01, 0.5, 0.01)
    CSe(parent, "Range")
    CSl(parent, "Max Distance", "AutoFireMaxDistance", 100, 2000, 50)
    CSe(parent, "Distance Handling")
    CTog(parent, "Proximity Fallback", "AutoFireProximityFallback")
    CSl(parent, "Proximity Angle", "AutoFireProximityAngle", 1.0, 8.0, 0.1)
    CSe(parent, "Filters")
    CTog(parent, "Visible Check", "AutoFireVisibleCheck")
end

function Interface.BuildModsTab(parent)
    CSe(parent, "Movement")
    if DeviceInfo.isPC then
        CTog(parent, "Fly", "FlyEnabled")
        CSl(parent, "Fly Speed", "FlySpeed", 10, 80, 5)
    end
    CTog(parent, "Speed Hack", "SpeedEnabled")
    CSl(parent, "Walk Speed", "SpeedValue", 16, 500, 1)
    CTog(parent, "Infinite Jump", "InfJumpEnabled")
    CSe(parent, "Movement Trainer")
    CTog(parent, "BHOP Trainer HUD", "BhopTrainerEnabled")
    CTog(parent, "Show Speed", "BhopShowSpeed")
    CTog(parent, "Show Jump Count", "BhopShowJumps")
    CTog(parent, "Show Jump Timing", "BhopShowTiming")
    CSl(parent, "Perfect Window", "BhopPerfectWindow", 0.05, 0.6, 0.01)
    CSe(parent, "Recoil & Effects")
    CTog(parent, "No Recoil", "NoRecoilEnabled")
    CTog(parent, "Anti Flash", "AntiFlashEnabled")
    CSe(parent, "Weapon Tweaks")
    CTog(parent, "Hitbox Expander", "HitboxExpanderEnabled")
    CSl(parent, "Expander Size", "HitboxExpanderSize", 1.0, 5.0, 0.1)
    CSeP(parent, "Combat Extras")
    CTog(parent, "Rapid Fire", "RapidFireEnabled")
    CTog(parent, "Max Accuracy", "MaxAccuracyEnabled")
    CTog(parent, "No Spread", "NoSpreadEnabled")
    CTog(parent, "Spinbot", "SpinbotEnabled")
    CSeP(parent, "Fun / Hit Sounds")
    CTog(parent, "Hit Sounds", "HitSoundsEnabled")
    local soundOpts = {"Vine Boom", "Mega Knight", "MLG Airhorn", "Boom Headshot", "Taco Bell", "Anime SFX", "Loud Anime", "Hit Sound", "Hit Punch", "Hit Effect", "Hit SFX 2", "Hit-Sound"}
    local soundGrid = Instance.new("Frame")
    soundGrid.Name = "HitSoundLibrary"
    soundGrid.Size = UDim2.new(1,0,0,0)
    soundGrid.AutomaticSize = Enum.AutomaticSize.Y
    soundGrid.BackgroundTransparency = 1
    soundGrid.Parent = routeParent(parent)
    local gl = Instance.new("UIGridLayout")
    gl.CellSize = UDim2.new(0.5,-3,0,26)
    gl.CellPadding = UDim2.new(0,6,0,5)
    gl.SortOrder = Enum.SortOrder.LayoutOrder
    gl.Parent = soundGrid

    local function previewHitSound(name)
        local id = (Configuration.HitSoundMap or {})[name]
        if not id then return false end
        local ok = pcall(function()
            local snd = Instance.new("Sound")
            snd.Name = "CELESTIAL_H_PreviewSound"
            snd.SoundId = id
            snd.Volume = math.clamp(tonumber(Configuration.HitSoundVolume) or 0.5,0,1)
            local spread = math.clamp(tonumber(Configuration.HitSoundRandomPitch) or 0.06,0,0.25)
            local base = math.clamp(tonumber(Configuration.HitSoundPitch) or 1,0.5,2)
            snd.PlaybackSpeed = math.clamp(base + (math.random()-0.5)*spread,0.5,2)
            snd.Parent = game:GetService("SoundService")
            snd:Play()
            task.delay(2,function() pcall(function() snd:Destroy() end) end)
        end)
        return ok
    end
    for _, nm in ipairs(soundOpts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(0,26)
        b.BackgroundColor3 = CELESTIAL_HUI.BtnBg
        b.BackgroundTransparency = 0.18
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 8
        b.Text = nm
        b.TextColor3 = (Configuration.HitSoundChoice == nm) and CELESTIAL_HUI.Text or CELESTIAL_HUI.TextMuted
        b.AutoButtonColor = false
        b.Parent = soundGrid
        corner(b,6); stroke(b,CELESTIAL_HUI.Stroke,1,0.28)
        b.MouseEnter:Connect(function() T:Create(b,TweenInfo.new(0.12),{BackgroundTransparency=0.02}):Play() end)
        b.MouseLeave:Connect(function() T:Create(b,TweenInfo.new(0.12),{BackgroundTransparency=0.18}):Play() end)
        b.MouseButton1Click:Connect(function()
            Configuration.HitSoundChoice = nm
            for _, child in ipairs(soundGrid:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = child.Text == nm and CELESTIAL_HUI.Text or CELESTIAL_HUI.TextMuted
                end
            end
            saveActiveProfile()
            if Configuration.HitSoundPreviewOnSelect then previewHitSound(nm) end
        end)
    end
    CSl(parent, "Volume", "HitSoundVolume", 0, 1, 0.01)
    CSl(parent, "Pitch", "HitSoundPitch", 0.5, 2, 0.05)
    CSl(parent, "Random Pitch", "HitSoundRandomPitch", 0, 0.25, 0.01)
    CTog(parent, "Preview On Select", "HitSoundPreviewOnSelect")
    CBut(parent, "Preview Selected Sound", function(btn)
        local ok = previewHitSound(Configuration.HitSoundChoice or "Vine Boom")
        local old = btn.Text
        btn.Text = ok and "PREVIEW PLAYING" or "AUDIO UNAVAILABLE"
        task.delay(0.8,function() if btn and btn.Parent then btn.Text=old end end)
    end, "default")
    CBut(parent, "Random Anime SFX", function()
        local pool = {"Anime SFX","Loud Anime","Hit Sound","Hit Punch","Hit Effect","Hit SFX 2","Hit-Sound"}
        local nm = pool[math.random(1,#pool)]
        Configuration.HitSoundChoice = nm
        saveActiveProfile()
        previewHitSound(nm)
    end, "accent")
    CTog(parent, "Custom Crosshair", "CustomCrosshairEnabled")
end

function Interface.BuildNetworkTab(parent)
    CInfo(parent, "Replication Lab", "Client/server telemetry and presentation only. This page does not alter replication, network ownership, or other players' hitboxes.")
    CSe(parent, "Network Status")
    CTog(parent, "Network Monitor", "NetworkMonitorEnabled")
    CTog(parent, "Show Ping", "NetworkShowPing")
    CTog(parent, "Show Jitter", "NetworkShowJitter")
    CSe(parent, "Replication Preview")
    CBut(parent, "Refresh Telemetry", function(btn)
        pcall(NetworkMonitor.Step)
        local old = btn.Text
        btn.Text = "TELEMETRY UPDATED"
        task.delay(0.8, function()
            if btn and btn.Parent then btn.Text = old end
        end)
    end, "accent")
    CInfo(parent, "Replication Preview", "Shows client/server state separation as a visual diagnostic. It does not alter replication, hide player hitboxes, spoof state, or move network ownership.", CELESTIAL_HUI.Accent)
    CSe(parent, "Diagnostics")
    CInfo(parent, "Jitter", "Watch this page while testing connection stability; high variance usually appears here before the UI feels inconsistent.", Color3.fromRGB(255, 190, 90))
    CInfo(parent, "FOV / Camera", "Camera presentation is kept independent so the FOV system can survive camera replacement.", Color3.fromRGB(120, 200, 255))
end

function Interface.BuildConfigTab(parent)
    CSe(parent, "Appearance")
    CTog(parent, "Anime Artwork", "AnimeImageEnabled")
    CSl(parent, "Artwork Transparency", "AnimeImageTransparency", 0, 1, 0.05)
    CSeg(parent, "Artwork Fit", "AnimeImageScale", {"Fit", "Stretch"})
    CBut(parent, "Use Built-in Anime", function(btn)
        Configuration.AnimeImageId = "151001200"
        Configuration.AnimeImageEnabled = true
        pcall(function() if AnimeGUI and AnimeGUI.Destroy then AnimeGUI.Destroy() end end)
        if Interface.TabContents.Home then pcall(function() if AnimeGUI and AnimeGUI.Build then AnimeGUI.Build(Interface.TabContents.Home) end end) end
        local old = btn.Text
        btn.Text = "ANIME ARTWORK READY"
        task.delay(0.9, function() if btn and btn.Parent then btn.Text = old end end)
        saveActiveProfile()
    end, "accent")
    CInfo(parent, "Anime Artwork", "Built-in public decal fallback is enabled. A custom Roblox image/decal ID can be entered into AnimeImageId. A separate original Celestial H artwork PNG is supplied for upload as your own Roblox image asset.")
    CTog(parent, "UI Animations", "UIAnimations")
    CSeg(parent, "Header Font", "UIHeaderFont", {"GothamBlack"})
    CSeg(parent, "Body Font", "UIFontBody", {"GothamMedium"})
    CSe(parent, "Network Monitor")
    CTog(parent, "Network Telemetry", "NetworkMonitorEnabled")
    CTog(parent, "Show Ping", "NetworkShowPing")
    CTog(parent, "Show Jitter", "NetworkShowJitter")
    CSe(parent, "Interface")
    CKB(parent, "Menu Key", "MenuBindType", "MenuKey", "MenuMouseButton")
    CSe(parent, "HUD Overlay")
    CTog(parent, "Enable HUD", "HUDEnabled", function(on) if on then pcall(makeHUD) else pcall(destroyHUD) end end)
    CTog(parent, "FPS Counter", "HUDShowFPS")
    CTog(parent, "Ping Counter", "HUDShowPing")
    CTog(parent, "Script Name", "HUDShowScriptName")
    CTog(parent, "Keybind List", "HUDShowKeybinds")
    CTog(parent, "Keybinds — Active Only", "HUDKeybindsOnlyActive")
    CTog(parent, "Session Time", "HUDShowSession")
    CTog(parent, "Player Count", "HUDShowPlayers")
    CTog(parent, "Clock", "HUDShowClock")
    CTog(parent, "Server ID", "HUDShowServer")
    CTog(parent, "Executor", "HUDShowExecutor")
    CTog(parent, "Memory", "HUDShowMemory")
    CTog(parent, "Status", "HUDShowStatus")
    CTog(parent, "FPS Graph", "HUDShowGraph")
    CTog(parent, "Compact HUD", "HUDCompact", function() task.defer(makeHUD) end)
    CSe(parent, "Watermark")
    CTog(parent, "Watermark", "WatermarkEnabled", function(on) pcall(setWatermarkEnabled,on) end)
    CTog(parent, "Version", "WatermarkShowVersion")
    CTog(parent, "Place Name", "WatermarkShowPlace")
    CTog(parent, "Clock", "WatermarkShowTime")
    CSe(parent, "Performance Tools")
    CTog(parent, "FPS Boost", "FPSBoostEnabled", function(on)
        if on then pcall(PerformanceTools.EnableFPSBoost) else pcall(PerformanceTools.DisableFPSBoost) end
    end)
    CSl(parent, "Max Render Distance", "MaxRenderDistance", 200, 2000, 50)
    CSe(parent, "Premium Key  \226\152\133")
    local premInput = Instance.new("TextBox")
    premInput.Size = UDim2.new(1, 0, 0, 34) premInput.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    premInput.BorderSizePixel = 0 premInput.Font = Enum.Font.GothamMedium
    premInput.TextSize = 12 premInput.TextColor3 = CELESTIAL_HUI.Text
    premInput.PlaceholderText = "W-CELESTIAL_H-... / M-CELESTIAL_H-... / Q-CELESTIAL_H-..."
    premInput.PlaceholderColor3 = CELESTIAL_HUI.TextMuted premInput.Text = ""
    premInput.ClearTextOnFocus = false premInput.TextXAlignment = Enum.TextXAlignment.Left premInput.Parent = parent
    corner(premInput, 6)
    local premPad = Instance.new("UIPadding")
    premPad.PaddingLeft = UDim.new(0, 10) premPad.PaddingRight = UDim.new(0, 10) premPad.Parent = premInput
    CBut(parent, "Redeem Premium Key", function(btn)
        local key = tostring(premInput.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then Popup.Show("Enter a key first", false) return end
        local ok, reason = KeySystem.Validate(key)
        if ok and Configuration.IsPremium then
            btn.Text = "Activated: " .. Configuration.PremiumTier
            premInput.Text = ""
            task.wait(2)
            btn.Text = "Redeem Premium Key"
        else
            btn.Text = "Not a valid premium key"
            task.wait(2)
            btn.Text = "Redeem Premium Key"
        end
    end, "accent")
    CSe(parent, "License Status")
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, 0, 0, 50) statusFrame.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    statusFrame.BackgroundTransparency = 0.3 statusFrame.BorderSizePixel = 0 statusFrame.Parent = parent
    corner(statusFrame, 6) stroke(statusFrame, CELESTIAL_HUI.Stroke, 1, 0.3)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -16, 0, 16) statusLabel.Position = UDim2.new(0, 8, 0, 6)
    statusLabel.BackgroundTransparency = 1 statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 11 statusLabel.TextColor3 = CELESTIAL_HUI.Accent3
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Text = "Type: --" statusLabel.Parent = statusFrame
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -16, 0, 16) timeLabel.Position = UDim2.new(0, 8, 0, 24)
    timeLabel.BackgroundTransparency = 1 timeLabel.Font = Enum.Font.GothamMedium
    timeLabel.TextSize = 11 timeLabel.TextColor3 = CELESTIAL_HUI.TextMuted
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Text = "Time Remaining: --" timeLabel.Parent = statusFrame
    Connections.Track(Utility.RunService.Heartbeat:Connect(function()
        if CameraAssist.ShuttingDown then return end
        if not statusFrame.Parent then return end
        if Configuration.IsPremium and Configuration.PremiumExpiry > 0 then
            local remaining = Configuration.PremiumExpiry - os.time()
            if remaining <= 0 then
                Configuration.IsPremium = false Configuration.PremiumTier = nil
                Configuration.PremiumExpiry = 0 Configuration.PremiumKey = nil
                statusLabel.Text = "Type: Expired" statusLabel.TextColor3 = CELESTIAL_HUI.Danger
                timeLabel.Text = "Time Remaining: --"
            else
                statusLabel.Text = "Type: Premium \226\152\133 " .. tostring(Configuration.PremiumTier or "")
                statusLabel.TextColor3 = CELESTIAL_HUI.Gold
                timeLabel.Text = "Time Remaining: " .. formatTime(remaining)
            end
        else
            local savedKey, expiry = KeySystem.ReadSaved()
            if savedKey and expiry and expiry > os.time() then
                statusLabel.Text = "Type: Work.ink Key" statusLabel.TextColor3 = CELESTIAL_HUI.Accent3
                timeLabel.Text = "Time Remaining: " .. formatTime(expiry - os.time())
            else
                statusLabel.Text = "Type: --" statusLabel.TextColor3 = CELESTIAL_HUI.TextMuted
                timeLabel.Text = "Time Remaining: --"
            end
        end
    end))
    CSe(parent, "Configuration")
    CBut(parent, "Save Config", function(btn)
        local ok = Configuration:Save()
        local o = btn.Text
        if ok then btn.Text = "Saved" else btn.Text = "Save Failed" end
        task.wait(1.2) btn.Text = o
    end, "accent")
    CBut(parent, "Load Config", function(btn)
        local ok = Configuration:Load()
        local o = btn.Text
        if ok then btn.Text = "Loaded" else btn.Text = "No Save Found" end
        task.wait(1.2) btn.Text = o
    end)
    CSe(parent, "Community")
    CBut(parent, "Join Discord", function(btn)
        local o = btn.Text
        if type(setclipboard) == "function" then
            pcall(setclipboard, "https://discord.gg/K3vgcVsCsS")
            btn.Text = "Link copied to clipboard"
        else btn.Text = "discord.gg/K3vgcVsCsS" end
        task.wait(2.0) btn.Text = o
    end, "discord")
    local bugNote = Instance.new("TextLabel")
    bugNote.Size = UDim2.new(1, 0, 0, 18) bugNote.BackgroundTransparency = 1
    bugNote.Font = Enum.Font.GothamMedium bugNote.TextSize = 10
    bugNote.TextColor3 = CELESTIAL_HUI.TextMuted bugNote.TextXAlignment = Enum.TextXAlignment.Center
    bugNote.Text = "Found a bug? Report it in the Discord." bugNote.Parent = parent
    CSe(parent, "System")
    CBut(parent, "Unload CELESTIAL_H", function() Interface.Unload() end, "danger")
end


local AnimeAssets = {
    "151001200",       -- Anime Girl (public Creator Store decal)
    "102563532473892", -- anime girl (public Creator Store decal)
    "6312481248",      -- Anime Girl (public Creator Store decal)
    "7695909959",      -- Anime girl (public Creator Store decal)
}

local function resolveAnimeIds()
    local ids = {}
    local configured = tostring(Configuration.AnimeImageId or ""):match("%d+")
    if configured and configured ~= "" then ids[#ids+1] = configured end
    for _, id in ipairs(AnimeAssets) do
        if not configured or id ~= configured then ids[#ids+1] = id end
    end
    return ids
end

local function animeAssetUrl(id, useThumb)
    if useThumb then
        return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=420&h=560"
    end
    return "rbxassetid://" .. tostring(id)
end

local AnimeGUI = {
    Gui = nil,
    Image = nil,
    Title = nil,
    Subtitle = nil,
    AssetIds = {},
    AssetIndex = 0,
    TriedThumb = false,
}

function AnimeGUI.TryNext()
    if not AnimeGUI.Image then return false end
    if AnimeGUI.AssetIndex >= #AnimeGUI.AssetIds then
        AnimeGUI.Image.Image = ""
        return false
    end
    AnimeGUI.AssetIndex += 1
    AnimeGUI.TriedThumb = false
    AnimeGUI.Image.Image = animeAssetUrl(AnimeGUI.AssetIds[AnimeGUI.AssetIndex], false)
    return true
end

function AnimeGUI.Build(parent)
    AnimeGUI.Destroy()

    local card = Instance.new("Frame")
    card.Name = "CELESTIAL_H_AnimeCard"
    card.Size = UDim2.new(1, 0, 0, 150)
    card.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    card.BackgroundTransparency = 0.04
    card.BorderSizePixel = 0
    card.Parent = routeParent(parent)
    corner(card, 12)
    stroke(card, CELESTIAL_HUI.Accent, 1, 0.18)

    local art = Instance.new("ImageLabel")
    art.Name = "AnimeArtwork"
    art.Size = UDim2.new(0, 218, 1, -10)
    art.Position = UDim2.new(1, -224, 0, 5)
    art.BackgroundColor3 = Color3.fromRGB(11, 8, 12)
    art.BackgroundTransparency = 0.06
    art.BorderSizePixel = 0
    art.ImageTransparency = math.clamp(tonumber(Configuration.AnimeImageTransparency) or 0, 0, 1)
    art.ScaleType = Configuration.AnimeImageScale == "Stretch" and Enum.ScaleType.Stretch or Enum.ScaleType.Fit
    art.Parent = card
    corner(art, 10)

    local tint = Instance.new("UIGradient")
    tint.Rotation = 90
    tint.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(175,120,145)),
    }
    tint.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.02),
        NumberSequenceKeypoint.new(1, 0.28),
    }
    tint.Parent = art

    local badge = Instance.new("TextLabel")
    badge.Name = "Badge"
    badge.Size = UDim2.fromOffset(82, 18)
    badge.Position = UDim2.new(0, 10, 0, 10)
    badge.BackgroundColor3 = CELESTIAL_HUI.Accent
    badge.BackgroundTransparency = 0.14
    badge.BorderSizePixel = 0
    badge.Font = Enum.Font.GothamBlack
    badge.TextSize = 7
    badge.TextColor3 = CELESTIAL_HUI.Text
    badge.Text = "CELESTIAL H"
    badge.Parent = card
    corner(badge, 7)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -244, 0, 30)
    title.Position = UDim2.new(0, 16, 0, 41)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = tostring(Configuration.AnimeImageTitle or "CELESTIAL H")
    title.TextSize = 19
    title.TextColor3 = CELESTIAL_HUI.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextStrokeTransparency = 0.78
    title.Parent = card

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, CELESTIAL_HUI.Accent),
        ColorSequenceKeypoint.new(0.52, CELESTIAL_HUI.Text),
        ColorSequenceKeypoint.new(1, CELESTIAL_HUI.Accent3),
    }
    grad.Parent = title

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -244, 0, 16)
    subtitle.Position = UDim2.new(0, 16, 0, 73)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = tostring(Configuration.AnimeImageSubtitle or "THE SKY IS NOT THE LIMIT")
    subtitle.TextSize = 8
    subtitle.TextColor3 = CELESTIAL_HUI.Accent3
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = card

    local hint = Instance.new("TextLabel")
    hint.Name = "Hint"
    hint.Size = UDim2.new(1, -244, 0, 34)
    hint.Position = UDim2.new(0, 16, 0, 95)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.GothamMedium
    hint.TextSize = 8
    hint.TextColor3 = CELESTIAL_HUI.TextMuted
    hint.TextWrapped = true
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.TextYAlignment = Enum.TextYAlignment.Top
    hint.Text = "Anime artwork • public Roblox decal fallback • custom asset ID supported"
    hint.Parent = card

    AnimeGUI.Gui = card
    AnimeGUI.Image = art
    AnimeGUI.Title = title
    AnimeGUI.Subtitle = subtitle
    AnimeGUI.AssetIds = resolveAnimeIds()
    AnimeGUI.AssetIndex = 0


    AnimeGUI.TryNext()
    return card
end

function AnimeGUI.Destroy()
    if AnimeGUI.ImageFailedConn then
        pcall(function() AnimeGUI.ImageFailedConn:Disconnect() end)
    end
    if AnimeGUI.Gui then pcall(function() AnimeGUI.Gui:Destroy() end) end
    AnimeGUI.Gui, AnimeGUI.Image, AnimeGUI.Title, AnimeGUI.Subtitle = nil, nil, nil, nil
    AnimeGUI.AssetIds, AnimeGUI.AssetIndex, AnimeGUI.TriedThumb = {}, 0, false
end

_G.__CELESTIAL_H_AnimeGUI = AnimeGUI
_G.AnimeGUI = AnimeGUI
_G.resolveAnimeIds = resolveAnimeIds
_G.animeAssetUrl = animeAssetUrl

local function CInfo(parent, title, body, accent)
    accent = accent or CELESTIAL_HUI.Accent
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 76)
    card.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.Parent = routeParent(parent)
    corner(card, 10)
    stroke(card, CELESTIAL_HUI.Stroke, 1, 0.2)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -18)
    bar.Position = UDim2.new(0, 8, 0, 9)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.Parent = card
    corner(bar, 2)
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -30, 0, 18)
    t.Position = UDim2.new(0, 20, 0, 12)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.Text = tostring(title)
    t.TextSize = 12
    t.TextColor3 = CELESTIAL_HUI.Text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = card
    local b = Instance.new("TextLabel")
    b.Size = UDim2.new(1, -34, 0, 34)
    b.Position = UDim2.new(0, 20, 0, 32)
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.GothamMedium
    b.Text = tostring(body)
    b.TextSize = 10
    b.TextColor3 = CELESTIAL_HUI.TextMuted
    b.TextWrapped = true
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextYAlignment = Enum.TextYAlignment.Top
    b.Parent = card
    return card
end

function Interface.BuildHomeTab(parent)
    if Configuration.AnimeImageEnabled ~= false then pcall(function() if AnimeGUI and AnimeGUI.Build then AnimeGUI.Build(parent) end end) end
    CInfo(parent, "CELESTIAL H", "Visual control suite with a compact categorized interface. Configure your presentation, world rendering and UI from one place.")
    CSe(parent, "Quick Access")
    CBut(parent, "Open World Visuals", function() Interface.SelectTab("World") end, "accent")
    CBut(parent, "Open Player Visuals", function() Interface.SelectTab("Players") end)
    CBut(parent, "Open UI Settings", function() Interface.SelectTab("Config") end)
    CSe(parent, "Session")
    local session = Instance.new("Frame")
    session.Size = UDim2.new(1, 0, 0, 76)
    session.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    session.BackgroundTransparency = 0.12
    session.BorderSizePixel = 0
    session.Parent = routeParent(parent)
    corner(session, 10) stroke(session, CELESTIAL_HUI.Stroke, 1, 0.25)
    local lp = Utility.Players.LocalPlayer
    local rows = {
        {"Executor", tostring(ExecutorInfo.Name)},
        {"Platform", tostring(DeviceInfo.platform or "Unknown")},
        {"Visuals", Configuration.VisualsEnabled and "Enabled" or "Disabled"},
        {"World", Configuration.WorldVisualsEnabled and tostring(Configuration.WorldPreset or "Custom") or "Default"},
    }
    for i, row in ipairs(rows) do
        local y = 6 + (i - 1) * 17
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.42, 0, 0, 15) l.Position = UDim2.new(0, 12, 0, y)
        l.BackgroundTransparency = 1 l.Font = Enum.Font.GothamMedium l.TextSize = 10
        l.Text = row[1] l.TextColor3 = CELESTIAL_HUI.TextMuted
        l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = session
        local v = Instance.new("TextLabel")
        v.Size = UDim2.new(0.54, -12, 0, 15) v.Position = UDim2.new(0.46, 0, 0, y)
        v.BackgroundTransparency = 1 v.Font = Enum.Font.GothamBold v.TextSize = 10
        v.Text = row[2] v.TextColor3 = CELESTIAL_HUI.Text
        v.TextXAlignment = Enum.TextXAlignment.Right v.Parent = session
    end
    CSe(parent, "Quick Toggles")
    CTog(parent, "Player Visuals", "VisualsEnabled")
    CTog(parent, "World Renderer", "WorldVisualsEnabled")
    CTog(parent, "Watermark", "WatermarkEnabled", function(on) pcall(setWatermarkEnabled, on) end)
end

function Interface.BuildWorldTab(parent)
    CInfo(parent, "World Renderer", "Tune Lighting, atmosphere and post-processing independently from player overlays.")
    CSe(parent, "Preset")
    CSeg(parent, "Style", "WorldPreset", {"Celestial", "Clean", "Sunset", "Noir"})
    CTog(parent, "Enable World Renderer", "WorldVisualsEnabled")
    CSe(parent, "Lighting")
    CSl(parent, "Brightness", "WorldBrightness", 0, 5, 0.1)
    CSl(parent, "Exposure", "WorldExposure", -2, 2, 0.05)
    CSl(parent, "Time of Day", "WorldClockTime", 0, 24, 0.25)
    CTog(parent, "Global Shadows", "WorldShadows")
    CTog(parent, "Fullbright", "WorldFullbright")
    CSe(parent, "Atmosphere")
    CSl(parent, "Density", "WorldAtmosphereDensity", 0, 1, 0.01)
    CSl(parent, "Fog Start", "WorldFogStart", 0, 5000, 50)
    CSl(parent, "Fog End", "WorldFogEnd", 50, 100000, 500)
    CSe(parent, "Post FX")
    CTog(parent, "Bloom", "WorldBloomEnabled")
    CTog(parent, "Color Correction", "WorldColorCorrectionEnabled")
    CTog(parent, "Sun Rays", "WorldSunRaysEnabled")
    CTog(parent, "Depth of Field", "WorldDepthOfFieldEnabled")
    CSe(parent, "Sky Changer")
    CTog(parent, "Stable Sky Changer", "SkyChangerEnabled")
    CSeg(parent, "Sky Preset", "SkyPreset", {"Celestial"})
    CTog(parent, "Lock Custom Sky", "SkyStableLock")
    CSe(parent, "Cloud Layer")
    CTog(parent, "Volumetric Clouds", "WorldCloudsEnabled")
    CSl(parent, "Cloud Cover", "WorldCloudCover", 0, 1, 0.05)
    CSl(parent, "Cloud Density", "WorldCloudDensity", 0, 1, 0.05)
    CSl(parent, "Cloud Speed", "WorldCloudSpeed", 0, 2, 0.05)
    CCS(parent, "Cloud Color", "WorldCloudColor", {"White", "Cyan", "Purple", "Blue", "Orange", "Pink"}, Configuration.BoxColorMap)
    CSe(parent, "Preset Notes")
    CInfo(parent, "Celestial", "Purple-tinted high-contrast presentation with a soft atmospheric look.", CELESTIAL_HUI.Accent)
    CInfo(parent, "Clean", "Neutral lighting intended to keep the scene close to its original appearance.", Color3.fromRGB(120, 220, 160))
    CInfo(parent, "Sunset / Noir", "Warm or dark cinematic profiles for a stronger visual mood.", Color3.fromRGB(255, 190, 90))
end

function Interface.BuildPlayersTab(parent)
    CInfo(parent, "Player Visuals", "Configure the existing on-screen presentation without adding new targeting or combat behavior.")
    CSe(parent, "ESP Elements")
    CTog(parent, "Enable Visuals", "VisualsEnabled")
    CTogColor(parent, "Boxes", "ShowBoxes", "BoxColor")
    CTog(parent, "Names", "ShowNames")
    CTog(parent, "Health", "ShowHealth")
    CTog(parent, "Distance", "ShowDistance")
    CTogColor(parent, "Skeleton", "ShowSkeleton", "SkeletonColor")
    CSe(parent, "Rendering")
    CSl(parent, "Max Render Distance", "MaxRenderDistance", 200, 3000, 50)
    CSl(parent, "Update Rate", "VisualsRateHz", 15, 120, 5)
    CTog(parent, "Team Check", "TeamCheck")
    CTog(parent, "Target Visibility", "ESPTargetVisEnabled")
    CSe(parent, "Local Player")
    CTog(parent, "Local Player Glow", "LocalPlayerHighlightEnabled")
    CCS(parent, "Glow Color", "LocalPlayerGlowColor", {"Purple", "Cyan", "Blue", "Green", "Orange", "Pink", "White"}, Configuration.BoxColorMap)
    CCS(parent, "Outline Color", "LocalPlayerOutlineColor", {"White", "Purple", "Cyan", "Green", "Red", "Black"}, Configuration.BoxColorMap)
    CSl(parent, "Fill Transparency", "LocalPlayerFillTransparency", 0, 1, 0.05)
    CSl(parent, "Outline Transparency", "LocalPlayerOutlineTransparency", 0, 1, 0.05)
    CSeg(parent, "Depth Mode", "LocalPlayerDepthMode", {"Occluded", "AlwaysOnTop"})
    CSe(parent, "Viewmodel")
    CTog(parent, "Viewmodel Chams", "ViewmodelChamsEnabled")
    CTog(parent, "Camera Viewmodel / Arms", "ViewmodelCameraArms")
    CCS(parent, "Hand / Weapon Color", "ViewmodelColor", {"Purple", "Cyan", "Blue", "Green", "Orange", "Pink", "White"}, Configuration.BoxColorMap)
    CSeg(parent, "Material", "ViewmodelMaterial", {"Neon", "ForceField", "SmoothPlastic", "Glass", "Metal"})
    CSl(parent, "Transparency", "ViewmodelTransparency", 0, 0.7, 0.05)
    CTog(parent, "Cast Shadows", "ViewmodelCastShadows")
    CTog(parent, "Rainbow Viewmodel", "ViewmodelRainbow")
    CSl(parent, "Rainbow Speed", "ViewmodelRainbowSpeed", 0.05, 2, 0.05)
    CSe(parent, "Local Skin Changer")
    CTog(parent, "Enable Skin Preview", "SkinChangerEnabled")
    CSeg(parent, "Skin Preset", "SkinPreset", {"Celestial", "Ice", "Sunset", "Mono", "Void"})
    CSeg(parent, "Skin Material", "SkinMaterial", {"SmoothPlastic", "Neon", "ForceField", "Glass", "Metal"})
    CCS(parent, "Accent Color", "SkinAccentColor", {"Purple", "Cyan", "Blue", "Green", "Orange", "Pink", "White"}, Configuration.BoxColorMap)
    CSl(parent, "Skin Transparency", "SkinTransparency", 0, 0.7, 0.05)
    CTog(parent, "Rainbow Skin", "SkinRainbow")
    CSl(parent, "Skin Rainbow Speed", "SkinRainbowSpeed", 0.05, 2, 0.05)
    CSe(parent, "Screen FX")
    CTog(parent, "Enable Screen FX", "ScreenFXEnabled")
    CSl(parent, "Saturation", "ScreenFXSaturation", -1, 1, 0.05)
    CSl(parent, "Contrast", "ScreenFXContrast", -1, 1, 0.05)
    CSl(parent, "Brightness", "ScreenFXBrightness", -1, 1, 0.05)
    CTog(parent, "Soft Blur", "ScreenFXBlurEnabled")
    CSl(parent, "Blur Size", "ScreenFXBlurSize", 0, 12, 1)
    CSe(parent, "Crosshair")
    CTog(parent, "Custom Crosshair", "CustomCrosshairEnabled")
    CInfo(parent, "Presentation", "Colors and overlays are shared with the existing Visuals renderer so profiles remain consistent.")
end

function Interface.Create()
    local sg = makeScreenGui("CELESTIAL_H_UI", 5000, false)
    if not sg then return nil end
    Interface.ScreenGui = sg

    local mf = Instance.new("Frame")
    mf.Name = "Main"
    mf.Size = UDim2.new(0, 860, 0, 540)
    mf.Position = UDim2.new(0.5, -430, 0.5, -270)
    mf.BackgroundColor3 = CELESTIAL_HUI.Bg
    mf.BorderSizePixel = 0
    mf.ClipsDescendants = true
    mf.Visible = false
    mf.Parent = sg
    Interface.MainFrame = mf
    corner(mf, 14) stroke(mf, CELESTIAL_HUI.Stroke, 1.5, 0)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 48)
    top.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
    top.BorderSizePixel = 0
    top.Parent = mf

    local brand = Instance.new("TextLabel")
    brand.Size = UDim2.fromOffset(154, 22)
    brand.Position = UDim2.new(0, 16, 0, 6)
    brand.BackgroundTransparency = 1
    brand.Font = Enum.Font.GothamBlack
    brand.Text = "CELESTIAL H"
    brand.TextSize = 18
    brand.TextColor3 = CELESTIAL_HUI.Text
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.Parent = top
    local miniAvatar = Instance.new("ImageLabel")
    miniAvatar.Name = "AnimeAvatar"
    miniAvatar.Size = UDim2.fromOffset(34, 34)
    miniAvatar.Position = UDim2.new(0, 190, 0, 7)
    miniAvatar.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    miniAvatar.BackgroundTransparency = 0.05
    miniAvatar.BorderSizePixel = 0
    miniAvatar.ScaleType = Enum.ScaleType.Crop
    local miniIds
    pcall(function() miniIds = resolveAnimeIds() end)
    if type(miniIds) ~= "table" or #miniIds == 0 then miniIds = {"151001200"} end
    local miniIndex = 1
    local miniThumb = false
    pcall(function() miniAvatar.Image = animeAssetUrl(miniIds[miniIndex], false) end)
    miniAvatar.Parent = top
    corner(miniAvatar, 10)
    stroke(miniAvatar, CELESTIAL_HUI.Stroke, 1, 0.2)

    local brandGrad = Instance.new("UIGradient")
    brandGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, CELESTIAL_HUI.Accent),
        ColorSequenceKeypoint.new(0.5, CELESTIAL_HUI.Text),
        ColorSequenceKeypoint.new(1, CELESTIAL_HUI.Accent3),
    }
    brandGrad.Parent = brand

    local version = Instance.new("TextLabel")
    version.Size = UDim2.fromOffset(190, 12)
    version.Position = UDim2.new(0, 17, 0, 28)
    version.BackgroundTransparency = 1
    version.Font = Enum.Font.GothamMedium
    version.Text = "CELESTIAL H  •  V7"
    version.TextSize = 8
    version.TextColor3 = CELESTIAL_HUI.TextMuted
    version.TextXAlignment = Enum.TextXAlignment.Left
    version.Parent = top

    local search = Instance.new("TextBox")
    search.Name = "Search"
    search.Size = UDim2.fromOffset(220, 26)
    search.Position = UDim2.new(1, -300, 0, 11)
    search.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    search.BorderSizePixel = 0
    search.Font = Enum.Font.GothamMedium
    search.PlaceholderText = "Search category..."
    search.PlaceholderColor3 = CELESTIAL_HUI.TextMuted
    search.Text = ""
    search.TextSize = 11
    search.TextColor3 = CELESTIAL_HUI.Text
    search.ClearTextOnFocus = false
    search.Parent = top
    corner(search, 8) stroke(search, CELESTIAL_HUI.Stroke, 1, 0.25)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 12) pad.PaddingRight = UDim.new(0, 12) pad.Parent = search

    local state = Instance.new("TextLabel")
    state.Size = UDim2.fromOffset(150, 24)
    state.Position = UDim2.new(1, -190, 0, 17)
    state.BackgroundTransparency = 1
    state.Font = Enum.Font.GothamBold
    state.Text = "●  ONLINE"
    state.TextSize = 10
    state.TextColor3 = Color3.fromRGB(80, 220, 130)
    state.TextXAlignment = Enum.TextXAlignment.Right
    state.Parent = top

    local cB = Instance.new("TextButton")
    cB.Size = UDim2.fromOffset(26, 26)
    cB.Position = UDim2.new(1, -31, 0, 11)
    cB.BackgroundTransparency = 1
    cB.Font = Enum.Font.GothamBold
    cB.Text = "×"
    cB.TextSize = 19
    cB.TextColor3 = CELESTIAL_HUI.TextMuted
    cB.AutoButtonColor = false
    cB.Parent = mf
    cB.MouseEnter:Connect(function() cB.TextColor3 = CELESTIAL_HUI.Text end)
    cB.MouseLeave:Connect(function() cB.TextColor3 = CELESTIAL_HUI.TextMuted end)
    cB.MouseButton1Click:Connect(function() mf.Visible = false end)
    Interface.CloseButton = cB

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Name = "Navigation"
    sidebar.Size = UDim2.new(0, 112, 1, -58)
    sidebar.Position = UDim2.new(0, 8, 0, 50)
    sidebar.BackgroundColor3 = Color3.fromRGB(12, 11, 19)
    sidebar.BackgroundTransparency = 0.15
    sidebar.BorderSizePixel = 0
    sidebar.ScrollBarThickness = 0
    sidebar.ScrollBarImageColor3 = CELESTIAL_HUI.Accent
    sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebar.Parent = mf
    corner(sidebar, 10) stroke(sidebar, CELESTIAL_HUI.Stroke, 1, 0.25)
    local sp = Instance.new("UIPadding")
    sp.PaddingTop = UDim.new(0, 10) sp.PaddingBottom = UDim.new(0, 10)
    sp.PaddingLeft = UDim.new(0, 7) sp.PaddingRight = UDim.new(0, 7) sp.Parent = sidebar
    local sl = Instance.new("UIListLayout")
    sl.Padding = UDim.new(0, 5) sl.SortOrder = Enum.SortOrder.LayoutOrder sl.Parent = sidebar

    local sideArt = Instance.new("Frame")
    sideArt.Name = "AnimeMascot"
    sideArt.LayoutOrder = 0
    sideArt.Size = UDim2.new(1, -2, 0, 172)
    sideArt.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    sideArt.BackgroundTransparency = 0.12
    sideArt.BorderSizePixel = 0
    sideArt.Parent = sidebar
    corner(sideArt, 10)
    stroke(sideArt, CELESTIAL_HUI.Stroke, 1, 0.22)

    local sideImage = Instance.new("ImageLabel")
    sideImage.Name = "Artwork"
    sideImage.Size = UDim2.new(1, -8, 1, -8)
    sideImage.Position = UDim2.new(0, 4, 0, 4)
    sideImage.BackgroundColor3 = Color3.fromRGB(11, 8, 12)
    sideImage.BackgroundTransparency = 0.02
    sideImage.BorderSizePixel = 0
    sideImage.ScaleType = Configuration.AnimeImageScale == "Stretch" and Enum.ScaleType.Stretch or Enum.ScaleType.Fit
    sideImage.ImageTransparency = math.clamp(tonumber(Configuration.AnimeImageTransparency) or 0, 0, 1)
    sideImage.Parent = sideArt
    corner(sideImage, 8)
    local sideIds
    pcall(function() sideIds = resolveAnimeIds() end)
    if type(sideIds) ~= "table" or #sideIds == 0 then sideIds = {"151001200"} end
    local sideIndex = 1
    local sideTriedThumb = false
    pcall(function() sideImage.Image = animeAssetUrl(sideIds[sideIndex], false) end)
    local sideFade = Instance.new("Frame")
    sideFade.AnchorPoint = Vector2.new(0,1)
    sideFade.Position = UDim2.new(0,4,1,-4)
    sideFade.Size = UDim2.new(1,-8,0,46)
    sideFade.BackgroundColor3 = Color3.fromRGB(9,6,10)
    sideFade.BackgroundTransparency = 0.20
    sideFade.BorderSizePixel = 0
    sideFade.Parent = sideArt
    corner(sideFade, 8)
    local sideTitle = Instance.new("TextLabel")
    sideTitle.Size = UDim2.new(1,-14,0,18)
    sideTitle.Position = UDim2.new(0,8,1,-43)
    sideTitle.BackgroundTransparency = 1
    sideTitle.Font = Enum.Font.GothamBlack
    sideTitle.TextSize = 10
    sideTitle.Text = "CELESTIAL H"
    sideTitle.TextColor3 = CELESTIAL_HUI.Text
    sideTitle.TextXAlignment = Enum.TextXAlignment.Left
    sideTitle.Parent = sideArt
    local sideSub = Instance.new("TextLabel")
    sideSub.Size = UDim2.new(1,-14,0,12)
    sideSub.Position = UDim2.new(0,8,1,-24)
    sideSub.BackgroundTransparency = 1
    sideSub.Font = Enum.Font.GothamBold
    sideSub.TextSize = 6
    sideSub.Text = "ANIME • VISUAL SUITE"
    sideSub.TextColor3 = CELESTIAL_HUI.Accent3
    sideSub.TextXAlignment = Enum.TextXAlignment.Left
    sideSub.Parent = sideArt

    local navGroups = {
        {name="HOME", items={{"Home","⌂"}}},
        {name="VISUALS", items={{"Visuals","◈"},{"World","✦"},{"Players","◎"}}},
        {name="COMBAT", items={{"Combat","◉"},{"Trigger","⌁"},{"Silent","◇"}}},
        {name="OTHER", items={{"Mods","◆"},{"Network","⌁"},{"Config","⚙"}}},
    }
    local tabN = {"Home","Visuals","World","Players","Combat","Trigger","Silent","Mods","Network","Config"}
    local icons = {}
    local tabBtns = {}
    local order = 0
    for _, group in ipairs(navGroups) do
        local gh = Instance.new("TextLabel")
        order += 1
        gh.LayoutOrder = order
        gh.Size = UDim2.new(1, -4, 0, 16)
        gh.BackgroundTransparency = 1
        gh.Font = Enum.Font.GothamBold
        gh.Text = group.name
        gh.TextSize = 8
        gh.TextColor3 = CELESTIAL_HUI.TextMuted
        gh.TextXAlignment = Enum.TextXAlignment.Left
        gh.Parent = sidebar
        local gp = Instance.new("UIPadding")
        gp.PaddingLeft = UDim.new(0, 8) gp.Parent = gh
        for _, item in ipairs(group.items) do
            local nm, ico = item[1], item[2]
            order += 1
            local b = Instance.new("TextButton")
            b.Name = nm .. "Button"
            b.LayoutOrder = order
            b.Size = UDim2.new(1, -4, 0, 30)
            b.BackgroundColor3 = CELESTIAL_HUI.BtnBg
            b.BackgroundTransparency = 1
            b.BorderSizePixel = 0
            b.Font = Enum.Font.GothamMedium
            b.Text = ""
            b.AutoButtonColor = false
            b.Parent = sidebar
            corner(b, 8)
            local ind = Instance.new("Frame")
            ind.Name = "Indicator"
            ind.Size = UDim2.fromOffset(3, 20)
            ind.Position = UDim2.new(0, 0, 0.5, -10)
            ind.BackgroundColor3 = CELESTIAL_HUI.Accent
            ind.BackgroundTransparency = 1
            ind.BorderSizePixel = 0
            ind.Parent = b
            corner(ind, 2)
            local il = Instance.new("TextLabel")
            il.Size = UDim2.fromOffset(20, 30)
            il.Position = UDim2.new(0, 9, 0, 0)
            il.BackgroundTransparency = 1
            il.Font = Enum.Font.GothamBold
            il.Text = ico
            il.TextSize = 13
            il.TextColor3 = CELESTIAL_HUI.TextMuted
            il.Parent = b
            local tx = Instance.new("TextLabel")
            tx.Size = UDim2.new(1, -34, 1, 0)
            tx.Position = UDim2.new(0, 30, 0, 0)
            tx.BackgroundTransparency = 1
            tx.Font = Enum.Font.GothamMedium
            tx.Text = nm
            tx.TextSize = 10
            tx.TextColor3 = CELESTIAL_HUI.TextMuted
            tx.TextXAlignment = Enum.TextXAlignment.Left
            tx.Parent = b
            tabBtns[nm] = b
            icons[nm] = {bar=ind, icon=il, text=tx}
            Interface.TabButtons[nm] = b
            b.MouseEnter:Connect(function()
                if Interface.CurrentTab ~= nm then
                    T:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.75}):Play()
                end
            end)
            b.MouseLeave:Connect(function()
                if Interface.CurrentTab ~= nm then
                    T:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
                end
            end)
        end
    end

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -130, 1, -58)
    content.Position = UDim2.new(0, 122, 0, 50)
    content.BackgroundColor3 = CELESTIAL_HUI.BtnBg
    content.BackgroundTransparency = 0.68
    content.BorderSizePixel = 0
    content.Parent = mf
    corner(content, 10) stroke(content, CELESTIAL_HUI.Stroke, 1, 0.18)

    local pageTitle = Instance.new("TextLabel")
    pageTitle.Name = "PageTitle"
    pageTitle.Size = UDim2.new(1, -28, 0, 26)
    pageTitle.Position = UDim2.new(0, 14, 0, 8)
    pageTitle.BackgroundTransparency = 1
    pageTitle.Font = Enum.Font.GothamBlack
    pageTitle.Text = "Home"
    pageTitle.TextSize = 14
    pageTitle.TextColor3 = CELESTIAL_HUI.Text
    pageTitle.TextXAlignment = Enum.TextXAlignment.Left
    pageTitle.Parent = content

    local loading = Instance.new("TextLabel")
    loading.Name = "Loading"
    loading.Size = UDim2.new(1, -28, 0, 30)
    loading.Position = UDim2.new(0, 14, 0, 78)
    loading.BackgroundTransparency = 1
    loading.Font = Enum.Font.GothamBold
    loading.Text = "Loading CELESTIAL H…"
    loading.TextSize = 11
    loading.TextColor3 = CELESTIAL_HUI.Accent3
    loading.TextXAlignment = Enum.TextXAlignment.Left
    loading.Parent = content

    local pageHint = Instance.new("TextLabel")
    pageHint.Size = UDim2.new(1, -28, 0, 18)
    pageHint.Position = UDim2.new(0, 14, 0, 28)
    pageHint.BackgroundTransparency = 1
    pageHint.Font = Enum.Font.GothamMedium
    pageHint.Text = "Manage your current category"
    pageHint.TextSize = 8
    pageHint.TextColor3 = CELESTIAL_HUI.TextMuted
    pageHint.TextXAlignment = Enum.TextXAlignment.Left
    pageHint.Parent = content

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, -12, 1, -54)
    pages.Position = UDim2.new(0, 6, 0, 50)
    pages.BackgroundTransparency = 1
    pages.Parent = content

    Interface.TabContents = {}
    Interface._PageRoutes = {}
    for _, nm in ipairs(tabN) do
        local sc = Instance.new("ScrollingFrame")
        sc.Name = nm .. "Page"
        sc.Size = UDim2.new(1, 0, 1, 0)
        sc.Position = UDim2.new(0, 0, 0, 0)
        sc.BackgroundTransparency = 1
        sc.BorderSizePixel = 0
        sc.ScrollBarThickness = 3
        sc.ScrollBarImageColor3 = CELESTIAL_HUI.Accent
        sc.ScrollBarImageTransparency = 0.35
        sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sc.CanvasSize = UDim2.new(0, 0, 0, 460)
        sc.Visible = false
        sc.Parent = pages
        local host = Instance.new("Frame")
        host.Name = "ColumnsHost"
        host.Size = UDim2.new(1, 0, 1, 0)
        host.AutomaticSize = Enum.AutomaticSize.Y
        host.BackgroundTransparency = 1
        host.Parent = sc
        local left = Instance.new("Frame")
        left.Name = "LeftColumn"
        left.Size = UDim2.new(0.5, -4, 0, 0)
        left.AutomaticSize = Enum.AutomaticSize.Y
        left.BackgroundTransparency = 1
        left.Parent = host
        local right = Instance.new("Frame")
        right.Name = "RightColumn"
        right.Size = UDim2.new(0.5, -4, 0, 0)
        right.Position = UDim2.new(0.5, 4, 0, 0)
        right.AutomaticSize = Enum.AutomaticSize.Y
        right.BackgroundTransparency = 1
        right.Parent = host
        for _, col in ipairs({left,right}) do
            local ly = Instance.new("UIListLayout")
            ly.Padding = UDim.new(0, 6)
            ly.SortOrder = Enum.SortOrder.LayoutOrder
            ly.Parent = col
        end
        local pd = Instance.new("UIPadding")
        pd.PaddingTop = UDim.new(0, 2) pd.PaddingBottom = UDim.new(0, 8)
        pd.PaddingLeft = UDim.new(0, 2) pd.PaddingRight = UDim.new(0, 2)
        pd.Parent = sc
        sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Interface.TabContents[nm] = sc
        Interface._PageRoutes[sc] = {columns={left,right}, current=1, started=false, body=nil}
    end

    local drag = false
    local dragStart, dragPos
    local function beginDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true dragStart = input.Position dragPos = mf.Position
        end
    end
    top.InputBegan:Connect(beginDrag)
    Connections.Track(Utility.UserInputService.InputChanged:Connect(function(input)
        if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            mf.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + d.X, dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
        end
    end))
    Connections.Track(Utility.UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end))

    function Interface.SelectTab(nm)
        if not tabBtns[nm] then return end
        if Interface.CurrentTab then
            local old = Interface.CurrentTab
            local ob = tabBtns[old]
            local oi = icons[old]
            if ob then T:Create(ob, TweenInfo.new(0.16), {BackgroundTransparency = 1}):Play() end
            if oi then
                oi.bar.BackgroundTransparency = 1
                oi.icon.TextColor3 = CELESTIAL_HUI.TextMuted
                oi.text.TextColor3 = CELESTIAL_HUI.TextMuted
            end
        end
        Interface.CurrentTab = nm
        local b = tabBtns[nm]
        local ic = icons[nm]
        b.BackgroundColor3 = CELESTIAL_HUI.Accent
        T:Create(b, TweenInfo.new(0.16), {BackgroundTransparency = 0.80}):Play()
        if ic and ic.bar then
            ic.bar.BackgroundColor3 = CELESTIAL_HUI.Accent
        end
        if ic then
            ic.bar.BackgroundTransparency = 0
            ic.icon.TextColor3 = CELESTIAL_HUI.Text
            ic.text.TextColor3 = CELESTIAL_HUI.Text
        end
        for n, c in pairs(Interface.TabContents) do c.Visible = (n == nm) end
        pageTitle.Text = nm
        if loading then loading.Visible = false end
        pageHint.Text = ({
            Home="Overview and quick access",
            Visuals="Player overlays, chams and presentation",
            World="Lighting, atmosphere and post-processing",
            Players="Player ESP and visual information",
            Combat="Aim and targeting controls",
            Trigger="Input and trigger controls",
            Silent="Silent targeting controls",
            Mods="Movement and miscellaneous controls",
            Network="Connection and replication diagnostics",
            Config="Interface, profiles and performance",
        })[nm] or "Manage your current category"
        if nm == "Silent" and not Configuration.IsPremium then
            task.defer(function() pcall(showPrem, "SILENT AIM \226\152\133", "Silent Aim is a premium feature.\nUnlock it in our Discord.") end)
        end
    end

    for nm, b in pairs(tabBtns) do
        b.MouseButton1Click:Connect(function() Interface.SelectTab(nm) end)
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q = tostring(search.Text or ""):lower():gsub("%s+", "")
        if q == "" then return end
        for _, nm in ipairs(tabN) do
            local a = nm:lower():gsub("%s+", "")
            if a:find(q, 1, true) then Interface.SelectTab(nm) break end
        end
    end)

    mf.Visible = true
    task.defer(function() pcall(function() Interface.BuildHomeTab(Interface.TabContents.Home) end) end)
    task.defer(function() pcall(function() Interface.BuildVisualsTab(Interface.TabContents.Visuals) end) end)
    task.defer(function() pcall(function() Interface.BuildWorldTab(Interface.TabContents.World) end) end)
    task.defer(function() pcall(function() Interface.BuildPlayersTab(Interface.TabContents.Players) end) end)
    task.defer(function() pcall(function() Interface.BuildCombatTab(Interface.TabContents.Combat) end) end)
    task.defer(function() pcall(function() Interface.BuildTriggerTab(Interface.TabContents.Trigger) end) end)
    task.defer(function() pcall(function() Interface.BuildSilentTab(Interface.TabContents.Silent) end) end)
    task.defer(function() pcall(function() Interface.BuildModsTab(Interface.TabContents.Mods) end) end)
    task.defer(function() pcall(function() Interface.BuildNetworkTab(Interface.TabContents.Network) end) end)
    task.defer(function() pcall(function() Interface.BuildConfigTab(Interface.TabContents.Config) end) end)
    Interface.SelectTab("Home")
end

function Interface.Unload()
    pcall(AnimeGUI.Destroy)
    CameraAssist.ShuttingDown = true
    SILENT.Active = false

    pcall(function() CameraAssist.Unbind() end)
    pcall(function() CameraAssist.UnbindViewFOV() end)
    pcall(WorldVisuals.Restore)
    pcall(LocalVisuals.Unload)
    pcall(ShotFX.Unload)
    pcall(NetworkMonitor.Unload)
    pcall(BhopTrainer.Unload)
    pcall(SkinChanger.Unload)
    pcall(SkyChanger.Unload)
    pcall(destroyHUD)
    pcall(function() CameraAssist.RestorePostFX() end)
    pcall(function() NVDisable() end)
    pcall(function() PerformanceTools.DisableFPSBoost() end)

    pcall(function()
        local lp = Utility.Players.LocalPlayer
        if lp and lp.Character then
            local t = lp.Character:FindFirstChildOfClass("Tool")
            if t and not t.Enabled then t.Enabled = true end
            local hum = lp.Character:FindFirstChildOfClass("Humanoid")
            if hum and CameraAssist.SavedAutoRotate ~= nil then
                hum.AutoRotate = CameraAssist.SavedAutoRotate
                CameraAssist.SavedAutoRotate = nil
            end
            local my = lp.Character:FindFirstChild("HumanoidRootPart")
            if my then
                local g = my:FindFirstChild("CELESTIAL_H_AimGyro")
                if g then g:Destroy() end
                local sg2 = my:FindFirstChild("CELESTIAL_H_SpinGyro")
                if sg2 then sg2:Destroy() end
            end
        end
    end)

    pcall(function() destroyHUD() end)
    pcall(function() Connections.DisconnectAll() end)

    Configuration.VisualsEnabled = false
    Configuration.CameraAssistEnabled = false
    Configuration.AutoFireEnabled = false

    pcall(function()
        for _, v in pairs(Visuals.Objects) do
            if v then
                if v.Container then pcall(function() v.Container:Destroy() end) end
                if v.SkeletonLines then
                    for _, l in ipairs(v.SkeletonLines) do if l then pcall(function() l:Destroy() end) end end
                end
            end
        end
        Visuals.Objects = {}
    end)
    pcall(function()
        if Visuals.Container then Visuals.Container:Destroy() end
        Visuals.Container = nil
    end)
    pcall(function() FOVCircle.Destroy() end)

    pcall(function() if Interface.ScreenGui then Interface.ScreenGui:Destroy() end end)
    pcall(function() saveActiveProfile() end)
    pcall(function() Configuration:Save() end)
    pcall(function()
        local par = safeGuiParent()
        if par then
            for _, g in ipairs(par:GetChildren()) do
                local n = g.Name
                if n == "CELESTIAL_H_Brain" or n == "CELESTIAL_H_Startup" or n == "CELESTIAL_H_Watermark" or n == "CELESTIAL_H_Discord"
                    or n == "CELESTIAL_H_Premium" or n == "CELESTIAL_H_MobileOverlay" or n == "CELESTIAL_H_Picker"
                    or n == "CELESTIAL_H_Crosshair" or n == "CELESTIAL_H_KeyUI" or n == "CELESTIAL_H_Popup"
                    or n == "CELESTIAL_H_UI" or n == "CELESTIAL_H_Visuals" or n == "CELESTIAL_H_FOV"
                    or n == "CELESTIAL_H_HUD" or n == "CELESTIAL_H_Keybinds" or n == "CELESTIAL_H_Graph" then
                    pcall(function() g:Destroy() end)
                end
            end
        end
    end)
end

local MobileOverlay = nil
local mobileToggleMenu = function() if Interface.MainFrame then Interface.MainFrame.Visible = not Interface.MainFrame.Visible end end

if DeviceInfo.isMobile then
    local par = safeGuiParent()
    if par then
        local sg = Instance.new("ScreenGui")
        sg.Name = "CELESTIAL_H_MobileOverlay" sg.ResetOnSpawn = false sg.IgnoreGuiInset = true
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling sg.DisplayOrder = 50
        pcall(function() sg.Parent = par end)
        local function mb(name, text, px, py, size, col)
            local b = Instance.new("TextButton")
            b.Name = name b.AnchorPoint = Vector2.new(0.5, 0.5)
            b.Size = UDim2.fromOffset(size, size) b.Position = UDim2.new(px, 0, py, 0)
            b.BackgroundColor3 = col b.BackgroundTransparency = 0.35 b.BorderSizePixel = 0
            b.Font = Enum.Font.GothamBold b.TextSize = math.floor(size * 0.22)
            b.TextColor3 = Color3.fromRGB(255, 255, 255) b.Text = text
            b.TextStrokeTransparency = 0.5 b.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            b.AutoButtonColor = false b.Parent = sg
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.5, 0) c.Parent = b
            local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(255, 255, 255) s.Thickness = 2 s.Transparency = 0.5 s.Parent = b
            return b
        end
        local ab = mb("Aim", "AIM", 0.88, 0.55, 100, Color3.fromRGB(220, 60, 90))
        local mB = mb("Menu", "MENU", 0.12, 0.10, 70, Color3.fromRGB(99, 102, 241))
        local aT = nil
        ab.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then aT = input CameraAssist.KeyHeld = true
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then CameraAssist.KeyHeld = true end
        end)
        ab.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then CameraAssist.KeyHeld = false
            elseif input.UserInputType == Enum.UserInputType.Touch and input == aT then aT = nil CameraAssist.KeyHeld = false end
        end)
        mB.MouseButton1Click:Connect(mobileToggleMenu)
        MobileOverlay = sg
    end
    Configuration.CameraAssistUseMouseWhileLocking = false
    Configuration.CameraAssistSmoothing = 10
    Configuration.CameraAssistFOV = 30
end

local FLASH_NAME_PATTERNS = {
    "flash", "blind", "damage", "hitmark", "hit_", "_hit", "blood",
    "redflash", "whiteflash", "grenade", "flashbang", "concussion",
    "overlay", "vignette", "hurt", "dmg",
}
local function name_is_flashy(n)
    if not n then return false end
    local l = n:lower()
    for _, p in ipairs(FLASH_NAME_PATTERNS) do
        if l:find(p) then return true end
    end
    return false
end

local function init_anti_flash()
    local AntiFlash = { killedFX = setmetatable({}, {__mode = "k"}), conns = {}, sweepTask = nil, watched = {} }

    local Lighting = game:GetService("Lighting")
    local function get_player_gui()
        local lp = game:GetService("Players").LocalPlayer
        if not lp then return nil end
        return lp:FindFirstChildOfClass("PlayerGui")
    end

    local function kill_lighting_effect(inst)
        if not Configuration.AntiFlashEnabled then return end
        if not inst or not inst.Parent then return end
        if inst:IsA("ColorCorrectionEffect") or inst:IsA("BrightnessEffect")
            or inst:IsA("BlurEffect") or inst:IsA("DepthOfFieldEffect") then
            if inst.Name == "CELESTIAL_H_NightVision" then return end
            local flashy = name_is_flashy(inst.Name)
            if not flashy and inst:IsA("ColorCorrectionEffect") then
                if (inst.Brightness or 0) > 0.35 then flashy = true end
                local tc = inst.TintColor
                if tc and tc.R > 0.85 and tc.G > 0.85 and tc.B > 0.85 and (inst.Enabled ~= false) then flashy = true end
            end
            if not flashy and inst:IsA("BrightnessEffect") then
                if (inst.Brightness or 0) > 0.25 then flashy = true end
            end
            if flashy then
                pcall(function() inst.Enabled = false end)
                AntiFlash.killedFX[inst] = true
            end
        end
    end

    -- Name-first gating: AbsoluteSize forces a layout pass. Only frames whose
    -- own Size property is already near-fullscreen hit the expensive path.
    local function kill_gui_flash(inst)
        if not Configuration.AntiFlashEnabled then return end
        if not inst or not inst.Parent then return end
        if not (inst:IsA("Frame") or inst:IsA("ImageLabel") or inst:IsA("ImageButton")) then return end
        local flashy = name_is_flashy(inst.Name)
        if not flashy then
            local sz = inst.Size
            if sz.X.Scale < 0.7 and sz.Y.Scale < 0.7 then return end
            local size = inst.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then return end
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            if size.X < vp.X * 0.7 or size.Y < vp.Y * 0.7 then return end
            if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                local ic = inst.ImageColor3
                if ic and ic.R > 0.85 and ic.G > 0.85 and ic.B > 0.85 and (inst.ImageTransparency or 1) < 0.85 then
                    flashy = true
                end
            else
                local col = inst.BackgroundColor3
                local bgtr = inst.BackgroundTransparency
                if col.R > 0.9 and col.G > 0.9 and col.B > 0.9 and (bgtr or 1) < 0.9 then
                    flashy = true
                end
            end
        end
        if flashy then
            pcall(function() inst.Visible = false end)
            AntiFlash.killedFX[inst] = true
        end
    end

    local function kill_workspace_flash(inst)
        if not Configuration.AntiFlashEnabled then return end
        if not inst or not inst.Parent then return end
        if not inst:IsA("BasePart") and not inst:IsA("ParticleEmitter")
            and not inst:IsA("Beam") and not inst:IsA("PointLight")
            and not inst:IsA("SpotLight") then return end
        if not name_is_flashy(inst.Name) then return end
        if inst:IsA("BasePart") then
            local tr = inst.Transparency
            if tr and tr < 0.8 then
                local col = inst.Color
                if col and col.R > 0.9 and col.G > 0.9 and col.B > 0.9 then
                    pcall(function() inst.Transparency = 1 end)
                    AntiFlash.killedFX[inst] = true
                end
            end
        elseif inst:IsA("PointLight") or inst:IsA("SpotLight") then
            pcall(function() inst.Enabled = false end)
            AntiFlash.killedFX[inst] = true
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Beam") then
            pcall(function() inst.Enabled = false end)
            AntiFlash.killedFX[inst] = true
        end
    end

    if Lighting then
        for _, ch in ipairs(Lighting:GetChildren()) do kill_lighting_effect(ch) end
        table.insert(AntiFlash.conns, Lighting.DescendantAdded:Connect(function(ch)
            if not Configuration.AntiFlashEnabled then return end
            if not (ch:IsA("ColorCorrectionEffect") or ch:IsA("BrightnessEffect")
                or ch:IsA("BlurEffect") or ch:IsA("DepthOfFieldEffect")) then return end
            task.defer(function() kill_lighting_effect(ch) end)
        end))
    end

    task.spawn(function()
        local PlayerGui = get_player_gui()
        local waited = 0
        while not PlayerGui and waited < 10 do
            task.wait(0.25)
            waited = waited + 0.25
            PlayerGui = get_player_gui()
        end
        if PlayerGui then
            table.insert(AntiFlash.conns, PlayerGui.DescendantAdded:Connect(function(ch)
                if not Configuration.AntiFlashEnabled then return end
                if not (ch:IsA("Frame") or ch:IsA("ImageLabel") or ch:IsA("ImageButton")) then return end
                task.defer(function() kill_gui_flash(ch) end)
            end))
            for _, sg in ipairs(PlayerGui:GetChildren()) do
                if sg:IsA("ScreenGui") then table.insert(AntiFlash.watched, sg) end
            end
            table.insert(AntiFlash.conns, PlayerGui.ChildAdded:Connect(function(ch)
                if ch:IsA("ScreenGui") then table.insert(AntiFlash.watched, ch) end
            end))
        end
    end)

    table.insert(AntiFlash.conns, game:GetService("Workspace").DescendantAdded:Connect(function(ch)
        if not Configuration.AntiFlashEnabled then return end
        if not name_is_flashy(ch.Name) then return end
        task.defer(function() kill_workspace_flash(ch) end)
    end))

    AntiFlash.sweepTask = task.spawn(function()
        while not CameraAssist.ShuttingDown do
            task.wait(0.33)
            if not Configuration.AntiFlashEnabled then continue end
            for _, ch in ipairs(Lighting:GetChildren()) do kill_lighting_effect(ch) end
            for i = #AntiFlash.watched, 1, -1 do
                if not AntiFlash.watched[i] or not AntiFlash.watched[i].Parent then
                    table.remove(AntiFlash.watched, i)
                end
            end
            for _, sg in ipairs(AntiFlash.watched) do
                for _, ch in ipairs(sg:GetChildren()) do
                    kill_gui_flash(ch)
                end
            end
        end
    end)

    _G.__CELESTIAL_H_AntiFlash = AntiFlash
end

local function initialize()
    if _G.__CELESTIAL_H_INITIALIZED then
        warn("[CELESTIAL_H] initialize already ran this session — skipping duplicate.")
        return
    end
    _G.__CELESTIAL_H_INITIALIZED = true
    pcall(function() Configuration:Load() end)
    local cat, raw = detectWeapon()
    if Configuration.WeaponProfilesEnabled and Configuration.WeaponAutoDetect then
        ActiveWeaponName = cat or "Default"
        applyProfile(ActiveWeaponName)
    else
        ActiveWeaponName = "Default"
    end
    Interface.Create()
    FOVCircle.Ensure()
    pcall(ShotFX.Init)
    pcall(BhopTrainer.Init)
    if Configuration.FPSBoostEnabled then pcall(PerformanceTools.EnableFPSBoost) end
    pcall(init_anti_flash)
    if Configuration.NightVisionEnabled then pcall(NVEnable) end
    CameraAssist.InitFocusTracking()
    CameraAssist.Bind()
    pcall(CameraAssist.BindViewFOV)
    _G.__CELESTIAL_H_BindDeferred = function()
        if CameraAssist.Bound then return end
        CameraAssist.Bind()
        pcall(CameraAssist.BindViewFOV)
    end
    _G.__CELESTIAL_H_Weapon = {
        get = function() return ActiveWeaponName end,
        list = function() return WeaponProfiles end,
        set = function(name) saveActiveProfile() ActiveWeaponName = name applyProfile(name) end,
    }
    Connections.Track(Utility.UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        local mt = false
        if Configuration.MenuBindType == "Mouse" then
            if input.UserInputType == Configuration.MenuMouseButton then mt = true end
        else
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Configuration.MenuKey then mt = true end
        end
        if mt and Interface.MainFrame then Interface.MainFrame.Visible = not Interface.MainFrame.Visible end
    end))
    Connections.Track(Utility.UserInputService.InputBegan:Connect(function(input)
        if Configuration.AutoFireBindType == "Mouse" then
            if input.UserInputType == Configuration.AutoFireMouseButton then AutoFire.KeyHeld = true end
        else
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Configuration.AutoFireKeyCode then AutoFire.KeyHeld = true end
        end
    end))
    Connections.Track(Utility.UserInputService.InputEnded:Connect(function(input)
        if Configuration.AutoFireBindType == "Mouse" then
            if input.UserInputType == Configuration.AutoFireMouseButton then AutoFire.KeyHeld = false end
        else
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Configuration.AutoFireKeyCode then AutoFire.KeyHeld = false end
        end
    end))
    Connections.Track(Utility.Players.PlayerRemoving:Connect(function(p)
        Visuals.OnPlayerRemoving(p)
        Utility.ClearTeamCache(p)
        Utility.DeflectCache[p] = nil
        Utility.DeflectCacheTime[p] = nil
        if CameraAssist._deflectCooldownUser == (p and p.UserId) then
            CameraAssist._deflectCooldownUntil = 0
            CameraAssist._deflectCooldownUser = nil
        end
    end))
    Connections.Track(Utility.RunService.RenderStepped:Connect(function()
        if CameraAssist.ShuttingDown then return end
        pcall(function() Visuals.Step() end)
        pcall(function() FOVCircle.Update() end)
        pcall(ShotFX.Step)
    end))

    local HB = {}
    local function Reg(name, rate, fn) HB[name] = { rate = rate, last = 0, fn = fn } end

    Reg("silent_flag", 0, function()
        SILENT.Active = Configuration.SilentAimEnabled
            and CameraAssist.Lock ~= nil
            and CameraAssist.Lock.Character ~= nil
            and CameraAssist.Lock.Character.Parent ~= nil
    end)

    Reg("autofire", 0, function()
        if Configuration.AutoFireEnabled then AutoFire.CheckAndFire() end
    end)

    Reg("featureapply", 0.1, function()
        FeatureApply("silentaim", {
            enabled = Configuration.SilentAimEnabled,
            set = { CameraAssistVisibleCheck = false, CameraAssistFOVPriority = true },
        })
        FeatureApply("aimlock", { enabled = Configuration.AimLockEnabled, set = { CameraAssistUseMouseWhileLocking = false } })
        FeatureApply("ragebot", {
            enabled = Configuration.RagebotEnabled,
            set = { CameraAssistSmoothing = 0, CameraAssistVisibleCheck = false, CameraAssistFOV = 65 },
        })
        FeatureApply("rapidfire", { enabled = Configuration.RapidFireEnabled, set = { AutoFireDelay = 0.01 } })
        FeatureApply("accuracy", {
            enabled = (Configuration.MaxAccuracyEnabled or Configuration.NoSpreadEnabled),
            set = { CameraAssistBulletSpeed = 3000, CameraAssistPrediction = true },
        })
    end)

    Reg("spinbot", 0.033, function()
        local lp = Utility.Players.LocalPlayer
        local my = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not my then return end
        local gyro = my:FindFirstChild("CELESTIAL_H_SpinGyro")
        if Configuration.SpinbotEnabled and not CameraAssist.Lock then
            if not gyro then
                gyro = Instance.new("BodyGyro")
                gyro.Name = "CELESTIAL_H_SpinGyro" gyro.MaxTorque = Vector3.new(0, 10e20, 0)
                gyro.P = 1e6 gyro.D = 1e5 gyro.Parent = my
                gyro.CFrame = my.CFrame
            end
            gyro.CFrame = gyro.CFrame * CFrame.Angles(0, math.rad(25), 0)
        elseif gyro then gyro:Destroy() end
    end)

    local infJumpStamp = 0
    Connections.Track(Utility.UserInputService.JumpRequest:Connect(function()
        infJumpStamp = tick()
    end))
    Reg("infjump", 0.033, function()
        if not Configuration.InfJumpEnabled then return end
        local lp = Utility.Players.LocalPlayer
        local hum = lp and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local held = Utility.UserInputService:IsKeyDown(Enum.KeyCode.Space)
        if not held and (tick() - infJumpStamp) > 0.15 then return end
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        pcall(function() hum.Jump = true end)
    end)

    Reg("local_visuals", 0.05, function()
        pcall(LocalVisuals.Step)
    end)

    local SkyChanger = {
        Active=false, Saved={}, Sky=nil, ChildConn=nil, Reentry=false,
        Presets={
            Celestial={
                Bk="rbxassetid://159454299",Dn="rbxassetid://159454296",Ft="rbxassetid://159454293",
                Lf="rbxassetid://159454286",Rt="rbxassetid://159454300",Up="rbxassetid://159454288"
            },
        }
    }
    function SkyChanger.SaveOriginal()
        if next(SkyChanger.Saved) then return end
        local L=game:GetService("Lighting")
        for _, sky in ipairs(L:GetChildren()) do
            if sky:IsA("Sky") and sky.Name ~= "CELESTIAL_H_Sky" then
                SkyChanger.Saved[#SkyChanger.Saved+1]={
                    Name=sky.Name, SkyboxBk=sky.SkyboxBk, SkyboxDn=sky.SkyboxDn, SkyboxFt=sky.SkyboxFt,
                    SkyboxLf=sky.SkyboxLf, SkyboxRt=sky.SkyboxRt, SkyboxUp=sky.SkyboxUp,
                    CelestialBodiesShown=sky.CelestialBodiesShown, StarCount=sky.StarCount,
                    SunAngularSize=sky.SunAngularSize, MoonAngularSize=sky.MoonAngularSize,
                }
            end
        end
    end
    function SkyChanger.DestroyOwned()
        local L=game:GetService("Lighting"); local sky=L:FindFirstChild("CELESTIAL_H_Sky")
        if sky then pcall(function() sky:Destroy() end) end
        SkyChanger.Sky=nil
    end
    function SkyChanger.Apply()
        local L=game:GetService("Lighting")
        if not Configuration.SkyChangerEnabled then
            if SkyChanger.Active then
                SkyChanger.DestroyOwned()
                for _, data in ipairs(SkyChanger.Saved) do
                    local s=Instance.new("Sky"); s.Name=data.Name
                    s.SkyboxBk=data.SkyboxBk; s.SkyboxDn=data.SkyboxDn; s.SkyboxFt=data.SkyboxFt
                    s.SkyboxLf=data.SkyboxLf; s.SkyboxRt=data.SkyboxRt; s.SkyboxUp=data.SkyboxUp
                    s.CelestialBodiesShown=data.CelestialBodiesShown; s.StarCount=data.StarCount
                    s.SunAngularSize=data.SunAngularSize; s.MoonAngularSize=data.MoonAngularSize; s.Parent=L
                end
                table.clear(SkyChanger.Saved); SkyChanger.Active=false
            end
            return
        end
        if SkyChanger.Reentry then return end
        SkyChanger.Reentry=true
        SkyChanger.SaveOriginal()
        for _, sky in ipairs(L:GetChildren()) do
            if sky:IsA("Sky") and sky.Name ~= "CELESTIAL_H_Sky" then pcall(function() sky:Destroy() end) end
        end
        local preset=SkyChanger.Presets[tostring(Configuration.SkyPreset or "Celestial")] or SkyChanger.Presets.Celestial
        local sky=L:FindFirstChild("CELESTIAL_H_Sky")
        if not sky or not sky:IsA("Sky") then
            if sky then sky:Destroy() end
            sky=Instance.new("Sky"); sky.Name="CELESTIAL_H_Sky"; sky.Parent=L
        end
        sky.SkyboxBk=preset.Bk; sky.SkyboxDn=preset.Dn; sky.SkyboxFt=preset.Ft
        sky.SkyboxLf=preset.Lf; sky.SkyboxRt=preset.Rt; sky.SkyboxUp=preset.Up
        sky.CelestialBodiesShown=true; sky.StarCount=3000
        SkyChanger.Sky=sky; SkyChanger.Active=true
        if not SkyChanger.ChildConn then
            SkyChanger.ChildConn=L.ChildAdded:Connect(function(ch)
                if not Configuration.SkyChangerEnabled or not Configuration.SkyStableLock then return end
                if ch:IsA("Sky") and ch.Name ~= "CELESTIAL_H_Sky" then task.defer(function()
                    if SkyChanger.Active and ch.Parent==L then pcall(function() ch:Destroy() end) end
                end) end
            end)
        end
        SkyChanger.Reentry=false
    end
    function SkyChanger.Unload()
        local L=game:GetService("Lighting")
        SkyChanger.DestroyOwned()
        for _, data in ipairs(SkyChanger.Saved) do
            local s=Instance.new("Sky"); s.Name=data.Name
            s.SkyboxBk=data.SkyboxBk; s.SkyboxDn=data.SkyboxDn; s.SkyboxFt=data.SkyboxFt
            s.SkyboxLf=data.SkyboxLf; s.SkyboxRt=data.SkyboxRt; s.SkyboxUp=data.SkyboxUp
            s.CelestialBodiesShown=data.CelestialBodiesShown; s.StarCount=data.StarCount
            s.SunAngularSize=data.SunAngularSize; s.MoonAngularSize=data.MoonAngularSize; s.Parent=L
        end
        table.clear(SkyChanger.Saved); SkyChanger.Active=false
        if SkyChanger.ChildConn then pcall(function() SkyChanger.ChildConn:Disconnect() end) end
        SkyChanger.ChildConn=nil
    end
    _G.__CELESTIAL_H_SkyChanger=SkyChanger

    Reg("world_visuals", 0.2, function() pcall(WorldVisuals.Apply) end)
    Reg("sky", 0.2, function() pcall(SkyChanger.Apply) end)
    Reg("skin_changer", 0.08, function() pcall(SkinChanger.ApplyCharacter) end)
    Reg("bhop_trainer", 0.05, function() pcall(BhopTrainer.Step) end)

    local crossLastState = false
    Reg("crosshair", 0.5, function()
        local want = Configuration.CustomCrosshairEnabled and Configuration.IsPremium
        if want == crossLastState then return end
        crossLastState = want
        if want then
            local sg = makeScreenGui("CELESTIAL_H_Crosshair", 150, true)
            if sg then
                local WHITE = Color3.fromRGB(255, 255, 255)
                local BLACK = Color3.fromRGB(0, 0, 0)
                local group = Instance.new("Frame")
                group.AnchorPoint = Vector2.new(0.5, 0.5) group.Position = UDim2.new(0.5, 0, 0.5, 0)
                group.Size = UDim2.fromOffset(24, 24) group.BackgroundTransparency = 1 group.Parent = sg
                local function arm(offx, offy, sizex, sizey)
                    local outline = Instance.new("Frame")
                    outline.AnchorPoint = Vector2.new(0.5, 0.5)
                    outline.Position = UDim2.new(0.5, offx, 0.5, offy)
                    outline.Size = UDim2.fromOffset(sizex + 2, sizey + 2)
                    outline.BackgroundColor3 = BLACK outline.BorderSizePixel = 0 outline.ZIndex = 1 outline.Parent = group
                    local inner = Instance.new("Frame")
                    inner.AnchorPoint = Vector2.new(0.5, 0.5)
                    inner.Position = UDim2.new(0.5, offx, 0.5, offy)
                    inner.Size = UDim2.fromOffset(sizex, sizey)
                    inner.BackgroundColor3 = WHITE inner.BorderSizePixel = 0 inner.ZIndex = 3 inner.Parent = group
                end
                arm(0, -4.5, 1, 6) arm(0, 4.5, 1, 6)
                arm(-4.5, 0, 6, 1) arm(4.5, 0, 6, 1)
                local dotOutline = Instance.new("Frame")
                dotOutline.AnchorPoint = Vector2.new(0.5, 0.5) dotOutline.Position = UDim2.new(0.5, 0, 0.5, 0)
                dotOutline.Size = UDim2.fromOffset(4, 4) dotOutline.BackgroundColor3 = BLACK
                dotOutline.BorderSizePixel = 0 dotOutline.ZIndex = 2 dotOutline.Parent = group
                local dot = Instance.new("Frame")
                dot.AnchorPoint = Vector2.new(0.5, 0.5) dot.Position = UDim2.new(0.5, 0, 0.5, 0)
                dot.Size = UDim2.fromOffset(2, 2) dot.BackgroundColor3 = WHITE
                dot.BorderSizePixel = 0 dot.ZIndex = 3 dot.Parent = group
            end
        else
            local par = safeGuiParent()
            if par then
                for _, g in ipairs(par:GetChildren()) do
                    if g.Name == "CELESTIAL_H_Crosshair" then pcall(function() g:Destroy() end) end
                end
            end
        end
    end)

    Reg("espvis", 0.08, function()
        if not Configuration.ESPTargetVisEnabled then return end
        local bcm = Configuration.BoxColorMap or {}
        for _, vo in pairs(Visuals.Objects) do
            if vo.Player and vo.Character and vo.Stroke then
                local pos, part = Utility.GetHitboxPosition(vo.Character, "Head")
                if pos then
                    local vis = Utility.IsPositionVisible(pos, {vo.Character}, tostring(vo.Player.UserId), part)
                    vo.Stroke.Color = vis and Color3.fromRGB(80, 220, 130) or (bcm[Configuration.BoxColor] or Color3.fromRGB(255, 100, 60))
                end
            end
        end
    end)

    
local NetworkMonitor = {
    Gui = nil,
    Ping = nil,
    Jitter = nil,
    LastPing = nil,
    LastUpdate = 0,
}
function NetworkMonitor.Destroy()
    if NetworkMonitor.Gui then pcall(function() NetworkMonitor.Gui:Destroy() end) end
    NetworkMonitor.Gui, NetworkMonitor.Ping, NetworkMonitor.Jitter = nil, nil, nil
end
function NetworkMonitor.Ensure()
    if not Configuration.NetworkMonitorEnabled then NetworkMonitor.Destroy(); return false end
    if NetworkMonitor.Gui and NetworkMonitor.Gui.Parent then return true end
    local sg = makeScreenGui("CELESTIAL_H_NetworkMonitor", 806, true)
    if not sg then return false end
    local box = Instance.new("Frame")
    box.AnchorPoint = Vector2.new(1,0)
    box.Position = UDim2.new(1,-16,0,88)
    box.Size = UDim2.fromOffset(210,34)
    box.BackgroundColor3 = CELESTIAL_HUI.Bg
    box.BackgroundTransparency = 0.14
    box.BorderSizePixel = 0
    box.Parent = sg
    corner(box, 9); stroke(box, CELESTIAL_HUI.Stroke, 1, 0.18)

    local ping = Instance.new("TextLabel")
    ping.Size = UDim2.new(0.5,-10,1,0)
    ping.Position = UDim2.new(0,10,0,0)
    ping.BackgroundTransparency = 1
    ping.Font = Enum.Font.GothamBold
    ping.TextSize = 9
    ping.TextColor3 = CELESTIAL_HUI.Text
    ping.TextXAlignment = Enum.TextXAlignment.Left
    ping.Parent = box

    local jitter = Instance.new("TextLabel")
    jitter.Size = UDim2.new(0.5,-10,1,0)
    jitter.Position = UDim2.new(0.5,0,0,0)
    jitter.BackgroundTransparency = 1
    jitter.Font = Enum.Font.GothamMedium
    jitter.TextSize = 9
    jitter.TextColor3 = CELESTIAL_HUI.TextMuted
    jitter.TextXAlignment = Enum.TextXAlignment.Right
    jitter.Parent = box

    NetworkMonitor.Gui, NetworkMonitor.Ping, NetworkMonitor.Jitter = sg, ping, jitter
    return true
end
function NetworkMonitor.Step()
    if not NetworkMonitor.Ensure() then return end
    local now = os.clock()
    if now - NetworkMonitor.LastUpdate < 0.25 then return end
    NetworkMonitor.LastUpdate = now
    local pingMs
    pcall(function()
        local stats = game:GetService("Stats")
        local item = stats.Network.ServerStatsItem["Data Ping"]
        if item then pingMs = tonumber(item:GetValue()) end
    end)
    if pingMs then
        if NetworkMonitor.LastPing then
            local delta = math.abs(pingMs - NetworkMonitor.LastPing)
            NetworkMonitor._jitter = (NetworkMonitor._jitter or delta) * 0.8 + delta * 0.2
        else
            NetworkMonitor._jitter = 0
        end
        NetworkMonitor.LastPing = pingMs
    end
    if NetworkMonitor.Ping then
        NetworkMonitor.Ping.Text = Configuration.NetworkShowPing ~= false and
            string.format("PING %sms", math.floor(pingMs or 0)) or ""
    end
    if NetworkMonitor.Jitter then
        NetworkMonitor.Jitter.Text = Configuration.NetworkShowJitter ~= false and
            string.format("JITTER %.1fms", NetworkMonitor._jitter or 0) or ""
    end
end
function NetworkMonitor.Unload() NetworkMonitor.Destroy() end
_G.__CELESTIAL_H_NetworkMonitor = NetworkMonitor
_G.NetworkMonitor = NetworkMonitor

local hitSoundDebounce = 0
    Reg("network_monitor", 0.25, function() pcall(NetworkMonitor.Step) end)

    Reg("hitsounds", 0.16, function()
        if not Configuration.HitSoundsEnabled then return end
        if not Configuration.IsPremium then Configuration.HitSoundsEnabled = false return end
        local lk = CameraAssist.Lock
        if not lk or not lk.Player or not lk.Character then return end
        local hum = lk.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local key = "CELESTIAL_H_HP_" .. tostring(lk.Player.UserId)
        local last = _G[key]
        if last and hum.Health < last then
            hitSoundDebounce = tick()
            local soundId = (Configuration.HitSoundMap or {})[Configuration.HitSoundChoice or "Vine Boom"] or "rbxassetid://6308606116"
            pcall(function()
                local snd = Instance.new("Sound")
                snd.Name = "CELESTIAL_H_HitSound"
                snd.SoundId = soundId
                snd.Volume = math.clamp(tonumber(Configuration.HitSoundVolume) or 0.5,0,1)
                local base = math.clamp(tonumber(Configuration.HitSoundPitch) or 1,0.5,2)
                local spread = math.clamp(tonumber(Configuration.HitSoundRandomPitch) or 0.06,0,0.25)
                snd.PlaybackSpeed = math.clamp(base + (math.random()-0.5)*spread,0.5,2)
                snd.Parent = game:GetService("SoundService")
                snd:Play()
                task.delay(2, function() pcall(function() snd:Destroy() end) end)
            end)
        end
        _G[key] = hum.Health
    end)

    local noclipped = {}
    local noclipWasOn = false
    Reg("noclip", 0.1, function()
        local lp = Utility.Players.LocalPlayer
        local char = lp and lp.Character
        if not char then noclipped = {} noclipWasOn = false return end
        if Configuration.FlyNoclipEnabled then
            noclipWasOn = true
            Configuration.FlyEnabled = true
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and not noclipped[p] then noclipped[p] = p.CanCollide p.CanCollide = false end
            end
        elseif noclipWasOn then
            for part, state in pairs(noclipped) do pcall(function() part.CanCollide = state end) end
            noclipped = {} noclipWasOn = false
        end
    end)

    Reg("hitbox", 0.25, function()
        local lp = Utility.Players.LocalPlayer
        if not lp then return end
        for _, p in ipairs(Utility.Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Character.Parent then
                for _, part_name in ipairs({"Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}) do
                    local part = p.Character:FindFirstChild(part_name)
                    if part and part:IsA("BasePart") then
                        if not part:GetAttribute("CELESTIAL_H_OrigSize") then part:SetAttribute("CELESTIAL_H_OrigSize", part.Size) end
                        local orig = part:GetAttribute("CELESTIAL_H_OrigSize")
                        local target = orig
                        if Configuration.HitboxExpanderEnabled then target = orig * (Configuration.HitboxExpanderSize or 1.5) end
                        if part.Size ~= target then pcall(function() part.Size = target end) end
                    end
                end
            end
        end
    end)

    Reg("norecoil", 0.05, function()
        if not Configuration.NoRecoilEnabled then return end
        local lp = Utility.Players.LocalPlayer
        if not lp or not lp.Character then return end
        local char = lp.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.CameraOffset.Magnitude > 0.001 then
            pcall(function() hum.CameraOffset = Vector3.zero end)
        end
        local animator = char:FindFirstChildOfClass("Animator")
        if animator then
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, track in ipairs(tracks) do
                    local a = track.Animation
                    if a and a.Name then
                        local n = a.Name:lower()
                        if n:find("recoil") or n:find("kick") or n:find("camera_shake")
                            or n:find("camshake") or n:find("shakerecoil") then
                            pcall(function() track:Stop(0) end)
                        end
                    end
                end
            end
        end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            for _, ch in ipairs(tool:GetChildren()) do
                if ch:IsA("NumberValue") then
                    local n = ch.Name:lower()
                    if n:find("recoil") or n:find("kick") or n:find("spread") or n:find("shake") then
                        if ch.Value ~= 0 then pcall(function() ch.Value = 0 end) end
                    end
                elseif ch:IsA("Vector3Value") then
                    local n = ch.Name:lower()
                    if n:find("recoil") or n:find("kick") or n:find("shake") then
                        if ch.Value.Magnitude > 0 then pcall(function() ch.Value = Vector3.zero end) end
                    end
                end
            end
        end
    end)

    local FlyState = { Tool = nil, WasForcing = false, StatesDisabled = false, SpeedApplied = false, PreSpeed = nil, PreJump = nil, Boost = nil }
    local FlyForward = Instance.new("BodyVelocity")
    FlyForward.Name = "CELESTIAL_H_FlyBV" FlyForward.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyForward.P = 10000 FlyForward.Parent = nil
    Reg("flyspeed", 0.033, function()
        local lp = Utility.Players.LocalPlayer
        if not lp then return end
        local char = lp.Character
        if not char or not char.Parent then
            FlyForward.Parent = nil FlyState.Tool = nil FlyState.WasForcing = false
            FlyState.StatesDisabled = false FlyState.SpeedApplied = false
            if FlyState.Boost then pcall(function() FlyState.Boost:Destroy() end) FlyState.Boost = nil end
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then FlyForward.Parent = nil return end
        if not Configuration.FlyEnabled and not Configuration.SpeedEnabled and not FlyState.WasForcing and not FlyState.SpeedApplied and FlyForward.Parent == nil then return end
        local cur = char:FindFirstChildOfClass("Tool")
        if cur then FlyState.Tool = cur end
        local flyA = Configuration.FlyEnabled
        local spdA = Configuration.SpeedEnabled
        local forceRun = flyA or spdA
        if flyA then
            if FlyForward.Parent ~= hrp then FlyForward.Parent = hrp end
            local cam = Utility.GetCamera()
            local mx, my, mz = 0, 0, 0
            if DeviceInfo.isMobile then
                local mv = hum.MoveDirection
                if mv and mv.Magnitude > 0.01 then mx = mv.X my = 0 mz = mv.Z end
            else
                if Utility.UserInputService:IsKeyDown(Enum.KeyCode.W) then mz = mz - 1 end
                if Utility.UserInputService:IsKeyDown(Enum.KeyCode.S) then mz = mz + 1 end
                if Utility.UserInputService:IsKeyDown(Enum.KeyCode.A) then mx = mx - 1 end
                if Utility.UserInputService:IsKeyDown(Enum.KeyCode.D) then mx = mx + 1 end
                if Utility.UserInputService:IsKeyDown(Enum.KeyCode.Space) then my = my + 1 end
                if Utility.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then my = my - 1 end
            end
            local mv = Vector3.new(mx, my, mz)
            local base = math.clamp(Configuration.FlySpeed or 50, 10, 80)
            local sp = base
            if not DeviceInfo.isMobile then
                if Utility.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then sp = base * 2.2 end
            end
            if cam and mv.Magnitude > 0 then
                local dir = (cam.CFrame.LookVector * -mv.Z + cam.CFrame.RightVector * mv.X + Vector3.new(0, 1, 0) * mv.Y)
                if dir.Magnitude > 0 then dir = dir.Unit end
                local target = dir * sp
                FlyForward.Velocity = FlyForward.Velocity:Lerp(target, 0.35)
            else
                FlyForward.Velocity = FlyForward.Velocity * 0.15
            end
        else
            if FlyForward.Parent then FlyForward.Velocity = Vector3.new(0, 0, 0) FlyForward.Parent = nil end
        end
        if spdA then
            if not FlyState.SpeedApplied then
                FlyState.PreSpeed = hum.WalkSpeed
                FlyState.PreJump = hum.JumpPower
                FlyState.SpeedApplied = true
                FlyState.Boost = Instance.new("BodyVelocity")
                FlyState.Boost.Name = "CELESTIAL_H_SpeedBoost"
                FlyState.Boost.MaxForce = Vector3.new(1e5, 0, 1e5)
                FlyState.Boost.P = 1250
                FlyState.Boost.Parent = hrp
            end
            local target_ws = math.clamp(Configuration.SpeedValue or 60, 16, 500)
            pcall(function() hum.WalkSpeed = target_ws end)
            pcall(function() hum.JumpPower = math.max(hum.JumpPower, 50) end)
            if FlyState.Boost and hrp then
                local mv = hum.MoveDirection
                if mv and mv.Magnitude > 0.01 then
                    FlyState.Boost.Velocity = Vector3.new(mv.X, 0, mv.Z).Unit * (target_ws * 0.9)
                else
                    FlyState.Boost.Velocity = Vector3.new(0, 0, 0)
                end
            end
        else
            if FlyState.SpeedApplied then
                if FlyState.PreSpeed then pcall(function() hum.WalkSpeed = FlyState.PreSpeed end) end
                if FlyState.PreJump then pcall(function() hum.JumpPower = FlyState.PreJump end) end
                if FlyState.Boost then pcall(function() FlyState.Boost:Destroy() end) FlyState.Boost = nil end
                FlyState.PreSpeed = nil FlyState.PreJump = nil FlyState.SpeedApplied = false
            end
        end
        if forceRun then
            FlyState.WasForcing = true
            local st = hum:GetState()
            if st ~= Enum.HumanoidStateType.Running and st ~= Enum.HumanoidStateType.RunningNoPhysics then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
            end
            if not FlyState.StatesDisabled then
                FlyState.StatesDisabled = true
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) end)
            end
            if FlyState.Tool and FlyState.Tool.Parent ~= char and (not FlyState.Tool.Parent or FlyState.Tool.Parent == lp.Backpack) then
                pcall(function() hum:EquipTool(FlyState.Tool) end)
            end
            if FlyState.Tool and not FlyState.Tool.Parent then FlyState.Tool = nil end
        else
            if FlyState.WasForcing then
                FlyState.WasForcing = false FlyState.StatesDisabled = false
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true) end)
                if FlyState.Tool and FlyState.Tool.Parent == lp.Backpack then
                    pcall(function() hum:EquipTool(FlyState.Tool) end)
                end
            end
        end
    end)

    Reg("deflectblock", 0.066, function()
        if not Configuration.AutoStopOnKatanaDeflect then return end
        local lp = Utility.Players.LocalPlayer
        if not lp then return end
        local char = lp.Character
        if not char or not char.Parent then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end
        local blk = false
        local aimed = nil
        local lk = CameraAssist.Lock
        if lk and lk.Player and lk.Character and lk.Character.Parent then
            aimed = lk.Player
        end
        if aimed and Utility.IsTargetDeflecting(aimed) then blk = true end
        if not blk and CameraAssist._deflectCooldownUntil
            and tick() < (CameraAssist._deflectCooldownUntil or 0) then
            blk = true
        end
        if blk then
            if tool.Enabled then pcall(function() tool.Enabled = false end) end
        else
            if not tool.Enabled then pcall(function() tool.Enabled = true end) end
        end
    end)

    Connections.Track(Utility.RunService.Heartbeat:Connect(function(dt)
        if CameraAssist.ShuttingDown then return end
        local now = tick()
        for _, sys in pairs(HB) do
            if now - sys.last >= sys.rate then
                sys.last = now
                pcall(sys.fn, dt)
            end
        end
    end))
end

_G.__CELESTIAL_H_last_connections = Connections

_G.__CELESTIAL_H_Diag = function()
    print("=== CELESTIAL H DIAG ===")
    print("device              =", DeviceInfo.isMobile and "MOBILE" or "PC")
    print("platform            =", DeviceInfo.platform)
    print("keyboard            =", DeviceInfo.keyboard)
    print("smoothing slider    =", Configuration.CameraAssistSmoothing)
    print("silent aim          =", Configuration.SilentAimEnabled)
    print("silent hook         =", SILENT.Mode)
    print("silent hit count    =", SILENT.HitCount)
    print("aimbot enabled      =", Configuration.CameraAssistEnabled)
    print("no recoil           =", Configuration.NoRecoilEnabled)
    print("anti flash          =", Configuration.AntiFlashEnabled)
    print("night vision        =", Configuration.NightVisionEnabled)
    print("premium             =", Configuration.IsPremium, Configuration.PremiumTier or "")
    print("=================")
end

_G.__CELESTIAL_H_Mobile = {
    device = DeviceInfo,
    aim = function(s) CameraAssist.KeyHeld = s and true or false end,
    toggleMenu = function() mobileToggleMenu() end,
    overlay = MobileOverlay,
}

local StartupGate = {}
StartupGate.Interval = 12 * 60 * 60

local function sgRead()
    if not ExecutorInfo.HasReadfile then return nil end
    for _, p in ipairs({"CELESTIAL_H/LastStartup.txt", "CELESTIAL_H_LastStartup.txt"}) do
        local ok, d = pcall(readfile, p)
        if ok and d then
            local n = tonumber(d)
            if n and n > 0 then return n end
        end
    end
    return nil
end
local function sgWrite(t)
    if not ExecutorInfo.HasWritefile then return end
    if ExecutorInfo.HasMakeFolder then pcall(makefolder, "CELESTIAL_H") end
    for _, p in ipairs({"CELESTIAL_H/LastStartup.txt", "CELESTIAL_H_LastStartup.txt"}) do
        if pcall(writefile, p, tostring(t)) then return end
    end
end
function StartupGate.ShouldPlay()
    local last = sgRead()
    if not last then return true end
    return (os.time() - last) >= StartupGate.Interval
end
function StartupGate.MarkPlayed() sgWrite(os.time()) end
function StartupGate.Run()
    task.defer(function()
        task.wait(0.3)
        local rev = false
        local function rv()
            if rev then return end
            rev = true
            if Interface.MainFrame then Interface.MainFrame.Visible = true end
            _G.__CELESTIAL_H_StartupDone = true
            if _G.__CELESTIAL_H_BindDeferred then pcall(_G.__CELESTIAL_H_BindDeferred) end
        end
        if not StartupGate.ShouldPlay() then rv() return end
        StartupGate.MarkPlayed()
        local sok = pcall(showStartup, rv)
        if not sok then rv() end
        task.delay(8, rv)
    end)
end

local function scheduleDiscordPopup()
    task.spawn(function()
        local waited = 0
        while not _G.__CELESTIAL_H_StartupDone and waited < 15 do
            task.wait(0.15)
            waited = waited + 0.15
        end
        task.wait(0.6)
        local now = os.time()
        local last = nil
        if ExecutorInfo.HasReadfile then
            for _, p in ipairs({"CELESTIAL_H/LastDiscordPopup.txt", "CELESTIAL_H_LastDiscordPopup.txt"}) do
                local ok, d = pcall(readfile, p)
                if ok and d then
                    local n = tonumber(d)
                    if n and n > 0 then last = n break end
                end
            end
        end
        if last and (now - last) < 12 * 60 * 60 then return end
        if ExecutorInfo.HasWritefile then
            if ExecutorInfo.HasMakeFolder then pcall(makefolder, "CELESTIAL_H") end
            for _, p in ipairs({"CELESTIAL_H/LastDiscordPopup.txt", "CELESTIAL_H_LastDiscordPopup.txt"}) do
                if pcall(writefile, p, tostring(now)) then break end
            end
        end
        pcall(makeDiscordPopup)
    end)
end

task.defer(function()
    KeySystem.Authorized = true
    Configuration.IsPremium = true
    Configuration.PremiumTier = "Premium"
    pcall(initialize)
    task.defer(function()
        pcall(makeWatermark)
        pcall(makeHUD)
    end)
    print("CELESTIAL H LOADED")
    StartupGate.Run()
    scheduleDiscordPopup()
    pcall(Presence.Register)
end)

print("CELESTIAL H INITIALIZING")

task.defer(function()
    while not CameraAssist.ShuttingDown do
        task.wait(2)
        if Configuration.WatermarkEnabled ~= false then
            if not WatermarkControl.Gui or not WatermarkControl.Gui.Parent then pcall(makeWatermark) end
        end
        if Configuration.HUDEnabled ~= false then
            if not HUDControl.Stats or not HUDControl.Stats.Parent then pcall(makeHUD) end
        end
    end
end)

return {Configuration = Configuration, Utility = Utility, KeySystem = KeySystem, WorldVisuals = WorldVisuals}
