
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
  y = y - 40
  
  local btnPad = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
	btnPad:SetSize(26,26)
	btnPad:SetHitRectInsets(-2,-200,-2,-2)
	btnPad.text:SetText('  Add extras if you only have one mount from this zone')
	btnPad.text:SetFontObject("GameFontNormal")
  btnPad:SetPoint('TOPLEFT', 40, y)
  btnPad:SetChecked(zoneMountSettings.padZoneList)
  btnPad:SetScript("OnClick",function() 
    local isChecked = btnPad:GetChecked()
    zoneMountSettings.padZoneList = isChecked
  end)
  y = y - 70

  local shiftInfo1 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  shiftInfo1:SetJustifyV('TOP')
  shiftInfo1:SetJustifyH('LEFT')
  shiftInfo1:SetPoint('TOPLEFT', 40, y)
  shiftInfo1:SetText('Select the modifiers to toggle between skyriding & steady flying when clicking the macro button:')
  y = y - 16

  local btnShift = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  btnShift:SetSize(26,26)
  btnShift:SetHitRectInsets(-2,-60,-2,-2)
  btnShift.text:SetText('  Shift')
  btnShift.text:SetFontObject("GameFontNormal")
  btnShift:SetPoint('TOPLEFT', 40, y)
  btnShift:SetChecked(zoneMountSettings.shiftSwitchStyle)
  btnShift:SetScript("OnClick",function() 
    local isCheckedShift = btnShift:GetChecked()
    zoneMountSettings.shiftSwitchStyle = isCheckedShift
    ZoneMount_UpdateMacro()
  end)

  local btnCtrl = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  btnCtrl:SetSize(26,26)
  btnCtrl:SetHitRectInsets(-2,-60,-2,-2)
  btnCtrl.text:SetText('  Ctrl')
  btnCtrl.text:SetFontObject("GameFontNormal")
  btnCtrl:SetPoint('TOPLEFT', 140, y)
  btnCtrl:SetChecked(zoneMountSettings.ctrlSwitchStyle)
  btnCtrl:SetScript("OnClick",function() 
    local isCheckedCtrl = btnCtrl:GetChecked()
    zoneMountSettings.ctrlSwitchStyle = isCheckedCtrl
    ZoneMount_UpdateMacro()
  end)

  local btnAlt = CreateFrame("CheckButton", nil, ZoneMount.panel, "UICheckButtonTemplate")
  btnAlt:SetSize(26,26)
  btnAlt:SetHitRectInsets(-2,-60,-2,-2)
  btnAlt.text:SetText('  Alt')
  btnAlt.text:SetFontObject("GameFontNormal")
  btnAlt:SetPoint('TOPLEFT', 240, y)
  btnAlt:SetChecked(zoneMountSettings.altSwitchStyle)
  btnAlt:SetScript("OnClick",function() 
    local isCheckedAlt = btnAlt:GetChecked()
    zoneMountSettings.altSwitchStyle = isCheckedAlt
    ZoneMount_UpdateMacro()
  end)
  y = y - 40

  local shiftInfo4 = ZoneMount.panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
  shiftInfo4:SetJustifyV('TOP')
  shiftInfo4:SetJustifyH('LEFT')
  shiftInfo4:SetPoint('TOPLEFT', 40, y)
  shiftInfo4:SetText('The unchecked modifiers can be used to summon a ground mount no matter where you are.')
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
  shiftInfo3:SetText('For these levels, all modifiers will summon a ground mount.')
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
  druidInfo3:SetText('Duplicate the ZoneMount macro and insert this line at the start:')
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
