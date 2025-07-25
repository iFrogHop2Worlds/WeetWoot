unit weewoo;

interface

uses
 System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections, System.Math.Vectors, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Utils;

type
  TWeetWoot = class(TForm)
    GameTimer: TTimer;
    procedure FormCreate(Sender: TObject);

    type
    TPlayer = record
      Rect: TRectangle;
      Velocity: TVector;
      IsOnGround: Boolean;
      CanWallJump: Boolean;
      WallJumpSide: TAlignLayout;
    end;

    type
    TBlock = class
      Rect: TRectangle;
    end;

  private
    FPlayer: TPlayer;
    FBlocks: TObjectList<TBlock>;
    FKeys: TDictionary<Word, Boolean>;
    FGameTime: Single;

    const
      Gravity = 0.5;
      PlayerSpeed = 4.0;
      JumpForce = -12.0;
      WallJumpHorizontalForce = 6.0;
      PanSpeed = 0.2;

    function IsKeyDown(Key: Word): Boolean;

  public
    procedure FormKeyDown(
      Sender: TObject;
      var Key: Word;
      var KeyChar: Char;
      Shift: TShiftState
    );
    procedure FormKeyUp(Sender: TObject;
      var Key: Word;
      var KeyChar: Char;
      Shift: TShiftState
    );
    procedure GameTimerTimer(Sender: TObject);
    procedure UpdatePlayer;
    procedure UpdateBlocks;
    procedure UpdateWorld;
    procedure GameOver(AMessage: string);
  end;

var
  WeetWoot: TWeetWoot;

implementation

{$R *.fmx}

procedure TWeetWoot.FormCreate(Sender: TObject);
begin
  // Initialize keyboard state dictionary
  FKeys := TDictionary<Word, Boolean>.Create;

  // Initialize block list
  FBlocks := TObjectList<TBlock>.Create;

  // Create Player
  FPlayer.Rect := TRectangle.Create(Self);
  FPlayer.Rect.Parent := Self;
  FPlayer.Rect.Fill.Color := TAlphaColors.Black;
  FPlayer.Rect.Width := 20;
  FPlayer.Rect.Height := 20;
  FPlayer.Rect.Position.X := (Self.Width - FPlayer.Rect.Width) / 2;
  FPlayer.Rect.Position.Y := Self.Height - FPlayer.Rect.Height - 50;
  FPlayer.Velocity := TVector.Create(0, 0);
  FPlayer.IsOnGround := False;
  FPlayer.CanWallJump := False;
  FGameTime := 0;

  GameTimer.Enabled := True;

end;

procedure TWeetWoot.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  FKeys.AddOrSetValue(Key, True);
end;

procedure TWeetWoot.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  FKeys.AddOrSetValue(Key, False);
end;

// Helper function to check key state
function TWeetWoot.IsKeyDown(Key: Word): Boolean;
begin
  Result := FKeys.TryGetValue(Key, Result) and Result;
  if Result then
    writeln('Key ' + IntToStr(Key) + ' is DOWN');
end;

procedure TWeetWoot.GameTimerTimer(Sender: TObject);
begin
  writeln('GameTimerTimer fired!'); // Add this
  UpdatePlayer;
  UpdateBlocks;
  UpdateWorld;
   writeln('GameTimerTimer ran al 3 main funcs!'); // Add this
  // The drawing is handled automatically by FMX when we update component positions
end;

procedure TWeetWoot.UpdatePlayer;
var
  NextPos: TRectF;
  CollisionRect: TRectF;
  Block: TBlock;
  CollidedWithWall: Boolean;
begin
  writeln('UpdatePlayer called. Player X: ' + FPlayer.Rect.Position.X.ToString + ', Y: ' + FPlayer.Rect.Position.Y.ToString);
  // --- Horizontal Movement ---
  if IsKeyDown(Ord('A')) then // Left
    FPlayer.Velocity.X := -PlayerSpeed
  else if IsKeyDown(Ord('D')) then // Right
    FPlayer.Velocity.X := PlayerSpeed
  else
    FPlayer.Velocity.X := 0;

  // --- Gravity ---
  if not FPlayer.IsOnGround then
    FPlayer.Velocity.Y := FPlayer.Velocity.Y + Gravity;

  // --- Jumping ---
  if IsKeyDown(Ord('W')) then
  begin
    if FPlayer.IsOnGround then // Normal Jump
    begin
      FPlayer.Velocity.Y := JumpForce;
      FPlayer.IsOnGround := False;
    end
    else if FPlayer.CanWallJump then // Wall Jump
    begin
      FPlayer.Velocity.Y := JumpForce; // Jump up
      if FPlayer.WallJumpSide = TAlignLayout.Left then
        FPlayer.Velocity.X := WallJumpHorizontalForce // Push right
      else
        FPlayer.Velocity.X := -WallJumpHorizontalForce; // Push left
      FPlayer.CanWallJump := False; // Can only wall jump once per touch
    end;
  end;

  // --- Power Drop ---
  if IsKeyDown(Ord('S')) and not FPlayer.IsOnGround then
  begin
    FPlayer.Velocity.Y := FPlayer.Velocity.Y + Gravity * 2; // Extra gravity
  end;

  // Assume no collisions for this frame
  FPlayer.IsOnGround := False;
  FPlayer.CanWallJump := False;
  CollidedWithWall := False;

  // --- Collision Detection ---
  // Check Y-axis collision first
  NextPos := FPlayer.Rect.BoundsRect;
  NextPos.Offset(0, FPlayer.Velocity.Y);

  for Block in FBlocks do
  begin
    if NextPos.IntersectsWith(Block.Rect.BoundsRect) then
    begin
      if FPlayer.Velocity.Y > 0 then // Moving Down
      begin
        FPlayer.IsOnGround := True;
        FPlayer.Velocity.Y := 0;
        FPlayer.Rect.Position.Y := Block.Rect.Position.Y - FPlayer.Rect.Height;
      end
      else if FPlayer.Velocity.Y < 0 then // Moving Up (hit ceiling)
      begin
        FPlayer.Velocity.Y := 0;
        FPlayer.Rect.Position.Y := Block.Rect.Position.Y + Block.Rect.Height;
      end;
      Break;
    end;
  end;

  // Check X-axis collision
  NextPos := FPlayer.Rect.BoundsRect;
  NextPos.Offset(FPlayer.Velocity.X, 0);

  for Block in FBlocks do
  begin
    if NextPos.IntersectsWith(Block.Rect.BoundsRect) then
    begin
      CollidedWithWall := True;
      if FPlayer.Velocity.X > 0 then // Moving right
      begin
        FPlayer.Velocity.X := 0;
        FPlayer.Rect.Position.X := Block.Rect.Position.X - FPlayer.Rect.Width;
        FPlayer.WallJumpSide := TAlignLayout.Left; // Hit the left side of the block
      end
      else if FPlayer.Velocity.X < 0 then // Moving left
      begin
        FPlayer.Velocity.X := 0;
        FPlayer.Rect.Position.X := Block.Rect.Position.X + Block.Rect.Width;
        FPlayer.WallJumpSide := TAlignLayout.Right; // Hit the right side of the block
      end;
      Break;
    end;
  end;

  // A wall-jump is possible if we are touching a wall and not on the ground
  if CollidedWithWall and not FPlayer.IsOnGround then
    FPlayer.CanWallJump := True;

  // --- Final Position Update ---
  FPlayer.Rect.Position.X := FPlayer.Rect.Position.X + FPlayer.Velocity.X;
  FPlayer.Rect.Position.Y := FPlayer.Rect.Position.Y + FPlayer.Velocity.Y;

  // --- Screen Boundaries ---
  if FPlayer.Rect.Position.X < 0 then FPlayer.Rect.Position.X := 0;
  if FPlayer.Rect.Position.X > Self.Width - FPlayer.Rect.Width then
    FPlayer.Rect.Position.X := Self.Width - FPlayer.Rect.Width;

  // --- Game Over Check ---
  if FPlayer.Rect.Position.Y > Self.Height then
    GameOver('You fell out of view!');
end;


procedure TWeetWoot.UpdateBlocks;
var
  i: Integer;
  Block: TBlock;
  Crushed: Boolean;
begin
  Crushed := False;
  // --- Spawn New Blocks ---
  // Spawn a new block every ~60 frames (about once per second)
if RandomRange(0, 60) = 0 then // This will trigger approximately every 61 frames (0-60)
begin
  var NewBlock := TBlock.Create;
  NewBlock.Rect := TRectangle.Create(Self);
  NewBlock.Rect.Parent := Self;
  NewBlock.Rect.Fill.Color := TAlphaColors.Darkgray;
  NewBlock.Rect.Width := RandomRange(60, 120); // Using RandomRange here as well
  NewBlock.Rect.Height := 20;
  NewBlock.Rect.Position.X := RandomRange(0, Round(Self.Width - NewBlock.Rect.Width));
  NewBlock.Rect.Position.Y := -NewBlock.Rect.Height; // Start just off-screen
  FBlocks.Add(NewBlock);
end;

  // --- Update Existing Blocks ---
  for i := FBlocks.Count - 1 downto 0 do
  begin
    Block := FBlocks[i];
    // Blocks fall down
    Block.Rect.Position.Y := Block.Rect.Position.Y + 2;

    // Check for collision with player (crush)
    if FPlayer.Rect.BoundsRect.IntersectsWith(Block.Rect.BoundsRect) and
       (FPlayer.Rect.Position.Y > Block.Rect.Position.Y) then
    begin
        Crushed := True;
    end;

    // Remove blocks that go off the bottom of the screen
    if Block.Rect.Position.Y > Self.Height then
    begin
      Block.Rect.Free;
      FBlocks.Delete(i);
    end;
  end;

  if Crushed then
    GameOver('You were crushed!');
end;

procedure TWeetWoot.UpdateWorld;
var
  Block: TBlock;
  lerpFactor: Single;
begin
  // --- Pan the View ---
  // Move the player and all blocks down to simulate the camera moving up
  FPlayer.Rect.Position.Y := FPlayer.Rect.Position.Y + PanSpeed;
  for Block in FBlocks do
  begin
    Block.Rect.Position.Y := Block.Rect.Position.Y + PanSpeed;
  end;

  // --- Update Background ---
//  FGameTime := FGameTime + GameTimer.Interval / 1000.0;
//  // Slowly transition from white to dark gray over 120 seconds
//  lerpFactor := Min(FGameTime / 120.0, 1.0);
  Self.Fill.Color := TAlphaColorRec.Whitesmoke; // (TAlphaColors.White, TAlphaColors.Dimgray, lerpFactor);
end;

procedure TWeetWoot.GameOver(AMessage: string);
begin
  GameTimer.Enabled := False;
  ShowMessage(AMessage + #13#10 + 'Click OK to close.');
  Application.Terminate;
end;

end.
