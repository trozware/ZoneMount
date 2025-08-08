function ZoneMount_Tests()
  ZoneMount_clearFilters()
  -- C_MountJournal.SetCollectedFilterSetting(2, true)
  -- C_MountJournal.SetCollectedFilterSetting(3, true)

  C_MountJournal.SetAllTypeFilters(true)
  C_MountJournal.SetTypeFilter(1, false)
  C_MountJournal.SetTypeFilter(2, false)
  C_MountJournal.SetTypeFilter(3, false)
  C_MountJournal.SetTypeFilter(4, true)

  local num_mounts = C_MountJournal.GetNumDisplayedMounts()

  -- local valid_mounts = ZoneMount_ValidMounts()
  -- print('Number of valid mounts = ', #valid_mounts)

  print('Number of filtered mounts = ', num_mounts)

  for n = 1, num_mounts do
    local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, 
      isFactionSpecific, faction, hideOnChar, isCollected, mountID, isSteadyFlight = 
      C_MountJournal.GetDisplayedMountInfo(n)
  --     -- if isSteadyFlight == true then
  --     --   print('Name', creatureName)
  --     --   print('ID', mountID)
  --     --   print('Type', mountTypeID)
  --     --   print('isSteadyFlight', isSteadyFlight)
  --     -- end

  --   -- if creatureName == 'Savage Blue Battle Turtle' then
  --   local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, 
  --   uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview 
  --   = C_MountJournal.GetMountInfoExtraByID(mountID)
    
  --   if mountTypeID == 231 then
        print('Name', creatureName)
  --     print('ID', mountID)
  --     print('Type', mountTypeID)
  --     print('Source type', sourceType)
  --     print('Source', source)
  --     print('Faction specific', isFactionSpecific)
  --     print('Faction', faction)
  --       print('isForSteadyFlight', isSteadyFlight)
  --       print('isForSteadyFlight', isSteadyFlight)
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
  --     -- print('isForSteadyFlight', isSteadyFlight)
  --     print('isForSteadyFlight', isSteadyFlight)
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
  --     -- print('isForSteadyFlight', isSteadyFlight)

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
  end
end
