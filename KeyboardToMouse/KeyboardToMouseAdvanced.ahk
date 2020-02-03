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

; Build Hotkeys. The data in the Delta Array holds the info for what needs to happen on each key press
; eg "w: {y: -1}" means that when w is pressed, move y in the -1 direction
For key, obj in Delta {
    ; key will now be the key to be used for input
    ; obj will be an object like {y: -1} which indicates what should happen for this key
    KeyStates[key] := 0 ; Initialize array which holds current state of keys with an entry for this key
    ; Although there will only be one item in obj, a for loop allows us to extract the axis name (eg y:) from the key
    for axis, dir in obj {
        ; axis now holds which axis this key affects. dir holds which direction this key moves that axis
        ; Now build function calls to happen when the key is pressed.
        ; The "Bind" command is used to attach axis, dir etc to this function call
        ; Hotkey for Press event - pass 1 for state as last parameter
        fn := Func("KeyEvent").Bind(axis, dir, 1)
        Hotkey, % key, % fn, ON
        ; Hotkey for Release event - pass 0 for state as last parameter
        fn := Func("KeyEvent").Bind(axis, dir, 0)
        Hotkey, % key " up", % fn, ON
    }
}
return

; Called when a key event happens
; Due to the use of Bind(), this hotkey function gets passed 3 parameters:
; axis: The axis that the key is for
; dir: The direction of that axis to move
; state: Whether the key was pressed (1), or released (0)
KeyEvent(axis, dir, state){
    global AxisStates, InputStates
    static timerRunning
    ;~ state := Abs(dir) ; state will be 1 (Key press) or 0 (Key release)
    if (InputStates[axis, dir] == state)
        return ; Ignore key repeat
    oppositeDir := dir * -1
    InputStates[axis, dir] := state
    
    ; Make checks to see if the opposite key to this one (eg w and s are opposite, and a and d are opposite) is also held
    if (InputStates[axis, oppositeDir]){
        if (state){
            ; Processing a key press while opposite key held (eg d held while a already held)
            AxisStates[axis] := 0 ; Set that axis to middle (Opposites cancel)
        } else {
            ; Processing a key release while opposite key pressed (eg d released while a still held)
            AxisStates[axis] := oppositeDir ; Set current direction to currently held opposite direction
        }
        ; No starting or stopping the timer is done here, because if opposite keys are held, then the timer should be running anyay
    } else {
        ; Normal key press or release
        AxisStates[axis] := (dir * state)
        if (AxisStates.x || AxisStates.y){  ; If the cursor should be moving in either the x or y axis...
            if (!timerRunning){             ; ... and the timer is not already running...
                SetTimer, DoMove, 10        ; ...Start the timer
                timerRunning := 1           ; Record that the timer is running
            }
        } else {                            ; Cursor should not be moving
            if (timerRunning){              ; Timer is currently running
                SetTimer, DoMove, Off       ; Stop it
                timerRunning := 0
            }
        }
    }
}

DoMove:
    x := AxisStates.x * Speed, y := AxisStates.y * Speed
    ; Cursor move (Use for desktop apps)
    MouseMove % x, % y, 0 , R
    ; Delta move (Use for FPS games)
	; DllCall("mouse_event", "UInt", 0x01, "UInt", x, "UInt", y)
    return