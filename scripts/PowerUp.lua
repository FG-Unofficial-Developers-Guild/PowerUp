
--		Author: Ryan Hagelstrom
--		Copyright © 2022
--		This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--		https://creativecommons.org/licenses/by-sa/4.0/
--		luacheck: globals onDesktopInit onDesktopClose purgeOldData setupData powerUpLoad versionMessages saveExtensionData
--		luacheck: globals powerUpMan getPowerUp setPowerUp registerExtension getExtensions versionChangeNotification

local tExtensions = {}

function onInit()
	Comm.registerSlashHandler("powerup", powerUpLoad)
	Comm.registerSlashHandler("powerupman", powerUpMan)

	OptionsManager.registerOption2(
					'PU_AUTO_RUN', false, 'option_header_game', 'option_label_PU_AUTO_RUN', 'option_entry_cycler',
					{ labels = 'option_val_on', values = 'enabled', baselabel = 'option_val_off', baseval = 'disabled', default = 'disabled' }
	);

	if Session.IsHost then
		purgeOldData()
		setupData()
	end
	saveExtensionData()
	if OptionsManager.isOption("PU_AUTO_RUN", "enabled") then
		Interface.onDesktopInit = powerUpLoad
	end
	Interface.onDesktopClose = onDesktopClose
end

function onDesktopClose()
	setPowerUp(DB.findNode("PowerUp.onload"))
end

-- if using old (<= v1.1) data structure, restructure it
-- this can eventually be removed, but should be left in place
-- for some time as users upgrade from early versions
function purgeOldData()
	local nodePowerUp = DB.findNode("PowerUp")
	if nodePowerUp and not nodePowerUp.getChild("onload") then
		local nodeTmp = DB.copyNode(nodePowerUp, DB.createNode("PowerUpTmp"))
		if nodeTmp then
			nodePowerUp.delete()
			nodePowerUp = setupData()
			if DB.copyNode(nodeTmp, nodePowerUp.getChild('onload')) then
				nodeTmp.delete()
			end
		end
	end
end

-- create data structure for saving extension version data
function setupData()
	local nodePowerUp = DB.createNode("PowerUp")
	if not nodePowerUp.getChild("onload") then
		nodePowerUp.createChild("onload")
		setPowerUp(nodePowerUp.getChild("onload"))
	end
	if not nodePowerUp.getChild("manual") then
		nodePowerUp.createChild("manual")
		setPowerUp(nodePowerUp.getChild("manual"))
	end
	return nodePowerUp
end

function saveExtensionData()
	for _,sName in pairs(Extension.getExtensions()) do
		local tInfo = Extension.getExtensionInfo(sName)
		registerExtension(tInfo.name, tInfo.version)
	end
end

--Used to allow extensions to register themself with whatever version string they want
-- since FG only accepts X.Y format
function registerExtension(sExtension, sVersion, tMessages)
	local nRet = 1
	if type(sExtension) == "string" and type(sVersion) == "string" and sExtension ~= "" and sVersion ~= "" then
		if not tExtensions[sExtension] then tExtensions[sExtension] = {}; end
		tExtensions[sExtension]['version'] = sVersion
		tExtensions[sExtension]['messages'] = tMessages
		nRet = 0
	end
	return nRet
end

--Get the extension table
function getExtensions()
	return tExtensions
end

-- check for new or modified extension versions and post chat messages
function versionChangeNotification(nodeDB, rMessage, sName, tData)
	sName = sName:gsub("%(.*%)", "")
	local sOldVersion = DB.getValue(nodeDB, UtilityManager.encodeXML(sName):gsub("%s","_"):gsub(":",""), "")
	if sOldVersion == "" then
		rMessage.text = sName .. " new to campaign"
		rMessage.bNoUpdates = false
		Comm.addChatMessage(rMessage)
	elseif tData['version'] ~= sOldVersion then
		rMessage.text = sName .. " Previous: " .. sOldVersion .. " Current: ".. tData['version']
		rMessage.bNoUpdates = false
		Comm.addChatMessage(rMessage)
	end
end

-- post update messages with links when found
function versionMessages(rMessage, tMessages)
	if not tMessages then return; end
	for _, msg in pairs(tMessages) do
		rMessage.icon = "PowerUpChat"
		if msg['icon'] then rMessage.icon = msg['icon']; end

		rMessage.text = ""
		if msg['message'] then rMessage.text = rMessage.text .. msg['message']; end
		if rMessage.text ~= "" and msg['link'] then rMessage.text = rMessage.text .. '\n'; end
		if msg['link'] then rMessage.text = rMessage.text .. msg['link']; end

		if rMessage.text ~= "" then Comm.addChatMessage(rMessage); end
	end
end

-- loop through extensions and call messaging functions
function getPowerUp(nodeDB)
	local rMessage = { font = "systemfont", icon = "PowerUpChat", bNoUpdates = true }
	if nodeDB then
		for sName, tData in pairs(tExtensions) do
			versionChangeNotification(nodeDB, rMessage, sName, tData)

			versionMessages(rMessage, tData['messages'])
		end
	end
	if rMessage.bNoUpdates then
		rMessage.text = "No extension updates detected"
		Comm.addChatMessage(rMessage)
	end
end

-- save list of current extension versions to database
function setPowerUp(nodeDB)
	if Session.IsHost then
		if nodeDB then
			for sName, tData in pairs(tExtensions) do
				sName = sName:gsub("%(.*%)", "")
				DB.setValue(nodeDB, UtilityManager.encodeXML(sName):gsub("%s","_"):gsub(":",""), "string", tData['version'])
			end
		end
	end
end

-- check for updates since last load
-- called from /powerup command or automatically on load (when option is enabled)
function powerUpLoad()
	getPowerUp(DB.findNode("PowerUp.onload"))
end

-- check for updates since command was last run
-- called from /powerup_man command
function powerUpMan()
	local nodePUMan = DB.findNode("PowerUp.manual")
	getPowerUp(nodePUMan)
	setPowerUp(nodePUMan)
end
