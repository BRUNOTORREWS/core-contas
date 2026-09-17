program CoreContasDesktop;

uses
  Vcl.Forms,
  Modelos.Conta in '..\src\modelos\Modelos.Conta.pas',
  Modelos.Cliente in '..\src\modelos\Modelos.Cliente.pas',
  Modelos.Lancamento in '..\src\modelos\Modelos.Lancamento.pas',
  Dominio.Excecoes in '..\src\dominio\Dominio.Excecoes.pas',
  Repositorios.Interfaces in '..\src\repositorios\Repositorios.Interfaces.pas',
  Repositorios.Conexao in '..\src\repositorios\Repositorios.Conexao.pas',
  Repositorios.FireDAC in '..\src\repositorios\Repositorios.FireDAC.pas',
  Repositorios.Factory in '..\src\repositorios\Repositorios.Factory.pas',
  Servicos.Conta in '..\src\servicos\Servicos.Conta.pas',
  Servicos.Transferencia in '..\src\servicos\Servicos.Transferencia.pas',
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
