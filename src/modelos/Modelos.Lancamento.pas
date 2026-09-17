unit Modelos.Lancamento;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Representa um lançamento de crédito (Valor > 0) ou débito
  ///   (Valor &lt; 0) em uma conta — espelha a tabela "lancamento" de
  ///   sql/001_schema.sql.
  /// </summary>
  TLancamento = record
  private
    FId: Integer;
    FIdConta: Integer;
    FValor: Currency;
    FDescricao: string;
    FData: TDateTime;
  public
    // Dois construtores para dois momentos de vida distintos do
    // lançamento — o curso original usava um único construtor para os
    // dois casos e, por isso, nunca preenchia o Id ao reconstruir um
    // TLancamento a partir de uma linha do banco (repare que, na Parte 9
    // do material original, ListarPorConta nem sequer fazia SELECT da
    // coluna ID_LANCAMENTO). Aqui corrigimos isso separando as duas
    // situações:

    /// <summary>
    ///   Cria um lançamento NOVO, ainda não persistido — usado pelo
    ///   TServicoTransferencia ao gerar os dois lados de uma
    ///   transferência. O Id é preenchido depois pelo repositório
    ///   (Fase de Repositórios), a partir do id_lancamento que o
    ///   PostgreSQL gera via GENERATED ALWAYS AS IDENTITY; a data fica
    ///   por conta do próprio banco (default now() na coluna
    ///   data_lancamento).
    /// </summary>
    constructor Create(const AIdConta: Integer; const AValor: Currency;
      const ADescricao: string); overload;

    /// <summary>
    ///   Reconstrói um lançamento EXISTENTE a partir de uma linha já lida
    ///   do banco (usado pelo repositório ao montar o extrato de uma
    ///   conta) — todos os campos, incluindo Id e Data, já são
    ///   conhecidos.
    /// </summary>
    constructor Create(const AId, AIdConta: Integer; const AValor: Currency;
      const ADescricao: string; const AData: TDateTime); overload;

    property Id: Integer read FId;
    property IdConta: Integer read FIdConta;
    property Valor: Currency read FValor;
    property Descricao: string read FDescricao;
    property Data: TDateTime read FData;
  end;

implementation

constructor TLancamento.Create(const AIdConta: Integer; const AValor: Currency;
  const ADescricao: string);
begin
  FIdConta := AIdConta;
  FValor := AValor;
  FDescricao := ADescricao;
  FData := Now;
end;

constructor TLancamento.Create(const AId, AIdConta: Integer; const AValor: Currency;
  const ADescricao: string; const AData: TDateTime);
begin
  FId := AId;
  FIdConta := AIdConta;
  FValor := AValor;
  FDescricao := ADescricao;
  FData := AData;
end;

end.
