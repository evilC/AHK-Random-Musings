/*
Advanced implementation of WSAD to mouse movement, with diagonal support and no delay for key repeat
Does not suffer from the issue that the basic script does (Holding opposite key weirdness)
If you hold an opposite key (eg hold d while a held), the cursor stops (Opposites cancel)
If you then release a while still holding d, the cursor immediately starts moving right
*/

#SingleInstance Force

; Lookup table of what axis and direction to move on key press
Delta := {w: {y: -1}
            , s: {y: 1}
            , a: {x: -1}
            , d: {x: 1}}

; How many px per tick of the timer to move
Speed := 10

AxisStates := {x: 0, y: 0}
InputStates := {x: {-1: 0, 1: 0}, y: {-1: 0, 1: 0}}

For key, obj in Delta {
    KeyStates[key] := 0
    for axis, dir in obj {
        fn := Func("KeyEvent").Bind(axis, dir, 1)
        Hotkey, % key, % fn, ON
        fn := Func("KeyEvent").Bind(axis, dir, 0)
        Hotkey, % key " up", % fn, ON
    }
}
return

KeyEvent(axis, dir, state){
    global AxisStates, InputStates
    ;~ state := Abs(dir) ; state will be 1 (Key press) or 0 (Key release)
    if (InputStates[axis, dir] == state)
        return ; Ignore key repeat
    oppositeDir := dir * -1
    InputStates[axis, dir] := state
    
    if (InputStates[axis, oppositeDir]){
        if (state){
            ; Opposite key held (eg d held while a already held)
            AxisStates[axis] := 0
        } else {
            ; Opposite key released (eg d released while a still held)
            AxisStates[axis] := oppositeDir
        }
    } else {
        ; Normal key press or release
        AxisStates[axis] := (dir * state)
        if (!AxisStates.x && !AxisStates.y){
            SetTimer, DoMove, Off
        } else {
            SetTimer, DoMove, 10
        }
    }
}

DoMove:
    x := AxisStates.x * Speed, y := AxisStates.y * Speed
    ; Cursor move (Use for desktop apps)
    MouseMove % x, % y * Speed, 0 , R
    ; Delta move (Use for FPS games)
	; DllCall("mouse_event", "UInt", 0x01, "UInt", x, "UInt", y)
    return