unit Repositorios.FireDAC;

interface

uses
  FireDAC.Comp.Client,
  Repositorios.Interfaces,
  Modelos.Conta,
  Modelos.Lancamento,
  Modelos.Cliente;

type
  // TInterfacedObject: cada classe abaixo implementa uma interface de
  // Repositorios.Interfaces e ganha contagem de referências automática
  // (Parte 1 do curso — nunca chame .Free numa variável destes tipos
  // quando ela estiver tipada como a interface; ver Fase de
  // API/Desktop, onde essas classes são instanciadas).

  TRepositorioContaFireDAC = class(TInterfacedObject, IRepositorioConta)
  private
    FConexao: TFDConnection;
    // A conexão é recebida, nunca criada aqui dentro (Injeção de
    // Dependência via construtor — D de SOLID). O repositório não é
    // dono da conexão e não a libera: quem a criou (o "ponto de
    // composição" da aplicação, ou o Singleton TConexaoPostgreSQL) é
    // responsável pelo seu ciclo de vida.
  public
    constructor Create(const AConexao: TFDConnection);
    function BuscarPorId(const AId: Integer): TConta;
    procedure Salvar(const AConta: TConta);
  end;

  TRepositorioLancamentoFireDAC = class(TInterfacedObject, IRepositorioLancamento)
  private
    FConexao: TFDConnection;
  public
    constructor Create(const AConexao: TFDConnection);
    function Salvar(const ALancamento: TLancamento): TLancamento;
    function ListarPorConta(const AIdConta: Integer): TArray<TLancamento>;
  end;

  TRepositorioClienteFireDAC = class(TInterfacedObject, IRepositorioCliente)
  private
    FConexao: TFDConnection;
  public
    constructor Create(const AConexao: TFDConnection);
    function BuscarPorId(const AId: Integer): TCliente;
  end;

  TTransacaoFireDAC = class(TInterfacedObject, ITransacao)
  private
    FConexao: TFDConnection;
  public
    constructor Create(const AConexao: TFDConnection);
    procedure Iniciar;
    procedure Confirmar;
    procedure Reverter;
  end;

implementation

uses
  Dominio.Excecoes;

{ TRepositorioContaFireDAC }

constructor TRepositorioContaFireDAC.Create(const AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

function TRepositorioContaFireDAC.BuscarPorId(const AId: Integer): TConta;
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;
    // Identificadores em minúsculas, sem aspas — coerente com o "case
    // folding" do PostgreSQL (Fase 1). O Postgres dobraria para
    // minúsculo de qualquer forma mesmo se você escrevesse ID_CONTA sem
    // aspas; escrever já em minúsculo é só disciplina para nunca
    // precisar pensar nisso.
    Qry.SQL.Text := 'select id_conta, id_cliente, saldo from conta where id_conta = :id';
    Qry.ParamByName('id').AsInteger := AId;
    Qry.Open;

    if Qry.IsEmpty then
      // Exceção de domínio (Dominio.Excecoes), não um Exception
      // genérico: é ela que a API (Fase 7) vai capturar
      // especificamente para responder HTTP 404 — um "except on
      // Exception" ali trataria um bug de programação da mesma forma
      // que "conta não existe", escondendo problemas reais.
      raise EContaNaoEncontrada.CreateFmt('Conta %d nao encontrada.', [AId]);

    Result := TConta.Create(
      Qry.FieldByName('id_conta').AsInteger,
      Qry.FieldByName('id_cliente').AsInteger,
      Qry.FieldByName('saldo').AsCurrency);
  finally
    Qry.Free;
  end;
end;

procedure TRepositorioContaFireDAC.Salvar(const AConta: TConta);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;
    Qry.SQL.Text := 'update conta set saldo = :saldo where id_conta = :id';
    // Este UPDATE dispara o trigger trg_conta_before_update criado na
    // Fase 1: o banco recusa a gravação (RAISE EXCEPTION) se, por
    // qualquer motivo, o saldo chegar negativo até aqui — mesmo que o
    // TServicoTransferencia (Fase 5) já devesse ter barrado isso antes.
    // Defesa em profundidade: duas camadas concordando na mesma regra.
    Qry.ParamByName('saldo').AsCurrency := AConta.Saldo;
    Qry.ParamByName('id').AsInteger := AConta.Id;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

{ TRepositorioLancamentoFireDAC }

constructor TRepositorioLancamentoFireDAC.Create(const AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

function TRepositorioLancamentoFireDAC.Salvar(const ALancamento: TLancamento): TLancamento;
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;
    Qry.SQL.Text :=
      'insert into lancamento (id_conta, valor, descricao) ' +
      'values (:id_conta, :valor, :descricao) ' +
      'returning id_lancamento, data_lancamento';
    // RETURNING é um recurso do PostgreSQL sem equivalente direto num
    // INSERT comum do Firebird clássico: devolve, na mesma viagem ao
    // banco, as colunas que o próprio servidor gerou (aqui, o id da
    // identity e o timestamp do DEFAULT now()). Sem RETURNING, seria
    // preciso um segundo round-trip (ex.: SELECT CURRVAL de uma
    // sequência) só para descobrir o que acabou de ser inserido — e é
    // exatamente essa segunda consulta que o material original do
    // curso nunca fazia, deixando o Id do lançamento sempre zerado ao
    // reconstruir o extrato.
    Qry.ParamByName('id_conta').AsInteger := ALancamento.IdConta;
    Qry.ParamByName('valor').AsCurrency := ALancamento.Valor;
    Qry.ParamByName('descricao').AsString := ALancamento.Descricao;
    Qry.Open; // Open, não ExecSQL: um INSERT ... RETURNING devolve linhas, como um SELECT

    Result := TLancamento.Create(
      Qry.FieldByName('id_lancamento').AsInteger,
      ALancamento.IdConta,
      ALancamento.Valor,
      ALancamento.Descricao,
      Qry.FieldByName('data_lancamento').AsDateTime);
  finally
    Qry.Free;
  end;
end;

function TRepositorioLancamentoFireDAC.ListarPorConta(
  const AIdConta: Integer): TArray<TLancamento>;
var
  Qry: TFDQuery;
  Lista: TArray<TLancamento>;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;
    // Consultando a VIEW vw_extrato_conta criada na Fase 1, não a
    // tabela lancamento diretamente: é o ganho prático de ter isolado o
    // extrato numa view lá no schema — se amanhã o extrato precisar
    // trazer também o nome do cliente (um JOIN a mais), a mudança
    // acontece só no banco, sem tocar neste repositório nem em quem o
    // consome.
    Qry.SQL.Text :=
      'select id_lancamento, id_conta, valor, descricao, data_lancamento ' +
      'from vw_extrato_conta where id_conta = :id_conta';
    Qry.ParamByName('id_conta').AsInteger := AIdConta;
    Qry.Open;

    Lista := [];
    while not Qry.Eof do
    begin
      Lista := Lista + [TLancamento.Create(
        Qry.FieldByName('id_lancamento').AsInteger,
        Qry.FieldByName('id_conta').AsInteger,
        Qry.FieldByName('valor').AsCurrency,
        Qry.FieldByName('descricao').AsString,
        Qry.FieldByName('data_lancamento').AsDateTime)];
      Qry.Next;
    end;
    Result := Lista;
  finally
    Qry.Free;
  end;
end;

{ TRepositorioClienteFireDAC }

constructor TRepositorioClienteFireDAC.Create(const AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

function TRepositorioClienteFireDAC.BuscarPorId(const AId: Integer): TCliente;
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;
    Qry.SQL.Text :=
      'select id_cliente, nome, cnpj_cpf, endereco, bairro, cidade, uf, cep ' +
      'from cliente where id_cliente = :id';
    Qry.ParamByName('id').AsInteger := AId;
    Qry.Open;

    if Qry.IsEmpty then
      raise EClienteNaoEncontrado.CreateFmt('Cliente %d nao encontrado.', [AId]);

    Result := TCliente.Create(
      Qry.FieldByName('id_cliente').AsInteger,
      Qry.FieldByName('nome').AsString,
      Qry.FieldByName('cnpj_cpf').AsString,
      Qry.FieldByName('endereco').AsString,
      Qry.FieldByName('bairro').AsString,
      Qry.FieldByName('cidade').AsString,
      Qry.FieldByName('uf').AsString,
      Qry.FieldByName('cep').AsString);
  finally
    Qry.Free;
  end;
end;

{ TTransacaoFireDAC }

constructor TTransacaoFireDAC.Create(const AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

procedure TTransacaoFireDAC.Iniciar;
begin
  // TFDConnection.StartTransaction usa uma transação padrão interna
  // quando nenhum TFDTransaction explícito foi atribuído a
  // Conexao.Transaction — dispensa criar e gerenciar um componente
  // TFDTransaction à parte só para este caso de uso simples (Parte 5.4
  // do curso original mostra a variante com o componente explícito,
  // útil quando se precisa de mais de uma transação simultânea ou de
  // um nível de isolamento específico).
  FConexao.StartTransaction;
end;

procedure TTransacaoFireDAC.Confirmar;
begin
  FConexao.Commit;
end;

procedure TTransacaoFireDAC.Reverter;
begin
  FConexao.Rollback;
end;

end.
