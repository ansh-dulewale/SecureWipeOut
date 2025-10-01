@echo off
REM SecureWipe Linux Build Script for Windows
REM Builds the Linux boot environment on Windows using WSL or Docker

echo ============================================
echo   SecureWipe Linux Boot Environment Build
echo ============================================
echo.

REM Check for WSL availability
wsl --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ WSL detected - using Linux build environment
    goto :build_with_wsl
) else (
    echo ❌ WSL not available
    goto :check_docker
)

:check_docker
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Docker detected - using containerized build
    goto :build_with_docker
) else (
    echo ❌ Neither WSL nor Docker available
    goto :error_no_build_env
)

:build_with_wsl
echo Building SecureWipe Linux environment using WSL...
echo.

REM Copy build scripts to WSL accessible location
wsl mkdir -p /tmp/securewipe-build
wsl cp -r ./linux-boot/* /tmp/securewipe-build/

REM Execute build script in WSL
wsl cd /tmp/securewipe-build/scripts && chmod +x *.sh && ./build-complete.sh

if %errorlevel% equ 0 (
    echo ✅ Build completed successfully!
    wsl cp /tmp/securewipe-build/output/securewipe-boot.iso ./
    echo ISO file copied to current directory
) else (
    echo ❌ Build failed in WSL
    goto :error_build_failed
)
goto :end

:build_with_docker
echo Building SecureWipe Linux environment using Docker...
echo.

REM Create Dockerfile for build environment
echo FROM alpine:3.19 > Dockerfile.build
echo RUN apk add --no-cache bash curl tar genisoimage grub >> Dockerfile.build
echo WORKDIR /build >> Dockerfile.build
echo COPY linux-boot/ /build/ >> Dockerfile.build
echo RUN chmod +x /build/scripts/*.sh >> Dockerfile.build
echo CMD ["/build/scripts/build-complete.sh"] >> Dockerfile.build

REM Build Docker image and run build
docker build -f Dockerfile.build -t securewipe-builder .
docker run --rm -v %cd%:/output securewipe-builder

if %errorlevel% equ 0 (
    echo ✅ Build completed successfully!
) else (
    echo ❌ Build failed in Docker
    goto :error_build_failed
)

REM Cleanup
del Dockerfile.build
goto :end

:error_no_build_env
echo.
echo ERROR: No suitable build environment found!
echo.
echo SecureWipe needs either WSL or Docker to build the Linux boot environment.
echo.
echo To install WSL:
echo   1. Run: wsl --install
echo   2. Restart your computer
echo   3. Run this script again
echo.
echo Alternatively, install Docker Desktop from https://docker.com/
echo.
pause
exit /b 1

:error_build_failed
echo.
echo ERROR: Build process failed!
echo.
echo Please check the error messages above and ensure:
echo - You have sufficient disk space (at least 1GB free)
echo - Internet connection is available for downloading Alpine Linux
echo - No antivirus software is blocking the build process
echo.
pause
exit /b 1

:end
echo.
echo ============================================
echo   SecureWipe Linux Build Complete!
echo ============================================
echo.
echo The bootable ISO image has been created and is ready for use.
echo You can now use SecureWipe to create bootable USB drives.
echo.
pause