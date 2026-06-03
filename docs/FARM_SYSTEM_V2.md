# Farm System V2

## Visão Geral

O sistema atual de lotes fixos é funcional para o protótipo e continua sendo a base jogável enquanto a fazenda evolui.  
O plano final, porém, é sair de um conjunto fechado de pontos de plantio e caminhar para uma fazenda mais livre, construída sobre tiles/grid.

Essa evolução não é só visual. A intenção é que a fazenda passe a ser um espaço vivo, transformado pela alquimia, pelo clima e pelos sistemas que orbitam o caldeirão.

## Objetivo de Design

O jogador deve poder escolher onde arar, organizar sua própria fazenda e moldar o terreno aos poucos.

O foco não é apenas plantar crops.  
O foco é transformar o solo com alquimia, fazendo a fazenda reagir a escolhas, estações, receitas e ferramentas.

## Solo Vivo Alquímico

O centro da ideia é o conceito de Solo Vivo Alquímico.

O solo pode existir em estados e tipos especiais, como:

- Solo Comum
- Solo Encantado
- Solo Sombrio
- Solo Gelado
- Solo Flamejante
- Solo Lunar
- Solo Instável

Cada tipo de solo pode afetar:

- velocidade de crescimento;
- chance de mutação;
- crops permitidas;
- chance de drops raros;
- consumo de água;
- interação com estação;
- interação com golems;
- receitas futuras.

## Limites Suaves

O jogo deve evitar limites duros demais.

O que deve ser evitado:

- stamina muito curta;
- limite diário rígido de arar;
- punição agressiva por ausência;
- destruir crops demais em tempo real.

O que deve ser preferido:

- qualidade do solo;
- estabilidade mágica;
- alcance do poço;
- capacidade dos golems;
- necessidade de essências alquímicas;
- biomas;
- estação;
- manutenção suave.

## Integração com o Caldeirão

O caldeirão deve continuar sendo o centro da transformação.

No futuro, ele deve criar essências e modificadores de solo, como:

- Essência Gelada
- Essência Flamejante
- Pó Lunar
- Fertilizante Sombrio
- Catalisador de Mutação
- Conservante Alquímico

Esses itens podem transformar tiles da fazenda e abrir espaço para novas rotas de progressão.

## Integração com Pesca

A pesca não deve ficar isolada.

Peixes e itens aquáticos podem alimentar outros sistemas, gerando ingredientes para:

- poções;
- iscas;
- fertilizantes;
- essências de solo;
- receitas sazonais;
- alimentos de animais e fazendinhas.

## Integração com Fazendinhas e Animais

Fazendinhas e animais também devem participar do ciclo principal.

Exemplos:

- crops alimentam animais;
- animais produzem ingredientes;
- ingredientes voltam para o caldeirão;
- o caldeirão cria melhorias de solo;
- o solo melhor gera crops especiais.

## Integração com Golems

Golems futuros devem trabalhar por área ou função.

Ideias futuras:

- Golem Coletor
- Golem Regador
- Golem de Solo
- Golem Pescador
- Golem Pastor
- Golem Guardião

Esses papéis podem evoluir com a árvore de alquimia.

## FarmTile

Estrutura futura conceitual para representar cada tile da fazenda:

- posição no grid;
- estado do tile;
- tipo de solo;
- crop atual;
- umidade;
- estabilidade mágica;
- modificadores ativos;
- estação favorecida;
- ocupante ou estrutura;
- tempo restante;
- dados de save.

Base técnica inicial:

- `Scripts/data/FarmTileData.gd`
- recurso isolado para representar um tile futuro
- ainda não usado no gameplay atual
- serve como fundação para o grid e para o save futuro

## FarmGridManager

Gerenciador futuro para controlar a fazenda baseada em grid:

- controlar tiles;
- permitir arar;
- permitir plantar;
- aplicar essências;
- salvar e carregar o grid;
- informar golems;
- validar áreas bloqueadas;
- lidar com expansão da fazenda.

Base técnica inicial:

- `Scripts/data/FarmGridManager.gd`
- gerenciador isolado de dados
- não usado no gameplay atual
- preparado para conversar com `FarmTileData` no futuro

Teste manual isolado:

- `Scripts/dev/FarmGridManagerSmokeTest.gd`
- valida criação, consulta, save/load em memória
- não é gameplay
- não roda automaticamente

Ferramenta temporária no Debug Panel:

- botão `Testar FarmGrid`
- roda o smoke test em memória quando acionado
- serve apenas para desenvolvimento e validação manual
- não altera o `FarmPlot` atual nem o gameplay

Preview visual isolado:

- `Scenes/dev/FarmGridPreview.tscn`
- `Scripts/dev/FarmGridPreview.gd`
- mostra um grid 5x5 desenhado em memória
- testa ferramenta ativa simples, com `Enxada`, `Semente`, `Regador` e `Colheita` fake
- permite alternar estados de tile manualmente
- permite alternar tipos de solo alquimico com clique direito
- permite simular crescimento fake em tiles plantados e irrigados com a tecla `G`
- simula o Decay Diario em memoria para limpar tiles arados ou molhados sem crop
- tiles plantados com crop fake nao voltam para grama no decay diario
- tiles plantados podem perder agua no decay diario sem deixar de estar plantados
- permite colher crop fake madura e devolver o tile para `ARADO`
- o crescimento fake usa `remaining_growth_time` e avanca apenas quando o tile esta molhado
- não substitui `FarmPlot`
- não salva no `SaveManager`
- não entra no gameplay principal

Checkpoint de arquitetura:

- o preview ja validou o loop minimo do FarmGrid em memoria
- as ferramentas continuam fake e isoladas
- o `FarmPlot` continua sendo o sistema ativo do prototipo
- a migracao real fica para fases futuras e seguras
- a pendencia de logs globais em cenas dev continua registrada como item tecnico em aberto

## Migração dos Lotes Atuais

O sistema atual de `FarmPlot` deve continuar por enquanto.

Plano sugerido:

### Fase 1
- Documentar o Farm System V2.

### Fase 2
- Criar `FarmTile` como estrutura isolada, sem usar no jogo.

### Fase 3
- Criar `FarmGridManager` isolado.

### Fase 4
- Criar uma área pequena de teste separada.
- Criar smoke tests manuais para validar a fundação antes da integração.

### Fase 5
- Migrar parte da fazenda.

### Fase 6
- Substituir `FarmPlot` apenas quando o grid estiver estável.

## Mecânica Central Única

Cauldron Crops não deve ser apenas um jogo de fazenda com caldeirão.

Ele deve ser um jogo em que o jogador cultiva, transforma e administra ecossistemas alquímicos.

Loop futuro:

pesca -> caldeirão -> solo -> crops -> fazendinhas -> receitas -> golems -> expansão

## Decisão Atual

- A ideia está aprovada como direção futura.
- Nenhuma implementação agora.
- O sistema atual de lotes continua.
- O Farm System V2 será planejado antes de codificar.
