# Primeira Região Externa — Plano de Vertical Slice

## Status

Fases A, B, C e D implementadas, automatizadas e aprovadas manualmente. As correções posteriores de continuidade também foram automatizadas e aprovadas manualmente.

Continua sem autorização para conteúdo final, lore definitiva, novos itens ou expansão do save.

### Entrega da Fase A

- `ForagingGroveRegion` é uma cena nova; o protótipo técnico foi preservado.
- A Fazenda/Vila conduz ao bosque e recebe o familiar por uma entrada correspondente no retorno.
- O shell artesanal possui entrada segura, clareira principal, ramo opcional, clareira inferior e marcos visuais.
- A navegação usa um polígono côncavo triangulado; mata fechada, limites e obstáculos centrais não aceitam movimento direto.
- A câmera respeita os limites de `2560 × 1440` e o retorno permanece disponível.
- Ainda não existem pontos de coleta, recursos, descoberta, lore ou persistência adicional nessa região.
- `ForagingGroveShellSmokeTest` valida identidade, entrada, limites, câmera, marcos, áreas caminháveis/bloqueadas e deslocamento.
- `RegionTravelSmokeTest` valida a viagem real entre Fazenda/Vila e bosque, o retorno e a preservação do estado runtime.

### Entrega da Fase B

- `ForageNode` concentra interação, aproximação, estado disponível/esgotado e feedback visual.
- Quatro pontos físicos oferecem `carvao x1`; é um recurso comum já catalogado com origem de coleta.
- A aquisição é determinística, sem RNG e sem criar item, receita ou regra econômica nova.
- O resultado entra em `GlobalInventory`, usado somente como bridge temporário da Mochila neste slice.
- `VillageChest` não é acessado: coleta externa não teleporta recursos para o armazenamento da vila.
- Cada ponto aceita apenas uma coleta e permanece esgotado enquanto a mesma instância do bosque existir.
- Não houve alteração de `SAVE_VERSION`; ao iniciar outra sessão, os pontos voltam ao estado inicial conforme o contrato temporário.
- `ForagingCollectionSmokeTest` valida aproximação física, ganho exato, rejeição de duplicação, feedback e reentrada na mesma instância.

### Entrega da Fase C

- A ramificação opcional abriga as Luzes do Bosque, uma curiosidade atmosférica sem recompensa material.
- O enxame mantém uma animação discreta e reage à proximidade do familiar com brilho e movimento mais vivos.
- Ao observar as luzes, o familiar se aproxima e recebe apenas uma mensagem local; não há item, receita, moeda, lore persistente ou bloqueio de progresso.
- A curiosidade pode ser revisitada livremente e não altera o save.
- `GroveFireflyCuriositySmokeTest` valida aproximação, reação ambiental, feedback e ausência de alteração na Mochila ou nas descobertas de lore.

## Estado de partida

- A Fazenda/Vila é a região HOME `farm_village`.
- A viagem entre cenas já possui entrada/saída nomeada, fade, bloqueio de input, retorno seguro e cache em memória.
- `PrototypeExternalRegion` valida somente a infraestrutura e não deve ser promovida diretamente a mapa final.
- O estado runtime da Fazenda é preservado durante a viagem, mas regiões externas e a posição do jogador ainda não são persistidas entre sessões.
- Enquanto a Fazenda fica em cache, o tempo decorrido na sessão é aplicado aos cultivos e ao caldeirão quando o jogador retorna; isso não constitui ainda uma simulação offline completa do golem ou da vila.
- `GlobalInventory.inventario` e `VillageChest.inventory` já são armazenamentos tecnicamente separados, embora o primeiro ainda misture responsabilidades de protótipo.

## Recomendação de tema

### Região Externa 01 — Bosque de Forrageamento

Nome apenas funcional; nome final e lore aguardam aprovação.

O bosque é a melhor primeira região porque:

- introduz exploração e coleta com baixo custo técnico e artístico;
- cria contraste claro com a Fazenda sem exigir combate, dungeon ou iluminação especial;
- combina com criaturas, pequenos eventos, segredos e recursos naturais já previstos;
- permite validar caminhos opcionais e landmarks em um mapa artesanal pequeno;
- pode continuar relevante com mudanças de estação, eventos e especialização no futuro.

### Alternativas consideradas

| Opção | Vantagem | Custo/risco | Decisão atual |
| --- | --- | --- | --- |
| Bosque de forrageamento | Melhor ponte entre exploração, recursos e mundo vivo | Precisa de regra de renovação dos pontos de coleta | Recomendada |
| Caverna/mina | Identidade forte e recursos claros | Exige iluminação, obstáculos e linguagem visual novas | Adiar |
| Zona úmida/lago expandido | Reaproveita pesca e recursos aquáticos | Sobrepõe o papel do lago atual e testa menos sistemas novos | Adiar |

## Fantasia funcional do slice

```text
sair da Fazenda/Vila
↓
seguir um caminho artesanal curto
↓
reconhecer landmarks e escolher um desvio opcional
↓
coletar poucos recursos físicos
↓
encontrar uma curiosidade opcional
↓
retornar à Fazenda/Vila com os itens na Mochila
```

Não entram neste slice:

- combate;
- NPC completo;
- quests encadeadas;
- dungeon procedural;
- loja ou moeda nova;
- mastery completa;
- simulação offline da região;
- rede de baús;
- lore central obrigatória.

## Escala e estrutura do mapa

- Mapa finito e artesanal de aproximadamente `2560 × 1440` pixels.
- Duração-alvo da primeira exploração: 5–8 minutos.
- Três espaços legíveis:
  1. entrada segura e retorno;
  2. clareira principal de coleta;
  3. desvio opcional com curiosidade ambiental.
- Um caminho principal sempre legível e um ramo opcional curto.
- Passagens úteis com pelo menos 96 pixels de largura.
- Sem labirinto; orientação deve vir de forma, cor e landmarks, não de placas extensas.
- A saída permanece acessível em todos os estados do mapa.

## Conteúdo mínimo

### Coleta

- Três a cinco pontos físicos de recurso comum.
- Pelo menos uma coleta determinística por visita/sessão; progresso não pode depender apenas de RNG.
- Um recurso incomum pode existir como bônus, descoberta ou atalho, nunca como bloqueio obrigatório exclusivo.
- Itens coletados entram primeiro na Mochila e nunca diretamente no `VillageChest`.

Os IDs dos recursos ainda não estão definidos. Antes de criar item novo, verificar se um item existente pode ganhar outra fonte sem desvalorizar sua função atual. Se um ID novo for necessário, ele deve nascer com uso claro e saída futura prevista — não apenas como loot decorativo.

### Descoberta

- Uma curiosidade atmosférica opcional, sem poder permanente necessário.
- A primeira versão não deve explicar a Guardiã, a corrupção ou o passado da vila.
- A descoberta pode ser apenas reação visual/sonora; recompensa material não é obrigatória.

### Mundo vivo

- Um comportamento ambiental pequeno e barato, como folhas, brilho, criatura distante ou objeto reagindo à aproximação.
- Nenhuma criatura funcional nova antes de a região provar navegação e coleta.

## Contrato temporário de inventário

Para este vertical slice:

- `GlobalInventory.inventario` pode representar temporariamente a Mochila para recursos coletados pelo familiar fora da vila;
- `VillageChest.inventory` continua representando o Village Storage;
- coleta externa não deposita automaticamente no Village Storage;
- caldeirão, purificação e projetos continuarem a ler `GlobalInventory` é dívida de transição já documentada, não arquitetura final;
- não implementar peso, capacidade, slots limitados ou categorias separadas nesta etapa.

Esse bridge permite validar exploração sem antecipar a reforma completa de inventário. O depósito Mochila → Village Storage e o consumo direto pelos sistemas da vila pertencem a um sprint próprio.

## Estado e salvamento do slice

Direção mínima recomendada:

- a região permanece em memória enquanto a sessão está aberta;
- pontos coletados continuam esgotados até encerrar a sessão;
- ao reiniciar o jogo, a região nasce novamente em seu estado inicial;
- itens já levados de volta e salvos na Fazenda permanecem no inventário;
- salvar e carregar continuam sendo ações da Fazenda/Vila durante este slice;
- não aumentar `SAVE_VERSION` apenas para persistir uma região ainda experimental.

Uma regra de renovação por dia/estação só deve ser criada quando o tempo real do jogo estiver conectado ao gameplay.

## Sequência mínima de implementação

### Fase A — shell jogável

- Criar nova cena para a região; não sobrescrever o protótipo técnico.
- Configurar `WorldRegion`, entradas, câmera, navegação e retorno.
- Construir apenas terreno, caminhos, limites e três landmarks em blockout coeso.
- Validar ida, exploração e retorno sem coleta.

Estado: implementada e aprovada.

### Fase B — coleta vertical

- Criar um `ForageNode` reutilizável com estado coletado/não coletado.
- Fazer o familiar aproximar-se antes da coleta.
- Depositar o resultado no bridge atual da Mochila.
- Exibir feedback curto no mundo, sem abrir painel modal.
- Manter coleta determinística e sem respawn arbitrário durante a sessão.

Estado: implementada e aprovada.

### Fase C — descoberta e vida

- Adicionar uma curiosidade opcional.
- Adicionar um único comportamento ambiental barato.
- Evitar recompensa obrigatória ou lore estrutural.

Estado: implementada e aprovada.

### Fase D — validação

- Smoke test de navegação e limites.
- Smoke test de coleta única e destino correto do item.
- Smoke test de ida/retorno e preservação da Fazenda.
- Teste manual de leitura espacial, orientação e sensação de duração.

Estado: validação automatizada e manual concluída; fase aprovada.

`ForagingGroveVerticalSliceSmokeTest` executa, numa mesma sessão, a saída da Fazenda/Vila, uma coleta física, a curiosidade opcional, o retorno pelo portal, a preservação da instância da Fazenda e a separação entre Mochila temporária e Village Storage.

O fechamento manual também confirmou a aproximação segura aos obstáculos interativos da Fazenda/Vila. `CoreWorldInteractionSmokeTest` protege baú, caldeirão, pesca e lote agrícola contra regressões de destino inalcançável ou interação executada dentro da colisão.

## Critérios de aceite

- O jogador entende visualmente como voltar sem texto longo.
- Não existem pontos alcançáveis que prendam o familiar.
- A câmera nunca revela vazio fora dos limites planejados.
- A região oferece uma escolha espacial simples, não apenas um corredor.
- A coleta ocorre no mundo após aproximação física.
- Recursos externos não aparecem diretamente no Village Storage.
- Nenhum conteúdo obrigatório depende exclusivamente de RNG.
- Retornar à Fazenda preserva integralmente seu estado runtime.
- A região pode receber eventos e novos pontos de interesse sem reescrever a transição.

## Decisões de aprovação antes da Fase A

Recomendação padrão:

1. aprovar o bosque de forrageamento como tema funcional;
2. manter nome e lore finais em aberto;
3. usar `GlobalInventory` como bridge temporário da Mochila;
4. manter save/load apenas na Fazenda durante o vertical slice;
5. criar uma cena nova e conservar `PrototypeExternalRegion` como teste técnico até a substituição ser validada.
