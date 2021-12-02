program MAD2WAD;

uses
  Forms,
  main in 'main.pas' {Form1},
  mw_madreader in 'mw_madreader.pas',
  mw_types in 'mw_types.pas',
  mw_wadwriter in 'mw_wadwriter.pas',
  mw_palette in 'mw_palette.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'MARS2MAD';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
