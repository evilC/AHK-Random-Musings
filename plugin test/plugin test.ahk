; Requires AHK_H v2

#singleinstance force
global CriticalPluginClass:=CriticalObject(PluginClass)

mc := new MainClass()

class MainClass {
	plugins := []
	__New(){
		LoopFiles,% A_ScriptDir "\plugins\*.ahk",F
			plugins.=(plugins?"|":"") SubStr(A_LoopFileName,1,-4) 
		Gui, Add, DropDownList, hwndDDL, %plugins%
		Gui, Add, Button, gCall, Call
		Gui, Show
		this.DDL := ddl
		fn := this.AddPlugin.Bind(this)
		GuiControl, +g, % DDL, % fn
	}
	
	AddPlugin(){
		if this.plugins.HasKey(pluginname:=GuiControlGet(,this.DDL)),	return
		ahk:=AhkThread("
			(Q
			#persistent`n%FileRead(A_ScriptDir "\plugins\" (pluginname) ".ahk")%
			%pluginname%.base:=CriticalObject(" (&CriticalPluginClass) ")
			plugin___:=CriticalObject(new %pluginname%(Object(" (&this) "))),pPlugin___:=&plugin___
			)")
		while !pPlugin:=ahk.ahkgetvar.pPlugin___
			Sleep 20
		this.plugins[pluginname] := CriticalObject(pPlugin)
	}
	
	SayHi(){
		msgbox("parent class says Hi")
	}
}

class PluginClass {
	__New(parent){
		this._parent := parent
	}
}
return
Call:
if call:=mc.plugins[GuiControlGet(,mc.DDL)]
	call.SayHi()
return

Esc::
GuiClose:
	ExitApp