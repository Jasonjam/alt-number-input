@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "SOURCE=%CD%\src\AltNum.ahk"
set "OUT_EXE=%CD%\AltNum.exe"

set "ICON=%CD%\assets\altnum.ico"

set "COMPILER=tools\AutoHotkey\Compiler\Ahk2Exe.ahk"
set "V2_BASE=tools\AutoHotkey\AutoHotkey64.exe"
SET "V1_ENGINE=tools\AutoHotkey\AutohotkeyU64.exe"

echo.
echo ================================
echo         AltNum 編譯工具
echo         AltNum Build Tool
echo ================================
echo.
echo [INFO] 此工具會在專案根目錄產生 AltNum.exe
echo        This tool will compile AltNum.exe in the project root.
echo.
echo.


echo [1/4] 檢查檔案來源 / Checking file sources...
if not exist "%SOURCE%" (
    echo.
    echo [ERROR] 找不到來源檔案 / Source not found:
    echo %SOURCE%
    pause
    exit /b 1
)

if not exist "%ICON%" (
    echo.
    echo [ERROR] 找不到ICO圖檔 / Icon not found:
    echo %ICON%
    pause
    exit /b 1
)

if not exist "%COMPILER%" (
    echo.
    echo [ERROR] 找不到 Ahk2Exe.ahk / Ahk2Exe.ahk not found:
    echo %COMPILER%
    pause
    exit /b 1
)

if not exist "%V1_ENGINE%" (
    echo.
    echo [ERROR] 找不到 v1Engine / v1Engine not found:
    echo %V1_ENGINE%
    pause
    exit /b 1
)

if not exist "%V2_BASE%" (
    echo.
    echo [ERROR] 找不到 v2Base: AutoHotkey64.exe 檔案 / v2Base: AutoHotkey64.exe file not found:
    echo %V2_BASE%
    pause
    exit /b 1
)

if exist "src\.pos.ini.template" (
    if not exist "src\.pos.ini" (
        move "src\.pos.ini.template" "src\.pos.ini" >nul
        echo [CRTE]  已建立 .pos.ini / Created .pos.ini
    ) else (
        del "src\.pos.ini.template"
        echo [SKIP] .pos.ini 已存在 / .pos.ini already exists
    )
)

echo [OK]  必要檔案檢查完成 / Required files found
echo.
echo.


echo [2/4] 移除舊的輸出檔案 / Removing old output file...
if exist "%OUT_EXE%" (
    del "%OUT_EXE%"
    echo [OK]  已移除舊的 AltNum.exe / Old AltNum.exe removed
) else (
    echo  [SKIP] 沒有舊的 AltNum.exe / No old AltNum.exe found
)
echo.
echo.


echo [3/4] 開始編譯 / Compiling AltNum...
:: 使用引號包覆所有路徑，並確保參數順序正確
"%V1_ENGINE%" "%COMPILER%" /in "%SOURCE%" /out "%OUT_EXE%" /icon "%ICON%" /base "%V2_BASE%"

if errorlevel 1 (
    echo [ERROR] 編譯失敗 / Compile failed.
    pause
    exit /b 1
) else (
    echo [OK]  編譯成功 / Compile succeeded.
)
echo.
echo.



echo [4/4] 檢查輸出檔案 / Checking output...
if not exist "%OUT_EXE%" (
    echo [ERROR] 輸出的 exe 檔案未生成 / Output exe not generated:
    echo %OUT_EXE%
    pause
    exit /b 1
) else (
    echo [OK]  輸出檔案生成成功 / Output file generated successfully:
)
echo.

echo.
echo ----------------------------------
echo [OK]  編譯完成 / Build complete
echo ----------------------------------
echo.
echo 輸出檔案 / Output :
echo %OUT_EXE%
echo.

pause