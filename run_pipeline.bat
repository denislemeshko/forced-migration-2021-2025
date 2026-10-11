@echo off
chcp 65001 > nul
set "PYTHONIOENCODING=utf-8"
setlocal
cd /d "%~dp0"

if not exist "logs" mkdir "logs"
if not exist "logs" exit /b 1

set "RUN_ID="
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss_fff"') do set "RUN_ID=%%I"
if not defined RUN_ID exit /b 1

set "LOG_FILE=logs\run_%RUN_ID%.log"

echo Pipeline running. Log: %LOG_FILE%
call :pipeline > "%LOG_FILE%" 2>&1
set "RESULT=%ERRORLEVEL%"

type "%LOG_FILE%"
echo.
echo Log saved: %LOG_FILE%
exit /b %RESULT%

:pipeline
echo START: %DATE% %TIME%

echo [1/3] Fetching API data
python check_api.py
if errorlevel 1 goto fail

echo [2/3] Analyzing data
python analyze.py
if errorlevel 1 goto fail

python analyze_origins.py
if errorlevel 1 goto fail

python analyze_world.py
if errorlevel 1 goto fail

echo [3/3] Loading PostgreSQL
docker compose exec -T db psql -U analyst -d unhcr < schema.sql
if errorlevel 1 goto fail

docker compose exec -T db psql -U analyst -d unhcr < load.sql
if errorlevel 1 goto fail

docker compose exec -T db psql -U analyst -d unhcr < load_origins.sql
if errorlevel 1 goto fail

docker compose exec -T db psql -U analyst -d unhcr < load_world.sql
if errorlevel 1 goto fail

echo Checking data completeness
docker compose exec -T db psql -U analyst -d unhcr < checks.sql
if errorlevel 1 goto fail

echo Running SQL analysis
docker compose exec -T db psql -U analyst -d unhcr -v ON_ERROR_STOP=1 < analysis.sql
if errorlevel 1 goto fail

echo SUCCESS: %DATE% %TIME%
exit /b 0

:fail
echo FAILED: %DATE% %TIME%
exit /b 1