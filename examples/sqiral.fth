require ../turtle.fth

require random.fs
utime drop seed !

50e fconstant LEN_INIT
1e  fconstant LEN_STEP
91e fconstant ROT_STEP

: f+! ( adr f: n -- )   { adr } adr f@ f+ adr f! ;

fvariable len  LEN_INIT len f!
: square ( -- )   4 0 do len f@ wk  LEN_STEP len f+!  ROT_STEP rt loop ;

: random-color ( -- )   3 0 do 255 random loop !color ;
: sqiral ( n -- )   0 do random-color square loop ;

: main ( -- )   turtle 360 sqiral ;
