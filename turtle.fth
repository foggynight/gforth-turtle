\ turtle.fth - Turtle graphics in GForth using SDL2.
\ Copyright (C) 2023 Robert Coffey
\ Released under the MIT license.

\ config -----------------------------------------------------------------------

1024 constant WINDOW_W
1024 constant WINDOW_H

144 constant FRAMES/SECOND

\ misc -------------------------------------------------------------------------

: -roll ( x0 .. x1 n -- x1 x0 .. x1-1 )   { n } n 0 do n roll loop ;

: ?>sign ( ? -- -1 | 1 )   if 1 else -1 then ;

: f-rot ( f: x y z -- f: z x y )   frot frot ;
: f2drop ( f: x y -- )   fdrop fdrop ;
: f2dup ( f: x y -- f: x y x y )   fover fover ;
: fdeg>rad ( f: x -- f: x )   pi f* 180e f/ ;
: fwrap ( f: n hi -- f: n )
  fover f0< if f2dup f+ else
  f2dup f>  if f2dup f- else
               fover    then then f-rot f2drop ;

: drop-wordlist ( n -- )   >r get-order 1- r> 1+ roll drop set-order ;

\ grid -------------------------------------------------------------------------

WINDOW_W constant GRID_W
WINDOW_H constant GRID_H
GRID_W GRID_H * constant GRID_SIZE

create grid GRID_SIZE chars allot
grid GRID_SIZE chars erase

: grid-ref ( x y -- a )   WINDOW_H * + grid + ;
: grid@ ( a -- c )   c@ ;
: grid! ( c a -- )   c! ;

: grid-on ( a -- )   true swap grid! ;
: grid-off ( a -- )   false swap grid! ;

: grid-within? { x y -- ? }   x 0 GRID_W within  y 0 GRID_H within  and ;
: grid-clear ( -- )   grid GRID_SIZE chars erase ;

\ window -----------------------------------------------------------------------

table >order definitions
require gforth-sdl2/SDL.fth
require gforth-sdl2/SDL_events.fth
require gforth-sdl2/SDL_render.fth
require gforth-sdl2/SDL_timer.fth
require gforth-sdl2/SDL_video.fth
wordlist >order definitions

WINDOW_W 2 / constant WINDOW_W/2
WINDOW_H 2 / constant WINDOW_H/2

variable window
variable render

: window-title   s\" gforth-turtle\0" drop ;

: rgb-black    0   0   0 ;
: rgb-red    255   0   0 ;
: rgb-green    0 255   0 ;
: rgb-blue     0   0 255 ;
: rgb-white  255 255 255 ;

: init-sdl2   SDL_INIT_VIDEO SDL_Init drop ;
: init-window
  window-title
  0 0 \ SDL_WINDOWPOS_UNDEFINED SDL_WINDOWPOS_UNDEFINED
  WINDOW_W WINDOW_H
  SDL_WINDOW_SHOWN
  SDL_CreateWindow window ! ;
: init-render
  window @ -1 SDL_RENDERER_ACCELERATED SDL_CreateRenderer render ! ;

: window-init ( -- )   init-sdl2 init-window init-render ;
: window-present ( -- )   render @ SDL_RenderPresent ;
: window-sleep ( ms -- )   SDL_Delay ;
: window-quit ( -- )   SDL_Quit ;

: !draw-rgba ( r g b a -- )   render @ 4 -roll SDL_SetRenderDrawColor drop ;
: !draw-rgb ( r g b -- )   255 !draw-rgba ;
: draw-clear ( -- )   render @ SDL_RenderClear drop ;
: draw-point ( x y -- )   render @ 2 -roll SDL_RenderDrawPoint drop ;
: draw-line ( x0 y0 x1 y1 -- )   render @ 4 -roll SDL_RenderDrawLine drop ;

: draw-background ( -- )   rgb-black !draw-rgb draw-clear ;
: draw-grid ( -- )
  WINDOW_H 0 do
    WINDOW_W 0 do
      j i grid-ref grid@ if
        rgb-red !draw-rgb
        j i draw-point
      then
    loop
  loop ;

\ turtle -----------------------------------------------------------------------

0e fconstant INIT_TURTLE_X
0e fconstant INIT_TURTLE_Y
0e fconstant INIT_TURTLE_HEAD

fvariable turtle-x INIT_TURTLE_X turtle-x f! \ (x,y) position, center-0
fvariable turtle-y INIT_TURTLE_Y turtle-y f!
fvariable turtle-head INIT_TURTLE_HEAD turtle-head f! \ heading deg, right-0, cw-rot
variable turtle-draw turtle-draw on

: turtle-draw?   turtle-draw @ ;

: x-rel>abs ( f: x -- x )   f>d drop WINDOW_W/2 + ;
: y-rel>abs ( f: y -- y )   f>d drop WINDOW_H/2 + ;
: pos-rel>abs ( f: x y -- x y )   y-rel>abs x-rel>abs swap ;

: turtle-pos ( -- f: x y )   turtle-x f@ turtle-y f@ ;
: turtle-pos/abs ( -- x y )   turtle-pos pos-rel>abs ;
: turtle-!pos ( f: x y -- )   turtle-y f! turtle-x f! ;

: (mark-point) { x y -- }   x y grid-within? if x y grid-ref grid-on then ;
: mark-point ( f: x y -- )   pos-rel>abs (mark-point) ;
: mark-turtle ( -- )   turtle-pos mark-point ;

\ The following is a variant of Bresenham's line drawing algorithm.
\
\     plotLine(x0, y0, x1, y1)
\         dx = abs(x1 - x0)
\         sx = x0 < x1 ? 1 : -1
\         dy = -abs(y1 - y0)
\         sy = y0 < y1 ? 1 : -1
\         error = dx + dy
\         while true
\             plot(x0, y0)
\             if x0 == x1 && y0 == y1 break
\             e2 = 2 * error
\             if e2 >= dy
\                 if x0 == x1 break
\                 error = error + dy
\                 x0 = x0 + sx
\             end if
\             if e2 <= dx
\                 if y0 == y1 break
\                 error = error + dx
\                 y0 = y0 + sy
\             end if
\         end while
\
\ Source: <https://en.wikipedia.org/wiki/Bresenham's_line_algorithm>
: mark-line ( f: x0 y0 x1 y1 -- )
  pos-rel>abs pos-rel>abs { x1 y1 x0 y0 }
  x1 x0 - abs  y1 y0 - abs negate  { dx dy }
  x0 x1 < ?>sign  y0 y1 < ?>sign  { sx sy }
  x0 y0 dx dy + { xw yw err }
  begin
    xw yw (mark-point)
    xw x1 = yw y1 = and ?exit
    err 2* { e2 }
    e2 dy >= if
      xw x1 = ?exit
      err dy + to err
      xw sx + to xw
    then
    e2 dx <= if
      yw y1 = ?exit
      err dx + to err
      yw sy + to yw
    then
  again ;

create event SDL_Event allot
: update-turtle ( -- )
  begin event SDL_PollEvent while
    event SDL_Event-type @ 0xFFFFFFFF and { et }
    et SDL_QUIT = if window-quit exit then
  repeat
  turtle-draw? if mark-turtle then
  draw-background draw-grid ( draw-turtle ) window-present ;

: put-turtle ( f: x1 y1 -- )
  turtle-x f@ turtle-y f@ { f: x1 f: y1 f: x0 f: y0 }
  x1 y1 turtle-!pos  turtle-draw? if x0 y0 x1 y1 mark-line then  update-turtle ;

: move-turtle ( f: dx dy -- )
  turtle-x f@ turtle-y f@ { f: dx f: dy f: x0 f: y0 }
  x0 dx f+ y0 dy f+ put-turtle ;

: rot-turtle ( f: n -- )
  turtle-head f@ f+ 360e fwrap  turtle-head f!  update-turtle ;

: walk-turtle ( f: n -- )
  turtle-x f@ turtle-y f@ turtle-head f@ fdeg>rad { f: n f: x f: y f: h }
  h fcos n f* x f+  h fsin n f* y f+  put-turtle ;

\ public -----------------------------------------------------------------------

wordlist >order definitions

: pos ( -- f: x y )   turtle-pos ;
: head ( -- f: n )   turtle-head f@ ;

: put ( f: x y -- )   put-turtle ;
: x ( -- f: x )   turtle-x f@ ;
: y ( -- f: x )   turtle-y f@ ;
: !x ( f: x -- )   turtle-y f@ put ;
: !y ( f: y -- )   turtle-x f@ fswap put ;
: !xy ( f: x y -- )   put ;
: home ( -- )   0e 0e put ;
: clear ( -- )   grid-clear update-turtle ;

: move ( f: dx dy -- )   move-turtle ;
: left ( f: n -- )   fnegate rot-turtle ;
: right ( f: n -- )   rot-turtle ;
: walk ( f: n -- )   walk-turtle ;
: back ( f: n -- )   fnegate walk ;

: mv move ;
: lt left ;
: lf left ;
: rt right ;
: wk walk ;
: fd walk ;
: bk back ;

: turtle   window-init update-turtle ;
: turtle-bye   window-quit ;

\ 1 drop-wordlist
