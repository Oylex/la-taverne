-- Guild membership: the real guild roster, or a simulated guild in sandbox mode.
-- Everything that asks "is this player one of us?" goes through this module.
local ADDON, ns = ...
local Guild = ns.NewModule("Guild")

local roster = {} -- [nameKey] = member
local rosterCount = 0

-- (Also loads the Guild Info: Alliance.lua asks for it while that's still empty.)
local function RequestRoster()
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    elseif GuildRoster then
        GuildRoster()
    end
end
Guild.RequestRoster = RequestRoster

local function RebuildRoster()
    wipe(roster)
    rosterCount = 0
    if not IsInGuild() then return end
    for i = 1, GetNumGuildMembers() or 0 do
        local name, rank, rankIndex, level, _, zone, _, _, online, _, classFile = GetGuildRosterInfo(i)
        if name then
            roster[ns.NameKey(name)] = {
                name = name,
                rank = rank,
                rankIndex = rankIndex,
                level = level,
                class = classFile,
                online = online and true or false,
                -- (where the game shows them in the guild roster, while online)
                zone = online and type(zone) == "string" and zone ~= "" and zone or nil,
            }
            rosterCount = rosterCount + 1
        end
    end
    Guild.SaveSnapshot()
end

-- My guild's member names, dated, saved for the whole account so my other characters can vouch
-- for them (Vouch.lua reads it; it also drops old ones): ns.db.rosterSnapshots[guild, lowercase]
-- = { guild, t, by, count, partial, names = { [nameKey] = true } }. partial: nobody offline in
-- the list (the game may only give the online members), so being missing from it proves
-- nothing. Never in test mode. At most every 10 minutes, unless the member count changed.
local SNAPSHOT_EVERY = 10 * 60
function Guild.SaveSnapshot()
    if Guild:IsSandbox() or rosterCount == 0 or not ns.db then return end
    local mine = GetGuildInfo("player")
    if type(mine) ~= "string" or mine == "" then return end
    ns.db.rosterSnapshots = ns.db.rosterSnapshots or {}
    local key = strtrim(mine):lower()
    local old = ns.db.rosterSnapshots[key]
    local now = GetServerTime()
    if type(old) == "table" and old.count == rosterCount and now - (old.t or 0) < SNAPSHOT_EVERY then return end
    local names, offline = {}, false
    for nameKey, member in pairs(roster) do
        names[nameKey] = true
        if not member.online then offline = true end
    end
    ns.db.rosterSnapshots[key] = { guild = mine, t = now, by = ns.FullName("player"), count = rosterCount,
        partial = not offline or nil, names = names }
end

function Guild:IsSandbox()
    return ns.db and ns.db.dev.sandbox
end

function Guild:InGuild()
    if self:IsSandbox() then return true end
    return IsInGuild()
end

function Guild:GetName()
    if self:IsSandbox() then return ns.db.dev.guildName end
    return (GetGuildInfo("player"))
end

-- Game restrictions (combat, boss, Mythic+, PvP match, some maps): while one is on, the game
-- blocks reading the Guild Info (ADDON_ACTION_BLOCKED) and the read comes back empty.
function Guild:Restricted()
    if InCombatLockdown and InCombatLockdown() then return true end
    local R = C_RestrictedActions
    local types = Enum and Enum.AddOnRestrictionType
    if R and R.IsAddOnRestrictionActive and types then
        for _, v in pairs(types) do
            local ok, on = pcall(R.IsAddOnRestrictionActive, v)
            if ok and on then return true end
        end
    end
    return false
end

-- The Guild Info, or nil while the game won't let addons read it (see Restricted).
function Guild:GetInfoText()
    if self:IsSandbox() then return ns.db.dev.infoText or "" end
    if self:Restricted() then return nil end
    return (GetGuildInfoText and GetGuildInfoText()) or ""
end

-- Returns the member entry for a "Firstname Lastname", or nil if not in the guild.
function Guild:GetMember(name)
    local key = ns.NameKey(name)
    if not key then return nil end
    if self:IsSandbox() then
        if ns.IsMe(name) then
            local _, classFile = UnitClass("player")
            return { name = ns.FullName("player"), rank = "Testeur", level = UnitLevel("player"), class = classFile, online = true }
        end
        local entry = ns.db.dev.roster[key]
        if entry then
            local real = roster[key]
            return {
                name = entry.name, rank = "Testeur", online = true,
                class = entry.class or (real and real.class), level = entry.level or (real and real.level),
            }
        end
        return nil
    end
    return roster[key]
end

-- Fake members have no class or level until their addon tells us (sandbox only).
function Guild:NoteClass(name, class, level)
    if not self:IsSandbox() then return end
    local entry = ns.db.dev.roster[ns.NameKey(name)]
    if entry then
        if type(class) == "string" then entry.class = class end
        if tonumber(level) then entry.level = tonumber(level) end
    end
end

-- Last time a fake member's addon talked to us (sandbox only), for the test guild window.
function Guild:NoteSeen(name)
    if not self:IsSandbox() then return end
    local entry = ns.db.dev.roster[ns.NameKey(name)]
    if entry then entry.seen = GetServerTime() end
end

-- Guild members whose name contains the text, online first. Used for name autocomplete.
function Guild:Search(text, limit)
    local needle = ns.NameKey(text)
    local results = {}
    if not needle or needle == "" then return results end
    local function consider(member)
        if member and not ns.IsMe(member.name) and ns.NameKey(member.name):find(needle, 1, true) then
            results[#results + 1] = member
        end
    end
    if self:IsSandbox() then
        for key in pairs(ns.db.dev.roster) do consider(self:GetMember(key)) end
    else
        for _, member in pairs(roster) do consider(member) end
    end
    table.sort(results, function(a, b)
        local aStarts = ns.NameKey(a.name):sub(1, #needle) == needle
        local bStarts = ns.NameKey(b.name):sub(1, #needle) == needle
        if aStarts ~= bStarts then return aStarts end
        if a.online ~= b.online then return a.online end
        return a.name < b.name
    end)
    for i = #results, (limit or 8) + 1, -1 do results[i] = nil end
    return results
end

-- Online members (me included), for the Players page. Debug mode: the test guild's members.
function Guild:GetOnline()
    local out = {}
    if self:IsSandbox() then
        for key in pairs(ns.db.dev.roster) do
            local m = self:GetMember(key)
            if m then out[#out + 1] = m end
        end
    else
        for _, member in pairs(roster) do
            if member.online then out[#out + 1] = member end
        end
    end
    return out
end

-- Officers = players allowed to edit the Guild Info. Everyone counts as one in sandbox (the
-- officer tools then only change the fake Guild Info).
function Guild:IsOfficer()
    if self:IsSandbox() then return true end
    return IsInGuild() and CanEditGuildInfo and CanEditGuildInfo() and true or false
end

-- Is this guild name my guild (the fake one in sandbox)?
function Guild:IsMyGuild(guildName)
    local mine = self:GetName()
    if type(guildName) ~= "string" or not mine then return false end
    return strtrim(guildName):lower() == strtrim(mine):lower()
end

function Guild:IsMember(name)
    return self:GetMember(name) ~= nil
end

function Guild:GetRosterCount()
    if self:IsSandbox() then
        local count = 1 -- me
        for _ in pairs(ns.db.dev.roster) do count = count + 1 end
        return count
    end
    return rosterCount
end

function Guild:OnLogin()
    ns.On("GUILD_ROSTER_UPDATE", RebuildRoster)
    ns.On("PLAYER_GUILD_UPDATE", function()
        RequestRoster()
        RebuildRoster()
    end)
    RequestRoster()
    -- The roster only refreshes when asked; keep it reasonably fresh.
    C_Timer.NewTicker(60, RequestRoster)
end
