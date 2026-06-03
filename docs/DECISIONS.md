# Decisions

## Decisão 1 - Golem automático desativado temporariamente
- Problema: `GolemManager.gd` colhia automaticamente e conflitada com o golem físico.
- Decisão: manter o código, mas desligar a automação com flag.
- Motivo: estabilizar o loop manual.
- Risco: a automação fica inativa até ser reativada.
- Como reativar: trocar `automation_enabled` para `true`.

## Decisão 2 - Não criar sistema de receitas escalável ainda
- Problema: receitas futuras serão muitas.
- Decisão: adiar a migração para dados externos até o loop mínimo estar validado.
- Motivo: evitar complexidade prematura.
- Próxima análise: comparar `Resource .tres`, JSON e CSV.

## Decisão 3 - Documentar antes de expandir
- Problema: o projeto já tem muitos sistemas iniciados.
- Decisão: criar documentação mínima antes de implementar novas mecânicas.
- Motivo: manter continuidade e reduzir risco de bagunça.

## Decisão 4 - Fallback de ícone no inventário
- Problema: os slots de inventário e do caldeirão apontavam para `res://Assets/Items/`, mas essa pasta não existe no estado atual do projeto.
- Decisão: aceitar também `res://Assets/` como caminho de fallback para ícones.
- Motivo: evitar falhas visuais e permitir que o protótipo continue funcionando mesmo com estrutura simples.
- Risco: quando os ícones finais forem organizados em outra pasta, será preciso revisar esse fallback.

## Decisão 5 - Salvamento mínimo com SaveManager
- Problema: o protótipo precisava manter continuidade entre sessões sem virar um sistema grande.
- Decisão: criar um `SaveManager` como Autoload e salvar apenas o progresso principal em `user://savegame.json`.
- Motivo: permitir retomar testes do loop principal sem mexer em plantação, golems ou estrutura de dados.
- Dados salvos agora: inventário, receitas descobertas, pontos de alquimia, moedas, estação, ano, água e quests simples.
- Dados adiados: estado de lotes/plantações, golems e qualquer migração de dados para formatos externos.
- Risco: o save atual não preserva o campo inteiro nem a automação completa; isso será tratado depois.

## Decisão 6 - Livro de receitas separado da produção em lote
- Problema: o jogador precisava consultar receitas descobertas sem misturar isso com automação ou produção em série.
- Decisão: criar uma primeira versão do Livro de Receitas apenas para consulta.
- Motivo: manter o fluxo atual simples e preparar a base para produção em lote futura.
- Limitação atual: o livro lê o formato existente de `Database.receitas_alquimia` com uma camada adaptadora simples.
- Próxima etapa: adicionar produção em lote, barra de progresso e cancelamento quando o loop de consulta estiver estável.

## Decisão 7 - Livro de receitas como entrada para produção em lote
- Problema: a consulta de receitas precisava virar ação prática sem criar uma segunda interface de produção.
- Decisão: manter o Livro de Receitas como tela principal de consulta e usar ele para disparar produção em lote no caldeirão.
- Motivo: preservar o fluxo mental do jogador e evitar duplicar controles.
- Risco: o livro continua dependendo do formato atual de `Database.receitas_alquimia` e da camada adaptadora simples.

## Decisão 8 - Cancelamento de lote devolve ingredientes restantes
- Problema: o jogador precisava interromper uma produção em andamento sem perder tudo.
- Decisão: permitir cancelamento por clique no caldeirão e devolver apenas os ingredientes que ainda não viraram resultado.
- Motivo: dar controle ao teste manual e reduzir frustração durante prototipagem.
- Risco: a lógica de cancelamento trata apenas o lote atual; estados mais complexos ficam para depois.

## Decisão 9 - Cancelamento visível do lote
- Problema: o cancelamento por clique no caldeirão não era óbvio o suficiente para teste manual.
- Decisão: adicionar um botão `Cancelar producao` dentro do painel de progresso do lote.
- Motivo: deixar a ação explícita e reduzir dependência de interação escondida.
- Risco: a interface continua provisoria e pode precisar de ajuste visual depois.

## Decisão 10 - UI provisoria do caldeirao
- Problema: a imagem antiga do popup apertava os novos campos e deixava a leitura ruim.
- Decisão: substituir a decoração visual por um placeholder temporario e reorganizar o popup com mais folga.
- Motivo: melhorar a usabilidade sem mexer na lógica do lote.
- Risco: a arte final ainda precisa ser desenhada depois.

## Decisão 11 - Fundo de rocha como NinePatchRect
- Problema: o fundo visual precisava preencher o popup com mais consistência e legibilidade.
- Decisão: usar um `NinePatchRect` com placeholder de rocha pixel art para o fundo do popup.
- Motivo: garantir preenchimento estável do painel sem afetar os controles acima.
- Risco: a arte final ainda será substituida depois, mantendo a UI provisoria por enquanto.

## Decisão 12 - Fonte pixel art provisoria
- Problema: a UI precisava de uma tipografia mais próxima de um cozy pixel art, sem copiar a identidade de outro jogo.
- Decisão: usar Pixelify Sans com um tema provisório compartilhado pelas principais interfaces.
- Motivo: melhorar a leitura e o clima visual sem alterar lógica.
- Fonte: `res://Assets/fonts/PixelifySans-Regular.ttf`.
- Licença: SIL Open Font License 1.1, registrada em `res://Assets/fonts/OFL.txt`.
- Risco: o tema ainda é provisório e pode receber ajustes de tamanho/espacamento depois.

## Decisão 13 - Receitas documentadas antes da migração
- Problema: o formato atual de receitas funciona, mas não escala bem para um catálogo maior.
- Decisão: documentar o esquema atual e a migração futura antes de alterar o código.
- Motivo: evitar mudanças prematuras enquanto o loop principal já está estável.
- Recomendação futura: migrar para `Resource .tres` como formato principal, mantendo JSON/CSV apenas como apoio se necessário.
- Risco: a documentação não resolve a limitação estrutural sozinha; ela só prepara a migração futura.

## Decisão 14 - Popup da UI precisa ficar visivel ao abrir
- Problema: o clique no caldeirao e a abertura do Livro chegavam aos handlers, mas a camada `PopupLayer` permanecia oculta.
- Decisão: reativar o `PopupLayer` ao abrir o popup do caldeirao e ao abrir o Livro de Receitas.
- Motivo: manter a estrutura atual de UI sem deixar a camada onde os painéis vivem invisivel.
- Risco: o `PopupLayer` continua sendo uma solução provisoria de camada compartilhada.

## Decisão 15 - RecipeData criado sem acoplar ao jogo
- Problema: o projeto precisava de uma base tipada para receitas sem quebrar o fluxo atual.
- Decisão: criar `RecipeData` e receitas `.tres` de teste como camada estrutural paralela.
- Motivo: preparar a migração futura enquanto o caldeirao continua lendo `Database.receitas_alquimia`.
- Risco: dois formatos vivem ao mesmo tempo por enquanto, entao o acoplamento futuro precisara ser feito com cuidado.

## Decisão 16 - RecipeDatabase apenas de leitura
- Problema: o projeto precisava validar `Resource` de receitas sem trocar a fonte principal ainda.
- Decisão: criar `RecipeDatabase.gd` somente para carregar, validar e comparar receitas.
- Motivo: permitir a migração futura de forma segura, sem acoplar o caldeirao nesta etapa.
- Risco: a manutenção temporaria de dois sistemas de receita continua exigindo disciplina na migracao.

## Decisão 17 - Livro de Receitas em paralelo com fallback
- Problema: o Livro de Receitas precisava mostrar dados ricos sem abandonar a fonte antiga.
- Decisão: usar `RecipeDatabase` apenas para leitura e exibição complementar no Livro, mantendo `Database.receitas_alquimia` como fallback obrigatório.
- Motivo: validar o novo formato sem mexer no caldeirao nem na producao em lote.
- Risco: o jogo continua com dois caminhos de dados ativos até a migracao completa ser validada.

## Decisão 18 - Cobertura completa das receitas legadas
- Problema: ainda faltavam `.tres` para parte do catálogo legado.
- Decisão: criar `RecipeData` para todas as receitas que ainda só existiam em `Database.receitas_alquimia`.
- Motivo: permitir cobertura completa do `RecipeDatabase` sem mexer no fluxo funcional do jogo.
- Risco: a cobertura dos dados está completa, mas a fonte funcional principal ainda é o sistema legado até a migração final.

## Decisão 19 - Baú da Vila V1 sem UI
- Problema: o golem precisava de um destino físico simples para depositar itens.
- Decisão: criar um Baú da Vila V1 apenas como nó físico com inventário interno e console debug.
- Motivo: validar o ciclo colheita -> transporte -> depósito antes de qualquer interface.
- Risco: o baú ainda não tem UI, salvamento nem interação avançada.

## Decisão 20 - Colheita segura do golem
- Problema: a colheita automática antiga dependia de clique humano e era frágil para IA.
- Decisão: criar `harvest_by_golem()` no `FarmPlot` para colher 1 item básico sem usar `_on_plot_clicked()`.
- Motivo: separar a lógica do golem da lógica de interação manual.
- Risco: bônus extras, sementes bônus e variações sazonais ficam para depois.

## Decisão 21 - Golem físico V1 com depósito
- Problema: o golem físico existia só como placeholder visual.
- Decisão: ligar `Golem.gd` à cena e fazer o golem procurar lote maduro, colher e depositar no Baú da Vila.
- Motivo: validar o loop físico mínimo do coletor antes de upgrades e árvore de talentos.
- Risco: o `GolemManager` segue desligado e o sistema ainda não tem pathfinding nem UI do baú.

## Decisão 22 - UI simples do Baú da Vila
- Problema: os itens depositados pelo golem ficavam invisíveis para o jogador.
- Decisão: criar um painel simples para abrir o baú, listar o conteúdo e permitir `Retirar Tudo` para o inventário global.
- Motivo: manter o baú separado do inventário do jogador e tornar o fluxo claro antes do salvamento.
- Risco: retirada individual e persistência do baú ainda ficam para etapas futuras.

## Decisão 23 - Botão temporário de smoke test no Debug Panel
- Problema: o `FarmGridManager` e o `FarmTileData` precisavam de uma forma rápida de validação manual sem tocar no gameplay.
- Decisão: adicionar um botão temporário `Testar FarmGrid` no Debug Panel para executar `FarmGridManagerSmokeTest.run()`.
- Motivo: permitir checagem em memória da fundação do grid sem acoplar a cena ou os lotes atuais.
- Risco: a ferramenta é só de desenvolvimento e deve ser removida ou reorganizada quando o grid entrar de verdade no jogo.

## Decisão 34 - Preview visual isolado do FarmGrid
- Problema: a fundação do grid precisava de uma visualização manual simples sem tocar no `FarmPlot` ativo.
- Decisão: criar `Scenes/dev/FarmGridPreview.tscn` como cena isolada de preview visual para o grid futuro.
- Motivo: permitir experimentar desenho e interação de tiles sem conectar ao gameplay principal.
- Risco: a cena é só de teste e não deve virar uma rota paralela de jogo.

## Decisão 35 - Preview mostra Solo Vivo Alquimico
- Problema: o preview precisava validar nao só o estado do tile, mas tambem o tipo de solo do Farm System V2.
- Decisão: representar `soil_type` com bordas coloridas e alternancia por clique direito na cena isolada.
- Motivo: facilitar leitura visual do Solo Vivo Alquimico sem assets adicionais.
- Risco: a visualizacao continua provisoria e deve ser substituida quando a arte final chegar.

## Decisão 36 - Preview testa Enxada e decay diario
- Problema: o preview precisava validar a futura regra de arar com ferramenta ativa e o retorno de terra arada sem crop na virada do dia.
- Decisão: usar `Enxada` como ferramenta ativa padrão e simular o `Decay Diario` apenas em memória no preview.
- Motivo: experimentar o comportamento sem criar tempo real nem alterar o `FarmPlot` ativo.
- Risco: a regra ainda é conceitual e pode mudar quando o loop de fazenda em grid existir de verdade.

## Decisão 37 - Preview testa Semente fake
- Problema: o preview precisava validar a regra de que tiles plantados com semente não voltam para grama no decay diário.
- Decisão: adicionar uma ferramenta fake `Semente` que planta um crop de debug em memória (`debug_crop`).
- Motivo: permitir testar plantio e proteção contra decay sem inventário real, sem Database e sem gameplay principal.
- Risco: o crop fake existe só para validação e deve ser substituido por dados reais quando a fazenda em grid entrar de verdade.

## Decisão 38 - Preview testa Regador fake
- Problema: o preview precisava validar o próximo passo do loop de fazenda em grid, molhando terra arada e plantios de debug.
- Decisão: adicionar uma ferramenta fake `Regador`, selecionada por tecla `3`, que molha tiles `ARADO` e `PLANTADO` em memória.
- Motivo: testar água, umidade e estado molhado sem criar inventário, `PocoManager` ou gameplay principal.
- Risco: a lógica de água continua provisória e pode ser ajustada quando o grid estiver realmente integrado.

## Decisão 39 - Preview testa crescimento fake
- Problema: o preview precisava validar a leitura de crescimento do crop sem criar tempo real, sistema de fases ou gameplay principal.
- Decisão: adicionar a tecla `G` para avançar `remaining_growth_time` apenas em tiles plantados e irrigados, usando marcadores visuais maiores conforme o crop se aproxima da maturidade.
- Motivo: observar a curva de crescimento em memoria com uma regra simples e sem punir o jogador no prototipo.
- Risco: o escalonamento visual e a quantidade de estagios podem mudar quando a fazenda em grid entrar de verdade.

## Decisão 40 - Preview testa colheita fake
- Problema: o preview precisava fechar o loop minimo da fazenda em grid com uma etapa de colheita sem inventario real.
- Decisão: adicionar a tecla `4` para selecionar `Colheita` e colher apenas crops maduras, limpando o tile e devolvendo-o para `ARADO`.
- Motivo: validar a transicao crescimento -> colheita -> preparo para novo plantio sem acoplar o sistema real de itens.
- Risco: a regra de retorno para `ARADO` pode ser ajustada quando o loop de solo e plantio entrar no jogo principal.

## Decisão 41 - Checkpoint do FarmGrid
- Problema: o FarmGrid V2 precisava de um registro oficial do que ja foi validado e do que ainda e fake antes de qualquer integracao.
- Decisão: criar um checkpoint de arquitetura documentando o preview, o loop minimo validado, os riscos e a pendencia de logs globais em cenas dev.
- Motivo: manter o FarmGrid isolado enquanto o `FarmPlot` segue como sistema ativo e confiavel do prototipo.
- Risco: o checkpoint nao resolve os logs globais; ele apenas registra a pendencia para investigacao futura.

## Decisão 23 - Presenca fisica do golem
- Problema: o golem parecia sem volume e passava visualmente por baixo de elementos do mundo.
- Decisão: ajustar a ordenacao visual com z_index por Y, mover a interacao para um ponto lateral/abaixo do lote e adicionar um sensor simples de proximidade.
- Motivo: melhorar a leitura espacial sem implementar pathfinding.
- Risco: o movimento continua em linha reta e pode atravessar obstaculos; isso fica para uma etapa futura.

## Decisão 24 - Recompensas compartilhadas da colheita
- Problema: a colheita manual já tinha bônus e drops raros, mas o golem ainda colhia só um item básico.
- Decisão: centralizar a geração das recompensas em `FarmPlot` para que a colheita manual e a do golem usem o mesmo conjunto de bônus.
- Motivo: manter paridade de jogo entre o que o jogador colhe na mão e o que o golem entrega ao Baú da Vila.
- Risco: o golem agora pode depositar mais de um tipo de item por viagem, então o balanceamento futuro precisa considerar esse volume extra.

## Decisão 25 - Navegacao simples do golem
- Problema: o golem ainda atravessava visualmente o caldeirão e não contornava obstáculos.
- Decisão: substituir o Tween direto por navegação simples com `NavigationAgent2D` e rota por waypoints quando a linha cruza o caldeirão.
- Motivo: dar um comportamento físico mais crível sem introduzir um sistema pesado de pathfinding agora.
- Risco: a solução ainda é híbrida e simples; obstáculos mais complexos continuarão exigindo refinamento depois.

## Decisão 26 - Caldeirão como obstáculo físico
- Problema: o caldeirão precisava bloquear o caminho do golem no mundo.
- Decisão: adicionar um obstáculo físico simples ao caldeirão e uma região de navegação básica na área jogável inicial.
- Motivo: tornar a navegação do protótipo previsível sem mexer na UI do caldeirão.
- Risco: o obstáculo é provisório e a área navegável ainda é ampla demais para um mapa com mais complexidade.

## Decisão 27 - Golem com corpo físico
- Problema: a navegação por `Node2D` ainda permitia leitura estranha e não respeitava colisão de forma confiável.
- Decisão: usar `CharacterBody2D` no golem físico, mantendo `NavigationAgent2D` como guia de rota.
- Motivo: impedir que o golem atravesse o caldeirão sem abrir escopo para pathfinding completo agora.
- Risco: a navegação continua provisória e pode precisar de refinamento quando a fazenda crescer.

## Decisão 28 - Desvio simples ao travar
- Problema: mesmo com colisão física, o golem podia encostar no caldeirão e ficar preso sem reação útil.
- Decisão: detectar travamento e calcular um waypoint de desvio simples ao redor do caldeirão antes de seguir o destino original.
- Motivo: destravar o coletor sem restaurar a rota manual em L nem implementar pathfinding completo ainda.
- Risco: o desvio é heurístico e pode precisar ser revisto quando a fazenda e os obstáculos crescerem.

## Decisão 29 - Terra arada em camada baixa
- Problema: o golem ainda podia parecer escondido pela terra arada e pela base visual dos lotes.
- Decisão: manter a terra/base do lote em camada baixa e dar ao golem um offset visual levemente acima do campo.
- Motivo: preservar a leitura espacial do protótipo sem mexer em coleta, depósito ou navegação.
- Risco: o sistema de camadas ainda é provisório e pode receber refinamento quando a cena crescer.

## Decisão 30 - Terra fora da herança do lote
- Problema: lotes mais abaixo na tela ainda podiam cobrir parcialmente o golem por herança de z do `FarmPlot`.
- Decisão: desligar a herança de z dos visuais de solo do lote e manter planta, VFX e tooltip com camadas próprias.
- Motivo: impedir que o chão de lotes inferiores cubra o golem sem mexer no fluxo do jogo.
- Risco: isso resolve a leitura atual, mas o sistema de camadas ainda continua provisório.

## Decisão 31 - Save mínimo do Baú da Vila
- Problema: o conteúdo do Baú da Vila podia ser perdido ao fechar o jogo antes da retirada.
- Decisão: salvar e restaurar o `inventory` do baú em `village_chest_inventory` dentro do `SaveManager`.
- Motivo: manter o ciclo do golem e do baú persistente sem mexer ainda nos lotes, crops ou no salvamento completo do mundo.
- Risco: o save continua mínimo e ainda não persiste o estado dos lotes/plantações.

## Decisão 32 - Debug Panel V1 temporario
- Problema: os testes do protótipo estavam lentos para itens, receitas, lotes, save e Baú da Vila.
- Decisão: criar um painel de debug oculto na UI principal, aberto por `F10`, com ferramentas temporárias de teste.
- Motivo: acelerar a validação do protótipo sem transformar essas ações em mecânicas reais.
- Risco: o painel precisa continuar claramente temporário para não poluir o fluxo normal do jogo.

## Decisão 33 - Debug Panel nao bloqueia input fechado
- Problema: o painel de debug podia interferir com cliques do mundo quando estava escondido.
- Decisão: manter o `DebugPanel` em `mouse_filter = Ignore` enquanto fechado e só passar para `Stop` quando aberto.
- Motivo: preservar o atalho de debug sem quebrar o clique no caldeirao, no Livro de Receitas ou em outras interacoes normais.
- Risco: a regra de input precisa continuar simples para nao reintroduzir bloqueio quando o painel crescer.

## Decisão 34 - Paineis fechados ignoram mouse
- Problema: painéis modais e temporários da UI podiam continuar no caminho do clique do mundo.
- Decisão: padronizar `mouse_filter = Ignore` quando estão fechados e `Stop` apenas enquanto visíveis.
- Motivo: deixar o caldeirao e o Livro de Receitas clicáveis sem precisar desmontar a UI de protótipo.
- Risco: qualquer novo painel temporário precisa seguir a mesma regra para não voltar a bloquear interação.

## Decisão 35 - Save minimo dos lotes por ordem do grupo
- Problema: os lotes de plantacao podiam perder estado ao fechar o jogo.
- Decisão: salvar cada lote em um array ordenado pela ordem atual do grupo `lotes_terra` e restaurar por índice.
- Motivo: manter a solução simples e estável para o protótipo, sem criar ids novos agora.
- Risco: a estabilidade depende da ordem de instância dos lotes continuar previsível no protótipo.

## Decisão 36 - Status do jogo V1 informativo
- Problema: o protótipo precisava mostrar mais contexto geral durante os testes.
- Decisão: expandir o `StatusPanel` existente para exibir moedas, estação, ano, água, alquimia, golems e estado do Baú da Vila.
- Motivo: dar leitura rápida do estado atual sem criar uma UI nova ou interferir no fluxo do jogo.
- Risco: o painel continua provisório e pode ser refinado ou substituido quando a interface final for desenhada.

## Decisão 37 - Tempo real futuro com modo debug
- Problema: o jogo final precisa de um modelo de tempo coerente com sessões reais, mas o protótipo ainda depende de testes rápidos.
- Decisão: documentar tempo real como direção final, porém manter o desenvolvimento em modo debug/controlável por enquanto.
- Motivo: permitir um `TimeManager` futuro sem travar o fluxo de testes do protótipo.
- Risco: o sistema de tempo real pode afetar crops, estações, quests, economia e salvamento se for ativado cedo demais.

## Decisão 38 - TimeManager base sem Autoload
- Problema: o projeto precisava de uma fundação técnica para o tempo futuro sem acoplar gameplay cedo demais.
- Decisão: criar `Scripts/TimeManager.gd` como script solto, com modo real desligado por padrão e funções de debug internas.
- Motivo: permitir evolução segura da arquitetura de tempo antes de conectar `SeasonManager`, `SaveManager`, plantações e UI.
- Risco: enquanto o `TimeManager` não for integrado, ele serve só como base estrutural e ainda não altera o jogo.

## Decisão 39 - Farm System V2 como planejamento
- Problema: o sistema atual de lotes é funcional, mas limitado para a visão final de fazenda viva e alquímica.
- Decisão: documentar o Farm System V2 como evolução futura baseada em tiles/grid, sem substituir `FarmPlot` agora.
- Motivo: preservar o protótipo estável enquanto se prepara a transição para Solo Vivo Alquímico, caldeirão expandido e integrações com pesca, fazendinhas e golems.
- Risco: a migração futura vai exigir planejamento cuidadoso para não quebrar save, UI e fluxos já validados.

## Decisão 40 - FarmTileData como Resource isolado
- Problema: a futura fazenda em grid precisa de uma base de dados serializável sem mexer no sistema atual.
- Decisão: criar `Scripts/data/FarmTileData.gd` como `Resource` isolado, sem conectar ao gameplay ainda.
- Motivo: preparar a futura serialização do grid e manter o `FarmPlot` como sistema ativo enquanto isso.
- Risco: enquanto o grid não existir, o recurso serve apenas como fundação técnica e documentação executável.

## Decisão 41 - FarmGridManager base sem cena
- Problema: o grid futuro precisava de um coordenador de dados sem virar parte da cena ou do gameplay cedo demais.
- Decisão: criar `Scripts/data/FarmGridManager.gd` como `RefCounted`, isolado e sem `Autoload`.
- Motivo: permitir montagem, leitura e serialização de grids a partir de `FarmTileData` sem substituir `FarmPlot`.
- Risco: o gerenciador ainda não participa do jogo real e pode precisar de ajustes quando o grid começar a ser usado de verdade.

## Decisão 42 - Smoke test manual do grid
- Problema: a base do grid precisava de uma validação rápida sem acoplar à cena do jogo.
- Decisão: criar `Scripts/dev/FarmGridManagerSmokeTest.gd` como teste manual em memória.
- Motivo: facilitar checagem de criação, alteração e serialização do grid sem mexer no gameplay.
- Risco: o teste depende de execução manual e não substitui testes automatizados futuros.
