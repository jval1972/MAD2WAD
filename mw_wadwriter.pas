//------------------------------------------------------------------------------
//
//  MAD2WAD - Create a Doom WAD file from Mars, Hero or Tao MAD files
//
//  Copyright (C) 2021-2022 by Jim Valavanis
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
//  MAD writer
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

unit mw_wadwriter;

interface

uses
  SysUtils,
  Classes;

type
  TWadWriter = class(TObject)
  private
    lumps: TStringList;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure AddData(const lumpname: string; const data: pointer; const size: integer);
    procedure AddFile(const lumpname: string; const fname: string);
    procedure AddString(const lumpname: string; const data: string);
    procedure AddSeparator(const lumpname: string);
    procedure SaveToStream(const strm: TStream);
    procedure SaveToFile(const fname: string);
  end;

function AddDataToWAD(const wad: TWADWriter; const lumpname, data: string): boolean;

implementation

uses
  mw_types;

constructor TWadWriter.Create;
begin
  lumps := TStringList.Create;
  Inherited;
end;

destructor TWadWriter.Destroy;
var
  i: integer;
begin
  for i := 0 to lumps.Count - 1 do
    if lumps.Objects[i] <> nil then
      lumps.Objects[i].Free;
  lumps.Free;
  Inherited;
end;

procedure TWadWriter.Clear;
var
  i: integer;
begin
  for i := 0 to lumps.Count - 1 do
    if lumps.Objects[i] <> nil then
      lumps.Objects[i].Free;
  lumps.Clear;
end;

procedure TWadWriter.AddData(const lumpname: string; const data: pointer; const size: integer);
var
  m: TMemoryStream;
begin
  if (data = nil) or (size = 0) then
    AddSeparator(lumpname)
  else
  begin
    m := TMemoryStream.Create;
    m.Write(data^, size);
    lumps.AddObject(UpperCase(lumpname), m);
  end;
end;

procedure TWadWriter.AddFile(const lumpname: string; const fname: string);
var
  m: TMemoryStream;
  f: TFileStream;
  buf: array[0..8191] of byte;
  numread: integer;
begin
  if FileExists(fname) then
  begin
    f := TFileStream.Create(fname, fmOpenRead);
    if f.Size = 0 then
    begin
      AddSeparator(lumpname);
      f.Free;
      exit;
    end;
    m := TMemoryStream.Create;
    repeat
      numread := f.Read(buf, SizeOf(buf));
      if numread > 0 then
        m.Write(buf, numread);
    until numread <= 0;
    lumps.AddObject(UpperCase(lumpname), m);
    f.Free;
  end
  else
    AddSeparator(lumpname);
end;

procedure TWadWriter.AddString(const lumpname: string; const data: string);
var
  m: TMemoryStream;
  i: integer;
begin
  m := TMemoryStream.Create;
  for i := 1 to Length(data) do
    m.Write(data[i], SizeOf(char));
  lumps.AddObject(UpperCase(lumpname), m);
end;

procedure TWadWriter.AddSeparator(const lumpname: string);
begin
  lumps.Add(UpperCase(lumpname));
end;

procedure TWadWriter.SaveToStream(const strm: TStream);
var
  h: wadinfo_t;
  la: Pfilelump_tArray;
  i: integer;
  p, ssize: integer;
  m: TMemoryStream;
begin
  p := strm.Position;
  h.identification := PWAD;
  h.numlumps := lumps.Count;
  h.infotableofs := p + SizeOf(wadinfo_t);
  strm.Write(h, SizeOf(h));
  p := strm.Position;
  GetMem(la, lumps.Count * SizeOf(filelump_t));
  strm.Write(la^, lumps.Count * SizeOf(filelump_t));

  for i := 0 to lumps.Count - 1 do
  begin
    la[i].filepos := strm.Position;
    m := lumps.Objects[i] as TMemoryStream;
    if m <> nil then
    begin
      la[i].size := m.Size;
      m.Seek(0, soBeginning);
      strm.Write(m.Memory^, m.Size);
    end
    else
      la[i].size := 0;
    la[i].name := stringtochar8(lumps.Strings[i]);
  end;
  ssize := strm.Position;
  strm.Seek(p, soBeginning);
  strm.Write(la^, lumps.Count * SizeOf(filelump_t));
  FreeMem(la, lumps.Count * SizeOf(filelump_t));
  strm.Seek(ssize, soBeginning);
end;

procedure TWadWriter.SaveToFile(const fname: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(fname, fmCreate);
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end;

function AddDataToWAD(const wad: TWADWriter; const lumpname, data: string): boolean;
begin
  if wad <> nil then
  begin
    wad.AddString(lumpname, data);
    Result := True;
  end
  else
    Result := False;
end;

end.

