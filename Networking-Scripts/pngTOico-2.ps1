# Take a PNG or JPEG file path as input
$filePath = Read-Host "Enter the path of the PNG or JPEG file"

# Convert the file to an ICO file using ImageMagick
& magick $filePath -background transparent -alpha remove -depth 8 -type
truecolor ico:$filePath.ico

# Save the output in the same directory as the input file
Move-Item $filePath.ico "$($filePath.Replace('.png', '.ico'))"