# Fishing System — Pesca de Ressonância

## Visão Geral

A pesca será um sistema integrado ao lago da fazenda.

No design final, a pesca não deve ser tratada como laboratório em cena separada. O lago será parte física da fazenda e servirá como ponto real de interação do jogador.

O objetivo é criar uma atividade calma, mágica e acessível, que converse com o restante do ecossistema alquímico do jogo sem quebrar o loop agrícola atual.

## Base atual no jogo principal

A `Vara de Pesca` já existe como ferramenta visual/global na toolbar principal.

A ferramenta já conversa com o V0 do lago, da boia, do popup de sincronia e das recompensas simples.

A presença dela serve como base de interface para a futura pesca integrada ao lago da fazenda, e o V0 já conversa com o lago, a boia, o popup e recompensas simples.

## Lago da Fazenda V0

O jogo principal já possui um `FishingSpot` físico/clicável na fazenda.

Esse ponto ainda é mínimo, mas já cobre o loop V0: ele responde quando a `Vara de Pesca` está ativa, mostra feedback de lançamento, mantém a boia e, quando a puxada fake acontece, abre o popup de sincronia V0.

Ainda não há áreas especiais nem integração com caldeirão ou árvore de alquimia nesta etapa; o V0 já inclui boia, puxada fake, popup e recompensa simples.

## Boia V0

A primeira representação visual da pesca é uma boia simples no ponto clicado do lago.

Ela é única: o jogo mantém apenas uma boia ativa por vez, e um novo clique com a Vara de Pesca reposiciona a mesma boia.

Ainda não existe puxada, timing, resultado ou recompensa. A boia é apenas o primeiro estado visual da ação de pescar.

## Puxada Fake V0

Depois de alguns segundos, a boia entra em um estado simples de puxada fake.

Esse estado existe apenas como sinal visual de que algo mordeu a linha. Ainda não há minigame completo, inventário especial ou integração com caldeirão, mas já existe uma recompensa aquática V0 simples.

Se o jogador clicar novamente com a Vara de Pesca ativa enquanto a boia está nesse estado, o jogo abre o popup de sincronia V0, encerra o teste da boia e volta o lago para o estado inicial.

## Popup de Sincronia V0

Quando a puxada fake está ativa e o jogador clica de novo com a `Vara de Pesca`, o jogo abre um popup simples de Pesca de Ressonância.

Esse popup é leve e serve só para validar a leitura do timing:

- mostra uma barra horizontal;
- mostra uma zona de acerto;
- mostra um marcador em movimento;
- aceita tecla `Espaço` e clique em qualquer área da janela, consumindo esse input para não vazar para outros handlers;
- calcula um resultado simples: `O pulso se perdeu.`, `Boa sincronia.` ou `Ressonância perfeita!`;
- gera recompensa aquática V0 simples no inventário real;
- não conecta inventário, caldeirão ou árvore de alquimia.

O popup continua sendo apenas o primeiro passo interativo da pesca. Ele valida o clique certo sem transformar o sistema em um minigame grande demais cedo demais.

Quando o popup se encerra, a `Vara de Pesca` permanece selecionada e o `FishingSpot` volta para `IDLE`, permitindo um novo lançamento imediato no lago. Para isso, o fechamento usa uma seleção forçada no `ToolManager`, sem depender do toggle de `select_fishing_rod()`.

## Recompensa Aquática V0

O resultado do popup já pode gerar recompensa simples no inventário real:

- `Errou` / `MISS`: nenhum item;
- `Bom` / `GOOD`: `peixe_comum` x1;
- `Perfeito` / `PERFECT`: `escama_brilhante` x1.

Esses itens entram em `GlobalInventory` e aparecem no inventário visual como parte do fluxo V0.

O balanceamento, os nomes e a quantidade de recompensas continuam provisórios. Ainda não há conexão com caldeirão, receitas ou árvore de alquimia.

## Princípio principal

O jogador poderá lançar a vara em qualquer área válida do lago.

Algumas áreas do lago terão movimento, ondulação ou brilho mágico temporário. Essas áreas especiais não serão obrigatórias para pescar, mas aumentam a chance de peixes melhores ou ingredientes aquáticos raros.

Esse desenho evita frustração e mantém a pesca acessível mesmo para quem só quer pescar de forma simples.

## Fluxo da pesca

Fluxo futuro planejado:

1. Jogador seleciona Vara de Pesca.
2. Jogador clica em qualquer área pescável do lago.
3. A boia é lançada.
4. Depois de um tempo, a boia é puxada.
5. Abre um popup/minigame de sincronia.
6. Jogador clica no momento certo.
7. Resultado gera peixe ou ingrediente aquático.
8. Recompensas podem alimentar inventário, caldeirão, receitas e árvore de alquimia no futuro.

Hoje, o jogo principal já tem uma versão V0 desse passo 5, com popup simples de sincronia e resultados fake que já geram recompensas simples.

Enquanto o popup está aberto, o Lago da Fazenda V0 bloqueia novo lançamento e pede para o jogador finalizar a pesca atual antes de começar outra.

## Pesca de Ressonância

A mecânica de sincronia será leve e chamada de Pesca de Ressonância.

A água pulsa.
A boia reage.
O jogador precisa clicar ou confirmar no momento certo.

Acertos melhores aumentam a qualidade da recompensa.

A mecânica deve ser calma, mágica e legível, não punitiva.

O design deve ser mais simples e aconchegante do que um minigame rítmico complexo.

## Áreas com movimento no lago

Pontos de movimento aparecerão temporariamente.

Esses pontos podem ser ondulações, círculos, brilhos ou bolhas.

Eles aumentam a chance de peixes melhores ou ingredientes aquáticos raros.

Essas áreas podem variar por estação, horário ou melhorias futuras.
Elas não impedem pesca fora delas.

Exemplo de chance conceitual:

- área comum: maior chance de peixe comum;
- área com movimento: maior chance de peixe raro;
- área brilhante: maior chance de ingrediente mágico.

Não há números definidos agora.

## Recompensas futuras

Recompensas possíveis, provisórias:

- `peixe_comum`;
- `peixe_luminoso`;
- `escama_brilhante`;
- `gota_lunar`;
- `lodo_de_lago`;
- `peixe_sazonal`;
- `ingrediente_aquatico_raro`.

Nomes e balanceamento continuam provisórios.

## Relação com caldeirão e receitas

A pesca deve fornecer ingredientes para:

- receitas alquímicas;
- poções;
- missões futuras;
- melhorias de fazenda;
- progressão na árvore de alquimia.

Nesta etapa, a pesca não deve ser conectada ainda ao caldeirão.

## Relação com árvore de alquimia

Possíveis upgrades futuros:

- aumentar chance de pontos de movimento aparecerem;
- ampliar janela de acerto;
- reduzir tempo até a boia ser puxada;
- aumentar chance de ingredientes raros;
- detectar pontos especiais por mais tempo;
- melhorar recompensas perfeitas;
- permitir iscas alquímicas futuramente.

## Versão mínima integrada V0

A primeira implementação futura deve ser pequena e controlada:

- criar lago ou ponto de pesca na fazenda;
- adicionar Vara de Pesca como ferramenta;
- permitir clicar no lago;
- lançar boia;
- após delay, abrir popup simples;
- calcular acerto por timing;
- gerar recompensa simples;
- sem árvore de upgrades;
- sem muitos peixes;
- sem save complexo;
- sem integração profunda com receitas ainda.

## O que evitar agora

Não criar agora:

- minigame complexo com várias pistas;
- muitos peixes;
- iscas consumíveis;
- loja de pesca;
- múltiplos lagos;
- ligação à árvore de alquimia;
- quebra do loop agrícola recém-estabilizado;
- conexão com o FarmGrid.

## Decisão atual

- A pesca foi aprovada como direção de gameplay paralelo.
- A prioridade é média.
- A implementação futura deve começar como versão mínima integrada ao lago da fazenda.
- Não será cena de laboratório isolada no design final.
- A primeira etapa de código deve ser pequena e controlada.
