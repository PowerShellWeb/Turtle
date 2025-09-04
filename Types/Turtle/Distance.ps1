<#
.SYNOPSIS
    Determines the distance to a point
.DESCRIPTION
    Determines the distance from the turtle's current position to a point.
#>
param()

$towards = $args

$tx = 0.0
$ty = 0.0

$nCount = 0
foreach ($toward in $towards) {
    if ($toward -is [double] -or $toward -is [float] -or $toward -is [int]) {
        if (-not ($nCount % 2)) {
            $tx = $toward 
        } else {
            $ty = $toward
        }
        $nCount++    
    }
    elseif ($null -ne $toward.X -and $null -ne $toward.Y) {
        $tx = $toward.x
        $ty = $toward.y
        $nCount+= 2        
    }
}

$tx/=($nCount/2)
$ty/=($nCount/2)

# Determine the delta from the turtle's current position to the specified point
$deltaX = $tx - $this.Position.X 
$deltaY = $ty - $this.Position.Y

# Calculate the distance using the Pythagorean theorem
return [Math]::Sqrt($deltaX*$deltaX + $deltaY*$deltaY)