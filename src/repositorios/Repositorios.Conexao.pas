unit Repositorios.Conexao;

interface

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  // As units abaixo não são usadas diretamente em nenhuma linha deste
  // arquivo — mas cada uma delas registra, na sua cláusula
  // "initialization" (um recurso de Object Pascal que roda código
  // automaticamente quando a unit é carregada), uma peça que o FireDAC
  // precisa em tempo de EXECUÇÃO para montar a conexão com o
  // PostgreSQL: definições padrão (Stan.Def), pool de conexões
  // (Stan.Pool), suporte assíncrono (Stan.Async), a camada física
  // genérica (Phys) e o driver específico do PostgreSQL (Phys.PG e
  // Phys.PGDef). Quando você arrasta um TFDConnection visualmente no
  // Designer e configura o DriverID pelo Object Inspector, a IDE
  // adiciona essas units automaticamente — como criamos a conexão só
  // por código (Injeção de Dependência, sem componente visual), tivemos
  // que declarar isso à mão.
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef;

type
  /// <summary>
  ///   Fornece a única instância de TFDConnection usada pela aplicação
  ///   para falar com o PostgreSQL do CoreContas.
  /// </summary>
  // Singleton (padrão citado na Parte 6.3 do curso original): garante
  // que a aplicação inteira — API, desktop, ou os dois processos
  // rodando ao mesmo tempo em máquinas diferentes — compartilhe uma
  // única TFDConnection (e, mais adiante, um único pool gerenciado pelo
  // FireDAC), em vez de cada tela ou cada rota abrir sua própria
  // conexão física.
  //
  // Use com moderação (o próprio material original já alerta): um
  // Singleton é acoplamento global por definição. É exatamente por isso
  // que TRepositorioContaFireDAC e os demais NÃO chamam
  // TConexaoPostgreSQL.Obter diretamente — eles recebem a conexão pronta
  // via construtor (Injeção de Dependência). Só o "ponto de composição"
  // da aplicação (a Fase de API/Desktop, mais adiante) vai chamar
  // TConexaoPostgreSQL.Obter. Isso mantém o Singleton confinado a um
  // único lugar do projeto e não contamina os testes com DUnitX (Fase
  // 6), que vão usar repositórios fake e nunca vão precisar desta
  // classe.
  TConexaoPostgreSQL = class
  private
    class var FInstancia: TFDConnection;
  public
    class function Obter: TFDConnection; static;
    class procedure Encerrar; static;
  end;

implementation

// Lê a configuração de uma variável de ambiente, com um valor padrão
// de fallback para desenvolvimento local. Isso existe para que
// credenciais (usuário/senha do PostgreSQL) NUNCA fiquem craveadas no
// código-fonte — importante especialmente porque este repositório é
// público: qualquer pessoa que o clonar usa seu próprio Postgres local
// (o fallback "postgres/postgres" cobre esse caso, já que é a
// instalação padrão), mas em qualquer ambiente real (CI, homologação,
// produção) as variáveis de ambiente CORECONTAS_DB_USER e
// CORECONTAS_DB_PASSWORD sobrescrevem o fallback sem precisar de
// nenhuma alteração de código.
function ObterConfig(const ANomeVariavel, AValorPadrao: string): string;
begin
  Result := GetEnvironmentVariable(ANomeVariavel);
  if Result = '' then
    Result := AValorPadrao;
end;

class function TConexaoPostgreSQL.Obter: TFDConnection;
begin
  if FInstancia = nil then
  begin
    FInstancia := TFDConnection.Create(nil);
    FInstancia.Params.Clear;
    FInstancia.Params.Add('DriverID=PG');
    FInstancia.Params.Add('Server=' + ObterConfig('CORECONTAS_DB_HOST', 'localhost'));
    FInstancia.Params.Add('Port=' + ObterConfig('CORECONTAS_DB_PORT', '5432'));
    FInstancia.Params.Add('Database=' + ObterConfig('CORECONTAS_DB_NAME', 'corecontas_dev'));
    FInstancia.Params.Add('User_Name=' + ObterConfig('CORECONTAS_DB_USER', 'postgres'));
    FInstancia.Params.Add('Password=' + ObterConfig('CORECONTAS_DB_PASSWORD', 'postgres'));
    // MetaDefSchema fixa o schema padrão de metadados como "public".
    // Diferente do Firebird (que não tem o conceito de "schema" dentro
    // de um banco — só tem "o banco"), o PostgreSQL sempre resolve
    // nomes de tabela dentro de um schema; "public" é o schema-padrão
    // quando uma tabela é referenciada sem qualificação (ex.: "conta"
    // em vez de "meuschema.conta"). Como o script da Fase 1 criou tudo
    // em "public" (o padrão do createdb), isso não muda nada na prática
    // — mas é bom deixar explícito em vez de depender do default
    // implícito.
    FInstancia.Params.Add('MetaDefSchema=public');
    FInstancia.LoginPrompt := False;
  end;

  if not FInstancia.Connected then
    FInstancia.Connected := True;

  Result := FInstancia;
end;

class procedure TConexaoPostgreSQL.Encerrar;
begin
  FreeAndNil(FInstancia);
end;

end.
