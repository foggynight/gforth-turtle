require ../turtle.fth

require random.fs
utime drop seed !

50e fconstant LEN_INIT
1e  fconstant LEN_STEP
91e fconstant ROT_STEP

: f+! ( adr f: n -- )   { adr } adr f@ f+ adr f! ;

: random-color ( -- )   3 0 do 255 random loop !color ;

fvariable len  LEN_INIT len f!
: square ( -- )   4 0 do len f@ wk  LEN_STEP len f+!  ROT_STEP rt loop ;
: sqiral ( n -- )   LEN_INIT len f!  0 do random-color square loop ;

: main ( -- )   turtle  home clear  360 sqiral ;
