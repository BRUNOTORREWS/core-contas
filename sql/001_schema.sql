-- =====================================================================
-- CoreContas — schema do banco (PostgreSQL)
-- Adaptado do projeto final do curso original (Firebird 3.0) para
-- Delphi 12 Athens + PostgreSQL, via FireDAC (DriverID=PG).
-- =====================================================================
--
-- CONVENÇÃO DE NOMENCLATURA — leia isto antes de rodar o script:
--
-- Todo identificador abaixo (tabela, coluna, função, trigger, índice)
-- está em snake_case, minúsculo, e NUNCA entre aspas duplas. Essa não
-- é uma questão de estilo — é a decisão que evita uma classe inteira
-- de bugs de "column does not exist" mais tarde, no FireDAC e no
-- pgAdmin. Veja a explicação completa sobre "case folding" na mensagem
-- que acompanha este arquivo.
--
-- Rode este script em uma base de TESTE (ex.: createdb corecontas_dev),
-- nunca direto em produção.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabela CLIENTE
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- GENERATED ALWAYS AS IDENTITY (padrão SQL, PostgreSQL 10+) substitui
    -- o par GENERATOR + TRIGGER BEFORE INSERT que o Firebird exige para
    -- autoincremento. O próprio PostgreSQL cria e gerencia a sequência
    -- internamente — não existe "CREATE GENERATOR" nem trigger de
    -- autoincremento neste schema.
    nome         varchar(100) NOT NULL,
    cnpj_cpf     varchar(14),
    endereco     varchar(100),
    bairro       varchar(60),
    cidade       varchar(60),
    uf           char(2),
    cep          varchar(9)
);

COMMENT ON TABLE cliente IS 'Titular de contas no CoreContas (pessoa física ou jurídica).';

-- ---------------------------------------------------------------------
-- Tabela CONTA
-- ---------------------------------------------------------------------
CREATE TABLE conta (
    id_conta               integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente              integer NOT NULL REFERENCES cliente (id_cliente),
    saldo                   numeric(15,2) NOT NULL DEFAULT 0,
    data_abertura           timestamp NOT NULL DEFAULT now(),
    data_ultima_alteracao   timestamp,
    CONSTRAINT chk_conta_saldo_nao_negativo CHECK (saldo >= 0)
    -- Defesa em profundidade: o TServicoTransferencia (camada de
    -- Serviços, mais adiante) já impede saldo negativo em Object Pascal
    -- antes de gravar — mas o banco não confia cegamente na aplicação.
    -- Qualquer UPDATE que tente deixar o saldo negativo, venha de onde
    -- vier (um bug futuro, um script manual, outra aplicação que um dia
    -- acesse o mesmo banco), é barrado aqui, na borda mais baixa do
    -- sistema.
);

COMMENT ON TABLE conta IS 'Conta financeira de um cliente, com saldo corrente.';

-- ---------------------------------------------------------------------
-- Tabela LANCAMENTO
-- ---------------------------------------------------------------------
CREATE TABLE lancamento (
    id_lancamento     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_conta          integer NOT NULL REFERENCES conta (id_conta),
    valor             numeric(15,2) NOT NULL,
    -- positivo = crédito, negativo = débito (mesma convenção do curso original)
    descricao         varchar(200),
    data_lancamento   timestamp NOT NULL DEFAULT now(),
    CONSTRAINT chk_lancamento_valor_nao_zero CHECK (valor <> 0)
);

COMMENT ON TABLE lancamento IS 'Registro individual de crédito ou débito em uma conta (partida simples).';

-- ---------------------------------------------------------------------
-- Índices
-- ---------------------------------------------------------------------
-- Olhando à frente para a camada de Repositório: toda consulta que o
-- futuro IRepositorioLancamento.ListarPorConta vai fazer filtra por
-- id_conta — é exatamente a coluna de alta seletividade (muitos valores
-- distintos, muito usada em WHERE) que merece índice, pelo mesmo
-- raciocínio de "índices e plano de execução" do material de SQL
-- avançado.
CREATE INDEX idx_lancamento_conta ON lancamento (id_conta);
CREATE INDEX idx_conta_cliente ON conta (id_cliente);

-- ---------------------------------------------------------------------
-- Trigger: carimbar data_ultima_alteracao e reforçar saldo não-negativo
-- ---------------------------------------------------------------------
-- Em PostgreSQL, diferente do Firebird, a LÓGICA do trigger (a função)
-- e o VÍNCULO do trigger com a tabela/evento são dois objetos
-- separados: primeiro cria-se uma FUNCTION em PL/pgSQL, depois um
-- TRIGGER que a referencia. No Firebird, os dois vinham juntos em um
-- único bloco "CREATE TRIGGER ... AS BEGIN ... END".
CREATE OR REPLACE FUNCTION trg_conta_before_update() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    -- Equivalente ao "EXCEPTION EX_ESTOQUE_NEGATIVO" do Firebird: em
    -- PL/pgSQL, um erro é lançado com RAISE EXCEPTION. Isso já seria
    -- redundante com o CHECK CONSTRAINT declarado na tabela CONTA (o
    -- CHECK sozinho já bloquearia o UPDATE) — está aqui de propósito,
    -- só para comparar lado a lado a sintaxe de trigger do Firebird com
    -- a do PostgreSQL. Na prática, prefira CHECK CONSTRAINT para uma
    -- regra simples como esta, e reserve trigger para lógica que um
    -- CHECK não expressa sozinho, como o carimbo de data logo abaixo.
    IF NEW.saldo < 0 THEN
        RAISE EXCEPTION 'Saldo nao pode ficar negativo (conta %)', NEW.id_conta;
    END IF;

    NEW.data_ultima_alteracao := now();
    RETURN NEW; -- em um trigger BEFORE, retornar NEW é o que aplica a mudança à linha
END;
$$;

CREATE TRIGGER trg_conta_before_update
    BEFORE UPDATE ON conta
    FOR EACH ROW
    EXECUTE FUNCTION trg_conta_before_update();

-- ---------------------------------------------------------------------
-- View: extrato consolidado (conta + lançamentos)
-- ---------------------------------------------------------------------
-- Mesmo papel da VW_PEDIDOS_PENDENTES do curso original: isola a futura
-- camada de Repositório de mudanças estruturais nas tabelas-base. Se
-- amanhã LANCAMENTO ganhar uma coluna nova, o IRepositorioLancamento
-- continua funcionando sem alteração, desde que as colunas que a view
-- expõe não mudem.
CREATE OR REPLACE VIEW vw_extrato_conta AS
SELECT
    l.id_lancamento,
    l.id_conta,
    c.id_cliente,
    l.valor,
    l.descricao,
    l.data_lancamento
FROM lancamento l
JOIN conta c ON c.id_conta = l.id_conta
ORDER BY l.data_lancamento DESC;
