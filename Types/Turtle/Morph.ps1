<#
.SYNOPSIS
    Morphs a Turtle
.DESCRIPTION
    Morphs a Turtle by animating its path.

    Any two paths with the same number of points can be morphed into each other smoothly.

    Any two paths with a different number of points will become a step-by-step animation.

    Since animations can include multiple complex paths, they can get quite large, and be quite beautiful.
.EXAMPLE
    $sierpinskiTriangle = turtle SierpinskiTriangle 42 4
    $SierpinskiTriangleFlipped = turtle rotate 180 SierpinskiTriangle 42 4
    turtle SierpinskiTriangle 42 4 morph (
        $SierpinskiTriangle, 
        $SierpinskiTriangleFlipped, 
        $sierpinskiTriangle
    ) save ./SierpinskiTriangleFlip.svg
.EXAMPLE
    $sideCount = (3..24 | Get-Random )
    $stepCount = 36
    
    $flower = turtle rotate ((Get-Random -Max 180) * -1) flower 42 10 $sideCount $stepCount
    $flower2 = turtle rotate ((Get-Random -Max 180)) flower 42 50 $sideCount $stepCount
    $flower3 = turtle rotate ((Get-Random -Max 90)) flower 42 20 $sideCount $stepCount
    turtle flower 42 10 $sideCount $stepCount duration ($sideCount * 3) morph ($flower, $flower2,$flower) |
        save-turtle ./flowerMorph.svg Pattern
.EXAMPLE
    $flowerAngle = (40..60 | Get-Random )
    $stepCount = 36
    $radius = 23..42 | Get-Random
    
    $flowerPetals = turtle rotate ((Get-Random -Max 180) * -1) flowerPetal $radius 10 $flowerAngle $stepCount    
    $flowerPetals3 = turtle rotate ((Get-Random -Max 180)) flowerPetal $radius 40 $flowerAngle $stepCount
    turtle flowerPetal $radius 10 $flowerAngle $stepCount duration $radius morph (
        $flowerPetals, 
        $flowerPetals3,
        $flowerPetals
    ) | Save-Turtle ./flowerPetalMorph.svg Pattern
.EXAMPLE
    turtle SierpinskiTriangle 42 4 morph |
        Save-Turtle ./SierpinskiTriangleConstruction.svg
.EXAMPLE
    turtle stroke '#224488' fill '#4488ff' backgroundColor '#112244' rotate 60 SierpinskiTriangle 42 4 SierpinskiTriangle -42 4 morph |
        Save-Turtle ./SierpinskiTriangleReflectionConstructionAndFill.svg
#>
param(
[Parameter(ValueFromRemainingArguments)]
$Arguments
)

$durationArgument = $null
$hasPoints = $false
$segmentCount = 0 
$newPaths = @(foreach ($arg in $Arguments) {
    if ($arg -is [string]) {
        if ($arg -match '^\s{0,}m') {
            $arg
            $hasPoints = $true
        }
    } elseif ($arg.PathData) {
        $arg.PathData
        $hasPoints = $true
    } elseif ($arg.D) {
        $arg.D
        $hasPoints = $true
    } elseif ($arg -is [TimeSpan]) {
        $durationArgument = $arg
    }
    elseif ($arg -is [double] -or $arg -is [int]) {
        if (-not $hasPoints -and $arg -is [int]) {
            $segmentCount = [Math]::Abs($arg)
        } else {
            $durationArgument = [TimeSpan]::FromSeconds($arg)
        }        
    }
})

if (-not $newPaths) {
    if ($this.Steps.Count) {        
        $stepList = @($this.PathData -join ' ' -split '(?=\p{L})' -ne '')
        if ($segmentCount) {
            $newPaths = @(
                for ($n = 1; $n -lt $stepList.Length; $n += ($stepList.Length/$segmentCount)) {
                    $stepList[0..$n] -join ' '
                }
            )            
        } else {
            $newPaths = @(foreach ($n in 1..($stepList.Length)) {
                $stepList[0..$n] -join ' '
            })
        }
        
    } else {
        return $this
    }        
}

if ($this.PathAnimation) {
    $updatedAnimations = 
        @(foreach ($animationXML in $this.PathAnimation -split '(?<=/>)') {
            $animationXML = $animationXML -as [xml]
            if (-not $animationXML) { continue }
            if ($animationXML.animate.attributeName -eq 'd') {
                $animationXML.animate.values = "$($newPaths -join ';')"
            }
            $animationXML.OuterXml
        })
    $this.PathAnimation = $updatedAnimations
} else {
    $this.PathAnimation += [Ordered]@{
        attributeName = 'd'   ; values = "$($newPaths -join ';')" ; repeatCount = 'indefinite'; dur = $(
            if ($durationArgument) {
                "$($durationArgument.TotalSeconds)s"
            } elseif ($this.Duration) {
                "$($this.Duration.TotalSeconds)s"
            } else {
                "4.2s"
            }
            
        )
    }
}

return $this