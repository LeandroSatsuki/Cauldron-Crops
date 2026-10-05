# Passagem de desenvolvimento para arte no Antigravity

Este é o documento permanente de comunicação entre o desenvolvimento funcional de Cauldron Crops e a direção de arte no Antigravity. Por decisão do autor em 2026-10-04, **Codex cuida de código e testes; Antigravity cuida de direção e produção artística**, com aprovação criativa do autor. Codex não produz arte final nem escolhe novos conceitos visuais.

## Referências e limites

- `ART_STYLE_GUIDE.md` é a referência artística disponível no workspace, mantida pelo trabalho de arte; sua edição local não é publicada por este incremento. Este documento não redefine seu estilo nem aplica automaticamente suas propostas de configuração ao jogo.
- `ITEM_TEXTURE_BACKLOG.md` é um levantamento histórico a revalidar, não uma lista de assets aprovados. O catálogo e os caminhos atuais precisam ser conferidos antes de produzir cada asset.
- `CAULDRON_CROPS_CONTEXT_MASTER.md`, `ROADMAP.md` e o plano do recorte distinguem implementado, proposto e pendente. Conteúdo apenas planejado não gera tarefa de produção confirmada.
- Aceite de código, screenshot de QA ou teste automático não é aprovação artística. As 50 pendências manuais do checkpoint da Aceleradora continuam pendentes.

## Como atualizar e usar

Ao finalizar uma implementação com impacto visual, Codex acrescenta **uma nota ao final deste documento**, sem apagar notas ou respostas anteriores. A nota informa o que realmente entrou e o contrato funcional que a arte precisa respeitar. Sem impacto visual, não criar tarefa fictícia. Novas receitas, itens, plantações, animais e golems terão suas próprias notas quando forem implementados; esta regra não autoriza adicioná-los todos de uma vez.

Antigravity consulta este arquivo e registra, junto à nota correspondente, sua resposta: proposta, arquivos produzidos, trabalho em andamento ou arte entregue. O autor confirma o aceite artístico; Codex confirma separadamente a integração funcional depois de testar. “Arte entregue” não significa “integrada” ou “aprovada”. Não há envio automático ao Antigravity ou acesso ao outro chat configurado por este documento.

Antes de editar uma cena ou script compartilhado, combinar responsável e arquivos. Preferir produzir assets novos sem mudar raízes de cena, nomes funcionais de nós, sinais ou IDs. Não sobrescrever alterações de outro agente ou substituir assets do autor por inferência.

## Contrato de integração técnica

Codex pode reutilizar assets existentes ou desenhar a forma geométrica mínima para tornar uma ação testável. Essas formas são placeholders, não referência artística. Manter estados distinguíveis e controles acessíveis, sem investir em ilustração ou animação elaborada.

Antigravity pode propor visual e animação, mas a troca artística deve preservar posição lógica, áreas clicáveis, colisões, destino de navegação, alcance, quantidades, timers e regras de profundidade do contrato existente. Um pivô artístico pode ser ajustado em um filho visual; mover a raiz física requer análise técnica. Alterações de resolução base, viewport, câmera, grid, escala global ou ordenação global não são troca de textura e devem ser coordenadas e testadas antes de integração. Em particular, o grid de mundo atual não deve ser reduzido só para corresponder à resolução nativa de um sprite.

Ícones de itens são procurados por `Database.obter_textura_item`: `Assets/Items/<item_id>.png`, depois `Assets/<item_id>.png`, depois `Assets/Items/<item_id>.svg`; há fallback textual. Preferir o caminho dedicado por ID, sem renomear o item ou mudar sua aquisição. Para animação de mundo, declarar o arquivo, dimensões, frames e ponto de ancoragem antes de conectar ao código; não pressupor um importador de spritesheet inexistente.

## Formato das próximas notas

Cada nota deve conter data e etapa; estado do conteúdo (implementado ou somente proposto); item IDs/cenas/scripts; função e estados observáveis; placeholder reutilizado ou criado; demanda visual sem impor estética; restrições técnicas; evidência e pendência; resposta do Antigravity, integração de Codex e aceite do autor. Prioridade aqui representa dependência funcional ou frequência de exposição, não autoridade sobre a ordem de produção artística.

## Notas para Antigravity

### Aceleradora e painel Golem

**Registro:** 2026-10-04. Conteúdo já implementado na fonte `f0f68ab`, com fechamento `e6e5c82`; pacote `Builds/Playtest/AcceleratorDelivery-20261004`. Não foi criado nesta etapa documental.

- IDs e arquivos: `pocao_aceleradora`; `Scenes/UI.tscn`, `Scripts/UI.gd`, `Scripts/GolemPanel.gd`, `Scripts/ItemUsePanel.gd` e `Scripts/Golem.gd`.
- Função: preparar uma próxima entrega pelo painel, sem aproximar o personagem; um frasco pessoal é consumido no início válido da entrega. Deslocamento 1,5× somente com aquela carga de colheita.
- Estados que o visual deve comunicar: nenhuma ordem, preparada sem gasto, ativa após gasto; estoque pessoal, ação disponível/bloqueada, cancelamento somente antes do gasto. O cartão de item apenas encaminha ao painel, sem botão Aplicar livre.
- Representação atual: painel/ícone de apoio provisórios já existentes. Cabeçalho e Fechar ficam fixos; apenas o corpo rola. A ação ativa não oferece cancelamento ou refund.
- Demanda: revisar apresentação e ícone próprios no fluxo existente, sem abrir outro fluxo de uso, introduzir HUD permanente ou sugerir aceleração de plantio/rega/depósito. Não há conceito novo criado por Codex.
- Contrato técnico: manter `GolemPanel/MarginContainer/VBoxGolem/ScrollContainer/Content` e os nós funcionais enquanto dependentes por caminho; preservar opacidade, arrasto, scroll, bloqueio de input e ferramentas/sementes selecionadas. Reorganização da hierarquia exige integração de código coordenada.
- Evidência: nove capturas de estados em 800×600, 800×720 e 1280×720 sob `Builds/QA/AcceleratorUI/`, locais e fora do Git. QA funcional passou; não há aceite artístico inferido.
- Resposta Antigravity: pendente. Integração de nova arte: pendente. Aceite artístico do autor: pendente.

### Preparo de Solo Vivo e interação de aplicação

**Registro:** 2026-10-04. Conteúdo já implementado no checkpoint Solo Vivo `549aa60` e mantido no pacote atual. Não há nova cultura nesta nota.

- IDs e arquivos: `preparo_solo_vivo`, `pocao_crescimento`; `Scripts/FarmPlot.gd`, `Scenes/FarmPlot.tscn`, `Scripts/ItemUsePanel.gd` e `Scripts/UI.gd`.
- Função: Solo Vivo é tratamento durável do lote piloto `(2,2)`, vazio/arado; não rega imediatamente. Trigo regado cuja colheita é entregue conserva umidade. Crescimento usa doses existentes ou abre um frasco no primeiro uso válido.
- Estados necessários: consulta do item, aplicação armada, alvo válido/recusado e cancelamento; solo tratado versus umidade herdada, que são informações diferentes. Não apresentar outros lotes ou culturas como elegíveis para o tratamento piloto.
- Representação atual: cartão/faixa/contorno provisórios, texturas de cultivo existentes reutilizadas. Demanda: apresentação artística dos itens e estados sem alterar regra de aplicação ou criar efeito novo.
- Contrato técnico: solo abaixo dos objetos e plantas; manter picking/posição da célula, autoridade de FarmPlot, tool/seed exclusivas da aplicação e consumo somente no commit válido. O indicador visual não amplia a área de uso.
- Evidência e limites: testes técnicos registrados em `FARM_SYSTEM_V2.md`; mouse físico, conforto e arte permanecem pendentes. Sem nome definitivo ou lore nova solicitada nesta nota.
- Resposta Antigravity: pendente. Integração de nova arte: pendente. Aceite artístico do autor: pendente.

### Inventário do visual existente

**Registro:** 2026-10-04. Referências técnicas para planejar substituição gradual, não novo pacote de produção autorizado nem pedido para descartar assets existentes.

Avatar em `Scenes/PlayerAvatar.tscn`, baú em `Scenes/VillageChest.tscn`, golem em `Scenes/Golem.tscn` e Poço em `Scenes/VillageWell.tscn` usam representações de protótipo. `Scripts/VillageWell.gd` desenha estados comum/melhorado, e o golem já comunica carga física de sementes/colheita. Ao substituir o visual, preservar essas distinções, o caminho físico e áreas clicáveis; não introduzir animação que teleporte ou entregue itens antes do commit lógico.

O backlog histórico de ícones permanece em `ITEM_TEXTURE_BACKLOG.md`; as duas notas acima complementam esse levantamento com contratos atuais. Antigravity decide conceito, prioridade artística e produção com o autor. Nenhum sprite, textura, configuração de renderização ou asset do autor foi alterado por este documento.

Resposta Antigravity: pendente. Plano de substituição: pendente. Aceite artístico do autor: pendente.

### Fonte renovável de Raiz Gélida no Bosque

**Registro:** 2026-10-04. Contrato aprovado pelo autor, implementação funcional neste incremento. Gameplay `b126f34`, entrega `8d4df8c`, pacote `Builds/Playtest/RenewableRoot-20261004`. Não é uma nova cultura ou uma mudança do conceito artístico da Raiz.

- Item `raiz_gelida`, ID persistente da fonte `grove_root`; cena `Scenes/ForagingGroveRegion.tscn`, nó `ForageNodes/RenewableRoot`, posição de mundo `(960,630)`. Código em `Scripts/ForageNode.gd`, `Scripts/GroveExpedition.gd` e descrição em `Scripts/Database.gd`.
- Função: aproximação física por clique, uma unidade na Mochila, renovação em 45s de jogo aberto inclusive na vila. Primeira visita disponível sem purificação/restauração, sem receita/XP/marco/slots concedidos pela coleta. Raiz cultivada no inverno continua o mesmo item.
- Estados: disponível, esgotada aguardando renovação e disponível novamente. Recusa por capacidade não esgota; aviso transitório explica depósito/retorno. Texto atual informa item/quantidade/tempo, sem rótulo de carvão na Raiz.
- Placeholder: instância da geometria já existente em `Scenes/ForageNode.tscn`, sem desenho/asset novo produzido por Codex. Texto identifica a Raiz; forma final, conceito e acabamento ficam com Antigravity.
- Demanda visual: representação própria da fonte disponível/esgotada e legibilidade dos dois estados no Bosque, usando o item existente; esta nota não pede paleta, lore, nova planta, bioma ou coleta automática.
- Restrições: preservar posição lógica e ponto alcançável, `AvailableVisual`/`DepletedVisual`, `CollisionShape2D` de picking (raio atual 34) e alcance 62; área não é novo obstáculo físico de navegação. Não ampliar colisões por trocar o sprite. Rótulos/feedback não capturam mouse. Sprite/efeito não concede recursos antes da chegada.
- Arte em andamento no workspace por outro agente permanece separada desta entrega de código. O PNG local de item, se presente, não é certificado ou publicado como arte aprovada por este incremento; o pacote limpo usa os recursos versionados.
- Fechamento funcional: Root86 por backend headless/OpenGL, fixture2/reabertura8 e suíte limpa58/58,11reaberturas/5fixtures, startups/PCK/hashes/logs conferidos pelo QA independente. Fonte acessível por caminhada de API e estados de recusa/renovação testados; picking de mouse, legibilidade/conforto, ritmo e arte continuam pendentes nos cinco RG, sem aceite artístico inferido.
- Resposta Antigravity: pendente. Nova arte integrada por Codex: pendente. Aceite artístico do autor: pendente.

### Tomate como segunda cultura inicial

**Registro:** 2026-10-04. Contrato aprovado pelo autor, domínio/orientação fechados tecnicamente; gameplay `a42b86d`, entrega `e5846b1`, pacote `Builds/Playtest/TomatoCrop-20261004`. Não é aceite artístico.

- IDs preservados: `semente_verao` e `tomate_sol`; receita nova `Data/recipes/semente_tomate_recuperacao.tres`, sem item/espécie novo. Scripts funcionais: Database, FarmPlot, InventorySlot, UI e SaveManager.
- Função: fabricar 1 trigo + 1 água → 1 semente/2s/0XP pelo Livro ou mistura; plantar da Mochila na Primavera/Verão e regar. Golem continua semeando somente trigo, Solo Vivo não retém água para tomate. Não há novo calendário ou lore.
- Estados observáveis: semente selecionada/desselecionada, cultivo crescendo/maduro/regado, colheita e estoque; são estados já existentes do tomate. Receita conhecida no Livro, disponibilidade conforme recursos e resultado bloqueado por capacidade usam interfaces vigentes. Tooltip orienta duas estações e aquisição sem primeiro tomate.
- Representação: assets e visual de cultivo existentes reutilizados, sem desenho ou animação novo por Codex. Os PNGs locais produzidos pelo trabalho artístico separado não são publicados ou certificados nesta etapa; pacote limpo usa recursos versionados.
- Demanda: considerar o tomate/semente no conjunto visual e na legibilidade dos estados existentes. Nenhum pedido de paleta/conceito novo, cultura sazonal em lote especial ou janela adicional.
- Restrições: manter IDs, raiz/posição/grid/picking/alcance, plantio pessoal, consumo somente após validação, renderização abaixo dos objetos e controles opacos sem atravessar input. Arte não altera 5s/base, rega/bônus ou políticas de estação. Reorganização de hierarquia/viewport/grid exige coordenação técnica.
- Evidência e pendência: Tomato125 por backend headless/OpenGL/fixture2/reabertura8; suíte limpa59/59,12reaberturas/6fixtures, startups/PCK/manifesto/hashes/85logs conferidos pelo QA independente. Cinco TC no checklist, todos pendentes, em total60; não inferir picking físico, conforto, ritmo ou arte aprovados. Arte concorrente não incluída no pacote; respostas do Antigravity permanecem no workspace sem serem publicadas por este fechamento.
- Resposta Antigravity: pendente. Nova arte integrada por Codex: pendente. Aceite artístico do autor: pendente.

### Semeadura seletiva no painel Golem

**Registro:** 2026-10-04. Contrato aprovado pelo autor após `034edec` (Decisão 136). Implementação funcional fechada tecnicamente em `f587fe4`, pacote limpo `Builds/Playtest/SelectiveSower-20261004`; não é aprovação artística ou manual.

- IDs existentes `semente_basica` e `semente_verao`. Código em Golem, GolemSeedCargo, GolemWorkState, FarmPlot e UI; cena `Scenes/UI.tscn`. Nenhum item, receita, planta, golem ou asset novo.
- Função: escolher Trigo OU Tomate no mesmo piloto de quatro lotes; uma semente do Village Storage é carregada até plantar/devolver. Seleção só governa futuras retiradas, não liga habilidade ou interfere na ferramenta/semente pessoal; sem fallback/fila.
- Estados observáveis: escolha exclusiva, habilidade ON/OFF independente, gate da Clareira, troca disponível/bloqueada por tarefa ou cargo inclusive pausa/devolução, falta de estoque/estação/alvo. A carga mantém seu ID original mesmo com escolha futura diferente restaurada por save; OFF conserva devolução física.
- Representação reutilizada: dois botões e rótulo no painel opaco/rolável atual; carga usa textura do item existente com fallback do ícone genérico de semente. Não criar conceito, estilo ou spritesheet por Codex. Assets artísticos locais não são integrados/certificados por este incremento.
- Caminhos funcionais: `GolemPanel/MarginContainer/VBoxGolem/ScrollContainer/Content/SeedSelection` (HBoxContainer), filhos `WheatButton`/`TomatoButton` (Button), `SeedSelectionStatus` (Label); ON/OFF `SeedingToggle`, descrição `SeedingHint` e status `SeedingStatus`. Preservar nomes/conexões ou coordenar alteração com código.
- Demanda visual: integrar estes estados no acabamento do painel existente, sem novo HUD/janela ou indicação de autossuficiência. Manter cabeçalho/Fechar fixos, scroll, arrasto, legibilidade em 800×600/800×720/1280×720 e cliques GUI sem atravessar mundo; não alterar quatro células, collider, picking, navegação, alcance, timers, estação ou regras de custódia por troca de visual.
- Evidência e pendência: domínio79/física129/persistência28 e UI333 por backend headless/OpenGL; reaberturas8 de domínio e8 de UI. Capturas funcionais conferidas nas três resoluções, com arte local concorrente, sem certificação do visual do pacote limpo. Entrega limpa61/61 headless,14reaberturas/7fixtures/2cenários adicionais; EXE headless/OpenGL/PCK/manifesto/hashes/92logs finais sem ERROR, launcher/checklist e limpeza conferidos. Arte externa não incorporada. Cinco SS acrescentados ao checklist, total65 manuais pendentes; mouse físico, conforto/ritmo e arte não homologados.
- Resposta Antigravity: pendente. Nova arte integrada por Codex: nenhuma nesta etapa. Aceite artístico do autor: pendente.

### Adubo Flamejante aplicado ao tomate

**Registro:** 2026-10-04. Contrato aprovado pelo autor após `6f92350` (Decisão138); implementação funcional e QA dedicada concluídas, pacote limpo ainda em fechamento. Não é aceite artístico/manual/balanceamento.

- IDs existentes: `adubo_flamejante`, `semente_verao`, `tomate_sol`; receita `Data/recipes/tomate_sol_trigo.tres` preserva 1tomate+1trigo→1adubo/2s e descoberta/XP vigentes. Nenhum item, cultura, conceito ou asset novo por Codex.
- Função: consultar na Mochila → Aplicar → clicar tomate crescendo/maduro → caminhar/revalidar → gastar um adubo pessoal. Uma cultura/colheita recebe +2 tomates aditivos; não rega/acelera/impede morte, não é solo permanente nem aplicação automática. Morte/reset real perde o tratamento; capacidade/load/retry/cargo não repetem bônus.
- Superfícies existentes: `UI/ItemUsePanel`, cartão `ItemCard` e faixa `ApplicationBar` criados por `Scripts/ItemUsePanel.gd`; `FarmPlot/TooltipArea` acrescenta “Adubo Flamejante · +2 tomates na próxima colheita”. Main arbitra input/chegada; FarmPlot governa elegibilidade e benefício. Texto do item/receita explica efeito e perda.
- Estados para acabamento futuro: consulta/Aplicar disponível, intenção armada/cancelada, aproximação, alvo inválido/alterado/sem estoque, cultura adubada crescendo/madura e colheita pendente por espaço. Representação atual reutiliza cartão/faixa/tooltip e recursos versionados; ícone/efeito final e distinção visual da cultura tratada pertencem ao Antigravity. Não criar nova janela/HUD, paleta ou lore por esta passagem.
- Restrições: manter IDs, posição/grid/collider/picking, alcance46 e geração da cultura; crescer→maduro é a mesma planta, replantar não. Arte não altera timers/rega/sorteios/quantidades. GUI opaca deve bloquear clique atravessado, com Aplicar/Fechar/Cancelar legíveis em 800×600/800×720/1280×720. Reflow do cartão foi corrigido com reset_size, sem redesenho.
- Evidência: domínio123 e persistência86/fixture2/reabertura8 por backend; UI144 headless/150 OpenGL (6 capturas extras), entrada do slot e caminhada/recusas/cancelamentos. Capturas do workspace incluem arte concorrente, não certificam a arte do futuro pacote limpo. Cinco AF no checklist, total70 manuais pendentes. Mouse físico, conforto, ritmo, arte e balanceamento não homologados.
- Resposta Antigravity: pendente. Nova arte integrada por Codex: nenhuma. Aceite artístico do autor: pendente.
