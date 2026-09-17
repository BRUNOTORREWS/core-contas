unit Modelos.Conta;

interface

type
  /// <summary>
  ///   Representa os dados de uma conta financeira (id_conta, id_cliente,
  ///   saldo) — um espelho, em Object Pascal, da tabela "conta" definida em
  ///   sql/001_schema.sql.
  /// </summary>
  // Single Responsibility (S de SOLID): TConta tem um único motivo para
  // mudar — a FORMA dos dados de uma conta. Ela não sabe ler/gravar no
  // PostgreSQL (isso é responsabilidade do Repositório, próxima fase) e
  // não decide se uma transferência é válida (isso é responsabilidade do
  // Serviço, depois). É só um carregador de dados.
  //
  // "record" em vez de "class": diferente do curso original (que usava
  // TConta = class), este é um tipo por VALOR. Ele é copiado na
  // atribuição e nunca precisa de .Free. Isso elimina, por construção, o
  // vazamento de memória que existia no material original — lá,
  // TServicoTransferencia.Transferir buscava Origem/Destino via
  // BuscarPorId (que retornava instâncias de classe) e nunca as
  // liberava. Records também são a opção mais segura em cenários
  // multithread (Parte 1 do curso): como não há referência
  // compartilhada, duas threads não podem pisar na mesma instância.
  TConta = record
  private
    FId: Integer;
    FIdCliente: Integer;
    FSaldo: Currency;
  public
    constructor Create(const AId, AIdCliente: Integer; const ASaldo: Currency);

    property Id: Integer read FId;
    property IdCliente: Integer read FIdCliente;

    // Saldo tem "write" porque o TServicoTransferencia (Fase de Serviços)
    // precisa debitar/creditar o valor em memória antes de devolver a
    // conta ao repositório para persistência. Como TConta é um record,
    // essa alteração fica isolada na cópia local da variável do
    // chamador — não existe o risco de duas partes do código
    // enxergarem, sem querer, o mesmo objeto mutável.
    property Saldo: Currency read FSaldo write FSaldo;
  end;

implementation

constructor TConta.Create(const AId, AIdCliente: Integer; const ASaldo: Currency);
begin
  FId := AId;
  FIdCliente := AIdCliente;
  FSaldo := ASaldo;
end;

end.
