# Direção de Mundo — Fazenda/Vila e Regiões

## Decidido

- Cauldron Crops terá um mundo finito composto por mapas artesanais.
- A Fazenda/Vila é o mapa principal e o HOME emocional e produtivo do jogo.
- O mapa principal contém subáreas com identidades próprias; a corrupção bloqueia regiões macro e a purificação as torna navegáveis.
- Purificação abre o mundo; limpeza e restauração transformam seus elementos locais. Uma área purificada não deve se converter automaticamente em campo agrícola vazio.
- Regiões externas poderão existir como mapas próprios no futuro, sem fazer a Fazenda/Vila crescer infinitamente.
- Regiões recuperadas ampliam o repertório de eventos, recursos, criaturas, segredos e atividades, mantendo áreas antigas relevantes.

## Direção de protótipo, ainda sujeita a validação

- Personagem físico do jogador, possivelmente um familiar ligado à antiga Guardiã.
- Click-to-move para exploração e interação.
- Identidade futura de região e subárea para sistemas que realmente precisarem desse contexto.
- Simulação abstrata de mapas que não estejam carregados.

## Aplicação atual

- O `FarmBlockoutV0` e o marcador visível de agricultura livre eram guias de desenvolvimento e não fazem parte da apresentação ao jogador; ambos ficam desativados no runtime padrão.
- O lago, o caldeirão, o baú, os lotes, a primeira purificação e a Pedra das Marcas continuam sendo elementos reais do mapa atual.
- A arquitetura atual permanece local à Fazenda/Vila. Não há implementação antecipada de sistema global de regiões, personagem ou navegação entre mapas.
