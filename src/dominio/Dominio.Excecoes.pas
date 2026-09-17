unit Dominio.Excecoes;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Exceções de domínio do CoreContas. Nunca use "except on Exception
  ///   do" para tratar erros de negócio — capture sempre um destes tipos
  ///   específicos, para que quem chama saiba exatamente o que deu
  ///   errado (e a API, mais adiante, possa mapear cada uma para o
  ///   status HTTP correto).
  /// </summary>
  //
  // Por que esta unit não se chama "Servicos.Excecoes" (como no curso
  // original): o Repositório (Fase 3, esta fase) já precisa lançar
  // EContaNaoEncontrada e EClienteNaoEncontrado, e o Repositório é uma
  // camada ABAIXO do Serviço na arquitetura (UI -> Serviço -> Repositório
  // -> Infraestrutura). Se essas exceções vivessem em "Servicos.Excecoes",
  // o Repositório teria que importar uma unit da camada de Serviço para
  // lançar seu próprio erro — uma dependência de baixo para cima, que
  // quebra a regra de dependência da arquitetura em camadas. Colocando
  // as exceções em uma unit de domínio própria, sem depender de
  // Repositorios.* nem de Servicos.*, tanto o Repositório quanto o
  // Serviço podem depender dela sem que nenhuma das duas camadas
  // dependa da outra.
  EContaNaoEncontrada = class(Exception);
  EClienteNaoEncontrado = class(Exception);
  ESaldoInsuficiente = class(Exception);
  EValorInvalido = class(Exception);

implementation

end.
