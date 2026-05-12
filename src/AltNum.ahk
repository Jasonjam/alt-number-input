#Requires AutoHotkey v2.0
#SingleInstance Force ;避免管理員模式重複執行
SendMode "Event"  ; 用 SendEvent，IME 狀況下較穩
CoordMode "ToolTip", "Screen"  ; ToolTip 用螢幕座標


; ========================================
; 專案路徑初始化
; ========================================
; --- 設定 ROOT 路徑 ---
if (A_IsCompiled) { ; 由 exe 開啟
    APP_ROOT := A_ScriptDir
}

if (!A_IsCompiled) { ; 由 ahk 開啟
    APP_ROOT := A_ScriptDir "\.."
}

; --- 設定 Settings 路徑 ---
ConfigFile := APP_ROOT "\src\Settings.ini"
; 設定檔 存在性檢查
if !FileExist(ConfigFile){
    MsgBox("Settings.ini not found:`n" ConfigFile, "Settings Error", "Iconx")
    ExitApp
}

; ========================================
; 管理員模式 檢查
; ========================================
g_adminMode := IniRead(ConfigFile, "General", "adminMode", "false") ; 讀取參數，預設是關閉 false
g_adminMode := StrLower(Trim(g_adminMode)) ; adminMode的值 標準化：去除空白、轉小寫

if (g_adminMode = "true" || g_adminMode = 1){ ; 檢查參數
    if !A_IsAdmin { ; 如果目前不是管理員模式，就重啟一次，並以管理員模式執行
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '"') ; 如果是 EXE，直接以管理員權限啟動自己
        else
            Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"') ; 如果是腳本，用 AHK 啟動
    }
    ExitApp()
    }
}

; ========================================
; Tray 系統托盤 ( 要在adminMode後 )
; ========================================
InitTrayMenu() {
    global TrayIconOn, TrayIconOff
    global Label_Suspend, Label_Reload, Label_Exit

    ; Tray icon path
    TrayIconOn  := APP_ROOT "\assets\altnum.ico"
    TrayIconOff := APP_ROOT "\assets\altnum-off.ico"

    ; Tray icon 檔案存在性檢查
    if !FileExist(TrayIconOn){
        MsgBox("TrayIconOn not found:`n" TrayIconOn, "Icon Error", "Iconx")
        ExitApp
    }

    if !FileExist(TrayIconOff){
        MsgBox("TrayIconOff not found:`n" TrayIconOff, "Icon Error", "Iconx")
        ExitApp
    }



    A_IconTip := "AltNum" ; TrayIcon 提示文字
    TraySetIcon(TrayIconOn) ; 自訂初始 TrayIcon

    A_TrayMenu.Delete() ; 刪除 AHK 自帶的 MENU

    Label_Suspend := "Pause / 暫停"
    Label_Reload := "Reload / 重新載入"
    Label_Exit := "Exit / 離開"


    A_TrayMenu.Add(Label_Suspend, (*) => ToggleSuspend()) ; 暫停選項
    A_TrayMenu.Add(Label_Reload, (*) => Reload())
    A_TrayMenu.Add()
    A_TrayMenu.Add(Label_Exit, (*) => ExitApp())

    
}
InitTrayMenu()

; ========================================
; 設定檔讀取 & 預設值
; ========================================

; ----- 預設值，以防沒讀到Settings -----
; Suspend Toggle key
ToggleSuspendKey := IniRead(ConfigFile, "Hotkeys", "ToggleSuspendKey", "F8")
; TrigKey
g_TrigSide := IniRead(ConfigFile, "TrigKey", "Side", "R") ; Side 預設 R
g_TrigModifier  := IniRead(ConfigFile, "TrigKey", "Modifier", "Alt") ; Modifier 預設 Alt

LoadSettings() {
    global ToggleSuspendKey, g_TrigSide, g_TrigModifier

    ; 從設定檔讀取參數，並覆蓋預設值
    ToggleSuspendKey := IniRead(ConfigFile, "Hotkeys", "ToggleSuspendKey", ToggleSuspendKey)
    g_TrigSide := IniRead(ConfigFile, "TrigKey", "Side", g_TrigSide)
    g_TrigModifier  := IniRead(ConfigFile, "TrigKey", "Modifier", g_TrigModifier)
}


; ----- 動態綁定 AltNum 開關熱鍵 -----
; 動態綁定寫法: Hotkey, <按鍵變數名>, <要執行的標籤或函式>
Hotkey ToggleSuspendKey, ToggleSuspend, "On S" ; 註冊暫停熱鍵，S = Suspend exempt，"On S" 為固定字眼


; ------ AltNum 熱鍵群組初始化 -----
; 設定主鍵 (PrimaryKey) & 對應的輸出(OutputKey) (主鍵 := 要送出的按鍵)
g_AltNumMap := Map()
g_AltNumMap["1"] := "{Numpad1}"
g_AltNumMap["2"] := "{Numpad2}"
g_AltNumMap["3"] := "{Numpad3}"
g_AltNumMap["4"] := "{Numpad4}"
g_AltNumMap["5"] := "{Numpad5}"
g_AltNumMap["6"] := "{Numpad6}"
g_AltNumMap["7"] := "{Numpad7}"
g_AltNumMap["8"] := "{Numpad8}"
g_AltNumMap["9"] := "{Numpad9}"
g_AltNumMap["0"] := "{Numpad0}"
g_AltNumMap["."] := "{NumpadDot}"
g_AltNumMap["/"] := "{NumpadDiv}"
g_AltNumMap["-"] := "{NumpadSub}"

; 組裝修飾鍵，並轉成修飾鍵符號
TriggerModifierSymbol := CreateTriggerModifierSymbol(g_TrigSide, g_TrigModifier) ; 組裝並轉化後，把結果存成變數

; 動態註冊成熱鍵 (為初始化的最後一步)，觸發後由 SendNumpadKey 函式處理
RegisterAltNumHotkeys(TriggerModifierSymbol)


; --- 定義 ---
; TriggerModifier: 觸發修飾鍵(例如 RAlt)
; TriggerModifierSymbol : AHK專用的修飾鍵符號表示 (例如 >!)
; PrimaryKey: 使用者實際按下的主鍵，例如 1 / 2 / . / -
; OutputKey: 實際送出的按鍵，例如 {Numpad1}
; 熱鍵 : 修飾鍵 + 主鍵 的組合 (例如 >!1 代表 RAlt + 1)


return


; ========================================
; Functions
; ========================================

; 顯示提示，預設 1000ms 後自動關閉
__ShowTip(text, ms := 1000) {
    ToolTip(text)
    ; V2 的 SetTimer 傳入函式物件，() => ToolTip() 是匿名函式，直接清空文字
    SetTimer(() => ToolTip(), -ms)
}

; 切換暫停狀態
ToggleSuspend(*) {
    global TrayIconOn, TrayIconOff, Label_Suspend
    Suspend(-1) ; 切換掛起狀態 (-1 代表 Toggle)


    if (A_IsSuspended) {
        A_TrayMenu.Check(Label_Suspend) ; 在選單項目前面打勾
        __ShowTip("AltNum: OFF")

        TraySetIcon(TrayIconOff, , true) ; 設定托盤圖示為關閉狀態，並且強制更新圖示（第三個參數 true）
        return
    } 
    if(!A_IsSuspended) {
        A_TrayMenu.Uncheck(Label_Suspend) ; 取消勾選
        __ShowTip("AltNum: ON")

        TraySetIcon(TrayIconOn) ; ICON
        return
    }

}

; 修飾鍵符號 組合與轉換
CreateTriggerModifierSymbol(origSide, origModifier) {
    ; 根據 Setting 的 Side 和 Modifier 來建立熱鍵的修飾鍵，再將"修飾鍵"轉成"修飾鍵符號" eg. "L" + "Ctrl" -> "<^"
    trigSide := StrUpper(Trim(origSide))
    trigModifier  := StrLower(Trim(origModifier))

    sideMap := Map(
        "", "",
        "L", "<",
        "R", ">"
    )

    modifierMap := Map(
        "alt", "!",
        "ctrl", "^",
        "shift", "+",
        "win", "#"
    )

    if (!sideMap.Has(trigSide)) {
        MsgBox(
            "Invalid TrigKey Side:`nYou set: " origSide "`nAllowed: L / R / blank",
            "Settings Error",
            "Iconx"
        )
        ExitApp
    }

    if (!modifierMap.Has(trigModifier)) {
        MsgBox(
            "Invalid TrigKey Modifier:`nYou set: " origModifier "`nAllowed: Alt / Ctrl / Shift / Win",
            "Settings Error",
            "Iconx"
        )
        ExitApp
    }

    return sideMap[trigSide] . modifierMap[trigModifier]
}

; 註冊動態熱鍵
RegisterAltNumHotkeys(TriggerModifierSymbol) {
    ; 將 "修飾鍵符號" + 主鍵(g_AltNumMap來的)，組合成AHK 熱鍵縮寫，並動態註冊成熱鍵 (eg. <^5)
    global g_AltNumMap

    for PrimaryKey, outputKey in g_AltNumMap {
        ahkShortcut  := TriggerModifierSymbol . PrimaryKey ; 組合成 AHK 熱鍵縮寫
        Hotkey(ahkShortcut, SendMappedKey.Bind(outputKey))
    }
}
; 熱鍵觸發後，送出映射後的按鍵
SendMappedKey(outputKey, *) {
    SendInput(outputKey)
}