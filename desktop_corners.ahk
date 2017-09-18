; Put your hotcorner actions here
Action_TopLeft() {
    Send, {LWin down}{Tab down}
    Send, {Lwin up}{Tab up}
}
Action_BottomRight() {
    return
}
Action_BottomLeft() {
    return
}
Action_TopRight() {
    return
}
GetCorner(x, y, cornerIndex, tolerance)
{
    ; loop through each monitor
    for idx, elem in ScreenArray
    {
        if (cornerIndex == 0) { ; Top Left
            ; If statements are so it doesn't break the for loop on the first false. It will only return if true
            if (x >= elem[1] and x <= elem[1] + tolerance) and (y >= elem[2] and y <= elem[2] + tolerance) {
                return True
            }
        } else if (cornerIndex == 1) { ; Top Right
            if (x >= elem[3] - tolerance and x <= elem[3]) and (y >= elem[2] and y <= elem[2] + tolerance) {
                return True
            }
        } else if (cornerIndex == 2) { ; Bottom Right
            if (x >= elem[3] - tolerance and x <= elem[3]) and (y >= elem[4] - tolerance and y <= elem[4]) {
                return True
            }
        } else { ; Bottom Left
            if (x >= elem[1] and x <= elem[1] + tolerance) and (y >= elem[4] - tolerance and y <= elem[4]) {
                return True
            }
        }
    }
}
HotCorners()
{
    CoordMode, Mouse, Screen
    MouseGetPos, MouseX, MouseY
    if GetCorner(MouseX, MouseY, 0, tolerance) {    ; TopLeft
        Action_TopLeft()
        Sleep, 1000
    } else if GetCorner(MouseX, MouseY, 1, tolerance) {     ; TopRight
        Action_TopRight()
        Sleep, 1000
    } else if GetCorner(MouseX, MouseY, 3, tolerance) {     ; BottomLeft
        Action_BottomLeft()
        Sleep, 1000
    } else if GetCorner(MouseX, MouseY, 2, tolerance) {     ; BottomRight
        Action_BottomRight()
        Sleep, 1000
    }
    return
}

global tolerance = 5   ; Adjust tolerance if needed
global ScreenArray := Object()
; Get the number of monitors
SysGet, NumMonitors, MonitorCount
; Insert a new empty array for each monitor
Loop %NumMonitors% {
    ScreenArray.Insert(Object())
}
; For each monitor, get the dimensions as coordinates
for index, element in ScreenArray 
{
    ; get monitor details for this index (These are 1 based indexes)
    SysGet, Mon, Monitor, %index%
    element.Insert(MonLeft)
    element.Insert(MonTop)
    element.Insert(MonRight)
    element.insert(MonBottom)
}
SetTimer, HotCorners, 300