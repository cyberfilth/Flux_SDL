(* NPC stats and initialisation *)

unit entities;

{$mode objfpc}{$H+}
{$ModeSwitch advancedrecords}

interface

uses
  SDL2, SysUtils, map, dungeon, globalutils;

type
  (* Store information about NPC's *)
  Creature = record
    (* Unique ID *)
    npcID: smallint;
    (* Creature type *)
    race: shortstring;
    (* health and position on game map *)
    currentHP, maxHP, attack, defense, posX, posY: smallint;
    (* Character used to represent NPC on game map *)
    glyph: char;
    (* Colour of character on screen *)
    glyphR, glyphG, glyphB: byte;
    (* Is the NPC in the players FoV *)
    inView: boolean;
    (* Has the NPC been killed, to be removed at end of game loop *)
    isDead: boolean;
  end;

var
  entityList: array of Creature;
  npcAmount, listLength: smallint;

(* Generate list of creatures on the map *)
procedure spawnNPC;
(* Move NPC's *)
procedure moveNPC(id, newX, newY: smallint);

implementation

procedure spawnNPC;
var
  i, p, r: smallint;
begin
  // get number of NPCs
  npcAmount := (dungeon.totalRooms - 2) div 2;

end;

procedure moveNPC(id, newX, newY: smallint);
begin

end;

end.

