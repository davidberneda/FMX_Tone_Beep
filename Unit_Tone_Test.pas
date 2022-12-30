unit Unit_Tone_Test;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts;

type
  TToneDemo = class(TForm)
    Button1: TButton;
    Button2: TButton;
    TBDuration: TTrackBar;
    TextDuration: TText;
    Label1: TLabel;
    Label2: TLabel;
    TBFrequency: TTrackBar;
    TextFrequency: TText;
    Layout1: TLayout;
    RectangleDo: TRectangle;
    RectangleSi: TRectangle;
    RectangleLa: TRectangle;
    RectangleSol: TRectangle;
    RectangleFa: TRectangle;
    RectangleMi: TRectangle;
    RectangleRe: TRectangle;
    RectangleReB: TRectangle;
    RectangleMiB: TRectangle;
    RectangleSolB: TRectangle;
    RectangleLaB: TRectangle;
    RectangleSiB: TRectangle;
    Button3: TButton;
    GitHub: TText;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure TBDurationChange(Sender: TObject);
    procedure TBFrequencyChange(Sender: TObject);
    procedure RectangleDoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure GitHubClick(Sender: TObject);
  private
    { Private declarations }

    function Duration:Integer;
  public
    { Public declarations }
  end;

var
  ToneDemo: TToneDemo;

implementation

{$R *.fmx}

uses
  FMX_Tone, FMX_OpenURL;

function TToneDemo.Duration:Integer;
begin
  result:=Round(TBDuration.Value);
end;

procedure TToneDemo.FormCreate(Sender: TObject);
begin
  {$IFDEF MSWINDOWS}
  Button3.Visible:=True;
  {$ENDIF}
end;

procedure TToneDemo.GitHubClick(Sender: TObject);
begin
  TOpenURL.Go(GitHub.Text);
end;

procedure TToneDemo.Button1Click(Sender: TObject);
begin
  TTone.Beep(Duration);
end;

procedure TToneDemo.Button2Click(Sender: TObject);
begin
  TTone.Play(Round(TBFrequency.Value), Duration);
end;

procedure TToneDemo.Button3Click(Sender: TObject);
begin
  {$IFDEF MSWINDOWS}
  TTone.PlayPCM(Round(TBFrequency.Value), Duration);
  {$ENDIF}
end;

procedure TToneDemo.RectangleDoMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if Sender=RectangleDo  then TTone.Play(261.63, Duration) else
  if Sender=RectangleReB then TTone.Play(277.18, Duration) else
  if Sender=RectangleRe  then TTone.Play(293.66, Duration) else
  if Sender=RectangleMiB then TTone.Play(311.13, Duration) else
  if Sender=RectangleMi  then TTone.Play(329.63, Duration) else
  if Sender=RectangleFa  then TTone.Play(349.23, Duration) else
  if Sender=RectangleSolB then TTone.Play(369.99, Duration) else
  if Sender=RectangleSol then TTone.Play(392.00, Duration) else
  if Sender=RectangleLaB then TTone.Play(415.30, Duration) else
  if Sender=RectangleLa  then TTone.Play(440.00, Duration) else
  if Sender=RectangleSiB then TTone.Play(466.16, Duration) else
  if Sender=RectangleSi  then TTone.Play(493.88, Duration);
end;

procedure TToneDemo.TBDurationChange(Sender: TObject);
begin
  TextDuration.Text := Round(TBDuration.Value).ToString+' msec.';
end;

procedure TToneDemo.TBFrequencyChange(Sender: TObject);
begin
  TextFrequency.Text := Round(TBFrequency.Value).ToString+' Hertz';
end;

end.
