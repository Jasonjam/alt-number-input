# alt-number-input

此為 ahk v1 製作的腳本  
為解決 Windows 注音 在 80% 鍵盤下，打數字要來回切換中英文的問題  
透過 Alt + 數字鍵 (0–9) 即可直接輸出數字，也支援符號 , . ; -  
靈感來自 macOS 上的 Fn + 1–9 可直接輸出數字的設計

## 注意

-   Release 的 exe 檔會被防毒或 Microsoft Defender 擋住
    -   可點"其他資訊" > 仍要執行
    -   若不放心，可以用 'tools' 資料夾內的 AutoHotkey2ExePortable.exe 自行轉成 exe
    -   或上網自行下載 AutoHotkey 官方轉檔工具

## 功能

-   Alt + 0–9：在注音輸入法下直接輸出數字
-   支援常用符號：
    -   `Alt + ,` → `,`
    -   `Alt + .` → `.`
    -   `Alt + ;` → `;`
    -   `Alt + -` → `-`
-   無需切換中英輸入模式
-   F8：Alt-number 模式開關 (可自訂開關按鍵)

### 設定檔 ( Settings.txt )

-   Alt-number 模式開關: F8 ( 預設 )
-   開關提示的顯示位置: 主螢幕中央 / 自訂座標

## 編譯

使用 AutoHotkey2ExePortable 打包成 exe  
ICON 使用 Affinity 製作

### 使用附帶工具編譯

1. 解壓 `tools/AutoHotkey2ExePortable.zip`
2. 執行解壓後資料夾內的 `AutoHotkey2ExePortable.exe`
3. 在工具中設定：
    - **Source (script file)**：選擇 `src/alt-number-input.ahk`
    - **Custom Ico(.ico file)**：選擇 `assets/altnum_512px.ico`（非必要）
4. 按下 `Convert` 產生 exe
