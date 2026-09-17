unit Repositorios.Fakes;

interface

uses
  System.Generics.Collections,
  Repositorios.Interfaces,
  Modelos.Conta,
  Modelos.Lancamento;

type
  /// <summary>
  ///   Implementação em memória de IRepositorioConta, usada apenas nos
  ///   testes com DUnitX (Fase 5). Nunca toca no PostgreSQL.
  /// </summary>
  TRepositorioContaFake = class(TInterfacedObject, IRepositorioConta)
  private
    FContas: TDictionary<Integer, TConta>;
  public
    constructor Create;
    destructor Destroy; override;
    function BuscarPorId(const AId: Integer): TConta;
    procedure Salvar(const AConta: TConta);
    // Método auxiliar, fora da interface IRepositorioConta — existe só
    // para montar o cenário de cada teste (ex.: "a conta 1 começa com
    // saldo 1000"). Não é Open/Closed nem Repository pattern: é um
    // detalhe de implementação do fake, que nenhum código de produção
    // chama.
    procedure Adicionar(const AConta: TConta);
  end;

  /// <summary>
  ///   Implementação em memória de IRepositorioLancamento.
  /// </summary>
  TRepositorioLancamentoFake = class(TInterfacedObject, IRepositorioLancamento)
  private
    FLancamentos: TList<TLancamento>;
    FProximoId: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Salvar(const ALancamento: TLancamento): TLancamento;
    function ListarPorConta(const AIdConta: Integer): TArray<TLancamento>;
  end;

  /// <summary>
  ///   Implementação em memória de ITransacao — em vez de
  ///   StartTransaction/Commit/Rollback num TFDConnection, apenas
  ///   registra o que foi chamado, para os testes poderem verificar que
  ///   TServicoTransferencia confirma no caminho feliz e reverte quando
  ///   algo dá errado.
  /// </summary>
  TTransacaoFake = class(TInterfacedObject, ITransacao)
  private
    FIniciada: Boolean;
    FConfirmada: Boolean;
    FRevertida: Boolean;
  public
    procedure Iniciar;
    procedure Confirmar;
    procedure Reverter;
    property Iniciada: Boolean read FIniciada;
    property Confirmada: Boolean read FConfirmada;
    property Revertida: Boolean read FRevertida;
  end;

implementation

uses
  System.SysUtils,
  Dominio.Excecoes;

{ TRepositorioContaFake }

constructor TRepositorioContaFake.Create;
begin
  inherited Create;
  FContas := TDictionary<Integer, TConta>.Create;
end;

destructor TRepositorioContaFake.Destroy;
begin
  FContas.Free;
  inherited;
end;

function TRepositorioContaFake.BuscarPorId(const AId: Integer): TConta;
begin
  // Liskov Substitution (L de SOLID), na prática: este fake precisa
  // honrar o MESMO contrato de erro que TRepositorioContaFireDAC (Fase
  // 3) — lançar EContaNaoEncontrada para um id inexistente, nunca
  // devolver silenciosamente um TConta "vazio" (Default(TConta), com
  // Id = 0 e Saldo = 0). Se o fake se comportasse diferente da
  // implementação real neste ponto, TServicoTransferencia passaria nos
  // testes mas se comportaria diferente contra o PostgreSQL de
  // verdade — o pior tipo de teste, o que mente.
  if not FContas.TryGetValue(AId, Result) then
    raise EContaNaoEncontrada.CreateFmt('Conta %d nao encontrada.', [AId]);
end;

procedure TRepositorioContaFake.Salvar(const AConta: TConta);
begin
  FContas.AddOrSetValue(AConta.Id, AConta);
end;

procedure TRepositorioContaFake.Adicionar(const AConta: TConta);
begin
  FContas.Add(AConta.Id, AConta);
end;

{ TRepositorioLancamentoFake }

constructor TRepositorioLancamentoFake.Create;
begin
  inherited Create;
  FLancamentos := TList<TLancamento>.Create;
end;

destructor TRepositorioLancamentoFake.Destroy;
begin
  FLancamentos.Free;
  inherited;
end;

function TRepositorioLancamentoFake.Salvar(const ALancamento: TLancamento): TLancamento;
begin
  Inc(FProximoId);
  // Simula, na memória, o "insert ... returning id_lancamento,
  // data_lancamento" do PostgreSQL (Fase 3): o objetivo não é
  // reproduzir o SGBD, é honrar o mesmo CONTRATO da interface —
  // devolver um TLancamento com Id já preenchido.
  Result := TLancamento.Create(FProximoId, ALancamento.IdConta, ALancamento.Valor,
    ALancamento.Descricao, Now);
  FLancamentos.Add(Result);
end;

function TRepositorioLancamentoFake.ListarPorConta(
  const AIdConta: Integer): TArray<TLancamento>;
var
  Lista: TArray<TLancamento>;
  Item: TLancamento;
begin
  Lista := [];
  for Item in FLancamentos do
    if Item.IdConta = AIdConta then
      Lista := Lista + [Item];
  Result := Lista;
end;

{ TTransacaoFake }

procedure TTransacaoFake.Iniciar;
begin
  FIniciada := True;
end;

procedure TTransacaoFake.Confirmar;
begin
  FConfirmada := True;
end;

procedure TTransacaoFake.Reverter;
begin
  FRevertida := True;
end;

end.
