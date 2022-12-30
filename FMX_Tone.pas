unit FMX_Tone;

interface

(*
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
  TTone=record
  public
    // Duration in Milliseconds (minimum 2 in Windows)
    class procedure Beep(const ADuration: Integer); static;

    // Frequency in Hertz
    class procedure Play(const AFrequency:Single; const ADuration:Integer); static;

    {$IFDEF MSWINDOWS}
    // Same as "Play", but using PCM Wav generated data instead of Winapi Beep
    class procedure PlayPCM(const AFrequency:Single; const ADuration:Integer); static;
    {$ENDIF}
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
  Volume: Integer;
  StreamType: Integer;
  ToneType: Integer;
  ToneGenerator: JToneGenerator;
begin
  Volume := TJToneGenerator.JavaClass.MAX_VOLUME;

  StreamType := TJAudioManager.JavaClass.STREAM_ALARM;
  ToneType := TJToneGenerator.JavaClass.TONE_DTMF_0;

  ToneGenerator := TJToneGenerator.JavaClass.init(StreamType, Volume);
  ToneGenerator.startTone(ToneType, ADuration);
{$ENDIF}
{$ENDIF}
{$ENDIF}
end;

const sampleRate = 8000;

function Generate(const AFrequency:Single; const ADuration:Integer):{$IFDEF ANDROID}TJavaArray{$ELSE}TArray{$ENDIF}<Byte>;
var
  idx : Integer;
  generatedSnd : {$IFDEF ANDROID}TJavaArray{$ELSE}TArray{$ENDIF}<Byte>;
  tmp : Single;

  procedure SetGenerated(const Sample:Integer; const Val:Single);
  var t : Integer;
  begin
    t:=Round(Sin(Sample*tmp)*Val*32767);

    // in 16 bit wav PCM, first byte is the low order byte
    generatedSnd[idx] := t and $00ff;
    Inc(idx);
    generatedSnd[idx] := (t and $ff00) shr 8;
    Inc(idx);
  end;

var
  NumSamples : Integer;
  i, ramp : Integer;
begin
  NumSamples := Trunc(ADuration * SampleRate * 0.001 * 0.5);

  {$IFDEF ANDROID}
  generatedSnd:=TJavaArray<Byte>.Create(2*numSamples);
  {$ELSE}
  SetLength(generatedSnd,2*NumSamples);
  {$ENDIF}

  tmp:=(AFrequency * 2 * PI) / sampleRate;

  // Amplitude ramp as a percent of sample count
  ramp := NumSamples div 120;

  idx := 0;

  // Ramp amplitude up (to avoid clicks)
  for i:=0 to ramp-1 do
      SetGenerated(i,i/ramp); // Ramp up to maximum

  // Max amplitude for most of the samples
  for i:=ramp to (NumSamples-1) - ramp do
      SetGenerated(i,1); // scale to maximum amplitude

  // Ramp amplitude down
  for i:=1 + (NumSamples-1) - ramp to NumSamples-1 do
      SetGenerated(i,(numSamples-i)/ramp); // Ramp down to zero

  result:=generatedSnd;
end;

{$IFDEF MSWINDOWS}

// Code from:
// https://stackoverflow.com/questions/26917558/playing-pcm-wav-file-in-delphi
class procedure TTone.PlayPCM(const AFrequency:Single; const ADuration:Integer);

  function InitAudioSys:TWaveFormatEx;
  begin
    with result do
    begin
      wFormatTag := WAVE_FORMAT_PCM;
      nChannels := 1; // Mono
      nSamplesPerSec := SampleRate;
      wBitsPerSample := 16;
      nAvgBytesPerSec := nChannels * nSamplesPerSec * wBitsPerSample div 8;
      nBlockAlign := nChannels * wBitsPerSample div 8;
      cbSize := 0;
    end;
  end;

  procedure CheckError(const Err:Cardinal);
  begin
    if Err<>MMSYSERR_NOERROR then
       raiseLastOSError(Err);
  end;

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
  Samples : TArray<Byte>;
begin
  Samples:=Generate(AFrequency,ADuration);

  fmt:=InitAudioSys;

  CheckError(waveOutOpen(@wo, WAVE_MAPPER, @fmt, 0, 0, CALLBACK_NULL));
  try
    InitHeader(hdr,fmt.nChannels,Samples);
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
end;
{$ENDIF}

class procedure TTone.Play(const AFrequency:Single; const ADuration:Integer);
{$IFDEF MSWINDOWS}
begin
  Winapi.Windows.Beep(Round(AFrequency),ADuration);
{$ELSE}
{$IFDEF LINUX}
begin
  // TODO
{$ELSE}
{$IFDEF ANDROID}
var
  bufferSize : Integer;
  iaudioTrack :  JAudioTrack;
  generatedSnd : TJavaArray<Byte>;
begin
  generatedSnd:=Generate(AFrequency,ADuration);

  bufferSize := TJAudioTrack.JavaClass.getMinBufferSize(sampleRate,
        TJAudioFormat.JavaClass.CHANNEL_OUT_MONO,
        TJAudioFormat.JavaClass.ENCODING_PCM_16BIT);

  iaudioTrack:= TJAudioTrack.JavaClass.init(TJAudioManager.JavaClass.STREAM_MUSIC,
                sampleRate, TJAudioFormat.JavaClass.CHANNEL_OUT_MONO,
                TJAudioFormat.JavaClass.ENCODING_PCM_16BIT, bufferSize,
                TJAudioTrack.JavaClass.MODE_STREAM);
  try
    // Play the track
    iaudioTrack.play;
    iaudioTrack.write(generatedSnd, 0, generatedSnd.Length); // Load the track

  finally
    if iaudioTrack<>nil then
       iaudioTrack.release; // Track play done. Release track.
  end;
{$ENDIF}
{$ENDIF}
{$ENDIF}
end;


// TODO:
// TTone.Volume:=50
// waveoutsetvolume

end.
