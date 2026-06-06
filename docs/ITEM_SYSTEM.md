# Item System — Catálogo de Itens V0

## Visão geral

O projeto agora tem um catálogo central mínimo de itens em `Scripts/Database.gd`.

Esse catálogo serve como base para nomes, ícones, raridade, valor, tags e origem dos itens já existentes no jogo. Os valores são provisórios e existem para preparar futura venda, receitas, filtros e progressão.

## Campos principais

Cada item do catálogo expõe, por enquanto:

- `item_id`
- `nome`
- `categoria`
- `raridade`
- `valor_base`
- `pode_vender`
- `pode_usar_em_receita`
- `tags`
- `origem`
- `descricao`
- `icone`

## Itens cobertos no V0

### Pesca

- `peixe_comum`
- `escama_brilhante`

### Crops

- `trigo`
- `raiz_gelida`
- `tomate_sol`
- `abobora_sombria`

### Sementes

- `semente_basica`
- `semente_inverno`
- `semente_verao`
- `semente_outono`

### Recursos e ingredientes já existentes

- `agua`
- `carvao`
- `palha_rara`
- `rama_encantada`
- `essencia_sombria`
- `adubo_flamejante`
- `elixir_estacional`
- `pocao_crescimento`
- `pocao_aceleradora`
- `golem_coletor`
- `pocao_purificadora_fraca`

## Uso na purificação V0

A purificação da Área Bloqueada V0 agora consulta um conjunto de requisitos múltiplos:

- `pocao_purificadora_fraca` x1
- `escama_brilhante` x1
- `trigo` x3

Nesse estágio, a poção purificadora fraca funciona como catalisador provisório, `escama_brilhante` conecta a pesca à progressão e `trigo` conecta a agricultura à progressão. Agora existe uma receita V0 no caldeirão para produzir a poção: `agua` + `peixe_comum`.

## Regras atuais

- Água continua sendo recurso interno do jogo, com tratamento visual separado no StatusPanel.
- Itens de pesca já entram no inventário real e agora têm metadados estruturados.
- `pocao_purificadora_fraca` existe como item provisório/debug para o Obstáculo Mágico V0.
- `peixe_comum` também participa da alquimia V0 para ligar pesca ao catalisador de purificação.
- Crops e sementes existentes foram cadastrados apenas com o que o projeto já usa hoje.
- A receita V0 do caldeirão para a poção purificadora fraca já existe.
- Nenhum balanceamento final foi definido.

## Uso esperado

O catálogo deve ser a referência principal para:

- visual da UI;
- venda futura;
- filtros por categoria e tags;
- receitas futuras;
- expansão da pesca;
- expansão das crops.

## Relação com expansão e purificação

O catálogo também prepara futuras áreas bloqueadas da fazenda, porque a purificação poderá consultar:

- `valor_base`
- `categoria`
- `raridade`
- `tags`
- `pode_usar_em_receita`
- `origem`
- `descricao`

Isso permite que obstáculos e bloqueios exijam itens com tags como `purificacao`, `aquatico`, `magico` ou `sazonal` sem espalhar hardcode pelo projeto.

## Observação

Os dados ainda são provisórios. O objetivo do V0 é centralizar o que já existe para evitar hardcode espalhado demais.
