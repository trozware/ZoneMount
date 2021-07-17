-- ISSUES
---------
-- detect underwater breathing - warlock buff, potions, quest items

-- /dump GetMacroInfo('ZoneMount') => gets ID of selected icon
-- 134400 = Question mark icon
-- 132226 = Horse shoe icon - gold
-- 136103 = Horse shoe icon - blue


ZoneMount = {} 

local ZoneMount_EventFrame = CreateFrame("Frame")
ZoneMount_EventFrame:RegisterEvent("VARIABLES_LOADED")
ZoneMount_EventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
ZoneMount_EventFrame:RegisterEvent("PLAYER_LOGIN")

local ZoneMount_LastSummon = nil
local ZoneMount_DebugMode = false
local ZoneMount_LastDismountCommand = nil
local ZoneMount_HasMacroInstalled = false

ZoneMount_EventFrame:SetScript("OnEvent",
  function(self, event, ...)
    -- print(event)
    if event == "VARIABLES_LOADED" then
      ZoneMount:Initialize()
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
      -- print('Mount changed event')
    elseif event == "PLAYER_LOGIN" then
      ZoneMount_ShowWelcome()
      ZoneMount_UpdateMacro()
    end  
  end
)

function ZoneMount:Initialize()
  SLASH_ZONEMOUNT1, SLASH_ZONEMOUNT2 = "/zonemount", "/zm"
  SlashCmdList["ZONEMOUNT"] = ZoneMountCommandHandler

  if not zoneMountSettings then
		zoneMountSettings = {
      favsOnly = false,
      hideInfo = false
		}
  end

  ZoneMount_addInterfaceOptions()
end

function ZoneMountCommandHandler(msg) 
    if msg == 'mount' then
      ZoneMount_MountOrDismount()
    elseif msg == 'macro' then
      ZoneMount_CreateMacro()
    elseif msg == 'about' then
      ZoneMount_DisplayInfo()
    elseif msg == 'do' or msg == 'act' then
      ZoneMount_DoSpecial()
      -- ZoneMount_DisplayMessage("Current Status:", true)
      -- print('IsOutdoors = ', IsOutdoors())
      -- print('IsFlyableArea = ', IsFlyableArea())
      -- print('IsMounted = ', IsMounted())
      -- print('IsFlying = ', IsFlying())
      -- print('IsSubmerged = ', IsSubmerged())
      -- print('IsSwimming = ', IsSwimming())
      -- print('Preferred mount type = ', ZoneMount_TypeOfMountToSummon())
      -- print('=========================')
    -- elseif msg == 'debug' then
    --   ZoneMount_ToggleDebugMode()
    elseif msg == '' or msg == 'help' then
      ZoneMount_DisplayHelp()
    else
      ZoneMount_SearchForMount(msg)
    end
end

function ZoneMount_ToggleDebugMode()
  if ZoneMount_DebugMode == true then
    ZoneMount_DebugMode = false
    print('ZoneMount debug mode is now OFF.')
  else
    ZoneMount_DebugMode = true
    print('ZoneMount debug mode is now ON.')
  end
end

function ZoneMount_ShowWelcome()
  local v = GetAddOnMetadata("ZoneMount", "Version") 
  local msg = "|c0000FF00Welcome to ZoneMount v" .. v .. ": " .. "|c0000FFFFType |c00FFD100/zm help |c0000FFFFfor help."
  ZoneMount_DisplayMessage(msg, false)
end

function ZoneMount_DisplayMessage(msg, format)
  if format == true then
    local formatted_msg = "|c0000FF00ZoneMount: |c0000FFFF" .. msg
    ChatFrame1:AddMessage(formatted_msg)
  else
    ChatFrame1:AddMessage(msg)
  end
end

function ZoneMount_DisplaySummonMessage(name, zone, description)
  if zoneMountSettings.hideInfo then
    return
  end

  local msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFSummoning " .. "|c00FFD100" .. name
  if zone and zone ~= '' then
    msg = msg .. "|c0000FFFF from " .. zone.. "."
  end
  ChatFrame1:AddMessage(msg)

  if description and description ~= '' then
    ChatFrame1:AddMessage("|c0000FFFF" .. description)
  end
end

function ZoneMount_DisplayInfo()
  ZoneMount_ShowWelcome()

  local current_mount_info = ZoneMount_CurrentMount()
  if current_mount_info == '' then
    ZoneMount_DisplayMessage('You are not mounted, or your current mount cannot be determined.')
    return
  end

  local description = ZoneMount_DescriptionForMount(current_mount_info.id)
  local msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFMount: " .. "|c00FFD100" .. current_mount_info.name
  ChatFrame1:AddMessage(msg)

  if description and description ~= '' then
    ChatFrame1:AddMessage("|c0000FFFF" .. description)
  end
end

function ZoneMount_MountOrDismount() 
  if IsMounted() then
    if not IsFlying() then
      Dismount()
      ZoneMount_LastDismountCommand = nil
    elseif ZoneMount_HasMacroInstalled then
      local now = GetTime()           -- time in seconds
      if ZoneMount_LastDismountCommand ~= nil and now - ZoneMount_LastDismountCommand < 2.0 then
        Dismount()
      else
        local formatted_msg = '|c0000FF00ZoneMount: |c0000FFFFYou are flying.|c00FFD100'
        formatted_msg = formatted_msg .. 'To plummet off your mount, press the macro button again within 2 seconds.'
        ChatFrame1:AddMessage(formatted_msg)

        ZoneMount_LastDismountCommand = now
      end
    else
      ZoneMount_LookForMount()
      ZoneMount_LastDismountCommand = nil
    end
  else
    ZoneMount_LookForMount()
    ZoneMount_LastDismountCommand = nil
  end
end

function ZoneMount_LookForMount()
  local badReason = ZoneMount_ShouldLookForNewMount() 
  if badReason ~= 'yes' then
    ZoneMount_DisplayMessage('Not a good time right now... ' .. badReason, true)
    return
  end

  local mount_type = ZoneMount_TypeOfMountToSummon()
  local secondary_mount_type = ''
  if mount_type == 'water' then
    if IsFlyableArea() and UnitLevel("player") >= 30 then
      secondary_mount_type = 'flying'
    else
      secondary_mount_type = 'ground'
    end
  end

  -- print('Looking for ', mount_type, 'mount')
  if mount_type == 'none' then
    ZoneMount_DisplayMessage('Not a good place right now...', true)
    return
  end

  local debug_report = ''
  local valid_mounts = ZoneMount_ValidMounts()
  -- print('Number of valid mounts = ', #valid_mounts)
  if #valid_mounts == 0 then
    ZoneMount_DisplayMessage(ZoneMount_FailReason(), true)
    return
  end

  local zone_mounts = {}
  local type_mounts = {}
  local secondary_zone_mounts = {}
  local secondary_type_mounts = {}
  local zone_names = ZoneMount_ZoneNames()

  for n = 1, #valid_mounts do
    local mount_id = valid_mounts[n].ID
    local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
      uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
      = C_MountJournal.GetMountInfoExtraByID(mount_id)

    if ZoneMount_RightMountType(mount_type, mountTypeID) then
        type_mounts[#type_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = '' }

        local matchingZoneName = ZoneMount_SourceInValidZone(source, zone_names)
        if matchingZoneName ~= '' then
          zone_mounts[#zone_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = matchingZoneName }

          -- print(valid_mounts[n].name, mountTypeID)
          -- -- print(description)
          -- print(matchingZoneName)
          -- print('==================')
        end
      else if secondary_mount_type ~= '' and ZoneMount_RightMountType(secondary_mount_type, mountTypeID) then
        secondary_type_mounts[#secondary_type_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = '' }

        local matchingZoneName = ZoneMount_SourceInValidZone(source, zone_names)
        if matchingZoneName ~= '' then
          secondary_zone_mounts[#secondary_zone_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = matchingZoneName }
        end
      end
    end
  end

  if ZoneMount_DebugMode == true then
    debug_report = 'Type: ' .. mount_type .. ' = ' .. #type_mounts .. '\n' ..
      'Zone: ' .. #zone_mounts .. '\n'

    if secondary_mount_type ~= '' then
      debug_report = debug_report .. 'Type 2: ' .. secondary_mount_type .. ' = ' .. #secondary_type_mounts .. '\n' ..
            'Zone 2: ' .. #secondary_zone_mounts .. '\n'
    end
  end

  -- print('Number of ' .. mount_type .. ' mounts = ', #type_mounts)
  -- print('Number of zone mounts = ', #zone_mounts)

  -- if secondary_mount_type ~= '' then
  --   print('Number of ' .. secondary_mount_type .. ' mounts = ', #secondary_type_mounts)
  --   print('Number of secondary zone mounts = ', #secondary_zone_mounts)
  -- end

  if #zone_mounts == 0 then
    zone_mounts = type_mounts
  end
  if #zone_mounts == 0 then
    zone_mounts = secondary_zone_mounts
  end
  if #zone_mounts == 0 then
    zone_mounts = secondary_type_mounts
  end
  if #type_mounts == 0 then
    type_mounts = secondary_type_mounts
  end

  local mount_index, name, id, description, source

  if #zone_mounts == 1 and #type_mounts > 1 then
    -- add in at least one other valid mount if possible
    -- duplicate correct one to give it a better chance
    local zone_name = zone_mounts[1].name
    zone_mounts[2] = zone_mounts[1]
    local extra_name = ''
    repeat
      mount_index = math.random(#type_mounts)
      if type_mounts[mount_index].name ~= zone_name then
        zone_mounts[#zone_mounts + 1] = type_mounts[mount_index]
        extra_name = type_mounts[mount_index].name
      end
    until #zone_mounts == 3
    ZoneMount_LastSummon = nil

    debug_report = debug_report .. 'adding type mount to zone mounts - ' ..  extra_name .. '\n'
  end

  if #zone_mounts == 1 and #valid_mounts > 1 then
    -- add in at least one other valid mount if possible
    -- duplicate correct one to give it a better chance
    local zone_name = zone_mounts[1].name
    zone_mounts[2] = zone_mounts[1]
    local extra_name = ''
    repeat
      mount_index = math.random(#valid_mounts)
      if valid_mounts[mount_index].name ~= zone_name then
        zone_mounts[#zone_mounts + 1] = valid_mounts[mount_index]
        extra_name = valid_mounts[mount_index].name
      end
    until #zone_mounts == 3
    ZoneMount_LastSummon = nil

    debug_report = debug_report .. 'adding valid mount to zone mounts - ' ..  extra_name .. '\n'
  end

  if #zone_mounts == 0 then
    zone_mounts = valid_mounts
  end

  debug_report = debug_report .. 'choosing randomly from ' .. #zone_mounts .. ' possible mounts...'

  -- print('Choosing randomly from ' .. #zone_mounts .. ' possible mounts...')
  repeat
    mount_index = math.random(#zone_mounts)
    name = zone_mounts[mount_index].name
    id = zone_mounts[mount_index].ID
    description = zone_mounts[mount_index].description
    source = zone_mounts[mount_index].source
  until (ZoneMount_IsAlreadyMounted(name) == false and id ~= ZoneMount_LastSummon) or #zone_mounts == 1

  if not description then
    description = ZoneMount_DescriptionForMount(id)
  end
  ZoneMount_DisplaySummonMessage(name, source, description)

  if ZoneMount_IsAlreadyMounted(name) == false then
    C_MountJournal.SummonByID(id)
    ZoneMount_LastSummon = id
  end

  if ZoneMount_DebugMode == true then
    print(debug_report)
  end
end

function ZoneMount_IsDruid()
  local _, classFilename, _ = UnitClass('player')
  if classFilename == 'DRUID' then
    return true
  end
  return false
end

function ZoneMount_CheckForDruidShapeshift(id)
  local _, classFilename, _ = UnitClass('player')
  if classFilename == 'DRUID' then
    print('Is a druid')
    local shapeIndex = GetShapeshiftForm(true)
    print('Shape = ' ..  shapeIndex)
    ZoneMount_PrintShape()

    if shapeIndex == 3 and IsFlying() then
      print('Travel form - flying')
      return
    end
    -- 0 is normal, 3 is travel form and works, anything else blocks mounting
    if shapeIndex > 0 then
      print('Cancelling')
      CancelShapeshiftForm()
    end
  end

  C_MountJournal.SummonByID(id)
  ZoneMount_LastSummon = id
end

function ZoneMount_PrintShape()
  local shapeIndex = GetShapeshiftForm(true)
  if shapeIndex == 0 then
    print('Not shifted')
  elseif shapeIndex == 1 then
    print('Bear form')
  elseif shapeIndex == 2 then
    print('Cat form')
  elseif shapeIndex == 3 then
    print('Travel form')
  elseif shapeIndex == 4 then
    print('4: Moon, tree or stag form')
  elseif shapeIndex == 5 then
    print('5: Moon, tree or stag form')
  elseif shapeIndex == 6 then
    print('6: Moon, tree or stag form')
  else
    print('Unknown form')
  end
end

function ZoneMount_ValidMounts()
  C_MountJournal.SetAllSourceFilters(true)
  C_MountJournal.SetCollectedFilterSetting(1, true)
  C_MountJournal.SetCollectedFilterSetting(2, false)
  C_MountJournal.SetSearch('')

  local playerLevel = UnitLevel("player")
  local inMaw = ZoneMount_InTheMaw()

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()
  -- print('Number of displayed mounts = ', num_mounts)

  local valid_mounts = {}
  local chauffeur_mounts = {}
  local maw_mounts = {}

  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID = 
      C_MountJournal.GetDisplayedMountInfo(n)

    if zoneMountSettings.favsOnly == false or isFavorite == true then
      if isCollected and (mountID == 1304 or mountID == 1441 or mountID == 1442) then
        maw_mounts[#maw_mounts + 1] = { name = creatureName, ID = mountID }
      elseif isUsable and isCollected then
        if (mountID == 678 or mountID == 679) and playerLevel > 10 then
          chauffeur_mounts[#chauffeur_mounts + 1] = { name = creatureName, ID = mountID }
        else
          valid_mounts[#valid_mounts + 1] = { name = creatureName, ID = mountID }
        end
      end
    end
  end

  if #valid_mounts == 0 and inMaw then
    valid_mounts = maw_mounts
  end

  -- don't use chauffered mount if 10 or higher as it is slower, unless htere are no other options
  if #valid_mounts == 0 and not inMaw then
    valid_mounts = chauffeur_mounts
  end

  return valid_mounts
end

function ZoneMount_FailReason()
  -- called when there are no valid mounts
  local total_mounts = C_MountJournal.GetNumMounts()
  local num_mounts = C_MountJournal.GetNumDisplayedMounts()

  if total_mounts == 0 then
    return 'You have no mounts.'
  elseif num_mounts == 0 then
    return 'You have no mounts that can be used here.'
  else
    return 'You are not allowed to mount in this area.'
  end
end

function ZoneMount_TypeOfMountToSummon()
  --  TODO: IsFlyableArea returns false in Draenor where you can now fly
  if IsIndoors() then
    return 'none'
  elseif IsSubmerged() or IsSwimming() then
    return 'water'
  elseif IsFlyableArea() and UnitLevel("player") >= 30 then
    return 'flying'
  elseif ZoneMount_InDraenor() and UnitLevel("player") >= 30 then
    return 'flying'
  else
    return 'ground'
  end
end

function ZoneMount_ShouldLookForNewMount()
  if UnitIsFeignDeath("player") then
    return 'You are feigning death.'
  end

  if InCombatLockdown() then
    return 'You are in combat.'
  end

  if UnitIsDeadOrGhost("player") then
    return 'You are dead.'
  end

  local spellName, _, _, _, _, _, _, _, _, _ = UnitCastingInfo("player")
  if spellName ~= nil then
    return 'You are casting ' .. spellName .. '.'
  end 

  local channelName, _, _, _, _, _, _, _ = UnitChannelInfo("player")
  if channelName ~= nil then
    return 'You are channeling ' .. channelName .. '.'
  end

  if IsFlying() == true then
    return 'You are flying.'
  end

  if UnitInVehicle("player") == true then
    return 'You are in a vehicle.'
  end

  if UnitOnTaxi("player") == true then
    return 'You are in a taxi.'
  end

  return 'yes'
end

function ZoneMount_RightMountType(required_type, type_id)
  if required_type == 'water' then
    if type_id == 231 then
      -- turtles work on land or water
      return true
    elseif type_id == 254 and ZoneMount_IsUnderwater() then
      -- call underwater mounts only if breath is running out i.e. underwater
      return true
    elseif type_id == 232 and ZoneMount_InVashjir() == true then
      -- Vashj'ir Seahorse - only works in Vashj'ir zones
      return true
    else
      return false
    end
  elseif required_type == 'flying' then
    if type_id == 247 or type_id == 248 or type_id == 254 or type_id == 398 then
      return true
    else
      return false
    end
  elseif required_type == 'ground' then
    if type_id == 230 or type_id == 231 or type_id == 241 or type_id == 269 
      or type_id == 284 then
      return true
    else
      return false
    end
  else
    return false
  end
end

function ZoneMount_InVashjir()
  local zone = GetZoneText()
  if zone == 'Shimmering Expanse' or zone == 'Abyssal Depths' 
    or zone == "Kelp'thar Forest" then
    return true
  else
    return false
  end
end

function ZoneMount_InTheMaw()
  local zone = GetZoneText()
  if zone == 'The Maw' then
    return true
  end

  local zone_names = ZoneMount_ZoneNames()
  for n = 1, #zone_names do
    if zone_names[n] == 'The Maw' then
      return true
    end
  end

  return false
end

function ZoneMount_InDraenor()
  local zone = GetZoneText()  
  if zone == 'Shadowmoon Valley' or zone == 'Frostfore Ridge' or zone == 'Ashran'
    or zone == 'Gorgrond' or zone == 'Nagrand' or zone == 'Spires of Arak' or zone == 'Talador' 
    or zone == 'Tanaan Jungle' or zone == 'Lunarfall' or zone == 'Frostwall' then
    return true
  else
    return false
  end
end

function ZoneMount_SearchForMount(search_name)
  if ZoneMount_ShouldLookForNewMount() == 'no' then
    ZoneMount_DisplayMessage('Not a good time right now...', true)
    return
  end

  local mount_name = strlower(search_name)
  local totalMatch = nil
  local goodMatch = {}
  local fairMatch = {}

  C_MountJournal.SetAllSourceFilters(true)
  C_MountJournal.SetCollectedFilterSetting(1, true)
  C_MountJournal.SetCollectedFilterSetting(2, false)
  C_MountJournal.SetSearch('')

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()

  local valid_mounts = {}
  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID = 
      C_MountJournal.GetDisplayedMountInfo(n)

    if isUsable and isCollected then
      if strlower(creatureName) == mount_name then
        totalMatch = { name = creatureName, ID = mountID }
        break
      else
        local strLocation1 = strfind(strlower(creatureName), mount_name)
        local strLocation2 = strfind(strlower(creatureName), ' ' .. mount_name)
        if strLocation1 == 1 or strLocation2 ~= nil then
          goodMatch[#goodMatch + 1] = { name = creatureName, ID = mountID }
        elseif strLocation1 ~= nil then
          fairMatch[#fairMatch + 1] = { name = creatureName, ID = mountID }
        end
      end
    end
  end

  local matching_id = nil
  local matching_name = nil

  if totalMatch ~= nil then
    matching_id = totalMatch.ID
    matching_name = totalMatch.name
  else
    local possibles = goodMatch
    if #goodMatch == 0 then
      possibles = fairMatch
    end

    if #possibles > 0 then
      repeat
        mount_index = math.random(#possibles)
        matching_id = possibles[mount_index].ID
        matching_name = possibles[mount_index].name
      until (ZoneMount_IsAlreadyMounted(matching_name) == false or #possibles == 1)
    end
  end

  if matching_id ~= nil then
    if ZoneMount_IsAlreadyMounted(matching_name) then
      ZoneMount_DisplayMessage('Already riding ' .. matching_name, true)
    else
      local description = ZoneMount_DescriptionForMount(matching_id)
      ZoneMount_DisplaySummonMessage(matching_name, '', description)
      C_MountJournal.SummonByID(matching_id)
      ZoneMount_LastSummon = matching_id
    end
  else
    ZoneMount_DisplayMessage("|c0000FF00ZoneMount: " .. "|c0000FFFFCan't find a mount with a name like |c00FFD100" .. search_name .. ".")
  end
end

function ZoneMount_DescriptionForMount(mount_id)
    local _, description, _, _, _,  _, _, _, _  = C_MountJournal.GetMountInfoExtraByID(mount_id)
    return description
end

function ZoneMount_DisplayHelp()
  local msg
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm mount|c0000FFFF to summon an appropriate mount."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm about|c0000FFFF to show some information about ZoneMount and your mount."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm _name_|c0000FFFF to search for a mount by name."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm macro|c0000FFFF to create a ZoneMount macro action button."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm do|c0000FFFF while on the ground to make your mount do its special action."
  ChatFrame1:AddMessage(msg)
end

function ZoneMount_IsAlreadyMounted(mount_name)
  for i = 1, 40 do 
    local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
      nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, 
      nameplateShowAll, timeMod, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 
      = UnitAura('player', i)
    if name == mount_name then
      return true
    end
  end

  return false
end

function ZoneMount_CurrentMount()
  if not IsMounted() then
    return ''
  end

  local mount_names = ZoneMount_ListMountNames()

  for i = 1, 40 do 
    local name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
      nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, 
      nameplateShowAll, timeMod, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 
      = UnitAura('player', i)

    for x = 1, #mount_names do
      if mount_names[x].name == name then
        return mount_names[x]
      end
    end
  end

  return ''
end

function ZoneMount_ListMountNames()
  C_MountJournal.SetAllSourceFilters(true)
  C_MountJournal.SetCollectedFilterSetting(1, true)
  C_MountJournal.SetCollectedFilterSetting(2, false)
  C_MountJournal.SetSearch('')

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()

  local mount_names = {}
  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID = 
      C_MountJournal.GetDisplayedMountInfo(n)
      mount_names[#mount_names + 1] = { name = creatureName, id = mountID }
  end

  return mount_names
end

function ZoneMount_CreateMacro()
  local existing_macro = GetMacroInfo('ZoneMount')
  if existing_macro then
    ZoneMount_HasMacroInstalled = true
    ZoneMount_DisplayMessage('Your ZoneMount macro already exists. Drag it into your action bar for easy access.', true)
    PickupMacro('ZoneMount')
    return
  end

  local macro_id = CreateMacro("ZoneMount", "136103", "/cancelform\n/zm mount", nil, nil);
  if macro_id then
    ZoneMount_HasMacroInstalled = true
    ZoneMount_DisplayMessage('Your ZoneMount macro has been created. Drag it into your action bar for easy access.', true)
    PickupMacro('ZoneMount')
  else
    ZoneMount_DisplayMessage('There was a problem creating your ZoneMount macro.', true)
  end
end

function ZoneMount_UpdateMacro() 
  local existing_macro = GetMacroInfo('ZoneMount')
  if existing_macro then
    local macroIndex = GetMacroIndexByName("ZoneMount")
    if macroIndex > 0 then
      EditMacro(macroIndex, "ZoneMount", "136103", "/cancelform\n/zm mount", nil, nil)
    end
    ZoneMount_HasMacroInstalled = true
  end
end

function ZoneMount_ZoneNames()
  local map_id = C_Map.GetBestMapForUnit('player')
  local info = C_Map.GetMapInfo(map_id)
  local zone_names = {}

  zone_names[#zone_names + 1] = GetZoneText()
  local subZone = GetSubZoneText()
  if subZone then
    zone_names[#zone_names + 1] = subZone
  end

  if info == nil or info.name == nil then
    return zone_names
  end

  if ZoneMount_InTable(zone_names, info.name) == false then
    zone_names[#zone_names + 1] = info.name
  end
  
  if info.mapType == nil then
    return zone_names
  end

  local previous_map_id = map_id

  while (info and info.mapType and info.mapType < 3) do
    map_id = info.parentMapID
    info = C_Map.GetMapInfo(map_id)

    if info and info.name and ZoneMount_InTable(zone_names, info.name) == false then
      previous_map_id = map_id
      zone_names[#zone_names + 1] = info.name
    end
  end

  local children = C_Map.GetMapChildrenInfo(previous_map_id)  -- , _, true)
  for n = 1, #children do
    if ZoneMount_InTable(zone_names, children[n].name) == false then
      zone_names[#zone_names + 1] = children[n].name
    end
  end

  -- print(map_id, #zone_names)
  -- for n = 1, #zone_names do
  --   print(zone_names[n])
  -- end
  return zone_names
end

function ZoneMount_SourceInValidZone(source, zones)
  for n = 1, #zones do
    if string.find(source, zones[n]) then
      return zones[n]
    end
  end
  return ''
end

function ZoneMount_InTable(tbl, item)
  for key, value in pairs(tbl) do
      if value == item then return key end
  end
  return false
end

function ZoneMount_IsUnderwater()
  local timer, initial, maxvalue, scale, paused, label = GetMirrorTimerInfo(2)
  -- print('Checking for underwater: timer = ' .. timer .. ' Scale = ' .. scale .. ' Paused = ' .. paused)
  if timer == 'BREATH' and paused == 0 and scale < 0 then
    return true
  end
  return false
end

function ZoneMount_ListMountTypes()
  C_MountJournal.SetAllSourceFilters(true)
  C_MountJournal.SetCollectedFilterSetting(1, true)
  C_MountJournal.SetCollectedFilterSetting(2, false)
  C_MountJournal.SetSearch('')

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()
  print('Number of mounts = ', num_mounts)

  local types = {}
  for n = 1, num_mounts do
    creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
      uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
      = C_MountJournal.GetDisplayedMountInfoExtra(n)

    if types[mountTypeID] then
      types[mountTypeID] = types[mountTypeID] + 1
    else
      types[mountTypeID] = 1
    end
  end

  for key, value in pairs(types) do
      print('Type ' .. key .. ': ' .. value)
  end
end

function ZoneMount_DoSpecial()
  local editbox=ChatEdit_ChooseBoxForSend(DEFAULT_CHAT_FRAME);--  Get an editbox
  ChatEdit_ActivateChat(editbox);--   Show the editbox
  editbox:SetText("/mountspecial");-- Command goes here
  ChatEdit_OnEnterPressed(editbox);-- Process command and hide (runs ChatEdit_SendText() and ChatEdit_DeactivateChat() respectively)
end

function ZoneMount_Tests()
  C_MountJournal.SetAllSourceFilters(true)
  C_MountJournal.SetCollectedFilterSetting(1, true)
  C_MountJournal.SetCollectedFilterSetting(2, true)
  C_MountJournal.SetCollectedFilterSetting(3, true)

  C_MountJournal.SetSearch('')

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()

  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID = 
      C_MountJournal.GetDisplayedMountInfo(n)

      if creatureName == 'Mawsworn Soulhunter' or creatureName == 'Corridor Creeper'  or creatureName == 'Bound Shadehound' then
        print(creatureName, mountID)
      end
  end
end

function ZoneMount_addInterfaceOptions()
  local y = -16
  ZoneMount.panel = CreateFrame("Frame", "ZonemountPanel", UIParent )
  ZoneMount.panel.name = "ZoneMount"
  InterfaceOptions_AddCategory(ZoneMount.panel)

  local Title = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  Title:SetJustifyV('TOP')
  Title:SetJustifyH('LEFT')
  Title:SetPoint('TOPLEFT', 16, y)
  local v = GetAddOnMetadata("ZoneMount", "Version") 
  Title:SetText('ZoneMount v' .. v)
  y = y - 44

  local btnFT = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	btnFT:SetSize(26,26)
	btnFT:SetHitRectInsets(-2,-200,-2,-2)
	btnFT.text:SetText('  Show mount info in Chat')
	btnFT.text:SetFontObject("GameFontNormal")
  btnFT:SetPoint('TOPLEFT', 40, y)
  btnFT:SetChecked(not zoneMountSettings.hideInfo)
  btnFT:SetScript("OnClick",function() 
    local isChecked = btnFT:GetChecked()
    zoneMountSettings.hideInfo = not isChecked
  end)
  y = y - 40

  local btn2 = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	btn2:SetSize(26,26)
	btn2:SetHitRectInsets(-2,-200,-2,-2)
	btn2.text:SetText('  Select from Favorites only')
	btn2.text:SetFontObject("GameFontNormal")
  btn2:SetPoint('TOPLEFT', 40, y)
  btn2:SetChecked(zoneMountSettings.favsOnly)
  btn2:SetScript("OnClick",function() 
    local isChecked = btn2:GetChecked()
    zoneMountSettings.favsOnly = isChecked
  end)
  y = y - 40
end
