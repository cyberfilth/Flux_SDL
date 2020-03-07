(* Generates a cave with a grid-based dungeon superimposed over the top *)

unit cave;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, globalutils, map;

type
  coordinates = record
    x, y: smallint;
  end;

var
  r, c, i, p, t, listLength, firstHalf, lastHalf, iterations, tileCounter: smallint;
  caveArray, tempArray: array[1..globalutils.MAXROWS, 1..globalutils.MAXCOLUMNS] of char;
  totalRooms, roomSquare: smallint;
  (* Player starting position *)
  startX, startY: smallint;
  (* start creating corridors once this rises above 1 *)
  roomCounter: smallint;
  (* list of coordinates of centre of each room *)
  centreList: array of coordinates;
  (* TESTING - Write dungeon to text file *)
  filename:ShortString;
  myfile: text;

(* Carve a horizontal tunnel *)
procedure carveHorizontally(x1, x2, y: smallint);
(* Carve a vertical tunnel *)
procedure carveVertically(y1, y2, x: smallint);
(* Create a room *)
procedure createRoom(gridNumber: smallint);
(* Generate a dungeon *)
procedure generate;
(* sort room list in order from left to right *)
procedure leftToRight;

implementation

procedure leftToRight;
var
  i, j, n, tempX, tempY: smallint;
begin
  n := length(centreList) - 1;
  for i := n downto 2 do
    for j := 0 to i - 1 do
      if centreList[j].x > centreList[j + 1].x then
      begin
        tempX := centreList[j].x;
        tempY := centreList[j].y;
        centreList[j].x := centreList[j + 1].x;
        centreList[j].y := centreList[j + 1].y;
        centreList[j + 1].x := tempX;
        centreList[j + 1].y := tempY;
      end;
end;

procedure carveHorizontally(x1, x2, y: smallint);
var
  x: byte;
begin
  if x1 < x2 then
  begin
    for x := x1 to x2 do
      caveArray[y][x] := '.';
  end;
  if x1 > x2 then
  begin
    for x := x2 to x1 do
      caveArray[y][x] := '.';
  end;
end;

procedure carveVertically(y1, y2, x: smallint);
var
  y: byte;
begin
  if y1 < y2 then
  begin
    for y := y1 to y2 do
      caveArray[y][x] := '.';
  end;
  if y1 > y2 then
  begin
    for y := y2 to y1 do
      caveArray[y][x] := '.';
  end;
end;

procedure createCorridor(fromX, fromY, toX, toY: smallint);
var
  direction: byte;
begin
  // flip a coin to decide whether to first go horizontally or vertically
  direction := Random(2);
  // horizontally first
  if direction = 1 then
  begin
    carveHorizontally(fromX, toX, fromY);
    carveVertically(fromY, toY, toX);
  end
  // vertically first
  else
  begin
    carveVertically(fromY, toY, toX);
    carveHorizontally(fromX, toX, fromY);
  end;
end;

procedure createRoom(gridNumber: smallint);
var
  topLeftX, topLeftY, roomHeight, roomWidth, drawHeight, drawWidth,
  nudgeDown, nudgeAcross: smallint;
begin
  // row 1
  if (gridNumber >= 1) and (gridNumber <= 13) then
  begin
    topLeftX := (gridNumber * 5) - 3;
    topLeftY := 2;
  end;
  // row 2
  if (gridNumber >= 14) and (gridNumber <= 26) then
  begin
    topLeftX := (gridNumber * 5) - 68;
    topLeftY := 8;
  end;
  // row 3
  if (gridNumber >= 27) and (gridNumber <= 39) then
  begin
    topLeftX := (gridNumber * 5) - 133;
    topLeftY := 14;
  end;
  // row 4
  if (gridNumber >= 40) and (gridNumber <= 52) then
  begin
    topLeftX := (gridNumber * 5) - 198;
    topLeftY := 20;
  end;
  // row 5
  if (gridNumber >= 53) and (gridNumber <= 65) then
  begin
    topLeftX := (gridNumber * 5) - 263;
    topLeftY := 26;
  end;
  // row 6
  if (gridNumber >= 66) and (gridNumber <= 78) then
  begin
    topLeftX := (gridNumber * 5) - 328;
    topLeftY := 32;
  end;
  (* Randomly select room dimensions between 2 - 5 tiles in height / width *)
  roomHeight := Random(2) + 3;
  roomWidth := Random(2) + 3;
  (* Change starting point of each room so they don't all start
     drawing from the top left corner                           *)
  case roomHeight of
    2: nudgeDown := Random(0) + 2;
    3: nudgeDown := Random(0) + 1;
    else
      nudgeDown := 0;
  end;
  case roomWidth of
    2: nudgeAcross := Random(0) + 2;
    3: nudgeAcross := Random(0) + 1;
    else
      nudgeAcross := 0;
  end;
  (* Save coordinates of the centre of the room *)
  listLength := Length(centreList);
  SetLength(centreList, listLength + 1);
  centreList[listLength].x := (topLeftX + nudgeAcross) + (roomWidth div 2);
  centreList[listLength].y := (topLeftY + nudgeDown) + (roomHeight div 2);
  (* Draw room within the grid square *)
  for drawHeight := 0 to roomHeight do
  begin
    for drawWidth := 0 to roomWidth do
    begin
      caveArray[(topLeftY + nudgeDown) + drawHeight][(topLeftX + nudgeAcross) +
        drawWidth] := '.';
    end;
  end;
end;

procedure generate;
begin
  roomCounter := 0;
  // initialise the array
  SetLength(centreList, 1);
  // fill map with walls
  for r := 1 to globalutils.MAXROWS do
  begin
    for c := 1 to globalutils.MAXCOLUMNS do
    begin
      caveArray[r][c] := '#';
    end;
  end;

  for r := 2 to (globalutils.MAXROWS - 1) do
  begin
    for c := 2 to (globalutils.MAXCOLUMNS - 1) do
    begin
      (* 50% chance of drawing a wall tile *)
      if (Random(100) <= 50) then
        caveArray[r][c] := '#'
      else
        caveArray[r][c] := '.';
    end;
  end;
  (* Run through the process 5 times *)
  for iterations := 1 to 5 do
  begin
    for r := 2 to globalutils.MAXROWS - 1 do
    begin
      for c := 2 to globalutils.MAXCOLUMNS - 1 do
      begin
      (* A tile becomes a wall if it was a wall and 4 or more of its 8
      neighbours are walls, or if it was not but 5 or more neighbours were *)
        tileCounter := 0;
        if (caveArray[r - 1][c] = '#') then // NORTH
          Inc(tileCounter);
        if (caveArray[r - 1][c + 1] = '#') then // NORTH EAST
          Inc(tileCounter);
        if (caveArray[r][c + 1] = '#') then // EAST
          Inc(tileCounter);
        if (caveArray[r + 1][c + 1] = '#') then // SOUTH EAST
          Inc(tileCounter);
        if (caveArray[r + 1][c] = '#') then // SOUTH
          Inc(tileCounter);
        if (caveArray[r + 1][c - 1] = '#') then // SOUTH WEST
          Inc(tileCounter);
        if (caveArray[r][c - 1] = '#') then // WEST
          Inc(tileCounter);
        if (caveArray[r - 1][c - 1] = '#') then // NORTH WEST
          Inc(tileCounter);
        (* Set tiles in temporary array *)
        if (caveArray[r][c] = '#') then
        begin
          if (tileCounter >= 4) then
            tempArray[r][c] := '#'
          else
            tempArray[r][c] := '.';
        end;
        if (caveArray[r][c] = '.') then
        begin
          if (tileCounter >= 5) then
            tempArray[r][c] := '#'
          else
            tempArray[r][c] := '.';
        end;
      end;
    end;
    (* draw top and bottom border *)
    for i := 1 to globalutils.MAXCOLUMNS do
    begin
      tempArray[1][i] := '#';
      tempArray[globalutils.MAXROWS][i] := '#';
    end;
    (* draw left and right border *)
    for i := 1 to globalutils.MAXROWS do
    begin
      tempArray[i][1] := '#';
      tempArray[i][globalutils.MAXCOLUMNS] := '#';
    end;

    (* Copy temporary map back to main dungeon map array *)
    for r := 1 to globalutils.MAXROWS do
    begin
      for c := 1 to globalutils.MAXCOLUMNS do
      begin
        caveArray[r][c] := tempArray[r][c];
      end;
    end;
  end;
  // Random(Range End - Range Start) + Range Start;
  totalRooms := Random(5) + 10; // between 10 - 15 rooms
  for i := 1 to totalRooms do
  begin
    // randomly choose grid location from 1 to 78
    roomSquare := Random(77) + 1;
    createRoom(roomSquare);
    Inc(roomCounter);
  end;
  leftToRight();
  for i := 1 to (totalRooms - 1) do
  begin
    createCorridor(centreList[i].x, centreList[i].y, centreList[i + 1].x,
      centreList[i + 1].y);
  end;
  // connect random rooms so the map isn't totally linear
  // from the first half of the room list
  firstHalf := (totalRooms div 2);
  p := random(firstHalf - 1) + 1;
  t := random(firstHalf - 1) + 1;
  createCorridor(centreList[p].x, centreList[p].y, centreList[t].x,
    centreList[t].y);
  // from the second half of the room list
  lastHalf := (totalRooms - firstHalf);
  p := random(lastHalf) + firstHalf;
  t := random(lastHalf) + firstHalf;
  createCorridor(centreList[p].x, centreList[p].y, centreList[t].x,
    centreList[t].y);
  // set player start coordinates
  map.startX := centreList[1].x;
  map.startY := centreList[1].y;


  /////////////////////////////
  // Write map to text file for testing
  filename:='output_cave.txt';
  AssignFile(myfile, filename);
   rewrite(myfile);
   for r := 1 to MAXROWS do
  begin
    for c := 1 to MAXCOLUMNS do
    begin
   write(myfile,caveArray[r][c]);
   end;
    write(myfile, sLineBreak);
    end;
   closeFile(myfile);
  //////////////////////////////


  // Copy array to main dungeon
  for r := 1 to globalutils.MAXROWS do
  begin
    for c := 1 to globalutils.MAXCOLUMNS do
    begin
      globalutils.dungeonArray[r][c] := caveArray[r][c];
    end;
  end;
end;

end.
