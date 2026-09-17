unit Repositorios.Factory;

interface

uses
  FireDAC.Comp.Client,
  Repositorios.Interfaces;

type
  /// <summary>
  ///   Centraliza a criação das implementações concretas dos
  ///   repositórios do CoreContas.
  /// </summary>
  // Factory pattern (citado na Parte 6.3 do curso original): sem esta
  // classe, cada lugar que precisasse de um IRepositorioConta (a API na
  // Fase 7, o desktop na Fase 9, testes de integração futuros) teria
  // que conhecer o nome concreto "TRepositorioContaFireDAC" e a forma
  // exata de construí-lo. Com a fábrica, só ELA conhece esse nome; se
  // amanhã a implementação mudar (por exemplo, para adicionar logging
  // de cada query, ou trocar para outra biblioteca de acesso a dados),
  // muda-se um único lugar, e cada método aqui já devolve a
  // INTERFACE (IRepositorioConta), não a classe concreta — reforçando,
  // na assinatura, a Inversão de Dependência que já vale para
  // Repositorios.Interfaces.
  TFabricaRepositorios = class
  public
    class function CriarRepositorioConta(
      const AConexao: TFDConnection): IRepositorioConta; static;
    class function CriarRepositorioLancamento(
      const AConexao: TFDConnection): IRepositorioLancamento; static;
    class function CriarRepositorioCliente(
      const AConexao: TFDConnection): IRepositorioCliente; static;
    class function CriarTransacao(
      const AConexao: TFDConnection): ITransacao; static;
  end;

implementation

uses
  Repositorios.FireDAC;

class function TFabricaRepositorios.CriarRepositorioConta(
  const AConexao: TFDConnection): IRepositorioConta;
begin
  Result := TRepositorioContaFireDAC.Create(AConexao);
end;

class function TFabricaRepositorios.CriarRepositorioLancamento(
  const AConexao: TFDConnection): IRepositorioLancamento;
begin
  Result := TRepositorioLancamentoFireDAC.Create(AConexao);
end;

class function TFabricaRepositorios.CriarRepositorioCliente(
  const AConexao: TFDConnection): IRepositorioCliente;
begin
  Result := TRepositorioClienteFireDAC.Create(AConexao);
end;

class function TFabricaRepositorios.CriarTransacao(
  const AConexao: TFDConnection): ITransacao;
begin
  Result := TTransacaoFireDAC.Create(AConexao);
end;

end.
