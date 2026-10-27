@echo off
title HCMC UHI - Backend FastAPI
echo ========================================================
echo   HE THONG DU BAO DAO NHIET DO THI TP. HO CHI MINH
echo   Backend FastAPI (XGBoost + SQLite + Heatmap API)
echo ========================================================
echo.

:: Tu dong giai phong cong 8000 neu co tien trinh cu dang chiem giu
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8000 ^| findstr LISTENING') do (
    echo Dang giai phong cong 8000 tu tien trinh PID %%a...
    taskkill /f /pid %%a >nul 2>&1
)

echo Dang khoi dong may chu tai http://127.0.0.1:8000 ...
cd /d "%~dp0DACN"
if exist "..\.venv\Scripts\python.exe" (
    ..\.venv\Scripts\python.exe -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
) else (
    python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
)
pause
