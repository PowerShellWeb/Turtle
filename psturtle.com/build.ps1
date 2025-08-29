<#
.SYNOPSIS
    Builds the website.
.DESCRIPTION
    Builds a static site using PowerShell.

    * The site will be configured using any `config.*` files.
    * Functions and filters will be loaded from any `functions.*` or `filters.*` files.
    * All files will be processed using `buildFile.ps1` (any `*.*.ps1` file should be run).
.EXAMPLE
    ./build.ps1
#>
param(
[string[]]
$FilePath,

[string]
$Root = $PSScriptRoot
)

# Push into the script root directory
if ($PSScriptRoot) { Push-Location $PSScriptRoot }

# Creation of a sitewide object to hold configuration information.
$Site = [Ordered]@{}
$Site.Files = 
    if ($filePath) { Get-ChildItem -Recurse -File -Path $FilePath } 
    else { Get-ChildItem -Recurse -File }

$Site.PSScriptRoot = "$PSScriptRoot"

#region Common Functions and Filters
$functionFileNames = 'functions', 'function', 'filters', 'filter'
$functionPattern   = "(?>$($functionFileNames -join '|'))\.ps1$"
$functionFiles     = Get-ChildItem -Path $Site.PSScriptRoot |
    Where-Object Name -Match $functionPattern

foreach ($file in $functionFiles) {
    # If we have a file with the name function or functions, we'll use it to set the site configuration.
    . $file.FullName
}
#endregion Common Functions and Filters

# Set an alias to buildPage.ps1
Set-Alias BuildPage ./buildPage.ps1

# If we have an event path,
$gitHubEvent =
    if ($env:GITHUB_EVENT_PATH) {
        # all we need to do to serve it is copy it.
        Copy-Item $env:GITHUB_EVENT_PATH .\gitHubEvent.json

        # and we can assign it to a variable, so you we can use it in any files we build.
        Get-Content -Path .\gitHubEvent.json -Raw | ConvertFrom-Json
    }

# If we have a CNAME, read it, trim it, and update the site object.
if (Test-Path 'CNAME') {
    $Site.CNAME = $CNAME = (Get-Content -Path 'CNAME' -Raw).Trim()
    $Site.RootUrl = "https://$CNAME/"
} elseif (
    ($site.PSScriptRoot | Split-Path -Leaf) -like '*.*'
) {
    $site.CNAME = $CNAME = ($site.PSScriptRoot | Split-Path -Leaf)
    $site.RootUrl = "https://$CNAME/"
}

# If we have a config.json file, it can be used to set the site configuration.
if (Test-Path 'config.json') {
    $siteConfig = Get-Content -Path 'config.json' -Raw | ConvertFrom-Json
    foreach ($property in $siteConfig.psobject.properties) {
        $Site[$property.Name] = $property.Value
    }
}

# If we have a config.psd1 file, we'll use it to set the site configuration.
if (Test-Path 'config.psd1') {
    $siteConfig = Import-LocalizedData -FileName 'config.psd1' -BaseDirectory $PSScriptRoot
    foreach ($property in $siteConfig.GetEnumerator()) {
        $Site[$property.Key] = $property.Value
    }
}

# If we have a config yaml, things 
if (Test-Path 'config.yaml') {
    $siteConfig = Get-Item 'config.yaml' | from_yaml
    foreach ($property in $siteConfig.GetEnumerator()) {
        $Site[$property.Name] = $property.Value
    }
}

# If we have a config.ps1 file,
if (Test-Path 'config.ps1') {
    # Get the script command
    $configScript = Get-Command -Name './config.ps1'
    # and install any requirements it has.
    $configScript | RequireModule
    # run it, and let it configure anything it chooses to.
    . $configScript
}

# Start the clock
$site['LastBuildTime'] = $lastBuildTime = [DateTime]::Now
#region Build Files

# Start the clock on the build process
$buildStart = [DateTime]::Now
# pipe every file we find to buildFile
$Site.Files | . buildPage
# and stop the clock
$buildEnd = [DateTime]::Now

#endregion Build Files

# If we have changed directories, we need to push back into the script root directory.
if ($PSScriptRoot -and "$PSScriptRoot" -ne "$pwd") {
    Push-Location $psScriptRoot
}

if ($site.includes.'LastBuild.json' -is [Management.Automation.ExternalScriptInfo]) {
    . $site.includes.'LastBuild.json'
}

#region index.rss
if (-not $Site.NoRss) {
    $pagesByDate = @($site.PagesByUrl.GetEnumerator() | 
        Sort-Object { $_.Value.Date } -Descending)
    $lastPubDate = if ($pagesByDate.Values.Date) {
        $pagesByDate[0].Value.Date.ToString('R')
    } else {
        $lastBuildTime.ToString('R')
    }
    $rssXml = @(
        '<rss version="2.0">'
            '<channel>'
            "<title>$([Security.SecurityElement]::Escape($(
                if ($site.Title) { $site.Title } else { $site.CNAME }
            )))</title>"
            "<link>$($site.RootUrl)</link>"        
            "<description>$([Security.SecurityElement]::Escape($(
                if ($site.Description) { $site.Description } else { $site.Title }
            )))</description>"
            "<pubDate>$($lastPubDate)</pubDate>"
            "<lastBuildDate>$($lastBuildTime.ToString('R'))</lastBuildDate>"
            "<language>$([Security.SecurityElement]::Escape($site.Language))</language>"        
            :nextPage foreach ($keyValue in $pagesByDate) {
                $key = $keyValue.Key
                $keyUri = $key -as [Uri]
                $page = $keyValue.Value
                if ($site.Disallow) {
                    foreach ($disallow in $site.Disallow) {
                        if ($keyUri.LocalPath -like "*$disallow*") { continue nextPage }
                        if ($keyUri.AbsoluteUri -like "*$disallow*") { continue nextPage }
                    }
                }
                if ($site.PagesByUrl[$key].NoIndex) { continue }
                if ($site.PagesByUrl[$key].NoSitemap) { continue }
                if ($site.PagesByUrl[$key].OutputFile.Extension -ne '.html') { continue }
                "<item>"
                "<title>$([Security.SecurityElement]::Escape($(
                    if ($page.Title) { $page.Title }
                    elseif ($site.Title) { $site.Title }
                    else { $site.CNAME }
                )))</title>"
                if ($site.PagesByUrl[$key].Date -is [DateTime]) {
                    "<pubDate>$($site.PagesByUrl[$key].Date.ToString('R'))</pubDate>"
                }
                "<description>$([Security.SecurityElement]::Escape($(
                    if ($page.Description) { $page.Description }
                    elseif ($site.Description) { $site.Description }
                )))</description>"
                "<link>$key</link>"
                "<guid isPermaLink='true'>$key</guid>"
                "</item>"
            }
            '</channel>'
        '</rss>'
    ) -join ' ' -as [xml]
    
    if ($rssXml) {
        $rssOutputPath = Join-Path $site.PSScriptRoot 'RSS' | Join-Path -ChildPath 'index.rss'
        if (-not (Test-Path $rssOutputPath)) {
            # Create the file if it doesn't exist
            $null = New-Item -ItemType File -Force $rssOutputPath
        }
        $rssXml.Save($rssOutputPath)
    }
}


#endregion index.rss

if ($site.includes.'Sitemap.xml' -is [Management.Automation.ExternalScriptInfo]) {
    . $site.includes.'Sitemap.xml' > sitemap.xml
}

if ($site.includes.'Robots.txt' -is [Management.Automation.ExternalScriptInfo]) {
    . $site.includes.'Robots.txt' > robots.txt
}

#region index.json
if (-not $Site.NoIndex) {
    $fileIndex =
        if ($filePath) { Get-ChildItem -Recurse -File -Path $FilePath }
        else { Get-ChildItem -Recurse -File }    

    $replacement = 
        if ($filePath) {
            "^" + ([regex]::Escape($filePath) -replace '\*','.{0,}?')
        } else {
            "^" + [regex]::Escape("$pwd")
        }

    $indexObject    = [Ordered]@{}
    $gitCommand     = $ExecutionContext.SessionState.InvokeCommand.GetCommand('git', 'Application')
    foreach ($file in $fileIndex) {
        $gitDates = 
            try { 
                (& $gitCommand log --follow --format=%ci --date default $file.FullName *>&1) -as [datetime[]]
            } catch {
                $null
            }
        $LASTEXITCODE = 0
        
        $indexObject[$file.FullName -replace $replacement] = [Ordered]@{
            Name        = $file.Name            
            Length      = $file.Length
            Extension   = $file.Extension
            CreatedAt   = 
                if ($gitDates) {
                    $gitDates[-1]
                } else {
                     $file.CreationTime
                }
            LastWriteTime = 
                if ($gitDates) {
                    $gitDates[0]
                } else {
                    $file.LastWriteTime
                }
        }
    }
        
    foreach ($indexKey in $indexObject.Keys) {
        if (-not $indexObject[$indexKey].CreatedAt) {
            if ($indexObject["$indexKey.ps1"].CreatedAt) {
                $indexObject[$indexKey].CreatedAt = $indexObject["$indexKey.ps1"].CreatedAt
            }
        }
        if (-not $indexObject[$indexKey].LastWriteTime) {
            if ($indexObject["$indexKey.ps1"].LastWriteTime) {
                $indexObject[$indexKey].LastWriteTime = $indexObject["$indexKey.ps1"].LastWriteTime
            }            
        }
    }
    
    $indexObject | ConvertTo-Json -Depth 4 > index.json
}
#endregion index.json

#region archive.zip
if ($site.Archive) {
    # Create an archive of the current deployment.
    Compress-Archive -Path $pwd -DestinationPath "archive.zip" -CompressionLevel Optimal -Force
}
#endregion archive.zip
if ($PSScriptRoot) { Pop-Location }
