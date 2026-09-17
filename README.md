# CoreContas

Motor de contas e lançamentos estilo fintech — contas com saldo, lançamentos de
crédito/débito, transferências entre contas e emissão de boleto de cobrança.

Projeto de estudo, construído em camadas (Modelo → Repositório → Serviço →
API/Desktop) com Delphi 12 Athens (RAD Studio 12) e PostgreSQL via FireDAC.

## Stack

- **Delphi 12 Athens** (RAD Studio 12)
- **PostgreSQL** via FireDAC (`DriverID=PG`)
- **Horse** — API REST
- **DUnitX** — testes unitários (camada de serviço, com repositórios fake)
- **ACBrBoleto** — emissão de boleto bancário

## Estrutura

```
CoreContas/
├── sql/            scripts de schema (PostgreSQL / PL/pgSQL)
├── src/
│   ├── modelos/        classes de domínio
│   ├── repositorios/   interfaces + implementação FireDAC/PostgreSQL
│   ├── servicos/        regras de negócio
│   └── boleto/          emissão de boleto (ACBrBoleto)
├── app-desktop/     aplicação VCL
├── app-api/         API REST (Horse)
└── testes/          projeto DUnitX
```

## Rodando o schema

```
createdb corecontas_dev
psql -d corecontas_dev -f sql/001_schema.sql
```
