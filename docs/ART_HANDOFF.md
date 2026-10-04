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

**Registro:** 2026-10-04. Contrato aprovado pelo autor, implementação funcional neste incremento; resultados de QA/pacote serão consolidados no fechamento. Não é uma nova cultura ou uma mudança do conceito artístico da Raiz.

- Item `raiz_gelida`, ID persistente da fonte `grove_root`; cena `Scenes/ForagingGroveRegion.tscn`, nó `ForageNodes/RenewableRoot`, posição de mundo `(960,630)`. Código em `Scripts/ForageNode.gd`, `Scripts/GroveExpedition.gd` e descrição em `Scripts/Database.gd`.
- Função: aproximação física por clique, uma unidade na Mochila, renovação em 45s de jogo aberto inclusive na vila. Primeira visita disponível sem purificação/restauração, sem receita/XP/marco/slots concedidos pela coleta. Raiz cultivada no inverno continua o mesmo item.
- Estados: disponível, esgotada aguardando renovação e disponível novamente. Recusa por capacidade não esgota; aviso transitório explica depósito/retorno. Texto atual informa item/quantidade/tempo, sem rótulo de carvão na Raiz.
- Placeholder: instância da geometria já existente em `Scenes/ForageNode.tscn`, sem desenho/asset novo produzido por Codex. Texto identifica a Raiz; forma final, conceito e acabamento ficam com Antigravity.
- Demanda visual: representação própria da fonte disponível/esgotada e legibilidade dos dois estados no Bosque, usando o item existente; esta nota não pede paleta, lore, nova planta, bioma ou coleta automática.
- Restrições: preservar posição lógica e ponto alcançável, `AvailableVisual`/`DepletedVisual`, `CollisionShape2D` de picking (raio atual 34) e alcance 62; área não é novo obstáculo físico de navegação. Não ampliar colisões por trocar o sprite. Rótulos/feedback não capturam mouse. Sprite/efeito não concede recursos antes da chegada.
- Arte em andamento no workspace por outro agente permanece separada desta entrega de código. O PNG local de item, se presente, não é certificado ou publicado como arte aprovada por este incremento; o pacote limpo usa os recursos versionados.
- Resposta Antigravity: pendente. Nova arte integrada por Codex: pendente. Aceite artístico do autor: pendente.
