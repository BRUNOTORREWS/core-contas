# CoreContas

Motor de contas e lançamentos estilo fintech: contas com saldo, lançamentos de
crédito/débito, transferências entre contas e emissão de boleto de cobrança.

## Sobre o projeto

Este é o projeto final de um curso guiado de Delphi, reconstruído do zero e
adaptado de **Firebird 3.0** para **Delphi 12 Athens (RAD Studio 12)** +
**PostgreSQL**, com foco em arquitetura de software: camadas bem separadas,
SOLID aplicado de forma concreta, injeção de dependência via construtor,
testes automatizados e mais de uma forma de expor a mesma regra de negócio
(API REST e aplicação desktop) sem duplicar código.

Não é um banco de verdade — é um exercício deliberadamente pequeno o
suficiente para terminar, mas que passa por todas as camadas de um sistema
financeiro real.

## Arquitetura

```
UI (VCL / API REST)
       |
       v
Service (regras de negócio — TServicoConta, TServicoTransferencia, TServicoCobranca)
       |
       v
Repository (interfaces — IRepositorioConta, IRepositorioLancamento, IRepositorioCliente, ITransacao)
       |
       v
Infraestrutura (implementação concreta — FireDAC + PostgreSQL / ACBrBoleto)
```

Regra de dependência: as camadas de cima conhecem as de baixo só pela
**interface**, nunca pela implementação concreta. Só o "ponto de composição"
de cada aplicação (`CoreContasAPI.dpr` e `Unit1.pas` do app desktop) decide
qual implementação real é usada — o mesmo `TServicoTransferencia` roda,
sem alteração nenhuma, atrás de uma rota HTTP ou de um clique de botão.

### SOLID e padrões de projeto aplicados

| Princípio/Padrão | Onde aparece |
|---|---|
| **S** — Single Responsibility | Cada classe de `modelos/`, `repositorios/` e `servicos/` tem um único motivo para mudar |
| **O** — Open/Closed | Trocar de PostgreSQL para outro banco (ou para um fake de teste) não exige alterar `TServicoTransferencia` |
| **L** — Liskov Substitution | Repositórios fake (`Repositorios.Fakes.pas`) honram o mesmo contrato de exceções que a implementação real (FireDAC) |
| **I** — Interface Segregation | `IRepositorioConta`, `IRepositorioLancamento` e `IRepositorioCliente` são interfaces pequenas e específicas, não uma "IRepositorio" genérica |
| **D** — Dependency Inversion | Toda dependência entre camadas é injetada via construtor, recebendo interfaces |
| **Repository** | `Repositorios.Interfaces.pas` + `Repositorios.FireDAC.pas` |
| **Factory** | `Repositorios.Factory.pas` (`TFabricaRepositorios`) |
| **Singleton** | `Repositorios.Conexao.pas` (`TConexaoPostgreSQL`) |

## Stack

- **Delphi 12 Athens** (RAD Studio 12), compilado para Win64
- **PostgreSQL** via FireDAC (`DriverID=PG`)
- **Horse** — API REST
- **DUnitX** — testes unitários (camada de serviço, com repositórios fake — sem tocar no banco)
- **ACBrBoleto** — emissão de boleto bancário

## Estrutura

```
CoreContas/
├── sql/                    scripts de schema (PostgreSQL / PL/pgSQL)
├── src/
│   ├── dominio/            exceções de domínio (EContaNaoEncontrada, ESaldoInsuficiente, ...)
│   ├── modelos/            classes de domínio (records: TConta, TCliente, TLancamento)
│   ├── repositorios/       interfaces + implementação FireDAC/PostgreSQL + factory + conexão
│   ├── servicos/           regras de negócio (transferência, consulta, cobrança)
│   └── boleto/             emissão de boleto (ACBrBoleto)
├── app-desktop/            aplicação VCL
├── app-api/                API REST (Horse)
└── testes/                 projeto DUnitX
```

## Rodando localmente

### 1. Banco de dados

```bash
createdb corecontas_dev
psql -d corecontas_dev -f sql/001_schema.sql
```

### 2. Configuração de conexão

A conexão (`src/repositorios/Repositorios.Conexao.pas`) lê a configuração de
variáveis de ambiente, com valores padrão para desenvolvimento local
(`localhost:5432`, banco `corecontas_dev`, usuário `postgres`):

| Variável | Padrão |
|---|---|
| `CORECONTAS_DB_HOST` | `localhost` |
| `CORECONTAS_DB_PORT` | `5432` |
| `CORECONTAS_DB_NAME` | `corecontas_dev` |
| `CORECONTAS_DB_USER` | `postgres` |
| `CORECONTAS_DB_PASSWORD` | `postgres` |

### 3. Testes (DUnitX)

Abra `testes/CoreContasTestes.dproj` no Delphi. O projeto de testes não
depende de FireDAC nem de PostgreSQL — usa repositórios fake em memória
(`src/repositorios/Repositorios.Fakes.pas`). Se o compilador não encontrar as
units `DUnitX.*`, adicione a pasta `Source` da instalação do
[DUnitX](https://github.com/VSoftTechnologies/DUnitX) ao Search Path do
projeto.

### 4. Aplicação desktop (VCL)

Abra `app-desktop/CoreContasDesktop.dproj`, compile para **Windows 64-bit**
(precisa bater com a bitness do PostgreSQL instalado) e rode. Se aparecer
erro de `libpq.dll` não encontrado, copie `libpq.dll` e as DLLs ao lado dele
(`libssl-3-x64.dll`, `libcrypto-3-x64.dll`, `libintl-9.dll`, `libiconv-2.dll`
etc.) da pasta `bin` da instalação do PostgreSQL para a pasta de saída do
build (`app-desktop\Win64\Debug\`).

### 5. API REST (Horse)

Requer o [Horse](https://github.com/HashLoad/horse) e o
[horse-jhonson](https://github.com/HashLoad/horse-jhonson) instalados e
apontados no Search Path. Expõe:

- `GET /contas/:id/saldo`
- `GET /contas/:id/extrato`
- `POST /lancamentos` — `{ "contaOrigem": 1, "contaDestino": 2, "valor": 150.00 }`

## Status

- ✅ Schema, camada de modelo/repositório/serviço, testes DUnitX (7/7 passando) e aplicação desktop — funcionando de ponta a ponta.
- 🚧 API REST (Horse) — código pronto, ainda não testada em execução.
- 🚧 Emissão de boleto (ACBrBoleto) — código pronto (`IEmissorBoleto`, `TEmissorBoletoACBr`, `TServicoCobranca`), mas não integrado a nenhum executável. O `master` atual do ACBr acoplou `ACBrBoleto` a uma cadeia de dependências bem mais pesada do que quando este código foi escrito (PIX, certificado digital/OpenSSL via `ACBrDFeSSL`, envio de e-mail), e a API do componente mudou (a unit `ACBrBoletoTitulo` referenciada aqui não existe mais na árvore atual do projeto) — integrar de verdade exigiria adaptar este código à API vigente do ACBr, não só instalar a biblioteca.
