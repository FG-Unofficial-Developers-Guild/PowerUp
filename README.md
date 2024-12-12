
# Power Up

[![Build FG Extension](https://github.com/rhagelstrom/PowerUp/actions/workflows/create-release.yml/badge.svg)](https://github.com/rhagelstrom/PowerUp/actions/workflows/create-release.yml) [![Luacheckrc](https://github.com/rhagelstrom/PowerUp/actions/workflows/luacheck.yml/badge.svg)](https://github.com/rhagelstrom/PowerUp/actions/workflows/luacheck.yml) [![Markdownlint](https://github.com/rhagelstrom/PowerUp/actions/workflows/markdownlint.yml/badge.svg)](https://github.com/rhagelstrom/PowerUp/actions/workflows/markdownlint.yml)

**Current Version:** ~dev_version~
**Updated:** ~date~

Power Up is Fantasy Grounds extension that allows a user to see the name of extensions that have been updated since the last time the campaign was loaded. Power Up also allows for customization and control of the loading on player modules by the GM.

The slash command **/powerup** will show which extensions have been updated since the last time the campaign was loaded.

The slash command: **/powerupman** will show which extensions have been updated since the last time **/powerupman** was run on the host.

## Options

| Name| Default | Options | Notes |
|---|---|---|---|
|Chat: Post new extension versions on Load| off| off/on| When on, will post the results of /powerup to the chat window when the table is loaded (Scroll to the top).|
|Image: Default token lock| on | off/on | When off, images when shared will set the token lock to off.|
|Image: Share images not identified| off | off/on | When on, images shared will be set to not identified.|
|Modules: Client autoload player modules| off| off/on| When on, will autoload all player loadable modules on the client(s).|
|Modules: Client only load GM player modules| off| off/on| When on, will only allow loading of player modules specified by the GMs campaign.|
|Modules: Default all modules to not player loadable| off| off/on| When on all player modules will be set to not loadable. GM must enable explicitly.|

## Extension Devs

For PowerUp to process your extension correctly you need to have a version in your extension.xml file

`<version>X.Y</version>`

FG doesn't process micro versions so X.Y.Z the Z gets stripped off and it also doesn't like any characters, only numbers.

Alternatively, If you want to use your own version string you can register with PowerUp with the following code in your onInit function where "My Extension Name" and "My Extension Version" are both strings. You will need to have your own process of making sure "My Extension Version" is updated every time you update your extension. To use this method, your load order must be above 10

```lua
if PowerUp then
    if PowerUp.registerExtension("My Extension Name", "My Extension Version") == 0 then
        --successfully registered
    else
        --error registering
    end
end
```

```lua
function onInit()
    if PowerUp then
       PowerUp.registerExtension("My Extension Name", "My Extension Version", {
                {
                    ['link'] = "https://github.com/FG-Unofficial-Developers-Guild/",
                    ['message'] = "v0.9\nAdded registration code"
                },
                {
                    ['link'] = "https://fgapp.idea.informer.com/",
                    ['message'] = "Please vote for this on the idea informer wishlist",
                    ['icon'] = "shooting_star"
                },
            }
        )
    end
end
```
