# Item Texture Backlog

Este arquivo lista os itens do catálogo que ainda precisam de textura própria para UI/inventário.

## Critério usado

Considerei como "precisa de textura" todo item que hoje depende de `Database.obter_icone_item()` com emoji/texto, em vez de uma textura dedicada já existente no diretório `Assets/`.

## Itens que precisam de textura

### Recursos e materiais básicos
- `agua`
- `carvao`
- `palha_rara`
- `rama_encantada`
- `essencia_sombria`
- `adubo_flamejante`
- `elixir_estacional`

### Crops e colheitas
- `trigo`
- `tomate_sol`
- `abobora_sombria`
- `raiz_gelida`
- `peixe_comum`
- `escama_brilhante`

### Sementes
- `semente_basica`
- `semente_inverno`
- `semente_verao`
- `semente_outono`

### Itens de alquimia / progressão
- `pocao_crescimento`
- `pocao_aceleradora`
- `pocao_purificadora_fraca`
- `golem_coletor`

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

## Próximo passo provável

Quando a arte começar a ser produzida, este arquivo pode virar a base de trabalho para:
- nome do asset;
- tamanho/padrão visual;
- paleta por raridade;
- vínculo com a entrada do `Database`.
