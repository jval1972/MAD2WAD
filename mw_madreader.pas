//------------------------------------------------------------------------------
//
//  MAD2WAD - Create a Doom WAD file from Mars, Hero or Tao MAD files
//
//  Copyright (C) 2021 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  WAD/MAD reader
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

unit mw_madreader;

interface

uses
  SysUtils,
  Classes,
  mw_types;

type
  TMADReader = class
  private
    h: wadinfo_t;
    la: Pfilelump_tArray;
    fs: TFileStream;
    ffilename: string;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure OpenWadFile(const aname: string);
    function EntryAsString(const id: integer): string; overload;
    function EntryAsString(const aname: string): string; overload;
    function ReadEntry(const id: integer; var buf: pointer; var bufsize: integer): boolean; overload;
    function ReadEntry(const aname: string; var buf: pointer; var bufsize: integer): boolean; overload;
    function EntryName(const id: integer): string;
    function EntryId(const aname: string): integer;
    function EntryInfo(const id: integer): Pfilelump_t; overload;
    function EntryInfo(const aname: string): Pfilelump_t; overload;
    function NumEntries: integer;
    function FileSize: integer;
    property FileName: string read ffilename;
    property Header: wadinfo_t read h;
  end;

implementation

constructor TMADReader.Create;
begin
  h.identification := 0;
  h.numlumps := 0;
  h.infotableofs := 0;
  la := nil;
  fs := nil;
  ffilename := '';
  Inherited;
end;

destructor TMADReader.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TMADReader.Clear;
begin
  if h.numlumps > 0 then
  begin
    FreeMem(la, h.numlumps * SizeOf(filelump_t));
    h.identification := 0;
    h.numlumps := 0;
    h.infotableofs := 0;
    la := nil;
    ffilename := '';
  end
  else
  begin
    h.identification := 0;
    h.infotableofs := 0;
  end;
  if fs <> nil then
  begin
    fs.Free;
    fs := nil;
  end;
end;

procedure TMADReader.OpenWadFile(const aname: string);
var
  madbuf: packed array[0..19] of byte;
  ismad: boolean;
  smad: string;
  pb: PByteArray;
  i: integer;
begin
  if aname = '' then
    Exit;
  {$IFDEF DEBUG}
  print('Opening WAD file ' + aname + #13#10);
  {$ENDIF}
  Clear;
  fs := TFileStream.Create(aname, fmOpenRead or fmShareDenyWrite);

  ismad := false;

  fs.Read(madbuf, SizeOf(madbuf));
  smad := '';
  for i := 0 to Length(MAD1) - 1 do
    smad := smad + Char(madbuf[i]);
  if smad = MAD1 then
  begin
    ismad := true;
    fs.Seek(8, soBeginning);
  end
  else
  begin
    smad := '';
    for i := 0 to Length(MAD2) - 1 do
      smad := smad + Char(madbuf[i]);
    if smad = MAD2 then
    begin
      ismad := true;
      fs.Seek(20, soBeginning);
    end;
  end;

  if not ismad then
  begin
    fs.Seek(0, soBeginning);
    fs.Read(h, SizeOf(wadinfo_t));
  end
  else
  begin
    h.identification := IMAD;
    fs.Read(h.numlumps, SizeOf(integer));
    fs.Read(h.infotableofs, SizeOf(integer));
  end;

  if (h.numlumps > 0) and (h.infotableofs < fs.Size) and ((h.identification = IWAD) or (h.identification = PWAD) or (h.identification = IMAD)) then
  begin
    fs.Seek(h.infotableofs, soBeginning);
    la := GetMemory(h.numlumps * SizeOf(filelump_t));
    fs.Read(la^, h.numlumps * SizeOf(filelump_t));
    if ismad then
    begin
      pb := PByteArray(la);
      for i := 0 to h.numlumps * SizeOf(filelump_t) - 1 do
        pb[i] := pb[i] - 48;
    end;
    ffilename := aname;
  end
  else
    Raise Exception.Create('Invalid MAD/WAD file ' + aname);
end;

function TMADReader.EntryAsString(const id: integer): string;
begin
  if (fs <> nil) and (id >= 0) and (id < h.numlumps) then
  begin
    SetLength(Result, la[id].size);
    fs.Seek(la[id].filepos, soBeginning);
    fs.Read((@Result[1])^, la[id].size);
  end
  else
    Result := '';
end;

function TMADReader.EntryAsString(const aname: string): string;
var
  id: integer;
begin
  id := EntryId(aname);
  if id >= 0 then
    Result := EntryAsString(id)
  else
    Result := '';
end;

function TMADReader.ReadEntry(const id: integer; var buf: pointer; var bufsize: integer): boolean;
begin
  if (fs <> nil) and (id >= 0) and (id < h.numlumps) then
  begin
    fs.Seek(la[id].filepos, soBeginning);
    bufsize := la[id].size;
    buf := GetMemory(bufsize);
    fs.Read(buf^, bufsize);
    Result := true;
  end
  else
    Result := false;
end;

function TMADReader.ReadEntry(const aname: string; var buf: pointer; var bufsize: integer): boolean; 
var
  id: integer;
begin
  id := EntryId(aname);
  if id >= 0 then
    Result := ReadEntry(id, buf, bufsize)
  else
    Result := false;
end;

function TMADReader.EntryName(const id: integer): string;
begin
  if (id >= 0) and (id < h.numlumps) then
    Result := char8tostring(la[id].name)
  else
    Result := '';
end;

function TMADReader.EntryId(const aname: string): integer;
var
  i: integer;
  uname: string;
begin
  uname := UpperCase(aname);
  for i := h.numlumps - 1 downto 0 do
    if char8tostring(la[i].name) = uname then
    begin
      Result := i;
      Exit;
    end;
  Result := -1;
end;

function TMADReader.EntryInfo(const id: integer): Pfilelump_t;
begin
  if (id >= 0) and (id < h.numlumps) then
    Result := @la[id]
  else
    Result := nil;
end;

function TMADReader.EntryInfo(const aname: string): Pfilelump_t;
begin
  result := EntryInfo(EntryId(aname));
end;

function TMADReader.NumEntries: integer;
begin
  Result := h.numlumps;
end;

function TMADReader.FileSize: integer;
begin
  if fs <> nil then
    Result := fs.Size
  else
    Result := 0;
end;

end.
