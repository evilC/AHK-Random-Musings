/*
Name: ScreenGrid
Version 1.2 (Monday, December 17, 2018)
Created: Wednesday,?February 7, 2018
Author: tidbit
Credit: 

Hotkeys:
	numpad 1-9      = the grid tile in the same position as the key
	numpad 0        = reset the grid
	numpad 5        = hold it to switch between monitors
	numpad minus    = go back up a level
	numpad divide   = toggle grid visibility
	numpad add = right click
	numpad enter    = click the middle of the middle tile, aswell as clickdrag*
	ctrl+esc        = exit

	* hold numpad enter for atleast 200ms (1/5 of a second) to enter clickdrag" mode.
	  The next time you press enter, it'll click and drag between those 2 locations.
	
Description:
Video of it in action: https://streamable.com/gn39d
*/



#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#singleInstance, force
setBatchLines, -1
#Include, <gdip> ; https://raw.githubusercontent.com/tariqporter/Gdip/master/Gdip.ahk
coordmode, mouse, screen 
OnExit, die

sounds:=1 ; play certain sounds, like monitor switching
mode:=1 ; 1 = lines, 2  rounded rects
; all modes
alineT:=8       ; line max thickness
fLineT:=1        ; fine line thickness
aLineC:="r"      ; active lines color ('r' for random otherwise: rrggbb format, no '0x')
oLineC:="r"      ; other lines color ('r' for random otherwise: rrggbb format, no '0x')
fLineC:="ffffff" ; fine lines color (rrggbb format, no '0x')
aLineA:=120      ; active lines alpha
oLineA:=80       ; other lines alpha
fLineA:=150      ; fine lines alpha
fLineAO:=110     ; fine lines alpha other lines
shadowS:=5       ; shadow size
ashadowA:=100    ; shadow alpha, active
oshadowA:=60     ; shadow alpha, others
; rects
rRadius:=20      ; corner radius
holdTimeMax:=500


; --------------------
; --- DO NOT TOUCH ---
; --------------------
holdMode:=0
wasHeld:=0
heldCoords:=[]
isVis:=1
mon:=1
gridSize:=3 ; 3 is the only number that works currently. 3 IS BEST. because numpad. 3x3 grid.
grid:=[]
history:=[]
dontadd:=0
deep:=0
pToken := Gdip_Startup()
gosub, setupMonitors

Gui, +hwndMYHWND -Caption +E0x80000 +LastFound +OwnDialogs +Owner +AlwaysOnTop
; Gui, +hwndMYHWND
Gui, Show, NA

hbm := CreateDIBSection(w2, w2)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(G, 4)


WinSet, ExStyle, +0x20, % "ahk_id " MYHWND ; clickthrough

dontadd:=1
gosub, draw
return


die:
guiclose:
~^esc::
	SelectObject(hdc, obm)
	DeleteObject(hbm)
	DeleteDC(hdc)
	Gdip_DeleteGraphics(G)
	Gdip_Shutdown(pToken)
	exitapp
return


setupMonitors:
	monArr:=allMonitorCoords()
	w2:=monArr[mon].w
	h2:=monArr[mon].h
	
	; winMove, ahk_id %MYHWND%,, % monArr[mon].x1, % monArr[mon].y1, % monArr[mon].w, % monArr[mon].h
	mainGrid:=buildGrid(gridSize, 0, 0, monArr[mon].w, monArr[mon].h)
	; mainGrid:=buildGrid(gridSize, monArr[mon].x1, monArr[mon].y1, monArr[mon].w, monArr[mon].h)
	
	
	; toolTip % mon "::" st_printArr(monArr), 10,, 2
	; msgBox % st_printArr(allMonitorCoords())
return


#if (getKeyState("numlock", "t")=1)

numpadSub:: ; go back a level
	dontadd:=1
	history.pop()
	deep-=1
	undoPressed:=1
	; toolTip, % deep "::" st_printArr(history)
	gosub, draw
return

numpad0:: ; reset
	hPath:=[]
	history:=[]
	chosen:=subGrid:=""
	deep:=0
	gosub, draw
return


numpadAdd:: ; right click
	mouseClick, Right
	if (sounds=1 && FileExist(A_WinDir "\media\speech sleep.wav"))
		soundPlay, %A_WinDir%\media\speech sleep.wav
return

numpadDiv:: ; toggle visibility
	isVis:=!isVis
	gosub, draw
return

numpadEnter:: ; left click and click and drag
	atk:=regExReplace(A_ThisHotkey, "[\W& ]")
	holdTime:=0
	canBeep:=1
	
	while (getKeyState(atk, "P"))
	{
		holdTime+=50
		if (holdTime>=holdTimeMax)
		{
			if (sounds=1 && canBeep=1)
				soundBeep
			canBeep:=0
			holdMode:=!holdMode
		}
		sleep, 50
	}
	
	if (holdMode=1)
		send, {lButton down}
	else if (holdMode=0 && getKeyState("lButton"))
		send, {lButton up}
	if (holdMode=0)
	{
		mouseClick
		if (sounds=1 && FileExist(A_WinDir "\media\Windows Balloon.wav"))
			soundPlay, %A_WinDir%\media\Windows Balloon.wav
	}
return


$numpad5:: ; go deep 1, or switches monitor
	atk:=regExReplace(A_ThisHotkey, "[\W& ]")
	didCycle:=0
	gosub, setupMonitors
	while (getKeyState(atk, "p"))
	{
		keywait, %atk%, t0.7
		ttt:=errorLevel
		if (ttt=1)
		{
			mon:=(mon<monArr.length()) ? mon+=1 : 1
			didCycle:=1
			mainGrid:=buildGrid(gridSize, 0, 0, monArr[mon].w, monArr[mon].h)
			gosub, draw
			; soundBeep
			if (sounds=1 && FileExist(A_WinDir "\media\Speech On.wav"))
				soundPlay, %A_WinDir%\media\Speech On.wav
			if (sounds=1 && !FileExist(A_WinDir "\media\Speech On.wav"))
				soundPlay, *-1
		}
		else
			break
	}
	; gosub, draw
	; soundBeep, 1500
	if (didCycle=1)
		return

numpad1::
numpad2::
numpad3::

numpad4::
numpad6::

numpad7::
numpad8::
numpad9::
	dontadd:=0
	atk:=substr(A_ThisHotkey, 7) ; atk = a_thishotkey
	chosen:=[(atk~="1|2|3") ? 3 : (atk~="4|5|6") ? 2 : 1
	        ,(atk~="1|4|7") ? 1 : (atk~="2|5|8") ? 2 : 3]
draw:
	; critical
	; toolTip % chosen.1 "," CHOSEN.2 "," IsObject(subGrid)
	w2:=monArr[mon].w
	h2:=monArr[mon].h
			
	if (IsObject(subGrid))
		ttt:=subGrid[chosen.1, chosen.2]
		, subGrid:=buildGrid(gridSize, ttt.x, ttt.y, ttt.w, ttt.h)
	else
		subGrid:=buildGrid(gridSize, monArr[mon].x1, monArr[mon].y1, w2, h2)
		
	; toolTip % deep "::" undoPressed
	if (IsObject(subGrid) && undoPressed=0)
		if (subGrid[1,1,"w"]<=1 && subGrid[1,1,"h"]<=1)
			return

	if (dontadd!=1)
		deep+=1
	deep:=clamp(deep, 1)
	undoPressed:=0
	
	; ------------------
	; ------------------
	; --- GDIP STUFF ---.
	; ------------------
	; ------------------
	Gdip_GraphicsClear(G)
	
	; ---------------
	; --- HISTORY ---
	; ---------------
	if (chosen.1!="" && chosen.2!="")
		history.push([chosen.1 , chosen.2])
	; toolTip % st_printArr(history)
	; history.="1,1|1,2"
	
	hPath:=getPath(mainGrid, gridSize, history)

	radius:=rRadius
	pSize:=alineT
	shs:=shadowS ; shadow size
	for iii, arr in hPath
	{
		if (iii=hPath.length())
			alphaFine:=format("{1:02x}", fLineA)
			, alphaS:=format("{1:02x}", ashadowA)
			, color:=(aLineC!="r") ? format("{1:02x}", aLineA) . aLineC
			    : format("{1:02x}{2:02x}{3:02x}{4:02x}", aLineA, rand(100, 255), rand(100, 255), rand(100, 255))
		else
			alphaFine:=format("{1:02x}", fLineAO)
			, alphaS:=format("{1:02x}", oshadowA)
			, color:= (oLineC!="r") ? format("{1:02x}", oLineA) . oLineC
			    : format("{1:02x}{2:02x}{3:02x}{4:02x}", oLineA, rand(40, 90), rand(40, 90), rand(40, 90))
		
		ps:=clamp(pSize, fLineT) ; pensize
		shs:=clamp(shs, fLineT) ; shadow size
		pPen := Gdip_CreatePen("0x" color, ps)
		pFine := Gdip_CreatePen("0x" alphaFine fLineC, 2)
		pShadow := Gdip_CreatePen("0x" alphaS "000000", shs)

		if (mode=1) ; lines
		{
		
			; msgBox % w2 "," h2 "`n-----`n" st_printArr(arr)
			; fine precision lines, more helpful than the thick 'style' lines
			loop, % gridSize-1
			{
				ttt:=a_index
				; toolTip % arr[ttt+1, 1, "x"]-offx "::", 500,200, 3
				; horizontal
				DrawHLine(G, pPen, pFine, pShadow
				, arr[ttt+1, 1, "x"], arr[ttt+1, 1, "y"]
				, arr[ttt+1, gridSize, "x2"], arr[ttt+1, 1, "y"])
				; vertical
				DrawVLine(G, pPen, pFine, pShadow
				, arr[1, ttt, "x2"], arr[1, 1, "y"]
				, arr[1, ttt, "x2"], arr[gridSize, gridSize, "y2"])
				
				; DrawHLine(G, pPen, pFine, pShadow, arr[3, 1, "x"], arr[3, 1, "y"], arr[3, 3, "x2"], arr[3, 1, "y"]) 
				; DrawVLine(G, pPen, pFine, pShadow, arr[2, 2, "x2"], arr[1, 1, "y"], arr[2, 2, "x2"], arr[3, 3, "y2"]) 
			}
		}
		else if (mode=2) ; rounded rect
		{
			; if it's tiny, only draw a bounding-box. tiny lines get in the way.
			if (arr[1, 1, "w"]<=5 || arr[1, 1, "h"]<=5)
				Gdip_DrawRoundedRectangle(G, pPen
				, arr[1, 1, "x"], arr[1, 1, "y"]
				, arr[1, 1, "w"]*gridSize+(PS*gridSize)
				, arr[1, 1, "h"]*gridSize+(PS*gridSize)
				, 2)
			else
				for col, v2 in arr
					for col, v3 in v2
						Gdip_DrawRoundedRectangle(G, pFine, v3.x+ps//2, v3.y+ps//2, v3.w, v3.h, clamp(radius, 1))
						, Gdip_DrawRoundedRectangle(G, pPen, v3.x+ps, v3.y+ps, v3.w-ps, v3.h-ps, clamp(radius, 1))
		}
		
		Gdip_DeletePen(pPen)
		Gdip_DeletePen(pFine)
		Gdip_DeletePen(pShadow)
		radius-=(radius/4)*iii
		pSize-=(pSize/3)*iii
		shs-=(shs/3)*iii
	}

	mid:=round(gridSize/2)
	xpos:=arr[mid, mid, "x"]+(arr[mid, mid, "w"]/2)+monArr[mon].x1
	ypos:=arr[mid, mid, "y"]+(arr[mid, mid, "h"]/2)+monArr[mon].y1
	; mouseGetPos, mx, my
	; 	mouseClickDrag, Left, %mx%, %my%, %xpos%, %ypos%, 26

		
	mousemove, %xpos%, %ypos%, % (holdMode=1) ? 26 : 0
	
	; -------------------
	; --- CURRENT DOT ---
	; -------------------
	color:=format("{1:02x}{2:02x}{3:02x}{4:02x}", 120, 255, 255, 255)
	
	pPen := Gdip_CreatePen("0x80000000", 1)
	pBrush:=Gdip_BrushCreateSolid("0x80ffffff")
	sss:=clamp(8, 2)
	Gdip_FillEllipse(G, pBrush, xpos-4, ypos-4, 8, 8) 
	Gdip_DrawEllipse(G, pPen, xpos-4, ypos-4, 8, 8) 
	Gdip_DeleteBrush(pBrush)
	Gdip_DeletePen(pPen)

	; UpdateLayeredWindow(MYHWND, hdc, 0, 0, w2, h2)
	if (isVis=1)
		UpdateLayeredWindow(MYHWND, hdc, monArr[mon].x1, monArr[mon].y1, w2, h2)
	else
	{
		Gdip_GraphicsClear(G)
		UpdateLayeredWindow(MYHWND, hdc, monArr[mon].x1, monArr[mon].y1, w2, h2)
	}
	chosen:=""
return
#if



allMonitorCoords()
{
	sysGet, count, MonitorCount
	obj:=[]
	loop, %count%
	{
		sysGet, mCoords, monitor, %A_Index%
		obj[a_index]:={"mon":A_Index, "x1":mCoordsLeft, "y1":mCoordsTop
		, "x2":mCoordsRight, "y2":mCoordsBottom
		, "w": mCoordsRight-mCoordsLeft, "h": mCoordsBottom-mCoordsTop}
	}
	return obj
}

rgbToHex(rrrgggbbb, delim:=" ")
{
	for k, v in strSplit(rrrgggbbb, delim)
		if (v!="")
			out.=format("{:02x}", clamp(v, 0, 255))
	return out
}

drawVLine(pGraphics, pPenM, pPenF, pPenS, x1, y1, x2, y2) 
{
	global ps, shs
	off:=shs//2+ps//2
	pPen := Gdip_CreatePen("0x80000000", 1)
	Gdip_DrawLine(pGraphics, pPenF, x1, y1, x2, y2) ; fine
	Gdip_DrawLine(pGraphics, pPenS, x1+off, y1, x2+off, y2) ; shadow
	Gdip_DrawLine(pGraphics, pPenM, x1, y1, x2, y2) ; base
}
drawHLine(pGraphics, pPenM, pPenF, pPenS, x1, y1, x2, y2) 
{
	global ps, shs
	off:=shs//2+ps//2
	Gdip_DrawLine(pGraphics, pPenF, x1, y1, x2, y2) ; fine
	Gdip_DrawLine(pGraphics, pPenS, x1, y1+off, x2, y2+off) ; shadow
	Gdip_DrawLine(pGraphics, pPenM, x1, y1, x2, y2) ; base
}

						
getPath(base, segments, path:="")
{
	out:=[]
	; msgBox % st_printArr(base)
	; ppp:=strSplit(path, "|", " ")
	out.push(buildGrid(segments
	, base[1,1].x
	, base[1,1].y
	, base[1,1].w*segments
	, base[1,1].h*segments))
	; msgBox % a_index st_printArr(out)
	
	if (!IsObject(path))
		return out
	for k, v in path
	{
		; ccc:=strSplit(v, ",")
		out.push(buildGrid(segments
		, out[k, v.1,v.2].x
		, out[k, v.1,v.2].y
		, out[k, v.1,v.2].w
		, out[k, v.1,v.2].h))
		; msgBox % a_index st_printArr(out)
	}
	return out
}

bright(hex, lum=0.5, mode=1) 
{
	for k, val in [substr(hex, 3, 2), substr(hex, 5, 2), substr(hex, 7, 2)] ; split the hex into an array of [##,##,##]
		val:=format("{1:d}", "0x" val) ; convert from hex, to decimal values
		, val:=round((mode=1) ? val*lum : val+lum) ; do the math
		, val:=(val<0) ? 0 : (val>255) ? 255 : val ; clamp the values between 0 and 255
		, out.=format("{1:02}", format("{1:x}", val)) ; build it again, make sure each hex thing is 2 chars long
	return out ; we're done!
}


clamp(num, min="", max="")
{
	return ((num<min && min!="") ? min : (num>max && max!="") ? max : num)
}

rand(max=100, min=1)
{
	if (min>max)
		t:=max, max:=min, min:=t
	random, r, %min%, %max%
	return r
}

buildGrid(segments:=3, xxx:="", yyy:="", www:="", hhh:="")
{
	xxx:=(xxx="") ? 0 : xxx
	yyy:=(yyy="") ? 0 : yyy
	www:=(www="") ? A_ScreenWidth : www
	hhh:=(hhh="") ? A_ScreenHeight : hhh
	cellw:=www/segments
	cellh:=hhh/segments
	grid:=[]
	loop, % segments
	{
		col:=a_index
		loop, % segments
			grid[row:=a_index, col]:=
			(join ltrim
			    {
			        x:floor(cellw*(col-1)+xxx),
			        y:floor(cellh*(row-1)+yyy),
			        x2:floor(cellw*(col-1)+cellw+xxx),
			        y2:floor(cellh*(row-1)+cellh+yyy),
			        w:floor(cellw),
			        h:floor(cellh)
			    }
	        )
	}
	return grid
}

st_printArr(array, depth=5, indentLevel="")
{
	for k,v in Array
	{
		list.= indentLevel "[" k "]"
		if (IsObject(v) && depth>1)
			list.="`n" st_printArr(v, depth-1, indentLevel . "    ")
		Else
			list.=" => " v
		list:=rtrim(list, "`r`n `t") "`n"
	}
	return rtrim(list)
}