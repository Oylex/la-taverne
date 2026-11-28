-- Guild and allied players on the world map.
--
-- Sharing (Options, on by default): every few seconds my place (a uiMapID and x, y on it) goes to
-- my guild (guild scope) and to the allied guilds (alliance channel), as hidden messages only
-- La Taverne reads. Every TICK while I move, every STILL_EVERY while I stand still, never from a
-- dungeon, raid or battleground ("off" then, and when sharing is turned off). Positions are never
-- queued: when the channel isn't ready, the next one goes instead.
-- Showing (Options: guild members, allied guilds): a class-coloured dot where each one stands,
-- on the game's world map, through its own map pin system (a data provider). With OpenMap's
-- stitched map, the dots are placed through OpenMap's public API (OpenMapAPI.WorldFromMap and
-- MapFromWorld), so they show from neighbouring zones and at any zoom too. Nothing else of
-- OpenMap's is used, except reading its saved "share" switches to avoid a second dot where
-- OpenMap already draws the same player (both share through it).
-- My party or raid is left to the game's own dots. A dot goes after GONE_AFTER without news.
-- Relayed positions (RMAP, Relay.lua): an allied guild's relay passes on its members who share
-- through OpenMap without La Taverne. Shown like the allied guilds' other dots, a little behind
-- (every 30 s to 2 min, so they last RELAYED_GONE), never over a player's own position.
local ADDON, ns = ...
local AllyMap = ns.NewModule("AllyMap")
local L = ns.L

local TICK = 2          -- seconds between looks at where I am
local SEND_EVERY = 10   -- seconds between places sent while I move (OpenMap's pace; dots glide in between)
local STILL_EVERY = 60  -- ... and while I stand still (a dot that's heard from stays)
local SLACK = 0.5       -- (timers aren't exact: 4.99 s is 5 s)
local GONE_AFTER = 150  -- seconds without news before a dot goes
local PRUNE_EVERY = 10  -- seconds between looks for dots gone stale
local MOVED = 0.002     -- a move this small on a zone's map isn't one
local DOT_SIZE = 14
local GLIDE = SEND_EVERY -- seconds a dot takes to slide to its new place
local JUMP = 0.1        -- a move this big on the shown map (a flight, a portal): placed at once, no slide
local FULL_EVERY = 60   -- seconds between messages that also carry class, level and character ID
local PIN = "LaTaverneAllyMapPin"
local TAG_COLOR = { 0.56, 0.72, 0.91 } -- allied guild ring (the tag's colour in allied chat)

local RELAYED_GONE = 300 -- seconds without news before a relayed dot goes
local RELAYED_MAX = 25   -- players read from one relayed batch (the relay sends 20 at most)

AllyMap.stats = { sent = 0, offSent = 0, received = 0, rejected = 0, expired = 0, drawn = 0, skippedOpenMap = 0,
    relayed = 0, relayedRefused = 0 }

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function Settings()
    return ns.db.allyMap
end

-- OpenMap ----------------------------------------------------------------------------------

-- OpenMap's account settings (its "worldmap" module), read only; nil without OpenMap.
local function OpenMapSettings()
    if not OpenMapAPI then return nil end
    local db = type(OpenMapDB) == "table" and OpenMapDB.worldmap
    return type(db) == "table" and db or nil
end

local function OpenMapStitched()
    if not (OpenMapAPI and OpenMapAPI.IsStitched) then return false end
    local ok, on = pcall(OpenMapAPI.IsStitched)
    return ok and on and true or false
end

-- OpenMap here, for Options: "on" (loaded, its map on), "off" (loaded, its map turned off in
-- its options), nil (not loaded).
function AllyMap:OpenMapState()
    if not OpenMapAPI then return nil end
    local db = OpenMapSettings()
    return (db and db.enabled == false) and "off" or "on"
end

-- Is my own OpenMap sharing my place too (to my guild and my friends who use it)?
local function OpenMapShares()
    local db = OpenMapSettings()
    return db and db.friendsShare == true or false
end

-- Where I am --------------------------------------------------------------------------------

local function InInstance()
    if not IsInInstance then return false end
    local inside = IsInInstance()
    if IsSecret(inside) then return true end
    return inside and true or false
end

local function XY(pos)
    if not pos then return nil end
    local x, y = pos.x, pos.y
    if (x == nil or y == nil) and pos.GetXY then x, y = pos:GetXY() end
    if IsSecret(x) or IsSecret(y) or type(x) ~= "number" or type(y) ~= "number" then return nil end
    return x, y
end

-- My place: a uiMapID and x, y on it (0..1); nil in an instance, or when the game won't say.
local function Here()
    if InInstance() or not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or IsSecret(mapID) or type(mapID) ~= "number" then return nil end
    local ok2, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok2 then return nil end
    local x, y = XY(pos)
    if not x or (x <= 0 and y <= 0) or x > 1 or y > 1 then return nil end -- (0, 0: the game doesn't know)
    return mapID, x, y
end
AllyMap.Here = Here

-- Sending -----------------------------------------------------------------------------------

-- Small: the place as one short text, "map x y" (x and y in 1/10000 of the map), then " 1" when
-- my OpenMap shares my place too (in every message, so nobody draws a second dot over
-- OpenMap's). Class, level and character ID don't change while I walk: only in a full one (the
-- first, then once a minute); receivers keep them from the last full one.
local function MyPayload(m, x, y, full)
    local payload = { p = format("%d %d %d%s", m, math.floor(x * 10000 + 0.5), math.floor(y * 10000 + 0.5),
        OpenMapShares() and " 1" or "") }
    if full then
        local _, class = UnitClass("player")
        local level = UnitLevel("player")
        local guid = UnitGUID("player")
        payload.c = (not IsSecret(class) and type(class) == "string") and class or nil
        payload.l = (not IsSecret(level) and type(level) == "number") and level or nil
        payload.id = (not IsSecret(guid) and type(guid) == "string") and guid or nil
    end
    return payload
end

-- One message for everyone: with a Guild Alliance, on the alliance channel only (my own guild
-- reads it there too, Comm lets my guild's positions through); without one, on the guild channel.
-- If the alliance channel isn't ready yet, the guild channel. Never queued. True if it went.
local function Broadcast(make, priority)
    if ns.Alliance:IsActive() and ns.Comm:SendAlly("POS", make(), priority, true) then return true end
    return ns.Guild:InGuild() and ns.Comm:Send("POS", make(), priority, true) or false
end

local last = { at = -math.huge, full = -math.huge } -- my place as last sent: m, x, y, at; full: last full one
local sharing = false            -- a place went out since sharing (re)started: "off" is owed when it stops

local function Tick()
    if not ns.db or not ns.Comm:IsLoggedIn() then return end
    if not Settings().share or InInstance() then
        -- "off" is owed until it goes out (a channel not ready: tried again next tick).
        if sharing and Broadcast(function() return { off = true } end, "NORMAL") then
            sharing = false
            last.m, last.at, last.full = nil, -math.huge, -math.huge
            AllyMap.stats.offSent = AllyMap.stats.offSent + 1
        end
        return
    end
    -- Nothing goes out before the player was told it's shared (the notice, OnLogin).
    if not Settings().told then return end
    local m, x, y = Here()
    if not m then return end
    local moved = m ~= last.m or math.abs(x - last.x) > MOVED or math.abs(y - last.y) > MOVED
    if GetTime() - last.at < (moved and SEND_EVERY or STILL_EVERY) - SLACK then return end
    local full = GetTime() - last.full >= FULL_EVERY - SLACK
    if Broadcast(function() return MyPayload(m, x, y, full) end, "BULK") then
        last.m, last.x, last.y, last.at = m, x, y, GetTime()
        if full then last.full = GetTime() end
        sharing = true
        AllyMap.stats.sent = AllyMap.stats.sent + 1
    end
end

-- Who's where -------------------------------------------------------------------------------

-- [nameKey] = { key, name, scope ("guild" | "ally"), guild, tag, m, x, y, c, l, guid, om, at }
local live = {}

local function InMyGroup(e)
    if not IsInGroup() then return false end
    local raid = IsInRaid()
    for i = 1, GetNumGroupMembers() do
        local unit = raid and ("raid" .. i) or ("party" .. i)
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if e.guid and not IsSecret(guid) and guid == e.guid then return true end
            local name = ns.FullName(unit)
            if name and not IsSecret(name) and ns.NameKey(name) == e.key then return true end
        end
    end
    return false
end

-- On my friends list, or a Battle.net friend (what OpenMap shares to besides the guild).
local function IsFriend(e)
    if e.guid then
        if C_FriendList and C_FriendList.IsFriend then
            local ok, yes = pcall(C_FriendList.IsFriend, e.guid)
            if ok and yes and not IsSecret(yes) then return true end
        end
        if C_BattleNet and C_BattleNet.GetAccountInfoByGUID then
            local ok, info = pcall(C_BattleNet.GetAccountInfoByGUID, e.guid)
            if ok and info and not IsSecret(info) then return true end
        end
    end
    if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
        for i = 1, C_FriendList.GetNumFriends() or 0 do
            local f = C_FriendList.GetFriendInfoByIndex(i)
            if f and type(f.name) == "string" and not IsSecret(f.name) and ns.NameKey(f.name) == e.key then return true end
        end
    end
    return false
end

-- OpenMap already draws this one itself (they share through it, and my OpenMap shows them):
-- a dot of ours would be a second one on top.
local function OpenMapDraws(e)
    if not e.om or not OpenMapStitched() then return false end
    local db = OpenMapSettings()
    if not db then return false end
    if e.scope == "guild" then return db.guild ~= false end
    return db.friends ~= false and IsFriend(e)
end

-- OpenMap's map is on and its own "Guild members on the map" is off: the player doesn't want
-- guild dots there, so ours hide too (instead of taking the place of OpenMap's), the allied
-- guilds' as well (they count as the guild, here as everywhere in La Taverne).
local function OpenMapHidesGuild()
    if not OpenMapStitched() then return false end
    local db = OpenMapSettings()
    return db ~= nil and db.guild == false
end

-- Whether a dot of ours shows for this one; false and "openmap" when OpenMap draws them already
-- (or OpenMap's guild switch is off).
local function Visible(e)
    local s = Settings()
    if e.scope == "guild" and not s.showGuild then return false end
    if e.scope == "ally" and not s.showAllies then return false end
    if OpenMapHidesGuild() then return false, "openmap" end
    if GetTime() - e.at > (e.lease or GONE_AFTER) then return false end
    if InMyGroup(e) then return false end
    if OpenMapDraws(e) then return false, "openmap" end
    return true
end

-- Placing a dot on the map shown -----------------------------------------------------------

local function WorldPos(m, x, y)
    if not (C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, cont, world = pcall(C_Map.GetWorldPosFromMapPos, m, CreateVector2D(x, y))
    if not ok or IsSecret(cont) or type(cont) ~= "number" or not world then return nil end
    return cont, world
end

-- The game's own map: through the world position, on a map of the same continent.
local function GamePosition(e, shown)
    local cont, world = WorldPos(e.m, e.x, e.y)
    if not cont or WorldPos(shown, 0.5, 0.5) ~= cont or not C_Map.GetMapPosFromWorldPos then return nil end
    local ok, _, pos = pcall(C_Map.GetMapPosFromWorldPos, cont, world, shown)
    if not ok then return nil end
    local x, y = XY(pos)
    if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then return x, y end
    return nil
end

-- Where a dot goes on the shown map's canvas (0..1 its own rectangle, past it on OpenMap's
-- stitched view, which shows beyond it); nil when it isn't on this map.
local function PinPosition(e, shown)
    if e.m == shown then return e.x, e.y end
    if OpenMapStitched() then
        local ok, u, v = pcall(OpenMapAPI.WorldFromMap, e.m, e.x, e.y)
        if ok and u then
            local ok2, x, y = pcall(OpenMapAPI.MapFromWorld, shown, u, v)
            if ok2 and x and x > -2 and x < 3 and y > -2 and y < 3 then return x, y end
            -- (OpenMap couldn't place it on this map: the game's own placement below)
        end
    end
    return GamePosition(e, shown)
end

-- Map pins ----------------------------------------------------------------------------------

local function ClassColor(class)
    local c = class and ((C_ClassColor and C_ClassColor.GetClassColor(class)) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]))
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function GuildColor()
    local info = ChatTypeInfo and ChatTypeInfo.GUILD
    if info then return info.r, info.g, info.b end
    return 0.25, 1, 0.25
end

-- OpenMap's stitched art can sit over the map's pins: a dot is lifted above it (not in
-- combat, where frame levels on the map are best left alone; lifted again as it ends).
local function HoverScripts(pin)
    if pin and not pin:GetScript("OnEnter") then
        pin:SetScript("OnEnter", pin.OnMouseEnter)
        pin:SetScript("OnLeave", pin.OnMouseLeave)
    end
end

local function Lift(pin)
    HoverScripts(pin)
    if not pin or not OpenMapStitched() or InCombatLockdown() or not OpenMapAPI.ArtTopLevel then return end
    local ok, top = pcall(OpenMapAPI.ArtTopLevel)
    if ok and type(top) == "number" and pin:GetFrameLevel() <= top then pin:SetFrameLevel(top + 2) end
end

-- A relayed dot: who passed it on, with "(not checked yet)" / "(disputed)" when nobody vouches
-- for that relay (Vouch.lua).
local function RelayedLine(e)
    local mark = ns.Vouch and ns.Vouch:Mark(e.relayedBy) or ""
    return L["Shares through OpenMap · passed on by %s (guild relay)"]:format(e.relayedBy .. mark)
end

local function ShowTooltip(pin)
    local e = pin.entry
    if not e then return end
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:AddLine(e.name, ClassColor(e.c))
    local info = C_Map.GetMapInfo(e.m)
    local ago = math.floor(GetTime() - e.at)
    -- With OpenMap: its dots' look (Friends.lua's DotEnter), so all dots read alike: level, place,
    -- then who they are in its light blue: "Guild", or the allied guild's name.
    if OpenMapAPI then
        if e.l and e.l > 0 then GameTooltip:AddLine((LEVEL or "Level") .. " " .. e.l, 1, 1, 1) end
        GameTooltip:AddLine(("%s  %.1f, %.1f"):format(info and info.name or "?", e.x * 100, e.y * 100), 1, 1, 1)
        local who = GUILD or "Guild"
        if e.scope == "ally" then who = e.guild or (e.tag and ("[" .. e.tag .. "]")) or who end
        GameTooltip:AddLine(who, 0.6, 0.8, 1)
        if ago >= 20 then GameTooltip:AddLine(L["Updated %d s ago"]:format(ago), 0.6, 0.6, 0.6) end
        if e.relayedBy then GameTooltip:AddLine(RelayedLine(e), 0.6, 0.6, 0.6) end
        GameTooltip:Show()
        return
    end
    if e.scope == "ally" then
        GameTooltip:AddLine((e.tag and ("[" .. e.tag .. "] ") or "") .. (e.guild or ""), TAG_COLOR[1], TAG_COLOR[2], TAG_COLOR[3])
    else
        GameTooltip:AddLine(GUILD or "Guild", GuildColor())
    end
    if e.l and e.l > 0 then GameTooltip:AddLine(L["Level %d"]:format(e.l), 1, 1, 1) end
    GameTooltip:AddLine(("%s  %.1f, %.1f"):format(info and info.name or "?", e.x * 100, e.y * 100), 1, 1, 1)
    if ago >= 20 then GameTooltip:AddLine(L["Updated %d s ago"]:format(ago), 0.6, 0.6, 0.6) end
    if e.relayedBy then GameTooltip:AddLine(RelayedLine(e), 0.6, 0.6, 0.6) end
    GameTooltip:Show()
end

local PinMixin = {}

function PinMixin:OnLoad()
    if self.dot then return end -- (already set up)
    if self.UseFrameLevelType then self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI") end
    if self.SetScalingLimits then self:SetScalingLimits(1, 1.0, 1.2) end
    self:SetSize(DOT_SIZE, DOT_SIZE)
    self.ring = self:CreateTexture(nil, "BORDER")
    self.ring:SetPoint("CENTER")
    self.ring:SetSize(DOT_SIZE, DOT_SIZE)
    self.dot = self:CreateTexture(nil, "ARTWORK")
    self.dot:SetPoint("CENTER")
    self.dot:SetSize(DOT_SIZE - 4, DOT_SIZE - 4)
    local atlas = C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("WhiteCircle-RaidBlips")
    for _, tex in ipairs({ self.ring, self.dot }) do
        if atlas then
            tex:SetAtlas("WhiteCircle-RaidBlips")
        else
            tex:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask") -- (a white disc)
        end
    end
    self:EnableMouse(true)
    if self.SetMouseClickEnabled then self:SetMouseClickEnabled(false) end -- (clicks go to the map)
    -- No OnEnter/OnLeave here: the map asserts a new pin has none ("assertion failed!" in
    -- AcquirePin), then sets them itself from OnMouseEnter/OnMouseLeave below. HoverScripts
    -- adds them after AcquirePin on clients whose map doesn't.
end

function PinMixin:OnMouseEnter() ShowTooltip(self) end
function PinMixin:OnMouseLeave() GameTooltip:Hide() end

function PinMixin:Look()
    local e = self.entry
    self.dot:SetVertexColor(ClassColor(e.c))
    if e.scope == "ally" then
        self.ring:SetVertexColor(TAG_COLOR[1], TAG_COLOR[2], TAG_COLOR[3])
    else
        self.ring:SetVertexColor(GuildColor())
    end
end

-- Sliding to a new place over GLIDE seconds, so a dot moves smoothly between two messages.
local function GlideUpdate(self)
    local t = (GetTime() - self.glideStart) / GLIDE
    if t >= 1 then
        self:SetScript("OnUpdate", nil)
        self.curX, self.curY = self.toX, self.toY
    else
        self.curX = self.fromX + (self.toX - self.fromX) * t
        self.curY = self.fromY + (self.toY - self.fromY) * t
    end
    self:SetPosition(self.curX, self.curY)
end

function PinMixin:PlaceAt(x, y)
    self:SetScript("OnUpdate", nil)
    self.curX, self.curY = x, y
    self:SetPosition(x, y)
end

function PinMixin:MoveTo(x, y)
    if not self.curX or math.abs(x - self.curX) > JUMP or math.abs(y - self.curY) > JUMP then
        self:PlaceAt(x, y)
        return
    end
    self.fromX, self.fromY, self.toX, self.toY = self.curX, self.curY, x, y
    self.glideStart = GetTime()
    self:SetScript("OnUpdate", GlideUpdate)
end

function PinMixin:OnAcquired(entry, x, y)
    self.entry = entry
    self:PlaceAt(x, y)
    self:Look()
end

function PinMixin:OnReleased()
    self:SetScript("OnUpdate", nil)
    self.entry, self.curX, self.curY = nil, nil, nil
end

local provider = CreateFromMixins(MapCanvasDataProviderMixin)
local registered = false

function provider:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate(PIN)
end

function provider:RefreshAllData()
    self:RemoveAllData()
    local map = self:GetMap()
    local shown = map:GetMapID()
    local count, openMap = 0, 0
    if shown then
        for _, e in pairs(live) do
            local show, why = Visible(e)
            if show then
                local x, y = PinPosition(e, shown)
                if x then
                    Lift(map:AcquirePin(PIN, e, x, y))
                    count = count + 1
                end
            elseif why == "openmap" then
                openMap = openMap + 1
            end
        end
    end
    -- (as of the last full redraw)
    AllyMap.stats.drawn, AllyMap.stats.skippedOpenMap = count, openMap
end

-- One player's dot, moved, added or taken off (a full refresh would close the tooltip under the mouse).
function provider:UpdateOne(e)
    local map = self:GetMap()
    local shown = map:GetMapID()
    local pin
    for p in map:EnumeratePinsByTemplate(PIN) do
        if p.entry and p.entry.key == e.key then pin = p break end
    end
    local x, y
    if shown and live[e.key] == e and Visible(e) then x, y = PinPosition(e, shown) end
    if not x then
        if pin then map:RemovePin(pin) end
    elseif pin then
        pin.entry = e
        pin:MoveTo(x, y)
        pin:Look()
        if GameTooltip:GetOwner() == pin then ShowTooltip(pin) end
    else
        Lift(map:AcquirePin(PIN, e, x, y))
    end
end

local function MapShown()
    return registered and WorldMapFrame and WorldMapFrame:IsShown()
end

local function Refresh()
    if MapShown() then provider:RefreshAllData() end
end
AllyMap.Refresh = Refresh

local function Register()
    if registered or not (WorldMapFrame and WorldMapFrame.AddDataProvider and WorldMapFrame.pinPools and MapCanvasPinMixin) then return end
    -- Our pin pool, as HereBeDragons does: pins made in code, not from an XML template.
    local pool = CreateUnsecuredRegionPoolInstance and CreateUnsecuredRegionPoolInstance(PIN) or CreateFramePool("FRAME")
    pool.parent = WorldMapFrame:GetCanvas()
    pool.createFunc = function()
        local frame = CreateFrame("Frame", nil, WorldMapFrame:GetCanvas())
        frame:SetSize(1, 1)
        local pin = Mixin(frame, MapCanvasPinMixin, PinMixin)
        pin:OnLoad() -- (made in code: no XML template calls it)
        return pin
    end
    pool.resetFunc = function(_, pin)
        pin:Hide()
        pin:ClearAllPoints()
        pin:OnReleased()
        pin.pinTemplate = nil
        pin.owningMap = nil
    end
    pool.creationFunc, pool.resetterFunc = pool.createFunc, pool.resetFunc -- (older clients' names)
    WorldMapFrame.pinPools[PIN] = pool
    WorldMapFrame:AddDataProvider(provider)
    registered = true
end

-- Receiving ---------------------------------------------------------------------------------

-- A number between lo and hi (not NaN: every comparison with it is false).
local function Between(v, lo, hi)
    return type(v) == "number" and v >= lo and v <= hi
end

-- The place in a message: "map x y" or "map x y 1" (p: 1 = their OpenMap shares too), or m, x,
-- y and om (the first version). Fills p.m, p.x, p.y, p.om.
local function ReadPlace(p)
    if type(p.p) == "string" and #p.p <= 32 then
        local m, x, y, om = p.p:match("^(%d+) (%d+) (%d+)( ?1?)$")
        if not m then return false end
        p.m, p.x, p.y = tonumber(m), tonumber(x) / 10000, tonumber(y) / 10000
        p.om = om == " 1" or nil
    end
    return true
end

local function ValidPayload(p)
    if not ReadPlace(p) then return false end
    if not Between(p.m, 1, 1000000) or p.m ~= math.floor(p.m) then return false end
    if not Between(p.x, 0, 1) or not Between(p.y, 0, 1) then return false end
    if p.c ~= nil and (type(p.c) ~= "string" or #p.c > 20 or not p.c:match("^%u+$")) then return false end
    if p.l ~= nil and not Between(p.l, 0, 200) then return false end
    if p.id ~= nil and (type(p.id) ~= "string" or #p.id > 64 or not p.id:match("^Player%-")) then return false end
    local ok, info = pcall(C_Map.GetMapInfo, p.m)
    return ok and info ~= nil
end

local function OnPosition(sender, p, isSelf, scope)
    if isSelf or type(sender) ~= "string" or type(p) ~= "table" then return end
    local key = ns.NameKey(sender)
    if p.off then
        local e = live[key]
        if e then
            live[key] = nil
            if MapShown() then provider:UpdateOne(e) end
        end
        return
    end
    if not ValidPayload(p) then
        AllyMap.stats.rejected = AllyMap.stats.rejected + 1
        return
    end
    AllyMap.stats.received = AllyMap.stats.received + 1
    -- Class, level and ID only come in a full message: kept from the last one. Until
    -- one arrives, the class from the guild roster when it's a guildmate.
    local old = live[key]
    if p.c == nil then
        p.c = old and old.c
        if not p.c and scope == "guild" then
            local member = ns.Guild:GetMember(sender)
            p.c = member and member.class or nil
        end
    end
    if p.l == nil then p.l = old and old.l end
    if p.id == nil then p.id = old and old.guid end
    local e = {
        -- (the guild's name is checked allied by Comm; shown as text, no "|" codes)
        key = key, name = sender, scope = scope,
        guild = scope == "ally" and type(p.g) == "string" and p.g:gsub("|", "||") or nil,
        tag = scope == "ally" and (ns.Alliance:GetTag(p.g) or "?") or nil,
        m = p.m, x = p.x, y = p.y, c = p.c, l = p.l, guid = p.id, om = p.om == true, at = GetTime(),
    }
    live[key] = e
    if MapShown() then provider:UpdateOne(e) end
    -- What they said about themselves: the allied player lists show it too.
    if scope == "ally" and ns.Vouch then ns.Vouch:NoteLooks(sender, p.c, p.l) end
end

ns.Comm:On("POS", function(sender, p, isSelf) OnPosition(sender, p, isSelf, "guild") end)
ns.Comm:OnAlly("POS", function(sender, p, isSelf) OnPosition(sender, p, isSelf, "ally") end)

-- A player's name in a relayed batch: no codes, separators or link characters.
local function ValidName(name)
    return type(name) == "string" and not IsSecret(name) and #name <= 48 and name:find("%S") ~= nil
        and not name:find("[%c|%[%]:,;]")
end

-- One entry of a relayed batch: "name,map,x,y" or "name,map,x,y,class,level" (x and y: 3
-- base-36 digits, 1/46655 of the map; class and level may be empty).
local function ReadRelayed(item)
    local name, m, x, y = item:match("^([^,]+),(%d+),(%w%w%w),(%w%w%w)$")
    local c, l
    if not name then
        name, m, x, y, c, l = item:match("^([^,]+),(%d+),(%w%w%w),(%w%w%w),(%u*),(%d*)$")
        if not name then return nil end
    end
    m, x, y = tonumber(m), tonumber(x, 36), tonumber(y, 36)
    if not ValidName(name) or not x or not y then return nil end
    local p = { m = m, x = x / 46655, y = y / 46655 }
    if c and c ~= "" then p.c = c end
    if l and l ~= "" then p.l = tonumber(l) end
    if not ValidPayload(p) then return nil end
    return name, p
end

-- An allied guild's relay (Relay.lua): d, the places; o, the players who stopped. My guild's
-- batches never come here (Comm.lua reads them as my guild's: only the relay hears them).
ns.Comm:OnAlly("RMAP", function(sender, p, isSelf)
    if isSelf or type(sender) ~= "string" or not ns.Relay or type(p.g) ~= "string" then return end
    local rp = tonumber(p.rp) or 0
    if rp > ns.Relay.RP then
        ns.Relay:NoteProtocol(rp, false)
        return
    end
    if rp < ns.Relay.RP - 1 then return end
    local st = AllyMap.stats
    local guild = strtrim(p.g):lower()
    local now = GetTime()
    local touched = {}
    if type(p.o) == "string" and #p.o <= 1500 then
        local n = 0
        for name in p.o:gmatch("[^;]+") do
            n = n + 1
            if n > RELAYED_MAX then break end
            local key = ValidName(name) and ns.NameKey(name)
            local e = key and live[key]
            -- (only a dot this guild's relay put there: a player's own one stays)
            if e and e.relayedBy and e.relayGuild == guild then
                live[key] = nil
                touched[#touched + 1] = e
            end
        end
    end
    if type(p.d) == "string" and #p.d <= 3000 then
        local n = 0
        for item in p.d:gmatch("[^;]+") do
            n = n + 1
            if n > RELAYED_MAX then break end
            local name, place = ReadRelayed(item)
            local key = name and ns.NameKey(name)
            -- Nobody of my guild, nor me: my guild's places never come from an allied guild.
            if not key or ns.IsMe(name) or ns.Guild:IsMember(name) then
                st.relayedRefused = st.relayedRefused + 1
            elseif ns.Vouch and not ns.Vouch:Relayed(name, p.g, sender, "map") then
                -- The game shows them in another guild lately (Vouch.lua): no dot.
                st.relayedRefused = st.relayedRefused + 1
                local old = live[key]
                if old and old.relayedBy then
                    live[key] = nil
                    touched[#touched + 1] = old
                end
            else
                local old = live[key]
                -- Their own position (they run La Taverne) wins while it's fresh.
                if not (old and not old.relayedBy and now - old.at <= GONE_AFTER) then
                    local same = old and old.relayedBy and old.relayGuild == guild
                    local e = {
                        key = key, name = name, scope = "ally",
                        guild = (p.g:gsub("|", "||")), tag = ns.Alliance:GetTag(p.g) or "?",
                        m = place.m, x = place.x, y = place.y,
                        c = place.c or (same and old.c) or nil, l = place.l or (same and old.l) or nil,
                        om = true, -- (they share through OpenMap: mine may draw them already, a friend)
                        at = now, lease = RELAYED_GONE, relayedBy = sender, relayGuild = guild,
                    }
                    live[key] = e
                    touched[#touched + 1] = e
                    st.relayed = st.relayed + 1
                end
            end
        end
    end
    if MapShown() then
        for _, e in ipairs(touched) do provider:UpdateOne(e) end
    end
end)

local function Prune()
    local now, gone = GetTime(), false
    for key, e in pairs(live) do
        if now - e.at > (e.lease or GONE_AFTER) then
            live[key] = nil
            gone = true
            AllyMap.stats.expired = AllyMap.stats.expired + 1
        end
    end
    if gone then Refresh() end
end

-- Settings ----------------------------------------------------------------------------------

-- After a switch changed (Options, OpenMap's menu): sent or stopped now, dots redrawn.
function AllyMap:SettingsChanged()
    Tick()
    Refresh()
end

function AllyMap:SetShow(scope, on)
    local s = Settings()
    if scope == "guild" then s.showGuild = on and true or false else s.showAllies = on and true or false end
    self:SettingsChanged()
    self:UpdateMapButton()
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
end

-- The zone a player shares, by name: from their last position while it's fresh (a city's or a
-- cave's own map read as its zone), nil when they don't share it (sharing off, in an instance,
-- nothing heard lately). For the Professions answers.
local ZONE_TYPE = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
function AllyMap:ZoneOf(name)
    local key = type(name) == "string" and ns.NameKey(name)
    local e = key and live[key]
    if not e or GetTime() - e.at > (e.lease or GONE_AFTER) then return nil end
    local mapID = e.m
    for _ = 1, 5 do
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if not ok or not info then return nil end
        if info.mapType <= ZONE_TYPE or not info.parentMapID or info.parentMapID == 0 then
            return type(info.name) == "string" and info.name ~= "" and info.name or nil
        end
        mapID = info.parentMapID
    end
    return nil
end

function AllyMap:Count()
    local n = 0
    for _ in pairs(live) do n = n + 1 end
    return n
end

-- OpenMap's menu: the two "show" switches, under a "La Taverne" heading (its public API), with
-- the lynx, so a switch starred onto OpenMap's map shows as La Taverne's.
local LYNX = "Interface\\AddOns\\LaTaverne\\media\\lynx_icon"
local openMapHooked = false
local function AddOpenMapToggles()
    if openMapHooked or not (OpenMapAPI and OpenMapAPI.RegisterMenuToggle) then return end
    openMapHooked = true
    pcall(OpenMapAPI.RegisterMenuToggle, "LaTaverne", {
        id = "guild", label = L["Guild members (La Taverne)"], section = "La Taverne", icon = LYNX,
        get = function() return Settings().showGuild end,
        set = function(v) AllyMap:SetShow("guild", v) end,
    })
    pcall(OpenMapAPI.RegisterMenuToggle, "LaTaverne", {
        id = "allies", label = L["Allied guilds (La Taverne)"], section = "La Taverne", icon = LYNX,
        get = function() return Settings().showAllies end,
        set = function(v) AllyMap:SetShow("ally", v) end,
    })
    if OpenMapAPI.RegisterCallback then
        pcall(OpenMapAPI.RegisterCallback, AllyMap, "OpenMap_StitchedChanged", function() Refresh() end)
    end
end

-- A lynx tab on the game map's right edge, where and as OpenMap shows its own: a click opens the
-- two switches. Only without OpenMap's map (its menu has them, and a star puts them on its map),
-- and only while Options, Map leaves it on. Lit while a switch is on, greyed while both are off.
local mapButton

local function ButtonWanted()
    return Settings().button ~= false and AllyMap:OpenMapState() ~= "on"
end

local function ButtonMenu(owner)
    ns.ContextMenu(owner, function(_, root)
        root:CreateTitle("La Taverne")
        root:CreateCheckbox(L["My guild's members"], function() return Settings().showGuild end,
            function() AllyMap:SetShow("guild", not Settings().showGuild) end)
        if ns.Alliance:IsActive() then
            root:CreateCheckbox(L["The allied guilds' members"], function() return Settings().showAllies end,
                function() AllyMap:SetShow("ally", not Settings().showAllies) end)
        end
        root:CreateDivider()
        root:CreateButton(L["Options"], function() ns.UI:ShowSection("options") ns.UI:Open() end)
    end)
end

function AllyMap:UpdateMapButton()
    if not mapButton then return end
    mapButton:SetShown(ButtonWanted())
    local s = Settings()
    local on = (s.showGuild or (s.showAllies and ns.Alliance:IsActive())) and true or false
    -- On: the tab's lit edge, as OpenMap lights a switch that's on. Off: the lynx greyed.
    mapButton.selected:SetShown(on and mapButton.hasArt)
    mapButton.icon:SetDesaturated(not on)
    mapButton.icon:SetAlpha(on and 1 or 0.6)
end

-- The tab looks and sits like OpenMap's own (its Panel.lua and Dungeons.lua): WoW Forever's side
-- tab art (the quest log's tabs), 40 out from the map's right edge by 42 along it, low on that
-- edge with 44 kept clear at the end, the lynx filling its face. The art is drawn for a tab on
-- the left, so it's mirrored for the right edge.
local TAB_ART = { bg = "common-sidetab-c60", selected = "common-sidetab-selected-c60", hover = "common-sidetab-hover-c60" }
local TAB_MASK = "common-sidetab-mask-c60"
local TAB_OUT, TAB_ALONG, TAB_END = 40, 42, 44
local ART_OUT, ART_ALONG, SHOW_OUT, SHOW_ALONG = 55, 60, 52, 54 -- (the art, and the part of it the tab shows)
local FACE_OUT, FACE_ALONG, FACE_IN = 43, 44, 2                 -- (its face, 2 in from the flat side)

local function HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

-- An atlas on a texture, mirrored left for right.
local function Mirrored(tex, name)
    tex:SetAtlas(name)
    local ulx, uly, _, lly, urx = tex:GetTexCoord()
    tex:SetTexCoord(urx, ulx, uly, lly)
end

local function MakeMapButton()
    local map = WorldMapFrame
    local sc = map and map.ScrollContainer
    if mapButton or not sc then return end
    local b = CreateFrame("Button", nil, map)
    b:SetSize(TAB_OUT, TAB_ALONG)
    b:SetPoint("RIGHT", sc, "BOTTOMRIGHT", 0, TAB_END + TAB_ALONG / 2)
    b:SetFrameLevel(math.min(sc:GetFrameLevel() + 9300, 9950)) -- (over the map and its pins)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.selected = b:CreateTexture(nil, "OVERLAY")
    b.hover = b:CreateTexture(nil, "HIGHLIGHT")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexture(LYNX)
    -- The art at the tab's size, its flat side on the map's edge.
    local ao, aa = TAB_OUT * ART_OUT / SHOW_OUT, TAB_ALONG * ART_ALONG / SHOW_ALONG
    local cx = -(ao - TAB_OUT) / 2
    b.hasArt = HasAtlas(TAB_ART.bg)
    if b.hasArt then
        for key, name in pairs(TAB_ART) do
            local tex = b[key]
            Mirrored(tex, HasAtlas(name) and name or TAB_ART.bg)
            tex:SetSize(ao, aa)
            tex:SetPoint("CENTER", cx, 0)
        end
        -- The lynx fills the tab's face, cut to its shape (the face's middle is nearer the flat side).
        if HasAtlas(TAB_MASK) then
            local mask = b:CreateMaskTexture()
            mask:SetAtlas(TAB_MASK)
            pcall(mask.SetTexCoord, mask, 1, 0, 0, 1)
            mask:SetSize(ao, aa)
            mask:SetPoint("CENTER", cx, 0)
            b.icon:AddMaskTexture(mask)
        end
        local side = math.max(FACE_OUT * ao / ART_OUT, FACE_ALONG * aa / ART_ALONG)
        local toward = (ART_OUT / 2 - FACE_IN - FACE_OUT / 2) * ao / ART_OUT
        b.icon:SetSize(side, side)
        b.icon:SetPoint("CENTER", cx + toward, 0)
    else
        -- (no such art on this client: a plain dark tab)
        b.bg:SetAllPoints()
        b.bg:SetColorTexture(0.1, 0.08, 0.06, 0.95)
        b.hover:SetAllPoints()
        b.hover:SetColorTexture(1, 1, 1, 0.15)
        b.icon:SetSize(TAB_ALONG - 10, TAB_ALONG - 10)
        b.icon:SetPoint("CENTER")
    end
    b:SetScript("OnMouseDown", function(self) self.icon:SetVertexColor(0.75, 0.75, 0.75) end)
    b:SetScript("OnMouseUp", function(self) self.icon:SetVertexColor(1, 1, 1) end)
    b:SetScript("OnClick", function(self) ButtonMenu(self) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("La Taverne")
        GameTooltip:AddLine(L["Who shows on the map: click to choose."], 1, 1, 1, true)
        local s = Settings()
        GameTooltip:AddLine(L["My guild's members"] .. ": " .. (s.showGuild and L["on"] or L["off"]), 0.8, 0.8, 0.8)
        if ns.Alliance:IsActive() then
            GameTooltip:AddLine(L["The allied guilds' members"] .. ": " .. (s.showAllies and L["on"] or L["off"]), 0.8, 0.8, 0.8)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    mapButton = b
    map:HookScript("OnShow", function() AllyMap:UpdateMapButton() end)
    AllyMap:UpdateMapButton()
end

-- Before a reload that changes the guild (test mode on or off): "off" now, on the side I'm
-- leaving, so my dot goes away there instead of after GONE_AFTER.
function AllyMap:StopSharing()
    if sharing then
        Broadcast(function() return { off = true } end, "ALERT")
        sharing = false
    end
end

function AllyMap:OnLogin()
    Register()
    MakeMapButton()
    if not registered or not mapButton then
        ns.On("ADDON_LOADED", function(name)
            if name == "Blizzard_WorldMap" then
                Register()
                MakeMapButton()
            end
        end)
    end
    AddOpenMapToggles()
    ns.On("ADDON_LOADED", function(name)
        if name == "OpenMap" then AddOpenMapToggles() end
    end)
    ns.On("PLAYER_REGEN_ENABLED", Refresh)                -- (dots lifted over OpenMap's art again)
    ns.On("GROUP_ROSTER_UPDATE", Refresh)                 -- (my group's own dots are the game's)
    C_Timer.NewTicker(TICK, Tick)
    C_Timer.NewTicker(PRUNE_EVERY, Prune)
    -- OpenMap's guild switch doesn't tell us when it changes: while the map is open, look each
    -- second, and redraw at once (otherwise each dot waited for its player's next position).
    local openMapHid = false
    C_Timer.NewTicker(1, function()
        if not MapShown() then return end
        AllyMap:UpdateMapButton() -- (OpenMap's map switched on or off: the lynx tab follows)
        local hid = OpenMapHidesGuild()
        if hid ~= openMapHid then
            openMapHid = hid
            Refresh()
        end
    end)
    -- Sharing is on by default: said once, so nobody shares without knowing it.
    C_Timer.After(15, function()
        local s = Settings()
        if s.share and not s.told then
            s.told = true
            ns.Print(L["Your position is now shared on the map with your guild and the allied guilds (players who run La Taverne). Options, Map: to turn it off."])
        end
    end)
end

-- /taverne map: what's shared and shown.
ns.commands.map = function()
    local s = Settings()
    local m, x, y = Here()
    ns.Print(format("map: sharing %s, showing guild %s, allies %s, OpenMap %s (stitched %s)",
        s.share and "on" or "off", s.showGuild and "on" or "off", s.showAllies and "on" or "off",
        OpenMapAPI and ("API v" .. tostring(OpenMapAPI.version)) or "absent", OpenMapStitched() and "yes" or "no"))
    ns.Print(m and format("map: here = map %d, %.1f, %.1f", m, x * 100, y * 100) or "map: here = unknown (instance, or the game won't say)")
    local st = AllyMap.stats
    ns.Print(format("map: sent %d, off %d, received %d, rejected %d, expired %d, drawn %d, left to OpenMap %d, relayed %d (refused %d)",
        st.sent, st.offSent, st.received, st.rejected, st.expired, st.drawn, st.skippedOpenMap, st.relayed, st.relayedRefused))
    local om = OpenMapSettings()
    ns.Print(format("map: OpenMap %s, its map %s, its guild switch %s: La Taverne's guild and allied dots %s",
        OpenMapAPI and "loaded" or "not loaded", OpenMapStitched() and "on" or "off",
        om and (om.guild == false and "off" or "on") or "?", OpenMapHidesGuild() and "hidden" or "follow La Taverne's switches"))
    local now = GetTime()
    for _, e in pairs(live) do
        ns.Print(format("  %s (%s%s%s) map %d %.1f, %.1f, %d s ago", e.name, e.scope, e.tag and (" " .. e.tag) or "",
            e.relayedBy and (", relayed by " .. e.relayedBy) or "", e.m, e.x * 100, e.y * 100, math.floor(now - e.at)))
    end
end
