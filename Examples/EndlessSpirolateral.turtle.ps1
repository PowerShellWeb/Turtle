Push-Location $PSScriptRoot
$myName = $MyInvocation.MyCommand.Name -replace '\.turtle\.ps1$'
$turtle = turtle rotate -30 @('spirolateral',42,60,6,@(1,3),'rotate', 60 * 6 )| 
    Set-Turtle -Property PatternTransform -Value @{scale=0.33} |
    set-turtle -property Fill -value '#4488ff' |
    set-turtle -property FillRule -value 'evenodd' |
    Set-Turtle -Property PatternAnimation -Value ([Ordered]@{
        type = 'scale'    ; values = 0.66,0.33, 0.66 ; repeatCount = 'indefinite' ;dur = "23s"; additive = 'sum'
    }, [Ordered]@{
        type = 'rotate'   ; values = 0, 360 ;repeatCount = 'indefinite'; dur = "41s"; additive = 'sum'
    }, [Ordered]@{
        type = 'skewX'    ; values = -30,30,-30;repeatCount = 'indefinite';dur = "83s";additive = 'sum'
    }, [Ordered]@{
        type = 'skewY'    ; values = 30,-30, 30;repeatCount = 'indefinite';additive = 'sum';dur = "103s"
    }, [Ordered]@{
        type = 'translate';values = "0 0","42 42", "0 0";repeatCount = 'indefinite';additive = 'sum';dur = "117s"
    })    
    
$turtle | save-turtle -Path "./$myName.svg" -Property Pattern
Pop-Location