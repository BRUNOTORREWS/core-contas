unit Boleto.Interfaces;

interface

uses
  Modelos.Cliente;

type
  /// <summary>
  ///   Abstrai a emissão de um boleto — quem implementa esta interface
  ///   sabe "como" gerar o boleto de verdade (ACBrBoleto, ou qualquer
  ///   outro provedor no futuro); quem a consome (TServicoCobranca, mais
  ///   abaixo) não sabe, e não precisa saber.
  /// </summary>
  // Mesmo raciocínio de Repository/Dependency Inversion já aplicado a
  // IRepositorioConta (Fase 3): ACBrBoleto é uma biblioteca de
  // terceiros, sujeita a mudar de versão, de fornecedor de layout, ou
  // até ser substituída por uma API de banco direta um dia. Nenhuma
  // dessas mudanças deveria obrigar TServicoCobranca a mudar — só a
  // implementação concreta (Boleto.ACBr, próxima unit) muda.
  IEmissorBoleto = interface
    ['{9D3F4B20-2000-4A4A-8C8C-000000000001}']
    procedure Emitir(const ANumeroDocumento: string; const AValor: Currency;
      const AVencimento: TDateTime; const ASacado: TCliente);
  end;

implementation

end.
