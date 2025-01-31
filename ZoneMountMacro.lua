
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
  if InCombatLockdown() then
    return
  end

  local existing_macro = GetMacroInfo('ZoneMount')
  if existing_macro then
    local macroIndex = GetMacroIndexByName("ZoneMount")
    if macroIndex > 0 then
      local macroText = ZoneMount_MacroText()
      local currentText = GetMacroBody(macroIndex)
      if macroText ~= currentText then
        EditMacro(macroIndex, "ZoneMount", "136103", macroText, nil, nil)
      end
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
    local mods = ''
    if zoneMountSettings.shiftSwitchStyle then
      mods = mods .. '[mod:shift,noflying]'
    end
    if zoneMountSettings.ctrlSwitchStyle then
      mods = mods .. '[mod:ctrl,noflying]'
    end
    if zoneMountSettings.altSwitchStyle then
      mods = mods .. '[mod:alt,noflying]'
    end
    local macroText = "/quietcast\n/cast " .. mods .. " Switch Flight Style\n/zm mount"
    return macroText
  end
  local macroText = "/zm mount"
  return macroText
end
