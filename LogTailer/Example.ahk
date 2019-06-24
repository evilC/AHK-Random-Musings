#SingleInstance force
#Persistent
#Include LogTailer.ahk

lt := new LogTailer("SampleLog.txt", Func("OnNewLine"))
return

; This function gets called each time there is a new line
OnNewLine(line){
    ToolTip % "New Line: " line
}
