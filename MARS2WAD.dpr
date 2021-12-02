program MARS2WAD;

uses
  Forms,
  main in 'main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'MARS2MAD';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
