# CAULDRON CROPS — PLANO DE EXECUÇÃO DA V0

> Documento operacional para o Codex.
>
> Objetivo: transformar a visão atual de Cauldron Crops em uma primeira versão jogável coerente, pequena e testável, sem perder a identidade do projeto nem iniciar uma reescrita desnecessária.
>
> Ler junto de:
>
> 1. `AGENTS.md`
> 2. `docs/CAULDRON_CROPS_CONTEXT_MASTER.md`
> 3. `README.md`
> 4. `docs/DECISIONS.md`
> 5. documentação específica do sistema em alteração.
>
> Quando documentação histórica e código divergirem, investigar antes de assumir qual está correto.
> Uma decisão humana mais recente sempre prevalece.

---

# 1. MISSÃO DA V0

A V0 não precisa representar tudo que Cauldron Crops poderá ser.

Ela precisa provar que o **coração do jogo funciona**.

Uma sessão inicial deve começar a comunicar:

- cultivo como base produtiva;
- caldeirão como centro mágico e de progressão;
- corrupção como obstáculo e expansão do mundo;
- golems como criaturas físicas que ajudam a fazenda;
- atividades opcionais enquanto cultivos crescem;
- pequenas descobertas e eventos;
- sensação de que o mundo possui mais possibilidades do que as imediatamente visíveis.

A V0 deve permitir responder positivamente a perguntas como:

1. Quero descobrir outra receita?
2. Quero purificar aquela área para ver o que existe lá?
3. É interessante observar o golem trabalhando?
4. Existe algo para fazer enquanto uma plantação demora?
5. Apareceu alguma coisa inesperada?
6. Tenho vontade de voltar amanhã?

---

# 2. FILOSOFIA CENTRAL

## Magia é infraestrutura, não decoração

O caldeirão, a alquimia, os espíritos, as plantas e a corrupção fazem parte do funcionamento do mundo.

## Ausência não pune; presença recompensa

A fazenda deve continuar sendo útil quando o jogador não está ativo.

Quando decide permanecer ativo, ele encontra:

- maior eficiência;
- eventos;
- descobertas;
- oportunidades;
- exploração;
- otimização;
- interação.

## Especialização recompensa profundidade; diversidade recompensa flexibilidade

Quem ama pesca pode construir uma economia extremamente eficiente em pesca.

Quem prefere várias atividades ganha facilidade para:

- quests;
- receitas;
- eventos;
- coleções;
- demandas variadas.

Nenhum estilo é incorreto.

## Eventos são convites, não obrigações

Eventos quebram monotonia e criam curiosidade.

Ignorá-los não deve punir o jogador.

## O jogador entra com um plano; o mundo oferece motivos para abandoná-lo

Uma boa sessão pode terminar fazendo algo completamente diferente do objetivo inicial.

## Golems são criaturas, não máquinas

Automação deve ser visível.

O jogador deve ver:

- golem caminhando;
- colhendo;
- carregando;
- depositando;
- descansando;
- futuramente colaborando entre si.

Evitar reduzir automação a um menu com “produção automática: ON”.

---

# 3. CENA-BÚSSOLA DA AUTOMAÇÃO

Uma imagem conceitual deve orientar decisões futuras:

> Um pequeno golem alquimista está quase pendurado na borda do caldeirão, mexendo uma poção porque aprendeu alquimia. A receita percebe que falta uma planta. Outro golem sai correndo pela fazenda carregando a planta nos braços, chega ao caldeirão e entrega o ingrediente para que a produção continue.

Essa cena resume:

- automação visível;
- logística física;
- especialização;
- personalidade;
- cadeia produtiva;
- mundo vivo.

Se uma futura automação puder ser implementada apenas como números, mas perder completamente essa sensação, discutir antes de seguir.

---

# 4. REFERÊNCIAS DE DESIGN

## FarmRPG

Absorver:

- requests mantendo itens antigos úteis;
- coleções;
- mastery/conhecimento para grinders;
- progressões paralelas;
- itens raros;
- eventos;
- objetivos de longo prazo;
- atividades diferentes alimentando umas às outras.

Evitar:

- progressão baseada só em números crescentes;
- FOMO obrigatório;
- gates lineares que eliminem escolhas.

## Tiny Terraces

Absorver:

- prazer de observar pequenos ajudantes trabalhando;
- automação física;
- posicionamento afetando eficiência;
- produção alimentando novos ajudantes;
- decoração como parte da vida do espaço.

Evitar:

- centenas/milhares de ajudantes;
- escala baseada principalmente em quantidade de workers;
- microgerenciamento excessivo;
- helpers tratados como peças descartáveis.

## MineColonies

Absorver:

- satisfação de fechar uma cadeia produtiva;
- pedidos internos;
- armazenamento/logística visível;
- prédios como infraestrutura;
- sensação de “eu construí isso e agora funciona”.

Não transformar Cauldron em simulador logístico pesado.

Construções só devem existir quando criam:

- especialização;
- nova fantasia;
- transformação visível;
- nova decisão;
- nova capacidade.

Evitar prédios cuja única função seja adicionar uma etapa artificial.

---

# 5. ESCOPO DA V0

## Obrigatório

### Agricultura

- arar;
- plantar;
- regar;
- crescer;
- colher;
- salvar/carregar;
- primeira versão de agricultura livre em solo válido.

### Caldeirão

- receitas conhecidas;
- descoberta de receitas;
- produção funcional;
- quantidades, tempos e recompensas coerentes com os dados;
- papel central no loop.

### Corrupção e purificação

- pelo menos uma área corrompida;
- entrega de recursos;
- purificação;
- área revelada/utilizável;
- algo interessante encontrado após purificar.

### Golem físico

- procurar trabalho;
- navegar;
- colher;
- carregar;
- depositar;
- regar se já estiver estável;
- idle simples;
- ponto de descanso ou comportamento ocioso simples.

### Pesca

- permanecer como atividade ativa opcional;
- pelo menos uma pequena coleção ou progressão associada.

### Save/load

- confiável dentro do escopo da V0;
- não criar duplicações;
- preservar estados principais.

### Evento previsível

Exemplo:

- peixe raro/lendário disponível dentro de uma janela de horário ou condição conhecida.

### Evento de atividade

Exemplo:

- pequena chance de uma Semente Dourada ou item especial ao colher.

### Evento aleatório de mundo

Exemplo:

- fragmento/objeto estranho que cai ou surge em determinada condição.

### Descoberta opcional de lore

Pelo menos um objeto, ruína ou frase que:

- não bloqueia progressão;
- não inicia automaticamente uma quest;
- recompensa curiosidade.

### Coleção inicial

Começar com uma categoria apenas.

Recomendação: pesca.

Completar pode conceder um pequeno bônus permanente, sem tornar a coleção obrigatória.

---

# 6. FORA DA V0

Não implementar como parte da primeira entrega:

- sistema completo de personalidade;
- relações profundas entre golems;
- centenas de eventos;
- centenas de receitas;
- genética complexa de golems;
- múltiplas grandes regiões;
- Fazenda Celestial completa;
- Feijão Celestial como cadeia final;
- dezenas de prédios;
- economia industrial extensa;
- dezenas de tipos de solo;
- multiplayer;
- árvore de habilidades final gigantesca;
- dezenas de coleções;
- narrativa principal completa;
- arte final de todo o jogo.

Essas ideias continuam válidas.

A V0 deve provar as sensações antes de construir escala.

---

# 7. PREMISSAS TÉCNICAS DA AUDITORIA

- `FarmPlot` continua sendo a autoridade efetiva do gameplay agrícola;
- `FarmGridManager` já atua como bridge/snapshot/índice;
- `FarmTileData` possui dados mais ricos, mas ainda não governa todo o gameplay;
- o save v4 usa o grid, mas mantém fallback legado;
- há risco de duplicação de lotes de expansão durante load;
- não existe ainda uma política única e explícita de solo válido;
- `Golem.gd` representa a direção atual;
- `GolemManager.gd` representa uma geração anterior e deve continuar desligado;
- `RecipeData` possui campos nem sempre respeitados na produção;
- o caldeirão ainda possui caminho abstrato de criação/contagem de golems;
- documentação histórica possui contradições.

## Decisão transitória para a V0

Salvo descoberta técnica que obrigue reconsideração:

> `FarmPlot` continua temporariamente como autoridade do gameplay agrícola.

> `FarmGridManager` funciona como índice/bridge/snapshot durante a primeira migração para solo livre.

Não migrar toda a agricultura para uma nova arquitetura de uma vez.

---

# 8. ESTRATÉGIA DE DESENVOLVIMENTO

Usar pequenos marcos testáveis.

Fluxo:

```text
entender
↓
alterar pouco
↓
verificar
↓
testar no Godot
↓
registrar decisão relevante
↓
somente então avançar
```

Não fazer grande refatoração preventiva.

Não limpar código apenas porque está “feio”.

Dívida técnica entra no caminho crítico quando:

- ameaça save;
- cria duplicação;
- bloqueia feature;
- cria duas fontes de verdade;
- torna o próximo passo inseguro.

---

# 9. MARCOS DA V0

## V0.0 — Baseline e fundação segura

Objetivo: garantir um estado de referência confiável antes das mudanças visíveis.

Tarefas:

1. registrar checklist manual do loop atual;
2. preservar saves representativos;
3. confirmar assets necessários e dependências não rastreadas;
4. confirmar abertura correta do projeto em estado limpo;
5. mapear quantidade atual de lotes e expansão.

Gate: não seguir se o jogo atual já não consegue plantar, regar, colher, pescar, usar caldeirão, purificar, salvar/carregar e fazer o golem colher/depositar.

---

## V0.1 — Identidade canônica de lotes

Problema: base, extras, expansão e lotes dinâmicos precisam usar o mesmo contrato de identidade.

Uma coordenada agrícola deve corresponder a no máximo um `FarmPlot`.

Objetivo:

- registrar;
- desregistrar;
- buscar;
- verificar existência de lote por coordenada.

Requisitos:

- expansão participa do mesmo registry;
- load reutiliza lote existente;
- impedir criação duplicada;
- criação dinâmica futura consulta o mesmo contrato.

Não fazer:

- não migrar tudo para `FarmTileData`;
- não implementar solo livre ainda;
- não refatorar `Main.gd` inteiro.

---

## V0.2 — Save v4 explícito e seguro

Objetivo: formalizar o contrato de persistência necessário para avançar.

Requisitos:

- ler `version`;
- diferenciar grid ausente de grid vazio;
- manter fallback legado enquanto necessário;
- evitar reconstruções destrutivas durante load;
- preservar expansão;
- documentar compatibilidade.

Não criar framework de migrations exagerado.

Não remover saves legados sem decisão humana.

---

## V0.3 — Contrato transitório da agricultura

Objetivo: definir claramente qual sistema possui cada responsabilidade durante a migração.

Premissa:

- `FarmPlot` continua autoridade do estado jogável na V0;
- `FarmGridManager` ajuda a localizar, indexar, serializar e representar espacialmente.

Não adicionar gameplay a campos de `FarmTileData` que sejam apagados por rebuilds sem antes corrigir sua persistência.

---

## V0.4 — Política de solo válido

Objetivo: criar uma única regra consultável que responda:

> “Posso arar aqui?”

Considerar:

- limite cultivável;
- área purificada;
- corrupção;
- água;
- obstáculos;
- construções;
- tile/lote existente;
- zonas reservadas.

“Não existe collider” não é suficiente.

---

## V0.5 — Piloto de agricultura livre

Objetivo: permitir arar uma pequena região validada sem depender de lotes pré-posicionados.

Fluxo:

```text
enxada
↓
clique no terreno
↓
converter para coordenada
↓
consultar solo válido
↓
verificar lote existente
↓
criar/preparar FarmPlot
↓
registrar
↓
persistir
```

Primeiro escopo pequeno.

Testar:

- criar;
- plantar;
- regar;
- crescer;
- colher;
- golem encontrar;
- salvar/carregar;
- impedir duplicação;
- rejeitar água;
- rejeitar obstáculo;
- rejeitar corrupção.

---

## V0.6 — Caldeirão coerente

Objetivo: fazer os dados das receitas realmente governarem a produção.

Alinhar:

1. quantidade do resultado;
2. tempo de produção;
3. pontos/recompensa de alquimia;
4. descoberta;
5. cancelamento/refund.

Preservar:

- `RecipeResolver`;
- `RecipeDatabase`;
- fallback legado enquanto necessário.

---

## V0.7 — Golem Vivo V0

Objetivo: provar que o golem é mais do que automação.

Preservar:

- navegação;
- seleção de trabalho;
- colheita;
- rega se estável;
- transporte;
- depósito.

Adicionar apenas primeira camada de vida:

- idle;
- olhar ao redor;
- pequena pausa;
- procurar ponto de descanso;
- sentar/dormir de forma simples;
- reação simples à chuva se o clima já permitir.

Animações mínimas desejadas:

- `idle`;
- `walk`;
- `work`;
- `carry`;
- `rest`;
- `react`.

Placeholders são aceitáveis.

---

## V0.8 — Primeira coleção

Recomendação: coleção de pesca.

Objetivo:

- prazer de completar;
- bônus para especialista;
- integração com atividade existente.

Filosofia:

Casual: “Completei a coleção.”

Otimizador: “Esse bônus combina com minha build.”

O bônus não deve ser obrigatório para pescar normalmente.

---

## V0.9 — Primeiro Event Director

Objetivo: criar fundação pequena para eventos.

Não construir sistema gigantesco.

A V0 deve provar três formatos:

### Evento previsível

Exemplo: peixe raro dentro de uma janela.

### Evento de atividade

Exemplo: chance de Semente Dourada ao colher.

### Evento aleatório de mundo

Exemplo: Fragmento Celestial surgindo após determinada condição.

Regras:

- eventos são opcionais;
- usar cooldown;
- evitar spam;
- evitar popups excessivos;
- comunicar preferencialmente pelo mundo;
- não criar FOMO importante;
- recompensas principalmente estéticas, colecionáveis, curiosas, materiais, dinheiro ou pequenas conveniências.

Evitar poder permanente significativo em evento temporário.

---

## V0.10 — Primeira descoberta de lore

Objetivo: provar narrativa opcional.

Na primeira área purificada, adicionar um pequeno elemento investigável.

Exemplo de direção:

> “Eles não nasceram da pedra.”

Não precisa ser exatamente esse texto.

Regras:

- sem quest automática;
- sem marcador obrigatório;
- sem recompensa numérica necessária;
- pode apenas alimentar mistério.

---

## V0.11 — Primeiro projeto de restauração

Opcional para fechamento da V0 caso o restante esteja estável.

Exemplos:

- Herbário;
- pequeno píer;
- santuário simples;
- estufa inicial.

A construção deve:

- representar uma fantasia;
- desbloquear possibilidade;
- mudar fisicamente o lugar.

Não criar estação apenas para adicionar uma etapa artificial de crafting.

---

# 10. CONTEÚDO ATIVO DA V0

A V0 deve começar a responder:

> “Minha plantação demora. Se eu quiser continuar jogando, o que faço?”

O conteúdo ativo deve vir de:

- pesca;
- experimentação no caldeirão;
- eventos;
- descoberta;
- purificação;
- requests simples se entrarem;
- coleção;
- pequena exploração/forrageamento quando houver espaço.

Regra:

> Idle produz. Ativo encontra oportunidades.

---

# 11. EVENTOS E ZONAS

A arquitetura futura deve permitir que purificar regiões aumente o repertório de eventos.

Exemplo:

```text
fazenda inicial
→ eventos básicos

bosque liberado
→ pool de eventos do bosque

caverna liberada
→ pool de eventos da caverna

lago expandido
→ novos eventos aquáticos
```

Quanto mais o mundo é restaurado, mais vivo ele se torna.

Não é necessário implementar múltiplas zonas na V0.

Apenas não criar um Event Director que impeça essa evolução.

---

# 12. CONSTRUÇÕES

Construções podem existir, mas devem complementar o caldeirão.

Possíveis direções futuras:

- Herbário;
- Estufa Mágica;
- Píer;
- Santuário dos Espíritos;
- Armazém Encantado.

Evitar:

- dezenas de processadores;
- máquinas redundantes;
- cadeias industriais profundas sem necessidade.

Teste:

> “Se removermos esse prédio, perdemos uma fantasia ou uma decisão interessante?”

Se não, provavelmente ele não merece existir.

---

# 13. AUTOMAÇÃO E LOGÍSTICA

A logística deve ser:

> visível, mas inteligente.

O jogador deve observar:

- golem pegando;
- andando;
- entregando.

Mas não ser obrigado a configurar dezenas de prioridades numéricas.

Preferir controles de intenção:

- equilibrado;
- agricultura;
- pesca;
- alquimia;
- transporte.

O jogador de otimização pode ganhar eficiência com:

- layout;
- distância;
- especialização;
- capacidade;
- posicionamento.

O casual continua funcional sem estudar logística.

---

# 14. REGRAS DE BALANCEAMENTO

## Conteúdo base deve funcionar

Bônus melhoram uma atividade, não tornam a atividade viável.

## Combos intencionais são desejados

Exemplo:

- árvore de pesca;
- bônus de coleção;
- golem especializado;
- evento;
- consumível.

## Evitar stacking acidental infinito

Quando várias fontes modificarem a mesma estatística, documentar regra de stacking.

## Itens antigos devem continuar encontrando usos

Possíveis usos:

- receita;
- request;
- coleção;
- ritual;
- construção;
- evento;
- troca;
- alimento de criatura.

---

# 15. ARTE E ANIMAÇÃO NA V0

Arte final não é bloqueador.

Prioridade:

1. legibilidade;
2. coesão;
3. personalidade;
4. refinamento.

Usar placeholders quando necessário.

Para golems, formas simples são desejáveis porque:

- facilitam animação;
- permitem variantes;
- podem ser expressivas;
- reduzem custo de produção.

O charme virá tanto do comportamento quanto da quantidade de frames.

---

# 16. COMO O CODEX DEVE TRABALHAR

Antes de alterar:

1. ler contexto;
2. inspecionar código relevante;
3. identificar riscos;
4. confirmar que a tarefa está dentro do marco atual.

Durante:

- alterações pequenas;
- preservar compatibilidade;
- evitar dependências novas sem necessidade;
- reutilizar contratos existentes quando corretos;
- não ampliar escopo silenciosamente.

Quando houver decisão importante:

1. explicar problema;
2. apresentar alternativas;
3. trade-offs;
4. recomendação.

Não implementar escolha arquitetural grande silenciosamente.

Depois:

- listar arquivos alterados;
- resumir implementação;
- informar comportamento esperado;
- apontar riscos;
- informar testes realizados;
- fornecer checklist manual do Godot.

Não começar automaticamente o próximo marco.

---

# 17. TESTE MANUAL É PARTE DO PROCESSO

O jogo é validado no Godot pelo autor.

Cada sprint deve possuir checklist pequeno.

Não considerar “compila” equivalente a “funciona”.

Quando o Codex não puder validar comportamento visual:

- explicar exatamente o que testar;
- indicar resultado esperado;
- indicar sinais de falha.

---

# 18. DOCUMENTAÇÃO

Não transformar documentação em burocracia.

Atualizar quando houver:

- nova decisão arquitetural;
- mudança de fonte de verdade;
- alteração de save;
- mudança importante de direção.

Usar:

- `DECISIONS.md` para decisões;
- documento de contexto para estado vigente;
- este arquivo como plano da V0.

---

# 19. PRIMEIRO TRABALHO A EXECUTAR

# Sprint 01 — Baseline + Identidade dos FarmPlots

## Fase A — somente leitura e baseline

1. Leia os arquivos de contexto.
2. Inspecione:
   - `Main.gd`
   - `FarmPlot.gd`
   - `FarmGridManager.gd`
   - `FarmTileData.gd`
   - `SaveManager.gd`
   - purificação/expansão
3. Liste todas as formas atuais de criação de `FarmPlot`.
4. Liste todos os registries/lookups existentes.
5. Confirme o risco de duplicação descrito na auditoria.
6. Verifique dependências não rastreadas relevantes à cena principal/calderão.
7. Não altere nada ainda.
8. Apresente um plano pequeno para a Fase B.

## Fase B — implementar identidade canônica

Somente após entender a Fase A:

1. criar ou consolidar contrato de registro;
2. garantir lookup por coordenada;
3. incluir lotes da expansão;
4. impedir duplicatas;
5. fazer load reutilizar lote existente;
6. preservar gameplay atual;
7. adicionar verificações/testes possíveis.

## Restrições

- não implementar solo livre;
- não migrar toda agricultura;
- não reescrever `Main.gd`;
- não alterar arte;
- não remover fallback legado;
- não reativar `GolemManager`;
- não começar Sprint 02.

## Entrega

Fornecer:

- diagnóstico da causa;
- arquivos alterados;
- contrato criado;
- riscos restantes;
- testes executados;
- checklist manual para Godot.

---

# 20. CHECKLIST MANUAL DO SPRINT 01

No Godot:

1. iniciar novo jogo;
2. observar quantidade/posição dos lotes;
3. plantar em lote base;
4. regar;
5. colher;
6. salvar;
7. carregar;
8. iniciar purificação;
9. entregar progresso parcial;
10. salvar/carregar;
11. concluir purificação;
12. usar lote liberado;
13. salvar;
14. carregar;
15. verificar visualmente sobreposição;
16. confirmar quantidade de lotes;
17. confirmar crop correto;
18. confirmar golem encontrando o lote correto;
19. confirmar que nenhum lote extra foi criado após load.

Se algo falhar, parar antes do próximo sprint.

---

# 21. SPRINTS SEGUINTES — ORDEM ATUAL

Após Sprint 01 aprovado manualmente:

```text
Sprint 02
Save v4 explícito/compatibilidade

Sprint 03
Contrato transitório FarmPlot/FarmGrid

Sprint 04
Política de solo válido

Sprint 05
Piloto de agricultura livre

Sprint 06
Caldeirão / RecipeData coerente

Sprint 07
Golem Vivo V0

Sprint 08
Coleção de pesca

Sprint 09
Event Director V0

Sprint 10
Lore opcional / descoberta

Sprint 11
Polimento e fechamento da V0
```

A ordem pode ser ajustada por nova evidência técnica.

Registrar o motivo de mudanças relevantes.

---

# 22. CRITÉRIOS DE V0 PRONTA

A V0 pode ser considerada pronta quando:

- loop agrícola funciona em terreno validado;
- save/load é confiável;
- caldeirão possui pequena progressão coerente;
- primeira purificação transforma o mundo;
- golem físico ajuda de forma visível;
- pesca funciona como conteúdo ativo;
- existe uma coleção simples;
- existe pelo menos um pequeno bônus de especialização;
- existe um evento previsível;
- existe um evento de atividade;
- existe um evento aleatório;
- existe uma descoberta opcional;
- uma sessão de 30–60 minutos apresenta escolhas reais;
- o jogador não precisa ficar olhando timer;
- o projeto continua pequeno o suficiente para evoluir.

---

# 23. O QUE A V0 NÃO PRECISA PROVAR

Não precisa provar:

- endgame;
- economia final;
- conteúdo infinito;
- narrativa completa;
- arte final;
- centenas de horas;
- sistema completo de golems;
- multiplayer;
- equilíbrio definitivo.

Ela precisa provar:

> **Cauldron Crops é divertido e tem identidade mesmo em pequena escala.**

---

# 24. FRASES-BÚSSOLA

> **Magia é infraestrutura, não decoração.**

> **Ausência não pune; presença recompensa.**

> **Especialização recompensa profundidade; diversidade recompensa flexibilidade.**

> **Eventos são convites, não obrigações.**

> **O jogador entra com um plano; o mundo oferece motivos para abandoná-lo.**

> **Idle produz. Ativo encontra oportunidades.**

> **Golems são criaturas, não máquinas.**

> **Automação deve ser algo que o jogador queira observar.**

> **Purificar uma área deve revelar algo, não apenas aumentar o mapa.**

> **Nem toda descoberta precisa dar uma recompensa. Às vezes descobrir é a recompensa.**

> **Provar a sensação antes de construir a escala.**

---

# 25. INSTRUÇÃO FINAL AO CODEX

Comece pelo **Sprint 01 — Baseline + Identidade dos FarmPlots**.

Primeiro faça a Fase A em modo somente leitura.

Não altere arquivos até concluir o diagnóstico e apresentar um plano pequeno para a Fase B.

Não tente concluir toda a V0 em uma única execução.

O objetivo é produzir uma base confiável e avançar por incrementos que o autor consiga testar, compreender e aprovar no Godot.
