if ($PSScriptRoot) { Push-Location $PSScriptRoot}

$turtlesOnATextPath = turtle rotate 90 jump 50 rotate -90 ArcRight 50 60 text 'turtles on a text path' textattribute @{'font-size'=36}
$turtlesOnATextPath | Save-Turtle ./TurtlesOnATextPath.svg


$textPath2 = turtle rotate 90 jump 50 rotate -90 ArcRight 50 -60 

$turtlesOnATextPath = 
    turtle rotate 90 jump 50 rotate -90 rotate -30 forward 200 text 'turtles on a text path' morph @(
        turtle rotate 90 jump 50 rotate -90 rotate -10 forward 200
        turtle rotate 90 jump 50 rotate -90 rotate -5 forward 200
        turtle rotate 90 jump 50 rotate -90 rotate -10 forward 200
    ) textAnimation ([Ordered]@{
        attributeName = 'fill'   ; values = "#4488ff;#224488;#4488ff" ; repeatCount = 'indefinite'; dur = "4.2s"
    },[Ordered]@{
        attributeName = 'font-size'   ; values = "1em;1.3em;1em" ; repeatCount = 'indefinite'; dur = "4.2s"
    },[Ordered]@{
        attributeName = 'textLength'   ; values = "100%;1%;100%" ; repeatCount = 'indefinite'; dur = "4.2s"
    },[Ordered]@{
        attributeName = 'x'   ; values = "-100%; 100%; -50%" ; repeatCount = 'indefinite'; dur = "4.2s"
    })
$turtlesOnATextPath | Save-Turtle ./TurtlesOnATextPathMorph.svg


turtle rotate -90 circle 42 text "a turtle circle" textattribute ([Ordered]@{
    'x'='5%';
    'dominant-baseline'='text-before-edge';
    'letter-spacing'='.16em'
}) save ./aTurtleCircle.svg

if ($PSScriptRoot) { Pop-Location }