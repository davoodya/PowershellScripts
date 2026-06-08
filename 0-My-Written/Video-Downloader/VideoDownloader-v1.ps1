Add-Type -AssemblyName System.Windows.Forms

# --- 1. دریافت URL ---
$videoUrl = Read-Host "Enter Video URL"

if ([string]::IsNullOrWhiteSpace($videoUrl)) {
    Write-Error "Video URL cannot be empty"
    exit
}

# --- 2. دریافت کیفیت ---
$validQualities = @{
    "144"  = 144
    "240"  = 240
    "360"  = 360
    "480"  = 480
    "720"  = 720
    "1080" = 1080
    "2k"   = 1440
    "4k"   = 2160
}

Write-Host "Available qualities: 144, 240, 360, 480, 720, 1080, 2k, 4k"
$qualityInput = Read-Host "Select quality"

if (-not $validQualities.ContainsKey($qualityInput)) {
    Write-Error "Invalid quality selected"
    exit
}

$height = $validQualities[$qualityInput]

# --- 3. دریافت تعداد Thread ---
$threads = 0
$threadsInput = Read-Host "Enter download threads (1 - 32 recommended)"

if (-not [int]::TryParse($threadsInput, [ref]$threads)) {
    Write-Error "Threads must be a numeric value"
    exit
}

if ($threads -lt 1 -or $threads -gt 32) {
    Write-Error "Threads must be between 1 and 32"
    exit
}


# --- 4. Save As Dialog ---

# --- Get Video Default Name ---
$videoTitle = & yt-dlp --get-title $videoUrl 2>$null

if ([string]::IsNullOrWhiteSpace($videoTitle)) {
    $videoTitle = "video"
}

# Remove unnessacry characters from video name
$invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
foreach ($char in $invalidChars) {
    $videoTitle = $videoTitle.Replace($char, '_')
}

$defaultFileName = "$videoTitle.mp4"

# --- Save As with Default Name ---
$saveDialog = New-Object System.Windows.Forms.SaveFileDialog
$saveDialog.Filter = "MP4 Video (*.mp4)|*.mp4"
$saveDialog.Title = "Save Video As"
$saveDialog.FileName = $defaultFileName
$saveDialog.OverwritePrompt = $true

if ($saveDialog.ShowDialog() -ne "OK") {
    Write-Host "Download cancelled by user"
    exit
}

$outputPath = $saveDialog.FileName
$outputDir  = Split-Path $outputPath
$outputFile = Split-Path $outputPath -Leaf


# استخراج مسیر و نام فایل
$outputDir  = Split-Path $outputPath
$outputFile = Split-Path $outputPath -Leaf

# --- 5. ساخت فرمت دانلود (IDM-like) ---
$format = "bv*[vcodec^=avc][height<=$height]+ba[acodec^=mp4a]/b"

# --- 6. اجرای yt-dlp ---
$videoUrl = $videoUrl.Trim().Trim('"')

$ytDlpCommand = @(
    "-N", $threads,
    "-f", $format,
    "--merge-output-format", "mp4",
    "-o", "$outputDir\$outputFile",
    "--user-agent", "Mozilla/5.0",
    $videoUrl
)


Write-Host "`nStarting download..."
Write-Host "Quality: $qualityInput"
Write-Host "Threads: $threads"
Write-Host "Saving to: $outputPath`n"

& yt-dlp @ytDlpCommand
