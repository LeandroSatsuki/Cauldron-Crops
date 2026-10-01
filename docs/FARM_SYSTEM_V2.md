# Farm System V2

## Visão Geral

O sistema atual de lotes fixos é funcional para o protótipo e continua sendo a base jogável enquanto a fazenda evolui.  
A direção final, porém, é sair de um conjunto fechado de pontos de plantio e caminhar para uma fazenda mais livre, construída sobre tiles/grid.

Essa evolução não é só visual. A intenção é que a fazenda passe a ser um espaço vivo, transformado pela alquimia, pelo clima e pelos sistemas que orbitam o caldeirão.

Nesta documentação, as seções de design descrevem o alvo do sistema; as seções de FarmTile, FarmGridManager, preview e checkpoint registram o estado atual já validado do laboratório.

### Estado atual da Fase 2 técnica

- O `Main` espelha os `FarmPlot` vivos em `FarmGridManager` como snapshot runtime-only.
- O golem físico lê esse snapshot para escolher alvos reais.
- O `SaveManager` já persiste e restaura `farm_grid`.
- `FarmPlot` segue como fonte de verdade runtime enquanto a migração definitiva não é aprovada.

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
- receitas.

## Limites Suaves

O jogo deve evitar limites duros demais.

O que evitar agora:

- stamina muito curta;
- limite diário rígido de arar;
- punição agressiva por ausência;
- destruir crops demais em tempo real.

O que priorizar:

- qualidade do solo;
- estabilidade mágica;
- alcance do poço;
- capacidade dos golems;
- necessidade de essências alquímicas;
- biomas;
- estação;
- manutenção suave.

## Integração com o Caldeirão

O caldeirão continua sendo o centro da transformação.

Na visão final, ele cria essências e modificadores de solo, como:

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

Na visão final, golems podem trabalhar por área ou função.

Papéis previstos:

- Golem Coletor
- Golem Regador
- Golem de Solo
- Golem Pescador
- Golem Pastor
- Golem Guardião

Esses papéis evoluem com a árvore de alquimia.

## FarmTile

Estrutura atual para representar cada tile da fazenda:

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
- recurso isolado para representar um tile do grid
- já é usado como contrato de leitura no gameplay e na persistência, mas ainda não substitui `FarmPlot` como autoridade total
- já serve como fundação para o grid e para o save

## FarmGridManager

Gerenciador isolado para controlar a fazenda baseada em grid:

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
- já serve como contrato de leitura para um consumidor real do gameplay (o golem) e para a persistência do save; o `Main` ainda o mantém como snapshot runtime-only espelhado dos plots vivos
- preparado para conversar com `FarmTileData` e já expõe criação, consulta, substituição, remoção e save/load em memória

Teste manual isolado:

- `Scripts/dev/FarmGridManagerSmokeTest.gd`
- valida criação, consulta, remoção, recriação e save/load em memória
- não é gameplay
- não roda automaticamente

Ferramenta temporária no Debug Panel:

- botão `Testar FarmGrid`
- roda o smoke test em memória quando acionado
- serve apenas para desenvolvimento e validação manual
- não altera o `FarmPlot` atual nem o gameplay

Ferramenta Ativa V0 no jogo principal:

- `Scripts/ToolManager.gd`
- registrado como `Autoload`
- ferramentas visuais globais: `Enxada`, `Regador`, `Colheita`, `Vara de Pesca`
- seleção visual/global por botões e teclas `1`, `2`, `3`, `4`
- ainda não altera gameplay
- `FarmPlot` continua ativo
- `FarmGrid` continua isolado
- sementes continuam como itens do inventário e do plantio atual
- `Semente` continua apenas no `FarmGridPreview` como ferramenta fake de teste

Preview visual isolado:

- `Scenes/dev/FarmGridPreview.tscn`
- `Scripts/dev/FarmGridPreview.gd`
- mostra um grid 5x5 desenhado em memória
- testa ferramenta ativa simples, com `Enxada`, `Semente`, `Regador` e `Colheita` fake
- permite alternar estados de tile manualmente
- permite alternar tipos de solo alquimico com clique direito
- permite remover tile do grid com clique do meio
- permite simular crescimento fake em tiles plantados e irrigados com a tecla `G`
- simula o Decay Diario em memoria para limpar tiles arados ou molhados sem crop
- tiles plantados com crop fake nao voltam para grama no decay diario
- tiles plantados podem perder agua no decay diario sem deixar de estar plantados
- permite colher crop fake madura e devolver o tile para `ARADO`
- o crescimento fake usa `remaining_growth_time` e avanca apenas quando o tile esta molhado
- não substitui `FarmPlot`
- não salva no `SaveManager`
- não entra no gameplay principal

Enxada V0 no FarmPlot atual:

- a Enxada ganhou uma primeira ação real nos lotes atuais do jogo principal
- lote vazio pode ser preparado/arado com a ferramenta ativa
- o estado de preparo é salvo como `arado: bool` no `FarmPlot`
- sementes só plantam em lote arado, evitando plantio acidental em terra nao preparada
- isso ainda nao cria aragem livre e nao substitui o `FarmPlot`
- o `FarmGrid` continua isolado e o preview continua sendo o laboratorio visual dessa transicao

Area Preparavel V0:

- a cena principal continua usando `FarmPlot`, mas agora com area ampliada por lotes potenciais preinstanciados
- os 16 lotes originais foram preservados primeiro, na mesma ordem e posicao
- novos lotes foram adicionados no final da ordem, sem instanciacao livre por clique
- todos os lotes novos continuam iniciando com `arado = false`
- o save continua por indice e permanece compativel com saves antigos
- o visual de lote nao arado agora usa uma aparencia provisoria mais natural/esverdeada
- terra arada seca e molhada continuam usando as texturas adubadas ja existentes
- o visual continua provisório e sem novos assets

Decay Diario V0 no FarmPlot atual:

- o jogo principal agora pode simular manualmente a virada do dia via Debug Panel
- lotes vazios e arados voltam ao estado natural quando não há semente plantada
- lotes plantados ou prontos para colher nao sao afetados por esse decay manual
- ainda nao existe tempo real conectado a essa regra; a virada automatica segue sem integração temporal real

## Farm Expansion System - Purificacao da Fazenda (alvo de design):

- a fazenda final é fixa, média/grande e dividida em áreas reservadas
- a expansao nao sera infinita, procedural ou livre no escopo atual
- a progressao abre areas bloqueadas ou corrompidas por meio de alquimia
- o Obstáculo Mágico V0 já introduz uma Área Bloqueada V0 visível com pocket 2x2 de `FarmPlot` append-only
- cada area purificada pode liberar novos lotes, plantas, pesca, criaturas, ruinas ou receitas
- o caldeirao passa a ser o centro da purificacao narrativa e mecanica
- pesca e Catálogo de Itens ja preparam esse eixo com recursos e metadados para desbloqueios
- a implementação completa fica para depois; o Obstáculo Mágico V0 já existe como primeiro teste prático
- ele usa `pocao_purificadora_fraca` e save mínimo de purificação

Colheita V0 por ferramenta no FarmPlot atual:

- a ferramenta `Colheita` do jogo principal agora reaproveita a colheita manual do `FarmPlot`
- o helper compartilhado continua gerando recompensas, bonus e drops raros pelo caminho atual
- o golem permanece usando `harvest_by_golem()` sem alterações nesta etapa
- sementes continuam como itens do inventario e o FarmGrid continua isolado

Checkpoint - Loop de Ferramentas V0:

- `ToolManager` é o controle global de ferramenta ativa do jogo principal
- Enxada prepara lote vazio, Regador rega lote e Colheita colhe lote pronto
- sementes continuam como item do inventário no jogo principal
- água aparece no StatusPanel e continua armazenada em `GlobalInventory.inventario["agua"]`
- a prioridade de clique favorece a ferramenta ativa antes da semente selecionada
- o Decay Diário ainda é manual/debug e só limpa lotes vazios e arados sem semente
- `FarmPlot` continua ativo, `FarmGrid` continua isolado e a Área Preparável V0 continua baseada em lotes pré-instanciados

Feedback visual das ferramentas:

- o `FarmPlot` reaproveita o texto flutuante existente da UI para mostrar respostas de Enxada, Regador, Colheita e avisos principais
- a mudança é só de comunicação visual; as regras de plantio, rega, colheita e save continuam as mesmas
- o console ainda pode receber prints diagnósticos quando fizer sentido, mas o jogador também vê o retorno na tela

Limpeza de logs repetitivos:

- a agua continua no inventario real, mas seus logs foram filtrados para reduzir ruído de debug
- o feedback visual passou a ser o canal principal para ações normais de lote, deixando o console mais útil para diagnostico real

Checkpoint de arquitetura:

- o preview ja validou o loop minimo do FarmGrid em memoria
- as ferramentas continuam fake e isoladas
- o `FarmPlot` continua sendo o sistema ativo do prototipo
- o `Main` mantém um snapshot runtime-only de `FarmGridManager` espelhado dos plots vivos, sincronizado por sinal de mudança de estado
- o golem ja pode consultar o snapshot para escolher alvos de colheita, mas a execução ainda acontece nos `FarmPlot` vivos
- o `Main` também consulta o snapshot para bloquear interação em tiles marcados como bloqueados
- a migracao real nao substituiu o `FarmPlot` ainda
- a pendencia de logs globais em cenas dev continua registrada como item tecnico em aberto


## Migração dos Lotes Atuais

O sistema atual de `FarmPlot` continua ativo por enquanto.

Roteiro sugerido:

### Fase 1
- Documentar o Farm System V2.

### Fase 2
- Ponte runtime-only fechada no `Main`.
- `FarmTileData` e `FarmGridManager` já servem como contrato de leitura/persistência para o golem e para o save.
- `FarmPlot` continua como sistema ativo do protótipo enquanto a migração definitiva não é aprovada.

### Fase 3
- Usar o preview dev e o smoke test para validar remoção, recriação, save/load e comportamento visual.

### Fase 4
- Criar uma área pequena de teste separada no jogo principal apenas quando o contrato do grid estiver estável.
- Criar smoke tests manuais adicionais para validar a fundação antes da integração.

### Fase 5
- Migrar parte da fazenda.

### Fase 6
- Substituir `FarmPlot` apenas quando o grid estiver estável.

## Mecânica Central Única

Cauldron Crops não é apenas um jogo de fazenda com caldeirão.

Ele é um jogo em que o jogador cultiva, transforma e administra ecossistemas alquímicos.

Loop alvo:

pesca -> caldeirão -> solo -> crops -> fazendinhas -> receitas -> golems -> expansão

## Fishing System - Pesca de Ressonancia (alvo de design)

O Fishing System é o caminho alvo para a pesca no jogo principal.

- o Lago da Fazenda V0 já existe como ponto físico/clicável no mapa principal
- a `Vara de Pesca` já existe como ferramenta visual/global na toolbar principal
- a pesca vai acontecer no lago real da fazenda
- o jogador poderá lançar a vara em qualquer área válida do lago
- áreas com ondulação, brilho ou movimento aumentam a chance de recompensas melhores
- essas áreas especiais são opcionais, não obrigatórias
- a primeira implementação alvo é pequena, calma e integrada ao lago da fazenda
- a Boia V0 já é o primeiro estado visual da pescaria no lago, sem minigame ou recompensa ainda
- a Puxada Fake V0 representa o estado visual anterior à sincronia real
- o popup de sincronia V0 já existe como primeiro passo interativo da Pesca de Ressonancia, com barra, marcador, Espaço e clique em qualquer área
- o feedback da sincronia V0 ainda é fake e nao gera recompensa real

### Pesca de Ressonancia

A mecânica alvo é uma sincronia leve e aconchegante:

- a água pulsa
- a boia reage
- o jogador clica no momento certo
- melhores acertos aumentam a qualidade da recompensa

### Recompensas previstas

Possíveis recompensas iniciais previstas:

- `peixe_comum`
- `peixe_luminoso`
- `escama_brilhante`
- `gota_lunar`
- `lodo_de_lago`
- `peixe_sazonal`
- `ingrediente_aquatico_raro`

### Relação com o resto do jogo

- a pesca alimenta caldeirão, receitas, missões e árvore de alquimia dentro da cadeia principal
- a pesca não começa como laboratório isolado no design final
- a primeira implementação de código é pequena e controlada
- a pesca já possui um popup simples de sincronia, mas ainda não tem recompensa real ou integração profunda com sistemas de progressão
- enquanto a sincronia está aberta, o lago bloqueia novo lançamento até o jogador encerrar a pesca atual

## Decisão Atual

- A ideia está aprovada como direção de design.
- Nenhuma integração ao jogo principal agora.
- O sistema atual de lotes continua ativo.
- O Farm System V2 segue em consolidação no laboratório antes de qualquer migração para o jogo principal.
