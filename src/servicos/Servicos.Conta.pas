unit Servicos.Conta;

interface

uses
  Repositorios.Interfaces,
  Modelos.Conta,
  Modelos.Lancamento;

type
  /// <summary>
  ///   Consultas de conta: saldo atual e extrato. Não há regra de
  ///   negócio "pesada" aqui — mas o serviço existe mesmo assim (em vez
  ///   de a API ou a tela desktop chamarem IRepositorioConta
  ///   diretamente) porque é este o único lugar da arquitetura onde
  ///   regras futuras de consulta (ex.: "só mostra saldo para usuários
  ///   autenticados", "extrato paginado") vão morar. Se a UI dependesse
  ///   do repositório diretamente, adicionar essa regra amanhã
  ///   significaria caçar cada tela e cada rota que chamam o
  ///   repositório — com o serviço como intermediário, muda-se um único
  ///   lugar.
  TServicoConta = class
  private
    FRepositorioContas: IRepositorioConta;
    FRepositorioLancamentos: IRepositorioLancamento;
  public
    constructor Create(const ARepositorioContas: IRepositorioConta;
      const ARepositorioLancamentos: IRepositorioLancamento);
    function BuscarPorId(const AId: Integer): TConta;
    function Extrato(const AId: Integer): TArray<TLancamento>;
  end;

implementation

constructor TServicoConta.Create(const ARepositorioContas: IRepositorioConta;
  const ARepositorioLancamentos: IRepositorioLancamento);
begin
  inherited Create;
  FRepositorioContas := ARepositorioContas;
  FRepositorioLancamentos := ARepositorioLancamentos;
end;

function TServicoConta.BuscarPorId(const AId: Integer): TConta;
begin
  // Repassa para o repositório; se a conta não existir,
  // EContaNaoEncontrada (Dominio.Excecoes) atravessa este método sem
  // ser capturada aqui — não há nada de útil que TServicoConta possa
  // fazer com esse erro além de deixá-lo subir para quem chamou.
  Result := FRepositorioContas.BuscarPorId(AId);
end;

function TServicoConta.Extrato(const AId: Integer): TArray<TLancamento>;
begin
  Result := FRepositorioLancamentos.ListarPorConta(AId);
end;

end.
