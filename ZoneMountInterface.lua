
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

  ZoneMount_btnShowChat = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	ZoneMount_btnShowChat:SetSize(26,26)
	ZoneMount_btnShowChat:SetHitRectInsets(-2,-200,-2,-2)
	ZoneMount_btnShowChat.text:SetText('  Show mount info in Chat')
	ZoneMount_btnShowChat.text:SetFontObject("GameFontNormal")
  ZoneMount_btnShowChat:SetPoint('TOPLEFT', 40, y)
  ZoneMount_btnShowChat:SetChecked(not zoneMountSettings.hideInfo)
  ZoneMount_btnShowChat:SetScript("OnClick",function() 
    local isChecked = ZoneMount_btnShowChat:GetChecked()
    zoneMountSettings.hideInfo = not isChecked
    ZoneMount_btnSlowChat:SetEnabled(not zoneMountSettings.hideInfo)
    if zoneMountSettings.hideInfo then
      ZoneMount_btnSlowChat.text:SetFontObject("GameFontDisable")
    else
      ZoneMount_btnSlowChat.text:SetFontObject("GameFontNormal")
    end
  end)
  y = y - 30
  
  ZoneMount_btnSlowChat = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  ZoneMount_btnSlowChat:SetSize(26,26)
	ZoneMount_btnSlowChat:SetHitRectInsets(-2,-200,-2,-2)
	ZoneMount_btnSlowChat.text:SetText('  Not more than once every 3 minutes')
  ZoneMount_btnSlowChat:SetPoint('TOPLEFT', 80, y)
  ZoneMount_btnSlowChat:SetChecked(zoneMountSettings.slowInfo)
  ZoneMount_btnSlowChat:SetEnabled(not zoneMountSettings.hideInfo)
  if zoneMountSettings.hideInfo then
    ZoneMount_btnSlowChat.text:SetFontObject("GameFontDisable")
  else
    ZoneMount_btnSlowChat.text:SetFontObject("GameFontNormal")
  end
  ZoneMount_btnSlowChat:SetScript("OnClick",function() 
    local isChecked = ZoneMount_btnSlowChat:GetChecked()
    zoneMountSettings.slowInfo = isChecked
    ZoneMount_LastChatReport = 0
  end)
  y = y - 40

  ZoneMount_btnWarn = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	ZoneMount_btnWarn:SetSize(26,26)
	ZoneMount_btnWarn:SetHitRectInsets(-2,-200,-2,-2)
	ZoneMount_btnWarn.text:SetText('  Show warnings in Chat')
	ZoneMount_btnWarn.text:SetFontObject("GameFontNormal")
  ZoneMount_btnWarn:SetPoint('TOPLEFT', 40, y)
  ZoneMount_btnWarn:SetChecked(not zoneMountSettings.hideWarnings)
  ZoneMount_btnWarn:SetScript("OnClick",function() 
    local isChecked = ZoneMount_btnWarn:GetChecked()
    zoneMountSettings.hideWarnings = not isChecked
  end)
  y = y - 40

  ZoneMount_btnFavs = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	ZoneMount_btnFavs:SetSize(26,26)
	ZoneMount_btnFavs:SetHitRectInsets(-2,-200,-2,-2)
	ZoneMount_btnFavs.text:SetText('  Select from Favorites only')
	ZoneMount_btnFavs.text:SetFontObject("GameFontNormal")
  ZoneMount_btnFavs:SetPoint('TOPLEFT', 40, y)
  ZoneMount_btnFavs:SetChecked(zoneMountSettings.favsOnly)
  ZoneMount_btnFavs:SetScript("OnClick",function() 
    local isChecked = ZoneMount_btnFavs:GetChecked()
    zoneMountSettings.favsOnly = isChecked
  end)
  y = y - 40
  
  ZoneMount_btnPad = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	ZoneMount_btnPad:SetSize(26,26)
	ZoneMount_btnPad:SetHitRectInsets(-2,-200,-2,-2)
	ZoneMount_btnPad.text:SetText('  Choose non-zone mounts sometimes,')
	ZoneMount_btnPad.text:SetFontObject("GameFontNormal")
  ZoneMount_btnPad:SetPoint('TOPLEFT', 40, y)
  ZoneMount_btnPad:SetChecked(zoneMountSettings.padZoneList)
  ZoneMount_btnPad:SetScript("OnClick",function() 
    local isChecked = ZoneMount_btnPad:GetChecked()
    zoneMountSettings.padZoneList = isChecked
  end)
  y = y - 24

  local padInfo1 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  padInfo1:SetJustifyV('TOP')
  padInfo1:SetJustifyH('LEFT')
  padInfo1:SetPoint('TOPLEFT', 70, y)
  padInfo1:SetText(' if you only have one mount from this zone')
  y = y - 40
  
  ZoneMount_btnSafe = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	ZoneMount_btnSafe:SetSize(26,26)
	ZoneMount_btnSafe:SetHitRectInsets(-2,-200,-2,-2)
	ZoneMount_btnSafe.text:SetText('  Disable flight-safety protocols,')
	ZoneMount_btnSafe.text:SetFontObject("GameFontNormal")
  ZoneMount_btnSafe:SetPoint('TOPLEFT', 40, y)
  ZoneMount_btnSafe:SetChecked(zoneMountSettings.flightSafetyDisabled)
  ZoneMount_btnSafe:SetScript("OnClick",function() 
    local isChecked = ZoneMount_btnSafe:GetChecked()
    zoneMountSettings.flightSafetyDisabled = isChecked
  end)
  y = y - 24

  local safeInfo = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  safeInfo:SetJustifyV('TOP')
  safeInfo:SetJustifyH('LEFT')
  safeInfo:SetPoint('TOPLEFT', 70, y)
  safeInfo:SetText(' Disabling allows you to instantly dismount on macro press')
  y = y - 60

  local shiftInfo1 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  shiftInfo1:SetJustifyV('TOP')
  shiftInfo1:SetJustifyH('LEFT')
  shiftInfo1:SetPoint('TOPLEFT', 40, y)
  shiftInfo1:SetText('Select the modifiers to toggle between skyriding & steady flying when clicking the macro button:')
  y = y - 16

  ZoneMount_btnShift = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  ZoneMount_btnShift:SetSize(26,26)
  ZoneMount_btnShift:SetHitRectInsets(-2,-60,-2,-2)
  ZoneMount_btnShift.text:SetText('  Shift')
  ZoneMount_btnShift.text:SetFontObject("GameFontNormal")
  ZoneMount_btnShift:SetPoint('TOPLEFT', 40, y)
  ZoneMount_btnShift:SetChecked(zoneMountSettings.shiftSwitchStyle)
  ZoneMount_btnShift:SetEnabled(not zoneMountSettings.shiftUseGround)
  if zoneMountSettings.shiftUseGround then
    ZoneMount_btnShift.text:SetFontObject("GameFontDisable")
  else
    ZoneMount_btnShift.text:SetFontObject("GameFontNormal")
  end
  ZoneMount_btnShift:SetScript("OnClick",function() 
    local isCheckedShift = ZoneMount_btnShift:GetChecked()
    zoneMountSettings.shiftSwitchStyle = isCheckedShift
    if isCheckedShift then
      zoneMountSettings.shiftUseGround = false
      ZoneMount_btnShift2:SetChecked(false)
    end
    ZoneMount_UpdateInterfaceModifiers()
  end)

  ZoneMount_btnCtrl = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  ZoneMount_btnCtrl:SetSize(26,26)
  ZoneMount_btnCtrl:SetHitRectInsets(-2,-60,-2,-2)
  ZoneMount_btnCtrl.text:SetText('  Ctrl')
  ZoneMount_btnCtrl.text:SetFontObject("GameFontNormal")
  ZoneMount_btnCtrl:SetPoint('TOPLEFT', 140, y)
  ZoneMount_btnCtrl:SetChecked(zoneMountSettings.ctrlSwitchStyle)
  ZoneMount_btnCtrl:SetEnabled(not zoneMountSettings.ctrlUseGround)
  if zoneMountSettings.ctrlUseGround then
    ZoneMount_btnCtrl.text:SetFontObject("GameFontDisable")
  else
    ZoneMount_btnCtrl.text:SetFontObject("GameFontNormal")
  end
  ZoneMount_btnCtrl:SetScript("OnClick",function() 
    local isCheckedCtrl = ZoneMount_btnCtrl:GetChecked()
    zoneMountSettings.ctrlSwitchStyle = isCheckedCtrl
    if isCheckedCtrl then
      zoneMountSettings.ctrlUseGround = false
      ZoneMount_btnCtrl2:SetChecked(false)
    end
    ZoneMount_UpdateInterfaceModifiers()
  end)

  ZoneMount_btnAlt = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  ZoneMount_btnAlt:SetSize(26,26)
  ZoneMount_btnAlt:SetHitRectInsets(-2,-60,-2,-2)
  ZoneMount_btnAlt.text:SetText('  Alt')
  ZoneMount_btnAlt.text:SetFontObject("GameFontNormal")
  ZoneMount_btnAlt:SetPoint('TOPLEFT', 240, y)
  ZoneMount_btnAlt:SetChecked(zoneMountSettings.altSwitchStyle)
  ZoneMount_btnAlt:SetEnabled(not zoneMountSettings.altUseGround)
  if zoneMountSettings.altUseGround then
    ZoneMount_btnAlt.text:SetFontObject("GameFontDisable")
  else
    ZoneMount_btnAlt.text:SetFontObject("GameFontNormal")
  end
  ZoneMount_btnAlt:SetScript("OnClick",function() 
    local isCheckedAlt = ZoneMount_btnAlt:GetChecked()
    zoneMountSettings.altSwitchStyle = isCheckedAlt
    if isCheckedAlt then
      zoneMountSettings.altUseGround = false
      ZoneMount_btnAlt2:SetChecked(false)
    end
    ZoneMount_UpdateInterfaceModifiers()
  end)
  y = y - 40

  local shiftInfo3 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  shiftInfo3:SetJustifyV('TOP')
  shiftInfo3:SetJustifyH('LEFT')
  shiftInfo3:SetPoint('TOPLEFT', 40, y)
  shiftInfo3:SetText('Select the modifiers to summon a ground mount:')
  y = y - 16

  ZoneMount_btnShift2 = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  ZoneMount_btnShift2:SetSize(26,26)
  ZoneMount_btnShift2:SetHitRectInsets(-2,-60,-2,-2)
  ZoneMount_btnShift2.text:SetText('  Shift')
  ZoneMount_btnShift2.text:SetFontObject("GameFontNormal")
  ZoneMount_btnShift2:SetPoint('TOPLEFT', 40, y)
  ZoneMount_btnShift2:SetChecked(zoneMountSettings.shiftUseGround)
  ZoneMount_btnShift2:SetEnabled(not zoneMountSettings.shiftSwitchStyle)
  if zoneMountSettings.shiftSwitchStyle then
    ZoneMount_btnShift2.text:SetFontObject("GameFontDisable")
  else
    ZoneMount_btnShift2.text:SetFontObject("GameFontNormal")
  end
  ZoneMount_btnShift2:SetScript("OnClick",function() 
    local isCheckedShift = ZoneMount_btnShift2:GetChecked()
    zoneMountSettings.shiftUseGround = isCheckedShift
    if isCheckedShift then
      zoneMountSettings.shiftSwitchStyle = false
      ZoneMount_btnShift:SetChecked(false)
    end
    ZoneMount_UpdateInterfaceModifiers()
  end)

  ZoneMount_btnCtrl2 = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  ZoneMount_btnCtrl2:SetSize(26,26)
  ZoneMount_btnCtrl2:SetHitRectInsets(-2,-60,-2,-2)
  ZoneMount_btnCtrl2.text:SetText('  Ctrl')
  ZoneMount_btnCtrl2.text:SetFontObject("GameFontNormal")
  ZoneMount_btnCtrl2:SetPoint('TOPLEFT', 140, y)
  ZoneMount_btnCtrl2:SetChecked(zoneMountSettings.ctrlUseGround)
  ZoneMount_btnCtrl2:SetEnabled(not zoneMountSettings.ctrlSwitchStyle)
  if zoneMountSettings.ctrlSwitchStyle then
    ZoneMount_btnCtrl2.text:SetFontObject("GameFontDisable")
  else
    ZoneMount_btnCtrl2.text:SetFontObject("GameFontNormal")
  end
  ZoneMount_btnCtrl2:SetScript("OnClick",function() 
    local isCheckedCtrl = ZoneMount_btnCtrl2:GetChecked()
    zoneMountSettings.ctrlUseGround = isCheckedCtrl
    if isCheckedCtrl then
      zoneMountSettings.ctrlSwitchStyle = false
      ZoneMount_btnCtrl:SetChecked(false)
    end
    ZoneMount_UpdateInterfaceModifiers()
  end)

  ZoneMount_btnAlt2 = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  ZoneMount_btnAlt2:SetSize(26,26)
  ZoneMount_btnAlt2:SetHitRectInsets(-2,-60,-2,-2)
  ZoneMount_btnAlt2.text:SetText('  Alt')
  ZoneMount_btnAlt2.text:SetFontObject("GameFontNormal")
  ZoneMount_btnAlt2:SetPoint('TOPLEFT', 240, y)
  ZoneMount_btnAlt2:SetChecked(zoneMountSettings.altUseGround)
  ZoneMount_btnAlt2:SetEnabled(not zoneMountSettings.altSwitchStyle)
  if zoneMountSettings.altSwitchStyle then
    ZoneMount_btnAlt2.text:SetFontObject("GameFontDisable")
  else
    ZoneMount_btnAlt2.text:SetFontObject("GameFontNormal")
  end
  ZoneMount_btnAlt2:SetScript("OnClick",function() 
    local isCheckedAlt = ZoneMount_btnAlt2:GetChecked()
    zoneMountSettings.altUseGround = isCheckedAlt
    if isCheckedAlt then
      zoneMountSettings.altSwitchStyle = false
      ZoneMount_btnAlt:SetChecked(false)
    end
    ZoneMount_UpdateInterfaceModifiers()
  end)
  y = y - 60

  -- local shiftInfo2 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  -- shiftInfo2:SetJustifyV('TOP')
  -- shiftInfo2:SetJustifyH('LEFT')
  -- shiftInfo2:SetPoint('TOPLEFT', 40, y)
  -- shiftInfo2:SetText('If your level is 10 - 19, you can skyride but not steady fly.')
  -- y = y - 40

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
  druidInfo3:SetText('duplicate the ZoneMount macro and insert this line at the start:')
  y = y - 20

  local druidInfo4 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  druidInfo4:SetJustifyV('TOP')
  druidInfo4:SetJustifyH('LEFT')
  druidInfo4:SetPoint('TOPLEFT', 100, y)
  druidInfo4:SetText('/cancelform')

  y = -60
  local addIgnoreTitle = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  addIgnoreTitle:SetJustifyV('TOP')
  addIgnoreTitle:SetJustifyH('LEFT')
  addIgnoreTitle:SetPoint('TOPLEFT', 440, y)
  addIgnoreTitle:SetText('Toggle Ignore:')

  y = y - 16
  local clearIgnoresBtn = CreateFrame("Button", nil, ZoneMount.panel, "UIPanelButtonTemplate")
	clearIgnoresBtn:SetSize(100,26)
	clearIgnoresBtn:SetText('Clear Ignores')
  clearIgnoresBtn:SetPoint('TOPLEFT', 550, y)
  clearIgnoresBtn.tooltipTitle = 'Clear your ignore list.'
  clearIgnoresBtn.tooltipBody = 'All the names in your ignore list will be deleted.'
  clearIgnoresBtn:SetScript("OnClick",function() 
    zoneMountSettings.ignores = {}
    ZoneMount_ignoresList:SetText(ZoneMount_ListIgnores())
  end)

  local addIgnoreBox = CreateFrame('editbox', nil, ZoneMount.panel, 'InputBoxTemplate')
  addIgnoreBox:SetPoint('TOPLEFT', 440, y)
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
  y = y - 24

  ZoneMount_ignoresList = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  ZoneMount_ignoresList:SetJustifyV('TOP')
  ZoneMount_ignoresList:SetJustifyH('LEFT')
  ZoneMount_ignoresList:SetHeight(180)
  ZoneMount_ignoresList:SetWidth(120)
  ZoneMount_ignoresList:SetPoint('TOPLEFT', 440, y)
  ZoneMount_ignoresList:SetText(ZoneMount_ListIgnores())
  y = y - 40
  
  local resetBtn = CreateFrame("Button", nil, ZoneMount.panel, "UIPanelButtonTemplate")
	resetBtn:SetSize(100,26)
	resetBtn:SetText('Reset Settings to Defaults')
  resetBtn:SetPoint('TOPLEFT', 40, -570)
  resetBtn:SetWidth(200)
  resetBtn.tooltipTitle = 'Reset all settings to the defaults.'
  resetBtn.tooltipBody = 'All the settings here will be reset to the defaults.'
  resetBtn:SetScript("OnClick",function() 
    ZoneMount_ResetSettings()
  end)
end

function ZoneMount_IgnoreMount(name)
  if #name < 3 then
    ZoneMount_DisplayMessage("|c0000FF00ZoneMount |c0000FFFFIgnore name must be at least 3 characters.")
    return
  end

  if not zoneMountSettings.ignores then
    zoneMountSettings.ignores = {}
  end
  

  if #zoneMountSettings.ignores >= 10 then
    ZoneMount_DisplayMessage("|c0000FF00ZoneMount |c0000FFFFYou can only add 10 names to the ignore list.")
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

function ZoneMount_ResetSettings()
  zoneMountSettings.resetCounter = 0
  ZoneMount_ApplyDefaultSettings()
  -- zoneMountSettings.ignores = {}
  -- ZoneMount_ignoresList:SetText(ZoneMount_ListIgnores())

  ZoneMount_btnShowChat:SetChecked(not zoneMountSettings.hideInfo)
  ZoneMount_btnSlowChat:SetChecked(zoneMountSettings.slowInfo)
  ZoneMount_btnWarn:SetChecked(not zoneMountSettings.hideWarnings)
  ZoneMount_btnFavs:SetChecked(zoneMountSettings.favsOnly)
  ZoneMount_btnPad:SetChecked(zoneMountSettings.padZoneList)
  ZoneMount_btnSafe:SetChecked(zoneMountSettings.flightSafetyDisabled)

  ZoneMount_UpdateInterfaceModifiers()
  ZoneMount_UpdateMacro()
end

function ZoneMount_UpdateInterfaceModifiers()
  if zoneMountSettings.shiftSwitchStyle == false and zoneMountSettings.ctrlSwitchStyle == false and zoneMountSettings.altSwitchStyle == false then
    zoneMountSettings.shiftSwitchStyle = true
    zoneMountSettings.shiftUseGround = false
  end
  if zoneMountSettings.shiftUseGround == false and zoneMountSettings.ctrlUseGround == false and zoneMountSettings.altUseGround == false then
    zoneMountSettings.altUseGround = true
    zoneMountSettings.altSwitchStyle = false

    -- repeat first check to trap if the second check was triggered
    if zoneMountSettings.shiftSwitchStyle == false and zoneMountSettings.ctrlSwitchStyle == false and zoneMountSettings.altSwitchStyle == false then
      zoneMountSettings.shiftSwitchStyle = true
      zoneMountSettings.shiftUseGround = false
    end
  end

  ZoneMount_btnShift:SetChecked(zoneMountSettings.shiftSwitchStyle)
  ZoneMount_btnShift:SetEnabled(not zoneMountSettings.shiftUseGround)
  if zoneMountSettings.shiftUseGround then
    ZoneMount_btnShift.text:SetFontObject("GameFontDisable")
    ZoneMount_btnShift:SetChecked(false)
  else
    ZoneMount_btnShift.text:SetFontObject("GameFontNormal")
  end

  ZoneMount_btnCtrl:SetChecked(zoneMountSettings.ctrlSwitchStyle)
  ZoneMount_btnCtrl:SetEnabled(not zoneMountSettings.ctrlUseGround)
  if zoneMountSettings.ctrlUseGround then
    ZoneMount_btnCtrl.text:SetFontObject("GameFontDisable")
    ZoneMount_btnCtrl:SetChecked(false)
  else
    ZoneMount_btnCtrl.text:SetFontObject("GameFontNormal")
  end

  ZoneMount_btnAlt:SetChecked(zoneMountSettings.altSwitchStyle)
  ZoneMount_btnAlt:SetEnabled(not zoneMountSettings.altUseGround)
  if zoneMountSettings.altUseGround then
    ZoneMount_btnAlt.text:SetFontObject("GameFontDisable")
    ZoneMount_btnAlt:SetChecked(false)
  else
    ZoneMount_btnAlt.text:SetFontObject("GameFontNormal")
  end

  ZoneMount_btnShift2:SetChecked(zoneMountSettings.shiftUseGround)
  ZoneMount_btnShift2:SetEnabled(not zoneMountSettings.shiftSwitchStyle)
  if zoneMountSettings.shiftSwitchStyle then
    ZoneMount_btnShift2.text:SetFontObject("GameFontDisable")
    ZoneMount_btnShift2:SetChecked(false)
  else
    ZoneMount_btnShift2.text:SetFontObject("GameFontNormal")
  end

  ZoneMount_btnCtrl2:SetChecked(zoneMountSettings.ctrlUseGround)
  ZoneMount_btnCtrl2:SetEnabled(not zoneMountSettings.ctrlSwitchStyle)
  if zoneMountSettings.ctrlSwitchStyle then
    ZoneMount_btnCtrl2.text:SetFontObject("GameFontDisable")
    ZoneMount_btnCtrl2:SetChecked(false)
  else
    ZoneMount_btnCtrl2.text:SetFontObject("GameFontNormal")
  end

  ZoneMount_btnAlt2:SetChecked(zoneMountSettings.altUseGround)
  ZoneMount_btnAlt2:SetEnabled(not zoneMountSettings.altSwitchStyle)
  if zoneMountSettings.altSwitchStyle then
    ZoneMount_btnAlt2.text:SetFontObject("GameFontDisable")
    ZoneMount_btnAlt2:SetChecked(false)
  else
    ZoneMount_btnAlt2.text:SetFontObject("GameFontNormal")
  end

  ZoneMount_UpdateMacro()
end
