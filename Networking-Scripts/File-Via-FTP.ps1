# Prompt the user for details
$ip = Read-Host "Please enter the destination IP address"
$port = Read-Host "Please enter the FTP port"
$username = Read-Host "Please enter the username"
$password = Read-Host "Please enter the password"
$filePath = Read-Host "Please enter the full path of the file to send"

# Create the FTP URL
$ftpUrl = "ftp://$ip:$port/" + [IO.Path]::GetFileName($filePath)

# Create WebClient instance
$webClient = New-Object System.Net.WebClient

# Set credentials
$webClient.Credentials = New-Object System.Net.NetworkCredential($username, $password)

try {
    # Upload the file
    $webClient.UploadFile($ftpUrl, "STOR", $filePath)
    Write-Host "File uploaded successfully to $ftpUrl"
} catch {
    Write-Host "An error occurred: $_"
} finally {
    $webClient.Dispose()
}

#Explanation:
#1. User Input: The script starts by collecting the destination IP, FTP port, username, password, and the path of the file to send from the user.
#2. FTP URL Construction: Constructs the FTP URL using the provided IP and port. It appends the filename extracted from the provided file path to the URL.
#3. WebClient Setup: Initializes a System.Net.WebClient instance and sets the credentials for FTP access.
#4. File Upload: Attempts to upload the file using the UploadFile method, which takes the FTP URL, the command "STOR" indicating the file is to be stored, and the local file path.
#5. Error Handling: Catches and displays any errors that occur during the upload process.
#6. Cleanup: Disposes of the WebClient instance after the operation is complete.
#This script requires that the FTP server is configured to accept connections on the specified port and that it supports passive mode FTP, as WebClient uses passive mode by default. Make sure to run this script in an environment where outbound FTP connections are allowed by firewalls and other security settings.