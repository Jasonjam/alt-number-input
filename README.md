# alt-number-input

此為 ahk v2 製作的腳本  
為解決 Windows 注音 在 80% 鍵盤下，輸入數字需來回切換輸入法的問題

## 快速開始

- 解壓縮 zip 後，點擊 `build.bat`
- 等待編譯完成後，執行 `AltNum.exe`

## 下載

- 下載連結: [Latest Ver.](https://github.com/Jasonjam/alt-number-input/releases/latest)
- 也可到右邊 Releases 頁面找 Latest 版本，Assets 下載 zip 壓縮檔

### 注意

- exe 檔可能會被防毒或 Microsoft Defender 擋住
    - 可點"其他資訊" > 仍要執行
    - 若不放心，可自行下載 AutoHotkey v2 官方轉檔工具

## 功能

- 預設 `RAlt + 0–9`：在注音輸入法下直接輸出數字
- 支援數字鍵盤常見符號：
    - `Alt + .` → `.`
    - `Alt + -` → `-`
    - `Alt + /` → `/`
- 重新載入程式: `RCtrl + F5`

## 設定頁

- Admin Mode: 以管理員模式啟動 (建議開啟)
- Trigger Side: 左 / 右 / 不設限 (預設 All)
- Trigger Key: 選擇修飾鍵 (預設 Alt)
- Pause Key: 暫停開關 (預設 F8)

## 備註

使用 Ahk2Exe.ahk 編譯  
Icon 使用 Affinity 製作
靈感自 mac 的 Fn + 1–9
