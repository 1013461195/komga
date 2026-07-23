@echo off
chcp 65001 >nul
setlocal

echo ==========================================
echo   Komga PostgreSQL Build Script
echo ==========================================
echo.

cd /d "%~dp0"

REM ---------- Check Docker ----------
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker not found. Please install Docker Desktop first.
    echo.
    goto :fail
)
echo [OK] Docker found
echo.

REM ---------- Build JAR ----------
echo Building JAR with gradle:jdk21-alpine ...
echo This may take a few minutes, please wait...
echo.

docker run --rm -v "%cd%:/home/gradle/project" -w /home/gradle/project -e GRADLE_OPTS=-Xmx2G gradle:jdk21-alpine gradle :komga:bootJar -x test --no-daemon

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Gradle build failed.
    echo.
    goto :fail
)

REM ---------- Check JAR ----------
if exist "komga\build\libs\komga-*.jar" (
    echo.
    echo [OK] JAR build successful!
    echo.
    dir /b "komga\build\libs\komga-*.jar"
    echo.
) else (
    echo.
    echo [ERROR] JAR file not found in komga\build\libs\
    echo.
    goto :fail
)

echo ==========================================
echo   Build completed!
echo.
echo   Next step:
echo     cd komga\docker
echo     docker compose -f docker-compose.postgresql.yml up -d --build
echo ==========================================
echo.

:fail
pause
endlocal
