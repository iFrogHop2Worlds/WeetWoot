unit ClockLabel2;

interface

uses
  System.SysUtils, System.Classes, FMX.Types, FMX.Controls,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
TClockLabel = class(TLabel)
private
  FFormat: String;
  FTimer: TTimer;
  procedure OnTimer(Sender: TObject);
  procedure SetFormat(const Value: String);
  procedure UpdateLabel;

public
  constructor Create(AOwner: TComponent); override;
  destructor Destroy; override;

published
  property Format: String read FFormat write SetFormat;

end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', []);
end;

{ TClockLabel }

constructor TClockLabel.Create(AOwner: TComponent);
begin
  FFormat := 'c';
  inherited;

  // No need to use TTimercompoment at design time.
  if not (csDesigning in ComponentState) then
  begin
    FTimer := TTimer.Create(Self);
    FTimer.OnTimer := OnTimer;
    FTimer.Interval := 1000;
    FTimer.Enabled := True;
  end;

  UpdateLabel;
end;

procedure TClockLabel.UpdateLabel;
begin
  Text := FormatDateTime(FFormat, Now);
end;

destructor TClockLabel.Destroy;
begin
  FreeAndNil(FTimer);
  inherited;
end;

procedure TClockLabel.OnTimer(Sender: TObject);
begin
  UpdateLabel;
end;

procedure TClockLabel.SetFormat(const Value: String);
begin
  FFormat := Value;
  UpdateLabel;
end;

//function TMyButton.GetDefaultStyleLookupName: string;
//begin
//  Result := Self.GetParentClassStyleLookupName; // stylename of the parent component
//end;
end.
