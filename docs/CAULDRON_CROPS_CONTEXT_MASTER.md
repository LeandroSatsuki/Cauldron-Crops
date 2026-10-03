# CAULDRON CROPS — CONTEXTO MESTRE DO PROJETO

> Documento de onboarding para agentes de IA/Codex.
>
> Objetivo: permitir que uma nova sessão compreenda rapidamente **o que Cauldron Crops pretende ser**, **o estado atual do protótipo**, **quais decisões já estão encaminhadas**, **quais continuam abertas** e **como colaborar com o autor do projeto**.
>
> Este documento **não é uma especificação imutável**. O jogo ainda está sendo descoberto durante o desenvolvimento. Quando houver conflito entre este documento e uma decisão humana mais recente, a decisão humana prevalece.

Estado operacional mais recente (2026-10-03): autor não poderá testar agora e autorizou continuar construção com checklist posterior. Não exigir novo gate manual a cada incremento nem presumir aceite. Segunda expedição implementada com aceites parciais de §46; polimento em §47–51 e orientação contextual da expedição em §52 verificados automaticamente. Consultar `ROADMAP.md` para fila atual/pendências. Relatos anteriores são históricos; arte e casos-limite não foram presumidos aprovados.

---

# 1. REGRA PRINCIPAL PARA QUALQUER AGENTE

Cauldron Crops não deve ser tratado apenas como um problema de implementação.

O autor quer **entender as decisões de programação e arquitetura**, e não simplesmente pedir para a IA produzir código.

A IA deve funcionar como:

- assistente técnico;
- pair programmer;
- mentor;
- revisor de arquitetura;
- executor quando a decisão já estiver clara.

O autor deve continuar sendo o **cérebro do projeto**.

## Antes de uma decisão arquitetural relevante

Quando houver mais de uma abordagem razoável:

1. explique o problema;
2. apresente as principais alternativas;
3. explique vantagens, desvantagens e consequências;
4. dê uma recomendação;
5. permita que o autor tome ou aprove a decisão;
6. somente então implemente, salvo quando a tarefa tiver sido explicitamente dada como execução direta.

Não escolha silenciosamente uma arquitetura importante apenas porque uma solução funciona.

## Não transformar tudo em aula

Nem toda linha precisa ser explicada.

A IA pode executar tarefas mecânicas, repetitivas ou já compreendidas pelo autor.

O foco de aprendizado deve estar principalmente em:

- responsabilidades;
- fluxo de dados;
- arquitetura;
- estados;
- persistência;
- debugging;
- dependências entre sistemas;
- trade-offs;
- motivo das decisões.

Uma boa meta é que o autor consiga responder:

1. O que entrou?
2. Por que entrou?
3. Quem conversa com isso?
4. Se quebrar, onde começo a investigar?

---

# 2. ESSÊNCIA DE CAULDRON CROPS

Cauldron Crops é um jogo 2D cozy/idle de fazenda, alquimia, descoberta, criaturas mágicas e reconstrução de um lugar corrompido.

A intenção não é fazer apenas um “Stardew Valley com magia”.

A magia deve fazer parte da infraestrutura do mundo e dos sistemas.

Uma formulação provisória da fantasia central é:

> Recuperar uma antiga fazenda/vila mágica tomada pela corrupção, usando cultivo, alquimia, criaturas mágicas e espíritos da natureza para trazer vida de volta ao lugar.

O jogo deve passar uma sensação de:

- curiosidade;
- magia;
- descoberta;
- aconchego;
- reconstrução;
- surpresa;
- mundo vivo;
- possibilidade.

Uma frase que pode servir como bússola de design:

> **O jogador deve sentir que o mundo sabe mais coisas do que ele.**

O jogador precisa compreender o loop básico sem wiki, mas deve perceber que existem segredos, comportamentos, histórias e possibilidades além do necessário para “zerar” ou progredir.

---

# 3. O CALDEIRÃO É O CORAÇÃO DO JOGO

O caldeirão fica no centro da vila/fazenda e deve ser um dos principais elementos da identidade de Cauldron Crops.

Ele não deve ser apenas uma crafting station.

A direção conceitual é que ele seja um artefato capaz de **transformar ou dar forma à magia**.

Ele conecta sistemas como:

```text
PLANTAÇÃO
    ↓
ingredientes
    ↓
CALDEIRÃO
    ↓
alquimia / transformação
    ↓
sementes
poções
crafts
rituais
purificação
corpos/receptáculos de golem
novas possibilidades
    ↓
PROGRESSÃO DA FAZENDA
```

A alquimia deve ser um dos principais motores de descoberta.

Idealmente, o jogador deve ter momentos do tipo:

> “O que acontece se eu misturar isso?”

Nem toda receita precisa ser simplesmente entregue em uma lista de níveis.

---

# 4. CORRUPÇÃO E EXPANSÃO DA FAZENDA

A fazenda/vila já teve dias de glória.

Algum evento ligado à corrupção destruiu ou abandonou grande parte do lugar.

A referência conceitual inicial veio do Gloom de CastleVille:

- regiões ficam tomadas por corrupção;
- o jogador purifica essas regiões;
- a terra restaurada volta a ser utilizável;
- novas partes do mundo são reveladas.

Purificar uma área não deve significar simplesmente:

> “+20 tiles de terreno”.

A expansão deve ter sensação de descoberta.

Uma região purificada pode revelar:

- ruínas;
- construções antigas;
- NPCs;
- criaturas;
- novos tipos de solo;
- plantas;
- recursos;
- lagos;
- passagens;
- elementos de lore;
- objetos estranhos;
- novas mecânicas.

Cada expansão pode responder uma pergunta e criar outra.

---

# 5. AGRICULTURA — DIREÇÃO DE DESIGN

O sistema começou com `FarmPlot` fixos.

Originalmente:

- os lotes já existiam no mapa;
- o jogador só podia arar/plantar nesses pontos.

A direção atual mudou.

## Objetivo

O jogador deve conseguir arar **qualquer local válido da terra**, desde que:

- seja uma área cultivável;
- esteja desbloqueada;
- não esteja tomada pela corrupção;
- não exista água;
- não exista obstáculo;
- não exista construção ou outra ocupação incompatível.

Portanto, não assumir que a grade fixa atual representa o sistema final.

Também não tratar diferenças históricas como `64 px` vs `80 px` automaticamente como bugs a “corrigir”.

O projeto passou por gerações diferentes da agricultura.

A migração precisa considerar a arquitetura desejada, não simplesmente padronizar números antigos.

---

# 6. CRIATURAS MÁGICAS NO LUGAR DO ÓBVIO

O mundo deve substituir vários arquétipos tradicionais de farming game por equivalentes mágicos.

Exemplos conceituais:

- galinhas → cocatrizes;
- animais comuns → criaturas mágicas;
- vizinhos humanos convencionais → ogros, fadas, goblins, espíritos e outras criaturas;
- plantas comuns → versões mágicas inspiradas em plantas reconhecíveis.

## Plantas

É desejável manter conexão com plantas reais para facilitar memorização.

Exemplo de direção:

- Tomate Solar;
- Abóbora Sombria;
- Cenoura Lunar;
- Feijão Celestial.

Evitar transformar todo item em nomes completamente abstratos que obriguem o jogador a decorar um dicionário.

Familiaridade + fantasia é desejável.

---

# 7. MISSÕES E NPCs

Criaturas da região podem oferecer solicitações, inclusive missões recorrentes/diárias.

Mas uma missão não deve existir apenas porque o sistema precisa de uma daily.

As solicitações devem fazer sentido na história e na vida da criatura.

Exemplo:

- comunidade perdeu seus cultivos devido à corrupção;
- criatura precisa de uma poção;
- ogro está reconstruindo uma casa;
- fada precisa de determinada flor;
- mercador procura determinado ingrediente.

Mecanicamente pode continuar sendo:

```text
entregar itens
→ recompensa
```

Mas narrativamente deve existir um motivo.

Recompensas podem incluir:

- dinheiro;
- sementes;
- materiais;
- itens;
- receitas;
- outros recursos.

---

# 8. GOLEMS — UM DOS PILARES DO JOGO

Os golems são um elemento central tanto mecanicamente quanto emocionalmente.

Eles **não devem ser apenas workers abstratos**.

A direção atual é que sejam criaturas físicas, fofas e vivas dentro do mundo.

## Funções

Inicialmente:

- coletar plantações maduras;
- levar itens ao baú.

Por progressão/árvore de habilidades, podem futuramente aprender:

- regar;
- plantar;
- pescar;
- usar o caldeirão;
- outras tarefas.

## Filosofia

Eles podem automatizar a fazenda, mas não devem parecer máquinas de farm infinito.

Queremos eventualmente explorar:

- cansaço;
- descanso;
- pequenas preferências;
- interações entre golems;
- personalidade;
- comportamentos raros;
- apego;
- aparência individual;
- afinidades;
- evolução/upgrades.

A presença deles deve ajudar a fazenda a parecer viva.

Exemplo de comportamento desejável:

Durante uma tempestade, um golem pode parar e procurar abrigo.

Não precisa haver recompensa.

O jogador pode apenas perceber:

> “Ele tem medo de trovão?”

Esse tipo de detalhe pode produzir mais vida do que sistemas enormes.

---

# 9. LORE PROVISÓRIA DOS GOLEMS

A ideia atual, ainda sujeita a discussão:

Os golems não são vidas criadas do zero.

Eles são **espíritos da natureza**.

A inspiração emocional inclui os pequenos espíritos de natureza de *Princesa Mononoke*, sem copiar elementos protegidos.

Antes da destruição da vila, uma entidade/guardiã extremamente poderosa possuía uma relação com esses espíritos.

Quando a corrupção surgiu, ela pode ter enviado/protegido os espíritos em outro plano ou camada da realidade.

Depois disso, ela foi aprisionada.

## Criar um golem

O jogador não cria a alma.

Ele prepara um **receptáculo/corpo** com materiais e realiza um ritual através do caldeirão.

Conceitualmente:

```text
materiais
↓
corpo/receptáculo

espírito da natureza
↓
ritual/calderão
↓
GOLEM
```

Os materiais podem influenciar:

- aparência;
- propriedades;
- afinidades;
- eventualmente alguns talentos.

O espírito determina sua individualidade.

Isso permite que RNG de criação tenha significado narrativo.

---

# 10. RNG E COLEÇÃO

O autor gosta de loot e RNG.

RNG deve existir, mas não apenas como aumento de números.

Pode participar de:

- materiais raros;
- sementes;
- receitas;
- eventos;
- aparência dos golems;
- peculiaridades;
- traços;
- variantes;
- descobertas.

Exemplo conceitual de um golem:

```text
corpo: musgo
olhos: cristal lunar
personalidade: curioso
afinidade: pesca
peculiaridade: dorme perto da água
traço raro: bioluminescente
```

O ideal é gerar momentos do tipo:

> “Olha o bichinho que nasceu!”

e não apenas:

> “Ganhei +17% de produtividade.”

---

# 11. IDLE — FILOSOFIA

A ideia inicial do jogo é ter forte natureza idle.

Mas o objetivo não é fazer um jogo em que a melhor forma de jogar seja não jogar.

A filosofia desejável é:

> **Ausência não pune; presença recompensa.**

## Offline/idle

Os golems mantêm parte da fazenda funcionando.

Podem:

- colher;
- cuidar;
- pescar;
- produzir;
- realizar tarefas compatíveis com suas habilidades.

## Jogador ativo

A presença ativa deve permitir:

- maior eficiência;
- decisões;
- descoberta;
- exploração;
- alquimia;
- eventos;
- otimização;
- recursos raros;
- interação;
- customização.

O jogador ativo pode ser mais rentável, mas quem não puder jogar naquele momento não deve sentir que perdeu tudo.

Os golems trabalham **junto com o jogador**, não no lugar dele.

---

# 12. O MUNDO DEVE PARECER VIVO

“Mundo vivo” não significa necessariamente centenas de NPCs ou uma simulação gigantesca.

Pequenos comportamentos podem produzir essa sensação.

Exemplos:

- golem se abriga da chuva;
- cocatriz persegue o próprio rabo;
- dois golems fazem uma pequena interação;
- criatura aparece ao longe;
- NPC muda uma frase depois da purificação;
- flor surge apenas em determinada condição;
- estátua reage a um item;
- planta se comporta diferente durante um evento;
- golem olha para uma ruína antiga.

Esses elementos podem ser relativamente baratos tecnicamente e muito valiosos emocionalmente.

---

# 13. DESCOBERTA, SEGREDOS E EASTER EGGS

Este é um dos pilares mais importantes.

O autor gosta muito da sensação de descobrir possibilidades, similar ao impacto que sentiu ao descobrir RPG pela primeira vez.

Cauldron Crops deve permitir:

> “Eu não sabia que dava para fazer isso.”

O jogo deve possuir muitas coisas opcionais espalhadas pela fazenda e por futuras regiões.

Quem não encontrar deve conseguir jogar normalmente.

Quem encontrar descobre mais sobre:

- mundo;
- passado;
- personagens;
- guardiã;
- golems;
- corrupção;
- caldeirão;
- outras regiões.

## Três tipos úteis de descoberta

### 1. Atmosférica

Não altera progressão significativamente.

Exemplos:

- animação rara;
- frase;
- som;
- comportamento;
- objeto reagindo;
- criatura distante.

### 2. Lore

Ajuda a montar o passado.

Exemplos:

- inscrições;
- ruínas;
- frases desconexas;
- memórias;
- relatos contraditórios;
- objetos antigos.

### 3. Mecânica

Realmente abre alguma possibilidade.

Exemplos:

- receita secreta;
- semente rara;
- variante de golem;
- nova região;
- recurso;
- ritual.

Nem toda descoberta deve dar XP, dinheiro ou recompensa.

Às vezes:

> **a descoberta é a recompensa.**

---

# 14. LORE NÃO OBRIGATÓRIA E FRAGMENTADA

Evitar depender apenas de:

```text
Diário 1
Diário 2
Diário 3
Diário 4
```

É desejável que parte da história seja reconstruída pelo jogador.

Exemplo:

Em uma ruína:

> “...prometi que não chamaria nenhum deles novamente.”

Muito depois:

> “Eles sempre retornam quando recebem um nome.”

Depois uma criatura comenta:

> “Ela dizia que não criava os pequeninos. Só lhes dava um lugar para ficar.”

O jogo não precisa dizer:

> “Essas três frases explicam os golems.”

O jogador curioso pode montar a hipótese.

Informações também podem ser:

- incompletas;
- enviesadas;
- contraditórias.

Exemplo:

- uma criatura acredita que a guardiã salvou a vila;
- outra acredita que ela condenou a vila.

A verdade não precisa ser revelada imediatamente.

---

# 15. EVENTOS

O autor gosta muito de eventos e possibilidades inesperadas.

Eventos não devem significar apenas conteúdo sazonal temporário.

Podem ser fenômenos naturais/mágicos internos ao mundo:

- chuva celestial;
- tempestade mágica;
- noite dos espíritos;
- lua incomum;
- enxame de fadas;
- estrela cadente;
- florescimento raro;
- névoa de corrupção;
- migração de criaturas.

Esses eventos podem alterar probabilidades ou possibilidades temporariamente.

---

# 16. SEMENTE CELESTIAL / FEIJÃO MÁGICO

Existe uma ideia de longo alcance:

Uma semente mágica extremamente especial, inspirada no conceito do feijão mágico, pode eventualmente levar o jogador acima das nuvens.

Lá poderá existir uma fazenda/região celestial especial.

Isso não deve ser o único objetivo do jogo.

A jornada precisa ser divertida independentemente disso.

## Ideia de descoberta

Depois de uma chuva/evento raro, pode existir uma pequena chance de uma semente cair do céu.

O jogo não precisa explicar imediatamente.

Exemplo:

**Semente Desconhecida**

> “Estranhamente quente. Parece ter caído de algum lugar muito distante.”

O jogador pode tentar plantá-la e descobrir que o solo normal não consegue sustentá-la.

Isso cria uma pergunta de longo prazo.

Não transformar automaticamente isso em:

> QUEST PRINCIPAL ATUALIZADA.

Preservar mistério.

---

# 17. FANTASIA DO JOGADOR — AINDA ABERTA

Ainda não existe decisão final sobre “quem é o jogador”.

Não canonizar sem discussão.

Ideias consideradas:

- bruxo;
- aprendiz;
- herdeiro;
- isekai;
- familiar/companheiro da antiga guardiã.

A direção mais interessante discutida até agora é a do **familiar antigo da guardiã**.

## Hipótese atual

A antiga dona/guardiã da fazenda era uma entidade ou criatura muito poderosa.

Ela foi aprisionada durante o evento que levou à corrupção e queda da vila.

Como último ato, enviou/protegeu seu familiar/amigo/companheiro.

Esse familiar ficou adormecido durante “tempo demais”.

Décadas, séculos ou outro intervalo não precisam ser definidos cedo.

Alguma influência/evento X faz esse familiar despertar.

Ele perdeu parte de suas memórias.

Assim:

- o jogador conhece o lugar;
- mas não lembra de tudo;
- a vila mudou;
- o jogador descobre o passado junto com o personagem.

Essa estrutura ajuda a justificar descoberta e mistério.

---

# 18. PERSONAGEM CONTROLÁVEL — DECISÃO ABERTA

O projeto começou sem personagem tradicional controlado por WASD.

Ainda não está decidido se isso foi a melhor opção.

Não implementar personagem controlável apenas por convenção de gênero.

Uma alternativa discutida:

O familiar representa o jogador fisicamente no mundo sem necessariamente usar movimentação tradicional.

Ele pode:

- aparecer perto das ações;
- acompanhar o cursor;
- reagir;
- dormir perto do caldeirão;
- participar de eventos;
- funcionar como mascote/representação do jogador.

A decisão deve considerar:

- identidade do idle;
- interação com o mundo;
- sensação de presença;
- custo de desenvolvimento;
- design de controles.

---

# 19. POR QUE AS CRIATURAS CONFIAM NO JOGADOR?

Evitar:

> “Você é o escolhido e todo mundo gosta de você.”

A confiança pode ser reconstruída.

A vila foi destruída.

A guardiã desapareceu.

O familiar reaparece depois de muito tempo.

Algumas criaturas podem reconhecê-lo.

Outras nunca o conheceram.

Exemplos:

- fada antiga reconhece algo nele;
- ogro jovem nunca ouviu falar;
- criatura foge;
- outra desconfia.

Missões e reconstrução da vila podem criar gradualmente a sensação de comunidade.

---

# 20. CUSTOMIZAÇÃO

A estética das criaturas e da fazenda é importante.

O jogador deve poder olhar para sua fazenda e sentir:

> “Essa é a minha.”

Direções:

- criaturas variadas;
- golems visualmente únicos;
- temas;
- decoração;
- plantas;
- organização;
- combinações estéticas.

Exemplos conceituais:

- fazenda cheia de musgo e golems naturais;
- fazenda lunar;
- fazenda de cristais;
- fazenda caótica de cocatrizes.

“Olha a minha fazenda” é uma sensação desejável.

---

# 21. SUPORTE A DIFERENTES PERFIS DE JOGADOR

O projeto pode atender:

- jogador cozy;
- jogador idle;
- jogador que gosta de coleção;
- jogador de descoberta/lore;
- jogador de customização;
- jogador que gosta de grind e otimização.

Evitar obrigar todos a jogar como grinders.

O grind pode existir como profundidade opcional.

---

# 22. PRINCÍPIO DE ESCOPO

A visão é ambiciosa.

Não implementar tudo de uma vez.

Regra:

> **Provar a sensação antes de construir a escala.**

Uma versão relativamente pequena já deveria conseguir provocar:

1. “Quero ver o que acontece se misturar isso.”
2. “Quero libertar aquela área para descobrir o que tem lá.”
3. “Olha o que meu golem está fazendo.”
4. “O que significa essa frase?”
5. “Espera... isso sempre esteve aqui?”

Se isso funcionar em pequena escala, expandir depois.

---

# 23. ESTADO TÉCNICO ATUAL — RESUMO DA AUDITORIA

O projeto já é um protótipo jogável integrado.

Sistemas existentes:

- agricultura baseada em `FarmPlot`;
- ferramentas;
- inventário;
- economia;
- loja/venda;
- estações;
- sono;
- caldeirão;
- receitas;
- golem físico;
- navegação;
- baú;
- pesca;
- purificação;
- expansão inicial;
- quests;
- skills;
- save/load;
- bridge inicial entre `FarmPlot` e `FarmGridManager`.

## Situação da agricultura

Hoje:

- `FarmPlot` ainda é a entidade real de gameplay;
- `FarmGridManager` já participa como bridge/snapshot;
- save e golem já usam partes do grid;
- `FarmGridPreview` existiu/existe como laboratório;
- agricultura verdadeiramente livre ainda não está concluída.

Não considerar presença de `FarmGridManager` equivalente a migração completa.

## Riscos técnicos importantes encontrados

1. identidade/autoridade entre `FarmPlot`, `FarmTileData` e `FarmGridManager`;
2. risco de lotes duplicados na expansão durante load;
3. save com versão declarada sem migração formal;
4. campos ricos do tile podem ser perdidos em rebuilds;
5. falta de política única de “solo válido”;
6. receitas Resources exibem propriedades nem sempre respeitadas pela produção;
7. criação de golem ainda possui contador abstrato em alguns fluxos;
8. IDs são persistidos sem política formal de alias/migração;
9. navegação ainda tem aspectos provisórios;
10. documentação possui camadas históricas contraditórias.

---

# 24. DIREÇÃO TÉCNICA ATUAL

Evitar reescrever o projeto.

A estratégia deve ser incremental.

Prioridade conceitual:

```text
preservar protótipo jogável
↓
estabilizar contratos que bloqueiam evolução
↓
migrar uma parte por vez
↓
testar no Godot
↓
registrar decisão
```

Não fazer:

> “vamos limpar tudo antes de continuar.”

Limpeza deve ser guiada pela direção futura.

Código antigo que não atrapalha pode permanecer temporariamente.

---

# 25. PONTOS TÉCNICOS QUE MAIS PROTEGEM O FUTURO

Antes de uma migração ampla para agricultura livre, provavelmente será necessário resolver:

- uma coordenada não pode representar dois lotes;
- lookup canônico de lote/tile;
- autoridade transitória do estado agrícola;
- política de solo válido;
- save por identidade/coordenada;
- integração correta da expansão;
- compatibilidade necessária com saves antigos;
- origem e tamanho lógico das células;
- relação do golem com tiles livres;
- obstáculos/corrupção dentro da mesma política de terreno.

Não resolver tudo de uma vez.

---

# 26. GOLEM FÍSICO É A DIREÇÃO ATUAL

`Golem.gd` representa a direção conceitual correta:

- criatura física;
- navegação;
- procura trabalho;
- deslocamento;
- colheita;
- rega;
- transporte;
- depósito.

`GolemManager.gd` representa uma geração mais antiga:

- automação abstrata;
- trabalho remoto;
- contador.

Ele deve permanecer desligado enquanto não houver decisão específica.

Não reativar automaticamente.

Pode eventualmente existir um manager de coleção/spawn/persistência de golems físicos, mas isso não significa reusar a lógica antiga de trabalho remoto.

---

# 27. CALDEIRÃO E RECEITAS

Direção técnica desejada:

```text
Cauldron
↓
RecipeResolver
↓
RecipeDatabase / RecipeData
↓
fallback legado temporário em Database
```

A migração deve continuar gradual.

Antes de expandir muito o catálogo, alinhar quando necessário:

- quantidade do resultado;
- tempo da receita;
- recompensa de alquimia;
- descoberta;
- refund/cancelamento.

Não apagar o catálogo legado sem verificar cobertura e saves.

---

# 28. SAVE

Save é uma área sensível.

Antes de mudanças grandes em agricultura, golems ou IDs:

- preservar saves representativos;
- entender versão;
- definir política de migração;
- evitar depender de ordem de nodes;
- evitar recriar entidades duplicadas;
- considerar identidade persistente.

Golems futuramente precisarão de identidade individual se aparência, personalidade, fadiga e apego forem persistentes.

---

# 29. DOCUMENTAÇÃO

O repositório possui documentação extensa, mas parte dela é histórica.

Arquivos como:

- `ROADMAP.md`;
- `DECISIONS.md`;
- `CHANGELOG.md`;
- `FARM_SYSTEM_V2.md`;
- outros docs específicos;

podem descrever estados de momentos diferentes do desenvolvimento.

Portanto:

- `DECISIONS.md` = histórico de decisões;
- `CHANGELOG.md` = histórico;
- documentos antigos não são automaticamente especificação vigente.

É recomendável manter um documento curto de estado atual.

Este arquivo pode cumprir parte dessa função, mas o ideal é separar no futuro:

```text
GAME_VISION.md
PROJECT_CONTEXT.md
DEVELOPMENT_PLAN.md
DECISIONS.md
```

---

# 30. MODOS DE COLABORAÇÃO

Quando possível, interpretar os seguintes modos:

## MENTOR

Não entregar imediatamente a solução completa.

Objetivo:

- fazer o autor raciocinar;
- explicar alternativas;
- fornecer pistas;
- corrigir entendimento;
- avançar gradualmente.

Útil para:

- arquitetura;
- conceitos;
- debugging;
- começo de implementação.

## PAIR

Autor e IA resolvem juntos.

O autor propõe uma solução ou raciocínio e a IA revisa.

## EXECUTA

A decisão já está tomada.

Implementar diretamente, com mudanças pequenas e testáveis.

## DEBUG

Evitar corrigir imediatamente quando o objetivo for aprendizado.

Primeiro:

```text
hipótese
↓
evidência
↓
teste
↓
causa
↓
correção
```

---

# 31. COMO IMPLEMENTAR FEATURES

Fluxo preferencial:

```text
IDEIA
↓
definir comportamento esperado
↓
identificar responsabilidades
↓
discutir arquitetura/trade-offs
↓
autor aprova decisão
↓
implementar pequena etapa
↓
rodar verificações possíveis
↓
autor testa no Godot
↓
corrigir
↓
documentar decisão relevante
```

Evitar implementar centenas de linhas sem criar checkpoints testáveis.

---

# 32. O QUE NÃO FAZER

Não:

- refatorar grandes áreas sem necessidade concreta;
- remover código legado só por estética;
- tratar protótipo como exercício de clean code;
- assumir que documentação antiga é verdade atual;
- reativar `GolemManager` antigo;
- substituir decisões humanas por convenções genéricas;
- criar features enormes de uma vez;
- transformar todo segredo em quest explícita;
- transformar todo evento em recompensa numérica;
- transformar golems em workers sem personalidade;
- transformar idle em obrigação de login;
- explicar todos os mistérios do mundo.

---

# 33. PRINCÍPIOS DE DESIGN RESUMIDOS

## Magia sistêmica

A magia dirige gameplay, não apenas estética.

## Caldeirão central

O caldeirão conecta progressão e descoberta.

## Recuperação

O jogador traz vida de volta a um lugar destruído.

## Criaturas, não máquinas

Golems e habitantes devem parecer vivos.

## Idle sem punição

Ausência não destrói progresso; presença oferece novas possibilidades.

## Descoberta

O mundo possui coisas que não são explicadas imediatamente.

## Mistério opcional

Lore profunda pode ser ignorada sem impedir o jogo.

## Personalização

A fazenda deve adquirir identidade própria.

## Familiaridade + fantasia

Especialmente em plantas e recursos.

## Provar sensação antes de escala

Uma pequena experiência mágica é melhor que cinquenta sistemas vazios.

---

# 34. QUESTÕES DE DESIGN AINDA ABERTAS

Não decidir unilateralmente:

- quem exatamente é o jogador;
- se haverá personagem diretamente controlável;
- quem aprisionou a guardiã;
- por que a guardiã foi aprisionada;
- origem definitiva da corrupção;
- natureza definitiva do plano dos espíritos;
- intervalo de tempo desde a queda da vila;
- verdade completa sobre a antiga guardiã;
- como funciona o endgame;
- quão explícita será a narrativa principal;
- quais eventos são sistemáticos versus únicos;
- número e estrutura final dos golems;
- profundidade da fadiga/emoções;
- progressão offline definitiva.

Esses pontos devem continuar sendo discutidos.

---

# 35. QUESTÕES TÉCNICAS AINDA ABERTAS

Antes de implementar mudanças grandes, discutir quando relevante:

- `FarmPlot` ou `FarmTileData` como autoridade;
- fonte oficial de solo cultivável;
- tamanho lógico/célula definitivo;
- tratamento de coordenadas;
- corrupção por região ou célula;
- persistência de múltiplos golems;
- criação física de golem pelo caldeirão;
- consumo de água pelos golems;
- persistência de produção ativa;
- crescimento por tempo de jogo/real/offline;
- política de aliases de IDs;
- compatibilidade com saves antigos.

---

# 36. OBJETIVO DE CURTO PRAZO

Antes de adicionar muitas features novas, transformar o protótipo em uma base em que seja seguro evoluir os pilares principais.

Ordem geral sugerida pela auditoria técnica:

1. baseline/teste manual;
2. identidade dos lotes;
3. save v4/migração;
4. contrato transitório da agricultura;
5. solo válido;
6. coerência de receitas;
7. contrato dos golems físicos;
8. política de IDs;
9. piloto de agricultura livre;
10. navegação/expansão;
11. separações arquiteturais apenas quando uma feature justificar.

Essa sequência é técnica, não uma obrigação absoluta de design.

Sempre comparar com a direção atual do jogo.

---

# 37. VISÃO DE LONGO PRAZO — NÃO IMPLEMENTAR COMO UM TODO

Possibilidades desejadas ao longo do desenvolvimento:

- agricultura livre;
- regiões corrompidas;
- ruínas;
- vila restaurável;
- criaturas mágicas;
- missões contextualizadas;
- eventos;
- clima;
- segredos;
- frases e lore fragmentada;
- receitas secretas;
- RNG;
- golems únicos;
- personalidade e fadiga;
- automação gradual;
- pesca;
- alquimia;
- customização;
- regiões futuras;
- área celestial;
- Feijão/Semente Celestial.

Cada uma deve entrar apenas quando o loop atual suportar.

---

# 38. CHECK FINAL PARA O AGENTE

Antes de propor uma implementação importante, pergunte internamente:

1. Isso fortalece algum pilar de Cauldron Crops?
2. Estamos resolvendo uma necessidade atual ou fazendo arquitetura “porque parece bonita”?
3. Existe código transitório que precisa ser entendido antes?
4. Essa mudança ameaça save?
5. Essa mudança altera uma decisão de design?
6. O autor precisa escolher entre alternativas?
7. Consigo dividir em uma etapa menor e testável?
8. Como o autor validará isso no Godot?
9. Precisamos atualizar `DECISIONS.md` ou contexto?
10. Estou ajudando o autor a entender a decisão ou simplesmente tomando-a por ele?

---

# 39. FRASES-BÚSSOLA DO PROJETO

> **O jogador deve sentir que o mundo sabe mais coisas do que ele.**

> **Ausência não pune; presença recompensa.**

> **Os golems são criaturas, não máquinas.**

> **A magia é infraestrutura, não decoração.**

> **Purificar uma área deve revelar algo, não apenas aumentar o mapa.**

> **Nem toda descoberta precisa dar uma recompensa. Às vezes descobrir é a recompensa.**

> **Provar a sensação antes de construir a escala.**

> **A IA pode acelerar a implementação; as decisões importantes precisam continuar compreensíveis para o autor.**

---

# 40. AO INICIAR UMA NOVA SESSÃO

Regra de fechamento atualizada pelo autor em 2026-10-01: ao finalizar cada etapa, validar, documentar, criar commit e enviar ao GitHub, preservando o histórico remoto e selecionando somente arquivos pertinentes. Se o teste manual ainda estiver pendente, publicar como checkpoint e sinalizar essa pendência, sem afirmar aprovação. A autorização substitui instruções históricas de não fazer commit. Consultar `AGENTS.md` para o procedimento.

Leia, nesta ordem, quando disponíveis:

1. este documento;
2. `AGENTS.md`;
3. `README.md`;
4. `docs/DECISIONS.md`;
5. documento atual de roadmap/plano;
6. documentação específica do sistema em que irá trabalhar;
7. código real relacionado à tarefa.

Depois:

- confronte documentação com código;
- diferencie “estado atual”, “legado” e “direção futura”;
- não faça alteração automática apenas por encontrar divergência;
- pergunte ou apresente alternativas quando houver decisão de design/arquitetura.

Este projeto está sendo desenvolvido de forma incremental e exploratória.

A continuidade da visão é mais importante do que perseguir uma arquitetura teoricamente perfeita.

---

# 41. DIREÇÃO FUTURA — ECONOMIA, INVENTÁRIO E AQUISIÇÃO

Esta é uma direção registrada para sprints futuros; ela não autoriza mudança imediata na V0.

```text
exploração fora da vila
↓
Mochila / Inventário Pessoal
↓
retorno físico e depósito
↓
Village Storage
↓
caldeirão, purificação, projetos, requests e comércio
```

- A Mochila representa o que o personagem carrega e, no futuro, terá limite expansível por slots/stacks generosos; ela não deve punir o jogador com microgerenciamento constante.
- O `VillageChest` atual é a primeira representação física do Village Storage, que será lógico e compartilhado. Golems preservam a cadeia visível coletar → carregar → depositar.
- Vários baús podem futuramente ser pontos de acesso ao mesmo armazenamento, sem transformar a logística visível dos golems em teleporte.
- Recursos de exploração entram primeiro na Mochila; não entram automaticamente no armazenamento da vila.
- A moeda universal existe como direção, porém nome e lore não estão definidos. Os textos e fluxos atuais de `Moedas`/venda são provisórios.
- Todo recurso comum precisa de uma saída universal de baixo atrito, mas seus usos de maior valor podem estar em contexto, conhecimento e especialização.
- Conteúdo importante deve oferecer múltiplas rotas quando fizer sentido; progresso obrigatório precisa de pelo menos um caminho determinístico adequado, sem depender exclusivamente de RNG severo.
- Conhecimento e maestria ampliam possibilidades sem tornar a atividade base inviável para quem não se especializou.

Estado de transição atual: o golem já deposita fisicamente no Baú da Vila. Caldeirão, purificação e restauração consultam `Village Storage` primeiro e completam pela Mochila, através de uma reserva transacional que devolve cada recurso à origem em caso de cancelamento. O Baú e a Mochila continuam sistemas separados, acessados por dois painéis opacos com transferência manual seletiva; recursos de exploração não são depositados automaticamente. O piloto da Mochila está ativo: 12 slots com stacks padrão de 99, com água fora dos slots. Se a capacidade bloquear um resultado, a restauração não consome recursos e o caldeirão mantém a produção pronta até existir espaço, sem enviar automaticamente ao Village Storage. Filtros, rede de baús, economia e requests continuam fora deste marco. A definição completa está nas **Decisões 84–92** de `DECISIONS.md`, no plano da Mochila e no contrato de acesso a recursos da vila.

Fechamento da Fase C: todas as entradas ativas de itens usam inserção estruturada e preservam a recompensa/origem diante de recusa. O `QuestBoard` continua oculto, mas seu caminho legado já é transacional; água continua fora dos slots; loja e F10 permanecem desativados.

Fase D em andamento: o visual de 12 slots e a seleção/save de sementes foram aprovados manualmente. A barra divide pilhas por `stack_maximo` e mostra ocupação discreta; água fica fora da grade. Slots vazios não respondem nem recebem destaque. Seleção é por tipo de semente e permanece exclusiva com ferramenta após load. A ativação de capacidade foi implementada em 2026-10-01, com validação manual ainda pendente. Overflow legado é carregado sem perda, com slots extras temporários e acesso completo pelo painel rolável do baú; permite completar pilha já ocupada, mas não abrir slots excedentes novos. Não há depósito automático.

Persistência mínima do caldeirão implementada em 2026-10-01, aguardando aprovação manual: `cauldrons` opcional no save v4 guarda mistura, resultado pronto e lote com tempo restante e reservas por origem dos crafts não entregues. Load substitui produção sem repetir consumo/refund; cancelamento bloqueado conserva recibos para nova tentativa, inclusive após reabrir. O contador abstrato legado de golems acompanha o snapshot, sem implementar spawn físico. Saves completos antigos sem produção carregam `IDLE`; produção ausente no arquivo antigo não pode ser recuperada. Os 31 smoke tests do checkpoint anterior passaram, incluindo reconstrução da cena e timers reais. A autorização de continuidade permitiu ativar o piloto, mas não foi registrada como aprovação do teste manual anterior. Nenhum sistema econômico, F10 ou destino novo de resultado foi antecipado.

A auditoria de ativação também protegeu a captura pendente da pesca contra sobrescrita por nova tentativa e perda ao reabrir. O campo opcional `fishing_pending_capture` do save v4 guarda recompensas e bônus existentes, sem criar fila genérica. Payload inválido é recusado antes de alterar estoques; save antigo completo limpa runtime e parcial sem estoques preserva a captura. Load reinicia o lago sem forçar a Vara sobre sementes restauradas. A coleção só avança na entrega integral. `PersonalInventoryPilotSmokeTest` cobre limite ativo por padrão, baú, overflow v3, JSON com cena recriada, recusa, retry único e compatibilidade. Próximo passo: checklist manual do piloto e da persistência do caldeirão, antes de balanceamento/expansão. Consultar as Decisões 88–92 e `PERSONAL_INVENTORY_ARCHITECTURE_PLAN.md`.

Preparação técnica adicional em 2026-10-01, sem mudar gameplay nem marcar teste manual como aprovado: a barra conta pilhas, mas o painel de transferência da Mochila agrupa tipos e preenche até 20 células. Isso pode comunicar capacidade diferente dos 12 slots reais. Próximo ajuste recomendado: coerência visual entre os dois, preservando baú separado, transferência seletiva e excesso legado; ainda não implementado. O plano da Mochila registra baseline e critérios. Dois testes relacionados foram reexecutados e passaram. A Fase E de expansão/balanceamento permanece condicionada à validação manual e às decisões do autor.

Incremento seguinte implementado em 2026-10-01: a recomendação visual acima foi executada. O painel da Mochila usa as mesmas pilhas da barra, 12 posições mínimas em quatro colunas, contador de ocupação e grade rolável para excesso legado. Baú continua agrupado por tipo, sem novo limite. Clicar numa pilha consulta o total do tipo; `Mover tudo` move esse tipo inteiro, não somente a pilha nem a Mochila toda. Callbacks de botões removidos são ignorados. Cinco testes relacionados passaram, incluindo novos cenários no teste do baú. Ajuste visual, piloto e persistência do caldeirão aguardam validação manual; nenhuma expansão, economia ou schema novo foi antecipado. Consultar Decisão 93 e o plano da Mochila.

# 42. ESTADO ATUAL — FASE E DA MOCHILA

Em 2026-10-01, o autor autorizou iniciar e finalizar a Fase E no mesmo ciclo e escolheu **recompensa por marcos de restauração/exploração**. Essa autorização substitui a antiga restrição de executar somente após teste manual; não significa que os testes pendentes foram realizados.

- Capacidade inicial 12; restaurar o primeiro Herbário concede +4, e a primeira coleta bem-sucedida em qualquer ponto do Bosque concede +4. Independentes, uma vez cada, até 20. Nenhuma moeda, material extra, loja, NPC, RNG ou lore nova.
- Ações recusadas não concedem marco. A restauração ainda precisa caber na Mochila antes de consumir ingredientes; liberar espaço e repetir preserva o progresso. Exploração continua na Mochila, sem teleporte ao baú.
- Barra com páginas de até 12 slots e ferramentas abaixo; painel do baú mostra capacidade dinâmica e marcos. Seleção por tipo, transferência seletiva, opacidade e acesso ao excesso legado preservados.
- Pilhas padrão 99 e exceção da água mantidas. Sem limites especiais novos, reordenação/posições persistentes ou versão v5. Resultados da vila continuam na Mochila com proteção no produtor; Village Storage permanece prioridade dos ingredientes e destino físico do golem.
- Campo opcional `inventory.backpack_milestones` no v4 valida IDs conhecidos/únicos antes de mutações, substitui o progresso e não acumula no load. Save completo antigo recupera somente o Herbário explicitamente restaurado no arquivo; coleta antiga do Bosque não era persistida, então requer a próxima coleta. Parcial sem campo preserva runtime. Quantidades excedentes nunca são cortadas.
- Validação: 33/33 smoke tests, incluindo `BackpackExpansionSmokeTest`, mais inspeção de renderização OpenGL dos painéis ampliados e da segunda página. Save pessoal não alterado. Implementação técnica da Fase E concluída; conforto/balanceamento e checklist manual integrado D/E/caldeirão continuam pendentes.

Próximo passo: aceite manual integrado do roteiro no plano da Mochila, seguido apenas dos ajustes concretos encontrados. Não iniciar economia, NPCs, rede de baús ou conteúdo novo automaticamente. Decisão 94 registra os limites deste fechamento.

Fechamento integrado seguinte (2026-10-01): 34/34 testes passaram. A auditoria encontrou que a colheita recusada por Mochila cheia guardava o sorteio apenas em runtime e o perdia ao carregar. Corrigido com `pending_harvest_rewards` opcional nos plots/tiles do save v4; primeiro sorteio sincroniza o bridge, load valida antes de mutações e manual/golem reutilizam os mesmos itens/quantidades. Conclusão limpa a pendência; dados de UI não são persistidos. Arquivos antigos preservam a cultura, mas não recuperam um sorteio ausente. O vertical slice agora verifica expansão/HUD no retorno do Bosque, depósito seletivo e replay do save. Testes pessoais/manuais não foram presumidos aprovados; Decisão 95 registra este incremento.

Polimento visual iniciado por autorização seguinte (2026-10-01): primeiro pacote remove blocos de lotes vazios, mantém terreno abaixo do solo e solo abaixo dos objetos, reutiliza folha limpa verde do caldeirão sem quadriculado, suaviza a grama e harmoniza fundos opacos da Mochila/objetivos com transferência. Baú ganha detalhes geométricos sem colisores novos. Inspeção renderizada inclui solo arado e popup de quantidade; teste existente verifica camadas após frames. Save, limites, layout funcional e economia não mudam. Arte local não relacionada permanece fora do commit. Decisão 96 delimita o checkpoint; aprovação estética manual e roteiro integrado anterior permanecem pendentes. Próximo pacote visual pode tratar composição, bordas e placeholders do golem/lago/portais, sem declarar arte finalizada.

# 43. ESTADO ATUAL — PAISAGISMO E PLACEHOLDERS

Autorização de continuidade em 2026-10-02 executou o segundo pacote visual. `FarmLandscape` usa grama existente como fundo contínuo, com trilhas/clareiras e vegetação baixa abaixo do solo. Nenhuma interação, collider, limite agrícola ou expansão de território. Consulta pontos físicos existentes e usa RNG local determinístico somente para cenografia.

Golem de pedra/musgo substitui o quadrado ciano sem mudar trabalho/vida/sensores; imagem ignora mouse e conserva o nome legado `ColorRect` esperado pela animação. SVGs de lago, arco e raízes distinguem pesca, viagem e corrupção. Estados/áreas clicáveis permanecem; polígonos antigos substituídos foram retirados. Não altera save v4, economia, lore, NPCs ou depósito. Arquivos locais não relacionados continuam preservados.

Capturas OpenGL e D3D12/Forward+ inspecionadas; teste de limpeza confere ausência de interação na cenografia e mouse do golem. Autor ainda precisa validar estética e pesca/cultivo/viagem/purificação/entrega. O aceite anterior não foi presumido.

Risco técnico pré-existente: `Main._ready` deriva `farm_origin` do viewport, enquanto objetos têm posições fixas. Próximo passo técnico recomendado é diagnóstico de coordenadas estáveis/resoluções e compatibilidade dos saves antes de migrar. A auditoria é direção futura, não migração autorizada por este polimento. Consultar Decisão 97 e `ROADMAP.md`.

# 44. ESTADO ATUAL — ORIGEM AGRÍCOLA ESTÁVEL

Após diagnóstico reproduzido em quatro tamanhos de janela, o autor autorizou a correção em 2026-10-02. `FarmOrigin`, marcador explícito de `Main.tscn` em `(680,760)`, substitui o cálculo pelo viewport. Os lotes ficam abaixo do núcleo da vila, sem cruzar caldeirão/entrada do Bosque; o piloto 6×2 não toca a corrupção. Câmera e janela não determinam coordenadas do mundo. Os objetos fixos, limites e regras de interação não foram movidos/expandidos.

Grade inicial/pocket/piloto/descoberta/Herbário usam a mesma origem; conversões de clique/grid respeitam local/global. A pedra sai do interior do pocket para sua borda superior, sem alterar descoberta/lore/save; o Herbário continua lateral. IDs, ordem dos 34 plots, espaçamento, registro, estados, colheitas pendentes, save v4 e fallback v3 permanecem. Nenhum lote antigo é apagado por esta mudança.

Saves antigos não guardam origem ou tamanho de janela: preservam a identidade lógica/cultura, mas são exibidos no layout canônico. Não é possível recuperar exatamente sua posição visual anterior. A exceção transitória para plots existentes permanece; esta etapa não migra o cultivo para autoridade nova nem implementa economia/NPCs/rede de baús.

Novo teste `FarmWorldCoordinatesSmokeTest` verifica resoluções, posição/ordem, bloqueadores com física ativa antes/depois de purificar, culturas prontas/crescendo, terra arada/lote dinâmico, JSON v4/v3/replay, resize/câmera e conversões. Viagem real também verifica resize fora da vila sem deslocar a grade no retorno. Roteiro manual específico em `FARM_LAYOUT_PLAN.md`; os aceites visuais e de Mochila/caldeirão anteriores continuam pendentes. Decisão 98 registra o contrato.

Validação automatizada: 35/35 smoke tests passaram. Importação sem erros e captura de solo/layout inspecionada em OpenGL e D3D12. Hash, tamanho e data do save pessoal inalterados; arquivos locais não relacionados preservados e fora da publicação.

Próximo passo: validar manualmente o layout canônico e save/load em janelas diferentes, seguido apenas dos ajustes concretos encontrados. Não abrir novos sistemas automaticamente.

Continuidade técnica em 2026-10-02: o teste integrado das interações agora encadeia purificação → investigação → arar/plantar/regar os quatro lotes → Herbário, usando os manipuladores reais e navegação/física ativas. Confere consumo, recompensa/marco únicos e reaplicação de JSON em outra cena/resolução. Somente teste/documentação, com recursos e velocidade sintéticos e sem I/O de save pessoal. Não testa picking do mouse ou hitboxes de Control; o aceite manual acima continua pendente, sem presumir aprovação a partir de “pode seguir”.

Checkpoint validado com suíte 35/35 sem erros e reexecução do percurso após conferir o tamanho efetivo dos viewports headless. Hash, tamanho e data do save pessoal permanecem inalterados. Próximo passo continua sendo o roteiro manual de layout/interações, não novos sistemas.

# 45. ESTADO ATUAL — PRIORIDADE DO INPUT COM ENXADA

Auditoria autorizada pela continuidade encontrou/reproduziu clique no baú consumido em `Main._unhandled_input` com enxada ativa, antes do physics picking. Os testes anteriores chamavam diretamente os callbacks e não detectavam essa etapa. A correção reutiliza a consulta física existente: colliders deixam o evento seguir até o objeto/lote; solo livre continua pelo fallback agrícola. Não muda seleção, sensores, navegação, layout, conteúdo ou save.

Regressão no teste integrado verifica o estágio real de `_unhandled_input` sobre baú, collider do caldeirão, lago e lote existente, além de criação/aração em solo livre. Falhou no baú antes da correção. Usa alinhamento câmera/mouse do viewport, não automação de pointer do sistema operacional. Decisão 99 registra contrato e limites; aceite manual continua pendente, especialmente abrir baú/caldeirão com enxada ativa e o roteiro anterior de layout/save/viagem.

Validação deste checkpoint: 35/35 smoke tests sem erros e `git diff --check` limpo. Save pessoal com hash/tamanho/data inalterados; arquivos locais não relacionados fora da publicação.

Aceite manual em 2026-10-03: após receber o roteiro de abrir baú/caldeirão com enxada selecionada, fechar os painéis e arar um lote da grade inicial, o autor respondeu “deu tudo certo”. Prioridade de cliques aprovada nesse escopo. A pendência específica mencionada no parágrafo anterior está concluída; não inferir aprovação de resize/save/load, viagem, restauração ou estética. Próximo passo continua sendo o roteiro integrado anterior; não iniciar sistemas novos automaticamente.

Aceite adicional em 2026-10-03: autor respondeu “aprovado” ao roteiro de arar/plantar/regar um lote inicial, F5, redimensionar/F9 e fechar/reabrir em outro tamanho de janela/carregar. Cultivo e save/load aprovados nas duas situações propostas. Atualiza a pendência histórica de resize/save/load acima; não inclui teste de saves legados, viagem/retorno, purificação/restauração, Mochila ou estética. Próximo teste manual: viajar ao Bosque, redimensionar fora da vila e retornar, conferindo grade e interações. Apenas registro documental, sem código ou nova execução da suíte.

Aceite seguinte em 2026-10-03: autor aprovou o roteiro Bosque → redimensionar janela → retorno à vila → conferir grade/culturas → abrir baú/caldeirão → selecionar vara e pescar. Viagem/retorno e essas interações estão validados no escopo proposto. Entrega física do golem não fazia parte desse roteiro e permanece pendente, assim como purificação/pedra/quatro lotes/Herbário, Mochila/persistência do caldeirão, saves legados e estética. Próximo teste manual: purificação e percurso de restauração. Registro somente documental, sem nova suíte ou mudança de código/save.

Aceite seguinte em 2026-10-03: autor aprovou o roteiro purificação (caso ainda bloqueada) → investigar pedra → arar/plantar/regar cada lote 2×2 → restaurar Herbário, conferindo ausência de travamentos e recompensa única. A pendência desse percurso está concluída no escopo proposto. Não inclui inspeção da área livre abaixo da grade, entrega do golem, saves legados ou os roteiros completos de Mochila/persistência do caldeirão/estética. Próximo teste manual: transporte e depósito físico do golem. Somente documentação, sem nova suíte ou mudança de código/save.

Aceite seguinte em 2026-10-03: autor aprovou deixar uma cultura amadurecer, observar o golem colher/transportar/depositar e colocar o personagem no caminho durante outra entrega, sem perda/duplicação da carga. A pendência de entrega física está concluída; os roteiros funcionais específicos de input, cultivo/resoluções, viagem/retorno, restauração e golem foram aprovados. Não equivale a aceite artístico ou de todos os sistemas. Permanecem inspeção/teste manual da área livre, saves legados e roteiros próprios de Mochila/persistência do caldeirão. Próximo teste: área livre abaixo da grade. Somente documentação, sem nova suíte ou mudança de código/save.

Fechamento dos roteiros funcionais do layout em 2026-10-03: autor aprovou criar um lote livre com enxada imediatamente abaixo do lado direito da grade inicial, plantar e regar sem sobreposição. A pendência específica da área livre está concluída nesse escopo, não em todas as células do piloto. Roteiros propostos de input, cultivo/resoluções, viagem/retorno, restauração, golem e lote livre aprovados. Não equivale a aceite artístico, teste manual de saves legados ou fechamento dos roteiros próprios de Mochila/persistência do caldeirão. Registro somente documental, sem nova suíte/código/save. Não iniciar novos sistemas automaticamente; demais pendências devem receber escopo separado.

Aceite da Mochila em 2026-10-03: autor aprovou o roteiro de conferir marcos/capacidade até 20 no baú, repetir coleta no Bosque sem aumentar além do limite, navegar páginas/selecionar e desselecionar semente na segunda página, transferir itens nos dois sentidos e salvar/reabrir/carregar preservando capacidade/quantidades. Expansão/navegação/transfers e persistência nesse escopo aprovadas. Não inclui os cenários de Mochila cheia, captura/colheita recusada, saves legados ou produção/cancelamento do caldeirão. Checklist no plano da Mochila mantém essas pendências; próximo roteiro manual é produção em andamento e retomada/cancelamento. Registro documental, sem nova suíte/código/save.

Aceite seguinte em 2026-10-03: autor aprovou produção em andamento do caldeirão → salvar/reabrir/carregar → conclusão com resultado/consumo únicos; em outra produção retomada, cancelar devolvendo reservas não utilizadas às origens sem duplicação. Persistência/cancelamento aprovados no roteiro proposto. Não abrange falta de espaço durante entrega/refund, captura/colheita recusada, saves legados ou aceite visual. Próxima etapa de validação: casos-limite de capacidade e recompensas no checklist da Mochila, mantendo aprovação artística separada. D/E já implementadas; não inventar Fase F nem iniciar economia/NPCs/rede de baús. Registro somente documental, sem nova suíte ou alteração de código/save.

Aceite seguinte em 2026-10-03: autor aprovou colher com Mochila cheia e resultado sem espaço nas pilhas → aviso/cultura mantida → salvar/reabrir/carregar → depositar no baú → colher novamente sem perda/duplicação. Esse caso-limite está aprovado; captura pendente durante sincronia, bloqueio de entrega/cancelamento do caldeirão por capacidade e saves legados não foram incluídos. Próxima revisão: aceite visual do estado atual; solicitar captura atual/feedback, sem presumir aprovação artística nem iniciar nova infraestrutura/gameplay. Somente documentação, sem nova suíte/código/save.

# 46. ESTADO ATUAL — SEGUNDA EXPEDIÇÃO / CLAREIRA RECUPERÁVEL

Atualização humana posterior: autor escolheu **novo conteúdo: definir recorte de gameplay/progressão**, recebeu proposta de expedição/restauração/recompensa agrícola e autorizou iniciar a grande fase. Isso substitui a prioridade anterior de aguardar revisão visual, sem representar aprovação artística ou autorização para outros sistemas.

Implementado no Bosque existente: investigar canteiro seco → aprender Mistura Restauradora → reunir carvão → preparar duas misturas no caldeirão/Livro da vila → levar na Mochila → restaurar → aprender Infusão da Clareira. Novo site usa apenas recursos pessoais; o Herbário e o acesso direto ao Storage na vila permanecem intactos. Receita agrícola produz Poção de Crescimento já funcional, preservando caminho sazonal anterior. Custos/tempos/efeito/roteiro detalhados no plano do Bosque e Decisão 100.

Uma fonte renovável fornece 2 carvões a cada 45 segundos de sessão para evitar bloqueio por recursos gastos; quatro fontes originais continuam únicas e agora persistem. Recusa por capacidade não esgota nenhuma fonte. `GroveExpedition` é estado específico de flags/fontes, não framework genérico de quests ou aquisição. Objetivo opaco minimizável, com contador da Mochila, fica oculto em modais e desaparece ao restaurar. Nomes funcionais/arte de apoio não decidem lore final. Preço/venda econômica não foram definidos.

Save v4 opcionalmente registra progresso do recorte e intervalo de ausência até salvar. F5 no Bosque captura HOME em cache (lotes/baú/produtores/purificação/Herbário), não a árvore externa vazia; F9 externo volta à entrada da vila e aplica o intervalo da sessão após restaurar recursos/produtores. Não persistir posição externa, simular tempo com jogo fechado ou logística offline do golem. Saves completos v3/v4 anteriores começam clareira intacta; parciais preservam runtime. Pré-validação impede alteração de região/estoque com payload novo inválido. Regressão reproduziu/corrigiu poção cujo tempo reduzido não entrava no snapshot agrícola: FarmPlot notifica alteração e save reconstrói o índice atual.

`GroveRestorationSliceSmokeTest` tem 72 verificações de navegação, Livro, duplicação de ingredientes, capacidade, origem pessoal, recompensa única, efeito no cultivo, JSON em cenas recriadas, save externo de produção/catch-up/cancelamento, inválidos e compatibilidade. A inspeção também reproduziu/corrigiu fechamento do Livro ocultando toda a HUD no host alternativo: apenas o PopupLayer específico do caldeirão é ocultado; regressão cobre os dois hosts. Testes fazem somente snapshots em memória, nunca I/O do save pessoal. Inspeção OpenGL em 1280×720 e D3D12/Forward+ em 1920×1080 é técnica, não teste de picking do sistema operacional nem aceite artístico. Em 1280, a HUD histórica da vila ainda pode sobrepor objetivos iniciais; a nova tarefa usa painel inferior compacto e não reformula toda a HUD nesta fase.

Fechamento técnico: importação sem erros, suíte 36/36 aprovada e `git diff --check` limpo. Hash/tamanho/data do save pessoal permanecem idênticos ao baseline; arte local e UID não relacionados preservados e excluídos da publicação.

Aceite manual parcial em 2026-10-03: autor respondeu “validado, pode continuar” ao roteiro de investigar canteiro/aprender receita, minimizar/expandir objetivo, coletar 4 carvões, voltar e produzir duas misturas pelo Livro, mantendo a HUD acessível. Descoberta/coleta/preparo aprovados nesse escopo. Não inferir aprovação de renovação cronometrada, capacidade cheia, restauração, efeito agrícola, persistência ou estética. Atualização somente documental, sem nova suíte ou alteração de código/save.

Aceite seguinte em 2026-10-03: autor validou o roteiro de retornar com duas misturas na Mochila, restaurar com consumo único/canteiro verde/objetivo oculto, repetir clique sem nova recompensa/consumo, produzir Infusão da Clareira e aplicar a poção numa cultura crescendo sem ferramenta. Restauração/recompensa/efeito agrícola aprovados nesse escopo; save/load, duração/balanceamento e arte continuam separados. Registro somente documental, sem nova suíte/código/save.

Aceite seguinte em 2026-10-03: autor aprovou F5 no Bosque restaurado → F9 retornando à vila com itens/receita preservados → revisita mantendo canteiro verde/objetivo oculto, sem consumo/recompensa repetidos → fechar/reabrir/carregar e repetir a conferência. Persistência após restauração aprovada no roteiro proposto. Não inclui produção em viagem, save anterior à restauração, capacidade cheia, duração/balanceamento ou estética. Apenas documentação, sem nova suíte/código ou acesso ao save pessoal.

Próximo passo: produção em viagem (passo 7), com conclusão e cancelamento em lotes separados. Escolher quantidade que permita viajar/salvar ainda em andamento, dentro dos recursos disponíveis; não alterar timers nem forçar via F10/save. Não apagar progresso para repetir descoberta; save anterior à restauração continua sem aceite manual. Cronometrar/avaliar conforto; hipótese de 20–30 minutos ainda não comprovada e não deve ser anunciada como duração entregue. Não alongar timers artificialmente nem expandir conteúdo sem recorte aprovado. Persistem, separadamente, captura pendente, entrega/refund do caldeirão por capacidade, saves legados reais e arte geral. Publicar como checkpoint testado automaticamente enquanto playtest estiver pendente.

# 47. ESTADO ATUAL — CONTINUIDADE COM TESTES MANUAIS ADIADOS / HUD RESPONSIVA

Diretriz humana mais recente: o autor não conseguirá fazer testes agora e autorizou seguir construindo o jogo, com checklist depois. Isso substitui o gate manual imediato do final de §46, mas não aprova seus casos pendentes nem amplia automaticamente o conteúdo. Continuar em incrementos delimitados, verificar automaticamente/visualmente quando possível, registrar limitações e publicar checkpoints no GitHub. Não pedir teste imediato a cada fechamento.

Primeiro incremento: corrigida sobreposição da Mochila/ferramentas com objetivos em janelas menores. `HUDLayout` ajusta largura e tamanho de página (até 12), empilha o conjunto em janela estreita e reposiciona o Caderno abaixo. Ferramentas usam ícone/número com tooltip quando nomes completos não cabem; `UI` mantém esse modo durante seus refreshes. Objetivos mantêm arraste/minimização e canto superior direito inicial, com botão acompanhando o painel e posição contida no viewport. Resize durante visita ao Bosque é aplicado ao reanexar HOME em cache. Posição dos painéis continua runtime-only.

Capacidade lógica 12/16/20, stacks, quantidades, seleção exclusiva semente/ferramenta e save v4 permanecem intactos. Páginas não escondem excesso legado; mudar tamanho preserva o primeiro índice anteriormente visível e redução de conteúdo limita a página. Não implementar economia, NPCs, armazenamento em rede ou lore nesse ajuste.

Validação: baseline sem `HUDLayout` reproduziu sobreposição em 1280×720. `HUDResponsiveLayoutSmokeTest` passou com 230 verificações de geometria de cada botão/slot, 25 pilhas legadas navegáveis, estoque/capacidade/seleção, resize, objetivos minimizados/arrastados e viagem real com HOME em cache. Resoluções: 800×720, 1024×768, 1280×720, 1920×1080 e 2560×1440. Suíte completa 37/37, importação sem erros e renderização técnica OpenGL/D3D12 inspecionada. Testes usam dados isolados; hash/tamanho/data do save pessoal permanecem iguais. Não prometer usabilidade abaixo dos tamanhos testados nem confundir sinais/geometria com picking do sistema operacional ou aceite artístico.

Fila manual adiada para checklist futuro: produção em viagem com conclusão/cancelamento em lotes separados; save anterior à restauração sem apagar progresso; renovação cronometrada do carvão e recusa por capacidade; captura pendente; entrega/refund do caldeirão bloqueados por espaço; saves legados reais; resize/paginação/ferramentas compactas/arraste/minimização; conforto, duração, balanceamento e arte. Preservar aceites anteriores sem exigir repetição total. Roteiros detalhados continuam nos planos de Mochila/Bosque.

Próximo incremento recomendado: analisar e adaptar legibilidade/layout dos painéis de caldeirão e Livro em janelas menores, sem modificar receitas/produção/estoques ou persistência. Novas expansões de gameplay exigem recorte próprio; a impossibilidade de testar não justifica inventar sistemas.

# 48. ESTADO ATUAL — CALDEIRÃO E LIVRO RESPONSIVOS

Autor autorizou seguir com o próximo incremento. `PopupBackground` mantém o contrato de captura de clique/drop e passa a apresentar o caldeirão com fundo opaco, slots delineados e controles dentro da borda. A inspeção em 800×600 identificou Mochila encoberta: altura compacta de 320 e posição abaixo da barra nas janelas estreitas deixam os ingredientes acessíveis. Layout normal mantém 420 de altura. Não apagar assets antigos nem mudar DropSlot/receitas/produção.

Livro conserva caminhos de nós e callbacks; `RightPanel` é agora ScrollContainer, sem rolagem horizontal, com acompanhamento de foco. Detalhes/títulos quebram linha, catálogo permanece na lista separada e cabeçalho/Fechar ficam acessíveis. Selecionar outra receita volta ao topo dos detalhes. O tamanho adapta-se ao viewport; arraste e posição runtime-only permanecem, com contenção no resize/reabertura. Fundo opaco usa a paleta existente, sem tema global/framework novo.

`AlchemyDialogLayoutSmokeTest` passou com 131 verificações: cinco resoluções (800×600, 800×720, 1024×768, 1280×720 e 1920×1080), controles dentro dos painéis, Mochila acessível, catálogo inteiro, descrição longa sintética e acesso à ação por rolagem, estoque intacto durante layout, drop/captura do fundo, troca popup → Livro, lote de duas unidades com quantidade digitada, consumo prioritário do baú/restituição após cancelar, fechamento nos dois hosts sem ocultar HUD. Renderização OpenGL/D3D12 conferida. Testes usam recursos isolados, sem I/O do save pessoal; custos, timers, gameplay/save não foram alterados.

Fechamento técnico: suíte completa 38/38, importação sem erros e `git diff --check` limpo. Hash/tamanho/data do save pessoal idênticos ao baseline; arquivos locais de arte e UID não relacionados ficam fora da publicação.

Checklist manual adiado deste pacote: abrir caldeirão com Mochila acessível, arrastar dois ingredientes e misturar, navegar/rolar Livro/digitar quantidade, produzir/cancelar, fechar/reabrir, arrastar/redimensionar painéis em janela menor. Não afirmar picking real, conforto ou aceite artístico a partir dos sinais/retângulos; tamanhos abaixo de 800×600 não têm validação de usabilidade. Pendências da expedição/capacidade de §47 continuam separadas.

Próximo incremento recomendado: melhorar comunicação dos estados existentes de produção, resultado pronto e falta de espaço no caldeirão, preservando destino/consumo/refund e save. Não ampliar conteúdo/economia/NPCs automaticamente.

# 49. ESTADO ATUAL — AVISOS PERSISTENTES DO CALDEIRÃO

Autor autorizou o próximo incremento, mantendo a diretriz de testes manuais adiados. Painel de lote antes situado no mundo passa a CanvasLayer, com fundo opaco e posição inferior direita contida no viewport. Reutiliza progress bar/cancelamento existentes; apresenta também produção manual e resultado pronto. Câmera não o desloca; resize e reanexação da HOME em cache atualizam geometria.

`get_production_feedback` é projeção somente leitura: mistura em preparo com tempo/destino, resultado pronto com quantidade e orientação de capacidade/recolhimento, lote ativo com quantidade por preparo/contagem entregue/tempo, lote pausado com recolhimento/retomada e cancelamento pendente com reservas preservadas/nova tentativa. Golem legado utiliza orientação de capacidade própria, não da Mochila. Produção, entrega, cancelamento, timers, origem dos ingredientes, reservas e campos de save não mudam. Não há retry automático ou novos controles de domínio.

`CauldronFeedbackSmokeTest` passou com 87 verificações em 1280×720, 800×720 e 1024×768: estados e JSON em memória, estoques/save invariáveis durante apresentação, câmera/resize/reanexação, resultado bloqueado e entrega única após liberar espaço, lote com resultado por preparo e cancelamento/restituição às origens, incluindo cancelamento pendente. Suíte completa 39/39, importação sem erros e renderização técnica OpenGL/D3D12 conferidas. Avisos de restituição sem espaço são esperados no fixture. Testes isolados não fazem I/O do save pessoal; hash/tamanho/data permanecem iguais ao baseline.

Checklist manual adiado: conferir avisos durante produção e ao terminar, depositar no baú para liberar espaço e recolher/retomar, repetir cancelamento bloqueado, mover câmera/redimensionar/retornar do Bosque. Não converter regressão por sinais/geometria em aceite de picking real, conforto, arte ou balanceamento; demais pendências de §47–48 seguem separadas. Próximo incremento recomendado: revisar/uniformizar comunicação de capacidade na pesca/coleta existentes, sem ampliar recursos, recompensas ou sistemas.

# 50. ESTADO ATUAL — AVISOS DE CAPACIDADE NA PESCA E COLETA

Continuidade autorizada, sem exigir playtest imediato. Coleta recusada mostra quantidade/item, informa que o recurso permanece no ponto e orienta depositar no Baú da Vila/voltar. Aviso tem quatro segundos de leitura antes da saída; textos de sucesso conservam duração anterior. Ponto, recompensa, marco e persistência só mudam no fluxo bem-sucedido existente.

Lago distingue recusa antes da sincronia (espaço para possíveis resultados, sem captura prometida) de captura já preservada. Esta lista todos os itens/quantidades e orienta depósito para entrega automática integral. Texto é projeção somente leitura dos campos existentes. Avisos de capacidade são transformados do mundo para tela, contidos no viewport e não bloqueiam cliques; demais textos flutuantes conservam seu comportamento. Painel da pesca passa a fundo opaco na paleta existente, com instruções/resultado quebrando linha e geometria recalculada após texto/resize para manter Fechar acessível.

Não muda preflight da pesca, atomicidade da entrega, coleção apenas após recebimento, proteção contra nova tentativa sobrescrever pendência, receita/recompensa, capacidade, destino ou schema de save. Captura continua entregue automaticamente pelo fluxo existente quando inativa e com espaço; recurso externo continua exigindo retorno/coleta, sem teleporte ao Storage.

`CollectionCapacityFeedbackSmokeTest`: 18 verificações de fonte/estoque preservados, duração, pré-recusa sem abrir sincronia, captura dupla sem coleção prematura, textos/item/quantidade, painel opaco/contido em 800×600, 1024×768 e 1280×720, JSON e recusa de sobrescrita, depósito → entrega integral única e coleta única. Suíte completa 40/40, importação sem erros e inspeção OpenGL/D3D12. Fixture isolado, sem I/O do save pessoal; hash/tamanho/data iguais ao baseline.

Manual adiado: leitura dos avisos no Bosque/lago, depósito/retorno para coletar, espaço ocupado durante sincronia → fechar/save/load → liberar espaço e conferir entrega única. Picking, conforto e direção artística permanecem pendentes; aceites prévios não são revogados. Próximo incremento recomendado: clareza dos requisitos/recusas da restauração existente (Herbário e Clareira), diferenciando Mochila e Storage local, sem novos projetos/recompensas/sistemas.

# 51. ESTADO ATUAL — REQUISITOS E RECUSAS DE RESTAURAÇÃO

Autor autorizou o recorte recomendado. Herbário mostra disponível/necessário somando baú e Mochila; recusa informa faltantes e consumo prioritário do Storage/complemento pessoal. Se a recompensa não couber, identifica item/quantidade e orienta depositar/tentar de novo, sem consumir custos. Aviso novo substitui anterior para evitar textos empilhados em cliques repetidos. Contadores consultam estados atuais, também após load, sem consumir ou alterar progresso.

Clareira mantém descoberta gratuita e mostra misturas disponíveis/necessárias apenas na Mochila. Explica que Baú da Vila não é usado no local externo; recusa orienta preparar faltantes no caldeirão e informa preservação da carga. Antes de descobrir continua apenas “Investigar clareira”; restaurada conserva identificação sem requisitos obsoletos. Custos, purificação, reservas/transações, recompensas/marcos, aprendizagem e campos de save não mudam.

Textos contrastados, quebrados e com espaço acima dos objetos. Avisos do Herbário usam conversão mundo → tela e quatro segundos de leitura do helper existente; retorno do Label permite substituição local, sem infraestrutura de fila. `RestorationFeedbackSmokeTest`: 18 verificações de contadores/origens, consulta invariável, recusa/capacidade, substituição do aviso, JSON e restaurações/recompensas únicas. Suíte completa 41/41, importação sem erros e OpenGL/D3D12 conferidos com fixture sintético. Save pessoal intacto por hash/tamanho/data; arquivos locais não relacionados excluídos do checkpoint.

Checklist manual adiado: ler requisitos no mapa, mudar estoques pelo baú/conferir contadores, recusar por falta/espaço e retomar, visitar a Clareira com misturas no baú versus Mochila. Sinais/renderização técnica não aprovam picking real, conforto ou arte; pendências de §47–50 continuam próprias. Próximo incremento recomendado: orientação contextual do objetivo da expedição conforme materiais e carga, sem novas quests/etapas/recompensas.

# 52. ESTADO ATUAL — ORIENTAÇÃO CONTEXTUAL DA EXPEDIÇÃO

Autor autorizou o recorte recomendado. Objetivo apresenta próxima ação e contador da Mochila, em vez de repetir todos os passos: reunir carvão que falta, preparar só misturas faltantes, retirar quantidade necessária do baú quando disponível, aguardar produção, recolher resultado pronto/bloqueado ou resolver cancelamento pendente. Com duas misturas carregadas, orienta levar ao Bosque ou interagir com a Clareira conforme região. Antes da descoberta e após conclusão, texto vazio; visibilidade/minimização/modal seguem regras existentes.

Texto consulta estoques e snapshot de produção da HOME atual ou preservada em cache somente para informação. Não transfere recursos, avança timers, altera fontes/receitas/progresso nem cria automação/fila/quest. Contagem de carvão pode incluir Storage para orientar retorno/preparo; consumo externo continua estritamente pessoal. Custo de 2 carvões por mistura, produção, recompensa e schema de save não mudam.

`GroveObjectiveGuidanceSmokeTest`: 37 verificações de orientação em estados de material/carga/baú, produção manual/lote/pronto/bloqueado/cancelamento pendente, consulta sem mutação, viagem real/HOME em cache, JSON, minimização e contenção em 800×720, 1024×768 e 1280×720. Suíte 42/42, importação sem erros e renderização técnica OpenGL/D3D12. Warnings de refund bloqueado são esperados no fixture; save pessoal intacto por hash/tamanho/data.

Manual adiado: transições de orientação em jogo com materiais reais, depósito/retirada, preparo/conclusão/bloqueio/cancelamento, viagem e minimização. Não presumir picking, conforto, arte ou coexistência global de painéis; pendências de §47–51 continuam separadas. Próximo incremento recomendado: conferir coexistência de objetivos/produção/HUD e corrigir sobreposições concretas, sem ampliar gameplay.

# 53. ESTADO ATUAL — COEXISTÊNCIA DOS PAINÉIS DE OBJETIVOS E PRODUÇÃO

Autor autorizou o recorte recomendado, com playtests adiados. Baseline reproduziu objetivo da Clareira sobre o aviso do caldeirão. Helpers locais no HUDLayout buscam posições livres próximas ao canto inferior direito, considerando Mochila, ferramentas, botões visíveis do Caderno e objetivos iniciais arrastados. Produção tem prioridade; tracker considera também o aviso. Objetivos iniciais continuam na posição escolhida pelo jogador, com contenção já existente, sem deslocamento imposto pelos outros avisos.

VBox legado do Caderno conserva altura vazia de lojas removidas; somente filhos visíveis reservam espaço. Tracker usa altura natural conforme texto e minimização. Geometria/visibilidade/resize disparam novo cálculo; refresh contextual existente permanece. Não há framework de janelas, novos controles de domínio, mudança de timers/receitas/consumo/reservas/destino/progressão ou schema de save.

`HUDPanelCoexistenceSmokeTest`: 305 verificações em cinco resoluções de 800×720 a 2560×1440, resultado pronto, mistura em preparo, lote ativo, lote pausado por capacidade e cancelamento pendente. Confere contenção, não sobreposição, botão de cancelar dentro do painel, reação ao arraste sem refresh forçado, minimização e snapshots invariáveis de Mochila/baú/produção/progresso. Warnings de refund bloqueado são esperados no cenário sintético isolado.

Suíte completa 43/43, importação sem erros e inspeção técnica OpenGL/D3D12. Save pessoal intacto por hash/tamanho/data. Avisos transitórios de ações continuam fora do escopo da coordenação dos painéis persistentes; não afirmar ausência de toda sobreposição visual do jogo. Arquivos locais de arte/UID anteriores preservados e excluídos do checkpoint.

Checklist manual adiado: leitura conjunta no mapa, minimizar e arrastar objetivos, redimensionar com produção ativa e interagir com baú/caldeirão sem captura indevida de cliques. Demais pendências de §47–52 seguem separadas. Geometria/renderização não validam picking real, conforto, arte ou posições arbitrárias que eliminem todo espaço livre; resoluções abaixo de 800×720 não recebem aceite. Próximo incremento recomendado: consolidar checklist integrado e auditar riscos técnicos restantes do recorte atual, sem iniciar novos sistemas/conteúdo automaticamente.

# 54. ESTADO ATUAL — CHECKLIST INTEGRADO E AUDITORIA DE RISCOS

Autor autorizou o recorte recomendado. ROADMAP centraliza a fila manual com IDs, pré-condições, esperado e registro aprovado/falhou/não executado: interface/interação, produção em viagem/renovação, capacidade/persistência condicionais e arte/ritmo. Aceites anteriores de Mochila, produção comum, colheita recusada, layout, interação com enxada e percurso/restauração/persistência da Clareira concluída continuam válidos nos seus escopos. Não apagar progresso, editar save, usar F10 ou fabricar estados extremos; sem pré-condição disponível, manter caso não executado. Autor continua indisponível para playtest imediato.

Auditoria somente leitura delimitada: SaveManager abre o arquivo principal diretamente com WRITE, sem temporário/backup/verificação posterior. Risco inferido de perda numa interrupção/falha, sem ocorrência reproduzida no save pessoal; regressões dev atuais usam snapshots/JSON e não exercitam save/load em disco. Caldeirão ainda envia aviso temporário pelo helper legado sem contenção de texto/coordenadas; painel persistente não cobre esse caminho. Busca de layout retorna posição preferida quando não cabe nenhuma candidata; não promete arrastes extremos ou resolução irrestrita. Riscos e próximos recortes registrados na tabela do ROADMAP; não é auditoria exaustiva nem constatação de falha em todos os fluxos normais.

Etapa somente documental: nenhum código, recurso, save ou gameplay alterado. Revisão de diff, links locais e rastreabilidade dos casos aos planos/código; sem nova execução de suíte. Resultado automatizado vigente permanece 43/43 do checkpoint `3d2240f`, sem converter em aprovação manual. README diferencia estado operacional de checkpoints históricos e planos de Mochila/Bosque apontam para a fila única.

Próximo incremento recomendado: proteger gravação do save contra falhas/interrupções com arquivo intermediário/cópia recuperável e testes de I/O em ambiente isolado. Preservar schema v3/v4, gameplay e save pessoal; não criar slots/cloud/migração nem recuperação silenciosa. Não implementar ainda nesta auditoria; autorização de continuidade deve se referir ao recorte recomendado. Avisos temporários/layout extremo e playtest continuam posteriores e separados.

# 55. ESTADO ATUAL — GRAVAÇÃO PROTEGIDA DO SAVE

Autor autorizou o recorte recomendado. SaveManager utiliza ProtectedSaveFile: grava `.tmp`, flush e leitura conferem texto exato/objeto JSON; principal anterior é copiado/conferido em `.bak.tmp` e promovido a `.bak` antes de substituir principal. Primeiro save não inventa backup. Falhas retornam false com erro visível; principal inválido como JSON não sobrescreve backup. Temporários órfãos não são carregados e nova tentativa prepara novo temporário. Não prometer atomicidade/durabilidade absoluta em falha física de disco/energia.

Load continua explicitamente do principal com preflight de domínio existente, sem carregar backup/temporário silenciosamente. Erros indicam backup quando existe, para recuperação assistida sem selecionar progresso antigo pelo jogador. Novo jogo explicitamente solicitado limpa principal/backup/temporários conhecidos. Schema v3/v4, snapshots, reservas/timers/estoques/progressão e regras do jogo não mudam; helper verifica integridade JSON, não substitui validação semântica do load.

Regressão ProtectedSaveFileSmokeTest com 19 verificações: arquivos reais, Unicode/v3/v4, primeiro save/substituição/backup, falhas simuladas de promoção, bloqueios reais de temporário/backup, diretório ausente, temporário incompleto/órfão, principal inválido/backup preservado e save/load/recusa com aviso/limpeza reais. Teste exige user:// sob Builds/QA e aborta antes de I/O fora do sandbox. Aviso de falha sintética é esperado, não erro de regressão.

Fechamento: suíte completa 44/44, importação sem erros e aviso de falha renderizado/inspecionado em OpenGL. Hash/tamanho/data do save pessoal idênticos ao baseline; arquivos locais não relacionados preservados/excluídos da publicação. SAVE-02 acrescentado ao checklist integrado, mantendo manual adiado.

Manual adiado: save normal duas vezes/reabertura/load e progresso preservado; aviso só se ocorrer naturalmente. Nunca forçar falha de disco/encerramento na gravação do save pessoal. Checklist integrado de §54/ROADMAP continua pendente e aceites anteriores preservados. Próximo recorte recomendado: reproduzir/corrigir avisos temporários legados do caldeirão com câmera/resize, sem mudar produção/refund ou implementar fila global.

# 56. ESTADO ATUAL — AVISOS TEMPORÁRIOS DO CALDEIRÃO

Autor autorizou o recorte recomendado. Baseline reproduziu aviso fora da tela. Helper local converte anchor do mundo por transform com canvas e reutiliza criar_texto_flutuante com quatro segundos de leitura/quebra/contorno/input ignorado. CauldronFeedbackLabel contém largura/posição durante resize e procura espaço quando toca HUD, produção ou tracker, reservando altura para saída animada. Aviso novo oculta/remove o anterior; sem fila global ou alteração do helper dos demais sistemas.

Sucesso manual, lote pronto, cancelamento concluído e recusa de resultado usam mesmo caminho; golem mantém limite próprio, sem confundir com Mochila. Produção, receitas/timers/estoques/reservas/entrega/refund/schema de save permanecem. Não prometer ausência de colisão quando não existe espaço livre nem mover/minimizar objetivos do jogador automaticamente.

CauldronTemporaryFeedbackSmokeTest: 33 verificações em quatro resoluções de 800×600 a 1920×1080, três offsets de câmera com scroll efetivamente atualizado, resize com aviso ativo, substituição, leitura/remoção, mouse/quebra, distinção de limite e snapshots de produção/Mochila/Storage invariáveis. Renderização técnica OpenGL conferida. Manual UI-05 acrescentado ao checklist; sem forçar estados de capacidade no save pessoal, sem aprovação artística/picking real presumida.

Fechamento técnico: suíte 45/45, retestes finais de avisos (33), produção (87) e coexistência (305), importação sem erros e inspeção OpenGL. Hash/tamanho/data do save pessoal intactos; warnings de refund bloqueado são esperados nos fixtures e arquivos locais não relacionados ficam fora da publicação.

Próximo recorte recomendado: revisar fallback quando objetivos/painéis eliminam todo espaço livre, preservando acesso a controles e escolha de minimização do jogador, sem gerenciador global de janelas ou nova progressão. Demais casos manuais e aceites anteriores continuam separados.

# 57. ESTADO ATUAL — FALLBACK COM HUD SATURADA

Autor autorizou o recorte recomendado. Baseline analítico do fixture: canto preferido cobria região protegida mesmo havendo alternativa menos sobreposta, porque toda tela era considerada ocupada. Busca ainda prefere candidatas livres; sem nenhuma, prioriza menor área sobre controles, depois sobreposição restante e distância. Protege botões visíveis/habilitados e slots da Mochila; tracker/aviso protegem cancelar produção. Nenhum gerenciador global, mudança de gameplay/save, movimento ou minimização automática dos objetivos.

Regressão HUDCrowdedFallbackSmokeTest com 28 verificações em 800×720, 1024×768 e 1280×720: fixtures saturados, redução evitável, limite inevitável, determinismo e arrastes com lote real ativo. Minimizar/cancelar descobertos nos casos integrados e snapshots invariáveis. Renderização OpenGL inspecionada: conteúdo pode se sobrepor no extremo, mas controles testados ficam expostos. Não prometer otimização contínua, zero colisão universal ou picking/conforto manual aprovado.

Fechamento técnico: suíte 46/46 e importação sem erros. UI-06 fica no checklist manual adiado. Save pessoal preservado por hash/tamanho/data; arquivos locais não relacionados excluídos da publicação. Próximo recorte recomendado: preparar checkpoint jogável e revisar o checklist consolidado antes de ampliar conteúdo. Demais aceites/pendências continuam separados.

# 58. ESTADO ATUAL — CHECKPOINT JOGÁVEL PÓS-V0

Preparação autorizada de playtest local Windows. Exportador limpo existente reutilizado com preset separado, suíte opcional e auditoria do PCK. Checkout somente do commit exclui mudanças/arte local; filtro remove dev/docs/tools/Builds do pacote. Transformação exclusiva do projeto temporário define `CauldronCropsPlaytest`, impedindo acesso ao save habitual mesmo pelo EXE direto. Projeto de desenvolvimento, schema e gameplay permanecem intactos; progresso não é copiado automaticamente.

Pacote local em Builds/Playtest/PostV0-20261003 inclui EXE/PCK, launcher OpenGL de compatibilidade, instruções, manifesto de commit/hashes, logs e somente checklist integrado de 16 casos. V0 aprovada permanece fechada; checkpoint pós-V0 e todos os casos condicionais de ROADMAP têm aceites separados. Não exigir teste imediato enquanto autor estiver indisponível.

Fechamento: fonte c43abae, suíte 46/46 em checkout limpo, auditoria do PCK e startup headless/OpenGL de 120 frames sem erros. O guard de ProtectedSaveFileSmokeTest recusou corretamente o primeiro caminho externo ao QA do checkout; runner corrigido. Exportação identificou preload de teste interno na UI; removido da abertura normal e carregado somente na ação dev explícita do editor, sem reativar F10. Save pessoal idêntico por hash/tamanho/data. Arte local, UID preexistente, saves/QA/binários não publicados. Build não equivale a playthrough/aprovação manual.

Próximo recorte recomendado: propor bloco delimitado de gameplay/progressão, com objetivos, aquisição determinística e critérios de aceite antes da implementação. Não ampliar economia, NPCs, lore definitiva ou mundo por consequência automática deste fechamento. Fila manual continua pendente, sem bloquear a elaboração da proposta.
