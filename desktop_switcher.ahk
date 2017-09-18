; For faster switching with standard method needs to disable "Animate windows when minimizing and maximizing"
; in SystemPropertiesAdvanced.exe -> Advanced -> Performance -> Settings -> Visual Effects

; Globals
DesktopCount := 4       ; Windows starts with 2 desktops at boot
CurrentDesktop := 1     ; Desktop count is 1-indexed (Microsoft numbers them this way)
PreviousDesktop := 1    ; Number of previous desktop
UseAltSwitchAfter := 2  ; Use alternative (TaskView) switch method if distance is more than this variable

KeyDelayStandartSwitch := 100 ; Delay between switching each desktop in standard mode.

;
; This function examines the registry to build an accurate list of the current virtual desktops and which one we're currently on.
; Current desktop UUID appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\1\VirtualDesktops
; List of desktops appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops
;
mapDesktopsFromRegistry() {
    global CurrentDesktop, DesktopCount, PreviousDesktop

    ; Get the current desktop UUID. Length should be 32 always, but there's no guarantee this couldn't change in a later Windows release so we check.
    IdLength := 32
    SessionId := getSessionId()
    if (SessionId) {
        RegRead, CurrentDesktopId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%SessionId%\VirtualDesktops, CurrentVirtualDesktop
        if (CurrentDesktopId) {
            IdLength := StrLen(CurrentDesktopId)
        }
    }

    ; Get a list of the UUIDs for all virtual desktops on the system
    RegRead, DesktopList, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
    if (DesktopList) {
        DesktopListLength := StrLen(DesktopList)
        ; Figure out how many virtual desktops there are
        DesktopCount := DesktopListLength / IdLength
    }
    else {
        DesktopCount := 1
    }

    ; Parse the REG_DATA string that stores the array of UUID's for virtual desktops in the registry.
    i := 0
    while (CurrentDesktopId and i < DesktopCount) {
        StartPos := (i * IdLength) + 1
        DesktopIter := SubStr(DesktopList, StartPos, IdLength)
        ; OutputDebug, The iterator is pointing at %DesktopIter% and count is %i%.

        ; Break out if we find a match in the list. If we didn't find anything, keep the
        ; old guess and pray we're still correct :-D.
        if (DesktopIter = CurrentDesktopId) {
            if (CurrentDesktop <> i + 1) {
                PreviousDesktop := CurrentDesktop
                CurrentDesktop := i + 1
            }
            ; OutputDebug, Current desktop number is %CurrentDesktop% with an ID of %DesktopIter%.
            break
        }
        i++
    }
}

;
; This functions finds out ID of current session.
;
getSessionId()
{
    ProcessId := DllCall("GetCurrentProcessId", "UInt")
    if ErrorLevel {
        ; OutputDebug, Error getting current process id: %ErrorLevel%
        return
    }
    ; OutputDebug, Current Process Id: %ProcessId%

    DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
    if ErrorLevel {
        ; OutputDebug, Error getting session id: %ErrorLevel%
        return
    }
    ; OutputDebug, Current Session Id: %SessionId%
    return SessionId
}

;
; This function restores window's focus after switching 
; desktop with new method (throught TaskView)
;
restoreActiveWindow()
{
    WinGetClass, ActiveClassName, A
    if (ActiveClassName == "MultitaskingViewFrame") {
        ; Waiting desktop switching
        Sleep, 100
        ; Activating last window
        Send, !{Esc}
    }
    
}

;
; This function switches to the desktop number provided.
;
switchDesktopByNumber(targetDesktop)
{
    global CurrentDesktop, DesktopCount, PreviousDesktop, UseAltSwitchAfter, KeyDelayStandartSwitch

    ; Re-generate the list of desktops and where we fit in that. We do this because
    ; the user may have switched desktops via some other means than the script.
    mapDesktopsFromRegistry()

    ; Don't switch to current desktop
    if (targetDesktop = CurrentDesktop) {
        return
    }

    ; Don't attempt to switch to an invalid desktop
    if (targetDesktop > DesktopCount || targetDesktop < 1) {
        ; OutputDebug, [invalid] target: %targetDesktop% current: %CurrentDesktop%
        return
    }

    PreviousDesktop := CurrentDesktop

    if (Abs(CurrentDesktop - targetDesktop) < UseAltSwitchAfter + 1) {
        ; Set delay between keys to prevent skipping some of them
        SetKeyDelay, KeyDelayStandartSwitch
        
        ; Go right until we reach the desktop we want
        while (CurrentDesktop < targetDesktop) {
            Send ^#{Right}
            CurrentDesktop++
            ; OutputDebug, [right] target: %targetDesktop% current: %CurrentDesktop%
        }

        ; Go left until we reach the desktop we want
        while (CurrentDesktop > targetDesktop) {
            Send ^#{Left}
            CurrentDesktop--
            ; OutputDebug, [left] target: %targetDesktop% current: %CurrentDesktop%
        }
        
        ; Remove delay between keys
        SetKeyDelay, -1
    } else {
        ; Open task view and wait for it to become active
        Loop
        {
            ; OutputDebug, Opening Task View
            Send, #{Tab}
            ; OutputDebug, Waiting for Task View
            WinWaitActive, ahk_class MultitaskingViewFrame,, 0.2
            if ErrorLevel {
                ; OutputDebug, Timed out waiting for task view
            }
            else {
                break
            }
        }

        ; Focus on desktops
        Send, {Tab}

        ; Page through desktops without opening any
        if (targetDesktop > 1) {
            targetDesktop--
            Send, {Right %targetDesktop%}
            targetDesktop++
        }

        ; Finally, select the desktop
        Send, {Enter}
        CurrentDesktop := targetDesktop
        
        ; Restore focus
        ; restoreActiveWindow()
    }
}

;
; This function moves active window to the desktop number provided.
;
moveCurrentWindowToDesktopByNumber(targetDesktop)
{
    global CurrentDesktop, DesktopCount

    ; Re-generate the list of desktops and where we fit in that. We do this because
    ; the user may have switched desktops via some other means than the script.
    mapDesktopsFromRegistry()

    ; Don't move to current desktop
    if (targetDesktop = CurrentDesktop) {
        return
    }

    ; Don't attempt to move to an invalid desktop
    if (targetDesktop > DesktopCount || targetDesktop < 1) {
        ; OutputDebug, [invalid] target: %targetDesktop% current: %CurrentDesktop%
        return
    }

    ; Open task view and wait for it to become active
    Loop
    {
        ; OutputDebug, Opening Task View
        Send, #{Tab}
        ; OutputDebug, Waiting for Task View
        WinWaitActive, ahk_class MultitaskingViewFrame,, 0.2
        if ErrorLevel {
            ; OutputDebug, Timed out waiting for task view
        }
        else {
            break
        }
    }
    
    ; Show context menu for active window
    Send, {AppsKey}
    
    ; Select Move item
    Send, m
    
    ; Count how many Down keys needed
    downKeyCount := targetDesktop - 1
    ; Current desktop not showed in menu, so decrease count by 1
    if (targetDesktop > CurrentDesktop) {
        downKeyCount--
    }
    
    ; Select targetDesktop in menu
    Send, {Down %downKeyCount%}
    
    ; Send window to selected desktop
    Send, {Enter}
    
    ; Close TaskView
    Send, {Esc}
}

;
; This function switches to last desktop where you were before
;
switchToPreviousDesktop()
{
    global PreviousDesktop
    switchDesktopByNumber(PreviousDesktop)
}

;
; This function creates a new virtual desktop and switches to it
;
createVirtualDesktop()
{
    global CurrentDesktop, DesktopCount, PreviousDesktop
    Send, #^d
    DesktopCount++
    PreviousDesktop := CurrentDesktop
    CurrentDesktop := DesktopCount
    ; OutputDebug, [create] desktops: %DesktopCount% current: %CurrentDesktop%
}

;
; This function deletes the current virtual desktop
;
deleteVirtualDesktop()
{
    global CurrentDesktop, DesktopCount, PreviousDesktop
    Send, #^{F4}
    DesktopCount--
    CurrentDesktop--
    PreviousDesktop := CurrentDesktop
    ; OutputDebug, [delete] desktops: %DesktopCount% current: %CurrentDesktop%
}

; Main
mapDesktopsFromRegistry()
PreviousDesktop := CurrentDesktop
; OutputDebug, [loading] desktops: %DesktopCount% current: %CurrentDesktop%

; User config!
; This section binds the key combo to the switch/create/delete actions
#1 Up::switchDesktopByNumber(1)
#2 Up::switchDesktopByNumber(2)
#3 Up::switchDesktopByNumber(3)
#4 Up::switchDesktopByNumber(4)
#5 Up::switchDesktopByNumber(5)
#6 Up::switchDesktopByNumber(6)
#7 Up::switchDesktopByNumber(7)
#8 Up::switchDesktopByNumber(8)
#9 Up::switchDesktopByNumber(9)
^#1 Up::moveCurrentWindowToDesktopByNumber(1)
^#2 Up::moveCurrentWindowToDesktopByNumber(2)
^#3 Up::moveCurrentWindowToDesktopByNumber(3)
^#4 Up::moveCurrentWindowToDesktopByNumber(4)
^#5 Up::moveCurrentWindowToDesktopByNumber(5)
^#6 Up::moveCurrentWindowToDesktopByNumber(6)
^#7 Up::moveCurrentWindowToDesktopByNumber(7)
^#8 Up::moveCurrentWindowToDesktopByNumber(8)
^#9 Up::moveCurrentWindowToDesktopByNumber(9)
; #n Up::switchDesktopByNumber(CurrentDesktop + 1)
; #p Up::switchDesktopByNumber(CurrentDesktop - 1)
#= Up::createVirtualDesktop()
#- Up::deleteVirtualDesktop()
#` Up::switchToPreviousDesktop()