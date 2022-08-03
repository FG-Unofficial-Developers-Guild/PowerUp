# Power Up

**Current Version:** 1.2
**Updated::** 08/03/22

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