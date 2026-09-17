unit Modelos.Cliente;

interface

type
  /// <summary>
  ///   Representa os dados de um cliente titular de contas — espelha a
  ///   tabela "cliente" de sql/001_schema.sql. Os campos de endereço
  ///   existem desde já porque serão consumidos pelo TEmissorBoleto
  ///   (Fase de Boleto) como dados do sacado.
  /// </summary>
  // Todas as propriedades são somente-leitura: um TCliente, neste
  // projeto, nunca é editado pelo domínio financeiro — ele é só
  // consultado (para exibir nome, ou para preencher um boleto). Se um
  // dia o projeto ganhar uma tela de cadastro de clientes, o padrão de
  // "reconstruir um novo record com os dados alterados" continua sendo
  // mais seguro do que expor setters soltos.
  TCliente = record
  private
    FId: Integer;
    FNome: string;
    FCNPJCPF: string;
    FEndereco: string;
    FBairro: string;
    FCidade: string;
    FUF: string;
    FCEP: string;
  public
    constructor Create(const AId: Integer; const ANome, ACNPJCPF, AEndereco,
      ABairro, ACidade, AUF, ACEP: string);

    property Id: Integer read FId;
    property Nome: string read FNome;
    property CNPJCPF: string read FCNPJCPF;
    property Endereco: string read FEndereco;
    property Bairro: string read FBairro;
    property Cidade: string read FCidade;
    property UF: string read FUF;
    property CEP: string read FCEP;
  end;

implementation

constructor TCliente.Create(const AId: Integer; const ANome, ACNPJCPF, AEndereco,
  ABairro, ACidade, AUF, ACEP: string);
begin
  FId := AId;
  FNome := ANome;
  FCNPJCPF := ACNPJCPF;
  FEndereco := AEndereco;
  FBairro := ABairro;
  FCidade := ACidade;
  FUF := AUF;
  FCEP := ACEP;
end;

end.
