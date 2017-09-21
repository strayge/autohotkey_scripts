; #NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; #NoTrayicon
; Menu, Tray, Icon, tray.ico,1
; Menu, Tray, NoStandard
; Menu, Tray, Add, Toggle Touch, Toggle
; Menu, Tray, Add, 
; Menu, Tray, Standard
; Menu, Tray, Default, Toggle Touch

isTouchscreenEnabled := GetCurrentStatus()

ToogleTouchScreen()
{
    global isTouchscreenEnabled
    if (isTouchscreenEnabled = 1) 
    {
        Run DevManView.exe /disable "HID-compliant touch screen"	; path to DevManView and disable device with this name/ID
        isTouchscreenEnabled := 0
        ; Menu, Tray, Icon , trayd.ico,,1
        traytip, Touchscreen, disabled	; little tooltip displayed to visualize the current action
        ;SetTimer, RemoveToolTip, 2000
    } else {
        Run DevManView.exe /enable "HID-compliant touch screen"	; path to DevManView and enable device with this name/ID
        isTouchscreenEnabled := 1
        ; Menu, Tray, Icon , tray.ico,,1
        traytip, Touchscreen, enabled	; little tooltip displayed to visualize the current action
        ;SetTimer, RemoveToolTip, 2000
    }
    return
}

; Toggle: ; double click tray icon to disable/enable
    ; Hotkey to disable/enable

GetCurrentStatus()
{
    Run DevManView.exe /stab temp.csv
    sleep, 1000
    isEnabled := 1
    Loop, read, temp.csv
    {
        stringParts := StrSplit(A_LoopReadLine, A_Tab)
        name:=stringParts[1]
        if (name = "HID-compliant touch screen")
        {
            status:=stringParts[10]
            if (status = "Yes")
            {
                isEnabled := 0
            }
            break
        }
    }
    FileDelete, temp.csv    
    return isEnabled
}
    
#t::ToogleTouchScreen()

;RemoveToolTip:
;SetTimer, RemoveToolTip, Off
;ToolTip
;return
