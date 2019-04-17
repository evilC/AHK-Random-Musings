#SingleInstance force
#include PovHelper.ahk

ph := new PovHelper(3)  ; Pass Joystick number here

/*
When calling Subscribe, pass direction NAMES (Up, Right, Down or Left) or INDEXES (1, 2, 3, 4)
*/
ph.Subscribe("Up", Func("Up"))
ph.Subscribe("Left", Func("Left"))
return

^Esc::
    ExitApp

Up(state){
    Tooltip % "Up " (state ? "Pressed" : "Released") " @ " A_TickCount
}

Left(state){
    Tooltip % "Left " (state ? "Pressed" : "Released") " @ " A_TickCount
}
