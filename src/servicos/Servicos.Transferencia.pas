unit Servicos.Transferencia;

interface

uses
  Repositorios.Interfaces,
  Modelos.Conta,
  Modelos.Lancamento;

type
  /// <summary>
  ///   Regra de negócio de transferência entre contas: valida, move o
  ///   saldo e registra os dois lançamentos (débito na origem, crédito
  ///   no destino) como uma única operação atômica.
  /// </summary>
  TServicoTransferencia = class
  private
    FRepositorioContas: IRepositorioConta;
    FRepositorioLancamentos: IRepositorioLancamento;
    FTransacao: ITransacao;
  public
    // Injeção de Dependência via construtor (D de SOLID): o serviço
    // recebe três INTERFACES, nunca uma classe concreta. Ele não sabe —
    // e não pode saber — se por trás existe PostgreSQL, um repositório
    // fake de teste (Fase 6) ou qualquer outra coisa. Essa mesma
    // característica é o que permite, mais adiante, reaproveitar
    // TServicoTransferencia tanto na API REST (Fase 7) quanto na tela
    // desktop (Fase 9) sem duplicar uma linha de regra de negócio.
    constructor Create(const ARepositorioContas: IRepositorioConta;
      const ARepositorioLancamentos: IRepositorioLancamento;
      const ATransacao: ITransacao);

    procedure Transferir(const AContaOrigemId, AContaDestinoId: Integer;
      const AValor: Currency);
  end;

implementation

uses
  Dominio.Excecoes;

constructor TServicoTransferencia.Create(const ARepositorioContas: IRepositorioConta;
  const ARepositorioLancamentos: IRepositorioLancamento;
  const ATransacao: ITransacao);
begin
  inherited Create;
  FRepositorioContas := ARepositorioContas;
  FRepositorioLancamentos := ARepositorioLancamentos;
  FTransacao := ATransacao;
end;

procedure TServicoTransferencia.Transferir(const AContaOrigemId, AContaDestinoId: Integer;
  const AValor: Currency);
var
  Origem, Destino: TConta;
begin
  // Validações de entrada acontecem ANTES de abrir a transação — não
  // faz sentido pagar o custo de iniciar uma transação no banco para
  // rejeitar algo que já sabemos, só olhando os parâmetros, que é
  // inválido.
  if AValor <= 0 then
    raise EValorInvalido.Create('O valor da transferencia deve ser positivo.');

  if AContaOrigemId = AContaDestinoId then
    // Regra que não existia no material original do curso — um bom
    // exemplo de caso de borda para cobrir com DUnitX na Fase 6 (o que
    // aconteceria aqui sem essa checagem? Origem e Destino apontariam
    // para o mesmo registro, e o saldo seria debitado e creditado ao
    // mesmo tempo, mascarando um erro de digitação do chamador).
    raise EValorInvalido.Create('Conta de origem e conta de destino nao podem ser iguais.');

  // Regra de ouro do FireDAC (Parte 5.4 do curso original): operações
  // que precisam ser "tudo ou nada" ficam dentro da mesma transação.
  // As quatro escritas abaixo (2 updates de conta + 2 inserts de
  // lançamento) só fazem sentido juntas — se a aplicação caísse entre a
  // terceira e a quarta escrita sem transação, o banco ficaria com o
  // saldo já debitado na origem, já creditado no destino, com um
  // lançamento de débito gravado, mas SEM o lançamento de crédito
  // correspondente: um extrato inconsistente. É exatamente esse
  // cenário que ITransacao existe para impedir.
  FTransacao.Iniciar;
  try
    Origem := FRepositorioContas.BuscarPorId(AContaOrigemId);
    Destino := FRepositorioContas.BuscarPorId(AContaDestinoId);
    // Se qualquer uma das duas contas não existir, BuscarPorId já
    // lança EContaNaoEncontrada (Fase 3) — o bloco except abaixo
    // reverte a transação e relança a mesma exceção, sem mascará-la.

    if Origem.Saldo < AValor then
      raise ESaldoInsuficiente.CreateFmt('Saldo insuficiente na conta %d.', [AContaOrigemId]);

    Origem.Saldo := Origem.Saldo - AValor;
    Destino.Saldo := Destino.Saldo + AValor;

    FRepositorioContas.Salvar(Origem);
    FRepositorioContas.Salvar(Destino);

    FRepositorioLancamentos.Salvar(
      TLancamento.Create(AContaOrigemId, -AValor, 'Transferencia enviada'));
    FRepositorioLancamentos.Salvar(
      TLancamento.Create(AContaDestinoId, AValor, 'Transferencia recebida'));

    FTransacao.Confirmar;
  except
    // Nunca "except on Exception do" silencioso: aqui, o único trabalho
    // do except é desfazer a transação e deixar a exceção original
    // (EContaNaoEncontrada, ESaldoInsuficiente, ou qualquer erro
    // inesperado do banco) seguir para quem chamou — "raise" sem
    // argumento relança a mesma exceção, preservando o tipo e a
    // mensagem originais.
    FTransacao.Reverter;
    raise;
  end;
end;

end.
