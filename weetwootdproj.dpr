program weetwootdproj;

uses
  System.StartUpCopy,
  FMX.Forms,
  weewoo in 'weewoo.pas' {WeetWoot};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TWeetWoot, WeetWoot);
  Application.Run;
end.
