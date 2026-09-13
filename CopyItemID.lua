local WOWHEAD_BASE = "https://www.wowhead.com/wotlk/"
-- local WOWHEAD_BASE = "http://localhost/aowow/?"

local TYPE_MAP = {
	item  = { slug = "item=", label = "Item" },
	spell = { slug = "spell=", label = "Spell" },
	npc   = { slug = "npc=", label = "NPC" },
}

StaticPopupDialogs["COPY_HOVERED_ID"] = {
	text = "Copy %s Wowhead Link:",
	button1 = "Close",
	hasEditBox = true,
	editBoxWidth = 320,   -- Increased width for longer URLs
	OnShow = function(self)
		self.editBox:SetText(self.data or "")
		self.editBox:HighlightText()
		self.editBox:SetFocus()
	end,
	EditBoxOnEnterPressed = function(self)
		StaticPopup_Hide("COPY_HOVERED_ID")
	end,
	EditBoxOnEscapePressed = function(self)
		StaticPopup_Hide("COPY_HOVERED_ID")
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

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

SLASH_COPYITEMID1 = "/copyitem"
SlashCmdList["COPYITEMID"] = function()
	local id, entityType = GetHoveredEntity()
	if id and TYPE_MAP[entityType] then
		local info = TYPE_MAP[entityType]
		local fullUrl = WOWHEAD_BASE .. info.slug .. id

		-- Arg 2 formats 'text' (%s), Arg 4 passes fullUrl to 'self.data'
		-- StaticPopup_Show("COPY_HOVERED_ID", info.label, nil, fullUrl)
		CopyToClipboard(fullUrl)
		PlaySound("igMainMenuContinue", "master");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc[CopyID]|r No valid Item, Spell, or NPC found under cursor.")
	end
end
