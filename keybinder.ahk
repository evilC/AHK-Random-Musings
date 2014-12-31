/*
Current best stab at being able to detect any input combo.
Designed to be fed into the Hotkey command to dynamically bind hotkeys.

Currently works with keyboard + mouse (most keys) and all modifiers (eg ^!+#wheelup is possible)
Could be extended to joystick buttons, but would consume a lot of the 100 hotkey limit?

Known unsupported combinations:
Escape (duh)
Ctrl + `
Shift + Plus Key gives += not ++ or =?
*/

#SingleInstance, force
#InstallKeybdHook
#InstallMouseHook

Class CInputBinder {
	BindMode := 0
	__New(guiid := 1){
		this._GuiID := guiid
		this.Binding := ""

		; Build list of "End Keys" for Input command
		this.EXTRA_KEY_LIST := "{Escape}"	; DO NOT REMOVE! - Used to quit binding
		; Standard non-printables
		this.EXTRA_KEY_LIST .= "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}"
		this.EXTRA_KEY_LIST .= "{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BackSpace}{Pause}{Space}{Tab}"
		; Numpad - Numlock ON
		this.EXTRA_KEY_LIST .= "{Numpad0}{Numpad1}{Numpad2}{Numpad3}{Numpad4}{Numpad5}{Numpad6}{Numpad7}{Numpad8}{Numpad9}{NumpadDot}{NumpadMult}{NumpadAdd}{NumpadSub}"
		; Numpad - Numlock OFF
		this.EXTRA_KEY_LIST .= "{NumpadIns}{NumpadEnd}{NumpadDown}{NumpadPgDn}{NumpadLeft}{NumpadClear}{NumpadRight}{NumpadHome}{NumpadUp}{NumpadPgUp}{NumpadDel}"
		; Numpad - Common
		this.EXTRA_KEY_LIST .= "{NumpadMult}{NumpadAdd}{NumpadSub}{NumpadDiv}{NumpadEnter}"
		; Stuff we may or may not want to trap
		;this.EXTRA_KEY_LIST .= "{Numlock}"
		this.EXTRA_KEY_LIST .= "{Capslock}"
		;this.EXTRA_KEY_LIST .= "{PrintScreen}"
		; Browser keys
		this.EXTRA_KEY_LIST .= "{Browser_Back}{Browser_Forward}{Browser_Refresh}{Browser_Stop}{Browser_Search}{Browser_Favorites}{Browser_Home}"
		; Media keys
		this.EXTRA_KEY_LIST .= "{Volume_Mute}{Volume_Down}{Volume_Up}{Media_Next}{Media_Prev}{Media_Stop}{Media_Play_Pause}"
		; App Keys
		this.EXTRA_KEY_LIST .= "{Launch_Mail}{Launch_Media}{Launch_App1}{Launch_App2}"

		; Create the Bind GUI
		prompt := "Please press the desired key combination.`n`n"
		prompt .= "Supports most keyboard keys and all mouse buttons. Also Ctrl, Alt, Shift, Win as modifiers or individual keys.`n"
		;prompt .= "Joystick buttons are also supported, but currently not with modifiers.`n"
		prompt .= "`nHit Escape to cancel."
		prompt .= "`nHold Escape to clear a binding."
		Gui, % this._GuiID ":New"
		Gui, % this._GuiID ":Add", text, center, %prompt%
		Gui, % this._GuiID ":-Border +AlwaysOnTop"
	}

	; returns 1 on success, 0 for cancel / fail, -1 for clear binding
	Bind(){
		ESCAPE_TIME := 2000
		return_val := 1
		detectedkey := ""
		endkey := ""

		; Show instructions
		Gui, % this._GuiID ":Show"

		; Turn Caps Lock off during bind mode, store state
		caps_state := GetKeyState("Capslock", "T") 
		if (caps_state){
			SetCapsLockState, Off
		}

		while (!detectedkey && !endkey){
			; Use Input command to detect keyboard / mouse buttons
			; http://ahkscript.org/docs/commands/Input.htm

			; Using "I" option for Input would be nice, but we need it so "Extra Buttons" (eg mouse) can be detected.

			this.BindMode := 1				; Read by #if label to activate hotkeys for "Extra Buttons"
			this.BindModeExtraButton := ""	; Buttons detected through other means than the Input box

			;Input, detectedkey, I L1 M, % this.EXTRA_KEY_LIST
			Input, detectedkey, L1 M, % this.EXTRA_KEY_LIST
			this.BindMode := 0
			; Capture which modifiers are held as we exit bind mode
			mod_states := this.GetModifierStates()
			if (substr(ErrorLevel,1,7) == "EndKey:"){
				endkey := substr(ErrorLevel,8)
			}
			if (endkey == "Escape"){
				; Escape could mean user pressed escape, or an "Extra Button" was pressed
				; Detect long ("Clear") or short ("Cancel") Escape press
				t := A_TickCount
				while (GetKeyState("Escape","P")){
					; Wait for key to be released - best not to progress whilst user holding Esc else dialogs will disappear etc.
					if (A_TickCount - t >= ESCAPE_TIME){
						; If Escape held for > ESCAPE_TIME, then hide GUI to let user know Clear has triggered and they can let go of Escape
						Gui, % this._GuiID ":Hide"
					}
					Sleep 50
				}

				if (A_TickCount - t >= ESCAPE_TIME){
					; Long Escape press - "Clear Binding"
					return_val := -1
				} else {
					; Short Escape press - "Cancel" or "Extra Button"
					if (this.BindModeExtraButton){
						detectedkey := this.BindModeExtraButton
					} else {
						return_val := 0
					}
				}
			} else {
				; Endkey contains pressed key combo
				; Not too sure why this case only happens with some key combos, eg Ctrl F12.
				if (!detectedkey && endkey){
					detectedkey := endkey
				}
			}
			Gui, % this._GuiID ":Hide"
			if (detectedkey){
				;Transform, detectedkey, Asc, 3
				detectedkey := GetKeyName(detectedkey)
				StringLower, detectedkey, detectedkey
				this.Binding := this.SerializeModifierStates(mod_states) detectedkey
			} else {
				if (return_val < 0){
					this.Binding := ""
				}
			}
		}
		Gui, % this._GuiID ":Hide"

		; Turn Caps Lock back on if it was on
		if (caps_state){
			SetCapsLockState, On
		}

		return !return_val
	}

	; Returns an object with .Shift, .Ctrl etc properties
	GetModifierStates(){
		ret := {}
		if (GetKeyState("LShift") || GetKeyState("RShift")){
			ret.Shift := 1
		} else {
			ret.Shift := 0
		}
		if (GetKeyState("LCtrl") || GetKeyState("RCtrl")){
			ret.Ctrl := 1
		} else {
			ret.Ctrl := 0
		}
		if (GetKeyState("LAlt") || GetKeyState("RAlt")){
			ret.Alt := 1
		} else {
			ret.Alt := 0
		}
		if (GetKeyState("LWin") || GetKeyState("RWin")){
			ret.Win := 1
		} else {
			ret.Win := 0
		}
		return ret
	}

	; Converts a modifier object to AHK hotkey prefix syntax (eg Ctrl = ^)
	SerializeModifierStates(mod_obj){
		ret := ""
		if (mod_obj.Shift){
			ret .= "+"
		}
		if (mod_obj.Ctrl){
			ret .= "^"
		}
		if (mod_obj.Alt){
			ret .= "!"
		}
		if (mod_obj.Win){
			ret .= "#"
		}
		return ret
	}
}

Gui, Add, Button, gBind W100 center, Bind
Gui, Add, Text, vBindingName W100 center, Nothing Bound
Gui, Show

; Create new CInputBinder object
binder := new CInputBinder(2)
Return

Bind:
	; Detect Input
	ret := binder.Bind()
	GuiControl,, BindingName, % binder.Binding
	Return

; When in bind mode, detedct "Extra Buttons"
; Could be extended to joystick etc, but may hit 100 limit quick?
; When Extra Button is hit, Set var to name of button, then hit Escape to quit BindMode
#If binder.BindMode
	*~lbutton::
	*~rbutton::
	*~mbutton::
	*~wheelup::
	*~wheeldown::
	*~wheelleft::
	*~wheelright::
	*~xbutton1::
	*~xbutton2::
		binder.BindModeExtraButton := Substr(A_ThisHotkey,3)
		Send {Escape}
		return

	~*lctrl up::
	~*rctrl up::
	~*lalt up::
	~*ralt up::
	~*lshift up::
	~*rshift up::
	~*lwin up::
	~*rwin up::
		binder.BindModeExtraButton := Substr(A_ThisHotkey,3,strlen(A_ThisHotkey) -5)
		Send {Escape}
		return
#if

GuiClose:
	ExitApp