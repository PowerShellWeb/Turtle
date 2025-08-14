describe Turtle {
    it "Draws things with simple commands" {
        $null = $turtle.Clear().Square()
        $turtleSquaredPoints = $turtle.Points       
        $turtleSquaredPoints.Length | Should -Be 8
        $turtleSquaredPoints | 
            Measure-Object -Sum | 
            Select-Object -ExpandProperty Sum | 
            Should -Be 0
    } 

    it 'Can draw an L-system, like a Sierpinski triangle' {
        $turtle.Clear().SierpinskiTriangle(200, 2, 120).points.Count |
            Should -Be 54
    }

    it 'Can rasterize an image, with a little help from chromium' {
        $png = New-Turtle | Move-Turtle SierpinskiTriangle 15 5 | Select-Object -ExpandProperty PNG
        $png[1..3] -as 'char[]' -as 'string[]' -join '' | Should -Be PNG
    }


    context 'Turtle Directions' {
        it 'Can tell you the way towards a point' {
            $turtle = turtle
            $turtle.Towards(0,1) | should -be 90
            $turtle.Towards(1,1) | Should -be 45
            $turtle.Towards(1,0) | should -be 0
            $turtle.Towards(-1,1) | Should -be 135
            $turtle.Towards(-1,0) | Should -be 180
            $turtle.Towards(0,-1) | Should -be -90
        }

        it 'Will return a relative heading' {
            $turtle = turtle
            $turtle = $turtle.Rotate($turtle.Towards(1,1))
            $turtle = $turtle.Forward($turtle.Distance(1,1))
            $turtle.Heading | Should -be 45
            [Math]::Round($turtle.Position.X,10) | Should -be 1
            [Math]::Round($turtle.Position.Y,10) | Should -be 1
            $turtle = $turtle.Rotate($turtle.Towards(2,2))
            $turtle = $turtle.Forward($turtle.Distance(2,2))
            $turtle.Heading | Should -be 45
            [Math]::Round($turtle.Position.Y,10) | Should -be 2
            [Math]::Round($turtle.Position.Y,10) | Should -be 2
        }
    }

    
}
