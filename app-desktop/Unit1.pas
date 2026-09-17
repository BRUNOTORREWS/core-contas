unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  FireDAC.Comp.Client,
  FireDAC.VCLUI.Wait, // registra o "cursor de espera" do FireDAC em apps VCL
  Repositorios.Interfaces, Repositorios.Conexao, Repositorios.Factory,
  Servicos.Conta, Servicos.Transferencia,
  Modelos.Conta, Modelos.Lancamento,
  Dominio.Excecoes;

type
  TForm1 = class(TForm)
    PnlConsulta: TPanel;
    LblTituloConsulta: TLabel;
    LblContaId: TLabel;
    EdtContaId: TEdit;
    BtnConsultar: TButton;
    LblSaldoTitulo: TLabel;
    LblSaldo: TLabel;
    PnlExtrato: TPanel;
    LblTituloExtrato: TLabel;
    ListViewExtrato: TListView;
    LblExtratoVazio: TLabel;
    PnlTransferencia: TPanel;
    LblTituloTransferencia: TLabel;
    LblContaOrigem: TLabel;
    EdtContaOrigem: TEdit;
    LblContaDestino: TLabel;
    EdtContaDestino: TEdit;
    LblValor: TLabel;
    EdtValor: TEdit;
    BtnTransferir: TPanel;
    LblAjudaTransferencia: TLabel;
    BtnSair: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnConsultarClick(Sender: TObject);
    procedure BtnTransferirClick(Sender: TObject);
    procedure BtnSairClick(Sender: TObject);
    procedure ListViewExtratoDrawItem(Sender: TCustomListView; Item: TListItem;
      Rect: TRect; State: TOwnerDrawState);
  private
    // As mesmas três interfaces de sempre (Fases 3 e 4) — a novidade
    // aqui é só o TIPO de "UI" que as consome. TServicoConta e
    // TServicoTransferencia não fazem ideia se quem os chama é uma rota
    // Horse, o OnClick de um TButton "cru" ou esta versão redesenhada.
    FConexao: TFDConnection;
    FRepoContas: IRepositorioConta;
    FRepoLancamentos: IRepositorioLancamento;
    FTransacao: ITransacao;
    FServicoConta: TServicoConta;
    FServicoTransferencia: TServicoTransferencia;

    // Duas responsabilidades separadas dentro do próprio FormCreate (S
    // de SOLID, em miniatura, dentro de uma única classe de tela):
    // MontarDependencias cuida de infraestrutura/DI; AplicarEstiloVisual
    // cuida só de aparência. Nenhuma das duas sabe da outra — dá pra
    // mudar a paleta de cores inteira sem tocar em uma linha de conexão
    // com o banco, e vice-versa.
    procedure MontarDependencias;
    procedure AplicarEstiloVisual;
    procedure PreencherExtrato(const ALancamentos: TArray<TLancamento>);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// Paleta da tela — centralizada aqui em vez de espalhada em cada
// Handler, para que trocar uma cor (ex.: o tom do acento) seja uma
// mudança em um único lugar. RGB() não pode ser usado dentro de uma
// declaração "const" em Object Pascal (não é uma expressão constante
// em tempo de compilação), então essas são funções, chamadas a partir
// de AplicarEstiloVisual e dos handlers que precisam delas.

function CorFundoJanela: TColor;
begin
  Result := RGB(245, 246, 248);
end;

function CorTextoPrincipal: TColor;
begin
  Result := RGB(33, 37, 41); // cinza-escuro, nunca preto puro
end;

function CorTextoMuted: TColor;
begin
  Result := RGB(120, 126, 135);
end;

function CorAcento: TColor;
begin
  Result := RGB(79, 70, 229); // única cor de destaque para acoes primarias
end;

function CorSucesso: TColor;
begin
  Result := RGB(22, 163, 74); // verde — saldo positivo / credito
end;

function CorErro: TColor;
begin
  Result := RGB(220, 38, 38); // vermelho — reservado para debito/erro
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  MontarDependencias;
  AplicarEstiloVisual;
end;

procedure TForm1.MontarDependencias;
begin
  // Ponto de composição da aplicação (Parte 6.4 do curso original) —
  // idêntico ao que já existia antes do redesenho. O redesenho visual
  // desta fase não muda absolutamente nada aqui: é a prova de que
  // aparência e regra de negócio são, de fato, preocupações
  // independentes nesta arquitetura.
  FConexao := TConexaoPostgreSQL.Obter;

  FRepoContas := TFabricaRepositorios.CriarRepositorioConta(FConexao);
  FRepoLancamentos := TFabricaRepositorios.CriarRepositorioLancamento(FConexao);
  FTransacao := TFabricaRepositorios.CriarTransacao(FConexao);

  FServicoConta := TServicoConta.Create(FRepoContas, FRepoLancamentos);
  FServicoTransferencia := TServicoTransferencia.Create(FRepoContas, FRepoLancamentos, FTransacao);
end;

procedure TForm1.AplicarEstiloVisual;
begin
  // Fundo neutro claro da janela e dos "cartões" — item 6 do pedido.
  Self.Color := CorFundoJanela;
  PnlConsulta.Color := clWhite;
  PnlExtrato.Color := clWhite;
  PnlTransferencia.Color := clWhite;

  // Títulos de secao e texto secundario nunca em preto puro (item 6).
  LblTituloConsulta.Font.Color := CorTextoPrincipal;
  LblTituloExtrato.Font.Color := CorTextoPrincipal;
  LblTituloTransferencia.Font.Color := CorTextoPrincipal;

  LblContaId.Font.Color := CorTextoMuted;
  LblSaldoTitulo.Font.Color := CorTextoMuted;
  LblContaOrigem.Font.Color := CorTextoMuted;
  LblContaDestino.Font.Color := CorTextoMuted;
  LblValor.Font.Color := CorTextoMuted;
  LblAjudaTransferencia.Font.Color := CorTextoMuted;
  LblExtratoVazio.Font.Color := CorTextoMuted;

  // Botao principal (Transferir) com cor de destaque solida; botao
  // secundario (Consultar) fica no visual padrao do Windows/VCL Style
  // ativo — hierarquia clara sem precisar de nenhum componente externo
  // (item 5). Usamos um TPanel "fazendo de botao" (Color + Font + um
  // OnClick) em vez de TButton ou TSpeedButton: TButton e desenhado
  // pelo Windows/tema ativo (Color nao tem efeito visual confiavel), e
  // TSpeedButton herda Color como PROTECTED (nao da pra acessar de
  // fora da classe) — TPanel.Color e publicado normalmente e sempre
  // pintado com a cor que voce definir.
  BtnTransferir.Color := CorAcento;
  BtnTransferir.Font.Color := clWhite;
  BtnTransferir.Font.Style := [fsBold];
  BtnTransferir.ParentBackground := False;
  BtnTransferir.Cursor := crHandPoint;

  // Saldo sem valor consultado ainda: neutro, nao verde nem vermelho.
  LblSaldo.Font.Color := CorTextoMuted;

  ListViewExtrato.OwnerDraw := True;
  ListViewExtrato.ReadOnly := True;
  ListViewExtrato.RowSelect := True;
  ListViewExtrato.GridLines := False;

  LblExtratoVazio.Visible := True;
  ListViewExtrato.Visible := False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FServicoConta.Free;
  FServicoTransferencia.Free;
  // FRepoContas, FRepoLancamentos e FTransacao são interfaces
  // (TInterfacedObject, Fase 3) — a última referência a cada uma delas
  // (dentro dos dois objetos liberados acima) já foi liberada; a
  // contagem de referências cuida do resto (Fase 2). A conexão em si é
  // o Singleton TConexaoPostgreSQL (Fase 3) — não a encerramos aqui,
  // porque em uma aplicação com mais de uma tela, outra tela poderia
  // ainda precisar dela; quem encerra é o ponto de saída do programa.
end;

procedure TForm1.BtnConsultarClick(Sender: TObject);
var
  IdConta: Integer;
  Conta: TConta;
  Lancamentos: TArray<TLancamento>;
begin
  if not TryStrToInt(EdtContaId.Text, IdConta) then
  begin
    ShowMessage('Informe um ID de conta valido.');
    Exit;
  end;

  try
    // Nenhuma regra de negócio aqui — só chama o Serviço e traduz o
    // resultado para os componentes visuais. É a mesma "rota fina" da
    // API, agora em forma de OnClick.
    Conta := FServicoConta.BuscarPorId(IdConta);

    LblSaldo.Caption := Format('R$ %.2n', [Conta.Saldo]);
    if Conta.Saldo >= 0 then
      LblSaldo.Font.Color := CorSucesso
    else
      LblSaldo.Font.Color := CorErro;

    Lancamentos := FServicoConta.Extrato(IdConta);
    PreencherExtrato(Lancamentos);
  except
    // Exceção de domínio, tratada especificamente — nunca "except on
    // Exception do" genérico.
    on E: EContaNaoEncontrada do
      ShowMessage(E.Message);
  end;
end;

procedure TForm1.PreencherExtrato(const ALancamentos: TArray<TLancamento>);
var
  I: Integer;
  Item: TListItem;
  Sinal: string;
begin
  ListViewExtrato.Items.BeginUpdate;
  try
    ListViewExtrato.Items.Clear;
    for I := 0 to High(ALancamentos) do
    begin
      Item := ListViewExtrato.Items.Add;
      Item.Caption := DateTimeToStr(ALancamentos[I].Data);
      Item.SubItems.Add(ALancamentos[I].Descricao);

      if ALancamentos[I].Valor >= 0 then
      begin
        Item.SubItems.Add('Credito');
        Sinal := '+ ';
      end
      else
      begin
        Item.SubItems.Add('Debito');
        Sinal := '- ';
      end;

      Item.SubItems.Add(Format('%sR$ %.2n', [Sinal, Abs(ALancamentos[I].Valor)]));
    end;
  finally
    ListViewExtrato.Items.EndUpdate;
  end;

  // Estado vazio explicito (item 3 do pedido): em vez de um grid em
  // branco sem explicacao, o usuario ve um texto dizendo o que
  // significa "nenhuma linha".
  LblExtratoVazio.Visible := ListViewExtrato.Items.Count = 0;
  ListViewExtrato.Visible := ListViewExtrato.Items.Count > 0;
end;

procedure TForm1.ListViewExtratoDrawItem(Sender: TCustomListView; Item: TListItem;
  Rect: TRect; State: TOwnerDrawState);
var
  LV: TListView;
  ColRect: TRect;
  XOffset, ColWidth, I: Integer;
  Texto: string;
  Credito: Boolean;
  CorTexto, CorFundoBadge, CorTextoBadge: TColor;
  LarguraBadge: Integer;
begin
  // A assinatura deste evento é fixa na VCL e recebe "Sender:
  // TCustomListView" — mas TCustomListView declara Canvas e Columns
  // como PROTECTED; só a classe pública TListView (que é o que
  // ListViewExtrato realmente É em tempo de execução) reexpõe esses
  // membros. Por isso o cast abaixo: sem ele, o compilador recusa o
  // acesso mesmo sabendo que, na prática, Sender sempre vai ser o
  // ListViewExtrato do formulário.
  LV := TListView(Sender);

  // TListView em modo OwnerDraw chama este evento uma vez por LINHA,
  // com "Rect" cobrindo a linha inteira (todas as colunas juntas) — não
  // existe um evento nativo "por celula" no TListView clássico da VCL.
  // Por isso fatiamos "Rect" manualmente pelas larguras de
  // LV.Columns[I].Width, técnica padrão para desenho customizado de
  // relatório em VCL.
  //
  // Atenção: o parâmetro deste evento já se CHAMA "Rect" (assinatura
  // fixa da VCL) — isso esconde a função global Rect(...) dentro deste
  // método. Por isso ColRect é montado atribuindo campo por campo, e
  // não chamando Rect(...).

  // Zebra: linhas de índice ímpar levemente acinzentadas, pares
  // brancas — item 3 do pedido ("linhas zebradas").
  if Odd(Item.Index) then
    LV.Canvas.Brush.Color := RGB(250, 250, 251)
  else
    LV.Canvas.Brush.Color := clWhite;
  LV.Canvas.FillRect(Rect);

  Credito := (Item.SubItems[1] = 'Credito');

  XOffset := Rect.Left;
  for I := 0 to LV.Columns.Count - 1 do
  begin
    ColWidth := LV.Columns[I].Width;

    ColRect.Left := XOffset;
    ColRect.Top := Rect.Top;
    ColRect.Right := XOffset + ColWidth;
    ColRect.Bottom := Rect.Bottom;

    if I = 0 then
      Texto := Item.Caption
    else
      Texto := Item.SubItems[I - 1];

    case I of
      2: // coluna "TIPO": desenhada como badge colorida, nao como texto simples
        begin
          if Credito then
          begin
            CorFundoBadge := RGB(220, 252, 231);
            CorTextoBadge := CorSucesso;
          end
          else
          begin
            CorFundoBadge := RGB(254, 226, 226);
            CorTextoBadge := CorErro;
          end;

          LarguraBadge := LV.Canvas.TextWidth(Texto) + 24;

          LV.Canvas.Brush.Color := CorFundoBadge;
          LV.Canvas.Pen.Color := CorFundoBadge;
          LV.Canvas.RoundRect(ColRect.Left + 8, ColRect.Top + 6,
            ColRect.Left + 8 + LarguraBadge, ColRect.Bottom - 6, 12, 12);

          LV.Canvas.Brush.Style := bsClear;
          LV.Canvas.Font.Color := CorTextoBadge;
          LV.Canvas.TextOut(ColRect.Left + 20,
            ColRect.Top + (ColRect.Height - LV.Canvas.TextHeight(Texto)) div 2, Texto);
          LV.Canvas.Brush.Style := bsSolid;
        end;
      3: // coluna "VALOR": alinhada a direita, colorida conforme credito/debito
        begin
          if Credito then
            CorTexto := CorSucesso
          else
            CorTexto := CorErro;

          LV.Canvas.Brush.Style := bsClear;
          LV.Canvas.Font.Color := CorTexto;
          LV.Canvas.Font.Style := [fsBold];
          LV.Canvas.TextOut(ColRect.Right - LV.Canvas.TextWidth(Texto) - 16,
            ColRect.Top + (ColRect.Height - LV.Canvas.TextHeight(Texto)) div 2, Texto);
          LV.Canvas.Font.Style := [];
          LV.Canvas.Brush.Style := bsSolid;
        end;
    else // colunas "DATA" e "DESCRICAO": texto simples, cor padrao
      begin
        LV.Canvas.Brush.Style := bsClear;
        LV.Canvas.Font.Color := CorTextoPrincipal;
        LV.Canvas.TextOut(ColRect.Left + 16,
          ColRect.Top + (ColRect.Height - LV.Canvas.TextHeight(Texto)) div 2, Texto);
        LV.Canvas.Brush.Style := bsSolid;
      end;
    end;

    Inc(XOffset, ColWidth);
  end;
end;

procedure TForm1.BtnSairClick(Sender: TObject);
begin
  // Close (não Application.Terminate) dispara o fluxo normal de
  // fechamento da janela — inclusive o FormDestroy acima, que libera
  // os Serviços corretamente antes do processo encerrar.
  Close;
end;

procedure TForm1.BtnTransferirClick(Sender: TObject);
var
  IdOrigem, IdDestino: Integer;
  Valor: Currency;
begin
  if not TryStrToInt(EdtContaOrigem.Text, IdOrigem) then
  begin
    ShowMessage('Informe um ID de conta de origem valido.');
    Exit;
  end;
  if not TryStrToInt(EdtContaDestino.Text, IdDestino) then
  begin
    ShowMessage('Informe um ID de conta de destino valido.');
    Exit;
  end;
  if not TryStrToCurr(EdtValor.Text, Valor) then
  begin
    ShowMessage('Informe um valor valido.');
    Exit;
  end;

  try
    // O MESMO TServicoTransferencia.Transferir já testado com DUnitX e
    // já exposto pela API — nenhuma regra de negócio nova aqui, só a
    // tradução de "clique de botão" para chamada de método. O texto de
    // ajuda abaixo do formulário (item 4 do pedido) só documenta, para
    // o usuário, uma verdade que já é garantida pelo Serviço.
    FServicoTransferencia.Transferir(IdOrigem, IdDestino, Valor);
    ShowMessage('Transferencia realizada com sucesso.');
    EdtValor.Clear;
  except
    on E: ESaldoInsuficiente do
      ShowMessage(E.Message);
    on E: EValorInvalido do
      ShowMessage(E.Message);
    on E: EContaNaoEncontrada do
      ShowMessage(E.Message);
  end;
end;

end.
