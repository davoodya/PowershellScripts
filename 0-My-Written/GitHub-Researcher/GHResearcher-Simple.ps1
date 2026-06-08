function Get-GitHubRepos {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("search", "user")]
        [string]$Mode = "search",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("fullname", "detailed", "url")]
        [string]$OutputFormat = "fullname",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("txt", "md", "json")]
        [string]$FileFormat = "txt",
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile = "",
        
        [Parameter(Mandatory=$false)]
        [int]$Limit = 100
    )
    
    if ($Mode -eq "search") {
        $jsonFields = @("nameWithOwner")
        $jqFilter = '.[].nameWithOwner'
        
        switch ($OutputFormat) {
            "fullname" { 
                $jsonFields = @("nameWithOwner")
                $jqFilter = '.[].nameWithOwner'
            }
            "detailed" { 
                $jsonFields = @("nameWithOwner", "description", "stargazerCount", "url")
                if ($FileFormat -eq "md") {
                    $jqFilter = '"| Repository | Description | Stars |\n|--------|-------------|-------|\n" + (.[] | "| [\(.nameWithOwner)](\(.url)) | \(.description // \"No description\") | \(.stargazerCount) |")'
                } else {
                    $jqFilter = '.[] | "Repository: \(.nameWithOwner)\nDescription: \(.description // "No description")\nStars: \(.stargazerCount)\n---"'
                }
            }
            "url" { 
                $jsonFields = @("url")
                $jqFilter = '.[].url'
            }
        }
        
        $command = "gh search repos `"$Query`" --limit $Limit --json $($jsonFields -join ',') --jq `"$jqFilter`""
    }
    else {
        # Mode "user"
        switch ($OutputFormat) {
            "fullname" { 
                $command = "gh repo list $Query --limit $Limit --json nameWithOwner --jq '.[].nameWithOwner'"
            }
            "detailed" { 
                if ($FileFormat -eq "md") {
                    $command = "gh repo list $Query --limit $Limit --json nameWithOwner,description,stargazerCount,url --jq `"'| Repository | Description | Stars |\n|--------|-------------|-------|\n' + (.[] | '| [\(.nameWithOwner)](\(.url)) | \(.description // \"No description\") | \(.stargazerCount) |')`""
                } else {
                    $command = "gh repo list $Query --limit $Limit --json nameWithOwner,description,stargazerCount --jq '.[] | `"Repository: \(.nameWithOwner)\nDescription: \(.description // \"No description\")\nStars: \(.stargazerCount)\n---`"'"
                }
            }
            "url" { 
                $command = "gh repo list $Query --limit $Limit --json url --jq '.[].url'"
            }
        }
    }
    
    Write-Host "Executing: $command" -ForegroundColor Cyan
    
    if ($OutputFile) {
        Invoke-Expression $command | Out-File -FilePath $OutputFile -Encoding utf8
        Write-Host "Output saved to: $OutputFile" -ForegroundColor Green
    } else {
        Invoke-Expression $command
    }
}