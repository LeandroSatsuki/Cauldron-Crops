# Changelog

## 2026-05-31
- Criação da documentação inicial do projeto.
- Registro do estado atual do projeto para continuidade entre sessões.
- Auto-colheita do `GolemManager` desativada temporariamente com flag para permitir teste manual do loop principal.

## 2026-05-31 - Inventário e caldeirão
- Correção do clique direito nos slots do inventário para permitir venda/ação secundária.
- Adição de fallback de caminho para ícones de item em `InventorySlot` e `DropSlot`.
- Melhoria das mensagens de aviso quando o item não possui imagem associada.

## 2026-05-31 - Salvamento mínimo
- Criação do `SaveManager` como Autoload para salvar e carregar progresso básico do protótipo.
- Salvamento em `user://savegame.json`.
- Inclusão de atalhos temporários de teste: `F5` para salvar e `F9` para carregar.
- Escopo inicial do save: inventário, receitas descobertas, pontos de alquimia, moedas, estação, ano, água e quests simples.

## 2026-05-31 - Livro de receitas
- Criação da primeira versão do Livro de Receitas para consultar receitas descobertas.
- Integração do livro na UI principal com botão dedicado.
- Exibição de ingredientes, resultado e quantidade maxima fabricavel com base no inventário atual.
- Consulta separada da produção em lote, que fica para uma etapa futura.

## 2026-05-31 - Livro e lote
- O Livro de Receitas passou a ficar acima do caldeirão para evitar conflito visual com o popup de mistura.
- Adição de produção em lote a partir do Livro de Receitas.
- Inclusão de barra de progresso abaixo do caldeirão para acompanhar o lote em andamento.
- Clique no caldeirão agora cancela a produção em lote e devolve os ingredientes ainda não processados.
- O Livro passou a atualizar a quantidade máxima fabricável conforme o inventário muda.

## 2026-05-31 - Colheita compartilhada
- A lógica de recompensas da colheita passou a ser compartilhada entre a colheita manual e o Golem Coletor V1.
- O golem agora deposita todos os bônus coletados no Baú da Vila, em vez de apenas um item básico.
- A deposição do golem ganhou feedback flutuante resumido no mundo.
- O fluxo principal continua igual para o jogador; a mudança só alinhou as recompensas entre manual e automatizado.

## 2026-05-31 - Cancelamento visível do lote
- Adição do botão `Cancelar producao` na área da barra de progresso do caldeirão.
- O cancelamento agora devolve os ingredientes das unidades restantes do lote.
- O cancelamento por clique no caldeirão foi mantido como atalho secundário.
- Redução dos prints de diagnóstico agora que o vínculo do caldeirão já está validado.
- A interface de lote continua provisória, mas mais clara para teste manual.

## 2026-05-31 - UI provisoria do caldeirao
- Substituição da imagem decorativa antiga do popup por um placeholder temporário próprio do projeto.
- Reorganização visual do popup do caldeirão para acomodar slots, botões, resultado e área de produção em lote com mais folga.
- Nenhuma mudança na lógica da produção em lote.
- A arte final do caldeirão continua para depois.

## 2026-05-31 - Fundo de rocha da UI
- Criação de um placeholder pixel art de rocha para o fundo do popup do caldeirão.
- Aplicação do fundo como `NinePatchRect` para preencher o popup de forma estável.
- Manutenção da UI e da lógica do caldeirão como provisórias, apenas com ajuste visual.

## 2026-05-31 - Fonte pixel art provisoria
- Adoção da fonte Pixelify Sans para a interface principal, popup do caldeirão e Livro de Receitas.
- Caminho da fonte: `res://Assets/fonts/PixelifySans-Regular.ttf`.
- Licença registrada em `res://Assets/fonts/OFL.txt` sob SIL Open Font License 1.1.
- Criação do tema provisório `res://Themes/pixel_ui_theme.tres`.
- Decisão explícita de não usar fonte Minecraft nem clone direto.
- A fonte foi verificada com textos em português contendo acentos.

## 2026-05-31 - Esquema de receitas
- Criação da documentação técnica `docs/RECIPES_SCHEMA.md`.
- Registro do formato atual das receitas em `Database.gd`.
- Comparação entre `Resource .tres`, JSON e CSV para a migração futura.
- Recomendação documentada: manter o protótipo no formato atual por enquanto e migrar depois para `Resource .tres`.

## 2026-05-31 - Estrutura inicial de Resource para receitas
- Criação do `RecipeData` em `Scripts/data/RecipeData.gd` como base tipada para receitas.
- Criação de duas receitas `.tres` de teste em `Data/recipes/` para validar a estrutura sem conectar o jogo ainda.
- Manutenção do fluxo atual do caldeirao e do Livro de Receitas sem alteracoes.
- Preparacao para um futuro `RecipeDatabase.gd` que consiga ler `Resource` e comparar com o sistema antigo.

## 2026-05-31 - Leitor estrutural de receitas
- Criação de `Scripts/data/RecipeDatabase.gd` como leitor apenas de validação.
- Carregamento de receitas `.tres` de `res://Data/recipes/` sem substituir o sistema antigo.
- Validação basica de campos obrigatorios de `RecipeData`.
- Comparacao dos ids de Resources com `Database.receitas_alquimia` para orientar a migracao futura.

## 2026-05-31 - Livro de Receitas em paralelo
- O Livro de Receitas passou a usar `RecipeDatabase` para exibir dados ricos quando o `RecipeData` existe e esta completo.
- O fallback antigo com `Database.receitas_alquimia` continua obrigatório e ativo.
- A produção em lote segue usando somente o sistema legado por enquanto.
- A exibição rica melhora nome, descricao, categoria, ingredientes, resultado e tempo sem trocar o fluxo principal.

## 2026-05-31 - Cobertura total das receitas legadas
- Criação dos `.tres` faltantes em `Data/recipes/` para cobrir todas as receitas atuais do sistema legado.
- O `RecipeDatabase` agora possui cobertura completa do catálogo legado atual.
- `Database.gd` continua sendo a fonte funcional da produção e do caldeirão.
- A camada `RecipeDatabase` segue sendo apenas leitura e apresentacao por enquanto.

## 2026-05-31 - Golem Coletor V1
- Criação do Baú da Vila V1 como alvo físico simples para depósito.
- Anexação do `Golem.gd` à cena do golem físico.
- O golem físico agora procura lote maduro, colhe 1 item e deposita no baú.
- `FarmPlot` passou a oferecer uma colheita segura para o golem via `harvest_by_golem()`.
- `GolemManager` continua desligado e a colheita invisível segue desativada.
- O Baú da Vila ainda não tem UI nem salvamento.

## 2026-05-31 - UI do Baú da Vila
- Criação de uma interface simples para o Baú da Vila com lista textual de conteúdo.
- Adição de clique no baú para abrir o painel pela UI principal.
- Adição do botão `Retirar Tudo`, transferindo itens para o inventário global.
- O baú continua separado do inventário do jogador; salvamento fica para depois.
- A retirada individual ainda não existe nesta etapa.

## 2026-05-31 - Presenca fisica do golem
- Ajuste de ordem visual por Y para o golem, baú e lotes usando z_index dinâmico.
- O golem agora usa um ponto de interação separado do centro visual da crop.
- Criação de um sensor simples para fazer as crops balançarem quando o golem passa perto.
- O movimento continua em linha reta; pathfinding completo fica para depois.

## 2026-05-31 - Navegacao do golem
- O golem passou a usar `NavigationAgent2D` para mover-se em direção a lotes e ao Baú da Vila.
- O caldeirão ganhou obstáculo físico simples para evitar travessia direta no mundo.
- A cena principal agora cria uma região de navegação simples cobrindo a área jogável inicial.
- O ajuste visual manteve o golem acima do solo arado durante o deslocamento.
- A solução é provisória e ainda não substitui um sistema completo de pathfinding com obstáculos refinados.

## 2026-05-31 - Colisao fisica do golem
- O golem físico passou a usar `CharacterBody2D` com colisão própria para respeitar obstáculos do mundo.
- O caldeirão continua sendo tratado como obstáculo físico do cenário.
- A navegação segue simples e apoiada por `NavigationAgent2D`, mas agora o corpo físico impede atravessar o caldeirão.
- A ordem visual dos lotes continua baseada em Y, com o golem acima do solo arado sem usar rota manual em L.

## 2026-05-31 - Desvio ao travar
- O golem agora detecta quando ficou travado contra o caldeirão ou outro obstáculo.
- Ao travar, ele calcula um desvio simples ao redor do caldeirão e tenta retomar o destino original.
- O destino final e o callback da ação continuam preservados durante o desvio.
- Se o travamento se repetir demais, a tentativa atual pode ser abortada com aviso.
- O comportamento segue provisório e ainda depende de refinamento futuro da região de navegação.

## 2026-05-31 - Camada visual do campo
- A terra arada e a base do lote passaram a ficar em camada visual baixa, separada da planta.
- O golem passou a usar um `z_index` levemente acima do campo para não ficar escondido pela terra arada.
- Tooltip, VFX e efeitos de colheita continuam acima dos visuais principais do lote.
- A ordenação por Y do protótipo foi mantida, só com offsets mais seguros para leitura.

## 2026-05-31 - Terra fora da herança visual
- A terra arada e o visual de solo deixaram de herdar a ordenação do `FarmPlot`.
- Isso evita que lotes mais abaixo na tela cubram parcialmente o golem quando ele passa entre as plantações.
- A crop continua com camada própria e os efeitos/tooltip seguem acima.
- A solução ainda é provisória e pode virar um sistema formal de camadas depois.
