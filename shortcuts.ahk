; =========================================================================
; Author: strayge
; =========================================================================
#SingleInstance, Force
#Persistent
#MaxHotkeysPerInterval 200
SetWorkingDir %A_ScriptDir%
; hints: # - win, ! - alt, ^ - ctrl, + - shift

; =========================================================================
;                                 SETTINGS
; =========================================================================
REMAP_HOMEEND_TO_PAGEUPDOWN = 1
ALWAYS_ON_TOP_AND_TRANSPARENCY = 1
SLEEP_AND_HIBERNATE = 1
EXPLORER_BACKSPACE_TO_TOP = 0
TOUCHPAD_3FINGERS_CUSTOM = 1
EXPLORER_CUSTOM_EDITORS = 1
CMD_IN_CURRENT_FOLDER = 1
DESKTOP_CORNERS = 1
PUNTO = 1
DESKTOP_SWITCHER = 1
TOUCHSCREEN_SWITCHER = 1
CPU_CHECKER = 1

; ==========================================================================
;                        Actions for desktop Corners
; ==========================================================================
; Must be placed before keyboard shortcuts
if DESKTOP_CORNERS 
{
    #include desktop_corners.ahk
}

; ==========================================================================
;                          Monitor for CPU loading
; ==========================================================================
; Must be placed before keyboard shortcuts
if CPU_CHECKER {
    #include cpu_checker.ahk
}

; ==========================================================================
;                         Switcher for TouchScreen
; ==========================================================================
if TOUCHSCREEN_SWITCHER {
#if TOUCHSCREEN_SWITCHER
#include touchscreen_switcher.ahk
#if
}

; ==========================================================================
;                    Switch between Virtual Desktops
; ==========================================================================
#KeyHistory 500
if DESKTOP_SWITCHER {
#if DESKTOP_SWITCHER
    #include desktop_switcher.ahk
#if
}

; ==========================================================================
;              Analog of Punto Switcher by CapsLock shortcut
; ==========================================================================
If PUNTO {
#if PUNTO
#include punto.ahk
#if
}

; =========================================================================
;                  HOME/END remapping to PAGEUP/PAGEDOWN
; =========================================================================
#If REMAP_HOMEEND_TO_PAGEUPDOWN
; remap pageup/pagedown to home/end
sc149::vk24sc147
sc151::vk23sc14F
sc147::vk21sc149
sc14F::vk22sc151
#If

; =========================================================================
;                 Always on Top and changing Transparency
; =========================================================================
#If ALWAYS_ON_TOP_AND_TRANSPARENCY
; always on top
#SPACE:: Winset, Alwaysontop, , A
return

; transparency increase
#WheelUp::
WinGet, transparency, Transparent, A
if (transparency = "")
{
    transparency := 255
}
if transparency < 255
{
    transparency := Transparency + 10
} else {
    transparency := 255
}
Winset, Transparent, %transparency%, A
return

; transparency decrease
#WheelDown::
WinGet, transparency, Transparent, A
if (transparency = "")
{
    transparency := 255
}
if transparency > 30
{
    transparency := transparency - 10
} else {
    transparency := 30
}
Winset, Transparent, %transparency%, A
return

#0::
Winset, Transparent, 255, A
return
#If
; =========================================================================
;                    SLEEP and HIBERNATE shortcuts
; =========================================================================
#If SLEEP_AND_HIBERNATE
; hibernate win+q
#sc010 UP::DllCall("PowrProf\SetSuspendState", "int", 1, "int", 1, "int", 1)
return

; sleep win+s
#sc01F UP::
ChangeActiveLayoutToEng()
Send #{vk58sc02D} ; win+x
Send {vk55sc016} ; u
Send {vk53sc01F} ; s
return
#If

; =========================================================================
;              Touchpad, 3-fingers shortcuts with app-context
; =========================================================================
#If TOUCHPAD_3FINGERS_CUSTOM and WinActive("ahk_class MozillaWindowClass")
; needed custom settings for touchpad
; #IfWinActive, ahk_class MozillaWindowClass
vk7d::  ; f14
Send, ^{vk57sc011}  ; ctrl+w
return

vk7c::  ; f13
Send, ^{vk54sc014}  ; ctrl+t
return
; #IfWinActive
#If

; ==========================================================================
;                      Shortcut: Top folder in Explorer
; ==========================================================================
#If EXPLORER_BACKSPACE_TO_TOP and WinActive("ahk_class CabinetWClass")
; explorer: backspace - top level folder
; #IfWinActive, ahk_class CabinetWClass
Backspace::SendInput {Alt Down}{Up}{Alt Up}
return
; #IfWinActive
#If

; =========================================================================
;          Notepad++ and HxD editors for selected file in Explorer
; =========================================================================
; explorer: win+e - open current file with Notepad++
#If, EXPLORER_CUSTOM_EDITORS and (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class WorkerW"))
f3::
    ClipboardSaved := ClipboardAll  ; save
    clipboard = 
    Send, ^{sc02E}  ; ctrl+c
    ClipWait, 0.2, 1
    fileAttribs := FileExist( clipboard )
    if ( !fileAttribs or InStr(fileAttribs, "D") )
    {
        return
    }
    NotepadPath := "C:\Program Files\Notepad++\notepad++.exe"
    Run "%NotepadPath%" "%clipboard%"
    Clipboard := ClipboardSaved  ; restore
    ClipSaved =   ; memory free (in case of large clip size)
    return
f4::
    ClipboardSaved := ClipboardAll  ; save
    clipboard = 
    Send, ^{sc02E}  ; ctrl+c
    ClipWait, 0.2, 1
    fileAttribs := FileExist( clipboard )
    if ( !fileAttribs or InStr(fileAttribs, "D") )
    {
        return
    }
    HexEditorPath := "c:\Program Files (x86)\totalcmd\Utilites\HxD\HxD.exe"
    Run "%HexEditorPath%" "%clipboard%"
    Clipboard := ClipboardSaved  ; restore
    ClipSaved =   ; memory free (in case of large clip size)
    return
#If

; =========================================================================
;             Start CMD in current folder in Explorer
; =========================================================================
#If CMD_IN_CURRENT_FOLDER and WinActive("ahk_class CabinetWClass")
; explorer: win+c: cmd in current folder
; #IfWinActive, ahk_class CabinetWClass
; win+c
#sc02E UP::
;ClipSaved := ClipboardAll
WinGetText, full_path, A
StringSplit, word_array, full_path, `n
Loop, %word_array0%
{
    IfInString, word_array%A_Index%, Address
    {
        full_path := word_array%A_Index%
        break
    }
} 
full_path := RegExReplace(full_path, "^Address: ", "")
StringReplace, full_path, full_path, `r, , all
IfInString full_path, \
{
    Run,  cmd /K cd /D "%full_path%"
}
else
{
    ;Run, cmd /K cd /D "C:\ "
    ChangeActiveLayoutToEng()
    Send !{vk44sc020} ; !d
    Send {ASC 99}{ASC 109}{ASC 100} ; cmd
    Send {Enter}
}
return
; #IfWinActive


; explorer: win+shift+c: cmd in current folder as admin
; #IfWinActive, ahk_class CabinetWClass
; win+shift+c
#+sc02E UP::
    ;ClipSaved := ClipboardAll
    WinGetText, full_path, A
    StringSplit, word_array, full_path, `n
    Loop, %word_array0%
    {
        IfInString, word_array%A_Index%, Address
        {
            full_path := word_array%A_Index%
            break
        }
    } 
    full_path := RegExReplace(full_path, "^Address: ", "")
    StringReplace, full_path, full_path, `r, , all
    IfInString full_path, \
    {
        Run *RunAs "cmd" /K cd /D "%full_path%"
        ; /K cd /D "%full_path%"
    }
    else
    {
        ; powershell.exe -Command "Start-Process cmd \"/k cd /d $((Resolve-Path .\).Path)\" -Verb RunAs"
        ; sleep, 1000
        ClipboardSaved := ClipboardAll  ; save
        Clipboard = powershell.exe -Command "Start-Process cmd \"/k cd /d $((Resolve-Path .\).Path)\" -Verb RunAs"
        ChangeActiveLayoutToEng()
        Send !{vk44sc020} ; !d
        sleep 100
        Send, ^{sc02F}  ; ctrl+v
        sleep 100
        Send {Enter}
        Clipboard := ClipboardSaved  ; restore
        ClipSaved =   ; memory free (in case of large clip size)
    }
    return
; #IfWinActive
#If


; ==========================================================================
;                              Common functions
; ==========================================================================
global en := DllCall("LoadKeyboardLayout", "Str", "00000409", "Int", 1)
ChangeActiveLayoutToEng()
{
    WinGet, window_id, ID, A
    pid := DllCall("GetWindowThreadProcessId", "UInt", window_id, "Ptr", 0)
    layout := DllCall("GetKeyboardLayout", "UInt", pid)
    if (layout != en)
    {
        sleep 200
        PostMessage 0x50, 0, %en%,, A
        sleep 200
        WinActivate, ahk_id %window_id%
        sleep 200
    }
    return
}

; ==========================================================================
