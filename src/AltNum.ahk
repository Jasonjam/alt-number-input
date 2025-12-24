#SingleInstance Force ;避免管理員模式重複執行
#InstallKeybdHook
SendMode, Event  ; 用 SendEvent，IME 狀況下較穩
CoordMode, ToolTip, Screen  ; ToolTip 用螢幕座標

; 參數Settings 路徑
ConfigFile := A_ScriptDir "\Settings.txt"

; ---- 管理員模式檢查 ----
g_adminMode := "true"  ; 預設值

IniRead, g_adminMode, %ConfigFile%, General, adminMode, true ; 讀取參數

if (g_adminMode = "true" || g_adminMode = 1) ; 檢查參數
{
    if !A_IsAdmin
    {
        Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
        ExitApp
    }
}

; ---- Tray icon (要在adminMode後) ----
TrayIconOn  := A_ScriptDir "\..\assets\altnum_512px.ico"
TrayIconOff := A_ScriptDir "\..\assets\altnum_512px-off.ico"
Menu, Tray, Icon, %TrayIconOn%
Menu, Tray, Tip, AltNum. F8: ON / OFF
if !FileExist(TrayIconOn)
{
    MsgBox, 16, Icon Error, TrayIconOn not found:`n%TrayIconOn%
    ExitApp
}

if !FileExist(TrayIconOff)
{
    MsgBox, 16, Icon Error, TrayIconOff not found:`n%TrayIconOff%
    ExitApp
}


; ========================================
; 設定檔讀取 & 預設值
; ========================================

; ----- 預設值，以防沒讀到Settings -----
; Hotkey
ToggleKey := "F8"
; Tooltip
g_TooltipType    := "Center"
g_TooltipCustomX := 0
g_TooltipCustomY := 0
; TrigKey
g_TrigSide := "R"
g_TrigKey  := "Alt"


; 開始讀取參數
if FileExist(ConfigFile)
{
    ;IniRead參數, 想存的變數名, 設定檔路徑, [Section]區塊名, 區塊下鍵名, 找無時的預設值

    ; Hotkeys
    IniRead, ToggleKey, %ConfigFile%, Hotkeys, ToggleKey, F8

    ; Tooltip
    IniRead, g_TooltipType,    %ConfigFile%, Tooltip, Type,    Center
    IniRead, g_TooltipCustomX, %ConfigFile%, Tooltip, CustomX, 0
    IniRead, g_TooltipCustomY, %ConfigFile%, Tooltip, CustomY, 0

    ; TrigKey
    IniRead, g_TrigSide, %ConfigFile%, TrigKey, Side, R
    IniRead, g_TrigKey,  %ConfigFile%, TrigKey, Key,  Alt
}

; ----- 動態綁定 AltNum 開關熱鍵 -----
; 切換鍵: Hotkey, <按鍵變數名>, <要執行的標籤或函式>
Hotkey, %ToggleKey%, ToggleAltNum

; ------ AltNum 熱鍵群組初始化 -----
; 預設要輸出的按鍵
g_AltNumKeys := ["1","2","3","4","5","6","7","8","9","0","-",",",".","/",";"]
    
; - 由 TrigKey 設定決定前綴鍵，例: Side=R, Key=Alt  →  ralt
; - 將前綴鍵 + g_AltNumKeys 內的按鍵，動態註冊成熱鍵（prefix & key）
;   例: ralt & 1  → SendNumLang("1")
TriggerPrefix := BuildTriggerPrefix(g_TrigKey, g_TrigSide)
RegisterAltNumHotkeys(TriggerPrefix)

return


; =======================
; 熱鍵區 (label)
; =======================
ToggleAltNum: ;整支腳本的熱鍵 on/off（包含 Alt+數字）
    Suspend, Permit ; 保險，Suspend 狀態下仍然可以觸發
    Suspend, Toggle
    
    suspended := A_IsSuspended ;A_IsSuspended=腳本是否處於Suspend狀態, true/false

    ; 顯示目前狀態
    ; OFF 狀態
    if (suspended)
    {
        Menu, Tray, Icon, %TrayIconOff%, , 1
        msg := "AltNum: OFF"
    }

    ; ON 狀態
    if (!suspended)
    {
        Menu, Tray, Icon, %TrayIconOn%, , 1
        msg := "AltNum: ON"
    }
    
    pos := GetTooltipPos()
    ToolTip, %msg%, % pos.x, % pos.y
    SetTimer, __HideTip, -1000 ;__HideTip 下詳
return

; --------------------------------------------------------------------
; __HideTip:
;   - 這是一個「標籤」(label)，只給 SetTimer 呼叫用。
;   - 為什麼不能直接寫：SetTimer, ToolTip, -1000 ?
;       → 因為 ToolTip 是 AHK 的內建「指令」，不是「標籤」。
;       → SetTimer 的第一個參數只能放「標籤名稱」，不能放指令。
;   - 所以要另外做一個 __HideTip:，由它來執行 ToolTip (清空並關閉)
;   - SetTimer, __HideTip, -1000 = 1 秒後只執行這段一次（負數 = 一次）
; --------------------------------------------------------------------
__HideTip:
    ToolTip
return


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

;把設定檔 (Key + Side) 轉成可用的前綴：RAlt / LCtrl ...
BuildTriggerPrefix(key, side) {
    origKey  := Trim(key)
    origSide := Trim(side)

    ; 轉大小寫: 動作, 輸出變數, 輸入變數
    StringUpper, side, origSide ; 大寫
    StringLower, key, origKey ; 小寫

    ; side 只允許 L / R / 空白
    if !(side = "" || side = "L" || side = "R") {
        MsgBox, 16, Settings Error, `nYou set: "%origSide%"
        ExitApp
    }
    
    ; key 白名單
    if !(key = "alt" || key = "ctrl" || key = "shift") {
        MsgBox, 16, Settings Error, `nYou set: "%origKey%"
        ExitApp
    }
    ; side 空白：照你規格回傳 "Alt/Ctrl/Shift"
    if (side = "")
        return key

    ; side 有值：組合 "LAlt/RAlt/LCtrl/..."
    return side . key
}

; 動態註冊
RegisterAltNumHotkeys(prefix) {
    global g_AltNumKeys 

    for i, k in g_AltNumKeys {
        hk := prefix " & " k
        fn := Func("SendNumLang").Bind(k)
        Hotkey, %hk%, %fn%, On
    }
}