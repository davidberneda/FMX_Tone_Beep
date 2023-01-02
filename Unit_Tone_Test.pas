unit Unit_Tone_Test;

interface

// https://github.com/davidberneda/FMX_Tone_Beep

// Enable this DEFINE if you have TeeChart components installed.
{$DEFINE TEECHART}  // <-- remove the "."

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.ListBox;

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
    GitHub: TText;
    ButtonChart: TButton;
    CBUsePCM: TCheckBox;
    CBWave: TComboBox;
    CBSampleRate: TComboBox;
    TBVolume: TTrackBar;
    TextVolume: TText;
    Label3: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure TBDurationChange(Sender: TObject);
    procedure TBFrequencyChange(Sender: TObject);
    procedure RectangleDoMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure FormCreate(Sender: TObject);
    procedure GitHubClick(Sender: TObject);
    procedure ButtonChartClick(Sender: TObject);
    procedure CBUsePCMChange(Sender: TObject);
    procedure CBWaveChange(Sender: TObject);
    procedure CBSampleRateChange(Sender: TObject);
    procedure TBVolumeChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
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
  FMX_Tone,

  {$IFDEF TEECHART}
  FMX_Tone_Chart,
  {$ENDIF}

  FMX_OpenURL;

procedure TToneDemo.ButtonChartClick(Sender: TObject);
begin
  {$IFDEF TEECHART}
  TFormChart.Edit(Self, TBFrequency.Value, Round(TBDuration.Value));
  {$ENDIF}
end;

function TToneDemo.Duration:Integer;
begin
  result:=Round(TBDuration.Value);
end;

procedure TToneDemo.FormCreate(Sender: TObject);
begin
  CBUsePCM.IsChecked:=TTone.UsePCM;

  {$IFNDEF MSWINDOWS}
  CBUsePCM.Visible:=False;
  {$ENDIF}

  {$IFNDEF TEECHART}
  ButtonChart.Visible:=False;
  {$ENDIF}
end;

procedure TToneDemo.FormShow(Sender: TObject);
begin
  TBVolume.Value:=TTone.Volume;
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

procedure TToneDemo.CBSampleRateChange(Sender: TObject);
begin
  case CBSampleRate.ItemIndex of
   0 : TTone.SampleRate:=TSampleRate.SampleRate8000;
   1 : TTone.SampleRate:=TSampleRate.SampleRate11025;
   2 : TTone.SampleRate:=TSampleRate.SampleRate22050;
   3 : TTone.SampleRate:=TSampleRate.SampleRate44100;
  end;
end;

procedure TToneDemo.CBUsePCMChange(Sender: TObject);
begin
  TTone.UsePCM:=CBUsePCM.IsChecked;

  CBWave.Enabled:=TTone.UsePCM;
  CBSampleRate.Enabled:=TTone.UsePCM;

  TBVolume.Enabled:=TTone.UsePCM;
  TextVolume.Enabled:=TTone.UsePCM;
end;

procedure TToneDemo.CBWaveChange(Sender: TObject);
begin
  case CBWave.ItemIndex of
    0: TTone.WaveStyle:=TWaveStyle.Sine;
    1: TTone.WaveStyle:=TWaveStyle.Square;
  end;
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

procedure TToneDemo.TBVolumeChange(Sender: TObject);
begin
  TTone.Volume:=Round(TBVolume.Value);
  TextVolume.Text:=TTone.Volume.ToString+' %';
end;

end.
