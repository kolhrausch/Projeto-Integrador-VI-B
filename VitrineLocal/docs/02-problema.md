# 2. Problema que resolve

## O problema

Grande parte dos microempreendedores e pequenos comércios ainda opera com controles improvisados: caderno, planilhas soltas, conversas de WhatsApp e memória. Isso gera três problemas principais:

1. **Presença digital fraca.** Os produtos são divulgados por fotos enviadas uma a uma em conversas, sem um catálogo organizado, com preços desatualizados e sem saber o que realmente despertou interesse. Muitos negócios nem têm site ou loja virtual por causa do custo e da complexidade.
2. **Decisões no "achismo".** Sem dados organizados, o dono não sabe com segurança qual produto dá mais retorno, quais clientes deixaram de comprar, qual o ticket médio ou em quais dias a venda cai.
3. **Dependência de internet e de ferramentas caras.** Sistemas de gestão e lojas virtuais costumam exigir conexão constante e mensalidade, o que é um obstáculo para quem atende em feiras, eventos, zona rural ou locais com sinal ruim.

## Como o aplicativo resolve

| Problema | Solução no Vitrine360 |

| Divulgação desorganizada | Catálogo digital com fotos, preços e categorias, que pode ser compartilhado em um toque (WhatsApp, Instagram e outros apps) |
| Pedidos e clientes sem registro | Cadastro de clientes e de pedidos com itens, forma de pagamento e status |
| Decisões sem dados | Painel e relatórios com indicadores calculados a partir dos próprios registros do negócio |
| Dependência de internet | Banco de dados **SQLite local**: todas as funções de cadastro, consulta e análise funcionam sem conexão |
| Custo | Aplicativo sem mensalidade e sem servidor próprio, pois os dados ficam no aparelho |

## Contribuição da Ciência de Dados

Os dados gerados pelo uso diário (pedidos, itens, clientes, compartilhamentos) alimentam análises descritivas no próprio aparelho:

- Faturamento e número de pedidos por período
- Ticket médio
- Ranking de produtos e **curva ABC**
- Perfil de clientes por recência e frequência de compra (fiéis, novos, em risco, inativos)
- Tendência de vendas por média móvel
- Efeito da divulgação: relação entre compartilhamentos do catálogo e pedidos no período

Detalhes dos cálculos estão em [03-funcionalidades.md](03-funcionalidades.md).
