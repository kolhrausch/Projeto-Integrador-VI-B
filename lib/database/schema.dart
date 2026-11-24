/// Script de criação do banco local (SQLite).
///
/// Cada item da lista é UMA instrução SQL, executada em ordem no `onCreate`
/// (primeira abertura do app). O mesmo texto é validado pelo script
/// `tool/validar_sql.py` e descrito em docs/09-construcao-do-banco.md.
abstract final class Schema {
  static const List<String> statements = [
    '''
CREATE TABLE empresa (
  id                  INTEGER PRIMARY KEY CHECK (id = 1),
  nome                TEXT NOT NULL,
  slogan              TEXT,
  whatsapp            TEXT,
  instagram           TEXT,
  horario_atendimento TEXT,
  logo_path           TEXT
)
''',
    '''
CREATE TABLE categoria (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  nome      TEXT NOT NULL UNIQUE,
  descricao TEXT,
  ativa     INTEGER NOT NULL DEFAULT 1 CHECK (ativa IN (0,1))
)
''',
    '''
CREATE TABLE produto (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  categoria_id   INTEGER REFERENCES categoria(id) ON DELETE SET NULL,
  nome           TEXT NOT NULL,
  descricao      TEXT,
  preco_centavos INTEGER NOT NULL CHECK (preco_centavos >= 0),
  estoque        INTEGER NOT NULL DEFAULT 0 CHECK (estoque >= 0),
  foto_path      TEXT,
  ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
  criado_em      TEXT NOT NULL
)
''',
    '''
CREATE TABLE cliente (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  nome        TEXT NOT NULL,
  telefone    TEXT UNIQUE,
  email       TEXT,
  observacoes TEXT,
  criado_em   TEXT NOT NULL
)
''',
    '''
CREATE TABLE pedido (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  cliente_id        INTEGER REFERENCES cliente(id) ON DELETE SET NULL,
  data_pedido       TEXT NOT NULL,
  status            TEXT NOT NULL CHECK (status IN ('ABERTO','PAGO','CANCELADO')),
  forma_pagamento   TEXT CHECK (forma_pagamento IN ('PIX','DINHEIRO','CARTAO','OUTRO')),
  desconto_centavos INTEGER NOT NULL DEFAULT 0 CHECK (desconto_centavos >= 0),
  total_centavos    INTEGER NOT NULL CHECK (total_centavos >= 0)
)
''',
    '''
CREATE TABLE item_pedido (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  pedido_id           INTEGER NOT NULL REFERENCES pedido(id)  ON DELETE CASCADE,
  produto_id          INTEGER NOT NULL REFERENCES produto(id) ON DELETE RESTRICT,
  quantidade          INTEGER NOT NULL CHECK (quantidade > 0),
  preco_unit_centavos INTEGER NOT NULL CHECK (preco_unit_centavos >= 0),
  UNIQUE (pedido_id, produto_id)
)
''',
    '''
CREATE TABLE divulgacao (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  canal        TEXT NOT NULL CHECK (canal IN ('WHATSAPP','INSTAGRAM','OUTRO')),
  data_envio   TEXT NOT NULL,
  qtd_produtos INTEGER NOT NULL CHECK (qtd_produtos >= 0),
  observacao   TEXT
)
''',
    '''
CREATE INDEX idx_produto_categoria ON produto(categoria_id)
''',
    '''
CREATE INDEX idx_pedido_data ON pedido(data_pedido)
''',
    '''
CREATE INDEX idx_pedido_cliente ON pedido(cliente_id)
''',
    '''
CREATE INDEX idx_item_produto ON item_pedido(produto_id)
''',
    '''
INSERT INTO empresa (id, nome) VALUES (1, 'Meu Negócio')
''',
  ];
}
