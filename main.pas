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
//  Main form
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/mars3d/
//------------------------------------------------------------------------------

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Panel2: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Panel3: TPanel;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
  private
    { Private declarations }
    finpfilename: string;
    foutfilename: string;
    procedure DoConvert;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  mw_madreader,
  mw_wadwriter;

procedure println(const s: string);
begin
  Form1.Memo1.Lines.Add(s);
  if Form1.Memo1.Lines.Count > 200 then
    Form1.Memo1.Lines.Delete(0);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  finpfilename := '';
  foutfilename := '';
  BitBtn2.Enabled := false;
  BitBtn3.Enabled := false;
  Edit1.Text := '';
  Edit2.Text := '';
  Memo1.Lines.Clear;
  println('MAD2WAD v1.0, (c) 2021 by Jim Valavanis');
  println('Use this tool to convert MAD files (Mars/Hero/Tao) to the Doom WADs.');
  println('');
  println('For updates please visit https://sourceforge.net/projects/mars3d/');
  println('');
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;
    finpfilename := OpenDialog1.FileName;
    println('Input file: ' + finpfilename);
    BitBtn2.Enabled := true;
  end;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    Edit2.Text := SaveDialog1.FileName;
    foutfilename := SaveDialog1.FileName;
    println('Output file: ' + foutfilename);
    BitBtn3.Enabled := true;
    BitBtn3Click(Sender);
  end;
end;

function CopyFile(const sname, dname: string): boolean;
var
  FromF, ToF: file;
  NumRead, NumWritten: Integer;
  Buf: array[1..8192] of Char;
begin
  if FileExists(sname) then
  begin
    AssignFile(FromF, sname);
    Reset(FromF, 1);
    AssignFile(ToF, dname);
    Rewrite(ToF, 1);
    repeat
      BlockRead(FromF, Buf, SizeOf(Buf), NumRead);
      BlockWrite(ToF, Buf, NumRead, NumWritten);
    until (NumRead = 0) or (NumWritten <> NumRead);
    CloseFile(FromF);
    CloseFile(ToF);
    Result := True;
  end
  else
    Result := False;
end;

procedure BackupFile(const fname: string);
var
  fbck: string;
begin
  if not FileExists(fname) then
    Exit;
  fbck := fname + '_bak';
  CopyFile(fname, fbck);
end;

procedure TForm1.DoConvert;
var
  mad: TMADReader;
  wad: TWadWriter;
  i: integer;
  path: string;

  procedure _AddFile(const lumpname: string; const fname: string);
  begin
    if FileExists(path + fname) then
      wad.AddFile(lumpname, path + fname)
    else if FileExists(path + 'INSTALL\' + fname) then
      wad.AddFile(lumpname, path + 'INSTALL\' + fname);
  end;

begin
  mad := TMADReader.Create;
  wad := TWadWriter.Create;

  try
    mad.OpenWadFile(finpfilename);

    path := ExtractFilePath(finpfilename);
    _AddFile('PALETTE', 'GAME.PAL');

    for i := 0 to mad.NumEntries - 1 do
      wad.AddString(mad.EntryName(i), mad.EntryAsString(i));

    wad.SaveToFile(foutfilename);
  finally
    mad.Free;
    wad.Free;
  end;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  finpfilename := Trim(finpfilename);
  if finpfilename = '' then
  begin
    println('Please select input file!');
    exit;
  end;

  if not FileExists(finpfilename) then
  begin
    println('Input file "' + finpfilename + '" does not exist!');
    exit;
  end;

  foutfilename := Trim(foutfilename);
  if foutfilename = '' then
  begin
    println('Please select output file!');
    exit;
  end;

  if UpperCase(ExpandFileName(foutfilename)) = UpperCase(ExpandFileName(finpfilename)) then
  begin
    println('Input and output file must be different!');
    exit;
  end;

  if FileExists(foutfilename) then
  begin
    println('Backup ' + ExtractFileName(foutfilename));
    BackupFile(foutfilename);
  end;

  println('Converting ' + ExtractFileName(finpfilename) + ' to ' + ExtractFileName(foutfilename));

  Screen.Cursor := crHourglass;
  try
    DoConvert;
  finally
    Screen.Cursor := crDefault;
  end;

  MessageBeep(0);
  if FileExists(foutfilename) then
    println('Conversion finished!')
  else
    println('Conversion failed!')
end;

end.
