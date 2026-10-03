# Mapa Macro da Fazenda — Fase 1.5

## Estado operacional — 2026-10-02

As seções 1–8 abaixo são planejamento histórico de blockout, não instruções de implementação atual. O layout em execução usa coordenadas de mundo fixas; não recalcular pelo viewport nem reativar os guias macro. A estabilização técnica está na Decisão 98, sem declaração de composição artística final.

- `Main.tscn/FarmOrigin`: `Marker2D` em `(680,760)`, sem collider ou interação. Não mover objetos fixos para acompanhar a tela.
- Centro do lote: `origem + grid_position × 80`, convertido de local para global pelo `Main`. Inverso usa `to_local` e arredondamento. Manter IDs e ordem dos 34 plots para o fallback legado.
- Grade inicial 6×5: centros de `(680,760)` a `(1080,1080)`. Pocket 2×2: colunas 6–7, linhas 0–1, centros de `(1160,760)` a `(1240,840)`.
- Piloto livre: colunas 4–9, linhas 5–6, centros de `(1000,1160)` a `(1400,1240)`; limites lógicos e marcador oculto por padrão preservados.
- Pedra: `(1254,686)`, fora dos quatro lotes; Herbário: `(1380,926)`, ao lado. Visibilidade/requisitos continuam associados ao mesmo obstáculo `first_obstacle`.
- Baú `(286,716)`, caldeirão físico `(990,521)`, lago `(1288,172)`, chegada `(1180,700)`, entrada do Bosque `(1530,475)` e obstáculo `(1728,802)` permanecem. O lago atual não é bloqueado pelo pocket; aquela direção nas zonas históricas abaixo não descreve o runtime vigente.
- Save v4/v3 não registra origem histórica. Culturas/progresso/colheitas e coordenadas lógicas são preservados, mas ao abrir a versão nova passam a ocupar este layout canônico. Não apagar lotes ou alterar a ordem para resolver sobreposição.

### Validação manual — status em 2026-10-03

1. **Aprovado pelo autor:** arar/plantar/regar um lote inicial, salvar, redimensionar a janela e carregar; posição relativa, cultura e rega preservadas.
2. **Aprovado pelo autor:** fechar/reabrir em outro tamanho de janela e carregar novamente o mesmo save. Não implica teste adicional de saves legados: estes podem reposicionar a grade uma vez para o layout canônico.
3. **Aprovado pelo autor:** roteiro de purificação → pedra → arar/plantar/regar cada lote 2×2 → restaurar Herbário lateral, sem travamentos ou recompensa duplicada. **Pendente separadamente:** inspeção específica da área livre abaixo da grade, que não foi solicitada nesse roteiro.
4. **Aprovado pelo autor:** viajar ao Bosque, mudar o tamanho da janela e retornar; conferir grade/culturas, abrir baú/caldeirão e pescar. **Pendente separadamente:** observar a entrega física do golem, que não fez parte do roteiro aprovado.

Regressão de input corrigida na Decisão 99 e validada manualmente pelo autor em 2026-10-03: abriu baú/caldeirão com enxada selecionada, fechou os painéis e arou um lote da grade inicial com sucesso. Aceite restrito a esse roteiro; os status acima registram as validações adicionais. O teste técnico verifica que `_unhandled_input` não consome o evento antes do picking.

Teste técnico: `godot --headless --path . res://Scenes/dev/FarmWorldCoordinatesSmokeTest.tscn`. Para inspeção renderizada, executar sem `--headless` e acrescentar `-- --capture-stable-world`; a captura sintética mostra solo arado e fica em `user://farm_world_coordinates.png`, sem escrever `savegame.json`.

Percurso integrado: `godot --headless --path . res://Scenes/dev/CoreWorldInteractionSmokeTest.tscn` cobre purificação → pedra → cultivo dos quatro lotes → Herbário → JSON em cena recriada/resolução diferente, além das aproximações a baú/caldeirão/pesca e entrega do golem. Usa os manipuladores do jogo, sinais dos botões e navegação/física ativas, com recursos/velocidade sintéticos. Não cobre picking do mouse nem hitboxes da interface; não substitui as validações manuais com status acima.

---

**Objetivo:** documentar o layout macro da fazenda antes da implementação de solo livre, mantendo intactos o loop da Fase 1, os `FarmPlot` atuais e a base de salvamento, e já reservar um envelope fixo para a vila/área inicial. A Fase 2 técnica já fechou a ponte runtime-only; este documento continua servindo como base visual para a evolução seguinte.

**Escopo:** blockout visual leve e documentação de layout. Nada aqui altera gameplay, cena, `FarmPlot`, `SaveManager` ou o laboratório do `FarmGridPreview`.

---

## 1) Estado atual da fazenda

A fazenda do protótipo hoje está organizada em torno de um núcleo funcional pequeno e concentrado, mas o chão deve continuar plantável em qualquer ponto do mapa — não existe uma zona rígida de plantio.

- **Grade ativa de `FarmPlot`:** 6 x 5 plots, mantidos em ordem fixa.
- **Pocket 2x2 bloqueado/liberável:** já preparado como expansão V0 após purificação.
- **Lago / pesca:** ponto físico separado do miolo agrícola, já integrado ao cenário.
- **Área corrompida:** obstáculo/área bloqueada V0 já existente e ligada à purificação.
- **Caldeirão:** presente no núcleo inicial, com papel central no loop de progressão.
- **Baú:** ponto físico próximo ao núcleo, usado como destino de itens do golem.
- **Golem:** também concentrado no entorno imediato do núcleo.
- **Marco de chegada / abrigo da vila:** existe como referência cenográfica, mas não precisa ser uma casa do jogador; pode ser apenas um ponto de identidade visual do núcleo inicial.

## 1.1) Envelope macro sugerido

Para evitar retrabalho e permitir blockout, textura e leitura espacial enquanto o sistema evolui, o mapa pode nascer com um envelope fixo maior que o núcleo atual:

- **Sugestão base:** 3200 x 1800.
- **Sugestão conservadora:** 2400 x 1600.
- **Regra prática:** a área útil central fica claramente menor que o envelope, com bordas reservadas para expansão adicional.

Esse envelope não precisa virar um grid rígido agora; ele serve como moldura cenográfica e reserva espacial para fases seguintes.

## 2) Problema atual

O diagnóstico atual é que muitos sistemas importantes ficaram concentrados na mesma área inicial. Isso cria três riscos principais:

- sensação de mapa “amontoado”;
- dificuldade de leitura espacial;
- falta de espaço reservado para crescimento adicional.

Em termos de design, o protótipo já funciona, mas o mundo ainda não comunica bem uma fazenda grande e organizada por funções.

## 3) Decisão de fase

- **Fase 1:** manter os lotes fixos, o loop validado e a demo estável.
- **Fase 1.5:** documentar o layout macro e fazer apenas blockout visual leve da fazenda.
- **Fase 2:** implementar solo livre / `FarmGrid` real e expansão sistêmica maior.

A Fase 1.5 existe para evitar retrabalho de mapa e para separar visualmente zonas que hoje estão próximas demais.

## 4) Zonas macro recomendadas

A fazenda final do protótipo é pensada como um conjunto de zonas com função clara, mas com cultivo livre em qualquer solo utilizável:

- **Área inicial**
  - caldeirão no centro visual;
  - pequena praça aberta ao redor;
  - baú/logística em um lado;
  - marco de chegada/abrigo da vila no outro;
  - ponto de leitura do estado geral;
  - acesso simples ao loop principal.

- **Área de cultivo**
  - bloco principal de produção;
  - todo o terreno continua plantável, sem uma zona rígida separada;
  - margem para expansão visual sem colar tudo no centro.

- **Área corrompida 1**
  - primeira área bloqueada/purificável;
  - já é lida como destino separado do núcleo inicial;
  - o lago fica bloqueado dentro dela.

- **Área corrompida 2 reservada**
  - reservada no layout, mas sem gameplay agora;
  - só entra quando houver decisão clara de expansão.

- **Área de criaturas / animais mágicos**
  - zona mais orgânica e separada do cultivo;
  - ideal para conteúdo sistêmico adicional.

- **Área de golems / ajudantes**
  - próxima do baú ou da logística da fazenda;
  - pensada para reduzir deslocamento e reforçar automação.

- **Área de pesca / lago**
  - o lago em si fica travado dentro da corrupção 1;
  - a leitura visual dele deve permanecer periférica e separada do núcleo agrícola.

- **Área de recursos / forrageamento**
  - espaço de coleta, materiais e progressão lateral;
  - pode funcionar como zona de transição entre áreas principais.

- **Área de ruína / mistério reservada**
  - opcional, se houver necessidade narrativa;
  - deve permanecer apenas como reserva de layout por enquanto.

## 5) Regras técnicas

- Não alterar a ordem dos `FarmPlot` existentes.
- Novos `FarmPlot` reais só entram depois de uma decisão explícita sobre o save.
- Áreas reservadas podem existir como blockout visual, mas sem gameplay.
- Qualquer área bloqueada visual **não deve** entrar no grupo `lotes_terra`.
- `FarmGridPreview` continua sendo um laboratório isolado.
- O mapa macro continua separado do gameplay principal; a leitura real de `FarmGridManager` acontece no `Main` como snapshot runtime-only, não no mapa macro.

## 6) Fase 1.5

A Fase 1.5 é pequena e segura:

1. **Documentar o layout**
   - registrar as zonas macro, o envelope fixo do mapa e os limites do núcleo atual.

2. **Criar blockout visual leve**
   - desenhar reservas de espaço, sem criar gameplay novo.
   - priorizar a área inicial centrada no caldeirão.

3. **Reservar espaço para a segunda área corrompida**
   - apenas como intenção espacial, sem funcionalidade.

4. **Criar missão inicial / objetivos mínimos**
   - só se isso ajudar a guiar a leitura do mapa e da progressão.

5. **Manter a Fase 1 intacta**
   - sem mexer em `FarmPlot`, `SaveManager`, cenas ou fluxo validado.

## 7) O que fica para a próxima evolução

A próxima evolução deve concentrar as mudanças sistêmicas de fato:

- solo livre;
- grid real;
- criação/remoção de lotes;
- segunda área corrompida funcional;
- expansão maior do save;
- migração real para `FarmGrid`, se aprovada.

Esses itens permanecem reservados porque a fase técnica atual já fechou com snapshot runtime-only no `Main`, golem lendo o grid e save/load persistindo `farm_grid`.

## 8) Observações finais

Este documento existe para organizar a escala da fazenda antes do salto para um sistema mais livre. A prioridade é evitar que o crescimento adicional empurre tudo para a mesma região inicial e comprometa leitura, ritmo e expansão.

O resultado esperado da Fase 1.5 não é mais gameplay: é um mapa melhor estruturado, com espaço reservado para as fases seguintes.
