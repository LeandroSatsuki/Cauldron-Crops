# Evolução do Projeto

## Estado operacional — 2026-10-02

As fases numeradas abaixo registram o planejamento histórico; não representam uma fila ainda não implementada. O fechamento da V0 foi aprovado. A evolução pós-V0 já entregou exploração do Bosque, acesso a recursos da vila e Fases A–E da Mochila.

O fechamento integrado posterior corrigiu a persistência de colheitas recusadas e validou viagem → marco de expansão → HUD no retorno → depósito seletivo → save/load. Suíte de 34 testes aprovada; roteiro manual de capacidade, marcos e persistência do caldeirão permanece pendente em `PERSONAL_INVENTORY_ARCHITECTURE_PLAN.md`.

Aceites adicionais em 2026-10-03: expansão/navegação da Mochila, marcos/capacidade até 20, coleta repetida sem novo aumento, seleção na segunda página, transferências e save/reabertura aprovados; também produção em andamento/retomada/cancelamento do caldeirão, com consumo/resultado/restituição únicos no roteiro proposto. Próxima etapa de validação: casos-limite de capacidade cheia e captura/colheita recusada no plano da Mochila. Não forçar cenário com F10/edição do save nem iniciar novos sistemas. Aceite artístico permanece separado.

Primeiro pacote de polimento visual executado após autorização de continuidade: remoção dos blocos opacos dos lotes intocados, camadas estáveis terreno → solo → objetos, caldeirão verde limpo reaproveitado, grama suavizada, detalhes no baú e HUD/objetivos opacos. Renderização da Fazenda, solo arado e transferência conferida; aceite manual pendente. Decisão 96 delimita o incremento, sem mudança de save ou gameplay.

Segundo pacote visual implementado após autorização: fundo contínuo sem bordas cinzas, trilhas e vegetação baixa não interativas, golem de pedra/musgo, lago com margem e arco de entrada distinto das raízes corrompidas. Posicionamento funcional, sensores, navegação, cultivo e save não mudam. Inspeção OpenGL/D3D12 conferida; aceite visual/manual dos dois pacotes permanece pendente. Decisão 97 registra contratos e limites.

Após auditoria somente leitura e autorização de implementação, origem agrícola estabilizada em `FarmOrigin=(680,760)`. Lotes/pocket/piloto e pontos derivados não dependem mais do viewport; pedra de investigação fica fora do pocket. IDs/ordem/estados e contratos v4/v3 preservados; saves antigos assumem o layout canônico, pois não registravam a origem anterior. Objetos fixos, limites e gameplay mantidos. Suíte 35/35 e renderização OpenGL/D3D12 conferidas; save pessoal intacto. Decisão 98 e estado atual de `FARM_LAYOUT_PLAN.md` registram contratos e roteiro.

Autor aprovou em 2026-10-03 cultivo/save/load após redimensionar e fechar/reabrir em outro tamanho de janela, conforme roteiro de lote inicial. Também aprovou Bosque → resize → retorno, conferindo grade/culturas e acesso à pesca/baú/caldeirão, purificação → pedra → quatro lotes → Herbário, entrega física do golem com o personagem no caminho e criação/plantio/rega de um lote livre abaixo do lado direito da grade, sem sobreposição. Roteiros funcionais propostos deste layout concluídos; ajustar apenas problemas concretos de playtest futuro. A composição artística ainda não é final; os roteiros da Mochila/persistência do caldeirão permanecem pendentes e devem ser tratados separadamente. Conteúdo/economia/NPCs e rede de armazenamento precisam de escopo próprio; não iniciar automaticamente novos sistemas. Arquivos locais de arte permanecem preservados.

Checkpoint técnico seguinte: percurso purificação → pedra → quatro culturas → Herbário coberto no teste integrado, incluindo consumo/recompensa/marco únicos e JSON em cena recriada/resolução diferente. Nenhuma mudança de gameplay. Callbacks/sinais com navegação real não validam picking do mouse/hitboxes da UI; o próximo passo manual acima não foi substituído.

Auditoria seguinte reproduziu conflito de prioridade com enxada ativa: o fallback agrícola consumia cliques antes do picking dos objetos. Corrigido apenas esse despacho e ampliada a regressão para objetos/lotes e solo livre (Decisão 99). Autor validou em 2026-10-03 abrir baú/caldeirão com enxada ativa, fechar painéis e arar um lote inicial. Este roteiro específico está aprovado; demais validações manuais acima permanecem pendentes. Nenhum sistema novo autorizado por este checkpoint.

## Fase 0 - Estado atual

- O projeto já possui o loop principal validado em sua base atual.
- O golem automático foi desativado temporariamente para estabilizar testes manuais.
- A base de receitas entrou em transição para `RecipeResolver` sobre `RecipeDatabase` / `Data/recipes`, com fallback legado temporário.

## Fase 1.5 - Layout macro, helpers runtime-only e preparação da fazenda

### Objetivo

Organizar o mapa e os suportes de UI/ajuda sem criar um novo sistema de gameplay nem mexer em save/schema.

### Já concluído ou em estado estável

- Layout Pass V1 da fazenda com blockout visual leve, envelope macro fixo e leitura espacial melhor.
- Painéis arrastáveis em runtime-only, sem persistência de posição.
- Missão Inicial V0 runtime-only, separada do `QuestManager`.
- UI base do inventário e do caldeirão é feita com escopo mínimo, usando `anchors`, `size_flags_*` e `mouse_filter` corretamente, sem polimento visual antes do loop básico estar estável.
- Golem Irrigador como talento do golem físico existente, sem criar nova entidade.
- Transição inicial do catálogo de receitas com `RecipeResolver`, mantendo fallback legado temporário.
- Primeira leva definitiva de receitas resource-first implementada sem novos IDs de item:
  - `Infusão Purificadora`
  - `Saquinho de Semente Mista`

### Fechado na Fase 1.5

- Layout macro final documentado e aplicado em blockout runtime-only.
- Envelope do mapa fixado e validado com a área inicial centrada no caldeirão.
- Segunda área corrompida reservada visualmente.
- Leitura das zonas reservadas refinada sem transformar isso em novo gameplay.
- Fase 1 mantida intacta enquanto a fazenda ganha forma maior.

## Fase 2 - Fechamento técnico do grid

### Objetivo

Fechar o contrato técnico do grid sem substituir de vez o protótipo em `FarmPlot`.

### Entregas da Fase 2

- Consolidar a ponte runtime-only no `Main` espelhando os plots vivos em `FarmGridManager`, sem tirar `FarmPlot` da fonte de verdade.
- Fazer o golem físico ler o snapshot do grid como contrato real de seleção de alvo.
- Fazer o save/load consumir `farm_grid` como contrato real de persistência.
- Manter bloqueios e validações de interação em cima do snapshot do grid e do `FarmPlot` legado.
- Validar o fechamento com `git diff --check` e launch headless do Godot.

### Reservado para a próxima evolução

- Implementar solo livre / `FarmGrid` real.
- Permitir criação e remoção de lotes como autoridade de gameplay.
- Tornar a segunda área corrompida funcional.
- Avaliar a migração real para `FarmGrid`, se aprovada.
- Expandir o save além do mínimo atual apenas se o loop exigir.
- Revisar a UI do caldeirão.
- Revisar o inventário.
- Revisar a venda.
- Decidir se o golem físico continua ativo ou permanece desativado.
- Preparar a UI de status para leitura rápida do estado geral.

### Observação de escopo

A Fase 2 deve concentrar as mudanças sistêmicas de fato; a Fase 1.5 existe para preparar layout, leitura espacial e compatibilidade runtime-only sem reabrir o save.

### Estado atual do fechamento técnico

- O `FarmGridManager` já está ligado ao jogo principal como snapshot runtime-only do `Main`.
- O golem físico e o save passaram a ler esse snapshot como contrato real de gameplay/persistência.
- `FarmPlot` continua como fonte de verdade runtime enquanto a migração completa não acontece.
- Os itens de UI/inventário/venda permanecem como refinamento posterior e não bloqueiam o contrato técnico do grid.

## Fase 3 - Dados escaláveis

- Definir o formato final para crops, itens e receitas.
- Avaliar `Resource .tres`, JSON ou CSV.
- Criar um padrão de receitas mais amplo.
- Documentar a arquitetura de tempo real antes de conectar gameplay.
- Criar a base do `TimeManager` sem integrar ao gameplay ainda.
- Criar smoke tests manuais para validar a fundação do grid.
- Evoluir o grid já fechado na fase anterior para authority de gameplay somente quando a migração definitiva for aprovada.

## Fase 4 - Conteúdo

- Novas crops.
- Novas receitas.
- Missões.
- Progressão.
- Upgrades.
- Consolidar a transição de lotes fixos para grid/tile sem alterar o protótipo atual.

## Fase 5 - Polimento

- Arte final pixel art.
- Áudio.
- Animações.
- Balanceamento.
- UX.
- Refinar a UI de status e os indicadores provisórios.
- Integrar o tempo real apenas quando o protótipo estiver estável.
