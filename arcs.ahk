#SingleInstance, Force
;#NoTrayIcon
#NoEnv
SetBatchLines, -1

;Gdip initialization
Gui, -Caption +E0x80000 +Hwndhwnd +LastFound +ToolWindow
Gui, Show, NoActivate

;Initiate menu
if (FileExist("arcs_options.ini"))
    Menu, Context, Add, Options
Menu, Context, Add, GitHub
Menu, Context, Add
Menu, Context, Add, Reload
Menu, Context, Add, Exit

size := 430
center := size // 2

hoursHandSize := 78
minsHandSize := 124
secsHandSize := 146

pToken := Gdip_Startup()
hbm := CreateDIBSection(size, size)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
pGraphics := Gdip_GraphicsFromHDC(hdc)
Gdip_SetSmoothingMode(pGraphics, 4) ;Anti-aliasing

DrawArc(color, width, radius, angleStart, angleDraw)
{
    global center, pGraphics
    pen := Gdip_CreatePen(color, width)
    rect1 := center - radius
    width := 2 * radius
    Gdip_DrawArc(pGraphics, pen, rect1, rect1, width, width, angleStart, angleDraw)
    return
}


;Pin to desktop
IniRead, pinToDesktop, arcs_options.ini, misc, pintodesktop, 0
if (pinToDesktop)
    DllCall("SetParent", "UInt", hwnd, "UInt", DllCall("GetShellWindow"))

;Update speed
IniRead, interval, arcs_options.ini, misc, updatespeed, 1000

;Window position
IniRead, x, arcs_options.ini, position, x
IniRead, y, arcs_options.ini, position, y

;Load colors from options file
IniRead, scheme,        arcs_options.ini, scheme, name, default
IniRead, colorActive,   arcs_options.ini, %scheme%, 1, 0xFFEEEEEE
IniRead, colorActive2,  arcs_options.ini, %scheme%, 2, 0xFFAAAAAA
IniRead, colorActive3,  arcs_options.ini, %scheme%, 3, 0x37FFFFFF
IniRead, colorInactive, arcs_options.ini, %scheme%, 4, 0x30999999
IniRead, colorHands,    arcs_options.ini, %scheme%, 6, 0xFFDDFFDD
IniRead, colorHandSecs, arcs_options.ini, %scheme%, 7, 0xFF80C0FF

bColor6 := Gdip_BrushCreateSolid(colorHands)

pHands := Gdip_CreatePen(colorHands, 2)
pHandSecs := Gdip_CreatePen(colorHandSecs, 2)

;GetNumberOfInterfaces
DllCall("Iphlpapi\GetNumberOfInterfaces", "UIntP", pdwNumIf)
pdwSize := 860 * pdwNumIf + 12
VarSetCapacity(pIfTable, pdwSize)

VarSetCapacity(lpSystemPowerStatus, 12) ;GetSystemPowerStatusg
VarSetCapacity(lpBuffer, 160) ;GlobalMemoryStatus
UpdateLayeredWindow(hwnd, hdc, x < 0 or (x > A_ScreenWidth - size) ? A_ScreenWidth / 2 - center : x, y < 0 or (y > A_ScreenHeight - size) ? A_ScreenHeight / 2 - center : y, size, size)

OnExit, exit
OnMessage(0x201, "WM_LBUTTONDOWN")
OnMessage(0x207, "WM_MBUTTONDOWN")
OnMessage(0x03, "WM_MOVE")
OnMessage(0x204, "WM_RBUTTONDOWN")

SetTimer, redraw, %interval%
redraw:
Gdip_GraphicsClear(pGraphics)

; ================== backgroubd =============================
; DrawArc(0x20777777, 94, 47, 0, 360)

; =================== center ================================
ring0size := 45
ring0width := 66
; Disk (the script is executed from) space usage arc
DriveSpaceFree, driveSpaceFree, %drive%
DriveGet, capacity, Capacity, % drive := SubStr(A_ScriptDir, 1, 3)
usedSpace := (capacity - driveSpaceFree) / capacity
DrawArc(colorActive3, ring0width, ring0size, -90, usedSpace * 360)

; ===========================================================
ring1size := 92
ring1width := 10
;Default arcs for volume
DrawArc(colorInactive, ring1width, ring1size, 92, 176)

;Arcs for volume
SoundGet, volume
DrawArc(colorActive2, ring1width, ring1size, 92, volume * 176 / 100)

;Default arcs for brightness
DrawArc(colorInactive, ring1width, ring1size, 88, -176)

;Arcs for brightness
brightness := MoveBrightness(0)
DrawArc(colorActive2, ring1width, ring1size, 88, -brightness * 176 / 100)

;==========================================================
ring2size := 115
ring2width := 15
;Default arcs for CPU and RAM
DrawArc(colorInactive, ring2width, ring2size, 91, 178)
DrawArc(colorInactive, ring2width, ring2size, 89, -178)

;Arcs for CPU and RAM
DllCall("kernel32\GlobalMemoryStatus", "UInt", &lpBuffer)
memory := *(&lpBuffer + 4)
DrawArc(colorActive, ring2width, ring2size, 89, -memory * 178 / 100)

DllCall("GetSystemTimes", "UInt64P", lpIdleTime, "UInt64P", lpKernelTime, "UInt64P", lpUserTime)
usr := lpUserTime - lpUserTime2, ker := lpKernelTime - lpKernelTime2, idl := lpIdleTime - lpIdleTime2
lpUserTime2 := lpUserTime, lpKernelTime2 := lpKernelTime, lpIdleTime2 := lpIdleTime
DrawArc(colorActive, ring2width, ring2size, 91, (ker + usr - idl) * 178 / (ker + usr))

;=============================================================
ring3size := 180
ring3width := 66
ring3sizeInner := 149
ring3widthInner := 4
;Arcs for battery
DllCall("Kernel32\GetSystemPowerStatus", "UInt", &lpSystemPowerStatus)
DrawArc(colorActive3, ring3width, ring3size, -90, b:=((t := *(&lpSystemPowerStatus + 2)) = 255 ? 0 : t) * 360 / 100)

; Not filled part of frame
DrawArc(colorActive3, ring3widthInner, ring3sizeInner, -90, b-360)

;=============================================================
;Indicator hands for hour, minute, and seconds
Gdip_DrawLine(pGraphics, pHands, center, center, center - hoursHandSize * Cos(t := (A_Hour * 30 + (A_Min * 6) / 12 + 90) * 0.0174532925), center - hoursHandSize * Sin(t))
Gdip_DrawLine(pGraphics, pHands, center, center, center - minsHandSize * Cos(t := (A_Min * 6 + 90) * 0.0174532925), center - minsHandSize * Sin(t))
Gdip_DrawLine(pGraphics, pHandSecs, center, center, center - secsHandSize * Cos(t := (A_Sec * 6 + 90) * 0.0174532925), center - secsHandSize * Sin(t))

;Draw pin
Gdip_FillEllipse(pGraphics, bColor6, center - 5, center - 5, 10, 10)
 

;Default arc for hour, minute, and seconds
;Gdip_DrawArc(pGraphics, pColor5_5, 148, 148, 134, 134, 0, 360)
;Gdip_DrawArc(pGraphics, pColor5_5, 154, 154, 122, 122, 0, 360)
;Gdip_DrawArc(pGraphics, pColor5_5, 160, 160, 110, 110, 0, 360)

;Default arcs for month of year, day of month
;Gdip_DrawArc(pGraphics, pColor5_5, 132, 132, 166, 166, 120, 150)
;Gdip_DrawArc(pGraphics, pColor5_5, 140, 140, 150, 150, 120, 90)



;Default arcs for network I/O
;Gdip_DrawArc(pGraphics, pColor5_5, 140, 140, 150, 150, -32, 32)
;Gdip_DrawArc(pGraphics, pColor5_5, 134, 134, 162, 162, -32, 32)



;Default arcs for HDD (D:, E:, and F:)
;Gdip_DrawArc(pGraphics, pColor5_15, 135, 135, 160, 160, 36, 26)
;Gdip_DrawArc(pGraphics, pColor5_15, 135, 135, 160, 160, 64, 26)
;Gdip_DrawArc(pGraphics, pColor5_15, 135, 135, 160, 160, 92, 26)



;Arcs for hour, minute, and seconds
;Gdip_DrawArc(pGraphics, pColor1_5, 148, 148, 134, 134, -90, Mod((A_Hour + A_Min / 60) * 30, 360))
;Gdip_DrawArc(pGraphics, pColor2_5, 154, 154, 122, 122, -90, A_Min * 6)
;Gdip_DrawArc(pGraphics, pColor3_5, 160, 160, 110, 110, -90, A_Sec * 6)

;Arcs for month of year and day of month
;Gdip_DrawArc(pGraphics, pColor2_5, 132, 132, 166, 166, 120, (A_Mon / 12) * 150)
;Gdip_DrawArc(pGraphics, pColor3_5, 140, 140, 150, 150, 120, (A_DD / A_LastDay()) * 90)



;Arcs for network I/O
; DllCall("Iphlpapi\GetIfTable", "UInt", &pIfTable, "UIntP", pdwSize, "Int", true)
; Loop, % decodeInteger(&pIfTable)
    ; down += decodeInteger((t := (&pIfTable + 860 * (A_Index - 1))) + 556), up += decodeInteger(t + 580)
; downRate := (down - down2) / 1024, upRate := (up - up2) / 1024
; down2 := down, up2 := up, down := 0, up := 0
; Gdip_DrawArc(pGraphics, pColor1_5, 140, 140, 150, 150, 0, -(downRate > 255 ? 255 : downRate) * 0.1254901961)
; Gdip_DrawArc(pGraphics, pColor1_5, 134, 134, 162, 162, 0, -(upRate > 255 ? 255 : upRate) * 0.1254901961)


;Arcs for HDD (D:, E:, and F:)
;DriveSpaceFree, driveSpaceFree, D:
;DriveGet, capacity, Capacity, D:
;Gdip_DrawArc(pGraphics, pColor3_15, 135, 135, 160, 160, 49, (capacity - driveSpaceFree) / capacity * 13)
;Gdip_DrawArc(pGraphics, pColor3_15, 135, 135, 160, 160, 49, (capacity - driveSpaceFree) / capacity * -13)

; DriveSpaceFree, driveSpaceFree, E:
; DriveGet, capacity, Capacity, E:
; Gdip_DrawArc(pGraphics, pColor3_15, 135, 135, 160, 160, 77, (capacity - driveSpaceFree) / capacity * 13)
; Gdip_DrawArc(pGraphics, pColor3_15, 135, 135, 160, 160, 77, (capacity - driveSpaceFree) / capacity * -13)

; DriveSpaceFree, driveSpaceFree, F:
; DriveGet, capacity, Capacity, F:
; Gdip_DrawArc(pGraphics, pColor3_15, 135, 135, 160, 160, 105, (capacity - driveSpaceFree) / capacity * 13)
; Gdip_DrawArc(pGraphics, pColor3_15, 135, 135, 160, 160, 105, (capacity - driveSpaceFree) / capacity * -13)

UpdateLayeredWindow(hwnd, hdc)
return


A_LastDay(){
    time := A_YYYY A_MM
    time += 31, D
    tme := SubStr(time, 1, 6)
    time -= A_YYYY A_MM, D
    Return time
}
decodeInteger(ptr)
{
    Return *ptr | *++ptr << 8 | *++ptr << 16 | *++ptr << 24
}
WM_LBUTTONDOWN(wParam, lParam){
    PostMessage, 0xA1, 2
}
WM_MOVE(wParam, lParam){
    WinGetPos, x, y
    IniWrite, %x%, arcs_options.ini, position, x
    IniWrite, %y%, arcs_options.ini, position, y
}
WM_RBUTTONDOWN(wParam, lParam){
    Menu, Context, Show
}

return
;Open arcs_options.ini or prompt to download if not exist
Options:
if (FileExist("arcs_options.ini"))
    Run, notepad arcs_options.ini

return
;Visit project page on GitHub
GitHub:
Run, https://github.com/NameLess-exe/arcs

return
;Reload
Reload:
Reload

return
;ExitApp
Exit:
GuiClose:
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Gdip_DeleteGraphics(G)
Gdip_Shutdown(pToken)
ExitApp

#Include Gdip.ahk


MoveBrightness(IndexMove)
{

    VarSetCapacity(SupportedBrightness, 256, 0)
    VarSetCapacity(SupportedBrightnessSize, 4, 0)
    VarSetCapacity(BrightnessSize, 4, 0)
    VarSetCapacity(Brightness, 3, 0)
    
    hLCD := DllCall("CreateFile"
    , Str, "\\.\LCD"
    , UInt, 0x80000000 | 0x40000000 ;Read | Write
    , UInt, 0x1 | 0x2  ; File Read | File Write
    , UInt, 0
    , UInt, 0x3  ; open any existing file
    , UInt, 0
      , UInt, 0)
    
    if hLCD != -1
    {
        
        DevVideo := 0x00000023, BuffMethod := 0, Fileacces := 0
          NumPut(0x03, Brightness, 0, "UChar")   ; 0x01 = Set AC, 0x02 = Set DC, 0x03 = Set both
          NumPut(0x00, Brightness, 1, "UChar")      ; The AC brightness level
          NumPut(0x00, Brightness, 2, "UChar")      ; The DC brightness level
        DllCall("DeviceIoControl"
          , UInt, hLCD
          , UInt, (DevVideo<<16 | 0x126<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_QUERY_DISPLAY_BRIGHTNESS
          , UInt, 0
          , UInt, 0
          , UInt, &Brightness
          , UInt, 3
          , UInt, &BrightnessSize
          , UInt, 0)
        
        DllCall("DeviceIoControl"
          , UInt, hLCD
          , UInt, (DevVideo<<16 | 0x125<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_QUERY_SUPPORTED_BRIGHTNESS
          , UInt, 0
          , UInt, 0
          , UInt, &SupportedBrightness
          , UInt, 256
          , UInt, &SupportedBrightnessSize
          , UInt, 0)
        
        ACBrightness := NumGet(Brightness, 1, "UChar")
        ACIndex := 0
        DCBrightness := NumGet(Brightness, 2, "UChar")
        DCIndex := 0
        BufferSize := NumGet(SupportedBrightnessSize, 0, "UInt")
        MaxIndex := BufferSize-1

        Loop, %BufferSize%
        {
        ThisIndex := A_Index-1
        ThisBrightness := NumGet(SupportedBrightness, ThisIndex, "UChar")
        if ACBrightness = %ThisBrightness%
            ACIndex := ThisIndex
        if DCBrightness = %ThisBrightness%
            DCIndex := ThisIndex
        }
        
        if IndexMove = 0
        {
            ; in my tests always ACBrightness == DCBrightness
            ; changes in range 5 - 100
            return ACBrightness
        }
        
        if DCIndex >= %ACIndex%
          BrightnessIndex := DCIndex
        else
          BrightnessIndex := ACIndex
          
        ; if IndexMove = 0
        ; {
            ; return BrightnessIndex
        ; }

        BrightnessIndex += IndexMove
        
        if BrightnessIndex > %MaxIndex%
           BrightnessIndex := MaxIndex
           
        if BrightnessIndex < 0
           BrightnessIndex := 0

        NewBrightness := NumGet(SupportedBrightness, BrightnessIndex, "UChar")
        
        NumPut(0x03, Brightness, 0, "UChar")   ; 0x01 = Set AC, 0x02 = Set DC, 0x03 = Set both
        NumPut(NewBrightness, Brightness, 1, "UChar")      ; The AC brightness level
        NumPut(NewBrightness, Brightness, 2, "UChar")      ; The DC brightness level
        
        DllCall("DeviceIoControl"
            , UInt, hLCD
            , UInt, (DevVideo<<16 | 0x127<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_SET_DISPLAY_BRIGHTNESS
            , UInt, &Brightness
            , UInt, 3
            , UInt, 0
            , UInt, 0
            , UInt, 0
            , Uint, 0)
        
        DllCall("CloseHandle", UInt, hLCD)
    
    }

}