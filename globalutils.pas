(* Common functions / utilities *)

unit globalutils;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

const
  (* Columns of the game map *)
  MAXCOLUMNS = 67;
  (* Rows of the game map *)
  MAXROWS = 38;

var
  dungeonArray: array[1..MAXROWS, 1..MAXCOLUMNS] of char;

(* Select random number from a range *)
function randomRange(fromNumber, toNumber: smallint): smallint;

implementation

// Random(Range End - Range Start) + Range Start
function randomRange(fromNumber, toNumber: smallint): smallint;
var
  p: smallint;
begin
  p := toNumber - fromNumber;
  Result := random(p + 1) + fromNumber;
end;

end.

