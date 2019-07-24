/*
Maps WSAD to mouse movement, with diagonal support and no delay for key repeat
*/

#SingleInstance force
MoveMultiplier := 5
HoldMoveVectors := {x: 0, y: 0}
MoveFn := Func("DoMove")
return

w::HandleInput("y", -1, 1)
w up::HandleInput("y", -1, 0)
s::HandleInput("y", 1, 1)
s up::HandleInput("y", 1, 0)
a::HandleInput("x", -1, 1)
a up::HandleInput("x", -1, 0)
d::HandleInput("x", 1, 1)
d up::HandleInput("x", 1, 0)

HandleInput(axis, dir, state){
	global HoldMoveVectors, MoveFn, MoveMultiplier
	if (state){
		v := dir * MoveMultiplier
		if (HoldMoveVectors[axis] == v)
			return ; Filter repeats
		HoldMoveVectors[axis] := v
		SetTimer, % MoveFn, 10
	} else {
		HoldMoveVectors[axis] := 0
		if (HoldMoveVectors.x == 0 && HoldMoveVectors.y == 0){
			SetTimer, % MoveFn, Off
		}
	}
}

DoMove(){
	global HoldMoveVectors
	; Cursor move (use to move mouse pointer)
	MouseMove, % HoldMoveVectors.x, % HoldMoveVectors.y , 0, R
	; Delta move (Use for FPS games)
	; DllCall("mouse_event", "UInt", 0x01, "UInt", HoldMoveVectors.x, "UInt", HoldMoveVectors.y)
}
