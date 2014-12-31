; Example of how to (mostly) encapsulate a GUI control within a class.
; Works by using the memory address of a class as the name for a GUI control.
; Trick learned by studying Fincs' AFC https://github.com/fincs/AFC

#SingleInstance, force

; Configure stuff that pollutes the global namespace - set prefixes etc
CONTROL_PREFIX := "__CTest_Controls_"
CONTROL_PREFIX_LENGTH := StrLen(CONTROL_PREFIX) + 1
LABEL_PREFIX := "__CTest_Labels_"

Class CMain {
	; Create a custom Edit box
	Class CTest {
		__New(name){
			static 	; Declare static, else Gui, Add fails ("Must be global or static")
			global CONTROL_PREFIX, LABEL_PREFIX
			local CtrlHwnd, addr

			; Store friendly name
			this.__Name := name

			; Find address of this class instance.
			addr := Object(this)

			; Prepend address to CONTROL_PREFIX to obtain unique name that links to this class instance.
			this.__VName := CONTROL_PREFIX addr

			; Create the GUI control
			Gui, Add, Edit, % "hwndCtrlHwnd v" this.__VName " g" LABEL_PREFIX "OptionChanged"

			; Store HWND of control for future reference
			this.__Handle := CtrlHwnd
		}

		; Mimic GuiControlGet behavior.
		GuiControlGet(cmd := "", value := ""){
			GuiControlGet, ov, %cmd%, % this.__Handle, % value
			return ov
		}

		; OnChange method is called by the __CTest_Labels_OptionChanged gLabel
		OnChange(){
			Tooltip % this.__Name " contents: " this.GuiControlGet()
		}
	}

	; DO NOT call this method, this is just a place to store labels within the class.
	__DoNotCallMe(){
		; Bear in mind that inside labels inside this function, we are not in the scope of the class.
		; That is to say, "this" does not equal the class instance!
		; "this" can be obtained from Object(SubStr(A_GuiControl,CONTROL_PREFIX_LENGTH))

		; Change events for all controls route to this label
		__CTest_Labels_OptionChanged:
			global CONTROL_PREFIX_LENGTH
			; Pull the address of the class instance from the control name and use it to obtain an object.
			; Then use the object to call the OnChange() method of the class instance that created the GUI control.
			Object(SubStr(A_GuiControl,CONTROL_PREFIX_LENGTH)).OnChange()
			return
	}

}

blah := new CMain()
test1 := new CMain.CTest("One")
test2 := new CMain.CTest("Two")
Gui, Show
Return

GuiClose:
	ExitApp
