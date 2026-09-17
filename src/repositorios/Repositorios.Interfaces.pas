unit Repositorios.Interfaces;

interface

uses
  Modelos.Conta,
  Modelos.Lancamento,
  Modelos.Cliente;

type
  // Repository pattern: cada interface isola o "como" persistir por
  // trás de um contrato orientado ao domínio (BuscarPorId, Salvar,
  // ListarPorConta — nunca "ExecutarSQL" ou "AbrirQuery"). Quem
  // depender destas interfaces (o TServicoTransferencia da Fase 5) não
  // sabe, e não precisa saber, que por trás existe PostgreSQL, FireDAC
  // ou um dicionário em memória usado num teste.
  //
  // Dependency Inversion (D de SOLID): repare que esta unit NÃO importa
  // FireDAC.Comp.Client nem nenhuma outra unit de acesso a dados — ela
  // é pura abstração. É essa ausência de dependência de infraestrutura
  // que permite ao Serviço (camada de alto nível) depender apenas desta
  // interface (abstração), e à implementação FireDAC (camada de baixo
  // nível, na próxima seção) depender da mesma interface — as duas
  // "olham" para o meio, nenhuma depende da outra diretamente.
  //
  // Interface Segregation (I de SOLID): três interfaces pequenas, uma
  // por agregado (Conta, Lancamento, Cliente), em vez de uma única
  // "IRepositorio" genérica com todos os métodos misturados. O futuro
  // emissor de boleto, por exemplo, só vai depender de
  // IRepositorioCliente — não é forçado a "herdar" métodos de Conta ou
  // Lancamento que nunca vai usar.

  IRepositorioConta = interface
    ['{7C1E2A10-1000-4A4A-9B9B-000000000001}']
    function BuscarPorId(const AId: Integer): TConta;
    procedure Salvar(const AConta: TConta);
  end;

  IRepositorioLancamento = interface
    ['{7C1E2A10-1000-4A4A-9B9B-000000000002}']
    // Salvar retorna o TLancamento gravado (e não apenas um
    // "procedure"): como TLancamento é um record com Id somente-leitura
    // (Fase 2), a única forma limpa de devolver ao chamador o
    // id_lancamento que o PostgreSQL gera no INSERT é retornar um novo
    // valor — não há como "escrever de volta" dentro do parâmetro
    // recebido.
    function Salvar(const ALancamento: TLancamento): TLancamento;
    function ListarPorConta(const AIdConta: Integer): TArray<TLancamento>;
  end;

  IRepositorioCliente = interface
    ['{7C1E2A10-1000-4A4A-9B9B-000000000003}']
    function BuscarPorId(const AId: Integer): TCliente;
  end;

  /// <summary>
  ///   Abstrai uma transação: um grupo de escritas que deve ser
  ///   confirmado (Confirmar) ou desfeito (Reverter) como uma única
  ///   unidade atômica.
  /// </summary>
  // Adicionada nesta fase porque a Fase 4 (Serviços) precisa dela: a
  // Parte 5.4 do curso original ensina "operações que precisam ser
  // tudo ou nada ficam dentro da mesma transação" (TFDTransaction), mas
  // TServicoTransferencia.Transferir não pode simplesmente instanciar
  // um TFDTransaction — isso faria a camada de Serviço depender de
  // FireDAC diretamente, quebrando a mesma Inversão de Dependência que
  // levou às interfaces acima. ITransacao resolve isso: o Serviço
  // recebe uma abstração de "começar/confirmar/desfazer", e só a
  // implementação concreta (TTransacaoFireDAC, na próxima seção) sabe
  // que por trás existe um TFDConnection.
  ITransacao = interface
    ['{7C1E2A10-1000-4A4A-9B9B-000000000004}']
    procedure Iniciar;
    procedure Confirmar;
    procedure Reverter;
  end;

implementation

end.
