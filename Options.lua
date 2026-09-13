local addonName, ns = ...

local EXAMPLE_ITEM_ID = 19019

local function CreateLabel(parent, text, font)
	local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
	label:SetJustifyH("LEFT")
	label:SetText(text)
	return label
end

local function CreateEditBox(name, parent, width)
	local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
	box:SetAutoFocus(false)
	box:SetWidth(width)
	box:SetHeight(20)
	box:SetMaxLetters(512)
	box:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	box:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	return box
end

-- Called from ADDON_LOADED once ns.db exists. UIDropDownMenu_Initialize runs the
-- menu builder straight away, so the panel can't be built at file load.
function ns:InitOptions()
	local db = self.db

	local panel = CreateFrame("Frame", "WoWHeadShortcutOptionsPanel", InterfaceOptionsFramePanelContainer)
	panel.name = addonName
	panel:Hide()

	local title = CreateLabel(panel, addonName, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)

	local intro = CreateLabel(panel, "Copies a link to the item, spell or NPC under the cursor. Press Shift+Alt+C (change it under Key Bindings > WoWHeadShortcut), or run /copylink.", "GameFontHighlightSmall")
	intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	intro:SetPoint("RIGHT", -32, 0)
	intro:SetHeight(32)
	intro:SetJustifyV("TOP")
	intro:SetNonSpaceWrap(true)

	-- Link site

	local siteLabel = CreateLabel(panel, "Link site")
	siteLabel:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -8)

	-- Dropdown and check button templates find their child regions by global name.
	local siteDropDown = CreateFrame("Frame", "WoWHeadShortcutSiteDropDown", panel, "UIDropDownMenuTemplate")
	siteDropDown:SetPoint("TOPLEFT", siteLabel, "BOTTOMLEFT", -16, -4)
	UIDropDownMenu_SetWidth(siteDropDown, 160)

	local urlLabel = CreateLabel(panel, "Custom base URL", "GameFontHighlight")
	urlLabel:SetPoint("TOPLEFT", siteDropDown, "BOTTOMLEFT", 16, -8)

	local urlBox = CreateEditBox("WoWHeadShortcutCustomUrlBox", panel, 400)
	urlBox:SetPoint("TOPLEFT", urlLabel, "BOTTOMLEFT", 6, -4)

	local preview = CreateLabel(panel, "", "GameFontHighlightSmall")
	preview:SetPoint("TOPLEFT", urlBox, "BOTTOMLEFT", -6, -6)

	-- Copy method

	local methodLabel = CreateLabel(panel, "Copy method")
	methodLabel:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -20)

	local methodText = CreateLabel(panel, "", "GameFontHighlightSmall")
	methodText:SetPoint("TOPLEFT", methodLabel, "BOTTOMLEFT", 0, -6)

	-- Sound

	local soundLabel = CreateLabel(panel, "Sound")
	soundLabel:SetPoint("TOPLEFT", methodText, "BOTTOMLEFT", 0, -20)

	local soundCheck = CreateFrame("CheckButton", "WoWHeadShortcutSoundCheck", panel, "OptionsCheckButtonTemplate")
	soundCheck:SetPoint("TOPLEFT", soundLabel, "BOTTOMLEFT", -2, -4)
	_G[soundCheck:GetName() .. "Text"]:SetText("Play a sound after copying to the clipboard")

	local soundBox = CreateEditBox("WoWHeadShortcutSoundBox", panel, 280)
	soundBox:SetPoint("TOPLEFT", soundCheck, "BOTTOMLEFT", 8, -4)

	local testButton = CreateFrame("Button", "WoWHeadShortcutSoundTestButton", panel, "UIPanelButtonTemplate")
	testButton:SetWidth(60)
	testButton:SetHeight(22)
	testButton:SetText("Test")
	testButton:SetPoint("LEFT", soundBox, "RIGHT", 8, 0)

	local soundHelp = CreateLabel(panel, "A sound name such as igMainMenuContinue, or the path to a sound file.", "GameFontHighlightSmall")
	soundHelp:SetPoint("TOPLEFT", soundBox, "BOTTOMLEFT", -6, -6)

	-- Updates everything derived from db without touching the edit box text,
	-- because the edit boxes call this from OnTextChanged.
	local function UpdateState()
		local isCustom = ns:GetSite(db.site).url == nil
		urlLabel:SetAlpha(isCustom and 1 or 0.5)
		urlBox:SetAlpha(isCustom and 1 or 0.5)
		urlBox:EnableMouse(isCustom)
		if not isCustom then
			urlBox:ClearFocus()
		end

		local baseUrl = ns:GetBaseUrl()
		if baseUrl then
			preview:SetText("Example: " .. baseUrl .. "item=" .. EXAMPLE_ITEM_ID)
		else
			preview:SetText("|cffff2020Enter a base URL to use a custom site.|r")
		end

		if ns:HasClipboard() then
			methodText:SetText("|cff20ff20AwesomeWotLK found.|r Links go straight to the clipboard.")
		else
			methodText:SetText("|cffff8020AwesomeWotLK not found.|r Links open in a popup where you copy them with Ctrl+C.")
		end
	end

	local function Refresh()
		local site = ns:GetSite(db.site)
		UIDropDownMenu_SetSelectedValue(siteDropDown, site.key)
		UIDropDownMenu_SetText(siteDropDown, site.label)
		urlBox:SetText(db.customUrl or "")
		soundCheck:SetChecked(db.playSound and 1 or nil)
		soundBox:SetText(db.soundName or "")
		UpdateState()
	end

	-- 3.3.5 passes different arguments to the builder than later clients; it uses none of them.
	UIDropDownMenu_Initialize(siteDropDown, function()
		for _, site in ipairs(ns.sites) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = site.label
			info.value = site.key
			info.checked = db.site == site.key
			info.func = function()
				db.site = site.key
				UIDropDownMenu_SetSelectedValue(siteDropDown, site.key)
				UIDropDownMenu_SetText(siteDropDown, site.label)
				UpdateState()
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	urlBox:SetScript("OnTextChanged", function(self)
		db.customUrl = self:GetText()
		UpdateState()
	end)

	soundCheck:SetScript("OnClick", function(self)
		db.playSound = self:GetChecked() and true or false
		PlaySound(db.playSound and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
	end)

	soundBox:SetScript("OnTextChanged", function(self)
		db.soundName = self:GetText()
	end)

	testButton:SetScript("OnClick", function()
		ns:PlayNamedSound(db.soundName)
	end)

	-- Changes save as they are made, so Okay and Cancel have nothing to do.
	panel.okay = function() end
	panel.cancel = function() end
	panel.default = function()
		for key, value in pairs(ns.defaults) do
			db[key] = value
		end
		Refresh()
	end
	panel.refresh = Refresh
	panel:SetScript("OnShow", Refresh)

	InterfaceOptions_AddCategory(panel)
	self.optionsPanel = panel
end

function ns:OpenOptions()
	InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
end
