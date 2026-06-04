# Fishing System — Pesca de Ressonância

## Visão Geral

A pesca será um sistema integrado ao lago da fazenda.

No design final, a pesca não deve ser tratada como laboratório em cena separada. O lago será parte física da fazenda e servirá como ponto real de interação do jogador.

O objetivo é criar uma atividade calma, mágica e acessível, que converse com o restante do ecossistema alquímico do jogo sem quebrar o loop agrícola atual.

## Base atual no jogo principal

A `Vara de Pesca` já existe como ferramenta visual/global na toolbar principal.

Ela ainda não lança boia, não abre minigame e não gera recompensa real.

A presença dela serve como base de interface para a futura pesca integrada ao lago da fazenda.

## Lago da Fazenda V0

O jogo principal já possui um `FishingSpot` físico/clicável na fazenda.

Esse ponto ainda é mínimo: ele só responde quando a `Vara de Pesca` está ativa e mostra feedback de lançamento.

Ainda não há minigame, recompensas, áreas especiais ou integração com inventário nesta etapa.

## Boia V0

A primeira representação visual da pesca é uma boia simples no ponto clicado do lago.

Ela é única: o jogo mantém apenas uma boia ativa por vez, e um novo clique com a Vara de Pesca reposiciona a mesma boia.

Ainda não existe puxada, timing, resultado ou recompensa. A boia é apenas o primeiro estado visual da ação de pescar.

## Puxada Fake V0

Depois de alguns segundos, a boia entra em um estado simples de puxada fake.

Esse estado existe apenas como sinal visual de que algo mordeu a linha. Ainda não há minigame, recompensa, inventário ou integração com caldeirão.

Se o jogador clicar novamente com a Vara de Pesca ativa enquanto a boia está nesse estado, o teste é encerrado e o protótipo volta para o estado inicial.

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
