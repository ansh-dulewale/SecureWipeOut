SecureWipe: The Reliable USB Formatting Utility
===============================================
[//]: # (Requirements section)

Requirements
------------

To build and run SecureWipe, you need:

- **Windows 10/11 (x64)**
- **Visual Studio 2022** (Community Edition is sufficient)
	- Includes MSVC compiler and Windows SDK
- **Git** (for version control)
- **PowerShell** (for running scripts)
- **Optional:** MinGW (for alternative build method)
- **Optional:** ImageMagick (for advanced icon conversion)

For icon updates:
- PNG image for your custom icon
- Online PNG to ICO converter (e.g. https://convertio.co/png-ico/)

No installation is required to run SecureWipe; just build and launch the executable.

[![VS2022 Build Status](https://img.shields.io/github/actions/workflow/status/pbatard/rufus/vs2022.yml?branch=master&style=flat-square&label=VS2022%20Build)](https://github.com/pbatard/rufus/actions/workflows/vs2022.yml)
[![MinGW Build Status](https://img.shields.io/github/actions/workflow/status/pbatard/rufus/mingw.yml?branch=master&style=flat-square&label=MinGW%20Build)](https://github.com/pbatard/rufus/actions/workflows/mingw.yml)
[![Coverity Scan Status](https://img.shields.io/coverity/scan/2172.svg?style=flat-square&label=Coverity%20Analysis)](https://scan.coverity.com/projects/pbatard-rufus)  
[![Latest Release](https://img.shields.io/github/release-pre/pbatard/rufus.svg?style=flat-square&label=Latest%20Release)](https://github.com/pbatard/rufus/releases)
[![Licence](https://img.shields.io/badge/license-GPLv3-blue.svg?style=flat-square&label=License)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![Download Stats](https://img.shields.io/github/downloads/pbatard/rufus/total.svg?label=Downloads&style=flat-square)](https://github.com/pbatard/rufus/releases)
[![Contributors](https://img.shields.io/github/contributors/pbatard/rufus.svg?style=flat-square&label=Contributors)](https://github.com/pbatard/rufus/graphs/contributors)

![SecureWipe logo](https://raw.githubusercontent.com/pbatard/rufus/master/res/icons/rufus-128.png)

SecureWipe is a utility that helps format and create bootable USB flash drives.

Features
--------

* Format USB, flash card and virtual drives to FAT/FAT32/NTFS/UDF/exFAT/ReFS/ext2/ext3
* Create DOS bootable USB drives using [FreeDOS](https://www.freedos.org) or MS-DOS
* Create BIOS or UEFI bootable drives, including [UEFI bootable NTFS](https://github.com/pbatard/uefi-ntfs)
* Create bootable drives from bootable ISOs (Windows, Linux, etc.)
* Create bootable drives from bootable disk images, including compressed ones
* Create Windows 11 installation drives for PCs that don't have TPM or Secure Boot
* Create [Windows To Go](https://en.wikipedia.org/wiki/Windows_To_Go) drives
* Create VHD/DD, VHDX and FFU images of an existing drive
* Create persistent Linux partitions
* Compute MD5, SHA-1, SHA-256 and SHA-512 checksums of the selected image
* Perform runtime validation of UEFI bootable media
* Improve Windows installation experience by automatically setting up OOBE parameters (local account, privacy options, etc.)
* Perform bad blocks checks, including detection of "fake" flash drives
* Download official Microsoft Windows 8, Windows 10 or Windows 11 retail ISOs
* Download [UEFI Shell](https://github.com/pbatard/UEFI-Shell) ISOs
* Modern and familiar UI, with [38 languages natively supported](https://github.com/pbatard/rufus/wiki/FAQ#What_languages_are_natively_supported_by_Rufus)
* Small footprint. No installation required.
* Portable. Secure Boot compatible.
* 100% [Free Software](https://www.gnu.org/philosophy/free-sw) ([GPL v3](https://www.gnu.org/licenses/gpl-3.0))

Compilation

How to Run SecureWipe
---------------------

After building the project, you can run SecureWipe as follows:

### 1. Run the Application

- Navigate to the build output directory:
	```
	cd x64\Release
	```
- Run the executable:
	```
	.\securewipe.exe
	```
	This will launch the SecureWipe GUI application.

### 2. Update the Application Icon

If you want to update the application icon to your custom brush/cleaning icon:

1. Save your icon image as `new_icon.png` in the project root.
2. Convert it to ICO format using an online tool (e.g. https://convertio.co/png-ico/) and save as `new_icon.ico`.
3. Run the provided script:
	 ```
	 .\update_icon_simple.cmd
	 ```
	 This will replace the icon files in `res/` and `res/icons/`.

4. Rebuild the project to apply the new icon:
	 ```
	 $env:PATH += ";C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin"
	 msbuild rufus.sln /p:Configuration=Release /p:Platform=x64
	 ```

### 3. Push Changes to GitHub

To push your changes:
```
git add .
git commit -m "Update application icon and add run instructions"
git push origin master
```

---
Use either Visual Studio 2022 or MinGW and then invoke the `.sln` or `configure`/`make` respectively.

#### Visual Studio

SecureWipe is an OSI compliant Open Source project. You are entitled to
download and use the *freely available* [Visual Studio Community Edition](https://www.visualstudio.com/vs/community/)
to build, run or develop for SecureWipe. As per the Visual Studio Community Edition license,
this applies regardless of whether you are an individual or a corporate user.

Additional information
----------------------

SecureWipe provides extensive information about what it is doing, either through its
easily accessible log, or through the [Windows debug facility](https://docs.microsoft.com/en-us/sysinternals/downloads/debugview).

* [__Official Website__](https://rufus.ie)
* [FAQ](https://github.com/pbatard/rufus/wiki/FAQ)

Enhancements/Bugs
-----------------

Please use the [GitHub issue tracker](https://github.com/pbatard/rufus/issues)
for reporting problems or suggesting new features.
