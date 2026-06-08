# Set the output directory
$outputDir = "C:\ConvertedICOs"

# Get the input file path from the user
$inputFilePrompt = "Enter the path of the PNG or JPEG file: "
$inputFilePath = Read-Host -Prompt $inputFilePrompt

# Check if the input file exists
if (!(Test-Path -Path $inputFilePath)) {
    Write-Host "The file does not exist." -ForegroundColor Red
    exit 1
}

# Get the input file extension
$inputExt = [System.IO.Path]::GetExtension($inputFilePath)

# Convert the input file to ICO
if ($inputExt -eq ".png" -or $inputExt -eq ".jpg") {
    $icoFile = [IO.Path]::Combine($outputDir, [IO.Path]::GetFileNameWithoutExtension($inputFilePath) + ".ico")
    [System.Drawing.Image]::Fromfile([System.IO.FileStream]::OpenRead($inputFilePath, [System.IO.FileMode]::Open),
[System.Drawing.Imaging.ImageFormat]::Png).Save($icoFile, [System.Drawing.Imaging.ImageFormat]::Icon)
} else {
    Write-Host "Only PNG and JPEG files are supported." -ForegroundColor Red
    exit 1
}

# Output the path of the converted ICO file
Write-Host "The converted ICO file is located at: $icoFile" -ForegroundColor Green