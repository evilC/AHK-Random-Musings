/*
UCR - Universal Control Remapper

Proof of concept for class-based hotkeys and class-based plugins.
evilc@evilc.com

Uses Fincs' AFC to encapsulate GUI controls into classes.
https://github.com/fincs/AFC
This script just demonstrates how to encapsulate hotkeys into classes, so I used AFC to keep this code uncluttered.

*/
#SingleInstance, force

#include <CCtrlLabel>
#include <CCtrlEdit>

_UCR_HotkeyLookup := {}

AFC_EntryPoint(UCR)

; "Master" class. Handles hotkey mapping, loading of children etc.
class UCR extends CWindow{
	__New(){
		base.__New("Main Window")
		new CCtrlLabel(this, "Hotkey List", "x5 y5 W310 h25 center")
		this.HKList := new CCtrlLabel(this, "", "x5 y35 w310 h200")
		this.Show("w320 h240")

		this.remap1 := new StraightRemap(this,"StraightRemap 1")
		this.remap1.EditApp.Value := "Notepad"

		this.remap2 := new StraightRemap(this,"StraightRemap 2")
		this.remap2.EditApp.Value := "Notepad++"

		this.toggle := new Toggle(this,"Toggle")
		this.toggle.EditApp.Value := "Notepad"
	}
	
	UpdateHKList(){
		; Update debug
		this.HKList.Text := ""
		for i, hotkey in GetHotkeys(){
			if (hotkey["Off?"]){
				onoff := hotkey["Off?"]
			} else {
				onoff := "On"
			}
			this.HKList.Text .= "Name:" hotkey.Name "   Status: " onoff "`n"
		}
	}

	; A subclass to handle hotkey mappings
	Class Hotkey {
		CurrentKey := ""
		CurrentApp := ""
		__New(parent){
			this.parent := parent
		}

		; Add or change the hotkey.
		Add(key,app){
			global _UCR_HotkeyLookup

			; Add the new hotkeys
			if (this.CurrentKey){
				this.Remove()
			}
			if (key){
				if (app){
					Hotkey, IfWinActive, % "ahk_class " app
				} else {
					Hotkey, IfWinActive
				}
				Hotkey, % "~*" key, _UCR_HotkeyHandler, UseErrorLevel
				Hotkey, % "~*" key " up", _UCR_HotkeyHandlerUp, UseErrorLevel

				if (!app){
					app := "_UCR_Global"
				}
				this.CurrentKey := key
				this.CurrentApp := app

				; Update the lookup table
				if (!IsObject(_UCR_HotkeyLookup[app])){
					_UCR_HotkeyLookup[app] := {}
				}
				_UCR_HotkeyLookup[app][key] := this.parent
			}
		}

		; Remove the hotkey from the list.
		Remove(){
			global _UCR_HotkeyLookup

			if (this.CurrentKey){
				_UCR_HotkeyLookup[this.CurrentApp][this.CurrentKey] := ""
				if (this.CurrentApp){
					Hotkey, IfWinActive, % "ahk_class " this.CurrentApp
				} else {
					Hotkey, IfWinActive
				}
				Hotkey, % "~*" this.CurrentKey, Off, UseErrorLevel
				Hotkey, % "~*" this.CurrentKey " up", Off, UseErrorLevel

				this.CurrentKey := ""
				this.CurrentApp := ""
			}
		}

		Test(){
			MsgBox % "I am a Hotkey, currently handling " this.CurrentKey
		}
	}
}

; Plugin base class to derive from
class Plugin extends CWindow {
	__New(parent,name){
		this.Parent := parent
		this.Name := name
		base.__New(name)

		this.Hotkey := new this.parent.Hotkey(this)

		new CCtrlLabel(this, "ifwinactive ahk_class", "x5 y5")
		this.EditApp := new CCtrlEdit(this, "", "xp+120 yp w100")
		this.EditApp.OnEvent := this.AppChanged

		new CCtrlLabel(this, "Input", "x5 y30")
		this.EditInput := new CCtrlEdit(this, "", "xp+120 yp w100")
		this.EditInput.OnEvent := this.InputChanged

		new CCtrlLabel(this, "Output", "x5 y60")
		this.EditOutput := new CCtrlEdit(this, "", "xp+120 yp w100")
		this.EditOutput.OnEvent := this.OutputChanged
		this.Show("w240 h100")
	}

	InputChanged(){
		this.Hotkey.Add(this.EditInput.value, this.EditApp.value)
		this.parent.UpdateHKList()
	}

	OutputChanged(){
	}

	AppChanged(){
		this.Hotkey.Add(this.EditInput.value, this.EditApp.value)
		this.parent.UpdateHKList()
	}

	DownEvent(){
	}

	UpEvent(){
	}

	Test(){
		msgbox % "I am aPlugin called " this.Name
	}
}

; A class to do a straight remapping - Input Key mapped to Output Key
Class StraightRemap Extends Plugin {
	DownEvent(){
		if (this.EditOutput.value){
			Tooltip % this.name ": " this.EditOutput.Value " DOWN"
			key := this.EditOutput.value
			Send {%key% down}
		}
	}

	UpEvent(){
		if (this.EditOutput.value){
			Tooltip % this.name ": " this.EditOutput.Value " UP"
			key := this.EditOutput.value
			Send {%key% up}
		}
	}
}

; A class to turn a key into a toggle - tap Input key to toggle state of Output Key
Class Toggle Extends Plugin {
	__New(parent, name){
		base.__New(parent, name)

		this.ToggleState := 0ab
	}

	DownEvent(){
		if (this.EditOutput.value){
			if (this.ToggleState){
				updown := "Up"
			} else {
				updown := "Down"
			}
			key := this.EditOutput.value
			Tooltip % this.name ": "  key " " updown
			this.ToggleState := !this.ToggleState
			Send {%key% %updown%}
		}
	}
}

return
GuiClose:
	ExitApp

; All hotkeys routed via these labels
_UCR_HotkeyHandler:
	; Search _UCR_HotkeyLookup array for object to route to...

	; Check current active app, see if we can find a match for that app and key
	WinGetClass, _UCR_CurrentClass, A
	key := Substr(A_ThisHotkey,3)

	if (IsObject(_UCR_HotkeyLookup[_UCR_CurrentClass][key])) {
		_UCR_HotkeyLookup[_UCR_CurrentClass][key].DownEvent()
		return
	}
	; No per-app variant found, try global
	if (IsObject(_UCR_HotkeyLookup["_UCR_Global"][key])) {
		_UCR_HotkeyLookup["_UCR_Global"][key].DownEvent()
		return
	}
	return

_UCR_HotkeyHandlerUp:
	WinGetClass, _UCR_CurrentClass, A
	key := Substr(A_ThisHotkey,3,(strlen(A_ThisHotkey) -5))
	if (IsObject(_UCR_HotkeyLookup[_UCR_CurrentClass][key])) {
		_UCR_HotkeyLookup[_UCR_CurrentClass][key].UpEvent()
		return
	}
	; No per-app variant found, try global
	if (IsObject(_UCR_HotkeyLookup["_UCR_Global"][key])) {
		_UCR_HotkeyLookup["_UCR_Global"][key].UpEvent()
		return
	}
	return

; Dependencies - not part of example

; GetHotkeys - pull the HotkeyList into an Array, so we can show current hotkeys in memory (for debugging purposes)
; From http://ahkscript.org/boards/viewtopic.php?p=31849#p31849
GetHotkeys(){
	static hEdit, pSFW, pSW, bkpSFW, bkpSW

	if !hEdit
	{
		dhw := A_DetectHiddenWindows
		DetectHiddenWindows, On
		ControlGet, hEdit, Hwnd,, Edit1, ahk_id %A_ScriptHwnd%
		DetectHiddenWindows %dhw%

		AStr := A_IsUnicode ? "AStr" : "Str"
		Ptr := A_PtrSize == 8 ? "Ptr" : "UInt"
		hmod := DllCall("GetModuleHandle", "Str", "user32.dll")
		pSFW := DllCall("GetProcAddress", Ptr, hmod, AStr, "SetForegroundWindow")
		pSW := DllCall("GetProcAddress", Ptr, hmod, AStr, "ShowWindow")
		DllCall("VirtualProtect", Ptr, pSFW, Ptr, 8, "UInt", 0x40, "UInt*", 0)
		DllCall("VirtualProtect", Ptr, pSW, Ptr, 8, "UInt", 0x40, "UInt*", 0)
		bkpSFW := NumGet(pSFW+0, 0, "Int64")
		bkpSW := NumGet(pSW+0, 0, "Int64")
	}

	if (A_PtrSize == 8)
	{
		NumPut(0x0000C300000001B8, pSFW+0, 0, "Int64")  ; return TRUE
		NumPut(0x0000C300000001B8, pSW+0, 0, "Int64")   ; return TRUE
	}
	else
	{
		NumPut(0x0004C200000001B8, pSFW+0, 0, "Int64")  ; return TRUE
		NumPut(0x0008C200000001B8, pSW+0, 0, "Int64")   ; return TRUE
	}

	ListHotkeys

	NumPut(bkpSFW, pSFW+0, 0, "Int64")
	NumPut(bkpSW, pSW+0, 0, "Int64")

	ControlGetText, text,, ahk_id %hEdit%

	static cols
	hotkeys := []
	for each, field in StrSplit(text, "`n", "`r")
	{
		if (A_Index == 1 && !cols)
			cols := StrSplit(field, "`t")
		if (A_Index <= 2 || field == "")
			continue

		out := {}
		for i, fld in StrSplit(field, "`t")
			out[ cols[A_Index] ] := fld
		static ObjPush := Func(A_AhkVersion < "2" ? "ObjInsert" : "ObjPush")
		%ObjPush%(hotkeys, out)
	}
	return hotkeys
}
