(* Organises the game world in an array and calculates the players FoV *)

unit map;

{$mode objfpc}{$H+}

interface

uses
  SDL2, SDL2_Image, globalutils;

const
  (* Maximum number of tiles in players sight *)
  MAXVISION = 140;
  (* Width of tiles is used as a multiplier in placing tiles *)
  tileSize = 10;
  (* File path to image folder *)
  imagesFolder = 'images\dungeon\ascii\';


type
  (* Tiles that make up the game world *)
  tile = record
    (* Unique tile ID *)
    id: smallint;
    (* Does the tile block movement *)
    blocks: boolean;
    (* Is the tile visible *)
    Visible: boolean;
    (* Has the tile been discovered already *)
    discovered: boolean;
    (* Character used to represent the tile *)
    glyph: char;
    (* Highlight colour of dungeon tiles *)
    hiR, hiG, hiB: byte;
    (* Default colour of dungeon tiles *)
    defR, defG, defB: byte;
  end;

  (* tiles that make up vision radius of player *)
  fovTile = record
    tileID: smallint;
    inSight: boolean;
    gtx, gty: smallint;
  end;

var
  (* Images used for the tiles *)
  aTexture, bTexture, cTexture, dTexture, eTexture, fTexture, gTexture,
  hTexture, iTexture, jTexture, kTexture, lTexture, mTexture, nTexture,
  oTexture, pTexture, floorTexture, rockTexture: PSDL_Texture;
  (* Rectangles to hold the images *)
  aRect, bRect, cRect, dRect, eRect, fRect, gRect, hRect, iRect,
  jRect, kRect, lRect, mRect, nRect, oRect, pRect, floorRect, rockRect: TSDL_Rect;
  (* Game map array *)
  maparea: array[1..MAXROWS, 1..MAXCOLUMNS] of tile;

(* Players Field of View *)
procedure FOV(x, y: smallint);
(* repaints any tiles not in FOV *)
procedure removeFOV;
(* Clears all tiles in players vision *)
procedure clearVision;
(* Load tile textures *)
procedure setupTiles;
(* Draw a map tile at position x, y. 1 = highlight colour, 0 = default colour *)
procedure drawTile(c, r: smallint; hiDef: byte);
(* Loop through tiles and set their ID, visibility etc *)
procedure setupMap;
(* Check if the direction to move to is valid *)
function player_can_move(checkX, checkY: smallint): boolean;
(* Translate map coordinates to screen coordinates *)
function mapToScreen(pos: smallint): smallint;
(* Translate screen coordinates to map coordinates *)
function screenToMap(pos: smallint): smallint;

implementation

uses
  main, dungeon, cave;

var
  (* Rows and Columns *)
  r, c: integer;
  (* FOV tile ID *)
  visID: smallint;
  visionRadius: array[1..MAXVISION] of fovTile;


(* FOV Procedures *)


(* Update the array of visible tiles *)
procedure updateVisibleTiles(i, y, x: smallint);
begin
  visionRadius[i].tileID := maparea[y][x].id;
  visionRadius[i].inSight := True;
  visionRadius[i].gtx := x;
  visionRadius[i].gty := y;
end;

(* Add what can be seen to the FOV array & paint the tiles *)
procedure paintFOV(y1, x1, y2, x2, y3, x3, y4, x4, y5, x5: smallint);
var
  i, x, y: smallint;
begin
  for i := 1 to 5 do
  begin
    case i of
      1:
      begin
        x := x1;
        y := y1;
      end;
      2:
      begin
        x := x2;
        y := y2;
      end;
      3:
      begin
        x := x3;
        y := y3;
      end;
      4:
      begin
        x := x4;
        y := y4;
      end;
      5:
      begin
        x := x5;
        y := y5;
      end;
    end;
    Inc(visID);
    drawTile(x, y, 1);
    maparea[y][x].Visible := True;
    maparea[y][x].discovered := True;
    updateVisibleTiles(visID, y, x);
    if (maparea[y][x].blocks = True) then
      exit;
  end;
end;

procedure FOV(x, y: smallint);
begin
  visID := 0;
  (* First octant *)
  paintFOV(y - 1, x, y - 2, x, y - 3, x, y - 4, x, y - 5, x);
  paintFOV(y - 1, x, y - 2, x, y - 3, x + 1, y - 4, x + 1, y - 5, x + 1);
  paintFOV(y - 1, x, y - 2, x + 1, y - 3, x + 1, y - 4, x + 2, y - 4, x + 2);
  paintFOV(y - 1, x + 1, y - 2, x + 2, y - 3, x + 2, y - 3, x + 3, y - 4, x + 3);
  paintFOV(y - 1, x + 1, y - 1, x + 2, y - 2, x + 3, y - 3, x + 4, y - 3, x + 4);
  paintFOV(y, x + 1, y - 1, x + 2, y - 1, x + 3, y - 2, x + 4, y - 2, x + 5);
  paintFOV(y, x + 1, y, x + 2, y - 1, x + 3, y - 1, x + 4, y - 1, x + 5);
  (* Second octant *)
  paintFOV(y, x + 1, y, x + 2, y, x + 3, y, x + 4, y, x + 5);
  paintFOV(y, x + 1, y, x + 2, y + 1, x + 3, y + 1, x + 4, y + 1, x + 5);
  paintFOV(y, x + 1, y + 1, x + 2, y + 1, x + 3, y + 2, x + 4, y + 2, x + 5);
  paintFOV(y + 1, x + 1, y + 2, x + 2, y + 2, x + 3, y + 3, x + 3, y + 3, x + 4);
  paintFOV(y + 1, x + 1, y + 2, x + 1, y + 3, x + 2, y + 4, x + 3, y + 4, x + 3);
  paintFOV(y + 1, x, y + 2, x + 1, y + 3, x + 1, y + 4, x + 2, y + 4, x + 3);
  paintFOV(y + 1, x, y + 2, x, y + 3, x + 1, y + 4, x + 1, y + 5, x + 1);
  (* Third octant *)
  paintFOV(y + 1, x, y + 2, x, y + 3, x, y + 4, x, y + 5, x);
  paintFOV(y + 1, x, y + 2, x, y + 3, x - 1, y + 4, x - 1, y + 5, x - 1);
  paintFOV(y + 1, x, y + 2, x - 1, y + 3, x - 1, y + 4, x - 2, y + 4, x - 3);
  paintFOV(y + 1, x - 1, y + 2, x - 1, y + 3, x - 2, y + 4, x - 3, y + 4, x - 3);
  paintFOV(y + 1, x - 1, y + 2, x - 2, y + 2, x - 3, y + 3, x - 3, y + 3, x - 4);
  paintFOV(y, x - 1, y + 1, x - 2, y + 1, x - 3, y + 2, x - 4, y + 2, x - 5);
  paintFOV(y, x - 1, y, x - 2, y + 1, x - 3, y + 1, x - 4, y + 1, x - 5);
  (* Fourth octant *)
  paintFOV(y, x - 1, y, x - 2, y, x - 3, y, x - 4, y, x - 5);
  paintFOV(y, x - 1, y, x - 2, y - 1, x - 3, y - 1, x - 4, y - 1, x - 5);
  paintFOV(y, x - 1, y - 1, x - 2, y - 1, x - 3, y - 2, x - 4, y - 2, x - 5);
  paintFOV(y - 1, x - 1, y - 1, x - 2, y - 2, x - 3, y - 3, x - 4, y - 3, x - 4);
  paintFOV(y - 1, x - 1, y - 2, x - 2, y - 3, x - 2, y - 3, x - 3, y - 4, x - 3);
  paintFOV(y - 1, x, y - 2, x - 1, y - 3, x - 1, y - 4, x - 2, y - 4, x - 2);
  paintFOV(y - 1, x, y - 2, x, y - 3, x - 1, y - 4, x - 1, y - 5, x - 1);
end;

procedure removeFOV;
var
  r, c: smallint;
begin
  for r := 1 to globalutils.MAXROWS do
  begin
    for c := 1 to globalutils.MAXCOLUMNS do
    begin
      if (maparea[r][c].discovered = True) then
      begin
        drawTile(c, r, 0);
        maparea[r][c].Visible := False;
      end;
    end;
  end;
end;

procedure clearVision;
var
  i: smallint;
begin
  for i := 1 to MAXVISION do
  begin
    visionRadius[i].tileID := i;
    visionRadius[i].inSight := False;
    visionRadius[i].gtx := 0;
    visionRadius[i].gty := 0;
  end;
end;


(* End of FOV functions *)

(* Load tile textures *)
procedure setupTiles;
(* set modulate colour of tiles *)
begin
  (* set scaling quality *)
  SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'nearest');
  // FLOOR
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + 'floor.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  floorTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if floorTexture = nil then
    Halt;
  (* prepare rectangle *)
  floorRect.w := tileSize;
  floorRect.h := tileSize;
  // ROCK
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + 'rock1.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  rockTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if rockTexture = nil then
    Halt;
  (* prepare rectangle *)
  rockRect.w := tileSize;
  rockRect.h := tileSize;
  // 0
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '0.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  aTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if aTexture = nil then
    Halt;
  (* prepare rectangle *)
  aRect.w := tileSize;
  aRect.h := tileSize;
  // 1
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '1.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  bTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if bTexture = nil then
    Halt;
  (* prepare rectangle *)
  bRect.w := tileSize;
  bRect.h := tileSize;
  // 2
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '2.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  cTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if cTexture = nil then
    Halt;
  (* prepare rectangle *)
  cRect.w := tileSize;
  cRect.h := tileSize;
  // 3
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '3.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  dTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if dTexture = nil then
    Halt;
  (* prepare rectangle *)
  dRect.w := tileSize;
  dRect.h := tileSize;
  // 4
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '4.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  eTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if eTexture = nil then
    Halt;
  (* prepare rectangle *)
  eRect.w := tileSize;
  eRect.h := tileSize;
  // 5
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '5.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  fTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if fTexture = nil then
    Halt;
  (* prepare rectangle *)
  fRect.w := tileSize;
  fRect.h := tileSize;
  // 6
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '6.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  gTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if gTexture = nil then
    Halt;
  (* prepare rectangle *)
  gRect.w := tileSize;
  gRect.h := tileSize;
  // 7
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '7.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  hTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if hTexture = nil then
    Halt;
  (* prepare rectangle *)
  hRect.w := tileSize;
  hRect.h := tileSize;
  // 8
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '8.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  iTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if iTexture = nil then
    Halt;
  (* prepare rectangle *)
  iRect.w := tileSize;
  iRect.h := tileSize;
  // 9
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '9.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  jTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if jTexture = nil then
    Halt;
  (* prepare rectangle *)
  jRect.w := tileSize;
  jRect.h := tileSize;
  // 10
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '10.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  kTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if kTexture = nil then
    Halt;
  (* prepare rectangle *)
  kRect.w := tileSize;
  kRect.h := tileSize;
  // 11
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '11.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  lTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if lTexture = nil then
    Halt;
  (* prepare rectangle *)
  lRect.w := tileSize;
  lRect.h := tileSize;
  // 12
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '12.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  mTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if mTexture = nil then
    Halt;
  (* prepare rectangle *)
  mRect.w := tileSize;
  mRect.h := tileSize;
  // 13
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '13.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  nTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if nTexture = nil then
    Halt;
  (* prepare rectangle *)
  nRect.w := tileSize;
  nRect.h := tileSize;
  // 14
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '14.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  oTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if oTexture = nil then
    Halt;
  (* prepare rectangle *)
  oRect.w := tileSize;
  oRect.h := tileSize;
  // 15
  (* create surface from file *)
  main.sdlSurface1 := IMG_Load(imagesFolder + '15.png');
  if main.sdlSurface1 = nil then
    Halt;
  (* load image file *)
  pTexture := SDL_CreateTextureFromSurface(main.sdlRenderer, main.sdlSurface1);
  if pTexture = nil then
    Halt;
  (* prepare rectangle *)
  pRect.w := tileSize;
  pRect.h := tileSize;
end;

(* Each tile drawing procedure is separated below *)

procedure drawFloor(c, r: smallint; hiDef: byte);
begin
  floorRect.x := mapToScreen(c);
  floorRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(floorTexture, maparea[r][c].hiR,
      maparea[r][c].hiG, maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(floorTexture, 69, 73, 74);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @floorRect);
  SDL_RenderCopy(main.sdlRenderer, floorTexture, @floorRect, nil);
  SDL_RenderCopy(sdlRenderer, floorTexture, nil, @floorRect);
end;

procedure drawRock(c, r: smallint; hiDef: byte);
begin
  rockRect.x := mapToScreen(c);
  rockRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(rockTexture, maparea[r][c].hiR,
      maparea[r][c].hiG, maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(rockTexture, maparea[r][c].defR,
      maparea[r][c].defG, maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @rockRect);
  SDL_RenderCopy(main.sdlRenderer, rockTexture, @rockRect, nil);
  SDL_RenderCopy(sdlRenderer, rockTexture, nil, @rockRect);
end;

procedure drawA(c, r: smallint; hiDef: byte);
begin
  aRect.x := mapToScreen(c);
  aRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(aTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(aTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @aRect);
  SDL_RenderCopy(main.sdlRenderer, aTexture, @aRect, nil);
  SDL_RenderCopy(sdlRenderer, aTexture, nil, @aRect);
end;

procedure drawB(c, r: smallint; hiDef: byte);
begin
  bRect.x := mapToScreen(c);
  bRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(bTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(bTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @bRect);
  SDL_RenderCopy(main.sdlRenderer, bTexture, @bRect, nil);
  SDL_RenderCopy(sdlRenderer, bTexture, nil, @bRect);
end;

procedure drawC(c, r: smallint; hiDef: byte);
begin
  cRect.x := mapToScreen(c);
  cRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(cTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(cTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @cRect);
  SDL_RenderCopy(main.sdlRenderer, cTexture, @cRect, nil);
  SDL_RenderCopy(sdlRenderer, cTexture, nil, @cRect);
end;

procedure drawD(c, r: smallint; hiDef: byte);
begin
  dRect.x := mapToScreen(c);
  dRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(dTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(dTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @dRect);
  SDL_RenderCopy(main.sdlRenderer, dTexture, @dRect, nil);
  SDL_RenderCopy(sdlRenderer, dTexture, nil, @dRect);
end;

procedure drawE(c, r: smallint; hiDef: byte);
begin
  eRect.x := mapToScreen(c);
  eRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(eTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(eTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @eRect);
  SDL_RenderCopy(main.sdlRenderer, eTexture, @eRect, nil);
  SDL_RenderCopy(sdlRenderer, eTexture, nil, @eRect);
end;

procedure drawF(c, r: smallint; hiDef: byte);
begin
  fRect.x := mapToScreen(c);
  fRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(fTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(fTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @fRect);
  SDL_RenderCopy(main.sdlRenderer, fTexture, @fRect, nil);
  SDL_RenderCopy(sdlRenderer, fTexture, nil, @fRect);
end;

procedure drawG(c, r: smallint; hiDef: byte);
begin
  gRect.x := mapToScreen(c);
  gRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(gTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(gTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @gRect);
  SDL_RenderCopy(main.sdlRenderer, gTexture, @gRect, nil);
  SDL_RenderCopy(sdlRenderer, gTexture, nil, @gRect);
end;

procedure drawH(c, r: smallint; hiDef: byte);
begin
  hRect.x := mapToScreen(c);
  hRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(hTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(hTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @hRect);
  SDL_RenderCopy(main.sdlRenderer, hTexture, @hRect, nil);
  SDL_RenderCopy(sdlRenderer, hTexture, nil, @hRect);
end;

procedure drawI(c, r: smallint; hiDef: byte);
begin
  iRect.x := mapToScreen(c);
  iRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(iTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(iTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @iRect);
  SDL_RenderCopy(main.sdlRenderer, iTexture, @iRect, nil);
  SDL_RenderCopy(sdlRenderer, iTexture, nil, @iRect);
end;

procedure drawJ(c, r: smallint; hiDef: byte);
begin
  jRect.x := mapToScreen(c);
  jRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(jTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(jTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @jRect);
  SDL_RenderCopy(main.sdlRenderer, jTexture, @jRect, nil);
  SDL_RenderCopy(sdlRenderer, jTexture, nil, @jRect);
end;

procedure drawK(c, r: smallint; hiDef: byte);
begin
  kRect.x := mapToScreen(c);
  kRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(kTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(kTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @kRect);
  SDL_RenderCopy(main.sdlRenderer, kTexture, @kRect, nil);
  SDL_RenderCopy(sdlRenderer, kTexture, nil, @kRect);
end;

procedure drawL(c, r: smallint; hiDef: byte);
begin
  lRect.x := mapToScreen(c);
  lRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(lTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(lTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @lRect);
  SDL_RenderCopy(main.sdlRenderer, lTexture, @lRect, nil);
  SDL_RenderCopy(sdlRenderer, lTexture, nil, @lRect);
end;

procedure drawM(c, r: smallint; hiDef: byte);
begin
  mRect.x := mapToScreen(c);
  mRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(mTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(mTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @mRect);
  SDL_RenderCopy(main.sdlRenderer, mTexture, @mRect, nil);
  SDL_RenderCopy(sdlRenderer, mTexture, nil, @mRect);
end;

procedure drawN(c, r: smallint; hiDef: byte);
begin
  nRect.x := mapToScreen(c);
  nRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(nTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(nTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @nRect);
  SDL_RenderCopy(main.sdlRenderer, nTexture, @nRect, nil);
  SDL_RenderCopy(sdlRenderer, nTexture, nil, @nRect);
end;

procedure drawO(c, r: smallint; hiDef: byte);
begin
  oRect.x := mapToScreen(c);
  oRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(oTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(oTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @oRect);
  SDL_RenderCopy(main.sdlRenderer, oTexture, @oRect, nil);
  SDL_RenderCopy(sdlRenderer, oTexture, nil, @oRect);
end;

procedure drawP(c, r: smallint; hiDef: byte);
begin
  pRect.x := mapToScreen(c);
  pRect.y := mapToScreen(r);
  if (hiDef = 1) then
    SDL_SetTextureColorMod(pTexture, maparea[r][c].hiR, maparea[r][c].hiG,
      maparea[r][c].hiB)
  else
    SDL_SetTextureColorMod(pTexture, maparea[r][c].defR, maparea[r][c].defG,
      maparea[r][c].defB);
  SDL_SetRenderDrawBlendMode(main.sdlRenderer, SDL_BLENDMODE_BLEND);
  SDL_RenderDrawRect(main.sdlRenderer, @pRect);
  SDL_RenderCopy(main.sdlRenderer, pTexture, @pRect, nil);
  SDL_RenderCopy(sdlRenderer, pTexture, nil, @pRect);
end;


(* Place a tile on the map *)
procedure drawTile(c, r: smallint; hiDef: byte);
begin
  case maparea[r][c].glyph of
    '.': drawFloor(c, r, hiDef);
    'A': drawA(c, r, hiDef);
    'B':
    begin
      (* workaround for u shaped tile *)
      if (maparea[r][c - 1].discovered = True) and
        (maparea[r][c + 1].discovered = False) and
        (maparea[r - 1][c].discovered = False) then
        drawN(c, r, hiDef)    // left side visible
      else if (maparea[r][c - 1].discovered = False) and
        (maparea[r][c + 1].discovered = True) and
        (maparea[r - 1][c].discovered = False) then
        drawL(c, r, hiDef)   // right side visible
      else if (maparea[r][c - 1].discovered = True) and
        (maparea[r][c + 1].discovered = False) and
        (maparea[r - 1][c].discovered = True) then
        drawF(c, r, hiDef)   // bottom left side visible
      else if (maparea[r][c - 1].discovered = False) and
        (maparea[r][c + 1].discovered = True) and
        (maparea[r - 1][c].discovered = True) then
        drawD(c, r, hiDef)  // bottom right side visible
      else if (maparea[r][c - 1].discovered = False) and
        (maparea[r][c + 1].discovered = False) and
        (maparea[r - 1][c].discovered = True) then
        drawH(c, r, hiDef)  // bottom visible
      else
        drawB(c, r, hiDef);
    end;
    'C': drawC(c, r, hiDef);
    'D': drawD(c, r, hiDef);
    'E': drawE(c, r, hiDef);
    'F': drawF(c, r, hiDef);
    'G':
    begin
      (* Workaround to stop 2 horizontal lines displaying if only one
      side of the wall is visible *)
      if (maparea[r + 1][c].discovered = False) and
        (maparea[r - 1][c].discovered = True) then
        drawO(c, r, hiDef)
      else if (maparea[r + 1][c].discovered = True) and
        (maparea[r - 1][c].discovered = False) then
        drawH(c, r, hiDef)
      else
        drawG(c, r, hiDef);
    end;
    'H': drawH(c, r, hiDef);
    'I':
    begin
      (* workaround for n shaped tile *)
      if (maparea[r][c - 1].discovered = True) and
        (maparea[r][c + 1].discovered = False) and
        (maparea[r - 1][c].discovered = False) then
        drawN(c, r, hiDef)    // left side visible
      else if (maparea[r][c - 1].discovered = False) and
        (maparea[r][c + 1].discovered = True) and
        (maparea[r - 1][c].discovered = False) then
        drawL(c, r, hiDef)   // right side visible
      else if (maparea[r][c - 1].discovered = True) and
        (maparea[r][c + 1].discovered = False) and
        (maparea[r - 1][c].discovered = True) then
        drawM(c, r, hiDef)   // top left side visible
      else if (maparea[r][c - 1].discovered = False) and
        (maparea[r][c + 1].discovered = True) and
        (maparea[r - 1][c].discovered = True) then
        drawK(c, r, hiDef)  // top right side visible
      else if (maparea[r][c - 1].discovered = False) and
        (maparea[r][c + 1].discovered = False) and
        (maparea[r - 1][c].discovered = True) then
        drawO(c, r, hiDef)  // top visible
      else
        drawI(c, r, hiDef);
    end;
    'J':
    begin
      (* Workaround to stop 2 vertical lines displaying if only one
      side of the wall is visible *)
      if (maparea[r][c + 1].discovered = False) and
        (maparea[r][c - 1].discovered = True) then
        drawN(c, r, hiDef)
      else if (maparea[r][c + 1].discovered = True) and
        (maparea[r][c - 1].discovered = False) then
        drawL(c, r, hiDef)
      else
        drawJ(c, r, hiDef);
    end;
    'K': drawK(c, r, hiDef);
    'L': drawL(c, r, hiDef);
    'M': drawM(c, r, hiDef);
    'N': drawN(c, r, hiDef);
    'O': drawO(c, r, hiDef);
    'P': drawP(c, r, hiDef);
    '#': drawRock(c, r, hiDef);
  end;
end;

(* Loop through tiles and set their ID, visibility etc *)
procedure setupMap;
var
  // give each tile a unique ID number
  id_int: smallint;
begin
  // Generate a dungeon
  cave.generate;
  //dungeon.generate;
  id_int := 0;
  for r := 1 to globalutils.MAXROWS do
  begin
    for c := 1 to globalutils.MAXCOLUMNS do
    begin
      Inc(id_int);
      maparea[r][c].id := id_int;
      maparea[r][c].blocks := True;
      maparea[r][c].Visible := False;
      maparea[r][c].discovered := False;
      maparea[r][c].glyph := globalutils.dungeonArray[r][c];
      maparea[r][c].hiR := 151;
      maparea[r][c].hiG := 222;
      maparea[r][c].hiB := 215;
      maparea[r][c].defR := 120;
      maparea[r][c].defG := 156;
      maparea[r][c].defB := 155;
      if globalutils.dungeonArray[r][c] = '.' then
        maparea[r][c].blocks := False;
    end;
  end;
end;

function player_can_move(checkX, checkY: smallint): boolean;
begin
  Result := False;
  if (maparea[screenToMap(checkY)][screenToMap(checkX)].blocks) = False then
    Result := True;
end;

function mapToScreen(pos: smallint): smallint;
begin
  Result := pos * tileSize;
end;

function screenToMap(pos: smallint): smallint;
begin
  Result := pos div tileSize;
end;

end.
