-- ISSUES
---------

-- if selecting dragon flyer with favs only and there are no favs, over-ride the setting
-- detect underwater breathing - warlock buff, potions, quest items

-- /dump GetMacroInfo('ZoneMount') => gets ID of selected icon
-- 134400 = Question mark icon
-- 132226 = Horse shoe icon - gold
-- 136103 = Horse shoe icon - blue

-- When checking zone names, can I check by ID to avoid translation issues?

ZoneMount = {} 

local ZoneMount_EventFrame = CreateFrame("Frame")
ZoneMount_EventFrame:RegisterEvent("VARIABLES_LOADED")
ZoneMount_EventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
ZoneMount_EventFrame:RegisterEvent("PLAYER_LOGIN")

local ZoneMount_LastSummon = nil
local ZoneMount_LastSummonTime = 0
local ZoneMount_LastSummonName = ''
local ZoneMount_DebugMode = false
local ZoneMount_LastDismountCommand = nil
local ZoneMount_HasMacroInstalled = false
local ZoneMount_LastChatReport = 0

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
      hideInfo = false,
      slowInfo = false,
      hideWarnings = false,
      -- dragonIslesDefaultDragon = true,
      -- otherPlacesDefaultNonDragon = true,
      ignores = {}
		}
  end

  -- if zoneMountSettings.dragonIslesDefaultDragon == nil then
  --   zoneMountSettings.dragonIslesDefaultDragon = true
  -- end
  -- if zoneMountSettings.otherPlacesDefaultNonDragon == nil then
  --   zoneMountSettings.otherPlacesDefaultNonDragon = true
  -- end
  if not zoneMountSettings.ignores then
    zoneMountSettings.ignores = {}
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
  local v = C_AddOns.GetAddOnMetadata("ZoneMount", "Version") 
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
  ZoneMount_LastSummonName = name

  if zoneMountSettings.hideInfo then
    return
  end

  local now = GetTime()           -- time in seconds
  if zoneMountSettings.slowInfo and now - ZoneMount_LastChatReport < 180 then
    return
  end
  ZoneMount_LastChatReport = now
  
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
  -- if mount_type == 'dragon' then
  --   secondary_mount_type = 'dragon'
  -- else
  if mount_type == 'water' and IsFlyableArea() and UnitLevel("player") >= 30 then
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
        faction, shouldHideOnChar, isCollected, mountID, isForDragonriding
        = C_MountJournal.GetMountInfoByID(mount_id)

      if ZoneMount_RightMountType(mount_type, mountTypeID, isForDragonriding) then
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
            validZone = false
            if source and #source > 0 then 
              if string.find(source, 'Game') then
                validZone = true
              elseif string.find(source, 'Promotion') then
                validZone = true
              end
            end
            if validZone then
              special_mounts[#special_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
              description = description, source = '' }
            end
          end
        else if secondary_mount_type ~= '' and ZoneMount_RightMountType(secondary_mount_type, mountTypeID, isForDragonriding) then
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
  if #zone_mounts == 0 then
    zone_mounts = secondary_type_mounts
  end
  if #type_mounts == 0 then
    type_mounts = secondary_type_mounts
  end

  -- print('Number of zone mounts = ', #zone_mounts)
  -- print('Number of special mounts = ', #special_mounts)

  if #special_mounts > 0 then
    local special_index = math.random(#special_mounts)
    zone_mounts[#zone_mounts + 1] = special_mounts[special_index]
  end

  -- if #zone_mounts / 2 >= #special_mounts then
  --   for n = 1, #special_mounts do
  --     zone_mounts[#zone_mounts + 1] = special_mounts[n]
  --   end
  -- else
  --   local total_required = #zone_mounts * 1.5
  --   local mount_index
  --   repeat
  --     mount_index = math.random(#special_mounts)
  --     zone_mounts[#zone_mounts + 1] = special_mounts[mount_index]
  --   until #zone_mounts == total_required
  -- end
  -- print('Number of zone mounts = ', #zone_mounts)

  local mount_index, name, id, description, source

  -- if mount_type ~= 'dragon' and #zone_mounts == 1 and #type_mounts > 1 then
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
      isFactionSpecific, faction, hideOnChar, isCollected, mountID, isForDragonriding = 
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
  -- local shouldUseDragon = false

  -- if ZoneMount_InDragonIsles() then
  --   if zoneMountSettings.dragonIslesDefaultDragon and IsModifierKeyDown() == false then
  --     shouldUseDragon = true
  --   elseif zoneMountSettings.dragonIslesDefaultDragon == false and IsModifierKeyDown() then
  --     shouldUseDragon = true
  --   end
  -- else
  --   if zoneMountSettings.otherPlacesDefaultNonDragon and IsModifierKeyDown() == false then
  --     shouldUseDragon = false
  --   elseif zoneMountSettings.otherPlacesDefaultNonDragon == false and IsModifierKeyDown() then
  --     shouldUseDragon = false
  --   elseif UnitLevel("player") >= 10 or ZoneMount_IsInRemix() then
  --     shouldUseDragon = true
  --   end
  -- end

  if IsIndoors() then
    return 'none'
  elseif ZoneMount_IsUnderwater() then
    return 'water'
  elseif UnitLevel("player") >= 10 and UnitLevel("player") < 20 then
    if IsModifierKeyDown() then
      return 'ground'
    else
      return 'flying'
    end
  -- elseif ZoneMount_CanDragonFly() and shouldUseDragon == true then
  --   return 'dragon'
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

function ZoneMount_RightMountType(required_type, type_id, isForDragonriding)
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
  if zone == 'Shadowmoon Valley' or zone == 'Frostfire Ridge' or zone == 'Ashran'
    or zone == 'Gorgrond' or zone == 'Nagrand' or zone == 'Spires of Arak' or zone == 'Talador' 
    or zone == 'Tanaan Jungle' or zone == 'Lunarfall' or zone == 'Frostwall' then
    return true
  else
    return false
  end
end

function ZoneMount_InDragonIsles()
  if ZoneMount_IsInRemix() then
    return true
  end

  local zone_names = ZoneMount_ZoneNames()
  for n = 1, #zone_names do
    if zone_names[n] == 'Dragon Isles' then
      return true
    end
  end
  return false
end

function ZoneMount_IsInKhazAlgar()
  local zone_names = ZoneMount_ZoneNames()
  for n = 1, #zone_names do
    if zone_names[n] == 'Khaz Algar' then
      return true
    end
  end
  return false
end

-- appears to be deprecated (isForDragonriding always false)
function ZoneMount_CanDragonFly()
  ZoneMount_clearFilters()
  C_MountJournal.SetAllTypeFilters(false)
  C_MountJournal.SetTypeFilter(4, true)

  local num_dragon_mounts = C_MountJournal.GetNumDisplayedMounts()
  if num_dragon_mounts == 0 then
    return false
  else
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
    isFactionSpecific, faction, hideOnChar, isCollected, mountID, isForDragonriding = 
    C_MountJournal.GetDisplayedMountInfo(1)
    return isUsable and isCollected and isForDragonriding
  end
end

-- 40231 = War Within Pathfinder achievement
function ZoneMount_HasWarWithinPathfinder()
  local achievementID = 40231
  local _, _, _, completed = GetAchievementInfo(achievementID)
  return completed
end

-- /dump C_Spell.GetSpellInfo("Skyriding Basics") -> 376777
-- /dump C_Spell.GetSpellInfo(376777)
-- /dump C_Spell.IsSpellUsable(376777)
function ZoneMount_CanSkyride()
  local spellID = 376777
  local isUsable = C_Spell.IsSpellUsable(spellID)
  return isUsable
end

function ZoneMount_SearchForMount(search_name)
  if ZoneMount_ShouldLookForNewMount() == 'no' then
    if not zoneMountSettings.hideWarnings then
      ZoneMount_DisplayMessage('Not a good time right now...', true)
    end
    return
  end

  local mount_name = string.lower(search_name)
  local totalMatch = nil
  local goodMatch = {}
  local fairMatch = {}

  ZoneMount_clearFilters()

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()

  local valid_mounts = {}
  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID = 
      C_MountJournal.GetDisplayedMountInfo(n)

    if isUsable and isCollected then
      if string.lower(creatureName) == mount_name then
        totalMatch = { name = creatureName, ID = mountID }
        break
      else
        local strLocation1 = string.find(string.lower(creatureName), mount_name)
        local strLocation2 = string.find(string.lower(creatureName), ' ' .. mount_name)
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
      if not zoneMountSettings.hideWarnings then
        ZoneMount_DisplayMessage('Already riding ' .. matching_name, true)
      end
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
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFHold down Shift, Alt or Ctrl while clicking the macro to toggle skyriding."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm do|c0000FFFF while on the ground to make your mount do its special action."
  ChatFrame1:AddMessage(msg)
end

function ZoneMount_IsAlreadyMounted(mount_name)
  if not IsMounted() then
    return false
  end

  for i = 1, 40 do 
    local aura = C_UnitAuras.GetAuraDataByIndex('player', i, 'HELPFUL')
    if aura == nil then
      return false
    end

    if aura.name == mount_name then
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
    local aura = C_UnitAuras.GetAuraDataByIndex('player', i, 'HELPFUL')
    if aura == nil then
      return ''
    end

    local name = aura.name

    for x = 1, #mount_names do
      if mount_names[x].name == name then
        return mount_names[x]
      end
    end
  end

  return ''
end

function ZoneMount_ListMountNames()
  ZoneMount_clearFilters()

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

  local macroText = ZoneMount_MacroText()
  local macro_id = CreateMacro("ZoneMount", "136103", macroText, nil, nil);
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
      local macroText = ZoneMount_MacroText()
      EditMacro(macroIndex, "ZoneMount", "136103", macroText, nil, nil)
    end
    ZoneMount_HasMacroInstalled = true
  end
end

-- /dump C_Spell.GetSpellInfo("Switch Flight Style") -> 436854
-- /dump C_Spell.GetSpellInfo(436854)
-- /dump C_Spell.IsSpellUsable(436854)
function ZoneMount_MacroText()
  local canSteadyFly = C_Spell.IsSpellUsable(436854)
  local canSwitch = ZoneMount_CanSkyride() and canSteadyFly
  if ZoneMount_IsInKhazAlgar() then
    canSwitch = ZoneMount_HasWarWithinPathfinder()
  end
  if canSwitch then
    local macroText = "/quietcast\n/cast [mod] Switch Flight Style\n/zm mount"
    return macroText
  end
  local macroText = "/zm mount"
  return macroText
end

function ZoneMount_ZoneNames()
  local map_id = C_Map.GetBestMapForUnit('player')
  local info = nil
  if map_id then 
    info = C_Map.GetMapInfo(map_id)
  end
  local zone_names = {}

  zone_names[#zone_names + 1] = GetZoneText()
  local subZone = GetSubZoneText()
  if subZone and #subZone > 0 then
    zone_names[#zone_names + 1] = subZone
  end

  if info == nil or info.name == nil or info.name == '' then
    return zone_names
  end

  if ZoneMount_InTable(zone_names, info.name) == false then
    zone_names[#zone_names + 1] = info.name
  end
  
  if info.mapType == nil then
    return zone_names
  end

  local previous_map_id = map_id

  while (info and info.mapType and info.mapType >= 3) do
    map_id = info.parentMapID
    info = C_Map.GetMapInfo(map_id)

    if info and info.name and #info.name > 0 and ZoneMount_InTable(zone_names, info.name) == false then
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

  -- for n = 1, #zones do
  --   -- split the zone name into words and check each one
  --   local words = {}
  --   for word in string.gmatch(zones[n], '([^%s]+)') do
  --     if #word > 3 and string.find(source, word) then
  --       return zones[n]
  --     end
  --   end
  -- end

  -- print(source)
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

-- /run ZoneMount_ListMountTypes()

function ZoneMount_ListMountTypes()
  ZoneMount_clearFilters()
  C_MountJournal.SetCollectedFilterSetting(2, true)
  C_MountJournal.SetCollectedFilterSetting(3, true)

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()
  print('Number of mounts = ', num_mounts)

  local types = {}

  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID, isForDragonriding = 
      C_MountJournal.GetDisplayedMountInfo(n)

    local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
      uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
      = C_MountJournal.GetMountInfoExtraByID(mountID)

    if types[mountTypeID] then
      types[mountTypeID] = types[mountTypeID] + 1
    else
      types[mountTypeID] = 1
    end


    if mountTypeID == 398 or mountTypeID == 231  or mountTypeID == 254 or mountTypeID == 232 or mountTypeID == 284 
      or mountTypeID == 241 or mountTypeID == 407 or mountTypeID == 242 or mountTypeID == 247 then
      print(mountTypeID, creatureName)
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
  -- ZoneMount_clearFilters()
  -- C_MountJournal.SetCollectedFilterSetting(2, true)
  -- C_MountJournal.SetCollectedFilterSetting(3, true)

  -- local num_mounts = C_MountJournal.GetNumDisplayedMounts()

  -- local valid_mounts = ZoneMount_ValidMounts()
  -- print('Number of valid mounts = ', #valid_mounts)

  -- for n = 1, num_mounts do
  --   local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
  --     isFactionSpecific, faction, hideOnChar, isCollected, mountID, isForDragonriding = 
  --     C_MountJournal.GetDisplayedMountInfo(n)
  --     -- if isForDragonriding == true then
  --     --   print('Name', creatureName)
  --     --   print('ID', mountID)
  --     --   print('Type', mountTypeID)
  --     --   print('isForDragonriding', isForDragonriding)
  --     -- end

  --   -- if creatureName == 'Savage Blue Battle Turtle' then
  --   local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
  --   uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
  --   = C_MountJournal.GetMountInfoExtraByID(mountID)
    
  --   if mountTypeID == 231 then
  --     print('Name', creatureName)
  --     print('ID', mountID)
  --     print('Type', mountTypeID)
  --     print('Source type', sourceType)
  --     print('Source', source)
  --     print('Faction specific', isFactionSpecific)
  --     print('Faction', faction)
  --       print('isForDragonriding', isForDragonriding)
  --       print('isForDragonriding', isForDragonriding)
  --     end

  --   -- if creatureName == 'Ebon Gryphon' or creatureName == 'Highland Drake' then
  --   --   local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
  --   --   uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
  --   --   = C_MountJournal.GetMountInfoExtraByID(mountID)

  --   --   print('Name', creatureName)
  --   --   print('ID', mountID)
  --   --   print('Type', mountTypeID)
  --     -- print('Source type', sourceType)
  --     -- print('Source', source)
  --     -- print('Faction specific', isFactionSpecific)
  --     -- print('Faction', faction)
  --     -- print('isForDragonriding', isForDragonriding)
  --     print('isForDragonriding', isForDragonriding)
  --     end

  --   -- if creatureName == 'Ebon Gryphon' or creatureName == 'Highland Drake' then
  --   --   local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
  --   --   uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
  --   --   = C_MountJournal.GetMountInfoExtraByID(mountID)

  --   --   print('Name', creatureName)
  --   --   print('ID', mountID)
  --   --   print('Type', mountTypeID)
  --     -- print('Source type', sourceType)
  --     -- print('Source', source)
  --     -- print('Faction specific', isFactionSpecific)
  --     -- print('Faction', faction)
  --     -- print('isForDragonriding', isForDragonriding)

  --     -- local zone_names = ZoneMount_ZoneNames()
  --     -- print('Zone names:')
  --     -- for n = 1, #zone_names do
  --     --   print(zone_names[n])
  --     -- end

  --     -- -- local matchingZoneName = ZoneMount_SourceInValidZone(source, zone_names)
  --     -- for n = 1, #zone_names do
  --     --   if zone_names[n] ~= '' and string.find(source, zone_names[n]) then
  --     --     print('Found source in "' .. zone_names[n] .. '"')
  --     --   else
  --     --     print('Not found in "' .. zone_names[n] .. '"')
  --     --   end
  --     end
  --   end
  -- end
end

-- /dump C_Spell.GetSpellInfo(424143)
function ZoneMount_IsInRemix()
  for i = 1, 50 do 
    local aura = C_UnitAuras.GetAuraDataByIndex('player', i, 'HELPFUL')
    if aura == nil then
      return false
    end

    local name = aura.name
    local spellId = aura.spellId
    if name and spellId then
      if name.find(name, 'Remix') or spellId == 424143 then
        return true
      end
    else
      return false
    end
  end
end

-- /dump C_Spell.GetSpellInfo(449026)
-- /dump ZoneMount_HasRadiantLight()
function ZoneMount_HasRadiantLight()
  local radiantLightSpellID = 449026
  local radiantLightDebuffID = 449042

  if UnitLevel("player") < 70 then
    return false
  end

  for i = 1, 100 do 
    local aura = C_UnitAuras.GetAuraDataByIndex('player', i)
    if aura == nil then
      break
    else
      if aura.spellId and aura.spellId == radiantLightSpellID then
        return true
      end
    end
  end

  for i = 1, 100 do 
    local aura = C_TooltipInfo.GetUnitDebuff('player', i)

    if aura == nil then
      break
    else
      if aura.id and aura.id == radiantLightDebuffID then
        return true
      end
    end
  end

  return false
end

function ZoneMount_addInterfaceOptions()
  local y = -16
  ZoneMount.panel = CreateFrame("Frame", "ZonemountPanel", UIParent )
  ZoneMount.panel.name = "ZoneMount"
  
    -- InterfaceOptions_AddCategory(ZoneMount.panel)
  
  local category, layout = Settings.RegisterCanvasLayoutCategory(ZoneMount.panel, ZoneMount.panel.name, ZoneMount.panel.name)
  category.ID = ZoneMount.panel.name
  Settings.RegisterAddOnCategory(category)

  local Title = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  Title:SetJustifyV('TOP')
  Title:SetJustifyH('LEFT')
  Title:SetPoint('TOPLEFT', 16, y)
  local v = C_AddOns.GetAddOnMetadata("ZoneMount", "Version") 
  Title:SetText('ZoneMount v' .. v)
  y = y - 44

  local btnFT = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  local btnSlow = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")

	btnFT:SetSize(26,26)
	btnFT:SetHitRectInsets(-2,-200,-2,-2)
	btnFT.text:SetText('  Show mount info in Chat')
	btnFT.text:SetFontObject("GameFontNormal")
  btnFT:SetPoint('TOPLEFT', 40, y)
  btnFT:SetChecked(not zoneMountSettings.hideInfo)
  btnFT:SetScript("OnClick",function() 
    local isChecked = btnFT:GetChecked()
    zoneMountSettings.hideInfo = not isChecked
    btnSlow:SetEnabled(not zoneMountSettings.hideInfo)
    if zoneMountSettings.hideInfo then
      btnSlow.text:SetFontObject("GameFontDisable")
    else
      btnSlow.text:SetFontObject("GameFontNormal")
    end
  end)
  y = y - 40

  btnSlow:SetSize(26,26)
	btnSlow:SetHitRectInsets(-2,-200,-2,-2)
	btnSlow.text:SetText('  Not more than once every 3 minutes')
  btnSlow:SetPoint('TOPLEFT', 80, y)
  btnSlow:SetChecked(zoneMountSettings.slowInfo)
  btnSlow:SetEnabled(not zoneMountSettings.hideInfo)
  if zoneMountSettings.hideInfo then
    btnSlow.text:SetFontObject("GameFontDisable")
  else
    btnSlow.text:SetFontObject("GameFontNormal")
  end
  btnSlow:SetScript("OnClick",function() 
    local isChecked = btnSlow:GetChecked()
    zoneMountSettings.slowInfo = isChecked
    ZoneMount_LastChatReport = 0
  end)
  y = y - 40

  local btnWarn = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	btnWarn:SetSize(26,26)
	btnWarn:SetHitRectInsets(-2,-200,-2,-2)
	btnWarn.text:SetText('  Show warnings in Chat')
	btnWarn.text:SetFontObject("GameFontNormal")
  btnWarn:SetPoint('TOPLEFT', 40, y)
  btnWarn:SetChecked(not zoneMountSettings.hideWarnings)
  btnWarn:SetScript("OnClick",function() 
    local isChecked = btnWarn:GetChecked()
    zoneMountSettings.hideWarnings = not isChecked
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
  y = y - 120

  local shiftInfo1 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  shiftInfo1:SetJustifyV('TOP')
  shiftInfo1:SetJustifyH('LEFT')
  shiftInfo1:SetPoint('TOPLEFT', 40, y)
  shiftInfo1:SetText('Hold down Shift, Alt or Ctrl while clicking the macro button to toggle skyriding.')
  y = y - 16

  local shiftInfo2 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  shiftInfo2:SetJustifyV('TOP')
  shiftInfo2:SetJustifyH('LEFT')
  shiftInfo2:SetPoint('TOPLEFT', 40, y)
  shiftInfo2:SetText('If your level is 10 - 19, you can skyride but not steady fly.')
  y = y - 16

  local shiftInfo3 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  shiftInfo3:SetJustifyV('TOP')
  shiftInfo3:SetJustifyH('LEFT')
  shiftInfo3:SetPoint('TOPLEFT', 40, y)
  shiftInfo3:SetText('For these levels, use Shift, Alt or Ctrl to summon a ground mount.')
  y = y - 50

  local druidInfo1 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  druidInfo1:SetJustifyV('TOP')
  druidInfo1:SetJustifyH('LEFT')
  druidInfo1:SetPoint('TOPLEFT', 40, y)
  druidInfo1:SetText('If you are a druid and want ZoneMount to revert')
  y = y - 16

  local druidInfo2 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  druidInfo2:SetJustifyV('TOP')
  druidInfo2:SetJustifyH('LEFT')
  druidInfo2:SetPoint('TOPLEFT', 40, y)
  druidInfo2:SetText('to your basic form so you can mount automatically,')
  y = y - 16

  local druidInfo3 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  druidInfo3:SetJustifyV('TOP')
  druidInfo3:SetJustifyH('LEFT')
  druidInfo3:SetPoint('TOPLEFT', 40, y)
  druidInfo3:SetText('insert the following line at the start of your ZoneMount macro:')
  y = y - 24

  local druidInfo4 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  druidInfo4:SetJustifyV('TOP')
  druidInfo4:SetJustifyH('LEFT')
  druidInfo4:SetPoint('TOPLEFT', 100, y)
  druidInfo4:SetText('/cancelform')

  y = -60
  local addIgnoreTitle = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  addIgnoreTitle:SetJustifyV('TOP')
  addIgnoreTitle:SetJustifyH('LEFT')
  addIgnoreTitle:SetPoint('TOPLEFT', 400, y)
  addIgnoreTitle:SetText('Toggle Ignore:')

  y = y - 16
  local clearIgnoresBtn = CreateFrame("Button", nil, ZoneMount.panel, "UIPanelButtonTemplate")
	clearIgnoresBtn:SetSize(100,26)
	clearIgnoresBtn:SetText('Clear Ignores')
  clearIgnoresBtn:SetPoint('TOPLEFT', 510, y)
  clearIgnoresBtn.tooltipTitle = 'Clear your ignore list.'
  clearIgnoresBtn.tooltipBody = 'All the names in your ignore list will be deleted.'
  clearIgnoresBtn:SetScript("OnClick",function() 
    zoneMountSettings.ignores = {}
    ZoneMount_ignoresList:SetText(ZoneMount_ListIgnores())
  end)

  local addIgnoreBox = CreateFrame('editbox', nil, ZoneMount.panel, 'InputBoxTemplate')
  addIgnoreBox:SetPoint('TOPLEFT', 400, y)
  addIgnoreBox:SetHeight(20)
  addIgnoreBox:SetWidth(100)
  addIgnoreBox:SetText('')
  addIgnoreBox:SetAutoFocus(false)
  addIgnoreBox:ClearFocus()
  addIgnoreBox:SetScript('OnEnterPressed', function(self)
    self:SetAutoFocus(false) -- Clear focus when enter is pressed because ketho said so
    self:ClearFocus()
    ZoneMount_IgnoreMount(self:GetText())
    self:SetText('')
  end)
  y = y - 40

  ZoneMount_ignoresList = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  ZoneMount_ignoresList:SetJustifyV('TOP')
  ZoneMount_ignoresList:SetJustifyH('LEFT')
  ZoneMount_ignoresList:SetHeight(180)
  ZoneMount_ignoresList:SetWidth(120)
  ZoneMount_ignoresList:SetPoint('TOPLEFT', 400, y)
  ZoneMount_ignoresList:SetText(ZoneMount_ListIgnores())
end

function ZoneMount_IgnoreMount(name)
  if #name < 3 then
    ZoneMount_displayMessage("|c0000FF00ZoneMount |c0000FFFFIgnore name must be at least 3 characters.")
    return
  end

  if not zoneMountSettings.ignores then
    zoneMountSettings.ignores = {}
  end
  

  if #zoneMountSettings.ignores >= 14 then
    ZoneMount_displayMessage("|c0000FF00ZoneMount |c0000FFFFYou can only add 14 names to the ignore list.")
    return
  end
  
  local haveRemoved = false
  local afterRemove = {}
  local testName = string.lower(name)

  for n = 1, #zoneMountSettings.ignores do
    local ignoreName = string.lower(zoneMountSettings.ignores[n])
    if ignoreName == testName then
      haveRemoved = true
    else
      afterRemove[#afterRemove + 1] = zoneMountSettings.ignores[n]
    end
  end

  if haveRemoved then
    zoneMountSettings.ignores = afterRemove
  else
    zoneMountSettings.ignores[#zoneMountSettings.ignores + 1] = name
  end

  ZoneMount_ignoresList:SetText(ZoneMount_ListIgnores())
end

function ZoneMount_ListIgnores()
  if not zoneMountSettings.ignores then
    zoneMountSettings.ignores = {}
    return 'Type a name or partial name above to ignore any mount whose name contains that text (case-insensitive).\n\nEnter the same text again to remove it from the list.'
  end

  -- trim empties or shorts
  local afterRemove = {}
  for n = 1, #zoneMountSettings.ignores do
    if #zoneMountSettings.ignores[n] >= 3 then
      afterRemove[#afterRemove + 1] = zoneMountSettings.ignores[n]
    end
  end
  zoneMountSettings.ignores = afterRemove

  local ignoreText = ''
  for n = 1, #zoneMountSettings.ignores do
    ignoreText = ignoreText .. zoneMountSettings.ignores[n] .. '\n'
  end
  ignoreText = ignoreText:sub(1, -2)

  if #ignoreText == 0 then
    return 'Type a name or partial name above to ignore any mount whose name contains that text (case-insensitive).\n\nEnter the same text again to remove it from the list.'
  end
  return ignoreText 
end