#SingleInstance force

; Money making script for Astrox Imperium
; Automates buying scrap, refining it, then selling the refined goods
; https://steamcommunity.com/app/954870/discussions/0/1679189548058195121/
; Use F1 to start the script, F2 to tell it to stop at the end of the next cycle
; Ctrl+Esc can be used to instantly abort

; Note: This script is currently hard-wired for 2560x1440 resolution, it would need to be altered to work with other resolutions
; Before starting:
; Go to Market tab and type "Scrap" into search box
; Move everyting out of cargo into storage, else it will get sold!

; Location of first slot of cargo
cargox := 84
cargoy := 319

; Location of first slot of refinery
refx := 546
refy := 424

F1::
    active := 1
    StatusTooltip("Running...")
    while (active){
        if (!BuyScrap()){
            active := 0
            ToolTip, , , , 1
            StatusTooltip("No more scrap")
            return
        }
        GoSub, RefineScrap
        Gosub, Sell
    }
    JobTooltip()
    StatusTooltip()
    return

F2::
    active := 0
    StatusTooltip("Stopping...")
    return

OpenMarket:
    Click, 2433, 494
    return

OpenRefinery:
    Click, 2224, 570
    return

ClickSearch:
    Click, 1730, 256
    return

F5:: BuyScrap()

BuyScrap(){
    JobTooltip("Buying...")
    Gosub, OpenMarket
    Sleep 500
    Gosub, ClickSearch
    Sleep 500
    ; Click near end of slider
    Click, 683, 414
    Sleep, 500
    ; Drag slider to end
    Drag(1718, 1240, 1783, 1240)
    Sleep 500
    found := ScrapFound()
    if (found){
        ; Click buy button
        Click, 1663, 1337
    }
    JobTooltip("Buying done")
    return found
}

Take:
    ; Take first item from refinery output and put in cargo
    Drag(refx, refy, cargox, cargoy)
    return

F6::
RefineScrap:
    JobTooltip("Refining...")
    Gosub, OpenRefinery
    Sleep 500
    ; Drag from first cargo slot to refinery
    Drag(cargox, cargoy, 572, 439)
    ; Click refine
    Click, 1929, 205
    ; Move mouse away
    MouseMove, 0, 0
    ; Wait for refining to complete
    while (true){
        PixelGetColor, col, 1929, 205, RGB
        if (col != 0xFE0001)
            break
        Sleep, 500
    }
    JobTooltip("Refining done")
    return

F7::
Sell:
    JobTooltip("Selling...")
    ToolTip, Selling..., 0, 100, 1
    Loop {
        GoSub, OpenRefinery
        Gosub, Take
        Gosub, OpenMarket
        ; Drag to sell box (Could do nothing if nothing left in cargo)
        Drag(cargox, cargoy, 1261, 904)
        Sleep 500
        ; Is Sell lit?
        col := 0
        PixelGetColor, col, 1667, 1337, RGB
        if (col != 0xFFFFFF){
            break
        }
        ; Click sell
        Click, 1667, 1337
    }
    JobTooltip("Selling done")
    return

Drag(fromx, fromy, tox, toy){
    MouseMove, % fromx, % fromy
    Sleep 50
    Send, {LButton down}
    Sleep 50
    MouseMove, tox, toy
    Sleep 50
    Send, {LButton up}
    Sleep 50
}

F8::ToolTip, % "Scrap Found: " ScrapFound()
; Returns true if there is scrap to buy
ScrapFound(){
    ImageSearch, x, y, 1545, 1312, 1813, 1356, *50 Buy.png
    return 1 - ERRORLEVEL
}

JobTooltip(text := ""){
    ToolTip, % text, 0, 100, 1
}

StatusTooltip(text := ""){
    ToolTip, % text, 0, 50, 2
}

^Esc::
    ExitApp