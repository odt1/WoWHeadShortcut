local addonName, ns = ...

-- Global so Bindings.xml can reach it.
WoWHeadShortcut = ns

BINDING_HEADER_WOWHEADSHORTCUT = "WoWHeadShortcut"
BINDING_NAME_WOWHEADSHORTCUT_COPY = "Copy link to hovered item, spell or NPC"

local PREFIX = "|cff33ffcc[WoWHeadShortcut]|r "

local BINDING_ACTION = "WOWHEADSHORTCUT_COPY"
local DEFAULT_BINDING_KEY = "ALT-SHIFT-C"
-- Keys bound before the addon was renamed from CopyItemID still point at this action.
local LEGACY_BINDING_ACTION = "COPYITEMID_COPY"

-- Entries with a url are presets; the one without uses the custom base URL.
ns.sites = {
	{ key = "wowhead", label = "Wowhead (WotLK)", url = "https://www.wowhead.com/wotlk/" },
	{ key = "custom", label = "Custom" },
}

ns.defaults = {
	site = "wowhead",
	customUrl = "http://localhost/aowow/?",
	playSound = true,
	soundName = "igMainMenuContinue",
}

local TYPE_MAP = {
	item  = { slug = "item=", label = "Item" },
	spell = { slug = "spell=", label = "Spell" },
	npc   = { slug = "npc=", label = "NPC" },
}

local popupUrl

StaticPopupDialogs["WOWHEADSHORTCUT_URL"] = {
	text = "Copy the %s link with Ctrl+C:",
	button1 = CLOSE,
	hasEditBox = 1,
	hasWideEditBox = 1,
	maxLetters = 512,
	OnShow = function(self)
		-- self.editBox isn't reliably set on 3.3.5 popups, so look the box up by name.
		local editBox = _G[self:GetName() .. "WideEditBox"] or _G[self:GetName() .. "EditBox"]
		editBox:SetText(popupUrl or "")
		editBox:SetFocus()
		editBox:HighlightText()
	end,
	EditBoxOnEnterPressed = function(self)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end

local function GetHoveredEntity()
	-- 1. Check for Item
	local _, itemLink = GameTooltip:GetItem()
	if itemLink then
		local itemID = itemLink:match("item:(%d+)")
		if itemID then
			return itemID, "item"
		end
	end

	-- 2. Check for Spell
	local _, _, spellID = GameTooltip:GetSpell()
	if spellID then
		return spellID, "spell"
	end

	-- 3. Check for NPC / Creature / Vehicle
	local _, unit = GameTooltip:GetUnit()
	unit = unit or (UnitExists("mouseover") and "mouseover")
	if unit and not UnitIsPlayer(unit) then
		local guid = UnitGUID(unit)
		if guid then
			local npcID = tonumber(guid:sub(7, 12), 16)
			if npcID and npcID > 0 then
				return npcID, "npc"
			end
		end
	end

	return nil, nil
end

-- Binds the default key once per account, so a key the player later changes or
-- clears in Key Bindings stays that way.
local function ApplyDefaultBinding()
	if ns.db.defaultBindingApplied then
		return
	end
	ns.db.defaultBindingApplied = true

	if GetBindingKey(BINDING_ACTION) then
		return
	end

	local current = GetBindingAction(DEFAULT_BINDING_KEY)
	if not current or current == "" or current == LEGACY_BINDING_ACTION then
		SetBinding(DEFAULT_BINDING_KEY, BINDING_ACTION)
		SaveBindings(GetCurrentBindingSet())
	else
		Print(("Shift+Alt+C is already bound to %s. Pick a key under Key Bindings > WoWHeadShortcut."):format(current))
	end
end

function ns:GetSite(key)
	for _, site in ipairs(self.sites) do
		if site.key == key then
			return site
		end
	end
	return self.sites[1]
end

-- Returns nil when the custom site is selected but its URL is blank.
function ns:GetBaseUrl()
	local site = self:GetSite(self.db.site)
	if site.url then
		return site.url
	end
	local url = strtrim(self.db.customUrl or "")
	if url ~= "" then
		return url
	end
end

-- Checked on every copy, so it follows whether the running client has AwesomeWotLK.
function ns:HasClipboard()
	return type(CopyToClipboard) == "function"
end

-- Anything that looks like a path goes to PlaySoundFile; bare names go to PlaySound.
function ns:PlayNamedSound(name)
	name = strtrim(name or "")
	if name == "" then
		return
	end
	if name:find("[\\/.]") then
		PlaySoundFile(name, "Master")
	else
		PlaySound(name, "Master")
	end
end

function ns:CopyHovered()
	local id, entityType = GetHoveredEntity()
	local info = TYPE_MAP[entityType]
	if not (id and info) then
		Print("No valid Item, Spell, or NPC found under cursor.")
		return
	end

	local baseUrl = self:GetBaseUrl()
	if not baseUrl then
		Print("The custom base URL is empty. Set it with /copylink options.")
		return
	end

	local url = baseUrl .. info.slug .. id
	if self:HasClipboard() then
		CopyToClipboard(url)
		if self.db.playSound then
			self:PlayNamedSound(self.db.soundName)
		end
	else
		popupUrl = url
		StaticPopup_Show("WOWHEADSHORTCUT_URL", info.label)
	end
end

SLASH_WOWHEADSHORTCUT1 = "/copylink"
SlashCmdList["WOWHEADSHORTCUT"] = function(msg)
	local command = strtrim(msg or ""):lower()
	if command == "options" or command == "config" then
		ns:OpenOptions()
	else
		ns:CopyHovered()
	end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
-- Key bindings are only readable once VARIABLES_LOADED fires.
loader:RegisterEvent("VARIABLES_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
	if event == "ADDON_LOADED" then
		if name ~= addonName then
			return
		end
		self:UnregisterEvent("ADDON_LOADED")

		WoWHeadShortcutDB = WoWHeadShortcutDB or {}
		for key, value in pairs(ns.defaults) do
			if WoWHeadShortcutDB[key] == nil then
				WoWHeadShortcutDB[key] = value
			end
		end
		ns.db = WoWHeadShortcutDB

		ns:InitOptions()
	elseif event == "VARIABLES_LOADED" and ns.db then
		ApplyDefaultBinding()
	end
end)
