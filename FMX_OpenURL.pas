unit FMX_OpenURL;

interface

type
  TOpenURL=class
    class procedure Go(const URL:String);
  end;

implementation

uses
  {$IFDEF POSIX}
  Posix.Stdlib;
  {$ENDIF}

  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  Winapi.ShellAPI;
  {$ENDIF}

class procedure TOpenURL.Go(const URL: string);
begin
  {$IFDEF POSIX}
  _system(PAnsiChar('open '+AnsiString(URL)));
  {$ENDIF}

  {$IFDEF MSWINDOWS}
  ShellExecute(0,'OPEN',PChar(URL),'','',SW_SHOWNORMAL);
  {$ENDIF}
end;

end.
