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
- A troca possui fade curto, bloqueia o input até a nova região estabilizar, rejeita pedidos duplicados e restaura a origem quando o destino é inválido.
- `PrototypeExternalRegion` é uma área estritamente técnica para validar ida, retorno, pontos de entrada e preservação da Fazenda; não define conteúdo ou lore de uma região final.
- `ForagingGroveRegion` é o primeiro shell externo jogável: mapa artesanal finito, caminho principal, ramificação opcional, câmera limitada e retorno físico à Fazenda/Vila.
- O bosque ainda usa apresentação de blockout, mas já contém a coleta vertical mínima da Fase B: quatro pontos determinísticos de um recurso comum existente.
- A coleta externa entra no bridge temporário da Mochila, não no `VillageChest`; os pontos mantêm o estado apenas na instância da sessão e não alteram o schema de save.
- A ramificação opcional contém as Luzes do Bosque: curiosidade atmosférica repetível, sem recompensa e sem registro persistente, cujo enxame reage à proximidade do familiar.
- Lore definitiva e persistência própria continuam fora da região.
- A Fazenda sai da árvore enquanto outra região está ativa, portanto seus timers e sistemas locais não continuam processando em segundo plano.
- Ainda não há simulação abstrata de mapas descarregados, catálogo extensível de regiões ou persistência da localização do jogador entre sessões.

## Próximo vertical slice

- A proposta da primeira região com conteúdo está em `FIRST_EXTERNAL_REGION_VERTICAL_SLICE.md`.
- A recomendação é um pequeno bosque de forrageamento, ainda sem nome ou lore definitivos.
- O shell navegável da Fase A foi aprovado.
- A coleta vertical da Fase B foi aprovada.
- A curiosidade e a vida ambiental mínima da Fase C estão implementadas e aguardam validação manual; a próxima etapa é a validação integrada do vertical slice.
