\ turtle.fth - Turtle graphics in GForth using SDL2.
\ Copyright (C) 2023 Robert Coffey
\ Released under the MIT license.

\ config -----------------------------------------------------------------------

144 constant FRAMES/SECOND

512 constant WINDOW_W
512 constant WINDOW_H

\ misc -------------------------------------------------------------------------

: -roll ( x0 .. xn n -- xn x0 .. xn-1 )   { n } n 0 do n roll loop ;

\ window -----------------------------------------------------------------------

table >order definitions
require gforth-sdl2/SDL.fth
require gforth-sdl2/SDL_events.fth
require gforth-sdl2/SDL_render.fth
require gforth-sdl2/SDL_timer.fth
require gforth-sdl2/SDL_video.fth
wordlist >order definitions

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
  SDL_WINDOWPOS_UNDEFINED SDL_WINDOWPOS_UNDEFINED
  WINDOW_W WINDOW_H
  SDL_WINDOW_SHOWN SDL_WINDOW_RESIZABLE or
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

: draw-background   rgb-black !draw-rgb draw-clear ;

\ main -------------------------------------------------------------------------

create event SDL_Event allot

: (main)
  begin
    begin event SDL_PollEvent while
      event SDL_Event-type @ 0xFFFFFFFF and { et }
      et SDL_QUIT = if window-quit exit then
    repeat
    draw-background
    window-present
    [ 1000 FRAMES/SECOND / ] literal window-sleep
  false until ;
: main   window-init (main) window-quit ;
