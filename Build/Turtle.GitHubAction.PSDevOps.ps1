﻿#requires -Module PSDevOps
Import-BuildStep -SourcePath (
    Join-Path $PSScriptRoot 'GitHub'
) -BuildSystem GitHubAction

$PSScriptRoot | Split-Path | Push-Location

New-GitHubAction -Name "TurtlePower" -Description 'Turtles in a PowerShell' -Action TurtleAction -Icon chevron-right -OutputPath .\action.yml

Pop-Location