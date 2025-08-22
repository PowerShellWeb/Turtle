$turtleCommands = Get-Command -Module Turtle -CommandType All

$turtleCoreCommands = $turtleCommands | Where-Object Noun -eq Turtle

ConvertFrom-Markdown @"

$(
    @(
        $turtleCoreCommands | Sort-Object Name -Descending |  %{ "* $($_.Name)"}
    ) -join [Environment]::NewLine
)

"@

