# ================================================================
# NppCLI Module v3.0.0 - Comprehensive Test Suite
# ================================================================
# Tests module import, parameter binding, extension parsing,
# wildcard detection, file creation, first/last, cross-platform
# path handling, editor resolver, config system, and directory
# scanning - all WITHOUT launching any editor.
# ================================================================
# Run with:
#   pwsh -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File test_syntax.ps1
# ================================================================

param(
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"
$passCount = 0
$failCount = 0
$testNumber = 0

function Assert-True {
    param([string]$Name, [bool]$Condition)
    $script:testNumber++
    if ($Condition) {
        Write-Host "  PASS [$script:testNumber]: $Name" -ForegroundColor Green
        $script:passCount++
    }
    else {
        Write-Host "  FAIL [$script:testNumber]: $Name" -ForegroundColor Red
        $script:failCount++
    }
}

# ================================================================
Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host " NppCLI Module v3.0.0 - Test Suite" -ForegroundColor Cyan
Write-Host "=====================================================`n" -ForegroundColor Cyan

# ================================================================
# GROUP 1: Module Import
# ================================================================
Write-Host "--- GROUP 1: Module Import ---" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\NppCLI.psd1" -Force -ErrorAction Stop
    Assert-True "Module imported successfully" $true
}
catch {
    Assert-True "Module imported successfully (ERROR: $_)" $false
    Write-Host "`nCRITICAL: Cannot continue tests without module." -ForegroundColor Red
    exit 1
}

$cmd = Get-Command npp -ErrorAction SilentlyContinue
Assert-True "Function 'npp' is available" ($null -ne $cmd)

# ================================================================
# GROUP 2: Parameter Types & Binding
# ================================================================
Write-Host "`n--- GROUP 2: Parameter Types & Binding ---" -ForegroundColor Yellow

$cmdInfo = Get-Command npp

# Switches must be SwitchParameter
foreach ($paramName in @('d', 'r', 'IncludeHidden')) {
    $pType = $cmdInfo.Parameters[$paramName].ParameterType
    Assert-True "-$paramName is [SwitchParameter]" ($pType -eq [System.Management.Automation.SwitchParameter])
}

# -e must be [string[]] (array, not string)
$eType = $cmdInfo.Parameters['e'].ParameterType
Assert-True "-e is [String[]]" ($eType -eq [string[]])

# Int parameters
foreach ($paramName in @('l', 'ct', 'first', 'last')) {
    $pType = $cmdInfo.Parameters[$paramName].ParameterType
    Assert-True "-$paramName is [Int32]" ($pType -eq [int])
}

# -x must be [string[]]
$xType = $cmdInfo.Parameters['x'].ParameterType
Assert-True "-x is [String[]]" ($xType -eq [string[]])

# Paths must be string array
Assert-True "-Paths is [String[]]" ($cmdInfo.Parameters['Paths'].ParameterType -eq [string[]])

# ================================================================
# GROUP 3: Short + Long Flag Aliases
# ================================================================
Write-Host "`n--- GROUP 3: Short + Long Flag Aliases ---" -ForegroundColor Yellow

# -d has alias 'directory'
$dAliases = $cmdInfo.Parameters['d'].Aliases
Assert-True "-d has alias 'directory'" ($dAliases -contains 'directory')

# -r has alias 'recursive'
$rAliases = $cmdInfo.Parameters['r'].Aliases
Assert-True "-r has alias 'recursive'" ($rAliases -contains 'recursive')

# -IncludeHidden has aliases 'a' and 'hidden'
$hiddenAliases = $cmdInfo.Parameters['IncludeHidden'].Aliases
Assert-True "-IncludeHidden has alias 'a'" ($hiddenAliases -contains 'a')
Assert-True "-IncludeHidden has alias 'hidden'" ($hiddenAliases -contains 'hidden')

# -e has aliases 'extension' and 'ext'
$eAliases = $cmdInfo.Parameters['e'].Aliases
Assert-True "-e has alias 'extension'" ($eAliases -contains 'extension')
Assert-True "-e has alias 'ext'" ($eAliases -contains 'ext')

# -l has alias 'limit'
$lAliases = $cmdInfo.Parameters['l'].Aliases
Assert-True "-l has alias 'limit'" ($lAliases -contains 'limit')

# -ct has alias 'confirmThreshold'
$ctAliases = $cmdInfo.Parameters['ct'].Aliases
Assert-True "-ct has alias 'confirmThreshold'" ($ctAliases -contains 'confirmThreshold')

# -x has alias 'exe'
$xAliases = $cmdInfo.Parameters['x'].Aliases
Assert-True "-x has alias 'exe'" ($xAliases -contains 'exe')

# ================================================================
# GROUP 4: CmdletBinding Attributes
# ================================================================
Write-Host "`n--- GROUP 4: CmdletBinding Attributes ---" -ForegroundColor Yellow

$cmdletBinding = $cmdInfo.ScriptBlock.Attributes |
    Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
Assert-True "PositionalBinding = false" ($cmdletBinding -and ($cmdletBinding.PositionalBinding -eq $false))

$pathsParam = $cmdInfo.Parameters['Paths']
$paramAttr = $pathsParam.Attributes |
    Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
Assert-True "Paths has ValueFromRemainingArguments" ($paramAttr.ValueFromRemainingArguments -eq $true)

# ================================================================
# GROUP 5: Wildcard Detection Regex
# ================================================================
Write-Host "`n--- GROUP 5: Wildcard Detection Regex ---" -ForegroundColor Yellow

$wildcards = @("*.txt", "file?.txt", "test[1-5].txt", "[abc].log", "new*", "sub\*.py")
$literals  = @("file.txt", "README.md", "folder/file.txt", "C:\temp\test.log", "my-dir")

foreach ($p in $wildcards) {
    Assert-True "'$p' detected as wildcard" ($p -match '[\*\?\[\]]')
}
foreach ($p in $literals) {
    Assert-True "'$p' detected as literal" (-not ($p -match '[\*\?\[\]]'))
}

# ================================================================
# GROUP 6: Extension Filter Parsing (CRITICAL - previously broken)
# ================================================================
Write-Host "`n--- GROUP 6: Extension Filter Parsing ---" -ForegroundColor Yellow

# Load the private module function directly for testing
. "$PSScriptRoot\Private\FileResolver.ps1"

# Single extension
$e1 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('php'))
Assert-True "'php' -> @('php')" (($e1.Count -eq 1) -and ($e1[0] -eq 'php'))

# Comma-separated string
$e2 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('php,txt'))
Assert-True "'php,txt' -> @('php','txt')" (($e2.Count -eq 2) -and ($e2 -contains 'php') -and ($e2 -contains 'txt'))

# With dots
$e3 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('.php,.txt'))
Assert-True "'.php,.txt' -> @('php','txt')" (($e3.Count -eq 2) -and ($e3 -contains 'php') -and ($e3 -contains 'txt'))

# With spaces
$e4 = @(ConvertTo-NormalizedExtensionList -RawExtensions @(' .csv , txt , .json '))
Assert-True "' .csv , txt , .json ' -> @('csv','txt','json')" (
    ($e4.Count -eq 3) -and ($e4 -contains 'csv') -and ($e4 -contains 'txt') -and ($e4 -contains 'json')
)

# Uppercase
$e5 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('PHP'))
Assert-True "'PHP' -> @('php') (lowercased)" (($e5.Count -eq 1) -and ($e5[0] -eq 'php'))

# Multiple array entries (simulates -e php -e txt)
$e6 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('php', 'txt'))
Assert-True "array @('php','txt') -> @('php','txt')" (($e6.Count -eq 2) -and ($e6 -contains 'php') -and ($e6 -contains 'txt'))

# Mixed array with commas (simulates -e php,txt -e css)
$e7 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('php,txt', 'css'))
Assert-True "array @('php,txt','css') -> @('php','txt','css')" (
    ($e7.Count -eq 3) -and ($e7 -contains 'php') -and ($e7 -contains 'txt') -and ($e7 -contains 'css')
)

# Deduplication
$e8 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('php,txt,php'))
Assert-True "'php,txt,php' -> @('php','txt') (deduplicated)" (($e8.Count -eq 2))

# Empty input
$e9 = @(ConvertTo-NormalizedExtensionList -RawExtensions @(''))
Assert-True "empty string -> @() (empty)" ($e9.Count -eq 0)

# ================================================================
# GROUP 7: Extension Matching
# ================================================================
Write-Host "`n--- GROUP 7: Extension Matching ---" -ForegroundColor Yellow

Assert-True "file.py matches ext [py,txt]"    (Test-ExtensionMatch -FileName "file.py" -ExtensionList @("py","txt"))
Assert-True "file.txt matches ext [py,txt]"   (Test-ExtensionMatch -FileName "file.txt" -ExtensionList @("py","txt"))
Assert-True "file.csv does NOT match [py,txt]" (-not (Test-ExtensionMatch -FileName "file.csv" -ExtensionList @("py","txt")))
Assert-True "FILE.PY matches ext [py]"         (Test-ExtensionMatch -FileName "FILE.PY" -ExtensionList @("py"))
Assert-True "doc.PDF matches ext [pdf]"        (Test-ExtensionMatch -FileName "doc.PDF" -ExtensionList @("pdf"))

# ================================================================
# GROUP 8: File Creation Logic
# ================================================================
Write-Host "`n--- GROUP 8: File Creation Logic ---" -ForegroundColor Yellow

$testDir  = Join-Path $PSScriptRoot "_npp_test_temp"
$testFile = Join-Path (Join-Path $testDir "subdir") "testfile.tmp"

# Clean up if left over
if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }

# Test parent directory creation + file creation
$parent = Split-Path $testFile -Parent
if (-not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
New-Item -ItemType File -Path $testFile -Force | Out-Null

Assert-True "Parent directory created" (Test-Path $parent)
Assert-True "File created at nested path" (Test-Path $testFile)
Assert-True "Resolve-Path works on created file" ($null -ne (Resolve-Path $testFile -ErrorAction SilentlyContinue))

if (-not $SkipCleanup) {
    Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
}

# ================================================================
# GROUP 9: --first / --last Selection Logic
# ================================================================
Write-Host "`n--- GROUP 9: --first / --last Selection Logic ---" -ForegroundColor Yellow

$testSet = @("alpha.txt", "bravo.txt", "charlie.txt", "delta.txt", "echo.txt")

$firstResult = @($testSet | Select-Object -First 2)
Assert-True "--first 2 selects 2 items" ($firstResult.Count -eq 2)
Assert-True "--first 2 selects alpha,bravo" (($firstResult[0] -eq "alpha.txt") -and ($firstResult[1] -eq "bravo.txt"))

$lastResult = @($testSet | Select-Object -Last 3)
Assert-True "--last 3 selects 3 items" ($lastResult.Count -eq 3)
Assert-True "--last 3 selects charlie,delta,echo" (
    ($lastResult[0] -eq "charlie.txt") -and ($lastResult[2] -eq "echo.txt")
)

$overResult = @($testSet | Select-Object -First 999)
Assert-True "--first 999 returns all 5" ($overResult.Count -eq 5)

# ================================================================
# GROUP 10: Cross-Platform Path Handling
# ================================================================
Write-Host "`n--- GROUP 10: Cross-Platform Path Handling ---" -ForegroundColor Yellow

# PS 5.1 Join-Path only accepts 2 arguments - always chain for compatibility
$joinResult = Join-Path (Join-Path "folder" "subfolder") "file.txt"
Assert-True "Join-Path produces valid path" ($joinResult -match 'folder.*subfolder.*file\.txt')

# Verify no hard-coded backslashes in the module source
$moduleSource = Get-Content (Join-Path $PSScriptRoot "NppCLI.psm1") -Raw
$hardCodedNppPath = $moduleSource -match 'C:\\Program Files\\Notepad\+\+\\notepad\+\+\.exe'
Assert-True "No hard-coded Npp path in main module" (-not $hardCodedNppPath)

# Verify private modules use Join-Path
$configSource = Get-Content (Join-Path (Join-Path $PSScriptRoot "Private") "Config.ps1") -Raw
Assert-True "Config.ps1 uses Join-Path" ($configSource -match 'Join-Path')

$editorSource = Get-Content (Join-Path (Join-Path $PSScriptRoot "Private") "EditorResolver.ps1") -Raw
Assert-True "EditorResolver.ps1 uses Join-Path" ($editorSource -match 'Join-Path')

# ================================================================
# GROUP 11: Config System
# ================================================================
Write-Host "`n--- GROUP 11: Config System ---" -ForegroundColor Yellow

# Load config functions
. "$PSScriptRoot\Private\Config.ps1"

# Test config dir path generation
$configDir = Get-NppCLIConfigDir
Assert-True "Config dir path contains .nppcli" ($configDir -match '\.nppcli')

$configPath = Get-NppCLIConfigPath
Assert-True "Config path ends with config.json" ($configPath -match 'config\.json$')

# Test save and load (use a temp test key to not pollute real config)
$origConfig = Get-NppCLIConfig
$testConfig = @{ 'TestKey' = 'TestValue123'; 'EditorPath' = 'C:\test\fake.exe' }
Save-NppCLIConfig -Config $testConfig

$loaded = Get-NppCLIConfig
Assert-True "Config round-trip: TestKey saved and loaded" ($loaded['TestKey'] -eq 'TestValue123')
Assert-True "Config round-trip: EditorPath saved and loaded" ($loaded['EditorPath'] -eq 'C:\test\fake.exe')

# Restore original config
if ($origConfig.Count -gt 0) {
    Save-NppCLIConfig -Config $origConfig
}
else {
    # Remove test config
    $cp = Get-NppCLIConfigPath
    if (Test-Path $cp) { Remove-Item $cp -Force -ErrorAction SilentlyContinue }
}

# ================================================================
# GROUP 12: Editor Resolver Functions Exist
# ================================================================
Write-Host "`n--- GROUP 12: Editor Resolver ---" -ForegroundColor Yellow

# Load editor resolver
. "$PSScriptRoot\Private\EditorResolver.ps1"

# Verify functions exist
Assert-True "Show-EditorFileDialog function exists" ($null -ne (Get-Command Show-EditorFileDialog -ErrorAction SilentlyContinue))
Assert-True "Find-NotepadPlusPlus function exists" ($null -ne (Get-Command Find-NotepadPlusPlus -ErrorAction SilentlyContinue))
Assert-True "Find-CommonEditor function exists" ($null -ne (Get-Command Find-CommonEditor -ErrorAction SilentlyContinue))
Assert-True "Resolve-EditorExecutable function exists" ($null -ne (Get-Command Resolve-EditorExecutable -ErrorAction SilentlyContinue))

# Test Find-NotepadPlusPlus (may or may not find it, but should not error)
$nppResult = $null
try {
    $nppResult = Find-NotepadPlusPlus
    Assert-True "Find-NotepadPlusPlus runs without error" $true
}
catch {
    Assert-True "Find-NotepadPlusPlus runs without error (ERROR: $_)" $false
}

# ================================================================
# GROUP 13: File Resolver Functions
# ================================================================
Write-Host "`n--- GROUP 13: File Resolver ---" -ForegroundColor Yellow

Assert-True "Test-IsWildcard function exists" ($null -ne (Get-Command Test-IsWildcard -ErrorAction SilentlyContinue))
Assert-True "ConvertTo-NormalizedExtensionList function exists" ($null -ne (Get-Command ConvertTo-NormalizedExtensionList -ErrorAction SilentlyContinue))
Assert-True "Test-ExtensionMatch function exists" ($null -ne (Get-Command Test-ExtensionMatch -ErrorAction SilentlyContinue))
Assert-True "Resolve-InputPaths function exists" ($null -ne (Get-Command Resolve-InputPaths -ErrorAction SilentlyContinue))
Assert-True "Invoke-DirectoryScan function exists" ($null -ne (Get-Command Invoke-DirectoryScan -ErrorAction SilentlyContinue))
Assert-True "Invoke-WildcardExpansion function exists" ($null -ne (Get-Command Invoke-WildcardExpansion -ErrorAction SilentlyContinue))

# Test-IsWildcard
Assert-True "Test-IsWildcard '*.txt' -> true" (Test-IsWildcard -Path '*.txt')
Assert-True "Test-IsWildcard 'file.txt' -> false" (-not (Test-IsWildcard -Path 'file.txt'))
Assert-True "Test-IsWildcard 'test[1-5].log' -> true" (Test-IsWildcard -Path 'test[1-5].log')

# ================================================================
# GROUP 14: Directory Scan + Filter Simulation
# ================================================================
Write-Host "`n--- GROUP 14: Directory Scan + Filter Simulation ---" -ForegroundColor Yellow

$scanDir = Join-Path $PSScriptRoot "_npp_scan_test"
if (Test-Path $scanDir) { Remove-Item $scanDir -Recurse -Force }
New-Item -ItemType Directory -Path $scanDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $scanDir "sub") -Force | Out-Null

# Create test files
@("a.txt", "b.txt", "c.py", "d.csv", "readme.md") | ForEach-Object {
    New-Item -ItemType File -Path (Join-Path $scanDir $_) -Force | Out-Null
}
@("deep1.txt", "deep2.py") | ForEach-Object {
    New-Item -ItemType File -Path (Join-Path (Join-Path $scanDir "sub") $_) -Force | Out-Null
}

# Non-recursive scan
$topFiles = @(Get-ChildItem -Path $scanDir -File)
Assert-True "Top-level scan finds 5 files" ($topFiles.Count -eq 5)

# Recursive scan
$allFiles = @(Get-ChildItem -Path $scanDir -File -Recurse)
Assert-True "Recursive scan finds 7 files" ($allFiles.Count -eq 7)

# Wildcard pattern filter
$txtOnly = @($allFiles | Where-Object { $_.Name -like "*.txt" })
Assert-True "*.txt filter finds 3 files (a.txt, b.txt, deep1.txt)" ($txtOnly.Count -eq 3)

# Extension filter
$pyOnly = @($allFiles | Where-Object { $_.Extension.TrimStart('.').ToLower() -eq "py" })
Assert-True "-e py filter finds 2 files (c.py, deep2.py)" ($pyOnly.Count -eq 2)

# Combined extension filter
$csvTxt = @($allFiles | Where-Object {
    $fe = $_.Extension.TrimStart('.').ToLower()
    @("csv","txt") -contains $fe
})
Assert-True "-e csv,txt finds 4 files" ($csvTxt.Count -eq 4)

# Test Invoke-DirectoryScan directly
$scanResult1 = Invoke-DirectoryScan -Directories @($scanDir) -Patterns @() -ExtensionList @() -Recursive
Assert-True "Invoke-DirectoryScan recursive finds 7 files" ($scanResult1.Count -eq 7)

$scanResult2 = Invoke-DirectoryScan -Directories @($scanDir) -Patterns @('*.txt') -ExtensionList @() -Recursive
Assert-True "Invoke-DirectoryScan recursive *.txt finds 3 files" ($scanResult2.Count -eq 3)

$scanResult3 = Invoke-DirectoryScan -Directories @($scanDir) -Patterns @() -ExtensionList @('py') -Recursive
Assert-True "Invoke-DirectoryScan recursive -e py finds 2 files" ($scanResult3.Count -eq 2)

$scanResult4 = Invoke-DirectoryScan -Directories @($scanDir) -Patterns @() -ExtensionList @('csv','txt')
Assert-True "Invoke-DirectoryScan non-recursive -e csv,txt finds 3 files" ($scanResult4.Count -eq 3)

if (-not $SkipCleanup) {
    Remove-Item $scanDir -Recurse -Force -ErrorAction SilentlyContinue
}

# ================================================================
# GROUP 15: Input Path Classification
# ================================================================
Write-Host "`n--- GROUP 15: Input Path Classification ---" -ForegroundColor Yellow

# Test classification in directory mode with a real dir
$classTestDir = Join-Path $PSScriptRoot "_npp_class_test"
if (Test-Path $classTestDir) { Remove-Item $classTestDir -Recurse -Force }
New-Item -ItemType Directory -Path $classTestDir -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $classTestDir "test.txt") -Force | Out-Null

# Directory mode: existing dir -> Directories, wildcard -> Patterns
$classified = Resolve-InputPaths -Paths @($classTestDir, "*.php") -DirectoryMode
Assert-True "Dir mode: existing dir classified as Directory" ($classified['Directories'].Count -ge 1)
Assert-True "Dir mode: *.php classified as Pattern" ($classified['Patterns'].Count -ge 1)

# File mode: existing file -> ResolvedFiles, wildcard -> Patterns
$existingFile = Join-Path $classTestDir "test.txt"
$classified2 = Resolve-InputPaths -Paths @($existingFile, "*.php")
Assert-True "File mode: existing file classified as ResolvedFile" ($classified2['ResolvedFiles'].Count -ge 1)
Assert-True "File mode: *.php classified as Pattern" ($classified2['Patterns'].Count -ge 1)

if (-not $SkipCleanup) {
    Remove-Item $classTestDir -Recurse -Force -ErrorAction SilentlyContinue
}

# ================================================================
# GROUP 16: Module Manifest Validation
# ================================================================
Write-Host "`n--- GROUP 16: Module Manifest Validation ---" -ForegroundColor Yellow

try {
    $manifest = Test-ModuleManifest -Path (Join-Path $PSScriptRoot "NppCLI.psd1") -ErrorAction Stop
    Assert-True "Manifest is valid" $true
    Assert-True "Version is 3.0.0" ($manifest.Version.ToString() -eq "3.0.0")
    Assert-True "Exports 'npp' function" ($manifest.ExportedFunctions.Keys -contains 'npp')
    Assert-True "Author is Davood Yahya" ($manifest.Author -like "*Davood*Yahya*")
    Assert-True "PowerShellVersion is 5.1" ($manifest.PowerShellVersion.ToString() -eq "5.1")

    $tags = $manifest.PrivateData.PSData.Tags
    Assert-True "Tags include NppCLI" ($tags -contains 'NppCLI')
    Assert-True "Tags include VSCode" ($tags -contains 'VSCode')
    Assert-True "Tags include CrossPlatform" ($tags -contains 'CrossPlatform')
    Assert-True "ProjectUri is set" ($manifest.PrivateData.PSData.ProjectUri -ne '')
    Assert-True "LicenseUri is set" ($manifest.PrivateData.PSData.LicenseUri -ne '')
}
catch {
    Assert-True "Manifest is valid (ERROR: $_)" $false
}

# ================================================================
# GROUP 17: Private Module Files Exist
# ================================================================
Write-Host "`n--- GROUP 17: Private Module Files ---" -ForegroundColor Yellow

$privateDir = Join-Path $PSScriptRoot "Private"
Assert-True "Private directory exists" (Test-Path $privateDir -PathType Container)
Assert-True "Config.ps1 exists" (Test-Path (Join-Path $privateDir "Config.ps1"))
Assert-True "EditorResolver.ps1 exists" (Test-Path (Join-Path $privateDir "EditorResolver.ps1"))
Assert-True "FileResolver.ps1 exists" (Test-Path (Join-Path $privateDir "FileResolver.ps1"))

# ================================================================
# GROUP 18: ASCII-Only Compliance
# ================================================================
Write-Host "`n--- GROUP 18: ASCII-Only Compliance ---" -ForegroundColor Yellow

$filesToCheck = @(
    (Join-Path $PSScriptRoot "NppCLI.psm1"),
    (Join-Path $PSScriptRoot "NppCLI.psd1"),
    (Join-Path $privateDir "Config.ps1"),
    (Join-Path $privateDir "EditorResolver.ps1"),
    (Join-Path $privateDir "FileResolver.ps1"),
    (Join-Path $privateDir "HelpSystem.ps1")
)

foreach ($file in $filesToCheck) {
    $fileName = Split-Path $file -Leaf
    $bytes = [System.IO.File]::ReadAllBytes($file)
    # Check for any byte > 127 (non-ASCII) - skip BOM bytes (EF BB BF)
    $hasNonAscii = $false
    $skipBom = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $skipBom = 3
    }
    for ($i = $skipBom; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -gt 127) {
            $hasNonAscii = $true
            break
        }
    }
    Assert-True "$fileName is ASCII-only (PS 5.1 safe)" (-not $hasNonAscii)
}

# ================================================================
# GROUP 19: Edge Cases - Extension Parameter
# ================================================================
Write-Host "`n--- GROUP 19: Edge Cases - Extension Parameter ---" -ForegroundColor Yellow

# Empty array
$ee1 = @(ConvertTo-NormalizedExtensionList -RawExtensions @())
Assert-True "Empty array -> empty result" ($ee1.Count -eq 0)

# Single dot only
$ee2 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('.'))
Assert-True "Single dot '.' -> empty result" ($ee2.Count -eq 0)

# Multiple commas only
$ee3 = @(ConvertTo-NormalizedExtensionList -RawExtensions @(',,,'))
Assert-True "',,,' -> empty result" ($ee3.Count -eq 0)

# Mixed valid and empty
$ee4 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('php,,txt,'))
Assert-True "'php,,txt,' -> @('php','txt')" (($ee4.Count -eq 2) -and ($ee4 -contains 'php') -and ($ee4 -contains 'txt'))

# Extension with multiple dots (edge case)
$ee5 = @(ConvertTo-NormalizedExtensionList -RawExtensions @('..php'))
Assert-True "'..php' -> @('php') (dots stripped)" (($ee5.Count -eq 1) -and ($ee5[0] -eq 'php'))

# ================================================================
# GROUP 20: Help System
# ================================================================
Write-Host "`n--- GROUP 20: Help System ---" -ForegroundColor Yellow

# Verify HelpSystem.ps1 exists
$helpSystemPath = Join-Path $privateDir "HelpSystem.ps1"
Assert-True "HelpSystem.ps1 exists" (Test-Path $helpSystemPath)

# Verify help functions are defined in HelpSystem.ps1 (they are private/module-scoped)
$helpContent = Get-Content $helpSystemPath -Raw
Assert-True "Show-NppHelpSummary defined in HelpSystem.ps1" ($helpContent -match 'function\s+Show-NppHelpSummary')
Assert-True "Show-NppHelpComprehensive defined in HelpSystem.ps1" ($helpContent -match 'function\s+Show-NppHelpComprehensive')
Assert-True "Show-NppHelpExamples defined in HelpSystem.ps1" ($helpContent -match 'function\s+Show-NppHelpExamples')
Assert-True "Show-NppHelp defined in HelpSystem.ps1" ($helpContent -match 'function\s+Show-NppHelp\b')

# Verify npp function has help parameters
$nppParams = (Get-Command npp).Parameters
Assert-True "npp has -h parameter" ($nppParams.ContainsKey('h'))
Assert-True "npp -h has alias 'help'" ($nppParams['h'].Aliases -contains 'help')
Assert-True "npp has -HelpSummary parameter" ($nppParams.ContainsKey('HelpSummary'))
Assert-True "npp has -Examples parameter" ($nppParams.ContainsKey('Examples'))

# Verify help parameters are SwitchParameter type
Assert-True "-h is [SwitchParameter]" ($nppParams['h'].ParameterType.Name -eq 'SwitchParameter')
Assert-True "-HelpSummary is [SwitchParameter]" ($nppParams['HelpSummary'].ParameterType.Name -eq 'SwitchParameter')
Assert-True "-Examples is [SwitchParameter]" ($nppParams['Examples'].ParameterType.Name -eq 'SwitchParameter')

# ================================================================
# SUMMARY
# ================================================================
Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host " TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Total : $($passCount + $failCount)" -ForegroundColor White
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "=====================================================`n" -ForegroundColor Cyan

if ($failCount -gt 0) {
    Write-Host "Some tests FAILED. Review output above." -ForegroundColor Red
}
else {
    Write-Host "All tests PASSED!" -ForegroundColor Green
}
