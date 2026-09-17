unit Testes.ServicoTransferencia;

interface

uses
  DUnitX.TestFramework,
  Servicos.Transferencia,
  Repositorios.Interfaces,
  Repositorios.Fakes,
  Modelos.Conta,
  Modelos.Lancamento,
  Dominio.Excecoes,
  System.SysUtils;

type
  [TestFixture]
  TTesteServicoTransferencia = class
  private
    FRepoContas: TRepositorioContaFake;
    FRepoLancamentos: TRepositorioLancamentoFake;
    FTransacao: TTransacaoFake;
    FServico: TServicoTransferencia;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Transferir_ComSaldoSuficiente_AtualizaOsDoisSaldosEConfirmaTransacao;

    [Test]
    procedure Transferir_ComSaldoSuficiente_GeraDoisLancamentosComValoresOpostos;

    [Test]
    procedure Transferir_ComSaldoExatoIgualAoValor_ZeraContaOrigem;

    [Test]
    procedure Transferir_ComSaldoInsuficiente_LancaExcecaoERevertaTransacao;

    [Test]
    procedure Transferir_ComValorZeroOuNegativo_LancaExcecao;

    [Test]
    procedure Transferir_ComContaOrigemIgualDestino_LancaExcecao;

    [Test]
    procedure Transferir_ComContaInexistente_LancaExcecaoERevertaTransacao;
  end;

implementation

procedure TTesteServicoTransferencia.Setup;
begin
  // Cada teste começa com repositórios fake NOVOS (nada de estado
  // vazando de um teste para o outro) e o mesmo cenário: conta 1 com
  // saldo 1000, conta 2 com saldo 50.
  FRepoContas := TRepositorioContaFake.Create;
  FRepoContas.Adicionar(TConta.Create(1, 1, 1000));
  FRepoContas.Adicionar(TConta.Create(2, 1, 50));

  FRepoLancamentos := TRepositorioLancamentoFake.Create;
  FTransacao := TTransacaoFake.Create;

  // Injeção de Dependência via construtor (D de SOLID), de novo: o
  // mesmo TServicoTransferencia que vai rodar contra PostgreSQL em
  // produção roda aqui contra três fakes em memória, sem mudar uma
  // linha da classe testada — só trocamos o que é injetado.
  FServico := TServicoTransferencia.Create(FRepoContas, FRepoLancamentos, FTransacao);
end;

procedure TTesteServicoTransferencia.TearDown;
begin
  FServico.Free;
  // FRepoContas, FRepoLancamentos e FTransacao são referenciados por
  // interface dentro de FServico (ITransacao, IRepositorioConta,
  // IRepositorioLancamento) — mas as variáveis de campo aqui na classe
  // de teste são dos tipos CONCRETOS (TRepositorioContaFake etc.),
  // porque os testes abaixo precisam inspecionar estado que não faz
  // parte da interface pública (ex.: TTransacaoFake.Confirmada). Como
  // são TInterfacedObject, ainda assim não chamamos .Free nelas: a
  // última referência de interface (dentro de FServico) já foi
  // liberada pelo Free acima, e a contagem de referências cuida do
  // resto.
end;

procedure TTesteServicoTransferencia.Transferir_ComSaldoSuficiente_AtualizaOsDoisSaldosEConfirmaTransacao;
begin
  FServico.Transferir(1, 2, 300);

  Assert.AreEqual<Currency>(700, FRepoContas.BuscarPorId(1).Saldo);
  Assert.AreEqual<Currency>(350, FRepoContas.BuscarPorId(2).Saldo);
  Assert.IsTrue(FTransacao.Confirmada, 'A transacao deveria ter sido confirmada.');
  Assert.IsFalse(FTransacao.Revertida, 'A transacao NAO deveria ter sido revertida.');
end;

procedure TTesteServicoTransferencia.Transferir_ComSaldoSuficiente_GeraDoisLancamentosComValoresOpostos;
var
  ExtratoOrigem, ExtratoDestino: TArray<TLancamento>;
begin
  FServico.Transferir(1, 2, 300);

  ExtratoOrigem := FRepoLancamentos.ListarPorConta(1);
  ExtratoDestino := FRepoLancamentos.ListarPorConta(2);

  Assert.AreEqual(1, Length(ExtratoOrigem));
  Assert.AreEqual(1, Length(ExtratoDestino));
  Assert.AreEqual<Currency>(-300, ExtratoOrigem[0].Valor);
  Assert.AreEqual<Currency>(300, ExtratoDestino[0].Valor);
end;

procedure TTesteServicoTransferencia.Transferir_ComSaldoExatoIgualAoValor_ZeraContaOrigem;
begin
  // Caso de borda que o material original não cobre: transferir
  // exatamente o saldo disponível deve ser permitido (a regra é
  // "Origem.Saldo < AValor", não "<="), deixando a conta de origem com
  // saldo zero — e não com uma ESaldoInsuficiente indevida.
  FServico.Transferir(1, 2, 1000);

  Assert.AreEqual<Currency>(0, FRepoContas.BuscarPorId(1).Saldo);
  Assert.AreEqual<Currency>(1050, FRepoContas.BuscarPorId(2).Saldo);
end;

procedure TTesteServicoTransferencia.Transferir_ComSaldoInsuficiente_LancaExcecaoERevertaTransacao;
begin
  Assert.WillRaise(
    procedure
    begin
      FServico.Transferir(1, 2, 5000); // maior que o saldo da conta 1
    end,
    ESaldoInsuficiente);

  Assert.IsTrue(FTransacao.Revertida, 'A transacao deveria ter sido revertida.');
  Assert.IsFalse(FTransacao.Confirmada, 'A transacao NAO deveria ter sido confirmada.');
  // E o saldo original precisa continuar intacto: nenhuma escrita
  // parcial deve ter "vazado" para os repositórios antes da exceção.
  Assert.AreEqual<Currency>(1000, FRepoContas.BuscarPorId(1).Saldo);
end;

procedure TTesteServicoTransferencia.Transferir_ComValorZeroOuNegativo_LancaExcecao;
begin
  Assert.WillRaise(
    procedure
    begin
      FServico.Transferir(1, 2, -10);
    end,
    EValorInvalido);
end;

procedure TTesteServicoTransferencia.Transferir_ComContaOrigemIgualDestino_LancaExcecao;
begin
  // Regra adicionada nesta adaptação (Fase 4) — sem ela, a mesma conta
  // seria debitada e creditada ao mesmo tempo, escondendo um provável
  // erro de digitação do chamador.
  Assert.WillRaise(
    procedure
    begin
      FServico.Transferir(1, 1, 100);
    end,
    EValorInvalido);
end;

procedure TTesteServicoTransferencia.Transferir_ComContaInexistente_LancaExcecaoERevertaTransacao;
begin
  Assert.WillRaise(
    procedure
    begin
      FServico.Transferir(1, 999, 100); // conta 999 nao existe no fake
    end,
    EContaNaoEncontrada);

  Assert.IsTrue(FTransacao.Revertida, 'A transacao deveria ter sido revertida.');
end;

initialization
  TDUnitX.RegisterTestFixture(TTesteServicoTransferencia);

end.
