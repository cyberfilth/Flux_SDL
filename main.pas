(* Main game loop and screen redraws *)

unit main;

{$mode objfpc}{$H+}

interface

uses
  SDL2;

var
  (* Game window *)
  sdlWindow1: PSDL_Window;
  (* Renderer that paints onto the sdlSurface *)
  sdlRenderer: PSDL_Renderer;
  (* Checks the game is still running when waiting for input *)
  Running: boolean = True;
  (* Image surface the game paints on *)
  sdlSurface1: PSDL_Surface;
  (* Waits for key press from the player *)
  sdlEvent: PSDL_Event;
  (* Triggered when the player presses a key *)
  KeyDownDir: longint;

(* New game setup *)
procedure newGame;
(* Waits for player input *)
procedure wait_for_input;
(* Repaints the map on screen *)
procedure repaintWindow;
(* Repaints the player on screen *)
procedure repaintPlayer;
(* Updates the screen after each move *)
procedure postPlayerAction;
(* Frees up memory when the game ends *)
procedure clearExit;

implementation

uses
  player, ui, map;

procedure newGame;
begin
  (* Set up game world *)
  map.setupMap;
  map.setupTiles;
  (* Draw side panel *)
  ui.draw_sidepanel;
  (* spawn player *)
  player.spawn_player;
  repaintWindow;
  repaintPlayer;
end;

(* Each movement is triggered by an individual keypress as the game is turn based *)
procedure wait_for_input;
begin
  new(sdlEvent);
  while Running = True do
  begin
    SDL_PumpEvents;
    while SDL_PollEvent(sdlEvent) = 1 do
      (* Movement keys *)
      case sdlEvent^.type_ of
        SDL_KEYDOWN:
        begin
          KeyDownDir := sdlEvent^.key.keysym.sym;
          (* Exit if player presses ESCAPE *)
          if KeyDownDir = 27 then
          begin
            clearExit;
          end;
          (* W*)
          if KeyDownDir = 119 then
          begin
            player.move_player(1);
            postPlayerAction;
          end;
          (* A *)
          if KeyDownDir = 97 then
          begin
            player.move_player(2);
            postPlayerAction;
          end;
          (* S *)
          if KeyDownDir = 115 then
          begin
            player.move_player(3);
            postPlayerAction;
          end;
          (* D *)
          if KeyDownDir = 100 then
          begin
            player.move_player(4);
            postPlayerAction;
          end;
        end;
      end;
  end;
end;

procedure repaintWindow;
begin
  SDL_SetRenderDrawColor(sdlRenderer, 0, 26, 19, SDL_ALPHA_OPAQUE);
  SDL_RenderClear(sdlRenderer);
  ui.draw_sidepanel;
    (* repaint any tiles not in FOV *)
  map.removeFOV;
  map.clearVision;
  map.FOV(player.ThePlayer.posX, player.ThePlayer.posY);
end;

procedure repaintPlayer;
begin
  SDL_SetTextureColorMod(PlayerTexture, player.ThePlayer.glyphR,
    player.ThePlayer.glyphG, player.ThePlayer.glyphB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_SetRenderDrawColor(main.sdlRenderer, 0, 26, 19, SDL_ALPHA_TRANSPARENT);
  SDL_RenderDrawRect(sdlRenderer, @PlayerGlyph);
  SDL_RenderCopy(sdlRenderer, PlayerTexture, @PlayerGlyph, nil);
  SDL_RenderCopy(sdlRenderer, PlayerTexture, nil, @PlayerGlyph);
  SDL_RenderPresent(sdlRenderer);
end;

procedure postPlayerAction;
begin
  repaintWindow;
  repaintPlayer;
end;

procedure clearExit;
begin
  (* clear memory and close SDL2 *)
  Running := False;
  dispose(sdlEvent);
  SDL_DestroyTexture(player.PlayerTexture);
  SDL_DestroyRenderer(sdlRenderer);
  SDL_DestroyWindow(sdlWindow1);
  SDL_Quit;
end;

end.
