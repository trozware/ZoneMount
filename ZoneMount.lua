-- ISSUES
---------
-- will summon Fathom Dweller at top of water and instantly dismount

ZoneMount = {} 

local ZoneMount_EventFrame = CreateFrame("Frame")
ZoneMount_EventFrame:RegisterEvent("VARIABLES_LOADED")
ZoneMount_EventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
ZoneMount_EventFrame:RegisterEvent("PLAYER_LOGIN")

ZoneMount_EventFrame:SetScript("OnEvent",
  function(self, event, ...)
    -- print(event)
    if event == "VARIABLES_LOADED" then
      ZoneMount:Initialize()
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
      -- print('Mount changed event')
    elseif event == "PLAYER_LOGIN" then
      ZoneMount_ShowWelcome()
    end  
  end
)

function ZoneMount:Initialize()
  SLASH_ZONEMOUNT1, SLASH_ZONEMOUNT2 = "/zonemount", "/zm"
  SlashCmdList["ZONEMOUNT"] = ZoneMountCommandHandler
end

function ZoneMountCommandHandler(msg) 
    if msg == 'mount' then
      ZoneMount_LookForMount()
    elseif msg == 'macro' then
      ZoneMount_CreateMacro()
    elseif msg == 'info' then
      ZoneMount_DisplayMessage("Current Status:", true)
      print('IsOutdoors = ', IsOutdoors())
      print('IsFlyableArea = ', IsFlyableArea())
      print('IsMounted = ', IsMounted())
      print('IsFlying = ', IsFlying())
      print('IsSubmerged = ', IsSubmerged())
      print('IsSwimming = ', IsSwimming())
      print('Preferred mount type = ', ZoneMount_TypeOfMountToSummon())
      print('=========================')
    elseif msg == '' then
      ZoneMount_DisplayHelp()
    else
      ZonePet_SearchForMount(msg)
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
    local msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFSummoning " .. "|c00FFD100" .. name
    if zone and zone ~= '' then
      msg = msg .. "|c0000FFFF from " .. zone.. "."
    end
    ChatFrame1:AddMessage(msg)

    if description and description ~= '' then
      ChatFrame1:AddMessage("|c0000FFFF" .. description)
    end
end

function ZoneMount_LookForMount()
  if ZoneMount_ShouldLookForNewMount() == 'no' then
    ZoneMount_DisplayMessage('Not a good time right now...', true)
    return
  end

  C_MountJournal.SetAllSourceFilters(true)
  C_MountJournal.SetCollectedFilterSetting(1, true)
  C_MountJournal.SetCollectedFilterSetting(2, false)
  C_MountJournal.SetSearch('')

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()
  -- print('Number of mounts = ', num_mounts)

  local mount_type = ZoneMount_TypeOfMountToSummon()
  -- print('Looking for ', mount_type, 'mount')
  if mount_type == 'none' then
    ZoneMount_DisplayMessage('Not a good place right now...', true)
    return
  end

  local mount_ids = C_MountJournal.GetMountIDs()
  -- print('Number of IDs', #mount_ids)

  local valid_mounts = {}
  for n = 1, num_mounts do
    mount_id = mount_ids[n]
    creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID = 
      C_MountJournal.GetDisplayedMountInfo(mount_id)

    if isUsable and isCollected then
      valid_mounts[#valid_mounts + 1] = { name = creatureName, ID = mountID }
    end
  end

  -- print('Number of valid mounts = ', #valid_mounts)

  local zone_mounts = {}
  local type_mounts = {}
  local zone_name = GetZoneText()
  local sub_zone_name = GetSubZoneText()

  for n = 1, #valid_mounts do
    mount_id = valid_mounts[n].ID
    creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
      uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
      = C_MountJournal.GetMountInfoExtraByID(mount_id)

    if ZoneMount_RightMountType(mount_type, mountTypeID) then
        type_mounts[#type_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = source }

        if string.find(source, zone_name) or string.find(source, sub_zone_name) then
          zone_mounts[#zone_mounts + 1] = { name = valid_mounts[n].name, ID = valid_mounts[n].ID, 
            description = description, source = source }
        end

        -- print(valid_mounts[n].name, mountTypeID)
        -- print(description)
        -- print(source)
        -- print('==================')
    end
  end
  -- print('Number of zone mounts = ', #zone_mounts)

  if #zone_mounts == 0 then
    zone_mounts = type_mounts
  end

  local mount_index, name, id, description, source

  if #zone_mounts == 1 and #type_mounts > 1 then
    -- add in at least one other valid mount if possible
    if #type_mounts < 3 then
      zone_mounts = type_mounts
    else
      local zone_name = zone_mounts[1].name
      repeat
        mount_index = math.random(#type_mounts)
        if type_mounts[mount_index].name ~= zone_name then
          zone_mounts[#zone_mounts + 1] = type_mounts[mount_index]
        end
      until #zone_mounts == 2
    end
  end

  repeat
    mount_index = math.random(#zone_mounts)
    name = zone_mounts[mount_index].name
    id = zone_mounts[mount_index].ID
    description = zone_mounts[mount_index].description
    source = zone_mounts[mount_index].source
  until ZoneMount_IsAlreadyMounted(name) == false or #zone_mounts == 1

  if string.find(source, zone_name) then
    ZoneMount_DisplaySummonMessage(name, zone_name, description)
  elseif string.find(source, sub_zone_name) then
    ZoneMount_DisplaySummonMessage(name, sub_zone_name, description)
  else
    ZoneMount_DisplaySummonMessage(name, '', description)
  end

  if ZoneMount_IsAlreadyMounted(name) == false then
    C_MountJournal.SummonByID(id)
  end
end

function ZoneMount_TypeOfMountToSummon()
  if IsIndoors() then
    return 'none'
  elseif IsSubmerged() or IsSwimming() then
    return 'water'
  elseif IsFlyableArea() then
    return 'flying'
  else
    return 'ground'
  end
end

function ZoneMount_ShouldLookForNewMount()
  if UnitIsFeignDeath("player") then
    return 'no'
  end

  spellName, _, _, _, _, _, _, _, _, _ = UnitCastingInfo("player")
  channelName, _, _, _, _, _, _, _ = UnitChannelInfo("player")
  inCombat = InCombatLockdown()
  isDead = UnitIsDeadOrGhost("player") or UnitIsFeignDeath("player")
  if inCombat == true or isDead == true or spellName ~= nil or channelName ~= nil or ZonePet_IsChannelling == true then
    return 'no'
  end

  if IsFlying() == true or 
    UnitInVehicle("player") == true or
    UnitOnTaxi("player") == true then
      return 'no'
  end

  return 'yes'
end

function ZoneMount_RightMountType(required_type, type_id)
  if required_type == 'water' then
    if type_id == 231 or type_id == 254 then
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

function ZonePet_SearchForMount(search_name)
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
    mount_id = mount_ids[n]
    creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID = 
      C_MountJournal.GetDisplayedMountInfo(mount_id)

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
  elseif #goodMatch > 0 then
    mount_index = math.random(#goodMatch)
    matching_id = goodMatch[mount_index].ID
    matching_name = goodMatch[mount_index].name
  elseif #fairMatch > 0 then
    mount_index = math.random(#fairMatch)
    matching_id = fairMatch[mount_index].ID
    matching_name = goodMatch[mount_index].name
  end

  if matching_id ~= nil then
    ZoneMount_DisplayMessage('Summoning ' .. matching_name, true)
    C_MountJournal.SummonByID(matching_id)
  else
    ZoneMount_DisplayMessage("|c0000FF00ZoneMount: " .. "|c0000FFFFCan't find a mount with a name like |c00FFD100" .. search_name .. ".")
  end
end

function ZoneMount_DisplayHelp()
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm mount|c0000FFFF to summon an appropriate mount."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zp _name_|c0000FFFF to search for a mount by name."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zp macro|c0000FFFF to create a ZoneMount macro action button."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zp info|c0000FFFF to show some debug info."
  ChatFrame1:AddMessage(msg)
end

function ZoneMount_IsAlreadyMounted(mount_name)
  for i= 1, 40 do 
    name, icon, count, debuffType, duration, expirationTime, source, isStealable, 
      nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, 
      nameplateShowAll, timeMod, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 
      = UnitAura('player', i)
    if name == mount_name then
      return true
    end
  end

  return false
end

function ZoneMount_CreateMacro()
  local existing_macro = GetMacroInfo('ZoneMount')
  if existing_macro then
    ZoneMount_DisplayMessage('Your ZoneMount macro already exists. Drag it into your action bar for easy access.', true)
    PickupMacro('ZoneMount')
    return
  end

  -- icon = 132226
  local macro_id = CreateMacro("ZoneMount", "132226", "/zm mount", nil, nil);
  if macro_id then
    ZoneMount_DisplayMessage('Your ZoneMount macro has been created. Drag it into your action bar for easy access.', true)
    PickupMacro('ZoneMount')
  else
    ZoneMount_DisplayMessage('There was a problem creating your ZoneMount macro.', true)
  end
end