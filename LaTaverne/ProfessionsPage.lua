-- The Professions page: who in my guild or the allied guilds can make a recipe.
-- - Left: a search box (a recipe's name, or shift-click an item into it) and the recipes that
--   match, from this client's own recipe list (Recipes.lua: nothing is asked while typing).
-- - Right: the recipe picked, Search, then the answers as they come: who answered and their
--   zone when they share it on the map (or the guild roster shows it), which of their characters know it (an alt is named), available to help,
--   cooldown, and Whisper (the chat box opened on them, a short text with the item's link,
--   not sent). My own characters are listed at once.
-- - Bottom: share my recipes (answer the questions), available to help.
-- Nothing is kept: leaving the page forgets the question and its answers.
local ADDON, ns = ...
local L = ns.L

local function Kit() return ns.UIKit end

local SUGGEST_H = 24     -- a suggestion row
local ANSWER_H = 40      -- an answer row
local SEARCHING_FOR = 15 -- seconds "Searching..." is shown after asking (answers still come after)
local SUGGEST_MAX = 50

local panel
local selected            -- the recipe picked (ID)
local itemIndex           -- [item ID] = { recipe ID, ... }, built the first time an item is shift-clicked
local itemIndexOf         -- the recipe list it was built from (Recipes.loads): built again after a new one
local Fill                -- (below)

-- A recipe's icon: the item it makes (many recipe spells only have the game's placeholder icon),
-- else the spell's own (enchants make no item). Read from the client, kept once found.
local icons = {}
local function RecipeIcon(id)
    if icons[id] then return icons[id] end
    local ok, icon = pcall(function()
        local out = C_TradeSkillUI.GetRecipeOutputItemData(id)
        local made = type(out) == "table" and out.itemID
        if made and made > 0 then
            return out.icon or (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(made))
        end
    end)
    if not (ok and icon) then
        ok, icon = pcall(function() return C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id) end)
    end
    icon = ok and icon or nil
    if icon then icons[id] = icon end
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- A recipe's tooltip: the game's own one for the item it makes (stats, level, binding), else the
-- spell's (enchants make no item), then its profession and whether I know it. Only the names
-- when the client has neither.
local function RecipeTooltip(owner, entry)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local ok, out = pcall(C_TradeSkillUI.GetRecipeOutputItemData, entry.id)
    local itemID = ok and type(out) == "table" and out.itemID
    local shown = itemID and itemID > 0 and pcall(GameTooltip.SetItemByID, GameTooltip, itemID)
    if not shown then shown = pcall(GameTooltip.SetSpellByID, GameTooltip, entry.id) end
    if not shown or GameTooltip:NumLines() == 0 then GameTooltip:SetText(entry.name) end
    local prof = ns.Recipes:ProfessionName(entry.prof)
    if prof then GameTooltip:AddLine(prof, 0.6, 0.6, 0.6) end
    if ns.Recipes:Knows(entry.id) then GameTooltip:AddLine(L["You know this recipe."], 0.13, 1, 0.13) end
    GameTooltip:Show()
end

local function Duration(seconds)
    if seconds >= 3600 then return format(L["%d h"], math.ceil(seconds / 3600)) end
    return format(L["%d min"], math.max(1, math.ceil(seconds / 60)))
end

-- The item a recipe makes, as a chat link, given to done(link) once the item is loaded (its name
-- comes from the server the first time). An enchant makes no item: the recipe's own link, or its
-- name in brackets.
local function RecipeLink(id, done)
    local ok, out = pcall(C_TradeSkillUI.GetRecipeOutputItemData, id)
    local itemID = ok and type(out) == "table" and out.itemID
    if itemID and itemID > 0 then
        local Item = _G.Item
        if Item and Item.CreateFromItemID then
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(function() done(item:GetItemLink() or out.hyperlink) end)
            return
        end
        if type(out.hyperlink) == "string" and not out.hyperlink:find("[]", 1, true) then
            done(out.hyperlink)
            return
        end
    end
    -- (Two lookups, not a list: Forever has no C_TradeSkillUI.GetRecipeLink, and a nil first in a
    -- list stops ipairs before C_Spell.GetSpellLink.)
    local link
    for _, get in pairs({ recipe = C_TradeSkillUI.GetRecipeLink, spell = C_Spell.GetSpellLink }) do
        if not link then
            local got, value = pcall(get, id)
            if got and type(value) == "string" and value ~= "" then link = value end
        end
    end
    done(link or ("[" .. (C_Spell.GetSpellName(id) or "?") .. "]"))
end

-- Whisper: the chat box opened on them, with the text ready (not sent). With the gamepad UI on,
-- La Taverne doesn't open the game's windows: a clickable name in the chat instead.
local function Whisper(name, id)
    RecipeLink(id, function(link)
        local text = format(L["Hi, could you make %s?"], link)
        if ns.GamepadUI() then
            local label = "|cff71d5ff[" .. name .. "]|r"
            local player = GetPlayerLink and GetPlayerLink(name, label) or ("|Hplayer:" .. name .. "|h" .. label .. "|h")
            ns.Print(format(L["Click %s to whisper them."], player) .. " " .. text)
            return
        end
        local tell = (ChatFrameUtil and ChatFrameUtil.SendTell) or ChatFrame_SendTell
        if not tell then return end
        tell(name)
        local get = (ChatFrameUtil and ChatFrameUtil.GetActiveWindow) or _G.ChatEdit_GetActiveWindow
        local box = get and get()
        if box and box.Insert then box:Insert(text) end
    end)
end

-- Shift-clicking an item --------------------------------------------------------------------

-- Which recipes make this item: from the recipe list, the item each one makes (read from the
-- client, no server request: the item's ID only). Built once, the first time.
local function RecipesMaking(itemID)
    if not ns.Recipes:IsReady() then return nil end -- (nothing cached before the list is there)
    if not itemIndex or itemIndexOf ~= ns.Recipes.loads then
        itemIndex = {}
        itemIndexOf = ns.Recipes.loads
        for _, entry in ipairs(ns.Recipes:All()) do
            local ok, out = pcall(C_TradeSkillUI.GetRecipeOutputItemData, entry.id)
            local made = ok and type(out) == "table" and out.itemID
            if made and made > 0 then
                itemIndex[made] = itemIndex[made] or {}
                table.insert(itemIndex[made], entry.id)
            end
        end
    end
    return itemIndex[itemID]
end

-- A link put in the search box (shift-click on an item, an enchant, a recipe): its recipes picked.
local lastLink, lastLinkAt
local function TakeLink(link)
    if not (panel and panel.search and panel.search:HasFocus()) or type(link) ~= "string" then return end
    if link == lastLink and GetTime() - lastLinkAt < 0.2 then return end -- (the same click, by the other hook)
    lastLink, lastLinkAt = link, GetTime()
    local name = link:match("|h%[(.-)%]|h") or ""
    local itemID = tonumber(link:match("|Hitem:(%d+)"))
    local spellID = tonumber(link:match("|Henchant:(%d+)") or link:match("|Hspell:(%d+)"))
    local ids = itemID and RecipesMaking(itemID) or (spellID and ns.Recipes:Get(spellID) and { spellID }) or nil
    -- The name as plain text, the box still being typed in (Backspace, another shift-click).
    panel.search:SetText(name)
    panel.search:SetCursorPosition(#name)
    if ids and ids[1] then
        panel.linked = ids
        selected = ids[1]
    else
        panel.linked = nil
        ns.Print(format(L["No recipe makes %s."], link))
    end
    Fill()
end

local hooked = false
local function HookLinks()
    if hooked then return end
    hooked = true
    -- Whichever the game has: the item link goes to the chat box (or ours, while it has the
    -- focus). Both when both exist (which one a shift-click calls isn't known); one may call the
    -- other, so TakeLink ignores the same link twice in a moment.
    if type(_G.ChatEdit_InsertLink) == "function" then hooksecurefunc("ChatEdit_InsertLink", TakeLink) end
    if ChatFrameUtil and type(ChatFrameUtil.InsertLink) == "function" then hooksecurefunc(ChatFrameUtil, "InsertLink", TakeLink) end
end

-- Rows ----------------------------------------------------------------------------------------

local function InitSuggestion(row, entry)
    local K = Kit()
    if not row.init then
        row.init = true
        K.RowBackground(row)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", 4, 0)
        row.name = K.NewLabel(row, "", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.name:SetPoint("RIGHT", -90, 0)
        row.name:SetJustifyH("LEFT")
        row.name:SetWordWrap(false)
        row.prof = K.NewLabel(row, "", "GameFontDisableSmall")
        row.prof:SetPoint("RIGHT", -6, 0)
        row.prof:SetWidth(84)
        row.prof:SetJustifyH("RIGHT")
        row.prof:SetWordWrap(false)
        row.glow = row:CreateTexture(nil, "BACKGROUND", nil, 1)
        row.glow:SetAllPoints()
        row.glow:SetColorTexture(1, 0.82, 0, 0.18)
        row:EnableMouse(true)
        row:SetScript("OnMouseUp", function(self)
            selected = self.entry.id
            panel.linked = nil
            Fill()
        end)
        row:SetScript("OnEnter", function(self) RecipeTooltip(self, self.entry) end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    row.entry = entry
    row.icon:SetTexture(RecipeIcon(entry.id))
    row.name:SetText(entry.name)
    row.prof:SetText(ns.Recipes:ProfessionName(entry.prof) or "")
    row.glow:SetShown(entry.id == selected)
end

-- Who knows it, in one line: "Kaz, alt of Alys" style. The one who answered is the character to
-- whisper; an alt of theirs that knows it is named.
local function KnowsLine(answer)
    local own, alts = false, {}
    for _, c in ipairs(answer.chars) do
        if c.alt then alts[#alts + 1] = c.name else own = true end
    end
    local parts = {}
    if own then parts[#parts + 1] = L["knows it"] end
    if #alts > 0 then
        parts[#parts + 1] = format(#alts == 1 and L["on their alt %s"] or L["on their alts %s"], table.concat(alts, ", "))
    end
    return table.concat(parts, ", ")
end

-- Where the one who answered is: the zone they share on the map (AllyMap.lua), else, for a
-- guildmate, the one the guild roster shows. Nil when neither says.
local function ZoneOf(name)
    local zone = ns.AllyMap and ns.AllyMap.ZoneOf and ns.AllyMap:ZoneOf(name)
    if zone then return zone end
    local member = ns.Guild:GetMember(name)
    return member and member.zone
end

local function InitAnswer(row, answer)
    local K = Kit()
    if not row.init then
        row.init = true
        K.RowBackground(row)
        row.name = K.NewLabel(row, "")
        row.name:SetPoint("TOPLEFT", 6, -4)
        row.badge = K.NewLabel(row, "", "GameFontHighlightSmall")
        row.badge:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
        row.info = K.NewLabel(row, "", "GameFontHighlightSmall")
        row.info:SetPoint("TOPLEFT", 6, -22)
        row.info:SetPoint("RIGHT", -96, 0)
        row.info:SetJustifyH("LEFT")
        row.info:SetWordWrap(false)
        row.whisper = K.NewButton(row, L["Whisper"], 86)
        row.whisper:SetPoint("RIGHT", -4, 0)
        row.whisper:SetScript("OnClick", function(self)
            local a = self:GetParent().answer
            if a and selected then Whisper(a.from, selected) end
        end)
    end
    row.answer = answer
    local zone = not answer.mine and ZoneOf(answer.from)
    row.name:SetText((answer.mine and ("|cff808080" .. L["You"] .. ":|r ") or "") .. "|cffffd100" .. answer.from .. "|r"
        .. (zone and ("  |cff808080" .. zone:gsub("|", "||") .. "|r") or ""))
    row.badge:SetText(answer.help and ("|cff20ff20" .. L["Available to help"] .. "|r") or "")
    local bits = { KnowsLine(answer) }
    for _, c in ipairs(answer.chars) do
        local left = c.readyAt and c.readyAt - GetTime()
        if left and left > 0 then
            bits[#bits + 1] = "|cffff9900" .. format(L["ready in %s"], Duration(left)) .. "|r"
            break
        end
    end
    row.info:SetText(table.concat(bits, "  ·  "))
    row.whisper:SetShown(not answer.mine)
end

-- The answers in order: mine first, then the ones available to help, then as they came.
local function SortedAnswers(q)
    local list = {}
    for i, key in ipairs(q.order) do
        local a = q.answers[key]
        if a then
            a.rank = (a.mine and 0 or a.help and 1 or 2) * 1000 + i
            list[#list + 1] = a
        end
    end
    table.sort(list, function(a, b) return a.rank < b.rank end)
    return list
end

-- Fill ------------------------------------------------------------------------------------------

local FillLive -- (below)

Fill = function()
    if not panel or not panel:IsShown() then return end
    local K, R = Kit(), ns.Recipes
    local p = panel

    -- Suggestions (only here: the live refresh every second leaves the list alone).
    local text = p.search:GetText() or ""
    local list
    if p.linked then
        list = {}
        for _, id in ipairs(p.linked) do list[#list + 1] = R:Get(id) end
    else
        list = R:Search(text, SUGGEST_MAX)
    end
    K.SetListData(p.suggestions, list)
    if not R:IsReady() then
        p.hint:SetText(L["The recipe list is being built: a few seconds after login."])
    elseif strtrim(text) == "" and not p.linked then
        p.hint:SetText(L["Type a recipe's name, or shift-click an item into the box."])
    elseif #list == 0 then
        p.hint:SetText(L["No recipe by that name."])
    else
        p.hint:SetText("")
    end

    FillLive()
end

-- What changes by itself: the recipe picked, the question, its answers, the options.
FillLive = function()
    if not panel or not panel:IsShown() then return end
    local K, R = Kit(), ns.Recipes
    local p = panel

    -- The recipe picked.
    local entry = selected and R:Get(selected)
    p.chosen:SetShown(entry ~= nil)
    p.pick:SetShown(entry == nil)
    if entry then
        p.chosenIcon:SetTexture(RecipeIcon(entry.id))
        p.chosenName:SetText(entry.name)
        p.chosenProf:SetText(R:ProfessionName(entry.prof) or "")
    end

    -- The question and its answers, when it's about the recipe picked.
    local q = R:GetQuestion()
    local mineAsked = q and entry and q.r == entry.id
    local now = GetTime()
    local wait = R:AskWait()
    p.ask:SetEnabled(entry ~= nil and R:IsReady() and wait <= 0)
    local answers = mineAsked and SortedAnswers(q) or {}
    K.SetListData(p.answers, answers)
    if not entry then
        p.status:SetText("")
    elseif not mineAsked then
        p.status:SetText(L["Search for who can make it: your guild and the allied guilds answer."])
    else
        local others = 0
        for _, a in ipairs(answers) do if not a.mine then others = others + 1 end end
        local ago = now - q.at
        if ago < SEARCHING_FOR then
            p.status:SetText(format(L["Searching... (%d answers)"], others))
        elseif #answers == 0 then
            p.status:SetText(L["Nobody online knows it, or nobody who can answer."])
        else
            p.status:SetText(format(L["%d answers, asked %s ago"], others,
                ago < 60 and format(L["%d s"], math.floor(ago)) or Duration(ago)))
        end
    end

    -- Options.
    p.share:SetChecked(R:IsSharing())
    p.help:SetChecked(R:IsHelping())
    p.help:SetEnabled(R:IsSharing())
end

-- Page ------------------------------------------------------------------------------------------

function ns.BuildProfessionsPanel()
    local K = Kit()
    local p = K.NewPanel()
    panel = p
    K.NewPageTitle(p, L["Professions"], { L["Professions"],
        L["Find who can make a recipe in your guild and the allied guilds."],
        L["Pick a recipe, then Search: every La Taverne whose character, or one of its alts, knows it answers by itself, in the background. Nothing is written in chat, and nothing is kept once you leave the page."],
        L["Your recipes are shared the same way: untick Share my recipes to stop answering."] })

    -- Left: search and suggestions.
    p.search = K.NewInput(p, 296, 60)
    p.search:SetPoint("TOPLEFT", 14, -46)
    K.SetPlaceholder(p.search, L["Recipe name, or shift-click an item"])
    p.search:SetScript("OnTextChanged", function(self, user)
        -- A link the game put in the box itself: kept as its plain name (a link can't be edited
        -- letter by letter).
        local text = self:GetText() or ""
        if text:find("|H", 1, true) then
            local plain = text:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            self:SetText(plain)
            self:SetCursorPosition(#plain)
            return
        end
        if user then
            p.linked = nil
            Fill()
        end
    end)
    p.search:HookScript("OnEditFocusGained", HookLinks)

    p.suggestions = K.NewScrollList(p, SUGGEST_H, InitSuggestion)
    p.suggestions:SetPoint("TOPLEFT", 8, -76)
    p.suggestions:SetSize(304, SUGGEST_H * 16)
    p.hint = K.NewLabel(p, "", "GameFontDisable")
    p.hint:SetPoint("TOPLEFT", p.suggestions, "TOPLEFT", 6, -6)
    p.hint:SetWidth(290)
    p.hint:SetJustifyH("LEFT")

    -- Right: the recipe picked, Search, the answers.
    local right = CreateFrame("Frame", nil, p)
    right:SetPoint("TOPLEFT", 336, -40)
    right:SetPoint("BOTTOMRIGHT", -4, 40)

    p.pick = K.NewLabel(right, L["Pick a recipe on the left."], "GameFontDisable")
    p.pick:SetPoint("TOPLEFT", 4, -12)

    p.chosen = CreateFrame("Frame", nil, right)
    p.chosen:SetPoint("TOPLEFT", 0, 0)
    p.chosen:SetPoint("RIGHT", 0, 0)
    p.chosen:SetHeight(44)
    p.chosen:EnableMouse(true)
    p.chosen:SetScript("OnEnter", function(self)
        local entry = selected and ns.Recipes:Get(selected)
        if entry then RecipeTooltip(self, entry) end
    end)
    p.chosen:SetScript("OnLeave", function() GameTooltip:Hide() end)
    p.chosenIcon = p.chosen:CreateTexture(nil, "ARTWORK")
    p.chosenIcon:SetSize(36, 36)
    p.chosenIcon:SetPoint("LEFT", 4, 0)
    p.chosenName = K.NewLabel(p.chosen, "", "GameFontNormalLarge")
    p.chosenName:SetPoint("TOPLEFT", p.chosenIcon, "TOPRIGHT", 8, -1)
    p.chosenName:SetPoint("RIGHT", -150, 0)
    p.chosenName:SetJustifyH("LEFT")
    p.chosenName:SetWordWrap(false)
    p.chosenProf = K.NewLabel(p.chosen, "", "GameFontHighlightSmall")
    p.chosenProf:SetPoint("BOTTOMLEFT", p.chosenIcon, "BOTTOMRIGHT", 8, 2)

    p.ask = K.NewButton(right, L["Search"], 140, 24)
    p.ask:SetPoint("TOPRIGHT", -4, -10)
    K.WithTooltip(p.ask, { L["Search"],
        L["Searches your guild and the allied guilds in the background: nothing is written in chat. Those whose characters know the recipe answer within a few seconds."],
        L["One search every 5 seconds."] })
    p.ask:SetScript("OnClick", function()
        if not selected then return end
        local ok, sent = ns.Recipes:Ask(selected)
        if ok and not sent then ns.Print(L["Nothing was sent: no guild or alliance channel is ready yet."]) end
        Fill()
    end)

    p.status = K.NewLabel(right, "", "GameFontHighlightSmall")
    p.status:SetPoint("TOPLEFT", 4, -52)
    p.status:SetPoint("RIGHT", -4, 0)
    p.status:SetJustifyH("LEFT")

    p.answers = K.NewScrollList(right, ANSWER_H, InitAnswer)
    p.answers:SetPoint("TOPLEFT", 0, -72)
    p.answers:SetPoint("BOTTOMRIGHT", -20, 0)

    -- Bottom: options.
    p.share = K.NewCheckbox(p, L["Share my recipes"], function(self)
        ns.Recipes:SetSharing(self:GetChecked())
        Fill()
    end)
    p.share:SetPoint("BOTTOMLEFT", 8, 4)
    K.WithTooltip(p.share, { L["Share my recipes"],
        L["When someone in your guild or an allied guild asks who can make a recipe, La Taverne answers for your characters that know it, your alts in the guild or an allied guild included."],
        L["Untick to stop answering."] })
    p.help = K.NewCheckbox(p, L["Available to help"], function(self)
        ns.Recipes:SetHelping(self:GetChecked())
        Fill()
    end)
    p.help:SetPoint("LEFT", p.share, "RIGHT", 220, 0)
    K.WithTooltip(p.help, { L["Available to help"],
        L["Your answers say you're happy to craft for others, and come first in their list."] })

    -- (The recipe list loaded, a question, an answer: the whole page, suggestions included.)
    ns.Recipes:OnChange(function() Fill() end)
    p.Refresh = Fill
    -- Live: "Searching...", the times, the Search button's 5 seconds.
    local wait = 0
    p:SetScript("OnUpdate", function(_, elapsed)
        wait = wait - elapsed
        if wait > 0 then return end
        wait = 1
        FillLive()
    end)
    -- Leaving the page forgets the question: its answers are for the page only.
    p:SetScript("OnHide", function() ns.Recipes:Forget() end)
    return p
end
