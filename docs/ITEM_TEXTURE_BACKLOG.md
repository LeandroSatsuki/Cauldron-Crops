# Mapa de Texturas de Itens

Este arquivo lista os itens do catálogo que ainda precisam de textura própria para UI/inventário.

## Critério usado

Considerei como "precisa de textura" todo item que hoje depende de `Database.obter_icone_item()` com emoji/texto, em vez de uma textura dedicada já existente no diretório `Assets/`.

## Como ler esta tabela

- **Prioridade 1**: itens que aparecem o tempo todo na UI de inventário, caldeirão ou slot de recompensa.
- **Prioridade 2**: itens centrais do loop atual, mas que não dominam a HUD.
- **Prioridade 3**: itens de progressão, raros ou de suporte que podem ficar para a fase de arte seguinte.
- **Textura alvo**: o tipo de asset que faria mais diferença primeiro.

## Lista técnica

| item_id | nome de exibição | grupo | prioridade | textura alvo | observação |
|---|---|---:|---:|---|---|
| `agua` | Água | recurso | 1 | ícone de inventário | aparece em receitas/loop base |
| `carvao` | Carvão | recurso | 1 | ícone de inventário | item recorrente do caldeirão |
| `trigo` | Trigo | crop | 1 | ícone de inventário | base de receitas e cultivo |
| `tomate_sol` | Tomate do Sol | crop | 1 | ícone de inventário | crop central do loop agrícola |
| `raiz_gelida` | Raiz Gélida | crop | 1 | ícone de inventário | aparece em receitas de purificação/crescimento |
| `peixe_comum` | Peixe Comum | peixe | 1 | ícone de inventário | recompensa de pesca mais frequente |
| `abobora_sombria` | Abóbora Sombria | crop | 2 | ícone de inventário | item de progressão e sazonalidade |
| `escama_brilhante` | Escama Brilhante | peixe/loot | 2 | ícone de inventário | loot mais raro de pesca/purificação |
| `semente_basica` | Semente Básica | semente | 2 | ícone de inventário | suporte ao plantio e receitas |
| `semente_verao` | Semente de Verão | semente | 2 | ícone de inventário | conversão de progresso agrícola |
| `semente_outono` | Semente de Outono | semente | 2 | ícone de inventário | conversão de progresso agrícola |
| `semente_inverno` | Semente de Inverno | semente | 2 | ícone de inventário | conversão de progresso agrícola |
| `pocao_crescimento` | Poção de Crescimento | alquimia | 3 | ícone de inventário | item de suporte do sistema de cultivo |
| `pocao_aceleradora` | Poção Aceleradora | alquimia | 3 | ícone de inventário | útil para loop, mas menos frequente |
| `pocao_purificadora_fraca` | Infusão Purificadora | alquimia | 3 | ícone de inventário | ligada ao eixo de purificação |
| `adubo_flamejante` | Adubo Flamejante | alquimia | 3 | ícone de inventário | item de progressão/sistema de solo |
| `elixir_estacional` | Elixir Estacional | alquimia | 3 | ícone de inventário | item de progressão |
| `essencia_sombria` | Essência Sombria | recurso | 3 | ícone de inventário | item raro de progressão |
| `palha_rara` | Palha Rara | recurso | 3 | ícone de inventário | material de suporte pouco frequente |
| `rama_encantada` | Rama Encantada | recurso | 3 | ícone de inventário | material de progressão/descoberta |
| `golem_coletor` | Golem Coletor | construção/serviço | 3 | ícone de inventário | item de progressão, não de uso contínuo |

## Fontes sugeridas de asset

Estas categorias já têm pesquisa prévia de pacotes em `asset-research/P02-golem-irrigador-assets/manifest.md`:

- `agua` → `instant-fastfood-pack-64x64`
- `trigo`, `tomate_sol`, `abobora_sombria`, `raiz_gelida`, `semente_basica`, `semente_inverno`, `semente_verao`, `semente_outono` → `farming-set-pixel-art` e/ou `plants-and-flowers-32-64`
- `peixe_comum`, `escama_brilhante` → `cute-fish-sprites`
- `carvao`, `palha_rara`, `rama_encantada`, `essencia_sombria`, `adubo_flamejante`, `elixir_estacional` → `rpg-items-154-free` e/ou `stones-pixel-art-32-64`
- `pocao_crescimento`, `pocao_aceleradora`, `pocao_purificadora_fraca` → `magic-potions-25`

## Observações

- As culturas já possuem texturas de mundo em `Assets/` para algumas fases visuais do lote, mas isso **não substitui** uma textura de item/inventário.
- Os itens acima ainda aparecem no catálogo com ícone textual/emoji e, por isso, continuam candidatos à arte final.
- Os itens de ferramenta (`tool_hoe`, `tool_watering_can`, `tool_harvest`, `tool_fishing_rod`, `tool_seed`) **não** entraram nesta lista porque já têm textura dedicada.

## Ordem sugerida de prioridade

1. `agua`, `carvao`, `trigo`, `tomate_sol`, `abobora_sombria`, `raiz_gelida`
2. `peixe_comum`, `escama_brilhante`
3. `semente_basica`, `semente_inverno`, `semente_verao`, `semente_outono`
4. `pocao_crescimento`, `pocao_aceleradora`, `pocao_purificadora_fraca`
5. `essencia_sombria`, `adubo_flamejante`, `elixir_estacional`, `palha_rara`, `rama_encantada`, `golem_coletor`

## Base para arte

Quando a arte começar a ser produzida, este arquivo pode virar a base de trabalho para:
- nome do asset;
- tamanho/padrão visual;
- paleta por raridade;
- vínculo com a entrada do `Database`.
