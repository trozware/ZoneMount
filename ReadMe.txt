Zone Mount add-on for World of Warcraft
====================================

Zone Mount provides a way to summon a suitable mount, preferably one from the zone or region you are in.

You may have collected a lot of mounts, but if you never remember to use them, you are missing out on some fun content. Maybe you always use a mount from among the same few, or maybe a mount just doesn't fit in with where you are.

Zone Mount checks all your mounts and tries to summon a mount that is native to your current zone. If you have no mounts or only a few mounts from the zone, you may see a random mount instead.

If you want to summon a particular mount, Zone Mount can search your mounts for a mount matching the name you enter.

Read the mount's name and description in the Chat. These descriptions can be very funny - yet another way we are missing out on some good content.

Usage:
=====

Use the Slash Commands listed below to operate Zone Mount or enter '/zm' in the Chat window to see a list of these commands.

Type '/zm macro' in the Chat to create a macro and stick its button to your mouse so you can place it into your action bar. This is the best way to use Zone Mount. The macro button will mount or dismount, but unlike Blizzard's "Summon Favorite Mount" button, it will not dismount you from a flying mount when you are hundreds of feet in the air! If it is not possible to mount at a particular time, the Chat will show you the reason for this.

If you really do want to plummet out of the sky, click the macro button twice inside 2 seconds.

Use Game Menu > Options > AddOns > ZoneMount to set whether and how often you want the mount info to appear in the chat, to make **Zone Mount** choose from your favorite mounts only, to set the modifier keys for skyriding and ground mounts and to configure other options.

To ignore specific mounts, go to Game Menu > Options > AddOns > ZoneMount. Type a name or partial name into the ignore field and press Return/Enter to add it to the list. If the entry is already in the list, it will be removed, or you can click the button to clear the entire list. This will block any mounts with names containing the entered text, case does not matter e.g. entering "gryphon" will block all mount names that include the text "gryphon" which covers "Ebon Gryphon" and "Snowy Gryphon" as well as many others.


Slash Commands:
==============

- /zm mount - mount or dismount.
- /zm about - show info about your current mount.
- /zm __name__ - search for a mount by name (searching is case-insensitive and will find partial matches).
- /zm macro - create a macro for easy use of Zone Mount.  
- /zm do - make your mount do its special action if it is on the ground.

Version History:
===============

v 2.3.0: Updated for 12.0.
v 2.2.4: Updated for 11.2.5 and Legion Remix.
v 2.2.3: Summons ground mounts for phase diving in K'aresh.
v 2.2.2: ZoneMount now summons a mount when you can fly inside Manaforge Omega.
v 2.2.1: Added option to disable flight safety (thanks to @LuckyPhilDev for the PR).
v 2.2.0: Added /zm ra command to summon a ride along mount or /zm macro2 to create a macro for it.
v 2.1.1: updated for 11.1.5 & fixed bug where ground mounts were summoned in some areas.
v 2.1.0: Will try to use the G-99 Breakneck in Undermine.
v 2.0.6: Updated for 11.0.1.
v 2.0.5: Fixed Lua error when no purchased or event mounts are found.
v 2.0.4: Stopped random "t" from appearing in the chat log.
v 2.0.3: Added option to reset all settings to the defaults, and fixed modifier conflicts.
v 2.0.2: Set default modifiers to Shift for flight mode and Alt for ground mounts.
v 2.0.1: Added option to choose modifier to summon a ground mount.
v 2.0.0: Updated for 11.0.7. Added option to choose modifiers keys for steady flight/skyriding toggle. Added option to turn off choosing non-zone mounts if you only have one for the zone.
v 1.8.3: Updated for 11.0.5.v 1.8.3: Updated for 11.0.5.
v 1.8.2: Fix for possible error when editing macro.
v 1.8.1: Merge PR, update ReadMe.
v 1.8.0: Mounting in the Dawnbreaker now works correctly. Better summoning in zones without secondary names and for dragon type mounts. Ignore list in Options.
v 1.7.2: Should allow mounting with Radiant Light in The Dawnbreaker dungeon.
v 1.7.1: Allows for War Within Pathfinder, /zm about working again.
v 1.7.0: Updated for The War Within. Better detection for skyriding ability.
v 1.6.3: Fix for remix bug.
v 1.6.2: Updated to fix errors with 11.0.2.
v 1.6.1: Allows for skyriding at level 10. Shift-click ZoneMount macro for ground mount if less than 30.
v 1.6.0: Update for 11.0 with skyriding.
v 1.5.1: Attempt to fix a reported bug.
v 1.5.0: Allows for dragon riding in Pandaria Remix. Shift-click ZoneMount macro for normal flyer.
v 1.4.2: Updated for 10.2.7.
v 1.4.1: Updated for 10.2.6.
v 1.4.0: Updated for 10.2.5. Use modifier key to toggle dragonriding mounts in and out of Dragon Isles.
v 1.3.2: Summons ground mounts in Millennia's Threshold.
v 1.3.1: Fix for not assigning zones to some flying mounts.
v 1.3.0: Allow for dragon flying in Emerald Dream. If you want to use a standard flying mount in Dragon Isles, summon it manually.
v 1.2.11: Updated for 10.2.0.
v 1.2.10: Updated for 10.1.7.
v 1.2.9: Updated for 10.1.5. Better water handling in Vashj'ir and Dragon Isles.
v 1.2.8: Allows for flying in Zaralek Cavern.
v 1.2.7: Updated for 10.1.0.
v 1.2.6: Updated for 10.0.7.
v 1.2.5: Added an option to show info in chat log less often.
v 1.2.4: Bug fix.
v 1.2.3: Fix for dragonriding mounts in Valdrakken. Updated for 10.0.5.
v 1.2.2: Supports dragonriding mounts in more areas of the Dragon Isles.
v 1.2.1: Summons dragonriding mounts in Dragon Isles.
v 1.1.7: Updated for 10.0.2.
v 1.1.6: Updated for 10.0. Will not summon slow Unsuccessful Prototype Fleetpod.
v 1.1.5: Better search. Will not summon slow Riding Turtle.
v 1.1.4: Updated for Patch 9.2.0.
v 1.1.3: Special mounts summoned more often, added option to turn off warnings in chat.
v 1.1.2: Updated for Patch 9.1.5.
v 1.1.1: Added /zm do command to perform special action (only works on the ground), fixed interface options bug.
v 1.1.0: Fix for riding now available in The Maw for all mounts. Added options to hide mount info in chat and to use favorites only. Set using Game Menu > Interface > AddOns > ZoneMount.
v 1.0.10: Included Bound Shadehound for mounting in the Maw.
v 1.0.9: Updated for Patch 9.0.5.
v 1.0.8: Workaround for WoW APIs not allowing flying in Draenor.
v 1.0.7: Will summon valid mounts in The Maw, slow chauffeured mounts only used at low level, druid shapes cancelled in macro before mounting.
v 1.0.6: Updated for 9.0.2   
v 1.0.5: Bug fix for summoning in weird places like the Dalaran Plank.
v 1.0.4: Updated for Shadowlands pre-patch.
v 1.0.3: For toons less than level 60, ground mounts will always be preferred, even in a flying region.
v 1.0.2: Dismount option, bug fix for getting map zone names.
v 1.0.1: Improved checking for areas where it is not possible to mount.
v 1.0.0: Initial release.