; #NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; ; #Warn  ; Enable warnings to assist with detecting common errors.
; SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


; This should be replaced by whatever your native language is. See 
; http://msdn.microsoft.com/en-us/library/dd318693%28v=vs.85%29.aspx
; for the language identifiers list.
ru := DllCall("LoadKeyboardLayout", "Str", "00000419", "Int", 1)
en := DllCall("LoadKeyboardLayout", "Str", "00000409", "Int", 1)

ConvertText(text, current_layout)
{
    AutoTrimOld := A_AutoTrim
    StringCaseSenseOld := A_StringCaseSense
    AutoTrim,Off
    StringCaseSense,On

    listEN=``1234567890-=qwertyuiop[]asdfghjkl`;'zxcvbnm,./~!@#$`%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?
    listRU=ё1234567890-=йцукенгшщзхъфывапролджэячсмитьбю.Ё!"№`;`%:?*()_+ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,
    ; "
    
    dest:=""
    loop, parse, text
    {
        destChar = %A_LoopField%
        if (current_layout = "en")
        {
            StringGetPos, pos1, listEN, %destChar%
            if pos1 >= 0
            {
                destChar := SubStr(listRU, pos1+1, 1)
            }
        }
        else if (current_layout = "ru")
        {
            StringGetPos, pos1, listRU, %destChar%
            if pos1 >= 0
            {
                destChar := SubStr(listEN, pos1+1, 1)
            }
        }
        dest=%dest%%destChar%
    }
    AutoTrim, %AutoTrimOld%
    StringCaseSense, %StringCaseSenseOld%
    return dest
}

InvertLayout(text, current_layout)
{
    AutoTrimOld := A_AutoTrim
    StringCaseSenseOld := A_StringCaseSense
    AutoTrim,Off
    StringCaseSense,On

    listEN=``1234567890-=qwertyuiop[]asdfghjkl`;'zxcvbnm,./~!@#$`%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?
    listRU=ё1234567890-=йцукенгшщзхъфывапролджэячсмитьбю.Ё!"№`;`%:?*()_+ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,
    ; "
    
    dest:=""
    loop, parse, text
    {
        destChar = %A_LoopField%
        StringGetPos, pos1, listEN, %destChar%
        StringGetPos, pos2, listRU, %destChar%
        if (current_layout = "en")
        {
            if pos1 >= 0
            {
                destChar := SubStr(listRU, pos1+1, 1)
            }
            else if pos2 >= 0
            {
                destChar := SubStr(listEN, pos2+1, 1)
            }
        }
        else if (current_layout = "ru")
        {
            if pos2 >= 0
            {
                destChar := SubStr(listEN, pos2+1, 1)
            }
            else if pos1 >= 0
            {
                destChar := SubStr(listRU, pos1+1, 1)
            }
        }
        dest=%dest%%destChar%
    }
    AutoTrim, %AutoTrimOld%
    StringCaseSense, %StringCaseSenseOld%
    return dest
}


InvertCase(text)
{
    AutoTrimOld := A_AutoTrim
    StringCaseSenseOld := A_StringCaseSense
    AutoTrim,Off
    StringCaseSense,On

    listLow=qwertyuiopasdfghjklzxcvbnmйцукенгшщзхъфывапролджэячсмитьбю
    listHigh=QWERTYUIOPASDFGHJKLZXCVBNMЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ
    
    dest:=""
    loop, parse, text
    {
        destChar = %A_LoopField%
        StringGetPos, pos1, listLow, %destChar%
        StringGetPos, pos2, listHigh, %destChar%
        if pos1 >= 0
        {
            destChar := SubStr(listHigh, pos1+1, 1)
        }
        else if pos2 >= 0
        {
            destChar := SubStr(listLow, pos2+1, 1)
        }
        dest=%dest%%destChar%
    }
    AutoTrim, %AutoTrimOld%
    StringCaseSense, %StringCaseSenseOld%
    return dest
}

CapsLock::
    ClipSaved := ClipboardAll

    clipboard := ""
    Send, ^{sc02E}  ; ctrl+c
    ClipWait, 0.1
    clip_content:=clipboard
    
    if DllCall("IsClipboardFormatAvailable", "uint", 1) {
        ;MsgBox Clipboard contains text.
        
        w := DllCall("GetForegroundWindow")
        pid := DllCall("GetWindowThreadProcessId", "UInt", w, "Ptr", 0)
        l := DllCall("GetKeyboardLayout", "UInt", pid)
        
        if (l = en)
        {
            new_str := InvertLayout(clip_content, "en")
            PostMessage 0x50, 0, %ru%,, A
        }
        else
        {
            new_str := InvertLayout(clip_content, "ru")
            PostMessage 0x50, 0, %en%,, A
        }
        ;new_str := InvertLayout(clip_content)
        
        clipboard := new_str
        sleep 100
        Send, ^{sc02F}  ; ctrl+v
        sleep 100
    }
    else if DllCall("IsClipboardFormatAvailable", "uint", 15) {
        ;MsgBox Clipboard contains files.
    }
    else {
        ;MsgBox Clipboard does not contain files or text.
    }

    Clipboard := ClipSaved
    ClipSaved := ""
    return

+CapsLock::
    ClipSaved := ClipboardAll

    clipboard := ""
    Send, ^{sc02E}  ; ctrl+c
    ClipWait, 0.1
    clip_content:=clipboard
    
    if DllCall("IsClipboardFormatAvailable", "uint", 1) {
        ;MsgBox Clipboard contains text.
        new_str := InvertCase(clip_content)
        
        clipboard := new_str
        sleep 100
        Send, ^{sc02F}  ; ctrl+v
        sleep 100
    }
    else if DllCall("IsClipboardFormatAvailable", "uint", 15) {
        ;MsgBox Clipboard contains files.
    }
    else {
        ;MsgBox Clipboard does not contain files or text.
    }

    Clipboard := ClipSaved
    ClipSaved := ""
    return


