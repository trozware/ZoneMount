function ZoneMount_CreateMacro()
  local existing_macro = GetMacroInfo("ZoneMount")
  if existing_macro then
    ZoneMount_HasMacroInstalled = true
    ZoneMount_DisplayMessage("Your ZoneMount macro already exists. Drag it into your action bar for easy access.", true)
    PickupMacro("ZoneMount")
    return
  end

  local macroText = ZoneMount_MacroText()
  local macro_id = CreateMacro("ZoneMount", "136103", macroText, nil, nil)
  if macro_id then
    ZoneMount_HasMacroInstalled = true
    ZoneMount_DisplayMessage(
      "Your ZoneMount macro has been created. Drag it into your action bar for easy access.",
      true
    )
    PickupMacro("ZoneMount")
  else
    ZoneMount_DisplayMessage("There was a problem creating your ZoneMount macro.", true)
  end
end

function ZoneMount_CreateRideAlongMacro()
  local existing_macro = GetMacroInfo("ZoneMount Ride Along")
  if existing_macro then
    ZoneMount_HasMacroInstalled = true
    ZoneMount_DisplayMessage(
      "Your ZoneMount Ride Along macro already exists. Drag it into your action bar for easy access.",
      true
    )
    PickupMacro("ZoneMount Ride Along")
    return
  end

  local macroText = "/zm ridealong"
  local macro_id = CreateMacro("ZoneMount Ride Along", "132226", macroText, nil, nil)
  if macro_id then
    ZoneMount_HasMacroInstalled = true
    ZoneMount_DisplayMessage(
      "Your ZoneMount Ride Along macro has been created. Drag it into your action bar for easy access.",
      true
    )
    PickupMacro("ZoneMount Ride Along")
  else
    ZoneMount_DisplayMessage("There was a problem creating your ZoneMount Ride Along macro.", true)
  end
end

function ZoneMount_UpdateMacro()
  if InCombatLockdown() or PlayerIsInCombat() then
    return
  end

  local existing_macro = GetMacroInfo("ZoneMount")
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

  local canBreakneck = ZoneMount_CanUseUndermineMount()
  local breakneckText = ""
  if canBreakneck then
    breakneckText = "/cast G-99 Breakneck\n"
  end

  if canSwitch then
    local clauses = {}
    if zoneMountSettings.shiftSwitchStyle then
      clauses[#clauses + 1] = "[mod:shift,noflying] Switch Flight Style"
    end
    if zoneMountSettings.ctrlSwitchStyle then
      clauses[#clauses + 1] = "[mod:ctrl,noflying] Switch Flight Style"
    end
    if zoneMountSettings.altSwitchStyle then
      clauses[#clauses + 1] = "[mod:alt,noflying] Switch Flight Style"
    end

    local castLine = ""
    if #clauses > 0 then
      castLine = "/cast " .. table.concat(clauses, "; ") .. "\n"
    end

    local macroText = "/quietcast\n" .. castLine .. breakneckText .. "/zm mount"
    return macroText
  end
  local macroText = "/quietcast\n" .. breakneckText .. "/zm mount"
  return macroText
end
