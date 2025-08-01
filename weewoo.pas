unit weewoo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections, System.Math.Vectors, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Utils, Winapi.Windows, FMX.Ani, FMX.Menus, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Media;

type
  TWeetWoot = class(TForm)
    GameTimer: TTimer;
    ScoreText: TText;
    GameMenu: TPopupMenu;
    Play: TMenuItem;
    Quit: TMenuItem;
    Scores: TMenuItem;
    SoundButton: TButton;
    Music: TMediaPlayer;
    Background: TBrushObject;
    procedure FormCreate(Sender: TObject);
    procedure MenuItemQuit(Sender: TObject);
    procedure MenuItemPlay(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure GameTimerTimer(Sender: TObject);
    procedure ToggleMusic(Sender: TObject);
    procedure ResetGame;

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
  public
  PanningSpeed: Double;
  private
    FPlayer: TPlayer;
    FBlocks: TObjectList<TBlock>;
    FKeys: TDictionary<Word, Boolean>;
    FGameTime: Single;
    FScore: Integer;
    FStartTime: Single;
    FSpawnRangeTimer: Integer;
    FMusicBool: Boolean;

    const
      Gravity = 0.9;
      PlayerSpeed = 10.0;
      JumpForce = -18.0;
      WallJumpHorizontalForce = 32.0;
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

procedure TWeetWoot.ResetGame;
  var
    GroundBlock: TBlock;
    i: Integer;
  begin
    FGameTime := 0;
    FScore := 0;
    ScoreText.Text := 'Score: 0';
    FSpawnRangeTimer := 50;
    Self.PanningSpeed := 0;
    FKeys.Clear;

    for i := Self.ChildrenCount - 1 downto 0 do
    begin
      if (Self.Children[i] is TRectangle) and (Self.Children[i] <> FPlayer.Rect) then
      begin
        Self.Children[i].Destroy;
      end;
    end;

    FBlocks.Destroy;

    FKeys := TDictionary<Word, Boolean>.Create;
    FBlocks := TObjectList<TBlock>.Create;
    FPlayer.Rect := TRectangle.Create(Self);
    FPlayer.Rect.Parent := Self;
    FPlayer.Rect.Fill.Color := TAlphaColors.white;
    FPlayer.Rect.Width := 20;
    FPlayer.Rect.Height := 20;
    FPlayer.Rect.Position.X := (Self.Width - FPlayer.Rect.Width) / 2;
    FPlayer.Rect.Position.Y := Self.Height/2;
    FPlayer.Velocity := TVector.Create(0, 0);
    FPlayer.IsOnGround := False;
    FPlayer.CanWallJump := False;
    FGameTime := 0;
    FSpawnRangeTimer := 50;
    self.PanningSpeed := 0;

    GroundBlock := TBlock.Create;
    GroundBlock.Rect := TRectangle.Create(Self);
    GroundBlock.Rect.Parent := Self;
    GroundBlock.Rect.Fill.Color := TAlphaColors.WhiteSmoke;
    GroundBlock.Rect.Width := Self.Width;
    GroundBlock.Rect.Height := 50;
    GroundBlock.Rect.Position.X := 0;
    GroundBlock.Rect.Position.Y := Self.Height - GroundBlock.Rect.Height;
    GroundBlock.VelocityY := 0;
    GroundBlock.IsGroundBlock := True;
    FBlocks.Add(GroundBlock);

    GameTimer.OnTimer := GameTimerTimer;
    GameTimer.Interval := 16;
    GameTimer.Enabled := True;

    if FMusicBool then
    begin
      Music.Stop; // restart
      Music.Play;
    end;
  end;

procedure TWeetWoot.FormCreate(Sender: TObject);
  var GroundBlock: TBlock;
  begin
    FKeys := TDictionary<Word, Boolean>.Create;
    FBlocks := TObjectList<TBlock>.Create;
    FPlayer.Rect := TRectangle.Create(Self);
    FPlayer.Rect.Parent := Self;
    FPlayer.Rect.Fill.Color := TAlphaColors.Aquamarine;
    FPlayer.Rect.Width := 20;
    FPlayer.Rect.Height := 20;
    FPlayer.Rect.Position.X := (Self.Width - FPlayer.Rect.Width) / 2;
    FPlayer.Rect.Position.Y := Self.Height/2;
    FPlayer.Velocity := TVector.Create(0, 0);
    FPlayer.IsOnGround := False;
    FPlayer.CanWallJump := False;
    FGameTime := 0;
    FSpawnRangeTimer := 50;
    self.PanningSpeed := 0;

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
    GameTimer.Interval := 16;
    GameTimer.Enabled := True;
    FMusicBool := True;
    Music.FileName := 'C:\source\weetwoot\retro.mp3';
    Music.Play;
  end;


procedure TWeetWoot.ToggleMusic(Sender: TObject);
  begin
    if FMusicBool then begin
      Music.Stop;
      FMusicBool := False;
    end;


    if FMusicBool = False then begin
      Music.Play;
      FMusicBool := True;
    end;

  end;

procedure TweetWoot.MenuItemQuit(Sender: TObject);
  begin
    Application.Terminate;
  end;


procedure TweetWoot.MenuItemPlay(Sender: TObject);
  begin
    ResetGame;
  end;


procedure TWeetWoot.FormKeyDown(
  Sender: TObject;
  var Key: Word;
  var KeyChar: Char; Shift: TShiftState
);
  begin
    FKeys.AddOrSetValue(Key, True);
    OutputDebugString(PChar('Key Down: ' + IntToStr(Key) + #13#10));
  end;


procedure TWeetWoot.FormKeyUp(
  Sender: TObject;
  var Key: Word;
  var KeyChar: Char;
  Shift: TShiftState
);
  begin
    FKeys.AddOrSetValue(Key, False);
  end;


function TWeetWoot.IsKeyDown(Key: Word): Boolean;
  begin
    Result := FKeys.TryGetValue(Key, Result) and Result;
  end;


procedure TWeetWoot.GameTimerTimer(Sender: TObject);
  begin
    if FBlocks.Count > 10 then self.PanningSpeed := 1;
    if FBlocks.Count > 120 then self.PanningSpeed := 2;

    UpdatePlayer;
    UpdateBlocks;
    UpdateWorld;
    FScore := FScore + 1;
    ScoreText.Text := 'Score: ' + IntToStr(FScore);
  end;


procedure TWeetWoot.UpdatePlayer;
  var
    NextPos: TRectF;
    CollidedBlock: TBlock;
    CollidedWithWall: Boolean;
    tempPlayerY: Single; // Store player's Y position before X collision check
  begin
    if IsKeyDown(Ord(37)) then
      FPlayer.Velocity.X := -PlayerSpeed
    else if IsKeyDown(Ord(39)) then
      FPlayer.Velocity.X := PlayerSpeed
    else
      FPlayer.Velocity.X := 0;

    FPlayer.Velocity.Y := FPlayer.Velocity.Y + Gravity;

    var t := GetTime;
    if IsKeyDown(38) and (t > FPlayer.CanJump) then
    begin
      if FPlayer.IsOnGround then
      begin
        FPlayer.Velocity.Y := JumpForce;
        FPlayer.IsOnGround := False;
      end
      else if FPlayer.CanWallJump then
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

    // Fast drop
    if IsKeyDown(Ord(40)) and not FPlayer.IsOnGround then
    begin
      FPlayer.Velocity.Y := FPlayer.Velocity.Y + Gravity * 10;
    end;

    if FPlayer.Velocity.Y > 15 then FPlayer.Velocity.Y := 15;

     // Reset collision states for this frame
    FPlayer.IsOnGround := False;
    FPlayer.CanWallJump := False;
    CollidedWithWall := False;

    var PlayerCurrentBounds := FPlayer.Rect.BoundsRect;

    NextPos := PlayerCurrentBounds;
    NextPos.Offset(0, FPlayer.Velocity.Y);

    for CollidedBlock in FBlocks do begin
      if NextPos.IntersectsWith(CollidedBlock.Rect.BoundsRect) then begin
        if FPlayer.Velocity.Y > 0 then begin   // Moving down
          FPlayer.IsOnGround := True;
          FPlayer.Velocity.Y := 0;
          FPlayer.Rect.Position.Y := CollidedBlock.Rect.Position.Y - FPlayer.Rect.Height;
        end else if FPlayer.Velocity.Y < 0 then begin  // up
          FPlayer.Velocity.Y := 0;
          FPlayer.Rect.Position.Y := CollidedBlock.Rect.Position.Y + CollidedBlock.Rect.Height;
        end;

        Break;
      end;
    end;

    if not FPlayer.IsOnGround or (FPlayer.Velocity.Y <> 0) then
        FPlayer.Rect.Position.Y := FPlayer.Rect.Position.Y + FPlayer.Velocity.Y;


    NextPos := FPlayer.Rect.BoundsRect;
    NextPos.Offset(FPlayer.Velocity.X, 0);

    for CollidedBlock in FBlocks do begin
      if CollidedBlock.IsGroundBlock and FPlayer.IsOnGround then begin
        Continue;
      end;

      if NextPos.IntersectsWith(CollidedBlock.Rect.BoundsRect) then begin
        CollidedWithWall := True;

        if FPlayer.Velocity.X > 0 then begin
          FPlayer.Velocity.X := 0;
          FPlayer.Rect.Position.X := CollidedBlock.Rect.Position.X - FPlayer.Rect.Width;
          FPlayer.WallJumpSide := TAlignLayout.Left;
        end else if FPlayer.Velocity.X < 0 then begin
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

    if FPlayer.Rect.Position.X < 0 then
      FPlayer.Rect.Position.X := Self.Width - FPlayer.Rect.Width;

    if FPlayer.Rect.Position.X > Self.Width - FPlayer.Rect.Width then  FPlayer.Rect.Position.X := 0;


    if FPlayer.Rect.Position.Y > Self.Height then begin
      GameOver('You fell out of view!');
      ResetGame;
      GameMenu.Popup(Self.Width/2, Self.Height/2);
    end;
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

    if RandomRange(0, FSpawnRangeTimer) = 0 then begin
      var block_dimension := RandomRange(80, 160);
      var NewBlock := TBlock.Create;
      NewBlock.Rect := TRectangle.Create(Self);
      NewBlock.Rect.Parent := Self;
      NewBlock.Rect.Fill.Color := TAlphaColors.Darkgray;
      NewBlock.Rect.Width := block_dimension;
      NewBlock.Rect.Height := block_dimension;
      NewBlock.Rect.Position.X := RandomRange(0, Round(Self.clientWidth-100 - NewBlock.Rect.Width));
      NewBlock.Rect.Position.Y := -NewBlock.Rect.Height;
      NewBlock.VelocityY := BlockInitialFallSpeed;
      FBlocks.Add(NewBlock);
    end;

    for i := FBlocks.Count - 1 downto 0 do begin
      Block := FBlocks[i];

      if Block.VelocityY <> 0 then
        Block.VelocityY := Block.VelocityY + Gravity ;

      BlockNextPos := Block.Rect.BoundsRect;
      BlockNextPos.Offset(1, Block.VelocityY);

      var BlockLanded: Boolean := False;
      for OtherBlock in FBlocks do begin
        if (Block = OtherBlock) then Continue;

        if BlockNextPos.IntersectsWith(OtherBlock.Rect.BoundsRect) then begin
          if Block.VelocityY > 0 then begin
            Block.VelocityY := 0;
            Block.Rect.Position.Y := OtherBlock.Rect.Position.Y - Block.Rect.Height;
            BlockLanded := True;
          end;
          Break;
        end;
      end;

      if not BlockLanded then
        Block.Rect.Position.Y := Block.Rect.Position.Y + Block.VelocityY;

      if FPlayer.Rect.BoundsRect.IntersectsWith(Block.Rect.BoundsRect) then begin
        if (Block.VelocityY >= 0)
        and (FPlayer.Rect.Position.Y >= Block.Rect.Position.Y + Block.Rect.Height - 20)
        then Crushed := True;
      end;


      if Block.Rect.Position.Y > Self.Height then begin
        Block.Rect.Free;
        FBlocks.Delete(i);
      end;
    end;

    if Crushed then begin
      GameOver('Ouch.. you were crushed!');
      ResetGame;
      GameMenu.Popup(Self.Width/2, Self.Height/2);
    end;

  end;

procedure TWeetWoot.UpdateWorld;
  var
    Block: TBlock;
    lerpFactor: Single;
  begin
    FPlayer.Rect.Position.Y := FPlayer.Rect.Position.Y + self.PanningSpeed;
    for Block in FBlocks do begin
        Block.Rect.Position.Y := Block.Rect.Position.Y + self.PanningSpeed;
    end;



    FPlayer.Rect.Fill.Color := TAlphaColors.White;
    if FScore < 300 then begin
      Self.Fill.Color := TAlphaColorRec.Azure;
    end
    else if FScore < 1000 then begin
      Self.Fill.Color := TAlphaColorRec.Cyan;
    end
    else if FScore < 3000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkblue;
    end
    else if FScore < 4000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkcyan;
    end
    else if FScore < 5000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkgoldenrod;
    end
    else if FScore < 6000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkgray;
    end
    else if FScore < 7000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkgreen;
    end
    else if FScore < 8000 then begin
      Self.Fill.Color := TAlphaColorRec.Lightseagreen;
    end
    else if FScore < 9000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkkhaki;
    end
    else if FScore < 10000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkmagenta;
    end
    else if FScore < 11000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkolivegreen;
    end
    else if FScore < 12000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkorange;
    end
    else if FScore < 13000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkorchid;
    end
    else if FScore < 14000 then begin
      Self.Fill.Color := TAlphaColorRec.Darkred;
    end

  end;

procedure TWeetWoot.GameOver(AMessage: string);
  begin
    GameTimer.Enabled := False;
    ShowMessage(AMessage + #13#10);
  end;

end.
