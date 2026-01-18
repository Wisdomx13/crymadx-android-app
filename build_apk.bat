@echo off
echo Building CrymadX Release APK...
echo.
cd /d "%~dp0"
C:\flutter\bin\flutter.bat build apk --release
echo.
echo APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
