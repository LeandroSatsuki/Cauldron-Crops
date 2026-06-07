# Catálogo de Transição — plano de migração do catálogo legado para o catálogo definitivo

## 1. Estado atual do catálogo no código

Hoje o projeto está em um estado híbrido de catálogo:

- `Scripts/Database.gd` ainda contém o catálogo legado/provisório de itens, receitas e alguns helpers de alquimia.
- `Data/recipes/*.tres` contém as receitas em formato `RecipeData` resource, usadas pela interface do livro e pela navegação do catálogo moderno.
- `Scripts/data/RecipeDatabase.gd` é a fonte de leitura dos resources de receita.
- `Scripts/RecipeBookUI.gd` usa `RecipeDatabase` para montar a exibição do Livro de Receitas.
- `Scripts/Cauldron.gd` ainda usa `Database.receitas_alquimia` como fonte funcional de produção.

Esse desenho é funcional, mas cria risco de drift entre:

- o catálogo legado do `Database`;
- os resources em `Data/recipes/`;
- e a UI do livro/calderão, que podem ficar desalinhados se os IDs mudarem em um lado e não no outro.

## 2. Catálogo definitivo de design

Os documentos novos de design definem uma direção mais completa para o jogo:

- Murchume como nome da corrupção;
- NPCs e seres mágicos como eixo de quests;
- 30 receitas iniciais;
- 16 crops definitivas;
- tempos reais de crops;
- 16 peixes sazonais;
- 7 peixes mágicos.

Esses documentos não são só listas de itens: eles definem a forma do catálogo futuro, a progressão e a leitura do mundo.

## 3. Tabela de equivalência legado -> definitivo

| Legado atual | Direção definitiva provável | Observação |
|---|---|---|
| `trigo` | `Solbroto` | crop básica de entrada |
| `abobora_sombria` | `Cinzabóbora` | crop de outono/volume |
| `raiz_gelida` | `Clarirraiz` | raiz de suporte/friagem |
| `peixe_comum` | `Riafin` | peixe base de água doce |
| `pocao_purificadora_fraca` | `Infusão Purificadora` ou `Água de Broto Claro` | pode virar o nome definitivo do efeito de purificação inicial |
| `tomate_sol` | sem equivalente direto ainda | pode virar ingrediente legado de ponte até o catálogo novo consolidar |
| `escama_brilhante` | item legado; futuro item derivado de pesca mágica ou purificação | não há equivalente direto no catálogo definitivo atual |
| `palha_rara` / `rama_encantada` | ingredientes legados de ponte para golem | podem existir enquanto a linha de ajudantes não é migrada |
| `golem_coletor` | ponte provisória do sistema de ajudantes | ainda não há um equivalente definitivo fechado nos docs novos |

## 4. Receitas legadas que podem permanecer temporariamente

Estas receitas ainda ajudam como ponte enquanto a migração não acontece em lote:

- `raiz_gelida_peixe_comum`
- `trigo_raiz_gelida`
- `palha_rara_rama_encantada`
- `abobora_sombria_raiz_gelida`

Elas cobrem, respectivamente, purificação, crescimento, golem/ajudantes e sazonalidade intermediária.

## 5. Receitas legadas candidatas a substituição futura

Estas receitas tendem a desalinhamento maior com o catálogo definitivo e devem ser tratadas como substituição futura:

- `carvao_trigo`
- `peixe_comum_trigo`
- `carvao_raiz_gelida`
- `tomate_sol_trigo`
- `tomate_sol_raiz_gelida`

Motivo: elas ainda refletem um catálogo provisório e dependem de nomes/combinações que não representam o desenho final dos docs novos.

## 6. Primeiras receitas definitivas candidatas

As receitas abaixo são candidatas para a primeira onda de migração definitiva, mas não devem ser implementadas agora neste passo de documentação:

- `Saquinho de Semente Mista`
- `Infusão Purificadora`
- `Água de Broto Claro`
- `Kit de Plantio Ritual`
- `Fritura de Riafin`
- opcional futura: `Bálsamo de Raiz e Flor`

Essas receitas têm uma boa relação com o loop atual e ajudam a converter o catálogo novo em gameplay legível sem depender de sistemas ainda imaturos.

## 7. O que NÃO migrar agora

Evitar migrar neste momento qualquer conteúdo que dependa de sistemas ainda não maduros ou ainda não formalizados:

- receitas com buffs complexos;
- receitas de stamina/energia sem sistema maduro;
- receitas de clima/hora/peixes mágicos;
- `Banquete de Restauração`;
- `Banquete do Eclipse`;
- receitas dependentes de NPCs/diálogo;
- múltiplos outputs de golem;
- save/schema.

## 8. Estratégia de transição recomendada

A transição segura deve seguir esta ordem:

1. manter o catálogo legado temporariamente;
2. criar uma tabela de alias/compatibilidade antes de trocar IDs;
3. alinhar `Database.gd` e `Data/recipes/*.tres` antes de qualquer migração maior;
4. migrar poucas receitas por vez;
5. validar Livro de Receitas, caldeirão, quests e purificação a cada lote;
6. evitar quebrar `receitas_descobertas` já salvas.

Essa ordem reduz retrabalho e evita que uma mudança de ID quebre o save, o livro ou o fluxo do caldeirão.

## 9. Riscos técnicos

Principais riscos identificados:

- drift entre `Database.gd` e `Data/recipes`;
- Livro de Receitas mostrar algo diferente do caldeirão;
- quests pedirem IDs removidos;
- `PurificationObstacle` depender de item legado;
- `SaveManager` preservar `receitas_descobertas` antigas;
- backlog de textura aumentar conforme o catálogo se reorganiza.

## 10. Próximo passo sugerido

O próximo passo seguro não é implementar receitas novas direto.

O caminho recomendado é um destes dois:

- criar uma camada de alias/compatibilidade;
- ou alinhar `Database` e `RecipeDatabase` numa única fonte antes de adicionar receitas definitivas.

Essa etapa deve acontecer antes do P02C de implementação de receitas, para evitar migração prematura e quebra de catálogo.

## Resumo executivo

- O código ainda opera com catálogo legado/provisório.
- Os docs novos já definem o catálogo definitivo.
- A migração deve ser incremental, com compatibilidade temporária.
- O foco agora é planejar o mapa de transição, não implementar novas receitas.
