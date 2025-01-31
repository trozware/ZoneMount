
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

function ZoneMount_IsUnderwater()
  local timer, initial, maxvalue, scale, paused, label = GetMirrorTimerInfo(2)
  -- print('Checking for underwater: timer = ' .. timer .. ' Scale = ' .. scale .. ' Paused = ' .. paused)
  if timer == 'BREATH' and paused == 0 and scale < 0 then
    return true
  end
  return false
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
  if IsAdvancedFlyableArea() and IsOutdoors() then
    return true
  end
  return false

  -- local spellID = 376777
  -- local isUsable = C_Spell.IsSpellUsable(spellID)
  -- return isUsable
end
