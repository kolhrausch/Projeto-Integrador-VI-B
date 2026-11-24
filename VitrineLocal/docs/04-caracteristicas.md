# 4. Características do aplicativo

## Requisitos funcionais

### Módulo Catálogo (presença digital)
| Código | Funcionalidade |
|---|---|
| RF01 | Cadastrar, editar, ativar/desativar e excluir produtos (nome, descrição, preço, estoque, foto, categoria) |
| RF02 | Cadastrar e editar categorias de produtos |
| RF03 | Buscar e filtrar produtos por nome e categoria |
| RF04 | Compartilhar o catálogo (texto formatado e imagens) por WhatsApp, Instagram e outros apps instalados no aparelho |
| RF05 | Registrar cada compartilhamento realizado (canal e data) para análise de divulgação |
| RF06 | Configurar a "Minha vitrine": nome da empresa, slogan, logotipo, WhatsApp, Instagram e horário de atendimento |

### Módulo Clientes e Pedidos
| Código | Funcionalidade |
|---|---|
| RF07 | Cadastrar, editar e excluir clientes (nome, telefone, e-mail opcional, observações) |
| RF08 | Registrar pedido com cliente, itens, quantidades, desconto e forma de pagamento |
| RF09 | Calcular automaticamente subtotal e total do pedido |
| RF10 | Atualizar o estoque ao finalizar ou cancelar um pedido |
| RF11 | Listar pedidos com filtro por status (aberto, pago, cancelado) e período |
| RF12 | Consultar o histórico de compras de cada cliente |

### Módulo Análise de Dados
| Código | Funcionalidade |
|---|---|
| RF13 | Painel inicial com faturamento do mês, número de pedidos, ticket médio e novos clientes |
| RF14 | Gráfico de vendas por dia, semana ou mês |
| RF15 | Ranking de produtos mais vendidos e **curva ABC** |
| RF16 | Classificação de clientes por recência e frequência: fiéis, novos, em risco e inativos |
| RF17 | Indicador de tendência de vendas por média móvel de 7 dias |
| RF18 | Relatório de produtos com estoque baixo |
| RF19 | Exportar resumo dos relatórios em arquivo CSV |

### Módulo Geral
| Código | Funcionalidade |
|---|---|
| RF20 | Tela "Sobre o app" com o nome completo de todos os integrantes do grupo |
| RF21 | Backup e restauração do arquivo do banco de dados (opcional, tempo permitindo) |

## Requisitos não funcionais

| Código | Requisito |
|---|---|
| RNF01 | Funcionar **100% offline**, com banco de dados SQLite local |
| RNF02 | Rodar em Android 6.0 (API 23) ou superior |
| RNF03 | Interface simples, com navegação por barra inferior e textos legíveis |
| RNF04 | Resposta das consultas do painel em menos de 2 segundos para até 5.000 pedidos |
| RNF05 | Dados armazenados somente no aparelho, sem envio a servidores externos |
| RNF06 | Valores monetários armazenados em centavos (inteiros) para evitar erros de arredondamento |

## Regras de negócio

- **RN01:** Um pedido só pode ser finalizado com pelo menos um item.
- **RN02:** A quantidade de cada item deve ser maior que zero e não pode exceder o estoque disponível.
- **RN03:** O preço do item é copiado do produto no momento da venda (preço histórico), para que alterações futuras não mudem pedidos antigos.
- **RN04:** Total do pedido = soma dos subtotais dos itens − desconto. O desconto não pode ser maior que a soma dos itens.
- **RN05:** Cancelar um pedido devolve ao estoque as quantidades dos itens.
- **RN06:** Produto com pedidos vinculados não é excluído, apenas desativado.
- **RN07:** Classificação de clientes (considerando a data de referência = hoje):
  - **Novo:** primeira compra há 30 dias ou menos
  - **Fiel:** 3 ou mais pedidos nos últimos 90 dias
  - **Em risco:** última compra entre 60 e 120 dias atrás
  - **Inativo:** última compra há mais de 120 dias ou nenhuma compra

## Indicadores de Ciência de Dados

Todos calculados por consultas SQL sobre o banco local.

| Indicador | Definição |
|---|---|
| Faturamento | Soma de `pedido.total_centavos` dos pedidos pagos no período |
| Ticket médio | Faturamento ÷ quantidade de pedidos pagos |
| Curva ABC | Produtos ordenados por receita; **A** = até 80% da receita acumulada, **B** = 80% a 95%, **C** = restante |
| Recência/Frequência | Dias desde a última compra e número de pedidos em uma janela de tempo |
| Média móvel (7 dias) | Média do faturamento diário nos 7 dias anteriores, usada para indicar tendência de alta ou queda |
| Efeito da divulgação | Pedidos nos 3 dias seguintes a cada compartilhamento do catálogo, comparados à média geral |

Exemplo de consulta (ranking de produtos para a curva ABC):

```sql
SELECT p.nome,
       SUM(i.quantidade * i.preco_unit_centavos) AS receita_centavos
FROM item_pedido i
JOIN produto p ON p.id = i.produto_id
JOIN pedido  d ON d.id = i.pedido_id
WHERE d.status = 'PAGO'
  AND d.data_pedido >= date('now', '-30 day')
GROUP BY p.id
ORDER BY receita_centavos DESC;
```
