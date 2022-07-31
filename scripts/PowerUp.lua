
--  	Author: Ryan Hagelstrom
--	  	Copyright © 2022
--	  	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--	  	https://creativecommons.org/licenses/by-sa/4.0/

local tExtensions = {}

function onInit()
	Comm.registerSlashHandler("powerup", powerUp);
	if  Session.IsHost then
		DB.createNode("PowerUp");
	end
	for _,sName in pairs(Extension.getExtensions()) do
		local tInfo = Extension.getExtensionInfo(sName)
		tExtensions[tInfo.name] = tInfo.version
   	end
end

function onClose()
	if  Session.IsHost then
		local nodeDB  = DB.findNode("PowerUp");
		if nodeDB then
			for sName, sVersion in pairs(tExtensions) do
				DB.setValue(nodeDB, UtilityManager.encodeXML(sName):gsub("%s","_"):gsub(":",""), "string", sVersion)
			end
		end
	end
end

function powerUp()
	local bNoUpdates = true
	local sMessage = {font = "systemfont"};
	sMessage.icon = "PowerUpChat"
	local nodeDB  = DB.findNode("PowerUp");
	if nodeDB then
		for sName, sVersion in pairs(tExtensions) do
			local sOldVersion = DB.getValue(nodeDB, UtilityManager.encodeXML(sName):gsub("%s","_"):gsub(":",""), '')
			if sOldVersion == '' then
				sMessage.text = sName .. " new to campaign";
				Comm.addChatMessage(sMessage);
				bNoUpdates = false;
			elseif sVersion ~= sOldVersion then
				sMessage.text = sName .. " Previous: " .. sOldVersion .. " Current: ".. sVersion;
				Comm.addChatMessage(sMessage);
				bNoUpdates = false;
			end
		end
	end
	if bNoUpdates then
		sMessage.text = "No extension updates detected";
		Comm.addChatMessage(sMessage);
	end
end