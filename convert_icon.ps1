# PowerShell script to convert PNG to ICO with multiple sizes
# This script requires the ImageMagick tool or Windows built-in capabilities

param(
    [Parameter(Mandatory=$true)]
    [string]$InputImage,
    [Parameter(Mandatory=$true)]
    [string]$OutputIcon
)

Write-Host "Converting $InputImage to $OutputIcon..."

# Check if ImageMagick is available
$imageMagickPath = Get-Command "magick" -ErrorAction SilentlyContinue

if ($imageMagickPath) {
    Write-Host "Using ImageMagick to convert image..."
    
    # Create ICO with multiple sizes (16x16, 24x24, 32x32, 48x48, 64x64, 128x128, 256x256)
    & magick $InputImage -resize 256x256 -quality 100 `
        "(" -clone 0 -resize 16x16 ")" `
        "(" -clone 0 -resize 24x24 ")" `
        "(" -clone 0 -resize 32x32 ")" `
        "(" -clone 0 -resize 48x48 ")" `
        "(" -clone 0 -resize 64x64 ")" `
        "(" -clone 0 -resize 128x128 ")" `
        -delete 0 $OutputIcon
    
    Write-Host "ICO file created successfully at $OutputIcon"
    
    # Also create individual PNG files for the icons folder
    $iconDir = Split-Path $OutputIcon -Parent
    $iconDir = Join-Path $iconDir "icons"
    
    if (Test-Path $iconDir) {
        Write-Host "Creating individual PNG files..."
        & magick $InputImage -resize 16x16 (Join-Path $iconDir "rufus-16.png")
        & magick $InputImage -resize 24x24 (Join-Path $iconDir "rufus-24.png")
        & magick $InputImage -resize 32x32 (Join-Path $iconDir "rufus-32.png")
        & magick $InputImage -resize 44x44 (Join-Path $iconDir "rufus-44.png")
        & magick $InputImage -resize 48x48 (Join-Path $iconDir "rufus-48.png")
        & magick $InputImage -resize 64x64 (Join-Path $iconDir "rufus-64.png")
        & magick $InputImage -resize 72x72 (Join-Path $iconDir "rufus-72.png")
        & magick $InputImage -resize 128x128 (Join-Path $iconDir "rufus-128.png")
        & magick $InputImage -resize 150x150 (Join-Path $iconDir "rufus-150.png")
        & magick $InputImage -resize 256x256 (Join-Path $iconDir "rufus-256.png")
        & magick $InputImage -resize 512x512 (Join-Path $iconDir "rufus-512.png")
        
        # Also create a copy as rufus.ico in the icons folder
        Copy-Item $OutputIcon (Join-Path $iconDir "rufus.ico")
        
        Write-Host "Individual PNG files created in icons folder"
    }
} else {
    Write-Host "ImageMagick not found. Please install ImageMagick or use an online converter."
    Write-Host "You can download ImageMagick from: https://imagemagick.org/script/download.php#windows"
    Write-Host ""
    Write-Host "Alternative: Use an online ICO converter like:"
    Write-Host "- https://convertio.co/png-ico/"
    Write-Host "- https://www.icoconverter.com/"
    Write-Host ""
    Write-Host "Make sure to create multiple sizes: 16x16, 24x24, 32x32, 48x48, 64x64, 128x128, 256x256"
}