(* FLUX - Free pascaL rogUeLike eXample
   @author(Chris Hawkins)       *)

program flux;

{$mode objfpc}{$H+}

uses
  SDL2,
  main,
  ui,
  map,
  dungeon,
  player,
  process_dungeon,
  globalutils,
  entities,
  cave;

{$R *.res}

begin
  (* initialisation of video subsystem *)
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, 'Error Box', SDL_GetError, nil);
    HALT;
  end;
  (* Set up window and render *)
  main.sdlWindow1 := SDL_CreateWindow('Flux - The Roguelike',
    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 837, 600, SDL_WINDOW_SHOWN);
  if main.sdlWindow1 = nil then
    Halt;
  main.sdlRenderer := SDL_CreateRenderer(main.sdlWindow1, -1, 0);
  if main.sdlRenderer = nil then
    Halt;
  (* Set random seed *)
  {$IFDEF Linux}
  RandSeed := RandSeed shl 8;
  {$ENDIF}
  {$IFDEF Windows}
  RandSeed := ((RandSeed shl 8) or GetProcessID);
  {$ENDIF}
  (* Setup new game *)
  main.newGame;
  (* Game loop *)
  main.wait_for_input;
end.
