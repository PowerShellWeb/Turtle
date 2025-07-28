<#
.SYNOPSIS
    Sets the steps of the turtle.
.DESCRIPTION
    Sets the steps of the turtle to the specified array of strings.

    This property will rarely be set directly, but will be updated every time the turtle moves.    
#>
param(
[string[]]
$Steps
)

$this |  Add-Member -MemberType NoteProperty -Force -Name '.Steps' -Value @($Steps)
