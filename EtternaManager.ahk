; EtternaManager: supplemental scripts for Etterna.
; written by kurulen, 2023

#UseHook
InstallKeybdHook true true
DetectHiddenWindows true

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; non-modifiables
global FlushTimerIsActive := false
global MaxWidth
global MaxHeight
global HeightDecr
global FlushPeriod
global AggressiveOptims
global Tock := false
global SettingsFile := A_ScriptDir "\EttMgr.cfg"
if FileExist(SettingsFile) {
	Loop read, SettingsFile {
		Loop parse, A_LoopReadLine, "," {
			if A_Index == 1 {
				MaxWidth := Integer(A_LoopField)
			} else if A_Index == 2 {
				MaxHeight := Integer(A_LoopField)
			} else if A_Index == 3 {
				HeightDecr := Integer(A_LoopField)
			} else if A_Index == 4 {
				FlushPeriod := Integer(A_LoopField)
			} else if A_Index == 5 {
				AggressiveOptims := Integer(A_LoopField)
			}
		}
	}
}
FlushTimerPeriodDefault := 8192

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; timers
SetTimer FlushTimer, FlushTimerPeriodDefault
SetTimer ClearSBText, 2048

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; gui
global MyGui := Gui()
MyGui.Title := "EtternaManager v0.8.0"
global GuiTabs := MyGui.Add("Tab3",, ["About","Config"])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; about tab
GuiTabs.UseTab("About", true)

MyGui.AddText(, "EtternaManager is a trainer for Etterna.`nIt will not let you cheat, but it can fix graphical issues.")

global FlushBtn := MyGui.AddButton("Default w80", "Toggle timer")
FlushBtn.OnEvent("Click", FlushTimerStart)

MyGui.AddText(, "Written in AutoHotkey v2 by kurulen, 2023.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; config tab
GuiTabs.UseTab("Config", true)

global vAggrOpts := MyGui.AddCheckBox("vAggrOpts", "Enable aggressive window optimizations?")

MyGui.AddText(, "Your monitor's width in pixels:")
global vWidthMax := MyGui.AddEdit("r1 vWidthMax w40","")
vWidthMax.Opt("+Limit +Number")

MyGui.AddText(, "Your monitor's height in pixels:")
global vHeightMax := MyGui.AddEdit("r1 vHeightMax w40","")
vHeightMax.Opt("+Limit +Number")

MyGui.AddText(, "The amount of pixels to decrement every flush cycle:")
global vHeightDec := MyGui.AddEdit("r1 vHeightDec w20","")
vHeightDec.Opt("+Limit +Number")

MyGui.AddText(, "The frequency of the flush cycles, in milliseconds:")
global vFlushPrd := MyGui.AddEdit("r1 vFlushPrd w40","")
vFlushPrd.Opt("+Limit +Number")

global RecheckBtn := MyGui.AddButton("Default w80", "Recheck")
RecheckBtn.OnEvent("Click", RecheckBtn_Callback)

GuiTabs.UseTab()

MyGui_Close(ThisGui) {
	ExitApp
}
MyGui.OnEvent("Close", MyGui_Close)

if FileExist(SettingsFile) {
	CheckDefineds()
	global GuiSB := MyGui.AddStatusBar(, "Ready. (Saved values have been added.)")
} else {
	global GuiSB := MyGui.AddStatusBar(, "Ready.")
}

; show the gui
MyGui.Show

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; functions

CheckDefineds() {
	global ; all variables must be used globally unless otherwise specified
	if MaxWidth {
		vWidthMax.Value := MaxWidth
	}
	if MaxHeight {
		vHeightMax.Value := MaxHeight
	}
	if HeightDecr {
		vHeightDec.Value := HeightDecr
	}
	if FlushPeriod {
		vFlushPrd.Value := FlushPeriod
		SetTimer FlushTimer, 0
		SetTimer FlushTimer, FlushPeriod
	}
	if AggressiveOptims {
		vAggrOpts.Value := AggressiveOptims
	}
}

; this will check all custom config values,
; setting variables to the ones defined here
RecheckBtn_Callback(GuiCtrlObj, Info) {
	global ; all variables must be used globally unless otherwise specified
	if IsInteger(vWidthMax.Value) {
		MaxWidth := vWidthMax.Value
	}
	if IsInteger(vHeightMax.Value) {
		MaxHeight := vHeightMax.Value
	}
	if IsInteger(vHeightDec.Value) {
		HeightDecr := vHeightDec.Value
	}
	if IsInteger(vFlushPrd.Value) {
		FlushPeriod := vFlushPrd.Value
		SetTimer FlushTimer, 0
		SetTimer FlushTimer, FlushPeriod
	}
	if IsInteger(vAggrOpts.Value) {
		AggressiveOptims := vAggrOpts.Value
	}	
	try FileDelete SettingsFile
	FileAppend 
	(
	String(MaxWidth)
	","
	String(MaxHeight)
	","
	String(HeightDecr)
	","
	String(FlushPeriod)
	","
	String(AggressiveOptims)
	","
	), SettingsFile
	GuiSB.SetText("Variables rechecked.")
}

; this will attempt to invalidate game buffers
; which should force the game to quit lagging
FlushTimer() { ; the flush timer function itself
	global ; all variables must be used globally unless otherwise specified
	if FlushTimerIsActive { ; is the flush timer active?
		try {
			WinActive("ahk_class Etterna") ; is the etterna window focused?
			WinRedraw ; attempts to force the game to redraw itself
			; attempts to invalidate the game buffers
			; by resizing the window very quickly
			WinMove 0, HeightDecr, MaxWidth, MaxHeight-HeightDecr
			WinMove 0, 0, MaxWidth, MaxHeight
			if Tock {
				GuiSB.SetText("Tock!")
				Tock := false
			} else {
				GuiSB.SetText("Tick!")
				Tock := true
			}
		}
	}
}

ClearSBText() {
	global
	try {
		GuiSB.SetText(" ")
	}
}

; put safe window optimizations for etterna here
WindowOptim() {
	WinSetStyle "-0xC00000", "ahk_class Etterna" ; removes the titlebar from the game window
}

; put aggressive (potentially crashing) window optimizations for etterna here
WindowOptimAggressive() {
	; disables dwm rendering for the etterna window's frame
	DllCall("dwmapi\DwmSetWindowAttribute", "ptr", WinExist("ahk_class Etterna")
	, "uint", DWMWA_NCRENDERING_POLICY := 2, "int*", DWMNCRP_DISABLED := 1, "uint", 4)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; enables the flush timer
FlushTimerStart(GuiCtrlObj, Info) {
	global ; all variables must be used globally unless otherwise specified
	if FlushTimerIsActive { ; is the flush timer active?
		FlushTimerIsActive := false ; if so, disable it
		WindowOptim()
		if AggressiveOptims == 1 {
			WindowOptimAggressive()
		}
		FlushTimer ; run it one last time...
		GuiSB.SetText("Flush timer has been stopped.")
	} else {
		FlushTimerIsActive := true ; if not, enable it
		WindowOptim()
		if AggressiveOptims == 1 {
			WindowOptimAggressive()
		}
		FlushTimer ; run it before starting the timer again...
		GuiSB.SetText("Flush timer has been started.")
	}
}