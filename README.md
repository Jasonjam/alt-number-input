# alt-number-input

此為 ahk v1 製作的腳本  
為解決 Windows 注音 在 80% 鍵盤下，輸入數字需來回切換輸入法的問題  
靈感從 mac 上的 Fn + 1–9 得來

## 快速開始

- 解壓縮 zip 後，點擊 `build.bat`
- 等待編譯完成後，執行 `AltNum.exe`

## 下載

- 下載連結: [Latest Ver.](https://github.com/Jasonjam/alt-number-input/releases/latest)
- 也可到右邊 Releases 頁面找 Latest 版本，Assets 下載 zip 壓縮檔

### 注意

- exe 檔可能會被防毒或 Microsoft Defender 擋住
    - 可點"其他資訊" > 仍要執行
    - 若不放心，可自行下載 AutoHotkey v1 官方轉檔工具

## 功能

- 預設 `Right Alt + 0–9`：在注音輸入法下直接輸出數字
- 支援數字鍵盤符號：
    - `Alt + .` → `.`
    - `Alt + -` → `-`
    - `Alt + /` → `/`
- F8： 功能暫停開關 (可自訂開關按鍵)

### 設定檔 ( Settings.ini )

- AltNum 模式暫停開關: F8 (預設)
- 開關提示的顯示位置: 主螢幕中央 / 自訂座標
- 觸發組合鍵: Right Alt (預設)，可自訂 `L / R / 空白` + `Ctrl / Alt / Shift / Win`

## 備註

使用 Ahk2Exe.exe 編譯  
ICON 使用 Affinity 製作
