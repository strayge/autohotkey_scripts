; #SingleInstance, Force 

CheckCPULoad() 
{

    WTS := ProcessExplorer.WTSEnumerateProcessesEx()
    string := ""
    loop % WTS.MaxIndex()
    {
        name := WTS[A_Index, "ProcessName"]
        pid := WTS[A_Index, "ProsessID"]
        cpu := floor(ProcessExplorer.GetProcessTimes(pid))
        
        if cpu > 15
        {
            string = %string%`n%cpu%`% %name% [%pid%]
        }
    }
    if string
    {
        traytip, Cpu Control, %string%, 5, 2
    }
    else
    {
        TotalCPU := CPULoad()
        if TotalCPU > 50
        {
            traytip, Cpu Control, Huge total CPU: %TotalCPU%`%, 5, 2
        }
    }
    
}
SetTimer, CheckCPULoad, 15000


CPULoad() { ; By SKAN, CD:22-Apr-2014 / MD:05-May-2014. Thanks to ejor, Codeproject: http://goo.gl/epYnkO
; http://ahkscript.org/boards/viewtopic.php?p=17166#p17166
Static PIT, PKT, PUT
    IfEqual, PIT,
    {  
        DllCall( "GetSystemTimes", "Int64P",PIT, "Int64P",PKT, "Int64P",PUT )
        Return 0
    }
    DllCall( "GetSystemTimes", "Int64P",CIT, "Int64P",CKT, "Int64P",CUT )
    IdleTime := PIT - CIT
    KernelTime := PKT - CKT
    UserTime := PUT - CUT
    SystemTime := KernelTime + UserTime
    Return ( ( SystemTime - IdleTime ) * 100 ) // SystemTime, PIT := CIT, PKT := CKT, PUT := CUT 
}

; =============================================================================
; Original url: 
; https://github.com/jNizM/AHK_ProcessExplorer/blob/master/src/ProcessExplorer.ahk
; Title .........: ProcessExplorer
; AHK Version ...: 1.1.23.05 x64 Unicode
; Win Version ...: Windows 10 Professional - x64
; Description ...: Log Remote Session Information
; Version .......: v0.07 Beta
; Modified ......: 2016.04.20-1653
; Author(s) .....: jNizM
; https://code.msdn.microsoft.com/windowsdesktop/Use-PerformanceCounter-to-272d57a1
; https://msdn.microsoft.com/en-us/library/aa965225(v=vs.85).aspx  (Memory Performance Information)
; =============================================================================
Class ProcessExplorer
{
    static ClassNew := ProcessExplorer.ClassInit()
    static ClassDel := OnExit(ObjBindMethod(ProcessExplorer, "_Delete"))

; =============================================================================

    ClassInit()
    {
        hADVAPI := DllCall("LoadLibrary", "str", "advapi32.dll", "uptr")
        hNTDLL  := DllCall("LoadLibrary", "str", "ntdll.dll", "uptr")
        hPSAPI  := DllCall("LoadLibrary", "str", "psapi.dll", "uptr")
        hWTSAPI := DllCall("LoadLibrary", "str", "wtsapi32.dll", "uptr")
        ;WinVer  := ProcessExplorer.RtlGetVersion()
    }

; =============================================================================

    WTSEnumerateProcessesEx()  ; https://msdn.microsoft.com/en-us/library/ee621013(v=vs.85).aspx 
    {
        local PI := PI_EX := TTL := 0  ; currently only 64-bit implemented | size (56 | 64)
        if !(DllCall("wtsapi32\WTSEnumerateProcessesEx", "ptr", 0, "uint*", 1, "uint", 0xFFFFFFFE, "ptr*", PI_EX, "uint*", TTL))
            return (ErrorLevel := 1) & 0
        PI := PI_EX, WTS := []
        loop % TTL
        {
            WTS[A_Index, "SessionID"]          := NumGet(PI+0, "uint")
            WTS[A_Index, "ProsessID"]          := NumGet(PI+4, "uint")
            WTS[A_Index, "ProcessName"]        := StrGet(NumGet(PI+8, "ptr"))
            WTS[A_Index, "UserSID"]            := SID := NumGet(PI+16, "ptr"), LAS := this.LookupAccountSid(SID)
            WTS[A_Index, "UserName"]           := LAS.Name
            WTS[A_Index, "DomainName"]         := LAS.Domain
            WTS[A_Index, "NumberOfThreads"]    := NumGet(PI+24, "uint")
            WTS[A_Index, "HandleCount"]        := NumGet(PI+28, "uint")
            WTS[A_Index, "PagefileUsage"]      := this.GetNumberFormatEx(Round(NumGet(PI+32, "uint") / 1024))
            WTS[A_Index, "PeakPagefileUsage"]  := this.GetNumberFormatEx(Round(NumGet(PI+36, "uint") / 1024))
            WTS[A_Index, "WorkingSetSize"]     := this.GetNumberFormatEx(Round(NumGet(PI+40, "uint") / 1024))
            WTS[A_Index, "PeakWorkingSetSize"] := this.GetNumberFormatEx(Round(NumGet(PI+44, "uint") / 1024))
            WTS[A_Index, "UserTime"]           := this.GetDurationFormatEx(NumGet(PI+48, "int64"))
            WTS[A_Index, "KernelTime"]         := this.GetDurationFormatEx(NumGet(PI+56, "int64"))
            WTS[A_Index, "UserTimeInt"]        := NumGet(PI+48, "int64")
            WTS[A_Index, "KernelTimeInt"]      := NumGet(PI+56, "int64")
            PI += 64
        }
        return WTS, this.WTSFreeMemoryEx(PI_EX, TTL)
    }

; =============================================================================

    WTSFreeMemoryEx(buf, cnt)  ; https://msdn.microsoft.com/en-us/library/ee621015(v=vs.85).aspx
    {
        if !(DllCall("wtsapi32\WTSFreeMemoryEx", "int", 1, "ptr", buf, "uint", cnt))
            return (ErrorLevel := 1) & 0
        return 1
    }

; =============================================================================

    LookupAccountSid(SID)  ; https://msdn.microsoft.com/en-us/library/aa379166(v=vs.85).aspx
    {
        static SNU := "", LAS := {}
        DllCall("advapi32\LookupAccountSid", "ptr", 0, "ptr", SID, "ptr", 0, "uint*", sn, "ptr", 0, "uint*", sd, "uint*", SNU)
        VarSetCapacity(n, sn * (A_IsUnicode ? 2 : 1), 0), VarSetCapacity(d, sd * (A_IsUnicode ? 2 : 1), 0)
        if !(DllCall("advapi32\LookupAccountSid", "ptr", 0, "ptr", SID, "str", n, "uint*", sn, "str", d, "uint*", sd, "uint*", SNU))
            return (ErrorLevel := 1) & 0
        LAS.Name := n, LAS.Domain := d
        return LAS
    }

; =============================================================================

    GetDurationFormatEx(VarIn)  ; https://msdn.microsoft.com/en-us/library/dd318092(v=vs.85).aspx
    {
        static format := "hh:mm:ss.fff", locale := "!x-sys-default-locale"
        if !(size := DllCall("GetDurationFormatEx", "ptr", &locale, "uint", 0, "ptr", 0, "int64", VarIn, "wstr", format, "ptr", 0, "int", 0))
            return (ErrorLevel := 1) & 0
        VarSetCapacity(buf, size * (A_IsUnicode ? 2 : 1), 0)
        if !(DllCall("GetDurationFormatEx", "ptr", &locale, "uint", 0, "ptr", 0, "int64", VarIn, "wstr", format, "wstr", buf, "int", size))
            return (ErrorLevel := 2) & 0
        return buf
    }

; =============================================================================

    GetNumberFormatEx(VarIn)  ; https://msdn.microsoft.com/en-us/library/dd318113(v=vs.85).aspx
    {
        static locale := "!x-sys-default-locale"
        if !(size := DllCall("GetNumberFormatEx", "ptr", &locale, "uint", 0, "ptr", &VarIn, "ptr", 0, "ptr", 0, "int", 0))
            return (ErrorLevel := 1) & 0
        VarSetCapacity(buf, size * (A_IsUnicode ? 2 : 1), 0)
        if !(DllCall("GetNumberFormatEx", "ptr", &locale, "uint", 0, "ptr", &VarIn, "ptr", 0, "str", buf, "int", size))
            return (ErrorLevel := 2) & 0
        return SubStr(buf, 1, - 3)
    }

; =============================================================================

    GetPerformanceInfo()  ; https://msdn.microsoft.com/en-us/library/ms683210(v=vs.85).aspx
    {
        static PI, size := NumPut(VarSetCapacity(PI, (A_PtrSize = 4) ? 56 : 104, 0), PI, "uint") ; 56 | 104
        if !(DllCall("GetPerformanceInfo", "ptr", &PI, "uint", size))
            if !(DllCall("psapi\GetPerformanceInfo", "ptr", &PI, "uint", size))
                return (ErrorLevel := 1) & 0
        GPI := {}
        GPI.CommitTotal       := NumGet(PI, o := A_PtrSize, "uptr") ;  4 |  8
        GPI.CommitLimit       := NumGet(PI, o += A_PtrSize, "uptr") ;  8 | 16
        GPI.CommitPeak        := NumGet(PI, o += A_PtrSize, "uptr") ; 12 | 24
        GPI.PhysicalTotal     := NumGet(PI, o += A_PtrSize, "uptr") ; 16 | 32
        GPI.PhysicalAvailable := NumGet(PI, o += A_PtrSize, "uptr") ; 20 | 40
        GPI.SystemCache       := NumGet(PI, o += A_PtrSize, "uptr") ; 24 | 48
        GPI.KernelTotal       := NumGet(PI, o += A_PtrSize, "uptr") ; 28 | 56
        GPI.KernelPaged       := NumGet(PI, o += A_PtrSize, "uptr") ; 32 | 64
        GPI.KernelNonpaged    := NumGet(PI, o += A_PtrSize, "uptr") ; 34 | 72
        GPI.PageSize          := NumGet(PI, o += A_PtrSize, "uptr") ; 40 | 80
        GPI.HandleCount       := NumGet(PI, o += A_PtrSize, "uint") ; 44 | 88
        GPI.ProcessCount      := NumGet(PI, o += 4        , "uint") ; 48 | 92
        GPI.ThreadCount       := NumGet(PI, o += 4        , "uint") ; 52 | 96
        return GPI
    }

; =============================================================================

    GetProcessMemoryInfo(ProcessID)  ; https://msdn.microsoft.com/en-us/library/ms683219(v=vs.85).aspx
    {
        static PMC_EX, size := NumPut(VarSetCapacity(PMC_EX, 8 + A_PtrSize * 9, 0), PMC_EX, "uint")  ; 44 | 80 
        hProcess := this.OpenProcess(ProcessID, 0x1000) ; ==> Problems with 0x0400 & 0x0410
        if !(DllCall("GetProcessMemoryInfo", "ptr", hProcess, "ptr", &PMC_EX, "uint", size))
            if !(DllCall("psapi\GetProcessMemoryInfo", "ptr", hProcess, "ptr", &PMC_EX, "uint", size))
                return (ErrorLevel := 1) & 0
        GPMI := {}
        GPMI.PageFaultCount             := NumGet(PMC_EX, 4, "uint")  ;  4 |  4
        GPMI.PeakWorkingSetSize         := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o := 8, "uptr") / 1024))  ;  8 |  8
        GPMI.WorkingSetSize             := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 12 | 16
        GPMI.QuotaPeakPagedPoolUsage    := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 16 | 24
        GPMI.QuotaPagedPoolUsage        := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 20 | 32
        GPMI.QuotaPeakNonPagedPoolUsage := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 24 | 40
        GPMI.QuotaNonPagedPoolUsage     := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 28 | 48
        GPMI.PagefileUsage              := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 32 | 56
        GPMI.PeakPagefileUsage          := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 36 | 64
        GPMI.PrivateUsage               := this.GetNumberFormatEx(Round(NumGet(PMC_EX, o += A_PtrSize, "uptr") / 1024)) ; 40 | 72
        return GPMI, this.CloseHandle(hProcess)
    }

; =============================================================================

    GetProcessTimes(ProcessID)  ; https://msdn.microsoft.com/en-us/library/ms683223(v=vs.85).aspx
    {
        static KernelTimeOld := {}
        static UserTimeOld := {}
        static KernelTime := {}
        static UserTime := {}
        static TimeOld := {}
        hProcess := this.OpenProcess(ProcessID, 0x1000)
        KernelTimeOld[ProcessID] := KernelTime[ProcessID]
        UserTimeOld[ProcessID] := UserTime[ProcessID]
        
        if !(DllCall("GetProcessTimes", "ptr", hProcess, "int64*", CT, "int64*", ET, "int64*", NKT, "int64*", NUT))
            return (ErrorLevel := 1) & 0
        
        KernelTime[ProcessID] := NKT
        UserTime[ProcessID] := NUT
        
        TimeNow := A_TickCount
        TimeDelta := TimeNow - TimeOld[ProcessID]
        
        EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
        
        cpu := (KernelTime[ProcessID] - KernelTimeOld[ProcessID] + UserTime[ProcessID] - UserTimeOld[ProcessID]) / TimeDelta * 1.e-2 / NUMBER_OF_PROCESSORS
        
        TimeOld[ProcessID] := TimeNow
        
        this.CloseHandle(hProcess)
        return cpu
    }

; =============================================================================

    RtlGetVersion()  ; https://msdn.microsoft.com/en-us/library/ff561910(v=vs.85).aspx
    {
  ; 0x0A00 - Windows 10
  ; 0x0603 - Windows 8.1
  ; 0x0602 - Windows 8 / Windows Server 2012
  ; 0x0601 - Windows 7 / Windows Server 2008 R2
  ; 0x0600 - Windows Vista / Windows Server 2008
  ; 0x0502 - Windows XP 64-Bit Edition / Windows Server 2003 / Windows Server 2003 R2
  ; 0x0501 - Windows XP
        static RTL_OSV_EX, init := NumPut(VarSetCapacity(RTL_OSV_EX, A_IsUnicode ? 284 : 156, 0), RTL_OSV_EX, "uint")
        if (DllCall("ntdll\RtlGetVersion", "ptr", &RTL_OSV_EX) != 0)
            return (ErrorLevel := 1) & 0
        return ((NumGet(RTL_OSV_EX, 4, "uint") << 8) | NumGet(RTL_OSV_EX, 8, "uint"))
    }

; =============================================================================

    GlobalMemoryStatusEx()  ; https://msdn.microsoft.com/en-us/library/aa366589(v=vs.85).aspx
    {
        static MS_EX, init := NumPut(VarSetCapacity(MS_EX, 64, 0), MS_EX, "uint")
        if !(DllCall("GlobalMemoryStatusEx", "ptr", &MS_EX))
            return (ErrorLevel := 1) & 0
        GMSEX := {}
        GMSEX.MemoryLoad           := NumGet(MS_EX,  4, "uint")
        GMSEX.TotalPhys            := NumGet(MS_EX,  8, "uint64")
        GMSEX.AvailPhys            := NumGet(MS_EX, 16, "uint64")
        GMSEX.TotalPageFile        := NumGet(MS_EX, 24, "uint64")
        GMSEX.AvailPageFile        := NumGet(MS_EX, 32, "uint64")
        GMSEX.TotalVirtual         := NumGet(MS_EX, 40, "uint64")
        GMSEX.AvailVirtual         := NumGet(MS_EX, 48, "uint64")
        GMSEX.AvailExtendedVirtual := NumGet(MS_EX, 56, "uint64")
        return GMSEX
    }

; =============================================================================

    OpenProcess(ProcessID, Access := 0x400)  ; https://msdn.microsoft.com/en-us/library/ms684320(v=vs.85).aspx
    {
        if !(hProcess := DllCall("OpenProcess", "uint", Access, "int", 0, "uint", ProcessID))
            return (ErrorLevel := 1) & 0
        return hProcess
    }

; =============================================================================

    CloseHandle(hObject)  ; https://msdn.microsoft.com/en-us/library/ms724211(v=vs.85).aspx
    {
        if !(DllCall("CloseHandle", "ptr", hObject))
            return (ErrorLevel := 1) & 0
        return 1
    }

; =============================================================================

    _Delete()
    {
        DllCall("FreeLibrary", "ptr", ProcessExplorer.hWTSAPI)
        DllCall("FreeLibrary", "ptr", ProcessExplorer.hPSAPI)
        DllCall("FreeLibrary", "ptr", ProcessExplorer.hNTDLL)
        DllCall("FreeLibrary", "ptr", ProcessExplorer.hADVAPI)
    }
}
; =============================================================================