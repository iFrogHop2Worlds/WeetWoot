unit weewoo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections, System.Math.Vectors, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Utils, Winapi.Windows, FMX.Ani;

type
  TWeetWoot = class(TForm)
    GameTimer: TTimer;
    ScoreText: TText;
    GradientAnimation1: TGradientAnimation;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure GameTimerTimer(Sender: TObject);
    //procedure ScoreTextClick(Sender: TObject);

    type
      TPlayer = record
        Rect: TRectangle;
        Velocity: TVector;
        IsOnGround: Boolean;
        CanJump: TDateTime;
        CanWallJump: Boolean;
        WallJumpSide: TAlignLayout;
      end;

      TBlock = class
        Rect: TRectangle;
        VelocityY: Single;
        IsGroundBlock: Boolean;
      end;


  private
    FPlayer: TPlayer;
    FBlocks: TObjectList<TBlock>;
    FKeys: TDictionary<Word, Boolean>;
    FGameTime: Single;
    FScore: Integer;
    FStartTime: Single;
    FSpawnRangeTimer: Integer;
    FPanSpeed: Double;
    const
      Gravity = 0.2;
      PlayerSpeed = 5.0;
      JumpForce = -9.0;
      WallJumpHorizontalForce = 25.0;
      BlockInitialFallSpeed = 0.02;

    function IsKeyDown(Key: Word): Boolean;
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
var
  GroundBlock: TBlock;
begin
  FKeys := TDictionary<Word, Boolean>.Create;
  FBlocks := TObjectList<TBlock>.Create;
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
  FSpawnRangeTimer := 16;
  FPanSpeed := 0;


  // --- Create Ground Block ---
  GroundBlock := TBlock.Create;
  GroundBlock.Rect := TRectangle.Create(Self);
  GroundBlock.Rect.Parent := Self;
  GroundBlock.Rect.Fill.Color := TAlphaColors.Whitesmoke;
  GroundBlock.Rect.Width := Self.Width;
  GroundBlock.Rect.Height := 50;
  GroundBlock.Rect.Position.X := 0;
  GroundBlock.Rect.Position.Y := Self.Height - GroundBlock.Rect.Height;
  GroundBlock.VelocityY := 0;
  GroundBlock.IsGroundBlock := True;
  FBlocks.Add(GroundBlock);

  GameTimer.OnTimer := GameTimerTimer;
  GameTimer.Interval := 18;
  GameTimer.Enabled := True;

end;

procedure TWeetWoot.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  FKeys.AddOrSetValue(Key, True);
  OutputDebugString(PChar('Key Down: ' + IntToStr(Key) + #13#10));
end;

procedure TWeetWoot.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  FKeys.AddOrSetValue(Key, False);
  OutputDebugString(PChar('Key Up: ' + IntToStr(Key) + #13#10));
end;

function TWeetWoot.IsKeyDown(Key: Word): Boolean;
begin
  Result := FKeys.TryGetValue(Key, Result) and Result;
end;

//procedure TWeetWoot.ScoreTextClick(Sender: TObject);
//begin
//  ShowMessage('Woo');
//end;



procedure TWeetWoot.GameTimerTimer(Sender: TObject);
begin
  if FBlocks.Count > 30
  then begin
  FPanSpeed := 1;
//  FSpawnRangeTimer := 160;
  end;

//  if FBlocks.Count > 90
//  then self.PanSpeed := 2;

  UpdatePlayer;
  UpdateBlocks;
  UpdateWorld;
  FScore := FScore + 1;
  ScoreText.Text := 'Score: ' + IntToStr(FScore);

  OutputDebugString(PChar('Score: ' + FScore.ToString + #13#10));
end;

procedure TWeetWoot.UpdatePlayer;
var
  NextPos: TRectF;
  CollidedBlock: TBlock;
  CollidedWithWall: Boolean;
  tempPlayerY: Single; // Store player's Y position before X collision check
begin

  if IsKeyDown(Ord(37)) then // Left
    FPlayer.Velocity.X := -PlayerSpeed
  else if IsKeyDown(Ord(39)) then // Right
    FPlayer.Velocity.X := PlayerSpeed
  else
    FPlayer.Velocity.X := 0;

  // --- Applying Gravity ---
  FPlayer.Velocity.Y := FPlayer.Velocity.Y + Gravity;

  // --- Jumping ---
  var t := GetTime;
  if IsKeyDown(38) and (t > FPlayer.CanJump) then
  begin
    if FPlayer.IsOnGround then // Normal Jump
    begin
      FPlayer.Velocity.Y := JumpForce;
      FPlayer.IsOnGround := False;
    end
    else if FPlayer.CanWallJump then // Wall Jump
    begin
      if FPlayer.WallJumpSide = TAlignLayout.Left then
        FPlayer.Velocity.X := -WallJumpHorizontalForce
      else
        FPlayer.Velocity.X := WallJumpHorizontalForce;

      FPlayer.Velocity.Y := JumpForce;
      FPlayer.CanWallJump := False;
    end;
    FPlayer.CanJump := GetTime + 0.0000000000000005;
  end;

  // --- Power Drop ---
  if IsKeyDown(Ord(40)) and not FPlayer.IsOnGround then
  begin
    FPlayer.Velocity.Y := FPlayer.Velocity.Y + Gravity * 10;
  end;

  // Limit player fall speed
  if FPlayer.Velocity.Y > 15 then FPlayer.Velocity.Y := 15;

   // Reset collision states for this frame
  FPlayer.IsOnGround := False;
  FPlayer.CanWallJump := False;
  CollidedWithWall := False;

  // Store player's current bounds for collision calculations
  var PlayerCurrentBounds := FPlayer.Rect.BoundsRect;

  // --- Resolve Y-axis Collision ---
  NextPos := PlayerCurrentBounds;
  NextPos.Offset(0, FPlayer.Velocity.Y);

  for CollidedBlock in FBlocks do
  begin
    if NextPos.IntersectsWith(CollidedBlock.Rect.BoundsRect) then
    begin
      if FPlayer.Velocity.Y > 0 then // Moving Down (landing)
      begin
        FPlayer.IsOnGround := True;
        FPlayer.Velocity.Y := 0;
        FPlayer.Rect.Position.Y := CollidedBlock.Rect.Position.Y - FPlayer.Rect.Height;
      end
      else if FPlayer.Velocity.Y < 0 then // Moving Up (hit ceiling)
      begin
        FPlayer.Velocity.Y := 0;
        FPlayer.Rect.Position.Y := CollidedBlock.Rect.Position.Y + CollidedBlock.Rect.Height;
      end;
      Break;
    end;
  end;

  if not FPlayer.IsOnGround or (FPlayer.Velocity.Y <> 0) then
      FPlayer.Rect.Position.Y := FPlayer.Rect.Position.Y + FPlayer.Velocity.Y;


  // --- Resolve X-axis Collision ---
  NextPos := FPlayer.Rect.BoundsRect; // Get player's current position (possibly Y-adjusted)
  NextPos.Offset(FPlayer.Velocity.X, 0); // Project player's X movement

  for CollidedBlock in FBlocks do
  begin
    if CollidedBlock.IsGroundBlock and FPlayer.IsOnGround then
    begin
      Continue;
    end;

    // check for wall collisions
    if NextPos.IntersectsWith(CollidedBlock.Rect.BoundsRect) then
    begin
      CollidedWithWall := True;
      if FPlayer.Velocity.X > 0 then // Moving right
      begin
        FPlayer.Velocity.X := 0;
        FPlayer.Rect.Position.X := CollidedBlock.Rect.Position.X - FPlayer.Rect.Width;
        FPlayer.WallJumpSide := TAlignLayout.Left;
      end
      else if FPlayer.Velocity.X < 0 then // Moving left
      begin
        FPlayer.Velocity.X := 0;
        FPlayer.Rect.Position.X := CollidedBlock.Rect.Position.X + CollidedBlock.Rect.Width;
        FPlayer.WallJumpSide := TAlignLayout.Right;
      end;
      Break; // Found an X-collision, break to prevent multiple snaps
    end;
  end;

  // Apply resolved X position.
  if FPlayer.Velocity.X <> 0 then
    FPlayer.Rect.Position.X := FPlayer.Rect.Position.X + FPlayer.Velocity.X;

  if CollidedWithWall and not FPlayer.IsOnGround then
    FPlayer.CanWallJump := True;

  // --- Screen Boundaries (for player horizontal todo wrap around..) ---
  if FPlayer.Rect.Position.X < 0 then FPlayer.Rect.Position.X := 0;
  if FPlayer.Rect.Position.X > Self.Width - FPlayer.Rect.Width then
    FPlayer.Rect.Position.X := Self.Width - FPlayer.Rect.Width;

  // --- Game Over Check ---
  // Player falls out of view if they go below the bottom edge of the form
  if FPlayer.Rect.Position.Y > Self.Height then
    GameOver('You fell out of view!');
end;


procedure TWeetWoot.UpdateBlocks;
var
  i: Integer;
  Block: TBlock;
  OtherBlock: TBlock;
  Crushed: Boolean;
  BlockNextPos: TRectF;
begin
  Crushed := False;

  // --- Spawn New Blocks ---
  if RandomRange(0, FSpawnRangeTimer) = 0 then
  begin
    var block_dimension := RandomRange(80, 160);
    var NewBlock := TBlock.Create;
    NewBlock.Rect := TRectangle.Create(Self);
    NewBlock.Rect.Parent := Self;
    NewBlock.Rect.Fill.Color := TAlphaColors.Darkgray;
    NewBlock.Rect.Width := block_dimension;
    NewBlock.Rect.Height := block_dimension;
    NewBlock.Rect.Position.X := RandomRange(0, Round(1920 - NewBlock.Rect.Width));
    NewBlock.Rect.Position.Y := -NewBlock.Rect.Height;
    NewBlock.VelocityY := BlockInitialFallSpeed;
    FBlocks.Add(NewBlock);
  end;

  // --- Update Blocks and Handle Collisions ---
  for i := FBlocks.Count - 1 downto 0 do // Iterate backwards for safe deletion
  begin
    Block := FBlocks[i];

    if Block.VelocityY <> 0 then
      Block.VelocityY := Block.VelocityY + Gravity ; //I think maybe we need to increase block velocity with FPanSpeed


    if Block.VelocityY = 69 then Block.DisposeOf;

    BlockNextPos := Block.Rect.BoundsRect;
    BlockNextPos.Offset(1, Block.VelocityY);

    var BlockLanded: Boolean := False;
    for OtherBlock in FBlocks do
    begin
      if (Block = OtherBlock) then
        Continue;

      if BlockNextPos.IntersectsWith(OtherBlock.Rect.BoundsRect) then
      begin
        if Block.VelocityY > 0 then // Only consider downward movement for landing
        begin
          Block.VelocityY := 0;
          // place block on top of the other block
          Block.Rect.Position.Y := OtherBlock.Rect.Position.Y - Block.Rect.Height;
          BlockLanded := True;
        end;
        Break;
      end;
    end;

    if not BlockLanded then
      Block.Rect.Position.Y := Block.Rect.Position.Y + Block.VelocityY;

    if FPlayer.Rect.BoundsRect.IntersectsWith(Block.Rect.BoundsRect) then
    begin
      if (Block.VelocityY >= 0)
      and (FPlayer.Rect.Position.Y >= Block.Rect.Position.Y + Block.Rect.Height - 20)
      then
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
    GameOver('Ouch.. you were crushed!');
end;

procedure TWeetWoot.UpdateWorld;
var
  Block: TBlock;
  lerpFactor: Single;
begin
  // --- Pan the View ---
  // Move the player and all blocks down to simulate the camera moving up
  FPlayer.Rect.Position.Y := FPlayer.Rect.Position.Y + FPanSpeed;
  for Block in FBlocks do
  begin
    Block.Rect.Position.Y := Block.Rect.Position.Y + FPanSpeed;
  end;

  // --- Update Background (commented out as per your previous code) ---
  // FGameTime := FGameTime + GameTimer.Interval / 1000.0;
  // lerpFactor := Min(FGameTime / 120.0, 1.0);
  Self.Fill.Color := TAlphaColorRec.Whitesmoke; // (TAlphaColors.White, TAlphaColors.Dimgray, lerpFactor);
end;

procedure TWeetWoot.GameOver(AMessage: string);
begin
  GameTimer.Enabled := False;
  ShowMessage(AMessage + #13#10 + 'Click OK to close.');
  Application.Terminate;
end;

end.
