unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls;

const
  NomeDLL       = 'HookTeclado.dll';
  CM_MANDA_TECLA  = WM_USER + $1000;


type
  THookTeclado=procedure; stdcall;

type
    TForm1 = class(TForm)
    Memo1: TMemo;
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

private
    { Private declarations }
    ArquivoM       : THandle;
    PReceptor      : ^Integer;
    HandleDLL      : THandle;
    HookOn,
    HookOff        : THookTeclado;

    procedure LlegaDelHook(var message: TMessage); message  CM_MANDA_TECLA;

public
    { Public declarations }
end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.FormCreate(Sender: TObject);
begin
  {Nao queremos que o memo seja editado conforme a tecla pressionada}
  Memo1.ReadOnly:=false;

  HandleDLL:=LoadLibrary( PChar(ExtractFilePath(Application.Exename)+NomeDLL ) );
  if HandleDLL = 0 then raise Exception.Create('Não foi possível carregar a DLL!');

  @HookOn :=GetProcAddress(HandleDLL, 'HookOn');
  @HookOff:=GetProcAddress(HandleDLL, 'HookOff');

  IF not assigned(HookOn) or
     not assigned(HookOff)  then
     raise Exception.Create('Não foram encontradas as funções na DLL');

  {Criamos o arquivo de memoria}
  ArquivoM:=CreateFileMapping( $FFFFFFFF,
                               nil,
                               PAGE_READWRITE,
                               0,
                               SizeOf(Integer),
                               'OReceptor');

    {Se o arquivo nao se criou, erro}
    if ArquivoM=0 then
      raise Exception.Create( 'Erro ao criar o arquivo');

    {Direcionamos nossa estrutura ao arquivo de memoria}
    PReceptor:=MapViewOfFile(ArquivoM,FILE_MAP_WRITE,0,0,0);

    {Escrevemos dados no arquivo de memoria}
    PReceptor^:=Handle;
    HookOn;
end;

procedure TForm1.LlegaDelHook(var message: TMessage);
var
   NomeTecla : array[0..100] of char;
   Acao      : string;
begin
  {Traduzimos de "Virtual key Code" a "TEXTO"}
  GetKeyNameText(Message.LParam,@NomeTecla,100);
  {Observamos se a tecla foi pressionada, soltada o repetida}
  if ((Message.lParam shr 31) and 1)=1 then
    Acao:='Solta'
  else
    if ((Message.lParam shr 30) and 1)=1 then
      Acao:='Repetida'
    else Acao:='Pressionada';

  Memo1.Lines.Add( Acao+
                      ' tecla: '+
                      String(NomeTecla) );
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  {Desativamos o Hook}
  if Assigned(HookOff) then
    HookOff;

  {Liberamos a DLL}
  if HandleDLL<>0 then
    FreeLibrary(HandleDLL);

  {Fechamos a vista do arquivo e o arquivo}
  if ArquivoM<>0 then begin
    UnmapViewOfFile(PReceptor);
    CloseHandle(ArquivoM);
  end;

end;

end.

