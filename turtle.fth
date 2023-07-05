\ turtle.fth - Turtle graphics in GForth using SDL2.
\ Copyright (C) 2023 Robert Coffey
\ Released under the MIT license.

\ config -----------------------------------------------------------------------

1024 constant WINDOW_W
1024 constant WINDOW_H

144 constant FRAMES/SECOND

\ misc -------------------------------------------------------------------------

: -roll ( x0 .. xn n -- xn x0 .. xn-1 )   { n } n 0 do n roll loop ;
: drop-wordlist ( n -- )   >r get-order 1- r> 1+ roll drop set-order ;

: f-rot ( f: x y z -- f: z x y )   frot frot ;
: f2drop ( f: x y -- )   fdrop fdrop ;
: f2dup ( f: x y -- f: x y x y )   fover fover ;
: fdeg>rad ( f: x -- f: x )   pi f* 180e f/ ;
: fwrap ( f: n hi -- f: n )
  fover f0< if f2dup f+ else
  f2dup f>  if f2dup f- else
               fover    then then f-rot f2drop ;

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
  0 0
  \ SDL_WINDOWPOS_UNDEFINED SDL_WINDOWPOS_UNDEFINED
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

\ turtle -----------------------------------------------------------------------

0e fconstant INIT_TURTLE_X
0e fconstant INIT_TURTLE_Y
0e fconstant INIT_TURTLE_HEAD

fvariable turtle-x INIT_TURTLE_X turtle-x f! \ (x,y) position, center-0
fvariable turtle-y INIT_TURTLE_Y turtle-y f!
fvariable turtle-head INIT_TURTLE_HEAD turtle-head f! \ heading deg, right-0, cw-rot
variable turtle-draw turtle-draw on

: x-rel>abs ( f: x -- x )   f>d drop WINDOW_W/2 + ;
: y-rel>abs ( f: y -- y )   f>d drop WINDOW_H/2 + ;
: pos-rel>abs ( f: x y -- x y )   y-rel>abs x-rel>abs swap ;

: turtle-pos ( -- f: x y )   turtle-x f@ turtle-y f@ ;
: turtle-pos/abs ( -- x y )   turtle-pos pos-rel>abs ;
: turtle-!pos ( f: x y -- )   turtle-y f! turtle-x f! ;

: draw-background ( -- )   rgb-black !draw-rgb draw-clear ;
: draw-turtle ( -- )   rgb-red !draw-rgb turtle-pos/abs draw-point ;

: ?draw-path ( f: ox oy nx ny -- )
  turtle-draw @ if
    rgb-red !draw-rgb
    pos-rel>abs pos-rel>abs draw-line
  then ;

\ Sleep after present prevents render backbuffer corruption. Not great but works
\ for now lol.
create event SDL_Event allot
: update-turtle
  begin event SDL_PollEvent while
    event SDL_Event-type @ 0xFFFFFFFF and { et }
    et SDL_QUIT = if window-quit exit then
  repeat
  draw-turtle window-present 1 window-sleep ;

: put-turtle ( f: nx ny -- )
  turtle-x f@ turtle-y f@ { f: nx f: ny f: ox f: oy }
  nx ny turtle-!pos  ox oy nx ny ?draw-path  update-turtle ;

: move-turtle ( f: dx dy -- )
  turtle-x f@ turtle-y f@ { f: dx f: dy f: ox f: oy }
  ox dx f+ oy dy f+ put-turtle ;

: rot-turtle ( f: n -- )
  turtle-head f@ f+ 360e fwrap  turtle-head f!  update-turtle ;
: walk-turtle ( f: n -- )
  turtle-x f@ turtle-y f@ turtle-head f@ fdeg>rad { f: n f: x f: y f: h }
  h fcos n f* x f+  h fsin n f* y f+  put-turtle ;

\ public -----------------------------------------------------------------------

wordlist >order definitions

: pos ( -- f: x y )   turtle-pos ;
: head ( -- f: n )   turtle-head f@ ;

: put ( f: nx ny -- )   put-turtle ;
: x ( -- f: x )   turtle-x f@ ;
: y ( -- f: x )   turtle-y f@ ;
: !x ( f: nx -- )   turtle-y f@ put ;
: !y ( f: ny -- )   turtle-x f@ fswap put ;
: !xy ( f: nx ny -- )   put ;
: home ( -- )   0e 0e put ;

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

: turtle   window-init draw-background update-turtle ;

1 drop-wordlist
