# FarmGrid Checkpoint

## Visao Geral

O FarmGrid V2 segue em laboratorio. O preview isolado validou o loop minimo em memoria, mas o jogo principal continua usando `FarmPlot` como sistema ativo de plantio e colheita.

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

## O que ainda e fake

- `crop_id = debug_crop`
- ferramentas nao vem de inventario real
- regador nao consome agua
- crescimento nao usa tempo real
- colheita nao gera item real
- save real nao guarda FarmGrid
- golem nao interage com FarmGrid
- caldeirao ainda nao cria essencias de solo
- nao existe renderizacao pixel art final
- nao existe pathfinding sobre grid

## Por que nao migrar ainda

O `FarmPlot` precisa continuar ativo porque:

- ja esta integrado ao plantio real
- ja salva e carrega
- ja conversa com golem
- ja conversa com Baú da Vila
- ja funciona no loop principal
- FarmGrid ainda e laboratorio

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
6. Criar save isolado do FarmGrid em teste.
7. So depois criar uma pequena area experimental no jogo principal.

## Pendencia tecnica: Autoloads em cenas dev

Durante os testes do FarmGridPreview aparecem logs como:

`Item adicionado ao inventario: agua`

Isso indica que algum Autoload ou sistema global roda mesmo em cenas dev isoladas.

Pendencia registrada:

- investigar a origem dos logs de agua
- evitar que cenas dev sejam poluidas por sistemas globais
- o `PocoManager` agora ignora `res://Scenes/dev/`, entao o ruido deve desaparecer nos previews
- manter a verificacao de outros possiveis logs globais, se aparecerem no futuro

## Decisao atual

- FarmGrid V2 aprovado como direcao futura
- preview validou o loop minimo
- FarmPlot continua como sistema ativo
- integracao real fica para etapas futuras
- nenhuma migracao agora

## Ferramenta Ativa V0

O jogo principal ganhou uma base de ferramenta ativa global com `ToolManager` como `Autoload`.

- primeira ferramenta real: Enxada
- selecao por botao e tecla `1`
- apenas estado visual/global por enquanto
- nao altera aragem, plantio ou colheita no gameplay
- FarmPlot continua ativo
- FarmGrid continua isolado
