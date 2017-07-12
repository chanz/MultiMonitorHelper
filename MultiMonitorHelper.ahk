;Start(){
	;#######################################################
	;
	;	Setups
	;
	;#######################################################
	#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
	#Persistent
	#WinActivateForce
	#InstallKeybdHook
	#UseHook On
	#Hotstring SP
	SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
	SetKeyDelay, 0, 50
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	DetectHiddenWindows, Off

	CoordMode, Mouse, Screen
	CoordMode, tooltip, screen
	SetBatchLines, -1
	Process, Priority,, High

	;#######################################################
	;
	;	Constants
	;
	;#######################################################
	E_WINDOW_ALL_MINIMIZE := -1
	E_WINDOW_ALL_MAXIMIZE := 1

	;#######################################################
	;
	;	UserOptions
	;
	;#######################################################
	class UserOptions {

		OnlyActiveIfWindowIsFullscreen := 0
		HotkeyAllowTransition := "^+"
		HotkeyActiveAllowTransition := 1

		HotkeyMinimizeAllWindowsOnCurrentMonitor := "#d"
		HotkeyActiveMinimizeAllWindowsOnCurrentMonitor := 1
		
		ScanUI()
		{
			this.OnlyActiveIfWindowIsFullscreen := GuiGet("OnlyActiveIfWindowIsFullscreen")
			this.HotkeyAllowTransition := GuiGet("HotkeyAllowTransition")
			this.HotkeyActiveAllowTransition := GuiGet("HotkeyActiveAllowTransition")

			this.HotkeyMinimizeAllWindowsOnCurrentMonitor := GuiGet("HotkeyMinimizeAllWindowsOnCurrentMonitor")
			this.HotkeyActiveMinimizeAllWindowsOnCurrentMonitor := GuiGet("HotkeyActiveMinimizeAllWindowsOnCurrentMonitor")
		}
	}
	Opts := new UserOptions()

	;#######################################################
	;
	;	Globals
	;
	;#######################################################
	; Instead of polluting the default namespace with Globals, create our own Globals "namespace".
	class Globals {

		Set(name, value) {
			Globals[name] := value
		}

		Get(name, value_default="") {
			result := Globals[name]
			If (result == "") {
				result := value_default
			}
			return result
		}
	}

	Globals.Set("SettingsUIWidth", 600)
	Globals.Set("SettingsUIHeight", 230)


	; TODO Move this globals to the globals class
	bAllowTransition := false
	bAllMinimized := false
	;g_adtMinimizedWindows := 0
	g_iMinimizedWindowsCount := 0
	WH_MOUSE := 7
	WH_MOUSE_LL := 14

	;#######################################################
	;
	;	Add 'Callbacks'
	;
	;#######################################################
	OnExit, QuitScript

	;#######################################################
	;
	;	Start Timers
	;
	;#######################################################
	SetTimer, Timer_CheckMouseTrap, 10
	SetTimer, Timer_WaitForStartMenu, 1000
	SetTimer, Timer_CheckActiveWindow, 250

	;#######################################################
	;
	;	Setup Tray
	;
	;#######################################################
	Menu, Tray, NoStandard
	Menu, Tray, Add, % Globals.Get("SettingsUITitle", "Multi Monitor Helper"), ShowSettingsUI
	Menu, Tray, Add ; Separator
	Menu, Tray, Standard
	Menu, Tray, Default, % Globals.Get("SettingsUITitle", "Multi Monitor Helper")

	;#######################################################
	;
	;	Startup functions
	;
	;#######################################################
	;Taskbar bewegen ?!
	;WinMove, ahk_class Shell_TrayWnd, -1280, , 2560

	CreateSettingsUI()
	Sleep, 50
	ReadConfig()
	Sleep, 50
	UpdateSettingsUI()

return

;#######################################################
;
;	Hotkeys
;
;#######################################################
;#c::
;	WinGetActiveTitle, szTitle
;	Click
;	WinActivate, szTitle
;return

;#######################################################
;
;	GUI
;
;#######################################################
ShowSettingsUI()
{
	global
	SetTimer, ToolTipTimer, Off
	ToolTip
	SettingsUIWidth := Globals.Get("SettingsUIWidth", 545)
	SettingsUIHeight := Globals.Get("SettingsUIHeight", 710)
	SettingsUITitle := Globals.Get("SettingsUITitle", "Multi Monitor Helper")
	Gui, Show, w%SettingsUIWidth% h%SettingsUIHeight%, %SettingsUITitle%
}

CreateSettingsUI()
{
	Global
	
	; General
	GuiAddGroupBox("General", "x7 y+15 w585 h108 Section")

	; Note: window handles (hwnd) are only needed if a UI tooltip should be attached.

	;GuiAddCheckbox(Contents, PositionInfo, CheckedState=0, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
	GuiAddCheckbox("Only lock/trap mouse on the current monitor if a window is in fullscreen.", "xs10 ys20 w400 h30", Opts.OnlyActiveIfWindowIsFullscreen, "OnlyActiveIfWindowIsFullscreen", "OnlyActiveIfWindowIsFullscreenH")
	AddToolTip(OnlyActiveIfWindowIsFullscreenH, "If checked the script does nothing, unless there is a window in fullscreen on the current monitor where the mouse is.")
	
	
	GuiAddText("Allow Transition Hotkey:", "x17 yp+35 w160 h20 0x0100", "LblHotkeyAllowTransition", "LblHotkeyAllowTransitionH")
	AddToolTip(LblHotkeyAllowTransitionH, "If the mouse is locked/trapped on a monitor, you can still transition between monitors by pressing and holding down this hotkey.")
	GuiAddEdit(Opts.HotkeyAllowTransition, "x+1 yp-2 w50 h20", "HotkeyAllowTransition", "HotkeyAllowTransitionH")
	AddToolTip(HotkeyAllowTransitionH, "Default: ctrl + shift")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", Opts.HotkeyActiveAllowTransition, "HotkeyActiveAllowTransition", "HotkeyActiveAllowTransitionH")
	AddToolTip(HotkeyActiveAllowTransitionH, "Enable Hotkey.")

	GuiAddText("Minimize Windows Hotkey:", "x17 yp+35 w160 h20 0x0100", "LblHotkeyMinimizeAllWindowsOnCurrentMonitor", "LblHotkeyMinimizeAllWindowsOnCurrentMonitorH")
	AddToolTip(LblHotkeyMinimizeAllWindowsOnCurrentMonitorH, "With this hotkey, you can minimize all windows on the current monitor your mouse is. Any default Microsoft Windows hotkey will be disabled.")
	GuiAddEdit(Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor, "x+1 yp-2 w50 h20", "HotkeyMinimizeAllWindowsOnCurrentMonitor", "HotkeyMinimizeAllWindowsOnCurrentMonitorH")
	AddToolTip(HotkeyMinimizeAllWindowsOnCurrentMonitorH, "Default: win + d")
	GuiAddCheckbox("", "x+5 yp-6 w30 h30", Opts.HotkeyActiveMinimizeAllWindowsOnCurrentMonitor, "HotkeyActiveMinimizeAllWindowsOnCurrentMonitor", "HotkeyActiveMinimizeAllWindowsOnCurrentMonitorH")
	AddToolTip(HotkeyActiveMinimizeAllWindowsOnCurrentMonitorH, "Enable Hotkey.")


	Gui, Add, Link, x17 yp+38 w160 h20 cBlue, <a href="http://www.autohotkey.com/docs/Hotkeys.htm">Hotkey Options</a>


	GuiAddButton("&Defaults", "x287 yp+55 w80 h23", "SettingsUI_BtnDefaults")
	GuiAddButton("&OK", "Default x372 yp+0 w75 h23", "SettingsUI_BtnOK")
	GuiAddButton("&Cancel", "x452 yp+0 w80 h23", "SettingsUI_BtnCancel")
}


GuiSet(ControlID, Param3="", SubCmd="")
{
	If (!(SubCmd == "")) {
		GuiControl, %SubCmd%, %ControlID%, %Param3%
	} Else {
		GuiControl,, %ControlID%, %Param3%
	}
}

GuiGet(ControlID, DefaultValue="")
{
	curVal =
	GuiControlGet, curVal,, %ControlID%, %DefaultValue%
	return curVal
}

GuiAdd(ControlType, Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Param4="", GuiName="")
{
	Global
	Local av, ah, al
	av := StrPrefix(AssocVar, "v")
	al := StrPrefix(AssocLabel, "g")
	ah := StrPrefix(AssocHwnd, "hwnd")
	
	If (ControlType = "GroupBox") {
		Gui, Font, cDA4F49
		Options := Param4
	}
	Else {
		Options := Param4 . " BackgroundTrans "
	}		
	
	GuiName := (StrLen(GuiName) > 0) ? Trim(GuiName) . ":Add" : "Add"
	Gui, %GuiName%, %ControlType%, %PositionInfo% %av% %al% %ah% %Options%, %Contents%
	Gui, Font
}

GuiAddButton(Contents, PositionInfo, AssocLabel="", AssocVar="", AssocHwnd="", Options="", GuiName="")
{
	GuiAdd("Button", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddGroupBox(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("GroupBox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddCheckbox(Contents, PositionInfo, CheckedState=0, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("Checkbox", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, "Checked" . CheckedState . " " . Options, GuiName)
}

GuiAddText(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	; static controls like Text need "0x0100" added to their options for the tooltip to work
	; either add it always here or don't forget to add it manually when using this function
	GuiAdd("Text", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddEdit(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("Edit", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddHotkey(Contents, PositionInfo, AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	GuiAdd("Hotkey", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiAddDropDownList(Contents, PositionInfo, Selected="", AssocVar="", AssocHwnd="", AssocLabel="", Options="", GuiName="")
{
	; usage : add list items as a | delimited string, for example = "item1|item2|item3"
	ListItems := StrSplit(Contents, "|")
	Contents := ""
	Loop % ListItems.MaxIndex() {
		Contents .= Trim(ListItems[A_Index]) . "|"
		; add second | to mark pre-select list item
		If (Trim(ListItems[A_Index]) == Selected) {
			Contents .= "|"
		}
	}
	GuiAdd("DropDownList", Contents, PositionInfo, AssocVar, AssocHwnd, AssocLabel, Options, GuiName)
}

GuiUpdateDropdownList(Contents="", Selected="", AssocVar="", Options="", GuiName="") {
	GuiName := (StrLen(GuiName) > 0) ? Trim(GuiName) . ":" . AssocVar : "" . AssocVar
	
	If (StrLen(Contents) > 0) {
		; usage : add list items as a | delimited string, for example = "item1|item2|item3"
		ListItems := StrSplit(Contents, "|")
		; prepend the list with a pipe to re-create the list instead of appending it
		Contents := "|"
		Loop % ListItems.MaxIndex() {
			Contents .= Trim(ListItems[A_Index]) . "|"
			; add second | to mark pre-select list item
			If (Trim(ListItems[A_Index]) == Selected) {
				Contents .= "|"
			}
		}
		GuiControl, , %GuiName%, %Contents%
	}
	
	If (StrLen(Selected)) > 0 {
		; falls back to "ChooseString" if param3 is not an integer
		GuiControl, Choose, %GuiName% , %Selected%  	
	}	
}

AddToolTip(con, text, Modify=0){
	Static TThwnd, GuiHwnd
	TInfo =
	UInt := "UInt"
	Ptr := (A_PtrSize ? "Ptr" : UInt)
	PtrSize := (A_PtrSize ? A_PtrSize : 4)
	Str := "Str"
	; defines from Windows MFC commctrl.h
	WM_USER := 0x400
	TTM_ADDTOOL := (A_IsUnicode ? WM_USER+50 : WM_USER+4)           ; used to add a tool, and assign it to a control
	TTM_UPDATETIPTEXT := (A_IsUnicode ? WM_USER+57 : WM_USER+12)    ; used to adjust the text of a tip
	TTM_SETMAXTIPWIDTH := WM_USER+24                                ; allows the use of multiline tooltips
	TTF_IDISHWND := 1
	TTF_CENTERTIP := 2
	TTF_RTLREADING := 4
	TTF_SUBCLASS := 16
	TTF_TRACK := 0x0020
	TTF_ABSOLUTE := 0x0080
	TTF_TRANSPARENT := 0x0100
	TTF_PARSELINKS := 0x1000
	If (!TThwnd) {
		Gui, +LastFound
		GuiHwnd := WinExist()
		TThwnd := DllCall("CreateWindowEx"
					,UInt,0
					,Str,"tooltips_class32"
					,UInt,0
					,UInt,2147483648
					,UInt,-2147483648
					,UInt,-2147483648
					,UInt,-2147483648
					,UInt,-2147483648
					,UInt,GuiHwnd
					,UInt,0
					,UInt,0
					,UInt,0)
	}
	; TOOLINFO structure
	cbSize := 6*4+6*PtrSize
	uFlags := TTF_IDISHWND|TTF_SUBCLASS|TTF_PARSELINKS
	VarSetCapacity(TInfo, cbSize, 0)
	NumPut(cbSize, TInfo)
	NumPut(uFlags, TInfo, 4)
	NumPut(GuiHwnd, TInfo, 8)
	NumPut(con, TInfo, 8+PtrSize)
	NumPut(&text, TInfo, 6*4+3*PtrSize)
	NumPut(0,TInfo, 6*4+6*PtrSize)
	DetectHiddenWindows, On
	If (!Modify) {
		DllCall("SendMessage"
			,Ptr,TThwnd
			,UInt,TTM_ADDTOOL
			,Ptr,0
			,Ptr,&TInfo
			,Ptr)
		DllCall("SendMessage"
			,Ptr,TThwnd
			,UInt,TTM_SETMAXTIPWIDTH
			,Ptr,0
			,Ptr,A_ScreenWidth)
	}
	DllCall("SendMessage"
		,Ptr,TThwnd
		,UInt,TTM_UPDATETIPTEXT
		,Ptr,0
		,Ptr,&TInfo
		,Ptr)

}

GetScreenInfo()
{
	SysGet, TotalScreenWidth, 78
	SysGet, TotalscreenHeight, 79
	SysGet, MonitorCount, 80

	Globals.Set("MonitorCount", MonitorCount)
	Globals.Set("TotalScreenWidth", TotalScreenWidth)
	Globals.Set("TotalScreenHeight", TotalscreenHeight)
}

;#######################################################
;	GUI Labels
;#######################################################
ShowSettingsUI:
	ReadConfig()
	Sleep, 50
	UpdateSettingsUI()
	Sleep, 50
	ShowSettingsUI()
return

SettingsUI_BtnOK:
	Global Opts
	Gui, Submit
	Sleep, 50
	WriteConfig()
	UpdateSettingsUI()
return

SettingsUI_BtnCancel:
	Gui, Cancel
return

SettingsUI_BtnDefaults:
	Gui, Cancel
	RemoveConfig()
	Sleep, 75
	CopyDefaultConfig()
	Sleep, 75
	ReadConfig()
	Sleep, 75
	UpdateSettingsUI()
	ShowSettingsUI()
return

;#######################################################
;	GUI Timers
;#######################################################
; Tick every 100 ms
; Remove tooltip if mouse is moved or 5 seconds pass
ToolTipTimer:
	Global Opts, ToolTipTimeout
	ToolTipTimeout += 1
	MouseGetPos, CurrX, CurrY
	MouseMoved := (CurrX - X) ** 2 + (CurrY - Y) ** 2 > Opts.MouseMoveThreshold ** 2
	If (MouseMoved or ((UseTooltipTimeout == 1) and (ToolTipTimeout >= Opts.ToolTipTimeoutTicks)))
	{
		SetTimer, ToolTipTimer, Off
		ToolTip
	}
	return


;#######################################################
;
;	Settings INI
;
;#######################################################
UpdateSettingsUI()
{
	Global

	GuiControl,, OnlyActiveIfWindowIsFullscreen, % Opts.OnlyActiveIfWindowIsFullscreen
	GuiControl,, HotkeyAllowTransition, % Opts.HotkeyAllowTransition
	GuiControl,, HotkeyActiveAllowTransition, % Opts.HotkeyActiveAllowTransition

	GuiControl,, HotkeyMinimizeAllWindowsOnCurrentMonitor, % Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor
	GuiControl,, HotkeyActiveMinimizeAllWindowsOnCurrentMonitor, % Opts.HotkeyActiveMinimizeAllWindowsOnCurrentMonitor

	if (Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor != "")
	{
		if (Opts.HotkeyActiveMinimizeAllWindowsOnCurrentMonitor == 1)
		{
			Hotkey, % Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor, HotkeyPressed_MinimizeAllWindowsOnCurrentMonitor
			Hotkey, % Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor, On
		}
		else {
			Hotkey, % Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor, Off
		}
	}
	
}

ReadConfig(ConfigPath="config.ini")
{
	Global
	IfExist, %ConfigPath%
	{
		; General

		Opts.OnlyActiveIfWindowIsFullscreen := IniRead(ConfigPath, "General", "OnlyActiveIfWindowIsFullscreen", Opts.OnlyActiveIfWindowIsFullscreen)
		Opts.HotkeyAllowTransition := IniRead(ConfigPath, "General", "HotkeyAllowTransition", Opts.HotkeyAllowTransition)
		Opts.HotkeyActiveAllowTransition := IniRead(ConfigPath, "General", "HotkeyActiveAllowTransition", Opts.HotkeyActiveAllowTransition)

		Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor := IniRead(ConfigPath, "General", "HotkeyMinimizeAllWindowsOnCurrentMonitor", Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor)
		Opts.HotkeyActiveMinimizeAllWindowsOnCurrentMonitor := IniRead(ConfigPath, "General", "HotkeyActiveMinimizeAllWindowsOnCurrentMonitor", Opts.HotkeyActiveMinimizeAllWindowsOnCurrentMonitor)
	}
	else {
		Msgbox, Error: Can't read from config file %ConfigPath%.
	}
}

WriteConfig(ConfigPath="config.ini")
{
	Global
	Opts.ScanUI()

	; General

	IniWrite(Opts.OnlyActiveIfWindowIsFullscreen, ConfigPath, "General", "OnlyActiveIfWindowIsFullscreen")
	IniWrite(Opts.HotkeyAllowTransition, ConfigPath, "General", "HotkeyAllowTransition")
	IniWrite(Opts.HotkeyActiveAllowTransition, ConfigPath, "General", "HotkeyActiveAllowTransition")

	IniWrite(Opts.HotkeyMinimizeAllWindowsOnCurrentMonitor, ConfigPath, "General", "HotkeyMinimizeAllWindowsOnCurrentMonitor")
	IniWrite(Opts.HotkeyActiveMinimizeAllWindowsOnCurrentMonitor, ConfigPath, "General", "HotkeyActiveMinimizeAllWindowsOnCurrentMonitor")
}

CopyDefaultConfig()
{
	FileCopy, %A_ScriptDir%\default_config.ini, %A_ScriptDir%\config.ini
}

RemoveConfig()
{
	FileDelete, %A_ScriptDir%\config.ini
}

IniRead(ConfigPath, Section_, Key, Default_)
{
	Result := ""
	IniRead, Result, %ConfigPath%, %Section_%, %Key%, %Default_%
	return Result
}

IniWrite(Val, ConfigPath, Section_, Key)
{
	IniWrite, %Val%, %ConfigPath%, %Section_%, %Key%
}

;#######################################################
;
;	Functions
;
;#######################################################
;#######################################################
;	API
;#######################################################
API_ClipCursor( Confine=true, x1=0 , y1=0, x2=1, y2=1 )
{
	VarSetCapacity(R,16,0),  NumPut(x1,&R+0),NumPut(y1,&R+4),NumPut(x2,&R+8),NumPut(y2,&R+12)
	Return Confine ? DllCall( "ClipCursor", UInt,&R ) : DllCall( "ClipCursor" )
}
;#######################################################
;	private
;#######################################################
ToggleWindowMinimizingAndRestoring(){
	
	global

	if( bAllMinimized == false )
	{
		SetAllWindowsOnCurrentMonitor(E_WINDOW_ALL_MINIMIZE)
	}
	else {
		SetAllWindowsOnCurrentMonitor(E_WINDOW_ALL_MAXIMIZE)
	}
	bAllMinimized := !bAllMinimized
}


SetAllWindowsOnCurrentMonitor(action)
{	
	global
	DetectHiddenWindows, Off
	;msgbox, % "action: " . action
	if(action == E_WINDOW_ALL_MINIMIZE)
	{

		;msgbox, secondary monitor: all windows minimize

		GetActiveMonitorBounds(MonitorLeft, MonitorTop, MonitorRight, MonitorBottom)
		ClearMinimizedWindows()
		winget, ids, list, , , Program Manager
		loop, %ids%
		{
		    stringtrimright, id, ids%a_index%, 0
		    WinGet, MinMaxState, MinMax, ahk_id %id%

		    if(MinMaxState == action)
		    {
		    	continue
		    }

		    g_bWinExists := WinExist("ahk_id " . id) == 0 ? false : true
		    if (!g_bWinExists) 
		    {
		    	continue
		    }
		    
		    wingettitle, title, ahk_id %id%

		    ; don't add windows with empty titles
		    if (title == "")
		    {
		        continue
		    }
		    
		    ;numwindows += 1

		    wingetpos, x, y, width, height, ahk_id %id%

		    ; Add 8 pixel to match even fullscreen windows, since they reach 8 pixels out of the screen
		    x := x+8
		    y := y+8

		    if(IsCoordinateInBounds(x, y, MonitorLeft, MonitorTop, MonitorRight, MonitorBottom))
		    {
		    	
		    	g_adtMinimizedWindows%g_iMinimizedWindowsCount% := id
		    	g_iMinimizedWindowsCount++
		    	
		    	;msgbox, % "Count: " . g_iMinimizedWindowsCount . "`nId: " . id . "`nadtId: " . g_adtMinimizedWindows%g_iMinimizedWindowsCount% . "`nName: " . title "`nMinMaxState: " MinMaxState "`ng_bWinExists: " g_bWinExists

		    	WinMinimize, ahk_id %id%
		    }
		}
		;traytip, There are %numwindows% windows on the screen (action: %action%).
	}
	else if(action == E_WINDOW_ALL_MAXIMIZE)
	{
		
		;msgbox, restoring all windows now (count: %g_iMinimizedWindowsCount%)
		Loop
		{
			ahkidTargetWindow := g_adtMinimizedWindows%g_iMinimizedWindowsCount%
			;traytip,, % "pos: " . A_Index . "; id: " . ahkidTargetWindow
			WinRestore, ahk_id %ahkidTargetWindow%

			g_iMinimizedWindowsCount--
			
			if (g_iMinimizedWindowsCount < 0)
			{
				break
			}
		}
	}
}

ClearMinimizedWindows() {

	global
	Loop, %g_iMinimizedWindowsCount%
	{
		g_adtMinimizedWindows%A_Index% := -1
	}
	g_iMinimizedWindowsCount := 0
}

TrapMouseOnCurrentMonitor(Activate=True) {
	if (Activate == False)
	{

		API_ClipCursor(False)
		return
	}

	GetActiveMonitorBounds(MonitorLeft, MonitorTop, MonitorRight, MonitorBottom)

	API_ClipCursor(True, MonitorLeft, MonitorTop, MonitorRight, MonitorBottom)
}

IsPrimaryMonitorActive() {
	
	SysGet, MonitorPrimär, MonitorPrimary
	SysGet, Monitor, Monitor, %MonitorPrimär%

	MouseGetPos, iMouseX, iMouseY

    if(IsCoordinateInBounds(iMouseX, iMouseY, MonitorLeft, MonitorTop, MonitorRight, MonitorBottom)) {
    	return true
    }
	return false
}

GetActiveMonitorBounds(ByRef MonitorLeft, ByRef MonitorTop, ByRef MonitorRight, ByRef MonitorBottom) {
	
	MouseGetPos, iMouseX, iMouseY

	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
	    SysGet, Monitor, Monitor, %A_Index%

	    if(IsCoordinateInBounds(iMouseX, iMouseY, MonitorLeft, MonitorTop, MonitorRight, MonitorBottom))
	    {
	    	break
	    }
	}
}

IsCoordinateInBounds(x, y, MonitorLeft, MonitorTop, MonitorRight, MonitorBottom) {

	if(MonitorLeft > x || x >= MonitorRight)
	{
		return False
	}

	if(MonitorTop > y || y >= MonitorBottom)
	{
		return false
	}

	return true
}

MoveMouseInBounds(x, y, maxLeft, maxTop, maxRight, maxBottom) {

	if(maxLeft > x)
	{
		MouseMove, maxLeft+1, y
		return true
	}

	if(x >= maxRight)
	{
		MouseMove, maxRight-1,y 
		return true
	}

	if(maxTop > y)
	{
		MouseMove, x, maxTop+1
		return true
	}

	if(y >= maxBottom)
	{
		MouseMove, x, maxBottom-1
		return true
	}

	return false
}

GetHotkeyState(hotkey) {

	;StringReplace hotkey, hotkey, +, % "Shift"
	;StringReplace hotkey, hotkey, ^, % "Ctrl"
	;StringReplace hotkey, hotkey, !, % "Alt"

	Loop, Parse, hotkey
	{
		if (A_LoopField == "+") {
			key%A_Index% := "Shift"
		}
		else if (A_LoopField == "^") {
			key%A_Index% := "Ctrl"
		}
		else if (A_LoopField == "!") {
			key%A_Index% := "Alt"
		}
		else if (A_LoopField == "#") {
			key%A_Index% := "Win"
		}
		else {
			key%A_Index% = A_LoopField
		}

		;tooltip, % "hotkey: " hotkey "`nA_LoopField: " A_LoopField "`nkey: " key%A_Index%

		if (!GetKeyState(key%A_Index%))
		{
			return false
		}
	}

	return true
}

;#######################################################
;
;	'Callbacks'
;
;#######################################################
QuitScript:
	TrapMouseOnCurrentMonitor(False)
	ExitAPP
return

HotkeyPressed_MinimizeAllWindowsOnCurrentMonitor:

	; Minimize all only on the active monitor
	ToggleWindowMinimizingAndRestoring()
return

;#######################################################
;
;	Timers
;
;#######################################################
Timer_WaitForStartMenu:
	
	Loop
	{
		WinWaitActive, ahk_class DV2ControlHost
		if(!IsPrimaryMonitorActive()){
			GetActiveMonitorBounds(MonitorLeft, MonitorTop, MonitorRight, MonitorBottom)
			WinGetPos,,,, StartMenu_Height
			WinMove, MonitorLeft, MonitorBottom-StartMenu_Height
		}
	}
return

Timer_CheckActiveWindow:

	if (Opts.OnlyActiveIfWindowIsFullscreen) {
		WinGet, g_hWndActive_id, ID, A
		g_bIsWindowInFullscreen := IsWindowFullScreen(g_hWndActive_id)

		; if the user chooses to leave the hotkey for transition empty or disabled it, then we must make sure the user is pinned on the monitor where the window is.
		if (!Opts.HotkeyActiveAllowTransition && g_bIsWindowInFullscreen) {
		;if (!Opts.HotkeyActiveAllowTransition) { ; easier to test with...
			
			; if the mouse is out of bounds move it back and then lock/trap the mouse on the monitor.
			WinGetPos, xWin, yWin, wWin, hWin, ahk_id %g_hWndActive_id%,,,
			MouseGetPos, xMouse, yMouse

			MoveMouseInBounds(xMouse, yMouse, xWin, yWin, xWin+wWin, yWin+hWin)
		}

		Globals.Set("WindowIsInFullscreen", g_bIsWindowInFullscreen)
	}

	;tooltip, % "GlobalsGet WindowsIsInFullscreen: " Globals.Get("WindowIsInFullscreen")
	
return

Timer_CheckMouseTrap:
	
	bAllowTransition := true

	if (Opts.OnlyActiveIfWindowIsFullscreen) {
		if (Globals.Get("WindowIsInFullscreen"))
		{
			if (Opts.HotkeyActiveAllowTransition) {
				bAllowTransition := GetHotkeyState(HotkeyAllowTransition)
			}
			else {
				bAllowTransition := false
			}
		}
	}
	else {
		if (Opts.HotkeyActiveAllowTransition) {

			;Transition between monitors only if the hotkey is pressed right now
			bAllowTransition := GetHotkeyState(HotkeyAllowTransition)
		}
	}

	;traytip,, % "bAllowTransition: " bAllowTransition
	TrapMouseOnCurrentMonitor(!bAllowTransition)

return

;#######################################################
;
;	Helper Functions
;
;#######################################################
; Prefix a string s with another string prefix.
; Does nothing if s is already prefixed.
StrPrefix(s, prefix) {
	If (s == "") {
		return ""
	} Else {
		If (SubStr(s, 1, StrLen(prefix)) == prefix) {
			return s ; Nothing to do
		} Else {
			return prefix . s
		}
	}
}

SetWindowBorderLess(Title) {

	WinSet, Style, -0xC00000, %Title% ; remove the titlebar and border(s)
	WinMove, %Title%, , 0, 0, (A_ScreenWidth), (A_ScreenHeight) ; move the window to 0,0 and reize it to the screen/monitor size
}


IsWindowFullScreen(winID) {
	;checks if the specified window is full screen

	WinGet style, Style, ahk_id %WinID%
	WinGetPos,,,winW,winH, ahk_id %WinID%
	; 0x800000 is WS_BORDER.
	; 0x20000000 is WS_MINIMIZE.
	; no border and not minimized
	Return ((style & 0x20800000) or winH < A_ScreenHeight or winW < A_ScreenWidth) ? false : true
}
