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
  (* Colours - Highlight and default colours *)
  // Orange
  ORANGEhiR = 213;
  ORANGEhiG = 97;
  ORANGEhiB = 0;
  ORANGEdefR = 174;
  ORANGEdefG = 79;
  ORANGEdefB = 0;
  ORANGEdarkR = 132;
  ORANGEdarkG = 60;
  ORANGEdarkB = 0;
  // Teal
  TEALhiR = 151;
  TEALhiG = 222;
  TEALhiB = 215;
  TEALdefR = 0;
  TEALdefG = 104;
  TEALdefB = 104;
  TEALdarkR = 0;
  TEALdarkG = 79;
  TEALdarkB = 79;

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
