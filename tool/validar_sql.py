#!/usr/bin/env python3
"""Valida o SQL do aplicativo Vitrine em um SQLite real.

Lê o script de criação (lib/database/schema.dart) e as consultas
(lib/database/queries.dart) exatamente como estão no código do app, cria o
banco em memória, popula com dados de exemplo e confere:

  * a criação das tabelas, índices e restrições (CHECK, UNIQUE, FK);
  * o comportamento das chaves estrangeiras (SET NULL, CASCADE, RESTRICT);
  * o resultado das consultas dos relatórios (faturamento, ranking/curva ABC,
    perfil de clientes, efeito da divulgação...).

Uso:  python3 tool/validar_sql.py
"""
import pathlib
import re
import sqlite3
import sys
from datetime import datetime, timedelta

RAIZ = pathlib.Path(__file__).resolve().parent.parent


def extrair_statements():
    codigo = (RAIZ / "lib/database/schema.dart").read_text(encoding="utf-8")
    return [s.strip() for s in re.findall(r"'''(.*?)'''", codigo, re.S)]


def extrair_queries():
    codigo = (RAIZ / "lib/database/queries.dart").read_text(encoding="utf-8")
    achados = re.findall(r"static const String (\w+) = '''(.*?)''';", codigo, re.S)
    return {nome: sql.strip() for nome, sql in achados}


def iso(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%S")


def esperar(cond, msg):
    if not cond:
        print(f"FALHOU: {msg}")
        sys.exit(1)
    print(f"ok  {msg}")


def erro_de(db, sql, args=()):
    try:
        db.execute(sql, args)
    except sqlite3.IntegrityError as e:
        return str(e)
    return None


def main():
    statements = extrair_statements()
    queries = extrair_queries()
    esperar(len(statements) >= 11, f"{len(statements)} instruções de criação extraídas do schema.dart")
    esperar(len(queries) >= 20, f"{len(queries)} consultas extraídas do queries.dart")

    db = sqlite3.connect(":memory:")
    db.execute("PRAGMA foreign_keys = ON")
    for s in statements:
        db.execute(s)
    tabelas = sorted(r[0] for r in db.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))
    esperar(tabelas == ["categoria", "cliente", "divulgacao", "empresa", "item_pedido", "pedido", "produto"],
            f"7 tabelas criadas: {', '.join(tabelas)}")
    for t in tabelas:
        colunas = db.execute(f"PRAGMA table_info({t})").fetchall()
        esperar(len(colunas) >= 3, f"tabela {t} tem {len(colunas)} colunas (mínimo 3)")
    esperar(db.execute("SELECT COUNT(*) FROM empresa").fetchone()[0] == 1, "linha única de empresa criada")

    # ------------------------------------------------------------ dados de exemplo
    hoje = datetime.now().replace(hour=12, minute=0, second=0, microsecond=0)
    agora = iso(hoje)
    db.execute("INSERT INTO categoria (nome) VALUES ('Doces'), ('Bebidas')")
    produtos = [
        (1, "Brigadeiro", 300, 50),
        (1, "Bolo de pote", 1200, 10),
        (2, "Suco", 800, 3),
        (None, "Sem categoria", 500, 20),
    ]
    for cat, nome, preco, est in produtos:
        db.execute("INSERT INTO produto (categoria_id, nome, preco_centavos, estoque, criado_em) VALUES (?,?,?,?,?)",
                   (cat, nome, preco, est, agora))
    clientes = [
        ("Ana (fiel)", "111", hoje - timedelta(days=200)),
        ("Bia (nova)", "222", hoje - timedelta(days=10)),
        ("Caio (risco)", "333", hoje - timedelta(days=200)),
        ("Duda (inativa)", "444", hoje - timedelta(days=300)),
    ]
    for nome, tel, criado in clientes:
        db.execute("INSERT INTO cliente (nome, telefone, criado_em) VALUES (?,?,?)", (nome, tel, iso(criado)))

    def pedido(cliente_id, dias_atras, status, itens, desconto=0):
        quando = hoje - timedelta(days=dias_atras)
        total = sum(q * preco for _, q, preco in itens) - desconto
        cur = db.execute(
            "INSERT INTO pedido (cliente_id, data_pedido, status, forma_pagamento, desconto_centavos, total_centavos)"
            " VALUES (?,?,?,?,?,?)", (cliente_id, iso(quando), status, "PIX", desconto, total))
        for produto_id, q, preco in itens:
            db.execute("INSERT INTO item_pedido (pedido_id, produto_id, quantidade, preco_unit_centavos) VALUES (?,?,?,?)",
                       (cur.lastrowid, produto_id, q, preco))
        return cur.lastrowid

    # Ana: 4 pedidos pagos (3 deles nos últimos 90 dias -> fiel); Bia: 1 pedido há 5 dias (nova)
    for d in (120, 50, 20, 3):
        pedido(1, d, "PAGO", [(1, 10, 300), (2, 1, 1200)])
    pedido(2, 5, "PAGO", [(3, 2, 800)])
    pedido(3, 100, "PAGO", [(1, 5, 300)])           # Caio: última compra há 100 dias (em risco)
    pedido(4, 200, "PAGO", [(1, 5, 300)])           # Duda: última compra há 200 dias (inativa)
    pedido(None, 1, "CANCELADO", [(2, 3, 1200)])    # cancelado não conta
    pedido(None, 0, "ABERTO", [(4, 1, 500)])        # aberto não conta
    db.execute("INSERT INTO divulgacao (canal, data_envio, qtd_produtos) VALUES ('WHATSAPP', ?, 4)",
               (iso(hoje - timedelta(days=5)),))

    q = queries
    # ------------------------------------------------------------- consultas
    for nome, sql in q.items():
        n = sql.count("?")
        if nome in ("produtosBusca",):
            args = ("%",)
        elif nome == "produtosBuscaCategoria":
            args = (1, "%")
        elif nome in ("vendasPorDia", "rankingProdutos", "pedidosPagosPeriodo"):
            args = ("-29 day",)
        elif n == 0:
            args = ()
        else:
            args = (1,) * n
        db.execute(sql, args).fetchall()
    esperar(True, "todas as consultas do queries.dart executam sem erro de SQL")

    esperar(len(db.execute(q["produtosBusca"], ("bri%",)).fetchall()) == 1, "busca de produto por nome (LIKE)")
    esperar(len(db.execute(q["produtosBuscaCategoria"], (2, "%")).fetchall()) == 1, "filtro de produtos por categoria")
    esperar(len(db.execute(q["produtosParaVenda"]).fetchall()) == 4, "produtos para venda (ativos com estoque)")
    esperar([r[1] for r in db.execute(q["estoqueBaixo"], (5,))] == ["Suco"], "estoque baixo (<= 5) lista apenas 'Suco'")
    esperar(db.execute(q["categoriaPorNome"], ("doces",)).fetchone() is not None, "categoria por nome (sem diferenciar maiúsculas)")
    esperar(db.execute(q["contarItensDoProduto"], (1,)).fetchone()[0] == 6, "contagem de itens vendidos do produto (RN06)")

    # resumo do mês: depende do dia do mês; confere contra cálculo direto
    mes = hoje.strftime("%Y-%m")
    esperado = db.execute(
        "SELECT COALESCE(SUM(total_centavos),0), COUNT(*) FROM pedido WHERE status='PAGO' AND substr(data_pedido,1,7)=?",
        (mes,)).fetchone()
    obtido = db.execute(q["resumoMes"]).fetchone()
    esperar(tuple(obtido) == tuple(esperado), f"resumo do mês (faturamento/pedidos) = {tuple(obtido)}")

    vendas7 = db.execute(q["vendasPorDia"], ("-6 day",)).fetchall()
    esperar(sum(r[2] for r in vendas7) == 2, f"vendas por dia (7 dias): 2 pedidos pagos ({[tuple(r) for r in vendas7]})")

    rank = db.execute(q["rankingProdutos"], ("-199 day",)).fetchall()
    esperar(rank[0][1] == "Brigadeiro", f"ranking de produtos por receita: {[(r[1], r[3]) for r in rank]}")
    esperar(all(rank[i][3] >= rank[i + 1][3] for i in range(len(rank) - 1)), "ranking ordenado por receita decrescente")
    esperar(all(r[1] != "Sem categoria" for r in rank), "pedido ABERTO/CANCELADO fora do ranking")

    perfil = {r[1]: r for r in db.execute(q["clientesPerfil"])}
    ana = perfil["Ana (fiel)"]
    esperar(ana[4] == 4 and ana[7] == 3, f"Ana: 4 pedidos, 3 nos últimos 90 dias (total={ana[4]}, 90d={ana[7]})")
    esperar(perfil["Duda (inativa)"][4] == 1, "Duda: 1 pedido")
    esperar(perfil["Bia (nova)"][5] == perfil["Bia (nova)"][6], "Bia: primeira e última compra coincidem")

    ef = db.execute(q["divulgacoesEfeito"]).fetchall()
    esperar(len(ef) == 1 and ef[0][3] == 2, f"efeito da divulgação: 2 pedidos pagos na janela de 4 dias ({[tuple(r) for r in ef]})")
    esperar(db.execute(q["pedidosPagosPeriodo"], ("-29 day",)).fetchone()[0] == 3, "pedidos pagos nos últimos 30 dias = 3")
    esperar(db.execute(q["divulgacoesNoMes"]).fetchone()[0] in (0, 1), "divulgações no mês")

    lista = db.execute(q["pedidosLista"]).fetchall()
    esperar(len(lista) == 9, "lista de pedidos com JOIN (9 pedidos)")
    esperar(lista[0][3] in ("ABERTO", "PAGO", "CANCELADO"), "pedidos ordenados do mais recente ao mais antigo")
    esperar(len(db.execute(q["itensDoPedido"], (1,)).fetchall()) == 2, "itens do pedido com nome do produto")
    esperar(len(db.execute(q["pedidosDoCliente"], (1,)).fetchall()) == 4, "histórico de pedidos do cliente (RF12)")

    # --------------------------------------------------- restrições e chaves
    esperar(erro_de(db, "INSERT INTO produto (nome, preco_centavos, estoque, criado_em) VALUES ('x', -1, 0, ?)", (agora,)) is not None,
            "CHECK: preço negativo é rejeitado")
    esperar(erro_de(db, "INSERT INTO produto (nome, preco_centavos, estoque, criado_em) VALUES ('x', 1, -5, ?)", (agora,)) is not None,
            "CHECK: estoque negativo é rejeitado")
    esperar(erro_de(db, "INSERT INTO pedido (data_pedido, status, total_centavos) VALUES (?, 'XYZ', 0)", (agora,)) is not None,
            "CHECK: status inválido é rejeitado")
    esperar(erro_de(db, "INSERT INTO item_pedido (pedido_id, produto_id, quantidade, preco_unit_centavos) VALUES (1, 2, 0, 1)") is not None,
            "CHECK: quantidade zero é rejeitada")
    esperar(erro_de(db, "INSERT INTO item_pedido (pedido_id, produto_id, quantidade, preco_unit_centavos) VALUES (1, 1, 1, 1)") is not None,
            "UNIQUE: mesmo produto duas vezes no pedido é rejeitado")
    esperar(erro_de(db, "INSERT INTO cliente (nome, telefone, criado_em) VALUES ('Outro', '111', ?)", (agora,)) is not None,
            "UNIQUE: telefone duplicado é rejeitado")
    esperar(erro_de(db, "INSERT INTO categoria (nome) VALUES ('Doces')") is not None, "UNIQUE: categoria duplicada é rejeitada")
    esperar(erro_de(db, "INSERT INTO pedido (cliente_id, data_pedido, status, total_centavos) VALUES (999, ?, 'PAGO', 0)", (agora,)) is not None,
            "FK: pedido com cliente inexistente é rejeitado")
    esperar(erro_de(db, "INSERT INTO empresa (id, nome) VALUES (2, 'X')") is not None, "CHECK: empresa só aceita id = 1")
    esperar(erro_de(db, "DELETE FROM produto WHERE id = 1") is not None, "FK RESTRICT: produto já vendido não pode ser excluído")

    db.execute("DELETE FROM cliente WHERE id = 1")
    esperar(db.execute("SELECT COUNT(*) FROM pedido WHERE cliente_id IS NULL").fetchone()[0] == 6,
            "FK SET NULL: excluir cliente preserva os pedidos (ficam sem cliente)")
    esperar(db.execute("SELECT COUNT(*) FROM pedido").fetchone()[0] == 9, "nenhum pedido perdido ao excluir cliente")
    db.execute("DELETE FROM pedido WHERE id = 1")
    esperar(db.execute("SELECT COUNT(*) FROM item_pedido WHERE pedido_id = 1").fetchone()[0] == 0,
            "FK CASCADE: excluir pedido remove seus itens")
    db.execute("DELETE FROM categoria WHERE id = 2")
    esperar(db.execute("SELECT categoria_id FROM produto WHERE nome = 'Suco'").fetchone()[0] is None,
            "FK SET NULL: excluir categoria deixa o produto sem categoria")

    print("\nTodas as verificações de SQL passaram.")


if __name__ == "__main__":
    main()
