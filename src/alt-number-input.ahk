#InstallKeybdHook
SendMode, Event  ; 用 SendEvent，IME 下較穩
CoordMode, ToolTip, Screen  ; ToolTip 用螢幕座標

; ========================================
; 設定檔讀取（ToggleKey 自訂）
; ========================================
ConfigFile := A_ScriptDir "\..\Settings.txt"

ToggleKey := "F8"  ; 預設值

if FileExist(ConfigFile)
{
    ;Hotkeys=Section名, ToggleKey=鍵名, F8=找無時的預設
    IniRead, keyFromFile, %ConfigFile%, Hotkeys, ToggleKey, F8
}

; 動態綁定熱鍵
Hotkey, %ToggleKey%, ToggleAltNum

; =======================
; 熱鍵區
; =======================

ToggleAltNum: ;整支腳本的熱鍵 on/off（包含 Alt+數字）
    Suspend, Toggle
    ; 顯示目前狀態
    suspended := A_IsSuspended
    msg := suspended ? "AltNum: OFF" : "AltNum: ON"
    
    pos := GetCenterPos()
    ToolTip, %msg%, % pos.x, % pos.y
    SetTimer, __HideTip, -1000
return



; =====================================================================
; __HideTip:
;   - 這是一個「標籤」(label)，只給 SetTimer 呼叫用。
;   - 為什麼不能直接寫：SetTimer, ToolTip, -1000 ?
;       → 因為 ToolTip 是 AHK 的內建「指令」，不是「標籤」。
;       → SetTimer 的第一個參數只能放「標籤名稱」，不能放指令。
;   - 所以要另外做一個 __HideTip:，由它來執行 ToolTip (清空並關閉)
;   - SetTimer, __HideTip, -1000 = 1 秒後只執行這段一次（負數 = 一次）
; =====================================================================
__HideTip:
    ToolTip
return

; —— Alt + 數字 ——（用 Numpad，已測可行）
!1::SendNumLang("1")
!2::SendNumLang("2")
!3::SendNumLang("3")
!4::SendNumLang("4")
!5::SendNumLang("5")
!6::SendNumLang("6")
!7::SendNumLang("7")
!8::SendNumLang("8")
!9::SendNumLang("9")
!0::SendNumLang("0")


; ; —— Alt + 符號 ——（用 vk，避開 IME 組字）
!-::SendNumLang("-")
!,::SendNumLang(",") 
!.::SendNumLang(".")
!/::SendNumLang("/")  
!;::SendNumLang(";") 



; =======================
; Functions 區
; =======================

SendNumLang(n) {
    prev := GetCurrentHKL()                 ; 記住目前語系
    hklEN := LoadHKL("00000409")            ; 英文(美式)
    PostMessage, 0x50, 0, %hklEN%, , A      ; WM_INPUTLANGCHANGEREQUEST
    ; Sleep, 10                               ; 需要時再放開
    SendInput, {Text}%n%
    if (prev) {
        PostMessage, 0x50, 0, %prev%, , A    ; 切回來
    }
}

GetCurrentHKL() {
    WinGet, hWnd, ID, A
    thread := DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "UInt*", 0, "UInt")
    return DllCall("GetKeyboardLayout", "UInt", thread, "Ptr")
}
LoadHKL(hklStr) {
    return DllCall("LoadKeyboardLayout", "Str", hklStr, "UInt", 1, "Ptr")
}

; 取主螢幕的畫面中心
GetCenterPos() {
    ; 先取得主螢幕編號
    SysGet, primary, MonitorPrimary
    ; 再取得該螢幕的工作區 (扣掉工作列)
    SysGet, mon, MonitorWorkArea, %primary%

    centerX := monLeft + (monRight - monLeft) / 2
    centerY := monTop  + (monBottom - monTop) / 2

    pos := {}          ; 建立一個空物件
    pos.x := centerX   ; 設置屬性
    pos.y := centerY
    return pos
}