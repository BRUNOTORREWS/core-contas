program CoreContasTestes;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Modelos.Conta in '..\src\modelos\Modelos.Conta.pas',
  Modelos.Cliente in '..\src\modelos\Modelos.Cliente.pas',
  Modelos.Lancamento in '..\src\modelos\Modelos.Lancamento.pas',
  Dominio.Excecoes in '..\src\dominio\Dominio.Excecoes.pas',
  Repositorios.Interfaces in '..\src\repositorios\Repositorios.Interfaces.pas',
  Repositorios.Fakes in '..\src\repositorios\Repositorios.Fakes.pas',
  Servicos.Transferencia in '..\src\servicos\Servicos.Transferencia.pas',
  Servicos.Conta in '..\src\servicos\Servicos.Conta.pas',
  Testes.ServicoTransferencia in 'Testes.ServicoTransferencia.pas';

// Note o que NÃO está nesta lista: Repositorios.FireDAC,
// Repositorios.Conexao, Repositorios.Factory. O projeto de testes
// nunca referencia a implementação concreta contra PostgreSQL nem a
// unit FireDAC.Comp.Client — é a prova, em forma de "isso nem compila
// se eu tentar", de que TServicoTransferencia realmente não depende de
// infraestrutura nenhuma. Rodar estes testes não exige um PostgreSQL
// rodando em lugar nenhum.

{$R *.RES}

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  ReportMemoryLeaksOnShutdown := True;
  try
    // TDUnitX.CreateRunner cria o executor de testes; UseRTTI faz com
    // que ele descubra as classes marcadas com [TestFixture] via
    // reflexão (RTTI estendido — Object Pascal moderno, Parte 1 do
    // curso original), sem precisar de nenhuma lista manual de testes.
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    runner.FailsOnNoAsserts := False;

    // Logger de console: imprime cada teste e o resumo final no
    // terminal (a mesma saída "3 de 3 testes executados, 0 falharam"
    // ilustrada na Parte 7.4 do curso original).
    logger := TDUnitXConsoleLogger.Create(True);
    runner.AddLogger(logger);

    // Logger em XML (formato NUnit): útil para integrar com CI/CD no
    // futuro, sem precisar mudar nada no projeto de teste em si.
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Concluido.. pressione <Enter> para sair.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.
