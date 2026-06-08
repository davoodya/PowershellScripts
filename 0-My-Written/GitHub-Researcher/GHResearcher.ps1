#!/usr/bin/env pwsh
<#
.SYNOPSIS
GitHub Repository Research Tool - Search GitHub repositories with various filters and output formats

.DESCRIPTION
This script searches GitHub repositories either across all of GitHub or within a specific developer's repositories.
Supports multiple output formats including name, description, markdown, json, and url.
#>

[CmdletBinding(DefaultParameterSetName = "All")]
param(
    [Parameter(ParameterSetName = "All", Mandatory = $true)]
    [switch]$All,
    
    [Parameter(ParameterSetName = "Dev", Mandatory = $true)]
    [string]$Dev,
    
    [Parameter(Mandatory = $true)]
    [string]$Query,
    
    [Parameter()]
    [switch]$Match,
    
    [Parameter()]
    [int]$Limit,
    
    [Parameter()]
    [string]$Stars,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("name", "description", "markdown", "json", "url")]
    [string]$Output,
    
    [Parameter()]
    [string]$File,
    
    [Parameter()]
    [string]$FilePath,
    
    [Parameter()]
    [string]$Additional
)

$ErrorActionPreference = "Continue"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if GitHub CLI is installed
function Test-GitHubCLI {
    try {
        $result = gh --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "[OK] GitHub CLI is installed" "Green"
            return $true
        }
    }
    catch {
        Write-ColorOutput "[ERROR] GitHub CLI (gh) is not installed or not in PATH" "Red"
        Write-ColorOutput "Please install it from: https://cli.github.com/" "Yellow"
        return $false
    }
    return $false
}

# Function to execute gh command properly
function Invoke-GHCommand {
    param(
        [string]$SubCommand,
        [array]$Arguments
    )
    
    $argumentsList = @()
    $argumentsList += $SubCommand
    $argumentsList += $Arguments
    
    Write-ColorOutput "[DEBUG] Executing: gh $($argumentsList -join ' ')" "DarkGray"
    
    try {
        $result = & "gh" $argumentsList 2>&1
        return $result
    }
    catch {
        Write-ColorOutput "[ERROR] Failed to execute gh command: $($_.Exception.Message)" "Red"
        return $null
    }
}

# Function to process repository results based on output format
function Format-Output {
    param(
        [array]$Repositories,
        [string]$Format,
        [string]$OutputPath
    )
    
    $outputContent = ""
    
    switch ($Format) {
        "name" {
            $lines = @()
            foreach ($repo in $Repositories) {
                $repoName = if ($repo.full_name) {
                    $repo.full_name
                }
                elseif ($repo.owner -and $repo.name) {
                    if ($repo.owner.login) {
                        "$($repo.owner.login)/$($repo.name)"
                    } else {
                        "$($repo.owner)/$($repo.name)"
                    }
                }
                else {
                    $repo.name
                }
                $lines += $repoName
            }
            $outputContent = $lines -join "`n"
        }
        
        "description" {
            foreach ($repo in $Repositories) {
                $repoName = if ($repo.full_name) {
                    $repo.full_name
                }
                elseif ($repo.owner -and $repo.name) {
                    if ($repo.owner.login) {
                        "$($repo.owner.login)/$($repo.name)"
                    } else {
                        "$($repo.owner)/$($repo.name)"
                    }
                }
                else {
                    $repo.name
                }
                
                $description = if ($repo.description) { $repo.description } else { "No description provided" }
                $stars = if ($repo.stargazersCount -or $repo.stargazers_count) { 
                    if ($repo.stargazersCount) { $repo.stargazersCount } else { $repo.stargazers_count }
                } 
                else { 
                    "null" 
                }
                
                $outputContent += "Repository: $repoName`n"
                $outputContent += "Description: $description`n"
                $outputContent += "Stars: $stars`n"
                $outputContent += "---`n"
            }
        }
        
        "markdown" {
            $outputContent += "| Repository | Description | Stars | Link |`n"
            $outputContent += "|------------|-------------|-------|------|`n"
            
            foreach ($repo in $Repositories) {
                $repoName = if ($repo.full_name) {
                    $repo.full_name
                }
                elseif ($repo.owner -and $repo.name) {
                    if ($repo.owner.login) {
                        "$($repo.owner.login)/$($repo.name)"
                    } else {
                        "$($repo.owner)/$($repo.name)"
                    }
                }
                else {
                    $repo.name
                }
                
                $repoUrl = if ($repo.html_url) {
                    $repo.html_url
                }
                elseif ($repo.url) {
                    $repo.url
                }
                else {
                    "https://github.com/$repoName"
                }
                
                $description = if ($repo.description) { 
                    $repo.description -replace "\|", "\\|" -replace "`n", " " 
                } 
                else { 
                    "No description" 
                }
                
                $stars = if ($repo.stargazersCount -or $repo.stargazers_count) { 
                    if ($repo.stargazersCount) { $repo.stargazersCount } else { $repo.stargazers_count }
                } 
                else { 
                    "0" 
                }
                
                $outputContent += "| [$repoName]($repoUrl) | $description | $stars | [Link]($repoUrl) |`n"
            }
        }
        
        "json" {
            $jsonOutput = @()
            foreach ($repo in $Repositories) {
                $ownerObj = if ($repo.owner) {
                    if ($repo.owner.login) {
                        @{
                            login = $repo.owner.login
                            id = if ($repo.owner.id) { $repo.owner.id } else { $null }
                            type = if ($repo.owner.type) { $repo.owner.type } else { "User" }
                            url = if ($repo.owner.url) { $repo.owner.url } else { "https://github.com/$($repo.owner.login)" }
                        }
                    }
                    elseif ($repo.owner -is [string]) {
                        @{
                            login = $repo.owner
                            type = "User"
                            url = "https://github.com/$($repo.owner)"
                        }
                    }
                    else {
                        @{ login = $repo.owner.ToString() }
                    }
                }
                else {
                    $null
                }
                
                $repoObj = @{
                    name = if ($repo.name) { $repo.name } else { $null }
                    owner = $ownerObj
                    description = if ($repo.description) { $repo.description } else { "" }
                    stargazersCount = if ($repo.stargazersCount -or $repo.stargazers_count) { 
                        if ($repo.stargazersCount) { $repo.stargazersCount } else { $repo.stargazers_count }
                    } 
                    else { 
                        0 
                    }
                    url = if ($repo.html_url) { $repo.html_url } 
                    elseif ($repo.url) { $repo.url }
                    else { "https://github.com/$($repo.owner.login)/$($repo.name)" }
                }
                $jsonOutput += $repoObj
            }
            $outputContent = $jsonOutput | ConvertTo-Json -Depth 10
        }
        
        "url" {
            $lines = @()
            foreach ($repo in $Repositories) {
                $repoName = if ($repo.full_name) {
                    $repo.full_name
                }
                elseif ($repo.owner -and $repo.name) {
                    if ($repo.owner.login) {
                        "$($repo.owner.login)/$($repo.name)"
                    } else {
                        "$($repo.owner)/$($repo.name)"
                    }
                }
                else {
                    $repo.name
                }
                $lines += "https://github.com/$repoName.git"
            }
            $outputContent = $lines -join "`n"
        }
    }
    
    # Write output to file or console
    if ($OutputPath) {
        try {
            $directory = Split-Path $OutputPath -Parent
            if ($directory -and !(Test-Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }
            $outputContent | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-ColorOutput "[SUCCESS] Output written to: $OutputPath" "Green"
        }
        catch {
            Write-ColorOutput "[ERROR] Failed to write to file: $($_.Exception.Message)" "Red"
            Write-ColorOutput "Displaying output instead:" "Yellow"
            Write-Output $outputContent
        }
    }
    else {
        Write-Output $outputContent
    }
}

# Main script execution
try {
    Write-ColorOutput "GitHub Repository Research Tool" "Cyan"
    Write-ColorOutput ("=" * 40) "Cyan"
    
    # Check if GitHub CLI is available
    if (-not (Test-GitHubCLI)) {
        exit 1
    }
    
    # Parse query - handle comma-separated values
    $queries = $Query -split ',' | ForEach-Object { $_.Trim() }
    
    $searchMode = if ($All) { "all" } else { "dev" }
    Write-ColorOutput "[INFO] Search Mode: $searchMode" "Cyan"
    Write-ColorOutput "[INFO] Queries: $($queries -join ', ')" "Cyan"
    
    # Collect all results
    $allResults = @()
    
    foreach ($singleQuery in $queries) {
        Write-ColorOutput "[INFO] Searching for: '$singleQuery'" "Yellow"
        
        if ($All) {
            # Build arguments for gh search repos
            $ghArgs = @("search", "repos", $singleQuery)
            
            # Add JSON output format
            $ghArgs += "--json"
            $ghArgs += "name,owner,description,stargazersCount,url,html_url,full_name"
            
            # Add limit
            $limitValue = if ($Limit) { $Limit } else { 1000 }
            $ghArgs += "--limit"
            $ghArgs += $limitValue.ToString()
            
            # Add match name flag if specified
            if ($Match) {
                $ghArgs += "--match"
                $ghArgs += "name"
            }
            
            # Add stars filter if specified
            if ($Stars) {
                $ghArgs += "--stars"
                $ghArgs += $Stars
            }
            
            # Add additional flags if specified
            if ($Additional) {
                $additionalFlags = $Additional -replace '^"|"$', '' -split ' '
                $ghArgs += $additionalFlags
            }
            
            # Execute command
            $result = Invoke-GHCommand -SubCommand "search" -Arguments $ghArgs[1..$($ghArgs.Length-1)]
            
            if ($null -eq $result) {
                continue
            }
            
            # Parse JSON results
            try {
                $repos = $result | ConvertFrom-Json
                if ($repos -isnot [array]) {
                    $repos = @($repos)
                }
                
                $allResults += $repos
                Write-ColorOutput "[SUCCESS] Found $($repos.Count) repositories for query '$singleQuery'" "Green"
            }
            catch {
                Write-ColorOutput "[WARNING] Failed to parse results for '$singleQuery': $($_.Exception.Message)" "Yellow"
                if ($result) {
                    Write-ColorOutput "Raw output: $result" "DarkGray"
                }
            }
        }
        else {
            # Build arguments for gh repo list
            $ghArgs = @("repo", "list", $Dev)
            
            # Add JSON output format
            $ghArgs += "--json"
            $ghArgs += "name,owner,description,stargazersCount,url,html_url,full_name"
            
            # Add limit
            $limitValue = if ($Limit) { $Limit } else { 1000 }
            $ghArgs += "--limit"
            $ghArgs += $limitValue.ToString()
            
            # Add additional flags if specified
            if ($Additional) {
                $additionalFlags = $Additional -replace '^"|"$', '' -split ' '
                $ghArgs += $additionalFlags
            }
            
            # Execute command
            $result = Invoke-GHCommand -SubCommand "repo" -Arguments $ghArgs[1..$($ghArgs.Length-1)]
            
            if ($null -eq $result) {
                continue
            }
            
            # Parse JSON results
            try {
                $repos = $result | ConvertFrom-Json
                if ($repos -isnot [array]) {
                    $repos = @($repos)
                }
                
                # Apply client-side filtering for Match flag
                if ($Match) {
                    $repos = $repos | Where-Object { 
                        $_.name -like "*$singleQuery*" -or 
                        $_.name -ilike "*$singleQuery*"
                    }
                }
                
                # Apply stars filter
                if ($Stars) {
                    $starsValue = $Stars -replace '[<>]=?', ''
                    $starsOperator = if ($Stars -match '>=') { "ge" }
                    elseif ($Stars -match '<=') { "le" }
                    elseif ($Stars -match '>') { "gt" }
                    elseif ($Stars -match '<') { "lt" }
                    else { "eq" }
                    
                    try {
                        $starsNum = [int]$starsValue
                        $repos = $repos | Where-Object {
                            $repoStars = $_.stargazersCount
                            switch ($starsOperator) {
                                "ge" { $repoStars -ge $starsNum }
                                "le" { $repoStars -le $starsNum }
                                "gt" { $repoStars -gt $starsNum }
                                "lt" { $repoStars -lt $starsNum }
                                "eq" { $repoStars -eq $starsNum }
                                default { $true }
                            }
                        }
                    }
                    catch {
                        Write-ColorOutput "[WARNING] Invalid stars filter: $Stars" "Yellow"
                    }
                }
                
                $allResults += $repos
                Write-ColorOutput "[SUCCESS] Found $($repos.Count) repositories for developer '$Dev' with query '$singleQuery'" "Green"
            }
            catch {
                Write-ColorOutput "[WARNING] Failed to parse results for '$Dev': $($_.Exception.Message)" "Yellow"
            }
        }
    }
    
    # Remove duplicates
    if ($allResults.Count -gt 0) {
        $allResults = $allResults | Sort-Object -Property { 
            if ($_.full_name) { $_.full_name } 
            elseif ($_.owner -and $_.owner.login -and $_.name) { "$($_.owner.login)/$($_.name)" }
            elseif ($_.owner -and $_.name) { "$($_.owner)/$($_.name)" }
            else { $_.name }
        } -Unique
    }
    
    Write-ColorOutput "[INFO] Total unique repositories found: $($allResults.Count)" "Cyan"
    
    # Determine output path
    $outputPath = $null
    if ($FilePath) {
        $outputPath = $FilePath
    }
    elseif ($File) {
        $outputPath = Join-Path (Get-Location) $File
    }
    
    # Format and output results
    if ($allResults.Count -gt 0) {
        Format-Output -Repositories $allResults -Format $Output -OutputPath $outputPath
    }
    else {
        Write-ColorOutput "[WARNING] No repositories found matching the criteria" "Yellow"
        
        if ($outputPath) {
            if ($Output -eq "json") {
                "[]" | Out-File -FilePath $outputPath -Encoding UTF8
            }
            elseif ($Output -eq "markdown") {
                "| Repository | Description | Stars | Link |`n|------------|-------------|-------|------|`n*No results found*" | Out-File -FilePath $outputPath -Encoding UTF8
            }
            else {
                "No results found" | Out-File -FilePath $outputPath -Encoding UTF8
            }
            Write-ColorOutput "[INFO] Empty results written to: $outputPath" "Yellow"
        }
    }
    
    Write-ColorOutput ("=" * 40) "Cyan"
    Write-ColorOutput "[COMPLETE] Script execution finished" "Green"
}
catch {
    Write-ColorOutput "[FATAL ERROR] $($_.Exception.Message)" "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "DarkRed"
    exit 1
}