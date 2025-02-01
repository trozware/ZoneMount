-- ISSUES
---------

-- add databroker to show in Titan Panel

-- When checking zone names, can I check by ID to avoid translation issues?

-- "Siren Isle" - High Winds debuff but only when mounted - no flying until later - how to detect?
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

ZoneMount_LastSummon = nil
ZoneMount_LastSummonTime = 0
ZoneMount_LastSummonName = ''
ZoneMount_DebugMode = false
ZoneMount_LastDismountCommand = nil
ZoneMount_HasMacroInstalled = false
ZoneMount_LastChatReport = 0

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
      ignores = {},
      shiftSwitchStyle = true,
      ctrlSwitchStyle = false,
      altSwitchStyle = false,
      shiftUseGround = false,
      ctrlUseGround = false,
      altUseGround = true,
      padZoneList = true
		}
  end

  if not zoneMountSettings.ignores then
    zoneMountSettings.ignores = {}
  end

  if zoneMountSettings.shiftSwitchStyle == false and zoneMountSettings.ctrlSwitchStyle == false and zoneMountSettings.altSwitchStyle == false then
    zoneMountSettings.shiftSwitchStyle = true
  end

  if zoneMountSettings.shiftUseGround == false and zoneMountSettings.ctrlUseGround == false and zoneMountSettings.altUseGround == false then
    zoneMountSettings.altUseGround = true
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
  local msg = "|c0000FF00Welcome to ZoneMount v" .. v .. ": " .. "|c0000FFFFType |c00FFD100/zm |c0000FFFFfor help."
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
      local max_attempts = #possibles
      local attempts = 0
      repeat
        attempts = attempts + 1
        mount_index = math.random(#possibles)
        matching_id = possibles[mount_index].ID
        matching_name = possibles[mount_index].name
      until (ZoneMount_IsAlreadyMounted(matching_name) == false or #possibles == 1 or attempts >= max_attempts)
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
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFHold down Shift while clicking the macro to toggle skyriding."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFHold down Alt while clicking the macro to summon a ground mount."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFType |cFFFFFFFF/zm do|c0000FFFF while on the ground to make your mount do its special action."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneMount: " .. "|c0000FFFFGo to Game menu - Options - Addons - ZoneMount to change settings."
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
      isFactionSpecific, faction, hideOnChar, isCollected, mountID, isSteadyFlight = 
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
  local editBox = ChatEdit_ChooseBoxForSend(DEFAULT_CHAT_FRAME) -- Get an edit box
  ChatEdit_ActivateChat(editBox) -- Show the edit box
  editBox:SetText("/mountspecial") -- Command goes here
  ChatEdit_OnEnterPressed(editBox) -- Process command and hide (runs ChatEdit_SendText() and ChatEdit_DeactivateChat() respectively)
end

function ZoneMount_InTable(tbl, item)
  for key, value in pairs(tbl) do
      if value == item then return key end
  end
  return false
end
