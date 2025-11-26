#InstallKeybdHook
SendMode, Event  ; 用 SendEvent，IME 狀況下較穩
CoordMode, ToolTip, Screen  ; ToolTip 用螢幕座標

; ========================================
; 設定檔讀取 & 預設值
; ========================================
ConfigFile := A_ScriptDir "\Settings.txt"

; ----- 預設值 -----
; Hotkey
ToggleKey := "F8"
; Tooltip
g_TooltipType    := "Center"
g_TooltipCustomX := 0
g_TooltipCustomY := 0

; 開始讀取參數
if FileExist(ConfigFile)
{
    ;IniRead參數, 預存的變數名, 設定檔路徑, [Section]區塊名, 區塊下鍵名, 找無時的預設值

    ; Hotkeys
    IniRead, ToggleKey, %ConfigFile%, Hotkeys, ToggleKey, F8

    ; Tooltip
    IniRead, g_TooltipType,    %ConfigFile%, Tooltip, Type,    Center
    IniRead, g_TooltipCustomX, %ConfigFile%, Tooltip, CustomX, 0
    IniRead, g_TooltipCustomY, %ConfigFile%, Tooltip, CustomY, 0
}

; ----- 動態綁定 AltNum 開關熱鍵 -----
; Hotkey參數, <按鍵變數名>, <要執行的標籤或函式>
Hotkey, %ToggleKey%, ToggleAltNum



; =======================
; 熱鍵區
; =======================
ToggleAltNum: ;整支腳本的熱鍵 on/off（包含 Alt+數字）
    Suspend, Toggle
    ; 顯示目前狀態
    suspended := A_IsSuspended
    msg := suspended ? "AltNum: OFF" : "AltNum: ON"
    
    pos := GetTooltipPos()
    ToolTip, %msg%, % pos.x, % pos.y
    SetTimer, __HideTip, -1000 ;__HideTip 下詳
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


; —— Alt + 符號 ——（用 vk，避開 IME 組字）
!-::SendNumLang("-")
!,::SendNumLang(",") 
!.::SendNumLang(".")
!/::SendNumLang("/")  
!;::SendNumLang(";") 



; =======================
; Functions 區
; =======================

; 強制用英文輸出字元 n（避免被注音擋住）
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

; 取得目前輸入語系（HKL）
GetCurrentHKL() {
    WinGet, hWnd, ID, A
    thread := DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "UInt*", 0, "UInt")
    return DllCall("GetKeyboardLayout", "UInt", thread, "Ptr")
}

; 載入指定語系（HKL）
LoadHKL(hklStr) {
    return DllCall("LoadKeyboardLayout", "Str", hklStr, "UInt", 1, "Ptr")
}

; 依設定檔決定 Tooltip 顯示座標
GetTooltipPos() {
    global g_TooltipType, g_TooltipCustomX, g_TooltipCustomY

    ; 使用者選 Custom
    if (g_TooltipType = "Custom") {
        pos := {}
        pos.x := g_TooltipCustomX
        pos.y := g_TooltipCustomY
        return pos
    }

    ; 其它情況 ( 預設 Center  )
    return GetCenterPos()
}

; 若為Center, 取主螢幕的畫面中心
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