# FarmGrid Checkpoint

## Visao Geral

O FarmGrid V2 fechou a ponte técnica como contrato runtime-only. O preview isolado validou o loop minimo em memoria, o jogo principal espelha os `FarmPlot` vivos em `FarmGridManager`, o golem fisico le esse snapshot e o save ja persiste `farm_grid`; `FarmPlot` segue como sistema ativo de plantio e colheita.

## Sistemas ja criados

- `FarmTileData`
- `FarmGridManager`
- `FarmGridManagerSmokeTest`
- `FarmGridPreview`

## Loop validado no preview

O preview validou:

1. Selecionar Enxada.
2. Arar tile de grama.
3. Selecionar Semente.
4. Plantar em terra arada ou molhada.
5. Selecionar Regador.
6. Molhar terra arada e plantacao fake.
7. Simular crescimento com tecla G.
8. Colher crop madura com ferramenta Colheita.
9. Retornar tile colhido para ARADO.
10. Simular Decay Diario com tecla D.
11. Limpar terra arada ou molhada sem crop.
12. Preservar tile plantado durante o decay.
13. Alternar tipos de Solo Vivo Alquimico com botao direito.
14. Remover tile do grid com clique do meio.

## Ferramentas fake testadas

- Enxada
- Semente
- Regador
- Colheita

As quatro ferramentas continuam fake e isoladas. Elas nao usam inventario real nem sistemas reais de itens.

## Solo Vivo Alquimico

Tipos testados:

- Comum
- Encantado
- Sombrio
- Gelado
- Flamejante
- Lunar
- Instavel

No preview, os tipos aparecem como borda visual. Eles ainda nao afetam crescimento, drops, receitas ou estacao.

## Decay Diario

Regra validada:

- Terra arada ou molhada sem crop volta para grama.
- Tile plantado nao volta para grama.
- Plantacao pode perder agua na virada simulada.
- O tipo de solo alquimico e preservado.

Isso valida a Ideia 01 do Farm System V2: Ciclo de Limpeza Natural da Terra.

## O que ainda e laboratorial

- `crop_id = debug_crop`
- ferramentas nao vem de inventario real
- regador nao consome agua
- crescimento nao usa tempo real
- colheita nao gera item real
- caldeirao ainda nao cria essencias de solo
- nao existe renderizacao pixel art final
- nao existe pathfinding sobre grid
- a migracao para `FarmGrid` como autoridade total de gameplay ainda nao foi aprovada

## Por que a migracao total ainda nao foi aprovada

O `FarmPlot` precisa continuar ativo porque:

- ja esta integrado ao plantio real
- ja salva e carrega
- ja conversa com golem
- ja conversa com Baú da Vila
- ja funciona no loop principal
- a autoridade total do `FarmGrid` ainda nao foi validada como substituta do prototipo

## Riscos da migracao

- quebrar save dos lotes
- quebrar golem
- quebrar plantio atual
- duplicar sistemas de fazenda
- misturar preview com gameplay
- perder estabilidade do prototipo
- precisar refatorar UI, inventario, pathfinding e save ao mesmo tempo

## Proximos passos seguros

1. Registrar o checkpoint.
2. Investigar ruido dos Autoloads nas cenas dev.
3. Melhorar o visual do preview sem tocar no gameplay.
4. Criar ferramenta real de selecao no jogo principal apenas depois.
5. Planejar adaptador entre `FarmPlot` e `FarmTile`.
6. Validar o save/load do FarmGrid já integrado ao contrato runtime-only.
7. Só depois avaliar a migração total do gameplay para o grid.

## Pendencia tecnica: Autoloads em cenas dev

Durante os testes do FarmGridPreview aparecem logs como:

`Item adicionado ao inventario: agua`

Isso indica que algum Autoload ou sistema global roda mesmo em cenas dev isoladas.

Pendencia registrada:

- investigar a origem dos logs de agua
- evitar que cenas dev sejam poluidas por sistemas globais
- o `PocoManager` agora ignora `res://Scenes/dev/`, entao o ruido deve desaparecer nos previews
- manter a verificacao de outros possiveis logs globais, se aparecerem mais adiante

## Decisao atual

- FarmGrid V2 fechou a ponte técnica como contrato runtime-only
- preview validou o loop minimo
- FarmPlot continua como sistema ativo
- a migração total do gameplay ainda nao foi aprovada
- nenhuma substituicao completa do prototipo agora

## Validacao do save v4

- `farm_grid` preserva o snapshot dos lotes vivos sem remover o fallback legado de `farm_plots`.
- Lotes dinamicos arados ou plantados sao recriados ao carregar quando ainda nao existem na cena.
- Um `farm_grid` vazio usa o fallback legado em vez de impedir a restauracao dos lotes.
- O estado `expansion_blocked` e aplicado mesmo quando o lote restaurado esta vazio.
- F5/F9 foi validado manualmente com lote dinamico e carregamento concluido com sucesso.
- O launch headless do Godot 4.6.2 encerrou sem erros.

## Ferramenta Ativa V0

O jogo principal ganhou uma base de ferramenta ativa global com `ToolManager` como `Autoload`.

- ferramentas visuais globais: Enxada, Regador e Colheita
- selecao por botoes e teclas `1`, `2`, `3`
- apenas estado visual/global por enquanto
- nao altera aragem, plantio ou colheita no gameplay
- FarmPlot continua ativo
- FarmGrid continua isolado
- sementes continuam como itens do inventario no jogo principal
- Semente permanece apenas no `FarmGridPreview` como ferramenta fake de teste
