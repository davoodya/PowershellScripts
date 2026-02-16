Add-Type -AssemblyName System.Windows.Forms

# ===============================
# 1. Video URL
# ===============================
$videoUrl = Read-Host "Enter Video URL"
$videoUrl = $videoUrl.Trim().Trim('"')

if ([string]::IsNullOrWhiteSpace($videoUrl)) {
    Write-Error "Video URL cannot be empty"
    exit
}

# ===============================
# 2. Quality
# ===============================
$qualities = @{
    "144"  = 144
    "240"  = 240
    "360"  = 360
    "480"  = 480
    "720"  = 720
    "1080" = 1080
}

Write-Host "Available qualities: 144, 240, 360, 480, 720, 1080"
$qualityInput = Read-Host "Select quality"

if (-not $qualities.ContainsKey($qualityInput)) {
    Write-Error "Invalid quality selected"
    exit
}

$height = $qualities[$qualityInput]

# ===============================
# 3. Threads
# ===============================
$threads = Read-Host "Enter download threads (1-32)"
if (-not ($threads -as [int]) -or $threads -lt 1 -or $threads -gt 32) {
    Write-Error "Threads must be between 1 and 32"
    exit
}

# ===============================
# 4. Get Video Title
# ===============================
$videoTitle = & yt-dlp --get-title $videoUrl 2>$null
if ([string]::IsNullOrWhiteSpace($videoTitle)) {
    $videoTitle = "video"
}

$invalid = [IO.Path]::GetInvalidFileNameChars()
foreach ($c in $invalid) { $videoTitle = $videoTitle.Replace($c, "_") }

# ===============================
# 5. Save As Dialog
# ===============================
$saveDialog = New-Object System.Windows.Forms.SaveFileDialog
$saveDialog.Filter = "MP4 Video (*.mp4)|*.mp4"
$saveDialog.Title  = "Save Video As"
$saveDialog.FileName = "$videoTitle.mp4"

if ($saveDialog.ShowDialog() -ne "OK") {
    Write-Host "Cancelled by user"
    exit
}

$outputMp4 = $saveDialog.FileName
$outputDir = Split-Path $outputMp4
$tempMp4   = Join-Path $outputDir "__temp_download__.mp4"

# ===============================
# 6. Compression Mode
# ===============================
Write-Host "`nCompression options:"
Write-Host "0 - No compression (Fast, larger size)"
Write-Host "1 - Smart compression (Recommended)"
Write-Host "2 - Lossless (Very large file)"

$compression = Read-Host "Select compression (0 / 1 / 2)"
if ($compression -notin @("0","1","2")) {
    Write-Error "Invalid compression option"
    exit
}

# ===============================
# 7. yt-dlp Download (MP4 only)
# ===============================
$format = "bv*[vcodec^=avc][height<=$height]/bv*[height<=$height]/b"

Write-Host "`nDownloading video..."

& yt-dlp `
    -N $threads `
    -f $format `
    --merge-output-format mp4 `
    -o $tempMp4 `
    --user-agent "Mozilla/5.0" `
    $videoUrl

if (-not (Test-Path $tempMp4)) {
    Write-Error "Download failed – MP4 file not created"
    exit
}

# ===============================
# 8. No Compression
# ===============================
if ($compression -eq "0") {
    Move-Item -Force $tempMp4 $outputMp4
    Write-Host "Download completed (no compression)"
    exit
}

# ===============================
# 9. ffmpeg Compression
# ===============================
switch ($compression) {
    "1" {
        # Smart compression
        $ffArgs = @(
            "-c:v","libx264",
            "-preset","slow",
            "-crf","23",
            "-pix_fmt","yuv420p",
            "-c:a","aac",
            "-b:a","128k"
        )
    }
    "2" {
        # Lossless
        $ffArgs = @(
            "-c:v","libx264",
            "-preset","veryslow",
            "-crf","0",
            "-pix_fmt","yuv420p",
            "-c:a","copy"
        )
    }
}

Write-Host "Compressing video..."

& ffmpeg -y -i $tempMp4 @ffArgs $outputMp4

Remove-Item $tempMp4 -Force
Write-Host "Download and compression completed successfully"
