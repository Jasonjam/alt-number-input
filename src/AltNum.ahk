#Requires AutoHotkey v2.0
#SingleInstance Force ;避免管理員模式重複執行
SendMode "Event"  ; 用 SendEvent，IME 狀況下較穩
CoordMode "ToolTip", "Screen"  ; ToolTip 用螢幕座標

; --- 名詞定義 ---
; TriggerModifier: 觸發修飾鍵(例如 RAlt)
; TriggerModifierSymbol : AHK專用的修飾鍵符號表示 (例如 >!)
; PrimaryKey: 使用者實際按下的主鍵，例如 1 / 2 / . / -
; OutputKey: 實際送出的按鍵，例如 {Numpad1}
; 熱鍵 : 修飾鍵 + 主鍵 的組合 (例如 >!1 代表 RAlt + 1)

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
global SettingsFile := APP_ROOT "\src\Settings.ini"
; 設定檔 存在 檢查
if !FileExist(SettingsFile) {
    MsgBox("Settings.ini not found:`n" SettingsFile, "Settings Error", "Iconx")
    ExitApp
}
global GuiPosFile := APP_ROOT "\src\.pos.ini"

; ========================================
; 管理員模式 檢查
; ========================================
CheckAdminMode(SettingsFile) {
    ; scope 內參數
    adminMode := IniRead(SettingsFile, "General", "adminMode", "false") ; 讀取參數，預設是關閉 false
    adminMode := StrLower(Trim(adminMode)) ; adminMode的值 標準化：去除空白、轉小寫

    if (adminMode = "true" || adminMode = 1) { ; 檢查參數
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
}

; ========================================
; Tray 系統托盤 初始化 ( 要在adminMode後 )
; ========================================
InitTrayMenu() {
    global TrayIconOn, TrayIconOff
    global Label_Suspend, Label_Reload, Label_Exit

    ; Tray icon path
    TrayIconOn := APP_ROOT "\assets\altnum.ico"
    TrayIconOff := APP_ROOT "\assets\altnum-off.ico"

    ; Tray icon 檔案存在性檢查
    if !FileExist(TrayIconOn) {
        MsgBox("TrayIconOn not found:`n" TrayIconOn, "Icon Error", "Iconx")
        ExitApp
    }

    if !FileExist(TrayIconOff) {
        MsgBox("TrayIconOff not found:`n" TrayIconOff, "Icon Error", "Iconx")
        ExitApp
    }

    A_IconTip := "AltNum" ; TrayIcon 提示文字
    TraySetIcon(TrayIconOn) ; 自訂初始 TrayIcon

    A_TrayMenu.Delete() ; 刪除 AHK 自帶的 MENU

    Label_Suspend := "Pause / 暫停"
    Label_Reload := "Reload / 重新載入"
    Label_Gui := "Setting / 設定"
    Label_Exit := "Exit / 離開"

    A_TrayMenu.Add(Label_Suspend, (*) => ToggleSuspendHandler()) ; 暫停選項
    A_TrayMenu.Add(Label_Reload, (*) => Reload())
    A_TrayMenu.Add(Label_Gui, (*) => mainGui.Show()) ; 再次開啟 GUI (非首次執行)
    A_TrayMenu.Add() ; 分隔線
    A_TrayMenu.Add(Label_Exit, (*) => ExitApp())

    A_TrayMenu.Default := Label_Gui
}

; ========================================
; GUI 設定
; ========================================
; --- 介面佈局配置 (統一管理) ---
GuiLayoutConfig() {
    cfg := {
        ; GUI 整體
        guiW: 300,      ; GUI 總寬
        marginX: 20,    ; Content 起始位置，Content=整行
        ; Row 每一行
        firstRowY: 50,  ; 第一行 Y座標 基準
        rowGap: 40,     ; 行距
        rowH: 20,       ; 每行高度
        ; Label : 標題 (左側)
        titleW: 100,    ; 寬度
        ; Control: 控制項 (右側)
        controlX: 120,  ; X座標，右側的 開始位置
        radioW: 60,     ; 單選按鈕寬度(含文字)
        ; DDL: Drop Down List. 下拉選單高度
        ddlW: 140,      ; 寬度
        ddlYOffset: -3, ; 往上調整 3px (預設會有點太高，調整後比較剛好)
        ; Button: 按鈕 (目前沒用到，預留)
        btnW: 90,       ; 寬度
        btnH: 30,       ; 高度
        hrMarginTop: 20,     ; hr margin-top
        btnMarginTop: 15,    ; btn margin-top
        btnMarginBottom: 15, ; btn margin-bottom
    }

    ; 計算 Content: ROW 內容的寬度
    cfg.contentW := cfg.guiW - (cfg.marginX * 2) ; Content 寬度 = GUI總寬 - (左右邊距 * 2)

    ; 排序給 getRowY
    cfg.rowIndex := Map("adminMode", 0,
        "triggerSide", 1,
        "triggerKey", 2,
        "pauseKey", 3)

    return cfg
}
InitGUI(*) {
    global mainGui
    ; 呼叫 介面佈局配置
    cfg := GuiLayoutConfig()

    ; 衍生計算值
    GetRadioX(index) { ; 根據 第幾個radio 計算X座標: 根據 index 動態計算，index 從 0 開始
        return cfg.controlX + (cfg.radioW * index)
    }
    getRowY(index) { ; 根據 行名 計算Y座標
        return cfg.firstRowY + (cfg.rowGap * cfg.rowIndex[index])
    }
    OffsetDDLY(rowName) { ; 根據 行名 調整 DDL Y座標
        return GetRowY(rowName) + cfg.ddlYOffset ; Drop Down List 預設會有點高，這個函式用來調整 Y座標
    }

    ; 建立 GUI 視窗
    mainGui := Gui("-AlwaysOnTop", "AltNum")
    mainGui.SetFont("s10", "Microsoft JhengHei")

    ; Page 標題
    pageTitle := mainGui.AddText(
        "x" cfg.marginX
        " y" 10
        " w" cfg.contentW
        " h" cfg.rowH
        , "AltNum Settings"
    )
    pageTitle.setFont("s11 Bold") ; 標題字體加大加粗

    ; PIN: Always on top 控制
    pinAotLabel := mainGui.addText(
        "x" (cfg.contentW - 18) ; 從右側算起
        " y" 14
        " w" 20
        " h" cfg.rowH
        , "Pin: "
    )
    pinAotLabel.setFont("s8")
    pinAotCheckbox := mainGui.AddCheckBox(
        "x" (cfg.contentW + 6)
        " y" 12
        " w" 8
        " h" cfg.rowH
    )
    pinAotCheckbox.value := false

    ; 分隔線
    mainGui.Add("Text",
        "x" (cfg.marginX - 5)
        " y" 35
        " w" (cfg.contentW + 5)
        " h2 BackgroundGray"
    )

    ; Admin Mode
    adminModeTitle := mainGui.AddText(  ; +0x200 垂直置中
        "x" cfg.marginX
        " y" getRowY("adminMode")
        " w" cfg.titleW
        " h" cfg.rowH
        " +0x200", "Admin Mode :"
    )
    adminOn := mainGui.AddRadio("x" GetRadioX(0) " y" getRowY("adminMode") " w" cfg.radioW " h" cfg.rowH, "ON")
    adminOff := mainGui.AddRadio("x" GetRadioX(1) " y" getRowY("adminMode") " w" cfg.radioW " h" cfg.rowH, "OFF")

    ; Trigger Side
    mainGui.AddText(
        "x" cfg.marginX
        " y" getRowY("triggerSide")
        " w" cfg.titleW
        " h" cfg.rowH
        " +0x200", "Trigger Side:"
    )
    sideL := mainGui.AddRadio("x" GetRadioX(0) " y" getRowY("triggerSide") " w" cfg.radioW " h" cfg.rowH, "L")
    sideR := mainGui.AddRadio("x" GetRadioX(1) " y" getRowY("triggerSide") " w" cfg.radioW " h" cfg.rowH, "R")
    sideAll := mainGui.AddRadio("x" GetRadioX(2) " y" getRowY("triggerSide") " w" cfg.radioW " h" cfg.rowH, "All")

    ; Trigger Key
    mainGui.AddText("x" cfg.marginX " y" getRowY("triggerKey") " w" cfg.titleW " h" cfg.rowH " +0x200", "Trigger Key:")
    modifierDDL := mainGui.AddDropDownList(
        "x" cfg.controlX " y" OffsetDDLY("triggerKey")
        " w" cfg.ddlW, ["Alt", "Ctrl", "Shift", "Win"]
    )

    ; Pause Key
    mainGui.AddText("x" cfg.marginX " y" getRowY("pauseKey") " w" cfg.titleW " h" cfg.rowH " +0x200", "Pause Key:")
    pauseInput := mainGui.AddEdit("x" cfg.controlX " y" getRowY("pauseKey") " w" cfg.ddlW " h" cfg.rowH)

    ; --- 底部 分隔線 ---
    lastRowBottomY := getRowY("pauseKey") + cfg.rowH ; 最後一行的底部 Y座標
    cfg.hrY := lastRowBottomY + cfg.hrMarginTop ; ROW 底部 Y + HR margin-top
    cfg.btnY := cfg.hrY + cfg.btnMarginTop ; HR 的Y + Btn margin-top
    mainGui.Add("Text", ; 分隔線 本體
        "x" cfg.marginX
        " y" cfg.hrY
        " w" cfg.contentW
        " h1 BackgroundGray"
    )

    ; --- 底部 按鈕區 ---
    btnGap := (cfg.contentW - (cfg.btnW * 2)) / 3 ; 按鈕間距，每顆按鈕的左右一起算
    btnSaveX := cfg.marginX + btnGap
    btnCancelX := btnSaveX + cfg.btnW + btnGap

    ; Save / Cancel Button
    btnSave := mainGui.AddButton(
        "x" btnSaveX
        " y" cfg.btnY
        " w" cfg.btnW
        " h" cfg.btnH
        , "Save"
    )
    btnSave.SetFont("Bold")
    btnCancel := mainGui.AddButton(
        "x" btnCancelX
        " y" cfg.btnY
        " w" cfg.btnW
        " h" cfg.btnH
        , "Cancel"
    )

    ; 綁定按鈕事件
    guiForm := {
        adminMode: {
            on: adminOn,
            off: adminOff
        },
        triggerSide: {
            L: sideL,
            R: sideR,
            all: sideAll
        },
        triggerKey: modifierDDL,
        pauseKey: pauseInput,
    }
    ; 綁定事件
    btnSave.OnEvent("Click", (*) => SaveHandler(guiForm, mainGui))
    btnCancel.OnEvent("Click", (*) => mainGui.Hide())
    pinAotLabel.OnEvent("Click", (*) => pinAotLabelClickHandler(mainGui, pinAotCheckbox)) ; label for checkbox
    pinAotLabel.OnEvent("DoubleClick", (*) => pinAotLabelClickHandler(mainGui, pinAotCheckbox)) ; 快速點擊更順暢
    pinAotCheckbox.OnEvent("Click", (*) => TogglePin(mainGui, pinAotCheckbox))

    ; 回填 設定的 Value
    ApplyGuiValues(adminOn, adminOff, sideL, sideR, sideAll, modifierDDL, pauseInput)

    ; --- Gui 設定 ---
    guiX := IniRead(GuiPosFile, "Gui", "x", "")
    guiY := IniRead(GuiPosFile, "Gui", "y", "")
    mainGui.OnEvent("Close", (*) => mainGui.Hide())

    ; 用 guiH 來計算 margin bottom
    cfg.guiH := cfg.btnY + cfg.btnH + cfg.btnMarginBottom
    ; 設定完成，顯示 GUI
    if (guiX = "" || guiY = "") { ; 如果沒有 x y
        return mainGui.Show("w" cfg.guiW " h" cfg.guiH)
    }
    mainGui.Show("x" guiX " y" guiY " w" cfg.guiW " h" cfg.guiH)
}

; GUI 控制項回填目前設定值
ApplyGuiValues(adminOn, adminOff, sideL, sideR, sideAll, modifierDDL, pauseInput) {
    global g_adminMode
    global g_TrigSide
    global g_TrigModifier
    global toggleSuspendKey

    isAdminMode := (StrLower(Trim(g_adminMode)) = "true" || g_adminMode = "1")
    adminOn.Value := isAdminMode
    adminOff.Value := !isAdminMode

    trigSide := StrUpper(Trim(g_TrigSide))
    sideL.Value := trigSide = "L"
    sideR.Value := trigSide = "R"
    sideAll.Value := trigSide = "ALL"

    modifierDDL.Text := g_TrigModifier
    pauseInput.Value := toggleSuspendKey
}

SaveHandler(guiForm, mainGui) {
    global SettingsFile

    ; 檢查 guiForm 帶來的值，來決定寫入。 用radio裡面有沒有值來決定 (checked)
    ; admin mode
    adminMode := guiForm.adminMode.on.Value ? "true" : "false"

    ; trigger side.
    triggerSide := guiForm.triggerSide.L.Value ? "L"
        : guiForm.triggerSide.R.Value ? "R"
            : "ALL"

    ; trigger key
    triggerKey := guiForm.triggerKey.Text

    ; pause Key
    pauseKey := guiForm.pauseKey.Value

    ; 空白 錯誤檢查
    if (adminMode = "" || triggerSide = "" || triggerKey = "" || pauseKey = "") {
        MsgBox("設定值不完整，未寫入 Settings.ini")
        return
    }

    ; 寫入 設定檔
    IniWrite(adminMode, SettingsFile, "General", "AdminMode")
    IniWrite(pauseKey, SettingsFile, "Hotkeys", "ToggleSuspendKey")
    IniWrite(triggerSide, SettingsFile, "TrigKey", "Side")
    IniWrite(triggerKey, SettingsFile, "TrigKey", "Modifier")

    Reload()
}

; ========================================
; 設定檔讀取 & 預設值
; ========================================
LoadSettings(SettingsFile) { ; 以防沒讀到Settings
    global ToggleSuspendKey
    global g_TrigSide, g_TrigModifier
    global g_adminMode

    ; ; Suspend Toggle key
    ToggleSuspendKey := IniRead(SettingsFile, "Hotkeys", "ToggleSuspendKey", "F8") ; 預設 F8
    ; TrigKey
    g_TrigSide := IniRead(SettingsFile, "TrigKey", "Side", "R") ; Side 預設 R
    g_TrigModifier := IniRead(SettingsFile, "TrigKey", "Modifier", "Alt") ; Modifier 預設 Alt

    ;Admin
    g_adminMode := IniRead(SettingsFile, "General", "AdminMode", "false")
}

; ========================================
; 熱鍵註冊 動態綁定 初始化
; ========================================
InitHotkeys() {
    global ToggleSuspendKey
    global g_TrigSide, g_TrigModifier

    ; Reload
    Hotkey("RCtrl & F5", (*) => Reload())

    ; 動態綁定寫法: Hotkey, <按鍵變數名>, <要執行的標籤或函式>
    Hotkey(ToggleSuspendKey, ToggleSuspendHandler, "On S") ; 註冊暫停熱鍵，S = Suspend exempt，"On S" 為固定字眼

    ; 組裝修飾鍵，並轉成修飾鍵符號
    TriggerModifierSymbol := CreateTriggerModifierSymbol(g_TrigSide, g_TrigModifier) ; 組裝並轉化後，把結果存成變數

    ; 動態註冊成熱鍵 (為初始化的最後一步)，觸發後由 SendNumpadKey 函式處理
    RegisterAltNumHotkeys(TriggerModifierSymbol)
}

; ========================================
; AltNum 熱鍵群組 初始化
; ========================================
InitAltNumMap() { ; 設定主鍵 (PrimaryKey) & 對應的輸出(OutputKey) (主鍵 := 要送出的按鍵)
    global g_AltNumMap

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
}

; ========================================
; Auto Execute
; ========================================
CheckAdminMode(SettingsFile)
LoadSettings(SettingsFile)
InitTrayMenu()
InitAltNumMap()
InitHotkeys()
OnMessage(0x0232, WM_EXITSIZEMOVE) ; 啟用監聽功能 (聽: 視窗移動/縮放)
InitGUI() ; 執行 APP，多次執行 initGui() 會產生多個 Gui
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
ToggleSuspendHandler(*) {
    global TrayIconOn, TrayIconOff, Label_Suspend
    Suspend(-1) ; 切換掛起狀態 (-1 代表 Toggle)

    if (A_IsSuspended) {
        A_TrayMenu.Check(Label_Suspend) ; 在選單項目前面打勾
        __ShowTip("AltNum: OFF")

        TraySetIcon(TrayIconOff, , true) ; 設定托盤圖示為關閉狀態，並且強制更新圖示（第三個參數 true）
        return
    }
    if (!A_IsSuspended) {
        A_TrayMenu.Uncheck(Label_Suspend) ; 取消勾選
        __ShowTip("AltNum: ON")

        TraySetIcon(TrayIconOn) ; ICON
        return
    }
}

; 切換 Pin: AOT 的狀態
TogglePin(guiObj, pinAotCheckbox) {
    guiObj.Opt(pinAotCheckbox.Value ? "+AlwaysOnTop" : "-AlwaysOnTop")
}
pinAotLabelClickHandler(guiObj, pinAotCheckbox) {
    pinAotCheckbox.Value := !pinAotCheckbox.Value
    TogglePin(guiObj, pinAotCheckbox)
}

; 紀錄 Gui 座標
SaveGuiPos(guiObj) {
    global GuiPosFile

    WinGetPos(&x, &y, , , guiObj)

    IniWrite(x, GuiPosFile, "Gui", "x")
    IniWrite(y, GuiPosFile, "Gui", "y")
}

; 視窗移動或調整大小結束
WM_EXITSIZEMOVE(wParam, lParam, msg, hwnd) {
    global mainGui
    if (hwnd = mainGui.Hwnd) {
        SaveGuiPos(mainGui)
    }
}

; 修飾鍵符號 組合與轉換
CreateTriggerModifierSymbol(origSide, origModifier) {
    ; 根據 Setting 的 Side 和 Modifier 來建立熱鍵的修飾鍵，再將"修飾鍵"轉成"修飾鍵符號" eg. "L" + "Ctrl" -> "<^"
    trigSide := StrUpper(Trim(origSide))
    trigModifier := StrLower(Trim(origModifier))

    sideMap := Map(
        "ALL", "",
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
            "Invalid TrigKey Side:`nYou set: " origSide "`nAllowed: L / R / ALL",
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
        ahkShortcut := TriggerModifierSymbol . PrimaryKey ; 組合成 AHK 熱鍵縮寫
        Hotkey(ahkShortcut, SendMappedKey.Bind(outputKey))
    }
}
; 熱鍵觸發後，送出映射後的按鍵
SendMappedKey(outputKey, *) {
    SendInput(outputKey)
}
