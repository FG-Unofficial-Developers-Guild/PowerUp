
--		Author: Ryan Hagelstrom
--		Copyright © 2022
--		This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--		https://creativecommons.org/licenses/by-sa/4.0/
--		luacheck: globals onDesktopInit onDesktopClose purgeOldData setupData powerUpLoad powerUpMan getPowerUp setPowerUp registerExtension

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
	for _,sName in pairs(Extension.getExtensions()) do
		local tInfo = Extension.getExtensionInfo(sName)
		tExtensions[tInfo.name] = tInfo.version
	end
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

--Used to allow extensions to register themself with whatever version string they want
-- since FG only accepts X.Y format
function registerExtension(sExtension, sVersion)
	local nRet = 1
	if type(sExtension) == "string" and type(sVersion) == "string" and sExtension ~= "" and sVersion ~= "" then
		tExtensions[sExtension] = sVersion
		nRet = 0
	end
	return nRet
end

--Get the extension table
function getExtensions()
	return tExtensions
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

-- check for new or modified extension versions
function getPowerUp(nodeDB)
	local rMessage = { font = "systemfont", icon = "PowerUpChat", bNoUpdates = true }
	if nodeDB then
		for sName, sVersion in pairs(tExtensions) do
			sName = sName:gsub("%(.*%)", "")
			local sOldVersion = DB.getValue(nodeDB, UtilityManager.encodeXML(sName):gsub("%s","_"):gsub(":",""), "")
			if sOldVersion == "" then
				rMessage.text = sName .. " new to campaign"
				rMessage.bNoUpdates = false
				Comm.addChatMessage(rMessage)
			elseif sVersion ~= sOldVersion then
				rMessage.text = sName .. " Previous: " .. sOldVersion .. " Current: ".. sVersion
				rMessage.bNoUpdates = false
				Comm.addChatMessage(rMessage)
			end
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
			for sName, sVersion in pairs(tExtensions) do
				sName = sName:gsub("%(.*%)", "")
				DB.setValue(nodeDB, UtilityManager.encodeXML(sName):gsub("%s","_"):gsub(":",""), "string", sVersion)
			end
		end
	end
end