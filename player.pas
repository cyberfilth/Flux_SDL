(* Player setup and stats *)
unit player;

{$mode objfpc}{$H+}

interface

uses
  SDL2, SDL2_image, SysUtils, map;

type
  (* Store information about the player *)
  Creature = record
    currentHP, maxHP, attack, defense, posX, posY: smallint;
    (* Colour of player glyph *)
    glyphR, glyphG, glyphB: byte;
  end;

var
  (* Image used for the Player Glyph *)
  PlayerTexture: PSDL_Texture;
  (* Visual representation of the Player in the game *)
  PlayerGlyph: TSDL_Rect;
  (* Player character *)
  ThePlayer: Creature;

(* Places the player on the map *)
procedure spawn_player;
(* Moves the player on the map *)
procedure move_player(dir: word);

implementation

uses
  main, dungeon;

procedure spawn_player;
begin
  (* Setup player stats *)
  with ThePlayer do
  begin
    glyphR := 255;
    glyphG := 255;
    glyphB := 51;
    currentHP := 20;
    maxHP := 20;
    attack := 5;
    defense := 2;
    posX := dungeon.startX;
    posY := dungeon.startY;
  end;
  (* set scaling quality *)
  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'nearest');
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load('images/sprites/player_glyph.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  PlayerTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if PlayerTexture = nil then
    Halt;
  (* prepare rectangle *)
  PlayerGlyph.x := dungeon.startX * map.tileSize;
  PlayerGlyph.y := dungeon.startY * map.tileSize;
  PlayerGlyph.w := map.tileSize;
  PlayerGlyph.h := map.tileSize;
end;

(* Move the player within the confines of the game map *)
procedure move_player(dir: word);
begin
  case dir of
    1:
    begin
      if (map.player_can_move(PlayerGlyph.x, PlayerGlyph.y - map.tileSize) = True) then
        PlayerGlyph.y := PlayerGlyph.y - map.tileSize;
    end;
    2:
    begin
      if (map.player_can_move(PlayerGlyph.x - map.tileSize, PlayerGlyph.y) = True) then
        PlayerGlyph.x := PlayerGlyph.x - map.tileSize;
    end;
    3:
    begin
      if (map.player_can_move(PlayerGlyph.x, PlayerGlyph.y + map.tileSize) = True) then
        PlayerGlyph.y := PlayerGlyph.y + map.tileSize;
    end;
    4:
    begin
      if (map.player_can_move(PlayerGlyph.x + map.tileSize, PlayerGlyph.y) = True) then
        PlayerGlyph.x := PlayerGlyph.x + map.tileSize;
    end
    else
    // empty else statement
  end;
  ThePlayer.posX := map.screenToMap(PlayerGlyph.x);
  ThePlayer.posY := map.screenToMap(PlayerGlyph.y);
end;

end.

