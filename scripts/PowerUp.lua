--		Author: Ryan Hagelstrom
--		Copyright © 2022
--		This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--		https://creativecommons.org/licenses/by-sa/4.0/
-- luacheck: globals onInit onClose customOnDesktopInit customOnDesktopClose customOnModuleUpdated customOnModuleAdded purgeOldData
-- luacheck: globals setupData saveExtensionData registerExtension getExtensions versionChangeNotification versionMessages getPowerUp
-- luacheck: globals setPowerUp powerUpMan forceLoad forceLoadModule defaultModulesDisabled
local onModuleAdded = nil;
local onModuleUpdated = nil;
local onDesktopClose = nil;
local onDesktopInit = nil;
local tExtensions = {};

function onInit()
    Comm.registerSlashHandler('powerup', customOnDesktopInit);
    Comm.registerSlashHandler('powerupman', powerUpMan);
    onDesktopInit = Interface.onDesktopInit;

    OptionsManager.registerOption2('PU_AUTO_RUN', false, 'option_PowerUp', 'option_label_PU_AUTO_RUN', 'option_entry_cycler', {
        labels = 'option_val_on',
        values = 'enabled',
        baselabel = 'option_val_off',
        baseval = 'disabled',
        default = 'disabled'
    });
    OptionsManager.registerOption2('PU_NO_EXTA', false, 'option_PowerUp', 'option_label_PU_NO_EXTRA', 'option_entry_cycler', {
        labels = 'option_val_on',
        values = 'enabled',
        baselabel = 'option_val_off',
        baseval = 'disabled',
        default = 'disabled'
    });
    OptionsManager.registerOption2('PU_FORCE_LOAD', false, 'option_PowerUp', 'option_label_PU_FORCE_LOAD', 'option_entry_cycler',
                                   {
        labels = 'option_val_on',
        values = 'enabled',
        baselabel = 'option_val_off',
        baseval = 'disabled',
        default = 'disabled'
    });
    OptionsManager.registerOption2('PU_DISABLE_LOAD', false, 'option_PowerUp', 'option_label_PU_DISABLE_LOAD', 'option_entry_cycler',
                                   {
        labels = 'option_val_on',
        values = 'on',
        baselabel = 'option_val_off',
        baseval = 'off',
        default = 'off'
    });

    onModuleAdded = Module.onModuleAdded;
    Module.onModuleAdded = customOnModuleAdded;
    if Session.IsHost then
        purgeOldData();
        setupData();
        OptionsManager.registerCallback('PU_DISABLE_LOAD', defaultModulesDisabled);
        defaultModulesDisabled();
    else
        onModuleUpdated = Module.onModuleUpdated;
        Module.onModuleUpdated = customOnModuleUpdated;
        OptionsManager.registerCallback('PU_FORCE_LOAD', forceLoad);
        if OptionsManager.isOption('PU_FORCE_LOAD', 'enabled') then
            forceLoad();
        end
    end

    saveExtensionData()
    if OptionsManager.isOption('PU_AUTO_RUN', 'enabled') then
        Interface.onDesktopInit = customOnDesktopInit;
    end
    onDesktopClose = Interface.onDesktopClose;
    Interface.onDesktopClose = customOnDesktopClose;
end

function onClose()
    Module.onModuleAdded = onModuleAdded;
    if not Session.IsHost then
        OptionsManager.unregisterCallback('PU_FORCE_LOAD', forceLoad);
        Module.onModuleUpdated = onModuleUpdated;
    end
    Interface.onDesktopInit = onDesktopInit;
    Interface.onDesktopClose = onDesktopClose;
    Module.onModuleUpdated = onModuleUpdated;
end

-- check for updates since last load
-- called from /powerup command or automatically on load (when option is enabled)
function customOnDesktopInit()
    getPowerUp(DB.findNode('PowerUp.onload'));
    if onDesktopInit then
        onDesktopInit();
    end
end

function customOnDesktopClose()
    setPowerUp(DB.findNode('PowerUp.onload'));
    if (onDesktopClose) then
        onDesktopClose();
    end
end

function customOnModuleUpdated(sName)
    if OptionsManager.isOption('PU_FORCE_LOAD', 'enabled') then
        forceLoadModule(sName);
    end
    if onModuleUpdated then
        onModuleUpdated(sName);
    end
end

function customOnModuleAdded(sName)
    if Session.IsHost and OptionsManager.isOption('PU_NO_EXTA', 'enabled') then
        Module.setModulePermissions(sName, false);
    end
    if not Session.IsHost and OptionsManager.isOption('PU_FORCE_LOAD', 'enabled') then
        forceLoadModule(sName);
    end
    if (onModuleAdded) then
        onModuleAdded(sName);
    end
end

-- if using old (<= v1.1) data structure, restructure it
-- this can eventually be removed, but should be left in place
-- for some time as users upgrade from early versions
function purgeOldData()
    local nodePowerUp = DB.findNode('PowerUp');
    if nodePowerUp and not DB.getChild(nodePowerUp, 'onload') then
        local nodeTmp = DB.copyNode(nodePowerUp, DB.createNode('PowerUpTmp'));
        if nodeTmp then
            DB.deleteNode(nodePowerUp);
            nodePowerUp = setupData();
            if DB.copyNode(nodeTmp, DB.getChild(nodePowerUp, 'onload')) then
                DB.deleteNode(nodeTmp);
            end
        end
    end
end

-- create data structure for saving extension version data
function setupData()
    local nodePowerUp = DB.createNode('PowerUp');
    if not DB.getChild(nodePowerUp, 'onload') then
        DB.createChild(nodePowerUp, 'onload');
        setPowerUp(DB.getChild(nodePowerUp, 'onload'));
    end
    if not DB.getChild(nodePowerUp, 'manual') then
        DB.createChild(nodePowerUp,'manual');
        setPowerUp(DB.getChild(nodePowerUp, 'manual'));
    end
    return nodePowerUp
end

function saveExtensionData()
    for _, sName in pairs(Extension.getExtensions()) do
        local tInfo = Extension.getExtensionInfo(sName);
        registerExtension(tInfo.name, tInfo.version);
    end
end

-- Used to allow extensions to register themself with whatever version string they want
-- since FG only accepts X.Y format
function registerExtension(sExtension, sVersion, tMessages)
    local nRet = 1;
    if type(sExtension) == 'string' and type(sVersion) == 'string' and sExtension ~= '' and sVersion ~= '' then
        if not tExtensions[sExtension] then
            tExtensions[sExtension] = {};
        end
        tExtensions[sExtension]['version'] = sVersion;
        tExtensions[sExtension]['messages'] = tMessages;
        nRet = 0;
    end
    return nRet;
end

-- Get the extension table
function getExtensions()
    return tExtensions;
end

-- check for new or modified extension versions and post chat messages
function versionChangeNotification(nodeDB, rMessage, sName, tData)
    sName = sName:gsub('%(.*%)', '');
    local sOldVersion = DB.getValue(nodeDB, UtilityManager.encodeXML(sName):gsub('%s', '_'):gsub(':', ''), '');
    if sOldVersion == '' then
        rMessage.text = sName .. ' new to campaign';
        rMessage.bNoUpdates = false;
        Comm.addChatMessage(rMessage);
    elseif tData['version'] ~= sOldVersion then
        rMessage.text = sName .. ' Previous: ' .. sOldVersion .. ' Current: ' .. tData['version'];
        rMessage.bNoUpdates = false;
        Comm.addChatMessage(rMessage);
    end
end

-- post update messages with links when found
function versionMessages(rMessage, tMessages)
    if not tMessages then
        return;
    end
    for _, msg in pairs(tMessages) do
        rMessage.icon = 'PowerUpChat';
        if msg['icon'] then
            rMessage.icon = msg['icon'];
        end

        rMessage.text = '';
        if msg['message'] then
            rMessage.text = rMessage.text .. msg['message'];
        end
        if rMessage.text ~= '' and msg['link'] then
            rMessage.text = rMessage.text .. '\n';
        end
        if msg['link'] then
            rMessage.text = rMessage.text .. msg['link'];
        end

        if rMessage.text ~= '' then
            Comm.addChatMessage(rMessage);
        end
    end
end

-- loop through extensions and call messaging functions
function getPowerUp(nodeDB)
    local rMessage = {font = 'systemfont', icon = 'PowerUpChat', bNoUpdates = true};
    if nodeDB then
        for sName, tData in pairs(tExtensions) do
            versionChangeNotification(nodeDB, rMessage, sName, tData);

            versionMessages(rMessage, tData['messages']);
        end
    end
    if rMessage.bNoUpdates then
        rMessage.icon = 'PowerUpChat';
        rMessage.text = 'No extension updates detected';
        Comm.addChatMessage(rMessage);
    end
end

-- save list of current extension versions to database
function setPowerUp(nodeDB)
    if Session.IsHost then
        if nodeDB then
            for sName, tData in pairs(tExtensions) do
                sName = sName:gsub('%(.*%)', '');
                DB.setValue(nodeDB, UtilityManager.encodeXML(sName):gsub('%s', '_'):gsub(':', ''), 'string', tData['version']);
            end
        end
    end
end

-- check for updates since command was last run
-- called from /powerup_man command
function powerUpMan()
    local nodePUMan = DB.findNode('PowerUp.manual');
    getPowerUp(nodePUMan);
    setPowerUp(nodePUMan);
end

function forceLoad()
    local tModules = Module.getModules();
    for _, sName in pairs(tModules) do
        forceLoadModule(sName);
    end
end

function forceLoadModule(sName)
    local tModule = Module.getModuleInfo(sName);
    if not tModule then
        return;
    end
    if tModule.permission == 'allow' and not tModule.loaded then
        Module.activate(sName);
    elseif tModule.permission == 'deny' and tModule.loaded then
        Module.deactivate(sName);
    end
end

function defaultModulesDisabled()
    if OptionsManager.isOption('PU_DISABLE_LOAD', 'on') then
        local nodePowerUp = DB.findNode('PowerUp');
        local tModules = Module.getModules();
        if not DB.getChild(nodePowerUp, 'module') then
            DB.createChild(nodePowerUp, 'module');
        end

        for _, sModule in ipairs(tModules) do
            if not DB.getChild(nodePowerUp, 'module.' .. sModule) then
                DB.createChild(nodePowerUp, 'module.' .. sModule);
                Module.setModulePermissions(sModule, false);
            end
        end
    end
end
