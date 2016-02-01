-- @Author: Admin
-- @Date:   2015-12-13 09:39:52
-- @Last Modified by:   Webster
-- @Last Modified time: 2016-02-01 13:14:51
local tinsert = table.insert
 -- stack overflow
local function GetUIStru(ui)
	local data = {}
	local function GetInfo(ui)
		local szType = ui:GetType()
		local szName = ui:GetName()
		local bIsWnd = szType:sub(1, 3) == "Wnd"
		local bChild, hChildItem
		if bIsWnd then
			bChild     = ui:GetFirstChild() ~= nil
			hChildItem = ui:Lookup("", "")
		elseif szType == "Handle" then
			bChild = ui:Lookup(0) ~= nil
		end
		local dat = {
			___id  = ui, -- ui metatable
			aPath  = { ui:GetTreePath() },
			szType = szType,
			szName = szName,
			aChild = (bChild or hChildItem) and {} or nil
		}
		return dat, bIsWnd, bChild, hChildItem
	end
	local function GetItemStru(ui, tab)
		local dat, bIsWnd, bChild = GetInfo(ui)
		tinsert(tab, dat)
		if bChild then
			local i = 0
			while ui:Lookup(i) do
				local frame = ui:Lookup(i)
				GetItemStru(frame, dat.aChild)
				i = i + 1
			end
		end
	end
	local function GetWinStru(ui, tab)
		local dat, bIsWnd, bChild, hChildItem = GetInfo(ui)
		tinsert(tab, dat)
		if hChildItem then
			GetItemStru(hChildItem, dat.aChild)
		end
		if bChild then
			local aChild = tab[#tab]
			local frame = ui:GetFirstChild()
			while frame do
				local dat, bIsWnd = GetInfo(frame)
				if bIsWnd then
					GetWinStru(frame, aChild.aChild)
				else
					GetItemStru(frame, aChild.aChild)
				end
				frame = frame:GetNext()
			end
		end
	end
	local dat, bIsWnd, bChild = GetInfo(ui)
	if bIsWnd then
		GetWinStru(ui, data)
	else
		GetItemStru(ui, data)
	end
	-- SaveLUAData("interface/ui.jx3dat", data, "\t", false)
	return data
end

local UI_INIFILE = "interface/UIEditor/UIEditor.ini"
local UI_ANCHOR  = { s = "CENTER", r = "CENTER", x = 0, y = 0 }
local UI = {}
UIEditor = {}

function UIEditor.OnFrameCreate()
	this:RegisterEvent("UI_SCALED")
	this.hNode    = this:CreateItemData(UI_INIFILE, "TreeLeaf_Node")
	this.hContent = this:CreateItemData(UI_INIFILE, "TreeLeaf_Content")
	this.hList    = this:Lookup("WndScroll_Tree", "")
	this.hUIPos   = this:Lookup("", "Image_UIPos")
	this.hList:Clear()
	local a = UI_ANCHOR
	this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
end

function UIEditor.OnEvent(szEvent)
	if szEvent == "UI_SCALED" then
		local a = UI_ANCHOR
		this:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
	end
end

function UIEditor.OnFrameDragEnd()
	UI_ANCHOR = GetFrameAnchor(this)
end

function UIEditor.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Select" then
		local menu = UI.GetMeun()
		local handle = this:Lookup("", "")
		local nX, nY = handle:GetAbsPos()
		local nW, nH = handle:GetSize()
		menu.nMiniWidth = handle:GetW()
		menu.x = nX
		menu.y = nY + nH
		PopupMenu(menu)
	elseif szName == "Btn_Close" then
		UI.CloseFrame()
	end
end

function UIEditor.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "TreeLeaf_Node" or szName == "TreeLeaf_Content" then
		if szName == "TreeLeaf_Node" then
			if this:IsExpand() then
				this:Collapse()
			else
				this:Expand()
			end
			this:GetParent():FormatAllItemPos()
		end
		local ui = this.dat.___id
		if ui and ui:IsValid() then
			local frame = UI.GetFrame()
			local edit = frame:Lookup("Edit_Log/Edit_Default")
			edit:SetText(GetPureText(table.concat(UI.GetTipInfo(ui))))
			edit:SetCaretPos(0)
		end
	end
end

function UIEditor.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "TreeLeaf_Node" or szName == "TreeLeaf_Content" then
		local ui = this.dat.___id
		if ui and ui:IsValid() then
			local szXml = table.concat(UI.GetTipInfo(ui))
			local x, y = Cursor:GetPos(true)
			local frame = OutputTip(szXml, 435, { x, y, 0, 0 }, ALW.RIGHT_LEFT)
			frame:StartMoving()
			return UI.SetUIPos(ui)
		end
	end
end
-- ReloadUIAddon()
function UIEditor.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "TreeLeaf_Node" or szName == "TreeLeaf_Content" then
		HideTip()
		return UI.SetUIPos(ui)
	end
end

function UI.SetUIPos(ui)
	local frame = UI.GetFrame()
	local hUIPos = frame:GetRoot().hUIPos
	if ui and ui:IsValid() then
		local x, y = ui:GetAbsPos()
		local w, h = ui:GetSize()
		hUIPos:SetSize(w, h)
		hUIPos:SetAbsPos(x, y)
		hUIPos:Show()
		if ui:IsVisible() then
			hUIPos:SetFrame(157)
		else
			hUIPos:SetFrame(158)
		end
	else
		hUIPos:Hide()
	end
end

function UI.GetTipInfo(ui)
	local xml = {
		GetFormatText("[" .. ui:GetName() .. "]\n", 65)
	}
	tinsert(xml, GetFormatText("Type: ", 67))
	tinsert(xml, GetFormatText(ui:GetType() .. "\n", 44))
	tinsert(xml, GetFormatText("Size: ", 67))
	tinsert(xml, GetFormatText(table.concat({ ui:GetSize() }, ", ") .. "\n", 44))
	local szPath1, szPath2 = ui:GetTreePath()
	tinsert(xml, GetFormatText("Path1: ", 67))
	tinsert(xml, GetFormatText(szPath1 .. "\n", 44))
	if szPath2 then
		tinsert(xml, GetFormatText("Path2: ", 67))
		tinsert(xml, GetFormatText(szPath2 .. "\n", 44))
	end
	tinsert(xml, GetFormatText("\n ---------- UI Table --------- \n\n", 67))
	for k, v in pairs(ui) do
		tinsert(xml, GetFormatText(k .. ": ", 67))
		tinsert(xml, GetFormatText(tostring(v) .. "\n", 44))
	end
	return xml
end

function UI.OpenFrame()
	return Wnd.OpenWindow(UI_INIFILE, "UIEditor")
end

function UI.CloseFrame()
	return Wnd.CloseWindow("UIEditor")
end

function UI.GetFrame()
	return Station.Lookup("Topmost/UIEditor")
end
UI.IsOpend = UI.GetFrame
function UI.ToggleFrame()
	if UI.IsOpend() then
		UI.CloseFrame()
	else
		UI.OpenFrame()
	end
end

function UI.GetMeun()
	local menu = {}
	for k, v in ipairs({ "Lowest", "Lowest1", "Lowest2", "Normal", "Normal1", "Normal2", "Topmost", "Topmost1", "Topmost2" })do
		tinsert(menu, { szOption = v })
		local frame = Station.Lookup(v):GetFirstChild()
		while frame do
			local ui = frame
			tinsert(menu[#menu], {
				szOption = frame:GetName(),
				bCheck   = true,
				bChecked = frame:IsVisible(),
				rgb      = frame:IsAddOn() and { 255, 255, 255 } or { 255, 255, 0 },
				fnAction = function()
					UI.UpdateTree(ui)
					local frame = UI.GetFrame()
					frame:Lookup("Btn_Select", "Text_Select"):SetText(ui:GetTreePath())
					Wnd.CloseWindow(GetPopupMenu())
				end,
				fnMouseLeave = function()
					return UI.SetUIPos()
				end,
				fnMouseEnter = function()
					return UI.SetUIPos(ui)
				end,
			})
			frame = frame:GetNext()
		end
	end
	return menu
end

function UI.UpdateTree(ui)
	local data   = GetUIStru(ui)
	local frame  = UI.GetFrame()
	local handle = frame.hList
	handle:Clear()
	local nIndent = 0
	local function AppendTree(data, i)
		for k, v in ipairs(data) do
			local h
			if v.aChild then
				h = handle:AppendItemFromData(frame.hNode)
			else
				h = handle:AppendItemFromData(frame.hContent)
			end
			local txt = h:Lookup(0)
			txt:SetText(v.szName)
			h:SetIndent(i)
			h:FormatAllItemPos()
			h.dat = v
			if v.aChild then
				AppendTree(v.aChild, i + 1)
			end
		end
	end
	AppendTree(data, nIndent)
	handle:Lookup(0):Expand()
	handle:FormatAllItemPos()
end

TraceButton_AppendAddonMenu({{ szOption = "UIEditor", fnAction = UI.ToggleFrame }})
