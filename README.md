# Power Up

**Current Version:** 1.4
**Updated::** 08/28/22

Power Up is Fantasy Grounds extension that allows a user to see the name of extensions that have been updated since the last time the campaign was loaded.

The slash command <b>/powerup</b> will show which extensions have been updated since the last time the campaign was loaded.

The slash command: <b>/powerupman</b> will show which extensions have been updated since the last time <b>/powerupman</b> was run on the host.
## Options

| Name| Default | Options | Notes | 
|---|---|---|---|---| 
|Game: Chat: Post New Extension Versions on Load| off| off/on| When on, will post the results of /powerup to the chat window when the table is loaded (Scroll to the top).| 

## Extension Devs:

For PowerUp to process your extension correctly you need to have a version in your extension.xml file

`<version>X.Y</version>`

FG doesn't process micro versions so X.Y.Z the Z gets stripped off and it also doesn't like any characters, only numbers.

Alternatively, If you want to use your own version string you can register with PowerUp with the following code in your onInit function where "My Extension Name" and "My Extension Version" are both strings. You will need to have your own process of making sure "My Extension Version" is updated every time you update your extension. To use this method, your load order must be above 10

```
if PowerUp then
	if PowerUp.registerExtension("My Extension Name", "My Extension Version") == 0 then
        --successfully registered
    else
        --error registering
    end
end
```
