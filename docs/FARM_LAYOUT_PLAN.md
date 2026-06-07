# Plano Macro da Fazenda - Fase 1.5

**Objetivo:** documentar o layout macro da fazenda antes da implementação de solo livre, mantendo intactos o loop da Fase 1, os `FarmPlot` atuais e a base de salvamento.

**Escopo:** planejamento e blockout visual leve. Nada aqui altera gameplay, cena, `FarmPlot`, `SaveManager` ou o laboratório do `FarmGridPreview`.

---

## 1) Estado atual da fazenda

A fazenda do protótipo hoje está organizada em torno de um núcleo funcional pequeno e concentrado:

- **Grade ativa de `FarmPlot`:** 6 x 5 plots, mantidos em ordem fixa.
- **Pocket 2x2 bloqueado/liberável:** já preparado como expansão V0 após purificação.
- **Lago / pesca:** ponto físico separado do miolo agrícola, já integrado ao cenário.
- **Área corrompida:** obstáculo/área bloqueada V0 já existente e ligada à purificação.
- **Caldeirão:** presente no núcleo inicial, com papel central no loop de progressão.
- **Baú:** ponto físico próximo ao núcleo, usado como destino de itens do golem.
- **Golem:** também concentrado no entorno imediato do núcleo.
- **Casa / spawn explícito:** não há uma casa/spawn explícita confirmada na cena analisada; esse ponto ainda precisa ser definido como parte do layout macro.

## 2) Problema atual

O diagnóstico atual é que muitos sistemas importantes ficaram concentrados na mesma área inicial. Isso cria três riscos principais:

- sensação de mapa “amontoado”;
- dificuldade de leitura espacial;
- falta de espaço reservado para crescimento futuro.

Em termos de design, o protótipo já funciona, mas o mundo ainda não comunica bem uma fazenda grande e organizada por funções.

## 3) Decisão de fase

- **Fase 1:** manter os lotes fixos, o loop validado e a demo estável.
- **Fase 1.5:** planejar o layout macro e fazer apenas blockout visual leve da fazenda.
- **Fase 2:** implementar solo livre / `FarmGrid` real e expansão sistêmica maior.

A Fase 1.5 existe para evitar retrabalho de mapa e para separar visualmente zonas que hoje estão próximas demais.

## 4) Zonas macro recomendadas

A fazenda final do protótipo deve ser pensada como um conjunto de zonas com função clara:

- **Área inicial**
  - casa/spawn;
  - caldeirão;
  - baú;
  - ponto de leitura do estado geral;
  - acesso simples ao loop principal.

- **Área de cultivo**
  - bloco principal de produção;
  - espaço para os lotes fixos atuais;
  - margem para expansão visual sem colar tudo no centro.

- **Área corrompida 1**
  - primeira área bloqueada/purificável;
  - já deve ser lida como destino separado do núcleo inicial.

- **Área corrompida 2 futura**
  - reservada no layout, mas sem gameplay agora;
  - só entra quando houver decisão clara de expansão.

- **Área de criaturas / animais mágicos**
  - zona mais orgânica e separada do cultivo;
  - ideal para conteúdo sistêmico futuro.

- **Área de golems / ajudantes**
  - próxima do baú ou da logística da fazenda;
  - pensada para reduzir deslocamento e reforçar automação.

- **Área de pesca / lago**
  - com leitura própria e afastada do núcleo agrícola;
  - já existe como ponto físico e deve ganhar mais identidade espacial.

- **Área de recursos / forrageamento**
  - espaço de coleta, materiais e progressão lateral;
  - pode funcionar como zona de transição entre áreas principais.

- **Área de ruína / mistério futura**
  - opcional, se houver necessidade narrativa;
  - deve permanecer apenas como reserva de layout por enquanto.

## 5) Regras técnicas

- Não alterar a ordem dos `FarmPlot` existentes.
- Novos `FarmPlot` reais só entram depois de uma decisão explícita sobre o save.
- Áreas futuras podem existir como blockout visual, mas sem gameplay.
- Qualquer área bloqueada visual **não deve** entrar no grupo `lotes_terra`.
- `FarmGridPreview` continua sendo um laboratório isolado.
- O plano macro não deve acoplar o `FarmGridManager` ao jogo principal.

## 6) Plano de Fase 1.5

A Fase 1.5 deve ser pequena e segura:

1. **Documentar o layout**
   - registrar as zonas macro e os limites do núcleo atual.

2. **Criar blockout visual leve**
   - desenhar reservas de espaço, sem criar gameplay novo.

3. **Reservar espaço para a segunda área corrompida**
   - apenas como intenção espacial, sem funcionalidade.

4. **Criar missão inicial / objetivos mínimos**
   - só se isso ajudar a guiar a leitura do mapa e da progressão.

5. **Manter a Fase 1 intacta**
   - sem mexer em `FarmPlot`, `SaveManager`, cenas ou fluxo validado.

## 9) Blockout visual V0

O blockout visual V0 da fazenda já pode ser implementado como camada de apresentação sem gameplay:

- marcadores visuais simples para criaturas/animais mágicos;
- marcadores visuais simples para golems/ajudantes;
- marcadores visuais simples para recursos/forrageamento;
- marcador visual da segunda área corrompida futura;
- marcador visual de ruína/mistério futura.

Esses elementos são apenas visuais, não entram em `lotes_terra` e não fazem parte do save.

## 7) O que fica para a Fase 2

A Fase 2 deve concentrar as mudanças sistêmicas de fato:

- solo livre;
- grid real;
- criação/remoção de lotes;
- segunda área corrompida funcional;
- expansão maior do save;
- migração real para `FarmGrid`, se aprovada.

## 8) Observações finais

Este plano existe para organizar a escala da fazenda antes do salto para um sistema mais livre. A prioridade é evitar que o crescimento futuro empurre tudo para a mesma região inicial e comprometa leitura, ritmo e expansão.

O resultado esperado da Fase 1.5 não é mais gameplay: é um mapa melhor planejado, com espaço reservado para as próximas fases.
