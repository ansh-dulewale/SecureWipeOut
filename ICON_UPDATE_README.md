# Icon Update Instructions

This document explains how to update the SecureWipe application icons with your new brush/cleaning icon.

## Prerequisites

You'll need one of the following:
1. **ImageMagick** (recommended) - Download from https://imagemagick.org/script/download.php#windows
2. **Online ICO converter** - Such as https://convertio.co/png-ico/ or https://www.icoconverter.com/

## Steps to Update Icons

### Method 1: Using the Automated Script (Recommended)

1. **Save the new icon**: Save the brush/cleaning icon image from the attachment as `new_icon.png` in the root directory of the SecureWipeOut project.

2. **Run the conversion script**: Double-click on `update_icon.cmd` or run it from the command line.

3. **Rebuild the application**: After successful conversion, rebuild the application using Visual Studio or your preferred build method.

### Method 2: Manual Conversion

If the automated script doesn't work:

1. **Save the attachment image** as `new_icon.png`

2. **Convert to ICO format** with multiple sizes:
   - 16x16 pixels
   - 24x24 pixels  
   - 32x32 pixels
   - 48x48 pixels
   - 64x64 pixels
   - 128x128 pixels
   - 256x256 pixels

3. **Replace the following files**:
   - `res/rufus.ico` - Main application icon
   - `res/icons/rufus.ico` - Copy of main icon
   - `res/icons/rufus-16.png`
   - `res/icons/rufus-24.png`
   - `res/icons/rufus-32.png`
   - `res/icons/rufus-44.png`
   - `res/icons/rufus-48.png`
   - `res/icons/rufus-64.png`
   - `res/icons/rufus-72.png`
   - `res/icons/rufus-128.png`
   - `res/icons/rufus-150.png`
   - `res/icons/rufus-256.png`
   - `res/icons/rufus-512.png`

## Files Affected

The icon change affects these resource files:
- `src/rufus.rc` - Contains the main icon reference (IDI_ICON points to ../res/rufus.ico)
- `res/rufus.ico` - Main application icon file
- `res/icons/` - Directory containing various icon sizes

## No Code Changes Required

The good news is that no source code changes are needed! The application already references the correct icon files through the resource file (`src/rufus.rc`), so simply replacing the icon files and rebuilding will apply the new icon.

## Verification

After updating and rebuilding:
1. Check that the new icon appears in Windows Explorer for the executable
2. Verify the icon appears in the application's title bar and taskbar
3. Confirm the About dialog shows the new icon

## Troubleshooting

- **Icon doesn't change**: Make sure to do a clean rebuild of the project
- **Image quality issues**: Ensure the source image is high resolution (at least 512x512) for best results
- **Conversion fails**: Try using an online converter if ImageMagick is not available