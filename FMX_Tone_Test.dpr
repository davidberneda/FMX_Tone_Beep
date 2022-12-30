program FMX_Tone_Test;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit_Tone_Test in 'Unit_Tone_Test.pas' {ToneDemo},
  FMX_Tone in 'FMX_Tone.pas',
  FMX_OpenURL in 'FMX_OpenURL.pas';

{$R *.res}

begin
  {$IFOPT D+}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TToneDemo, ToneDemo);
  Application.Run;
end.
