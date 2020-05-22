/*
An AHK script to automate setting temperatures for each layer for a Temperature Tower model in the Cura slicer
Default values are for this tower: https://www.thingiverse.com/thing:2493504
*/
#SingleInstance force
CoordMode Mouse, Window
SetMouseDelay, 50

InitialLayer := 42		; Initial Layer height for first block
LayersPerBlock := 34	; Add this many layers for each subsequent block
InitialTemp := 245		; Starting Temperature
NumBlocks := 9			; Number of blocks in tower

; Coordinates - tweak as appropriate
AddScriptInitial := {x: 65, y: 108}		; Add Script button location on first add
AddScriptDelta := 27					; How many pixels down Add Script button moves when you add a new script
TriggerCoords := {x: 530, y: 90}		; Coords of Trigger DropDown
LayerCoords := {x: 530, y: 120}			; Coords of Layer EditBox
ExtruderCoords := {x: 530, y: 400}		; Coords of Extruder CheckBox
ExtruderTempCoords := {x: 530, y: 436}	; Coords of Extruder Temp EditBox

WindowName := "Post Processing Plugin"

Gui, Add, Text, w100, Initial Temp
Gui, Add, Edit, x+5 w50 vInitialTemp gSettingChanged, % InitialTemp
Gui, Add, Text, w100 xm, Number of Blocks
Gui, Add, Edit, x+5 w50 vNumBlocks gSettingChanged, % NumBlocks
Gui, Add, Button, xm w160 Center gGo, Go
Gui, Show, , Temp Tower Tool
return

Go:
	WinActivate, % WindowName
	
	Sleep 500
	AddScript := {x: AddScriptInitial.x, y: AddScriptInitial.y}
	Temp := InitialTemp - 5
	Layer := InitialLayer
	Loop % NumBlocks - 1 {
		; Add Script
		MouseMove(AddScript)
		Send {LButton}{Down 2}{Enter}
		Wait()
		
		; Select Layer as trigger
		MouseMove(TriggerCoords)
		Send {LButton}{Down}{Enter}
		Wait()
		
		; Enter Layer Number
		MouseMove(LayerCoords)
		Send {LButton 2}
		Send % Layer
		
		; Check Extruder Box
		MouseMove(ExtruderCoords)
		Wait()
		; This box seems particularly problematic for some reason...
		; Seems to miss clicks, so hold mouse button down extra long
		Send {LButton down}
		Wait()
		Send {LButton up}
		Wait()
		
		; Enter Temp
		MouseMove(ExtruderTempCoords)
		Send {LButton 2}
		Send % Temp
		
		Wait()
		AddScript.y += AddScriptDelta
		Temp -= 5
		Layer += LayersPerBlock
	}
	return

SettingChanged:
	Gui, Submit, NoHide
	return

MouseMove(coords){
	MouseMove, % coords.x, % coords.y, 0
}


Wait(){
	Sleep, 500
}

^Esc::
GuiClose:
	ExitApp