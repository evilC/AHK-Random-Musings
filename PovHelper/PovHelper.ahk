class PovHelper {
    static PovMap := {-1: [0,0,0,0], 1: [1,0,0,0], 2: [1,1,0,0] , 3: [0,1,0,0], 4: [0,1,1,0], 5: [0,0,1,0], 6: [0,0,1,1], 7: [0,0,0,1], 8: [1,0,0,1]}
    static directionNames := {Up: 1, Right: 2, Down: 3, Left: 4}
    callbacks := {}
    currentAngle := -1
    directionStates := [0,0,0,0]
    
    __New(stickId){
        fn := this.WatchPov.Bind(this)
        this.stickId := stickId
        this.povStr := stickId "JoyPOV"
        
        SetTimer, % fn, 10
    }
    
    Subscribe(dir, callback){
        if (this.directionNames.HasKey(dir)){   ; Translate from direction name to index, if needed
            dir := this.directionNames[dir]
        }
        this.Callbacks[dir] := callback
    }
    
    WatchPov(){
        angle := GetKeyState(this.povStr)
        if (angle == this.currentAngle)
            return
        this.currentAngle := angle
        angle := (angle = -1 ? -1 : round(angle / 4500) + 1)
        newStates := this.PovMap[angle]
        Loop 4 {
            if (this.directionStates[A_Index] != newStates[A_Index]){
                this.directionStates[A_Index] := newStates[A_Index]
                if (this.callbacks.HasKey(A_Index)){
                    this.callbacks[A_Index].call(newStates[A_Index])
                }
            }
        }
    }
}
