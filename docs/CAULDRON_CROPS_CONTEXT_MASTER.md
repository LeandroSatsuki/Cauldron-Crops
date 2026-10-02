# CAULDRON CROPS — CONTEXTO MESTRE DO PROJETO

> Documento de onboarding para agentes de IA/Codex.
>
> Objetivo: permitir que uma nova sessão compreenda rapidamente **o que Cauldron Crops pretende ser**, **o estado atual do protótipo**, **quais decisões já estão encaminhadas**, **quais continuam abertas** e **como colaborar com o autor do projeto**.
>
> Este documento **não é uma especificação imutável**. O jogo ainda está sendo descoberto durante o desenvolvimento. Quando houver conflito entre este documento e uma decisão humana mais recente, a decisão humana prevalece.

Estado operacional mais recente (2026-10-02): Fase E da Mochila concluída tecnicamente e dois pacotes de polimento visual implementados. Consultar §42–43, `ROADMAP.md` e `PERSONAL_INVENTORY_ARCHITECTURE_PLAN.md`. Relatos anteriores são históricos; testes manuais pendentes não foram presumidos aprovados.

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
