require ../turtle.fth

: circle   360 0 do fdup fd 1e rt loop ;
: flower   18 0 do 3e circle 20e rt loop ;
: main   turtle flower ;
