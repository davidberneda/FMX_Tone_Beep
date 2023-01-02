unit FMX_Tone_Chart;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMXTee.Engine,
  FMXTee.Series, FMXTee.Procs, FMXTee.Chart, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Layouts;

type
  TFormChart = class(TForm)
    Chart1: TChart;
    Series1: TFastLineSeries;
    Layout1: TLayout;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }

    Samples : TArray<Single>;

    procedure AddSamples;
  public
    { Public declarations }
    class procedure Edit(const AOwner:TComponent;
                         const AFrequency:Single;
                         const ADuration:Integer); static;
  end;

implementation

{$R *.fmx}

uses
  FMX_Tone;

{ TFormChart }

procedure TFormChart.Button1Click(Sender: TObject);
begin
  TTone.Play(Samples);
end;

class procedure TFormChart.Edit(const AOwner:TComponent;
                                const AFrequency: Single;
                                const ADuration: Integer);
begin
  with TFormChart.Create(nil) do
  try
    Samples:=TTone.GenerateSamples(AFrequency,ADuration);

    Chart1.Title.Caption:='Frequency: '+FloatToStr(AFrequency)+
                   ' Hz. Duration: '+ADuration.ToString+' msec.';

    AddSamples;

    Chart1.Axes.Left.SetMinMax(-2,2);

    ShowModal(procedure(Modal:TModalResult)
      begin
      end);
  finally
    {$IFDEF MSWINDOWS}
    Free;
    {$ENDIF}
  end;
end;

procedure TFormChart.AddSamples;
var t : Integer;
begin
  Series1.BeginUpdate;
  try
    Series1.Clear;

    for t:=0 to High(Samples) do
        Series1.Add(Samples[t]);
  finally
    Series1.EndUpdate;
  end;
end;

end.
