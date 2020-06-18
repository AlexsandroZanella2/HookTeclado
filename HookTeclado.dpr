library HookTeclado;

{
Demonstracao de Hook de teclado a nivel de sistema, Radikal.
Como o que queremos é capturar as teclas pressionadas em qualquer parte
do Windows, precisamos instalar a função CallBack que chamará
o Hook em uma DLL, que é esta mesma.
}

uses
  Windows,
  Messages;

const
  CM_MANDA_TECLA = WM_USER + $1000;

var
  HookDeTeclado     : HHook;
  ArquivoM    : THandle;
  PReceptor   : ^Integer;

function CallBackDelHook( Code    : Integer;
                          wParam  : WPARAM;
                          lParam  : LPARAM
                          )       : LRESULT; stdcall;

{Esta é a funcao CallBack que chamará o hook.}
begin
  {Se uma tecla foi pressionada ou liberada}
  if code=HC_ACTION then begin
   {Observamos se o arquivo existe}
   ArquivoM:=OpenFileMapping(FILE_MAP_WRITE,False,'OReceptor');
   {Se nao existe, nao enviamos nada para a aplicacao receptora}
   if ArquivoM<>0 then begin
     PReceptor:=MapViewOfFile(ArquivoM,FILE_MAP_WRITE,0,0,0);
     PostMessage(PReceptor^,CM_MANDA_TECLA,wParam,lParam);
     UnmapViewOfFile(PReceptor);
     CloseHandle(ArquivoM);
   end;
  end;
  {Chamamos ao seguinte hook de teclado da cadeia}
  Result := CallNextHookEx(HookDeTeclado, Code, wParam, lParam)
end;

procedure HookOn; stdcall;
{Procedure que instala o hook}
begin
  HookDeTeclado:=SetWindowsHookEx(WH_KEYBOARD, @CallBackDelHook, HInstance , 0);
end;

procedure HookOff;  stdcall;
begin
  {procedure para desinstalar o hook}
  UnhookWindowsHookEx(HookDeTeclado);
end;

exports
  {Exportamos as procedures...}
  HookOn,
  HookOff;

begin
end.

