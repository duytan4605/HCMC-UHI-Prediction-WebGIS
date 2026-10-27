@echo off
title HCMC UHI - Flutter Windows Application
echo ========================================================
echo   HE THONG DU BAO DAO NHIET DO THI TP. HO CHI MINH
echo   Khoi dong ung dung Flutter Windows Native
echo ========================================================
echo.
set EXE_PATH=%~dp0DACN\frontend\mobile_app_flutter\build\windows\x64\runner\Release\hcmc_uhi.exe
if exist "%EXE_PATH%" (
    start "" "%EXE_PATH%"
) else (
    echo Khong tim thay file release exe, dang chay flutter run -d windows...
    cd /d "%~dp0DACN\frontend\mobile_app_flutter"
    flutter run -d windows
)

