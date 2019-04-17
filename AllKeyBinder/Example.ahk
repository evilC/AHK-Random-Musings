#include AllKeyBinder.ahk

kb := new AllKeyBinder(Func("MyFunc"))
return

MyFunc(code, name, state){
    Tooltip % "Key Code: " code ", Name: " name ", State: " state
}

^Esc::
	ExitApp
