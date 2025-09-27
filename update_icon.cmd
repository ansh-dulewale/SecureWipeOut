@echo off
echo Converting new icon...
echo.
echo Please make sure you have saved the new icon image as "new_icon.png" in this directory
echo.
pause

if not exist "new_icon.png" (
    echo ERROR: new_icon.png not found!
    echo Please save the attachment image as "new_icon.png" in this directory first.
    pause
    exit /b 1
)

echo Running PowerShell conversion script...
powershell -ExecutionPolicy Bypass -File "convert_icon.ps1" -InputImage "new_icon.png" -OutputIcon "res\rufus.ico"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Icon conversion completed successfully!
    echo.
    echo The following files have been updated:
    echo - res\rufus.ico
    echo - res\icons\rufus.ico
    echo - res\icons\rufus-*.png (various sizes)
    echo.
    echo You can now rebuild the application to see the new icon.
) else (
    echo.
    echo Conversion failed. Please check the error messages above.
)

echo.
pause