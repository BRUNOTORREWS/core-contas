object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'CoreContas'
  ClientHeight = 760
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object PnlConsulta: TPanel
    Left = 24
    Top = 24
    Width = 712
    Height = 120
    BevelOuter = bvNone
    BorderStyle = bsSingle
    TabOrder = 0
    object LblTituloConsulta: TLabel
      Left = 20
      Top = 16
      Width = 111
      Height = 19
      Caption = 'Consultar conta'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LblContaId: TLabel
      Left = 20
      Top = 52
      Width = 68
      Height = 13
      Caption = 'ID DA CONTA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object LblSaldoTitulo: TLabel
      Left = 380
      Top = 52
      Width = 312
      Height = 13
      Alignment = taRightJustify
      Caption = 'SALDO ATUAL'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object LblSaldo: TLabel
      Left = 380
      Top = 66
      Width = 312
      Height = 32
      Alignment = taRightJustify
      Caption = 'R$ -'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object EdtContaId: TEdit
      Left = 20
      Top = 70
      Width = 160
      Height = 26
      TabOrder = 0
      TextHint = 'Ex: 1'
    end
    object BtnConsultar: TButton
      Left = 190
      Top = 69
      Width = 110
      Height = 28
      Caption = 'Consultar'
      TabOrder = 1
      OnClick = BtnConsultarClick
    end
  end
  object PnlExtrato: TPanel
    Left = 24
    Top = 156
    Width = 712
    Height = 340
    BevelOuter = bvNone
    BorderStyle = bsSingle
    TabOrder = 1
    object LblTituloExtrato: TLabel
      Left = 20
      Top = 16
      Width = 179
      Height = 19
      Caption = 'Extrato de lan'#231'amentos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LblExtratoVazio: TLabel
      Left = 20
      Top = 48
      Width = 672
      Height = 270
      Alignment = taCenter
      Caption = 'Nenhum lan'#231'amento encontrado para esta conta.'
      Layout = tlCenter
    end
    object ListViewExtrato: TListView
      Left = 20
      Top = 48
      Width = 672
      Height = 270
      Columns = <
        item
          Caption = 'DATA'
          Width = 140
        end
        item
          Caption = 'DESCRI'#199#195'O'
          Width = 262
        end
        item
          Caption = 'TIPO'
          Width = 110
        end
        item
          Caption = 'VALOR'
          Width = 150
          Alignment = taRightJustify
        end>
      TabOrder = 0
      ViewStyle = vsReport
      OnDrawItem = ListViewExtratoDrawItem
    end
  end
  object PnlTransferencia: TPanel
    Left = 24
    Top = 508
    Width = 712
    Height = 190
    BevelOuter = bvNone
    BorderStyle = bsSingle
    TabOrder = 2
    object LblTituloTransferencia: TLabel
      Left = 20
      Top = 16
      Width = 154
      Height = 19
      Caption = 'Nova transfer'#234'ncia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object LblContaOrigem: TLabel
      Left = 20
      Top = 52
      Width = 83
      Height = 13
      Caption = 'CONTA ORIGEM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object LblContaDestino: TLabel
      Left = 220
      Top = 52
      Width = 88
      Height = 13
      Caption = 'CONTA DESTINO'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object LblValor: TLabel
      Left = 420
      Top = 52
      Width = 33
      Height = 13
      Caption = 'VALOR'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object LblAjudaTransferencia: TLabel
      Left = 20
      Top = 114
      Width = 672
      Height = 32
      AutoSize = False
      Caption =
        'A transfer'#234'ncia '#233' validada automaticamente: saldo insuficient' +
        'e ou valores inv'#225'lidos s'#227'o bloqueados antes do envio.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object EdtContaOrigem: TEdit
      Left = 20
      Top = 70
      Width = 180
      Height = 26
      TabOrder = 0
      TextHint = 'ID origem'
    end
    object EdtContaDestino: TEdit
      Left = 220
      Top = 70
      Width = 180
      Height = 26
      TabOrder = 1
      TextHint = 'ID destino'
    end
    object EdtValor: TEdit
      Left = 420
      Top = 70
      Width = 140
      Height = 26
      TabOrder = 2
      TextHint = 'R$ 0,00'
    end
    object BtnTransferir: TPanel
      Left = 580
      Top = 68
      Width = 112
      Height = 30
      BevelOuter = bvNone
      Caption = 'Transferir'
      ParentBackground = False
      OnClick = BtnTransferirClick
    end
  end
  object BtnSair: TButton
    Left = 626
    Top = 714
    Width = 110
    Height = 28
    Caption = 'Sair'
    TabOrder = 3
    OnClick = BtnSairClick
  end
end
