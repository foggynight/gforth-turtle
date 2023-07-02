\ turtle.fth - Turtle graphics in GForth using SDL2.
\ Copyright (C) 2023 Robert Coffey
\ Released under the MIT license.

\ config -----------------------------------------------------------------------

512 constant WINDOW_W
512 constant WINDOW_H

144 constant FRAMES/SECOND

\ misc -------------------------------------------------------------------------

: -roll ( x0 .. xn n -- xn x0 .. xn-1 )   { n } n 0 do n roll loop ;
: drop-wordlist ( n -- )   >r get-order 1- r> 1+ roll drop set-order ;

: deg>rad ( r -- r )   pi 180 0 d>f f/ f* ;
: xsiny ( x y -- n )   0 d>f deg>rad fsin 0 d>f f* f>d drop ;
: xcosy ( x y -- n )   0 d>f deg>rad fcos 0 d>f f* f>d drop ;

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

0 constant INIT_TURTLE_X
0 constant INIT_TURTLE_Y

variable turtle-x INIT_TURTLE_X turtle-x ! \ (x,y) position, center-origin
variable turtle-y INIT_TURTLE_Y turtle-y !
variable turtle-head 0 turtle-head ! \ heading (degrees), right-origin, cw-rot
variable turtle-draw turtle-draw on

: x-rel>abs   WINDOW_W/2 + ;
: y-rel>abs   WINDOW_H/2 + ;
: pos-rel>abs ( x y -- x y )   y-rel>abs swap x-rel>abs swap ;

: turtle-pos ( -- x y )   turtle-x @ turtle-y @ ;
: turtle-pos/abs ( -- x y )   turtle-pos pos-rel>abs ;
: turtle-!pos ( nx ny -- )   turtle-y ! turtle-x ! ;

: draw-background ( -- )   rgb-black !draw-rgb draw-clear ;
: draw-turtle ( -- )   rgb-red !draw-rgb turtle-pos/abs draw-point ;

: ?draw-path ( ox oy nx ny -- )
  turtle-draw @ if
    rgb-red !draw-rgb
    pos-rel>abs 2swap pos-rel>abs draw-line
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

: put-turtle ( nx ny -- )
  turtle-x @ turtle-y @ { nx ny ox oy }
  nx ny turtle-!pos  ox oy nx ny ?draw-path  update-turtle ;

: move-turtle ( dx dy -- )
  turtle-x @ turtle-y @ { dx dy ox oy }
  ox dx + oy dy + put-turtle ;

: rot-turtle ( n -- )   turtle-head @ + 360 mod turtle-head !  update-turtle ;
: walk-turtle ( n -- )
  turtle-x @ turtle-y @ turtle-head @ { n x y h }
  n h xcosy x +  n h xsiny y + put-turtle ;

\ public -----------------------------------------------------------------------

wordlist >order definitions

: pos ( -- x y )   turtle-pos ;
: head ( -- n )   turtle-head @ ;

: put ( nx ny -- )   put-turtle ;
: x ( -- x )   turtle-x @ ;
: y ( -- x )   turtle-y @ ;
: !x ( nx -- )   turtle-y @ put ;
: !y ( ny -- )   turtle-x @ swap put ;
: !xy ( nx ny -- )   put ;
: home ( -- )   0 0 put ;

: move ( dx dy -- )   move-turtle ;
: left ( n -- )   negate rot-turtle ;
: right ( n -- )   rot-turtle ;
: walk ( n -- )   walk-turtle ;
: back ( n -- )   negate walk ;

: mv move ;
: lt left ;
: lf left ;
: rt right ;
: wk walk ;
: fd walk ;
: bk back ;

: main   window-init draw-background update-turtle ;

1 drop-wordlist
