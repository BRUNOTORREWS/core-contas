unit Servicos.Cobranca;

interface

uses
  Repositorios.Interfaces,
  Boleto.Interfaces;

type
  /// <summary>
  ///   Regra de negócio de emissão de cobrança: valida os dados,
  ///   localiza o cliente sacado, e delega a emissão em si para um
  ///   IEmissorBoleto.
  /// </summary>
  TServicoCobranca = class
  private
    FRepositorioClientes: IRepositorioCliente;
    FEmissorBoleto: IEmissorBoleto;
  public
    // Injeção de Dependência via construtor, de novo — o mesmo padrão
    // de TServicoTransferencia (Fase 4), agora aplicado a uma dependência
    // que nem sequer é um repositório: IEmissorBoleto. Uma vez
    // internalizado o padrão (receba interfaces, não classes concretas,
    // via construtor), ele se repete de forma idêntica em qualquer
    // dependência nova — é isso que faz a arquitetura "escalar" sem
    // ficar mais complicada a cada peça nova.
    constructor Create(const ARepositorioClientes: IRepositorioCliente;
      const AEmissorBoleto: IEmissorBoleto);
    procedure EmitirCobranca(const AIdLancamento, AIdCliente: Integer;
      const AValor: Currency; const AVencimento: TDateTime);
  end;

implementation

uses
  System.SysUtils,
  Modelos.Cliente,
  Dominio.Excecoes;

constructor TServicoCobranca.Create(const ARepositorioClientes: IRepositorioCliente;
  const AEmissorBoleto: IEmissorBoleto);
begin
  inherited Create;
  FRepositorioClientes := ARepositorioClientes;
  FEmissorBoleto := AEmissorBoleto;
end;

procedure TServicoCobranca.EmitirCobranca(const AIdLancamento, AIdCliente: Integer;
  const AValor: Currency; const AVencimento: TDateTime);
var
  Sacado: TCliente;
  NumeroDocumento: string;
begin
  // As mesmas duas validações de EValorInvalido já usadas em
  // TServicoTransferencia (Fase 4) — não porque foram copiadas sem
  // pensar, mas porque "valor de uma operação financeira" é a mesma
  // regra de negócio em qualquer lugar do domínio: precisa ser
  // positivo. Reaproveitar a MESMA exceção de domínio (em vez de criar
  // uma EValorInvalidoCobranca separada) também é proposital: quem
  // consome a API só precisa aprender um tipo de erro para "valor
  // inválido", não um por operação.
  if AValor <= 0 then
    raise EValorInvalido.Create('O valor da cobranca deve ser positivo.');

  if AVencimento < Date then
    raise EValorInvalido.Create('A data de vencimento nao pode estar no passado.');

  // Se o cliente não existir, EClienteNaoEncontrado (Fase 3) atravessa
  // este método sem ser capturada aqui — mesmo raciocínio já aplicado
  // em TServicoConta.BuscarPorId (Fase 4).
  Sacado := FRepositorioClientes.BuscarPorId(AIdCliente);

  // NossoNumero/NumeroDocumento precisam ser únicos por cedente (regra
  // do próprio banco, não nossa) — usar o id do lançamento que originou
  // a cobrança, formatado com zeros à esquerda, garante unicidade sem
  // precisar de mais uma sequência só para isso.
  NumeroDocumento := Format('%.10d', [AIdLancamento]);

  FEmissorBoleto.Emitir(NumeroDocumento, AValor, AVencimento, Sacado);
end;

end.
