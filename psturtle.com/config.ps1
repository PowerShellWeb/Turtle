<#
.SYNOPSIS
    Configures the site
.DESCRIPTION
    Configures the site.  
    
    At the point this runs, a $Site dictionary should exist, and it should contain a list of files to build.

    Any *.json, *.psd1, or *.yaml files in the root should have already been loaded into the $Site dictionary.

    Any additional configuration or common initialization should be done here.
#>

param()

#region Core
if ($psScriptRoot) {Push-Location $psScriptRoot}
if (-not $Site) { $Site = [Ordered]@{} }
$parentFolderManifest = 
    Get-ChildItem -File -Path .. | 
    Where-Object Extension -eq .psd1 | 
    Select-String 'ModuleVersion\s{0,}='

if ($parentFolderManifest) {
    $ImportedParentModule = Import-Module -Name ../ -PassThru -Global
    if ($ImportedParentModule) {
        $site.Module = $ImportedParentModule
    }
}

if ($psScriptRoot -and -not $site.PSScriptRoot) {
    $site.PSScriptRoot = $PSScriptRoot
}
#endregion Core

#region _
if ($site.PSScriptRoot) {
    $underbarItems = 
        Get-ChildItem -Path $site.PSScriptRoot -Filter '_*' -Recurse

    $underbarFileQueue = [Collections.Queue]::new()

    foreach ($underbarItem in $underbarItems) {
        $relativePath = $underbarItem.FullName.Substring($site.PSScriptRoot.Length + 1)
        if ($underbarItem -is [IO.FileInfo]) {
            $underbarFileQueue.Enqueue($underbarItem)
        }
        else {
            foreach ($childItem in $underbarItem.GetFileSystemInfos()) {
                if ($childItem -is [IO.FileInfo]) {
                    $underbarFileQueue.Enqueue($childItem)
                }
            }            
        }
    }

    foreach ($underbarFile in $underbarFileQueue.ToArray()) {
        $relativePath = $underbarFile.FullName.Substring($site.PSScriptRoot.Length + 1)
        $pointer = $site
        $hierarchy = @($relativePath -split '[\\/]')
        for ($index = 0; $index -lt ($hierarchy.Length - 1); $index++) {
            $subdirectory = $hierarchy[$index] -replace '_'
            if (-not $pointer[$subdirectory]) {
                $pointer[$subdirectory] = [Ordered]@{}
            }
            $pointer = $pointer[$subdirectory]
        }
                
        $propertyName = $hierarchy[-1] -replace '_' -replace "$([Regex]::Escape($underbarFile.Extension))$"
        
        $fileData = 
            switch ($underbarFile.Extension) {
                '.ps1' { $ExecutionContext.SessionState.InvokeCommand.GetCommand($underbarFile.FullName, 'ExternalScript') }
                '.txt' { Get-Content -LiteralPath $underbarFile.FullName }
                '.json' { Get-Content -LiteralPath $underbarFile.FullName -Raw | ConvertFrom-Json }
                '.psd1' { Get-Content -LiteralPath $underbarFile.FullName -Raw | ConvertFrom-StringData }
                '.yaml' {
                    'YaYaml' | RequireModule
                    Get-Content -LiteralPath $underbarFile.FullName -Raw | ConvertFrom-Yaml                    
                }                
                '.svg' { (Get-Content -LiteralPath $underbarFile -Raw) -as [xml] }
                '.csv' { Import-Csv -LiteralPath $underbarFile.FullName }
                '.tsv' { Import-Csv -LiteralPath $underbarFile.FullName -Delimiter "`t" }            
            }

        if ($fileData) {
            $pointer[$propertyName] = $fileData
        }
    }
}
#region _

#region Site Metadata
$Site.Title = 'Turtle'
$Site.Description = 'Turtles in a PowerShell'
#endregion Site Metadata

#region Site Icons
$Site.Icon  = [Ordered]@{
    'GitHub' = . $site.includes.Feather 'GitHub'
    'RSS' = . $site.includes.Feather 'RSS'
}
#endregion Site Icons

#region Site Menus
$Site.Logo = 
    @(
        {             
            $flowerSides = 3..12 | Get-Random
            turtle Flower 42 (15,20,30,60,72 | Get-Random) $flowerSides 
        }
                
        {
            turtle SierpinskiTriangle 42 4
        }
    )

$site.Logo = . ($site.Logo | Get-Random)
$Site.Logo.ID = 'Turtle-Logo' 

<# $Site.Logo = $Site.Logo | Set-Turtle PathAnimation @{
    type = 'rotate'   ; values = 0, 360 ;repeatCount = 'indefinite'; dur = "31s"; additive = 'sum'; id ='rotate-logo'
} #>

$site.Taskbar = [Ordered]@{
    # 'BlueSky' = 'https://bsky.app/profile/mrpowershell.com'
    'GitHub' = 'https://github.com/PowerShellWeb/Turtle'
    'RSS' = 'https://psturtle.com/RSS/index.rss'
}

<#$site.HeaderMenu = [Ordered]@{

}#>
#endregion Site Menus

#region Site Background

$doodle = @(
    'forward', 100,'right', 90 * 2
    'forward', 50,'right', 90 * 2
    'forward', 100,'right', 90
    'forward', 25, 'right', 90 * 2
    'forward', 50
)

# Randomizing site background a bit
$backgroundPatternAnimations = 
    [Ordered]@{
        type = 'scale'    ; values = 0.66,0.33, 0.66 ; repeatCount = 'indefinite' ;dur = "277s"; additive = 'sum';id ='scale-pattern'
    }, [Ordered]@{
        type = 'rotate'   ; values = 0, 360 ;repeatCount = 'indefinite'; dur = "317s"; additive = 'sum'; id ='rotate-pattern'
    }

$sitebackgrounds = @(

    {turtle Flower 30 60 6}

    {turtle Flower 30 (360/8) 8}

    {turtle SierpinskiTriangle 15 4 }
    
    {turtle SierpinskiArrowheadCurve 15 4}

    {turtle KochSnowflake 4.2 4}
    
    {turtle BoxFractal 4.2 4}

    # {turtle Flower 15 5 40 72}

    {turtle Flower 15 9 40 40}

    {turtle rotate 72 square 84 jump 84}

    {turtle rotate 20 @('circle',15,0.5,'circle',15,-0.5, 'rotate', 90 * 4)}

    {turtle @('rotate', 90, 'circle',42,0.25,'circle',42,-0.25 * 4)}

    {turtle @('rotate', 45, 'circle',21,0.25,'circle',21,-0.25 * 8)}

    {turtle rotate (360/5) @('circle',15,0.5,'circle',15,-0.5, 'rotate', 72 * 5)}
    
    {
        turtle square 42 @('rotate', -60, 'forward',42, 'rotate', 120, 'forward',42, 'rotate', 30 * 4)
    }

    { 
        # Golden triangle/square star
        $goldenRatio = (1 + [Math]::sqrt(5))/2
        turtle @('rotate', -60, 'forward',(42*$goldenRatio), 'rotate', 120, 'forward',(42*$goldenRatio), 'rotate', 30 * 4)
    }

    {
        # Golden hexagon
        $goldenRatio = (1 + [Math]::sqrt(5))/2
        $BaseSideCount = 6
        turtle @(
            'rotate', (360/$BaseSideCount/-2)
            foreach ($n in 1..$BaseSideCount) {
                'forward'
                42 * $goldenRatio
                'rotate'
                360/$BaseSideCount
            }
        ) * 2
        
    }

    {
        # Golden hex flowers
        $goldenRatio = (1 + [Math]::sqrt(5))/2
        $BaseSideCount = 6
        turtle (@(
            'rotate', (360/$BaseSideCount/-2)
            foreach ($n in 1..$BaseSideCount) {
                'forward'
                42 * $goldenRatio
                'rotate'
                360/$BaseSideCount
            }
            'rotate', (360/($BaseSideCount)/4)
        ) * ($BaseSideCount * 4))
    }

    {        
        turtle @($doodle * 4)
    }

    {        
        turtle ($doodle,'right','10', 'forward', '50' * 36)
    }

    {
        turtle ($doodle,'left','45', 'forward', '100' * 8)
    }

    {
        turtle ($doodle,'left','30', 'forward', '75' * 3)
    }

    {
        turtle @('StepSpiral',23, 90, 4, 'rotate',90 * 4)
    }

    {
        turtle spirolateral 42 60 8
    }

    {
        turtle rotate -30 @('spirolateral',23,60,6,@(1,3),'rotate', 60 * 6 )
    }

    {
        turtle spirolateral 23 90 11 @(3,4,5) 
    }

    {
        turtle spirolateral 23 120 6 @(1,3)
    }

    {
        turtle spirolateral 23 144 8
    }
    
    {
        turtle @('StepSpiral',23, 60, 4 * 3)
    }

    {
        turtle @('StepSpiral',23, 120, 16, 18)
    }

    {
        turtle @('StepSpiral',23, 60, 16, 19 * 6)
    }

    {
        turtle @('ArcRight', 23, 60, 'ArcLeft', 23, 160 * 24)
    }

    {
        turtle Pentaplexity 23 4
    }

    {
        turtle BoardFractal 23 4        
    }

    {
        turtle CrystalFractal 23 4
    }

    {
        turtle FlowerPetal 
    }
)

$siteBackground = $sitebackgrounds | Get-Random
        
$site.Background = . $siteBackground|
    Set-Turtle PatternAnimation $backgroundPatternAnimations |
    Set-Turtle PathAttribute @{opacity=.2} |
    Select-Object -ExpandProperty Pattern
#endregion Site Background