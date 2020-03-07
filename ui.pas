(* User Interface - Unit responsible for displaying messages and stats *)

unit ui;

{$mode objfpc}{$H+}

interface

uses
  SDL2;

const
  (* side bar X position *)
  sbx = 685;
  (* side bar Y position *)
  sby = 9;
  (* side bar Width *)
  sbw = 145;
  (* side bar Heinght *)
  sbh = 381;

var
  (* Information bar on the right side of screen *)
  sidebarRect: TSDL_Rect;

(* Draws the panel on side of screen *)
procedure draw_sidepanel;

implementation

uses
  main;

(* Draws the panel on side of screen *)
procedure draw_sidepanel;
begin
  sidebarRect.x := sbx;
  sidebarRect.y := sby;
  sidebarRect.w := sbw;
  sidebarRect.h := sbh;
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_NONE);
  SDL_SetRenderDrawColor(main.sdlRenderer, 0, 128, 128, SDL_ALPHA_TRANSPARENT);
  SDL_RenderDrawRect(main.sdlRenderer, @sidebarRect);
end;

end.
