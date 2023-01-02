unit FMX_Tone;

interface

(*
  https://github.com/davidberneda/FMX_Tone_Beep

  EXAMPLE:

    TTone.Play(440, 1000)  //  <---  "La" note, 1 second.

  Delphi multi-platform implementation of sound "Beep" generation.

  Currently supported:

    - Windows 32 and 64 bit.
    - Android 32 and 64 bit.


  Android code ported from Java:
    https://stackoverflow.com/a/9106394

*)
type
  TWaveStyle=(Sine,Square); // TODO: Triangle, SawTooth

  TSampleRate=(SampleRate8000,SampleRate11025,
               SampleRate22050,SampleRate44100);

  TVolume=Byte; // 0..100

  TTone=record
  private
    {$IFDEF ANDROID}
    class var FVolume:TVolume;
    {$ENDIF}

    class function GetVolume:TVolume; static;
    class procedure SetVolume(Value:TVolume); static;
  public
    class var SampleRate : TSampleRate; // Default = 8000 (8kHz)
    class var UsePCM : Boolean;         // Default = Windows:False  Android:True
    class var WaveStyle : TWaveStyle;   // Default = Sine

    // Duration in Milliseconds (minimum 2 in Windows)
    class procedure Beep(const ADuration: Integer); static;

    // Frequency in Hertz
    class procedure Play(const AFrequency:Single; const ADuration:Integer); overload; static;

    // Play a custom array of samples (values in range -1..1)
    class procedure Play(const ASamples:TArray<Single>); overload; static;

    class function GenerateSamples(const AFrequency:Single; const ADuration:Integer):TArray<Single>; static;

    class property Volume:TVolume read GetVolume write SetVolume;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.MMSystem,
  {$ELSE}
  {$IFDEF ANDROID}
  Androidapi.Jni,
  Androidapi.JNIBridge,
  Androidapi.JNI.Media,
  {$ENDIF}
  {$ENDIF}

  System.SysUtils,
  System.Math;

class procedure TTone.Beep(const ADuration: Integer);
{$IFDEF MSWINDOWS}
begin
  Winapi.Windows.Beep(1000,ADuration);
{$ELSE}
{$IFDEF LINUX}
begin
 // TODO
{$ELSE}
{$IFDEF ANDROID}
var
  tmpVolume: Integer;
  StreamType: Integer;
  ToneType: Integer;
  ToneGenerator: JToneGenerator;
begin
  tmpVolume := TJToneGenerator.JavaClass.MAX_VOLUME;

  StreamType := TJAudioManager.JavaClass.STREAM_ALARM;
  ToneType := TJToneGenerator.JavaClass.TONE_DTMF_0;

  ToneGenerator := TJToneGenerator.JavaClass.init(StreamType, tmpVolume);
  ToneGenerator.startTone(ToneType, ADuration);
{$ELSE}
begin
 // TODO: MacOS, iOS
{$ENDIF}
{$ENDIF}
{$ENDIF}
end;

function GetSampleRate:Integer;
begin
  case TTone.SampleRate of
     SampleRate11025: result:=11025;
     SampleRate22050: result:=22050;
     SampleRate44100: result:=44100;
  else
     //SampleRate8000:
     result:=8000;
  end;
end;

class function TTone.GenerateSamples(const AFrequency:Single; const ADuration:Integer):TArray<Single>;
var
  Samples : TArray<Single>;
  tmp : Single;
  tmpFreq : Integer;

  procedure SetGenerated(const Sample:Integer; const Val:Single);
  begin
    case WaveStyle of
      TWaveStyle.Sine:
          Samples[Sample]:=Sin(Sample*tmp)*Val*0.5;

      TWaveStyle.Square:
           if (Sample div tmpFreq) mod 2 = 0 then // <-- not correct
              Samples[Sample]:=  1*tmp*Val
           else
              Samples[Sample]:= -1*tmp*Val;
    end;
  end;

var
  NumSamples : Integer;
  i, ramp : Integer;
begin
  NumSamples := Round(ADuration * GetSampleRate * 0.001 * 0.5);
  SetLength(Samples,NumSamples);

  case WaveStyle of
    TWaveStyle.Sine: tmp:=(AFrequency * 2 * PI) / GetSampleRate;
  else
  begin
    tmp:=0.5;
    tmpFreq:=Round(0.5*GetSampleRate/AFrequency);
  end;
  end;

  // Amplitude ramp as a percent of sample count
  ramp := NumSamples div 20;

  // Ramp amplitude up (to avoid clicks)
  for i:=0 to ramp-1 do
      SetGenerated(i,i/ramp); // Ramp up to maximum

  // Max amplitude for most of the samples
  for i:=ramp to (NumSamples-1) - ramp do
      SetGenerated(i,1); // scale to maximum amplitude

  // Ramp amplitude down
  for i:=1 + (NumSamples-1) - ramp to NumSamples-1 do
      SetGenerated(i,((NumSamples-1)-i)/ramp); // Ramp down to zero

  result:=Samples;
end;

{$IFDEF MSWINDOWS}
procedure CheckError(const Err:Cardinal);
begin
  if Err<>MMSYSERR_NOERROR then
     raiseLastOSError(Err);
end;

function InitAudioSys:TWaveFormatEx;
begin
  with result do
  begin
    wFormatTag := WAVE_FORMAT_PCM;
    nChannels := 1; // Mono
    nSamplesPerSec := GetSampleRate;
    wBitsPerSample := 16;
    nAvgBytesPerSec := nChannels * nSamplesPerSec * wBitsPerSample div 8;
    nBlockAlign := nChannels * wBitsPerSample div 8;
    cbSize := 0;
  end;
end;

{$ENDIF}

class function TTone.GetVolume: TVolume;
{$IFDEF MSWINDOWS}
var tmp : DWORD;
    wo: HWAVEOUT;
    fmt: TWaveFormatEx;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  fmt:=InitAudioSys;

  CheckError(waveOutOpen(@wo, WAVE_MAPPER, @fmt, 0, 0, CALLBACK_NULL));
  try
    CheckError(waveOutGetVolume(wo,@tmp));

    result:=(100*(tmp shr 16)) div $FFFF;
  finally
    CheckError(waveOutClose(wo));
  end;

  {$ELSE}
  result:=FVolume;
  {$ENDIF}
end;

// Converts and array of singles to an array of bytes, two bytes per single clamped to a 16bit word.
function PCM16Bit(const ASamples:TArray<Single>):{$IFDEF ANDROID}TJavaArray{$ELSE}TArray{$ENDIF}<Byte>;
var idx,
    t,
    tmp : Integer;
begin
  {$IFDEF ANDROID}
  result:=TJavaArray<Byte>.Create(2*Length(ASamples));
  {$ELSE}
  SetLength(result,2*Length(ASamples));
  {$ENDIF}

  idx:=0;

  for t:=0 to High(ASamples) do
  begin
    tmp:=Round(ASamples[t]*32767);

    result[idx] := tmp and $FF;
    Inc(idx);

    result[idx] := (tmp and $FF00) shr 8;
    Inc(idx);
  end;
end;

class procedure TTone.Play(const ASamples: TArray<Single>);

{$IFDEF MSWINDOWS}
  procedure InitHeader(var hdr: TWaveHdr; const Channels:Byte; const Samples:TArray<Byte>);
  begin
    ZeroMemory(@hdr, sizeof(hdr));

    with hdr do
    begin
      lpData := @Samples[0];
      dwBufferLength := Channels * Length(Samples) * SizeOf(Byte);
      dwFlags := 0;
    end;
  end;

var
  wo: HWAVEOUT;
  fmt: TWaveFormatEx;
  hdr: TWaveHdr;
begin
  fmt:=InitAudioSys;

  CheckError(waveOutOpen(@wo, WAVE_MAPPER, @fmt, 0, 0, CALLBACK_NULL));
  try
    InitHeader(hdr,fmt.nChannels,PCM16Bit(ASamples));
    CheckError(waveOutPrepareHeader(wo, @hdr, SizeOf(hdr)));
    CheckError(waveOutWrite(wo, @hdr, SizeOf(hdr)));

    // TODO: Callback to allow cancel waiting (asynchronous playing)

    // Block until sound play finishes:
    while (WHDR_DONE and hdr.dwFlags)<>WHDR_DONE do
        ;

    CheckError(waveOutUnprepareHeader(wo, @hdr, SizeOf(hdr)));
  finally
    CheckError(waveOutClose(wo));
  end;
{$ELSE}
{$IFDEF ANDROID}
var
  BufferSize : Integer;
  iaudioTrack :  JAudioTrack;
  generatedSnd : TJavaArray<Byte>;
begin
  generatedSnd:=PCM16Bit(ASamples);

  BufferSize := TJAudioTrack.JavaClass.getMinBufferSize(GetSampleRate,
        TJAudioFormat.JavaClass.CHANNEL_OUT_MONO,
        TJAudioFormat.JavaClass.ENCODING_PCM_16BIT);

  iaudioTrack:= TJAudioTrack.JavaClass.init(TJAudioManager.JavaClass.STREAM_MUSIC,
                GetSampleRate, TJAudioFormat.JavaClass.CHANNEL_OUT_MONO,
                TJAudioFormat.JavaClass.ENCODING_PCM_16BIT, BufferSize,
                TJAudioTrack.JavaClass.MODE_STREAM);
  try
    iaudioTrack.setVolume(Volume*0.01);

    // Play the track
    iaudioTrack.play;
    iaudioTrack.write(generatedSnd, 0, generatedSnd.Length); // Load the track

  finally
    if iaudioTrack<>nil then
       iaudioTrack.release; // Track play done. Release track.
  end;
{$ENDIF}
{$ENDIF}
end;

class procedure TTone.SetVolume(Value: TVolume);
{$IFDEF MSWINDOWS}
var tmp : DWORD;
    wo: HWAVEOUT;
    fmt: TWaveFormatEx;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  fmt:=InitAudioSys;

  CheckError(waveOutOpen(@wo, WAVE_MAPPER, @fmt, 0, 0, CALLBACK_NULL));
  try
    tmp:=Round(Value*$FFFF*0.01);
    tmp:=(tmp shl 16)+tmp;
    CheckError(waveOutSetVolume(wo,tmp));
  finally
    CheckError(waveOutClose(wo));
  end;

  {$ELSE}
  FVolume:=Value;
  {$ENDIF}
end;

function Generate(const AFrequency:Single; const ADuration:Integer):TArray<Single>;
begin
  result:=TTone.GenerateSamples(AFrequency,ADuration);
end;

{$IFDEF MSWINDOWS}
// Code from:
// https://stackoverflow.com/questions/26917558/playing-pcm-wav-file-in-delphi
procedure PlayPCM(const AFrequency:Single; const ADuration:Integer);
begin
  TTone.Play(Generate(AFrequency,ADuration));
end;
{$ENDIF}

class procedure TTone.Play(const AFrequency:Single; const ADuration:Integer);
{$IFDEF MSWINDOWS}
begin
  if UsePCM then
     PlayPCM(AFrequency,ADuration)
  else
     Winapi.Windows.Beep(Round(AFrequency),ADuration);
{$ELSE}
{$IFDEF LINUX}
begin
  // TODO
{$ELSE}
{$IFDEF ANDROID}
begin
  TTone.Play(Generate(AFrequency,ADuration));
{$ENDIF}
{$ENDIF}
{$ENDIF}
end;

{$IFDEF ANDROID}
initialization
  TTone.Volume:=100;
  TTone.UsePCM:=True;
finalization
{$ENDIF}
end.
