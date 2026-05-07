@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "SOURCE=%CD%\src\AltNum.ahk1"
set "OUT_EXE=%CD%\AltNum.exe"

set "ICON_ON=%CD%\assets\altnum.ico"

set "AHK2EXE=%CD%\tools\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BASE=%CD%\tools\AutoHotkey\Compiler\Unicode 32-bit.bin"

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

if not exist "%ICON_ON%" (
    echo.
    echo [ERROR] 找不到ICO圖檔 / Icon not found:
    echo %ICON_ON%
    pause
    exit /b 1
)

if not exist "%AHK2EXE%" (
    echo.
    echo [ERROR] 找不到 Ahk2Exe.exe / Ahk2Exe.exe not found:
    echo %AHK2EXE%
    pause
    exit /b 1
)

if not exist "%BASE%" (
    echo.
    echo [ERROR] 找不到 Base 檔案 / Base file not found:
    echo %BASE%
    pause
    exit /b 1
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
"%AHK2EXE%" /in "%SOURCE%" /out "%OUT_EXE%" /icon "%ICON_ON%" /base "%BASE%"

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