function ZoneMount_MountOrDismount() 
  local now = GetTime()           -- time in seconds
  local timelimit = 1.6
  if IsMounted() then
    timelimit = 0.16
  end
  if now - ZoneMount_LastSummonTime < timelimit then
    return
  end
  ZoneMount_LastSummonTime = now

  if IsMounted() then
    if not IsFlying() then
      Dismount()
      ZoneMount_LastDismountCommand = nil
      ZoneMount_LastSummonTime = now - 2
      if IsInGroup() == false then
        ZoneMount_UpdateMacro()   -- in case Pathfinder achievement has been earned
      end
    elseif ZoneMount_HasMacroInstalled then
      local now = GetTime()           -- time in seconds
      if ZoneMount_LastDismountCommand ~= nil and now - ZoneMount_LastDismountCommand < 2.0 then
        Dismount()
      else
        if not zoneMountSettings.hideWarnings then
          local formatted_msg = '|c0000FF00ZoneMount: |c0000FFFFYou are flying.|c00FFD100'
          formatted_msg = formatted_msg .. 'To plummet off your mount, press the macro button again within 2 seconds.'
          ChatFrame1:AddMessage(formatted_msg)
        end

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
    if not zoneMountSettings.hideWarnings then
      if badReason ~= 'You are casting ' .. ZoneMount_LastSummonName then
        ZoneMount_DisplayMessage('Not a good time right now... ' .. badReason, true)
      end
    end
    return
  end

  local mount_type = ZoneMount_TypeOfMountToSummon()
  local secondary_mount_type = 'ground'
  if mount_type == 'water' and IsFlyableArea() and UnitLevel("player") >= 20 then
    secondary_mount_type = 'flying'
  end 
  -- end

  -- print('Looking for ', mount_type, 'mount')
  if mount_type == 'none' then
    if not zoneMountSettings.hideWarnings then
      ZoneMount_DisplayMessage('Not a good place right now...', true)
    end
    return
  end

  local debug_report = ''
  local valid_mounts = ZoneMount_ValidMounts()
  -- print('Number of valid mounts = ', #valid_mounts)
  if #valid_mounts == 0 then
    if not zoneMountSettings.hideWarnings then
      ZoneMount_DisplayMessage(ZoneMount_FailReason(), true)
    end
    return
  end

  local zone_mounts = {}
  local special_mounts = {}
  local type_mounts = {}
  local secondary_zone_mounts = {}
  local secondary_type_mounts = {}
  local zone_names = ZoneMount_ZoneNames()
  -- print('Zone names:')
  -- for n = 1, #zone_names do
  --   print(zone_names[n])
  -- end

  for n = 1, #valid_mounts do
    local mount_id = valid_mounts[n].ID
    if mount_id and mount_id ~= '' then
      local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
        uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
        = C_MountJournal.GetMountInfoExtraByID(mount_id)
      local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific,  
        faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight
        = C_MountJournal.GetMountInfoByID(mount_id)

      if ZoneMount_RightMountType(mount_type, mountTypeID, isSteadyFlight) then
        -- print('==================')
        -- print(valid_mounts[n].name, mountTypeID)
        -- print(description)
        -- print(matchingZoneName)

        type_mounts[#type_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = '' }

        local matchingZoneName = ZoneMount_SourceInValidZone(source, zone_names)
        if matchingZoneName ~= '' then
          zone_mounts[#zone_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = matchingZoneName }
        else
          special_purchase = false
          if source and #source > 0 then 
            if string.find(source, 'Game') then
              special_purchase = true
            elseif string.find(source, 'Promotion') then
              special_purchase = true
            end
          end
          if special_purchase then
            special_mounts[#special_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = '' }
          end
        end
      else if secondary_mount_type ~= '' and ZoneMount_RightMountType(secondary_mount_type, mountTypeID, isSteadyFlight) then
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
  
  -- print('Number of special mounts = ', #special_mounts)
  -- for n = 1, #special_mounts do
    --   print(special_mounts[n].name, special_mounts[n].source)
  -- end

  if #zone_mounts == 0 then
    zone_mounts = type_mounts
  end
  if #zone_mounts == 0 then
    zone_mounts = secondary_zone_mounts
  end
  if #type_mounts == 0 then
    type_mounts = secondary_type_mounts
  end

  -- print('Number of zone mounts = ', #zone_mounts)
  -- print('Number of special mounts = ', #special_mounts)

  if #special_mounts > 0 and zoneMountSettings.padZoneList == true then
    local special_index = math.random(#special_mounts)
    zone_mounts[#zone_mounts + 1] = special_mounts[special_index]
  end

  local mount_index, name, id, description, source

  if #zone_mounts == 1 and #type_mounts > 1 and zoneMountSettings.padZoneList == true then
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

  if #zone_mounts == 1 and #valid_mounts > 1 and zoneMountSettings.padZoneList == true then
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
    if #special_mounts > 0 then
      local special_index = math.random(#special_mounts)
      zone_mounts[#zone_mounts + 1] = special_mounts[special_index]
    end
  end

  debug_report = debug_report .. 'choosing randomly from ' .. #zone_mounts .. ' possible mounts...'

  -- print('Choosing randomly from ' .. #zone_mounts .. ' possible mounts...')
  local max_attempts = #zone_mounts
  local attempts = 0
  repeat
    attempts = attempts + 1
    mount_index = math.random(#zone_mounts)
    name = zone_mounts[mount_index].name
    id = zone_mounts[mount_index].ID
    description = zone_mounts[mount_index].description
    source = zone_mounts[mount_index].source
  until (ZoneMount_IsAlreadyMounted(name) == false and id ~= ZoneMount_LastSummon) or #zone_mounts == 1 or attempts >= max_attempts

  if not description or #description == 0 then
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

function ZoneMount_clearFilters()
  C_MountJournal.SetAllTypeFilters(true)
  C_MountJournal.SetAllSourceFilters(true)
  C_MountJournal.SetSearch('')

  -- 1 = LE_MOUNT_JOURNAL_FILTER_COLLECTED	
  -- 2 = LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED	
  -- 3 =LE_MOUNT_JOURNAL_FILTER_UNUSABLE
  C_MountJournal.SetCollectedFilterSetting(1, true)
  C_MountJournal.SetCollectedFilterSetting(2, false)
  C_MountJournal.SetCollectedFilterSetting(3, false)
end

function ZoneMount_ValidMounts()
  ZoneMount_clearFilters()

  local playerLevel = UnitLevel("player")
  local inMaw = ZoneMount_InTheMaw()

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()
  -- print('Number of displayed mounts = ', num_mounts)

  local valid_mounts = {}
  local chauffeur_mounts = {}
  local maw_mounts = {}

  local englishFaction, localizedFaction = UnitFactionGroup('player')

  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID, isSteadyFlight = 
      C_MountJournal.GetDisplayedMountInfo(n)

    if mountID == 125 or mountID == 1539 then
      -- Riding Turtle or Unsuccessful Prototype Fleetpod, too slow
      isUsable = false
    end
    if mountID == 2039 then
      -- Savage Blue Battle Turtle too slow except in water
      if ZoneMount_IsUnderwater() or IsSubmerged() or IsSwimming() then
        isUsable = true
      else
        isUsable = false
      end
    end

    -- isFactionSpecific - true if the mount is only available to one faction, false otherwise.
    -- faction - 0 if the mount is available only to Horde players, 1 if the mount is available only to Alliance players, or nil if the mount is not faction-specific.
    if isFactionSpecific then
      if englishFaction == 'Alliance' and faction == 0 then
        isUsable = false
      elseif englishFaction == 'Horde' and faction == 1 then
        isUsable = false
      end
    end

    -- ignored names
    if isUsable and isCollected and creatureName and zoneMountSettings.ignores then
      for n = 1, #zoneMountSettings.ignores do
        if zoneMountSettings.ignores[n] then
          local testName = string.lower(zoneMountSettings.ignores[n])
          local index = string.find(string.lower(creatureName), testName)
          if index then
            isUsable = false
          end
        end
      end
    end

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

  -- don't use chauffered mount if 10 or higher as it is slower, unless there are no other options
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

-- /run print(ZoneMount_TypeOfMountToSummon())
function ZoneMount_TypeOfMountToSummon()
  if IsIndoors() then
    return 'none'
  elseif ZoneMount_ShouldUseGroundMount() then
    return 'ground'
  elseif ZoneMount_IsUnderwater() then
    return 'water'
  elseif UnitLevel("player") >= 10 and UnitLevel("player") < 20 then
    if IsModifierKeyDown() then
      return 'ground'
    else
      return 'flying'
    end
  elseif IsFlyableArea() and (UnitLevel("player") >= 10 or ZoneMount_IsInRemix()) then
    return 'flying'
  elseif UnitLevel("player") >= 70 and ZoneMount_HasWarWithinPathfinder() then
    return 'flying'
  elseif ZoneMount_CanSkyride() then
    return 'flying'
  elseif ZoneMount_InDraenor() and UnitLevel("player") >= 10 then
    return 'flying'
  elseif IsSubmerged() or IsSwimming() then
    return 'water'
  else
    return 'ground'
  end
end

function ZoneMount_ShouldUseGroundMount()
  if zoneMountSettings.shiftUseGround and IsShiftKeyDown() then
    return true
  elseif zoneMountSettings.ctrlUseGround and IsControlKeyDown() then
    return true
  elseif zoneMountSettings.altUseGround and IsAltKeyDown() then
    return true
  else
    return false
  end
end

function ZoneMount_ShouldLookForNewMount()
  if UnitIsFeignDeath("player") then
    return 'You are feigning death.'
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

  if ZoneMount_HasRadiantLight() == true then
    return 'yes'
  end

  if InCombatLockdown() then
    return 'You are in combat.'
  end

  return 'yes'
end

function ZoneMount_RightMountType(required_type, type_id, isSteadyFlight)
  if required_type == 'water' then
    if type_id == 231 or type_id == 407 then
      -- turtles work on land or water
      -- 407s work in water & flying
      return true
    elseif type_id == 254 and (ZoneMount_IsUnderwater() or (ZoneMount_InVashjir() and IsSubmerged())) then
      -- call underwater mounts only if breath is running out i.e. underwater
      return true
    elseif type_id == 232 and ZoneMount_InVashjir() == true then
      -- Vashj'ir Seahorse - only works in Vashj'ir zones
      return true
    else
      return false
    end
  elseif required_type == 'flying' then
    if type_id == 247 or type_id == 248 or type_id == 398 or type_id == 407 or type_id == 424 or type_id == 402 then
      return true
    else
      return false
    end
  elseif required_type == 'ground' then
    -- don't summon Savage Blue Battle Turtle (231) if not in water

    if type_id == 230 or type_id == 241 or type_id == 269 
      or type_id == 284 or type_id == 408 or type_id == 412 then
      return true
    else
      return false
    end
  else
    return false
  end
end
