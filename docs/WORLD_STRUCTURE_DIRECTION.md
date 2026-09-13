# Direção de Mundo — Fazenda/Vila e Regiões

## Decidido

- Cauldron Crops terá um mundo finito composto por mapas artesanais.
- A Fazenda/Vila é o mapa principal e o HOME emocional e produtivo do jogo.
- O mapa principal contém subáreas com identidades próprias; a corrupção bloqueia regiões macro e a purificação as torna navegáveis.
- Purificação abre o mundo; limpeza e restauração transformam seus elementos locais. Uma área purificada não deve se converter automaticamente em campo agrícola vazio.
- Regiões externas poderão existir como mapas próprios no futuro, sem fazer a Fazenda/Vila crescer infinitamente.
- Regiões recuperadas ampliam o repertório de eventos, recursos, criaturas, segredos e atividades, mantendo áreas antigas relevantes.

## Direção de protótipo, ainda sujeita a validação

- O papel narrativo definitivo do familiar e sua ligação exata com a antiga Guardiã.
- Identidade de região local e reutilizável para os mapas que realmente precisarem desse contexto.
- Simulação abstrata de mapas que não estejam carregados.

## Aplicação atual

- O `FarmBlockoutV0` e o marcador visível de agricultura livre eram guias de desenvolvimento e não fazem parte da apresentação ao jogador; ambos ficam desativados no runtime padrão.
- O lago, o caldeirão, o baú, os lotes, a primeira purificação e a Pedra das Marcas continuam sendo elementos reais do mapa atual.
- O jogador possui representação física por um familiar com click-to-move, aproximação contextual e desvio dos obstáculos centrais.
- A primeira área purificada também contém o Herbário das Marcas: uma ruína que pode ser restaurada com recursos já existentes, muda visualmente o local e revela uma Rama Encantada.
- O estado de restauração é salvo como dado opcional da expansão, preservando a compatibilidade do save v4.
- A Fazenda/Vila declara a identidade `farm_village`, o ponto de entrada `village_arrival` e um contrato local de pedido de transição.
- `RegionTravelCoordinator` executa a troca entre cenas e mantém as regiões visitadas em memória, sem salvar automaticamente nem alterar o schema de save.
- `PrototypeExternalRegion` é uma área estritamente técnica para validar ida, retorno, pontos de entrada e preservação da Fazenda; não define conteúdo ou lore de uma região final.
- A Fazenda sai da árvore enquanto outra região está ativa, portanto seus timers e sistemas locais não continuam processando em segundo plano.
- Ainda não há simulação abstrata de mapas descarregados, catálogo extensível de regiões ou persistência da localização do jogador entre sessões.
