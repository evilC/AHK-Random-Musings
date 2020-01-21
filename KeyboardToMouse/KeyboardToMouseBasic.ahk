/*
Basic implementation of WSAD to mouse movement, with diagonal support and no delay for key repeat
Suffers from usability issue if you hold two opposite directions (eg a and d) together...
... If, while holding a, you hold d, the cursor moves to the right...
... When you release a, the cursor would then stop for a while until key repeat kicks in, then carry on moving right
*/

; Lookup table of what axis and direction to move on key press
Delta := {w: {y: -1}
            , s: {y: 1}
            , a: {x: -1}
            , d: {x: 1}}

; How many px per tick of the timer to move
Speed := 10

AxisStates := {x: 0, y: 0}

For key, obj in Delta {
    for axis, dir in obj {
        fn := Func("KeyEvent").Bind(axis, dir)
        Hotkey, % key, % fn, ON
        fn := Func("KeyEvent").Bind(axis, 0)
        Hotkey, % key " up", % fn, ON
    }
}
Return

KeyEvent(axis, dir){
    global AxisStates
    if (AxisStates[axis] == dir)
        return ; Ignore key repeat
    AxisStates[axis] := dir
    if (!AxisStates.x && !AxisStates.y){
        SetTimer, DoMove, Off
    } else {
        SetTimer, DoMove, 10
    }
}

DoMove:
    x := AxisStates.x * Speed, y := AxisStates.y * Speed
    ; Cursor move (Use for desktop apps)
    MouseMove % x, % y, 0 , R
    ; Delta move (Use for FPS games)
	; DllCall("mouse_event", "UInt", 0x01, "UInt", x, "UInt", y)
    return
