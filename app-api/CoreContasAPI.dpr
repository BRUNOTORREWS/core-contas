program CoreContasAPI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  FireDAC.Comp.Client,
  Horse,
  Horse.Jhonson,
  Modelos.Conta in '..\src\modelos\Modelos.Conta.pas',
  Modelos.Cliente in '..\src\modelos\Modelos.Cliente.pas',
  Modelos.Lancamento in '..\src\modelos\Modelos.Lancamento.pas',
  Dominio.Excecoes in '..\src\dominio\Dominio.Excecoes.pas',
  Repositorios.Interfaces in '..\src\repositorios\Repositorios.Interfaces.pas',
  Repositorios.Conexao in '..\src\repositorios\Repositorios.Conexao.pas',
  Repositorios.FireDAC in '..\src\repositorios\Repositorios.FireDAC.pas',
  Repositorios.Factory in '..\src\repositorios\Repositorios.Factory.pas',
  Servicos.Conta in '..\src\servicos\Servicos.Conta.pas',
  Servicos.Transferencia in '..\src\servicos\Servicos.Transferencia.pas';

var
  Conexao: TFDConnection;
  RepoContas: IRepositorioConta;
  RepoLancamentos: IRepositorioLancamento;
  Transacao: ITransacao;
  ServicoConta: TServicoConta;
  ServicoTransferencia: TServicoTransferencia;

begin
  // ---------------------------------------------------------------
  // Ponto de composição da aplicação (Parte 6.4 do curso original):
  // é AQUI, e só aqui, que se decide qual implementação concreta de
  // cada interface vai ser usada. Troque estas poucas linhas por
  // fakes e o resto do programa (rotas, serviços) continua
  // compilando e se comportando de forma idêntica — é a mesma
  // propriedade que já provamos na Fase 5, agora explícita no ponto
  // de entrada real da aplicação.
  // ---------------------------------------------------------------
  Conexao := TConexaoPostgreSQL.Obter; // Singleton (Fase 3)

  RepoContas := TFabricaRepositorios.CriarRepositorioConta(Conexao);
  RepoLancamentos := TFabricaRepositorios.CriarRepositorioLancamento(Conexao);
  Transacao := TFabricaRepositorios.CriarTransacao(Conexao);

  ServicoConta := TServicoConta.Create(RepoContas, RepoLancamentos);
  ServicoTransferencia := TServicoTransferencia.Create(RepoContas, RepoLancamentos, Transacao);

  // -----------------------------------------------------------------
  // Middlewares — a ORDEM de registro importa: cada THorse.Use "envolve"
  // tudo que vem depois dele. Registrando o tratamento de erros PRIMEIRO,
  // seu Next() acaba envolvendo o Jhonson, o log, e todas as rotas — uma
  // exceção lançada em QUALQUER lugar dali pra frente (inclusive um JSON
  // malformado sendo interpretado pelo Jhonson) é capturada aqui.
  // -----------------------------------------------------------------

  // Middleware central de tratamento de erros: nenhuma rota abaixo tem
  // try/except próprio. Toda exceção de domínio lançada por
  // TServicoConta/TServicoTransferencia atravessa a rota e é
  // capturada em um único lugar, que traduz cada tipo de exceção para
  // o status HTTP correto — evita repetir "on EContaNaoEncontrada do
  // ... on ESaldoInsuficiente do ..." em cada rota (o curso original
  // repetia esse bloco em toda rota que podia falhar) e garante que
  // nenhuma rota nova, escrita no futuro, "esqueça" de tratar um erro
  // de domínio.
  THorse.Use(
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      try
        Next();
      except
        on E: EContaNaoEncontrada do
          Res.Send('{"erro": "' + E.Message + '"}').Status(404);
        on E: EClienteNaoEncontrado do
          Res.Send('{"erro": "' + E.Message + '"}').Status(404);
        on E: ESaldoInsuficiente do
          Res.Send('{"erro": "' + E.Message + '"}').Status(400);
        on E: EValorInvalido do
          Res.Send('{"erro": "' + E.Message + '"}').Status(400);
        on E: Exception do
        begin
          // Erro inesperado (bug, falha de conexão com o banco etc.):
          // NUNCA devolva E.Message/stack trace pro cliente — isso
          // vaza detalhe interno da implementação. Registre no log do
          // servidor e devolva uma mensagem genérica com 500.
          WriteLn(Format('[ERRO NAO TRATADO] %s: %s', [E.ClassName, E.Message]));
          Res.Send('{"erro": "erro interno no servidor"}').Status(500);
        end;
      end;
    end);

  THorse.Use(Jhonson); // facilita ler/escrever o corpo das requisições em JSON

  THorse.Use( // middleware de log, igual à Parte 8.3.3 do curso original
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      WriteLn(Format('[%s] %s %s',
        [DateTimeToStr(Now), Req.MethodToString, Req.RawWebRequest.PathInfo]));
      Next();
    end);

  // -----------------------------------------------------------------
  // Rotas — cada uma só traduz HTTP/JSON para uma chamada ao Serviço
  // já testado na Fase 5. Nenhuma rota abaixo decide se um saldo é
  // suficiente, nem grava nada diretamente: ISSO seria reimplementar
  // regra de negócio dentro da rota, o erro mais comum em APIs REST
  // mal desenhadas (Parte 8.3.2 do curso original).
  // -----------------------------------------------------------------

  THorse.Get('/contas/:id/saldo',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      IdConta: Integer;
      Conta: TConta;
      Json: TJSONObject;
    begin
      if not TryStrToInt(Req.Params['id'], IdConta) then
      begin
        Res.Send('{"erro": "id de conta invalido"}').Status(400);
        Exit;
      end;

      // Verbo GET, sem efeito colateral: só consulta. Status 200 é o
      // padrão de sucesso para leitura — não precisa ser setado
      // manualmente quando não há erro (Horse assume 200), mas
      // deixamos explícito por clareza didática.
      Conta := ServicoConta.BuscarPorId(IdConta);

      Json := TJSONObject.Create;
      Json.AddPair('id', TJSONNumber.Create(Conta.Id));
      Json.AddPair('saldo', TJSONNumber.Create(Conta.Saldo));
      Res.Send<TJSONObject>(Json).Status(200);
    end);

  THorse.Get('/contas/:id/extrato',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      IdConta: Integer;
      Lancamentos: TArray<TLancamento>;
      Json: TJSONArray;
      Item: TLancamento;
      ItemJson: TJSONObject;
    begin
      if not TryStrToInt(Req.Params['id'], IdConta) then
      begin
        Res.Send('{"erro": "id de conta invalido"}').Status(400);
        Exit;
      end;

      Lancamentos := ServicoConta.Extrato(IdConta);

      Json := TJSONArray.Create;
      for Item in Lancamentos do
      begin
        ItemJson := TJSONObject.Create;
        ItemJson.AddPair('id', TJSONNumber.Create(Item.Id));
        ItemJson.AddPair('valor', TJSONNumber.Create(Item.Valor));
        ItemJson.AddPair('descricao', Item.Descricao);
        // ISO 8601 para datas em JSON: formato não-ambíguo,
        // independente de locale — evite DateTimeToStr aqui, que
        // formataria a data conforme a configuração regional do
        // servidor (ex.: dd/mm/yyyy no Brasil), quebrando qualquer
        // cliente que espere um formato previsível.
        ItemJson.AddPair('data', DateToISO8601(Item.Data));
        Json.AddElement(ItemJson);
      end;

      Res.Send<TJSONArray>(Json).Status(200);
    end);

  THorse.Post('/lancamentos',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Corpo: TJSONObject;
    begin
      Corpo := Req.Body<TJSONObject>;

      // Verbo POST porque a chamada CRIA dois recursos (dois
      // lançamentos) e tem efeito colateral (move saldo) — nunca GET
      // para isso, mesmo que fosse "mais fácil de testar num
      // navegador". Toda a regra de negócio (validação de valor,
      // checagem de saldo, atomicidade) já aconteceu dentro de
      // TServicoTransferencia.Transferir; se algo for inválido, a
      // exceção sobe e o middleware de erros, registrado acima,
      // decide o status HTTP.
      ServicoTransferencia.Transferir(
        Corpo.GetValue<Integer>('contaOrigem'),
        Corpo.GetValue<Integer>('contaDestino'),
        Corpo.GetValue<Currency>('valor'));

      // 201 Created: a operação criou lançamentos novos — diferente de
      // 200 OK, que aqui seria menos preciso (200 sugere "apenas leu
      // ou confirmou algo que já existia").
      Res.Send('{"status": "ok"}').Status(201);
    end);

  THorse.Listen(9000);
  WriteLn('CoreContas API rodando em http://localhost:9000');
  ReadLn;

  TConexaoPostgreSQL.Encerrar;
end.
