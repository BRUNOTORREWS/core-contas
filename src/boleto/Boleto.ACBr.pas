unit Boleto.ACBr;

interface

uses
  ACBrBoleto,
  ACBrBoletoTitulo,
  Boleto.Interfaces,
  Modelos.Cliente;

type
  /// <summary>
  ///   Implementação de IEmissorBoleto usando o componente TACBrBoleto,
  ///   do framework ACBr.
  /// </summary>
  TEmissorBoletoACBr = class(TInterfacedObject, IEmissorBoleto)
  private
    FACBrBoleto: TACBrBoleto;
    // Recebido pronto via construtor — Banco e Cedente já configurados
    // por quem montou o objeto (o ponto de composição da aplicação,
    // igual fizemos com TFDConnection na Fase 3). Esta classe não sabe
    // qual banco está sendo usado nem os dados do cedente; só sabe
    // "criar um título e mandar imprimir".
  public
    constructor Create(const AACBrBoleto: TACBrBoleto);
    procedure Emitir(const ANumeroDocumento: string; const AValor: Currency;
      const AVencimento: TDateTime; const ASacado: TCliente);
  end;

implementation

uses
  System.SysUtils;

constructor TEmissorBoletoACBr.Create(const AACBrBoleto: TACBrBoleto);
begin
  inherited Create;
  FACBrBoleto := AACBrBoleto;
end;

procedure TEmissorBoletoACBr.Emitir(const ANumeroDocumento: string; const AValor: Currency;
  const AVencimento: TDateTime; const ASacado: TCliente);
var
  Titulo: TACBrTitulo;
begin
  Titulo := FACBrBoleto.CriarTituloNaLista;
  with Titulo do
  begin
    Vencimento := AVencimento;
    DataDocumento := Now;
    NumeroDocumento := ANumeroDocumento;
    NossoNumero := ANumeroDocumento; // deve ser único por cedente
    Carteira := '17'; // depende do convênio com o banco — ver Exemplos/ do ACBr

    ValorDocumento := AValor;

    Sacado.NomeSacado := ASacado.Nome;
    Sacado.CNPJCPF := ASacado.CNPJCPF;
    Sacado.Logradouro := ASacado.Endereco;
    Sacado.Bairro := ASacado.Bairro;
    Sacado.Cidade := ASacado.Cidade;
    Sacado.UF := ASacado.UF;
    Sacado.CEP := ASacado.CEP;
  end;

  // Gera o boleto (impressão/PDF, conforme o driver de saída
  // configurado no FACBrBoleto — ver observação sobre o motor de
  // relatório na explicação desta fase).
  FACBrBoleto.Imprimir;
end;

end.
