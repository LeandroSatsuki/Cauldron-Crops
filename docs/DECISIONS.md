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

## Decisão 20 - Icones provisorios na barra de ferramentas
- Problema: a Barra de Ferramentas V0 precisava de leitura visual melhor sem alterar gameplay.
- Decisão: aplicar icones provisórios em Enxada, Semente, Regador e Colheita mantendo botões do tipo `Button`.
- Motivo: reforçar a identidade visual da toolbar sem trocar a selecao global nem a logica de ferramentas.
- Risco: os icones sao provisórios e podem ser substituidos depois quando a arte final estiver pronta.

## Decisão 21 - Limpeza de logs do lago
- Problema: os logs temporários de carregamento do Lago da Fazenda V0 já cumpriram seu papel de diagnóstico.
- Decisão: remover apenas esses logs de inicialização, mantendo por enquanto os logs curtos de interação da pesca.
- Motivo: reduzir ruído no console sem perder visibilidade durante os testes do fluxo de lançamento e puxada fake.
- Risco: o lago continua dependendo de logs de interação para depuração rápida até a pesca V0 ser mais madura.

## Decisão 22 - Colheita segura do golem
- Problema: a colheita automática antiga dependia de clique humano e era frágil para IA.
- Decisão: criar `harvest_by_golem()` no `FarmPlot` para colher 1 item básico sem usar `_on_plot_clicked()`.
- Motivo: separar a lógica do golem da lógica de interação manual.
- Risco: bônus extras, sementes bônus e variações sazonais ficam para depois.

## Decisão 23 - Golem físico V1 com depósito
- Problema: o golem físico existia só como placeholder visual.
- Decisão: ligar `Golem.gd` à cena e fazer o golem procurar lote maduro, colher e depositar no Baú da Vila.
- Motivo: validar o loop físico mínimo do coletor antes de upgrades e árvore de talentos.
- Risco: o `GolemManager` segue desligado e o sistema ainda não tem pathfinding nem UI do baú.

## Decisão 24 - UI simples do Baú da Vila
- Problema: os itens depositados pelo golem ficavam invisíveis para o jogador.
- Decisão: criar um painel simples para abrir o baú, listar o conteúdo e permitir `Retirar Tudo` para o inventário global.
- Motivo: manter o baú separado do inventário do jogador e tornar o fluxo claro antes do salvamento.
- Risco: retirada individual e persistência do baú ainda ficam para etapas futuras.

## Decisão 25 - Botão temporário de smoke test no Debug Panel
- Problema: o `FarmGridManager` e o `FarmTileData` precisavam de uma forma rápida de validação manual sem tocar no gameplay.
- Decisão: adicionar um botão temporário `Testar FarmGrid` no Debug Panel para executar `FarmGridManagerSmokeTest.run()`.
- Motivo: permitir checagem em memória da fundação do grid sem acoplar a cena ou os lotes atuais.
- Risco: a ferramenta é só de desenvolvimento e deve ser removida ou reorganizada quando o grid entrar de verdade no jogo.

## Decisão 26 - Preview visual isolado do FarmGrid
- Problema: a fundação do grid precisava de uma visualização manual simples sem tocar no `FarmPlot` ativo.
- Decisão: criar `Scenes/dev/FarmGridPreview.tscn` como cena isolada de preview visual para o grid futuro.
- Motivo: permitir experimentar desenho e interação de tiles sem conectar ao gameplay principal.
- Risco: a cena é só de teste e não deve virar uma rota paralela de jogo.

## Decisão 27 - Preview mostra Solo Vivo Alquimico
- Problema: o preview precisava validar nao só o estado do tile, mas tambem o tipo de solo do Farm System V2.
- Decisão: representar `soil_type` com bordas coloridas e alternancia por clique direito na cena isolada.
- Motivo: facilitar leitura visual do Solo Vivo Alquimico sem assets adicionais.
- Risco: a visualizacao continua provisoria e deve ser substituida quando a arte final chegar.

## Decisão 28 - Preview testa Enxada e decay diario
- Problema: o preview precisava validar a futura regra de arar com ferramenta ativa e o retorno de terra arada sem crop na virada do dia.
- Decisão: usar `Enxada` como ferramenta ativa padrão e simular o `Decay Diario` apenas em memória no preview.
- Motivo: experimentar o comportamento sem criar tempo real nem alterar o `FarmPlot` ativo.
- Risco: a regra ainda é conceitual e pode mudar quando o loop de fazenda em grid existir de verdade.

## Decisão 29 - Preview testa Semente fake
- Problema: o preview precisava validar a regra de que tiles plantados com semente não voltam para grama no decay diário.
- Decisão: adicionar uma ferramenta fake `Semente` que planta um crop de debug em memória (`debug_crop`).
- Motivo: permitir testar plantio e proteção contra decay sem inventário real, sem Database e sem gameplay principal.
- Risco: o crop fake existe só para validação e deve ser substituido por dados reais quando a fazenda em grid entrar de verdade.

## Decisão 30 - Preview testa Regador fake
- Problema: o preview precisava validar o próximo passo do loop de fazenda em grid, molhando terra arada e plantios de debug.
- Decisão: adicionar uma ferramenta fake `Regador`, selecionada por tecla `3`, que molha tiles `ARADO` e `PLANTADO` em memória.
- Motivo: testar água, umidade e estado molhado sem criar inventário, `PocoManager` ou gameplay principal.
- Risco: a lógica de água continua provisória e pode ser ajustada quando o grid estiver realmente integrado.

## Decisão 31 - Preview testa crescimento fake
- Problema: o preview precisava validar a leitura de crescimento do crop sem criar tempo real, sistema de fases ou gameplay principal.
- Decisão: adicionar a tecla `G` para avançar `remaining_growth_time` apenas em tiles plantados e irrigados, usando marcadores visuais maiores conforme o crop se aproxima da maturidade.
- Motivo: observar a curva de crescimento em memoria com uma regra simples e sem punir o jogador no prototipo.
- Risco: o escalonamento visual e a quantidade de estagios podem mudar quando a fazenda em grid entrar de verdade.

## Decisão 32 - Preview testa colheita fake
- Problema: o preview precisava fechar o loop minimo da fazenda em grid com uma etapa de colheita sem inventario real.
- Decisão: adicionar a tecla `4` para selecionar `Colheita` e colher apenas crops maduras, limpando o tile e devolvendo-o para `ARADO`.
- Motivo: validar a transicao crescimento -> colheita -> preparo para novo plantio sem acoplar o sistema real de itens.
- Risco: a regra de retorno para `ARADO` pode ser ajustada quando o loop de solo e plantio entrar no jogo principal.

## Decisão 33 - Checkpoint do FarmGrid
- Problema: o FarmGrid V2 precisava de um registro oficial do que ja foi validado e do que ainda e fake antes de qualquer integracao.
- Decisão: criar um checkpoint de arquitetura documentando o preview, o loop minimo validado, os riscos e a pendencia de logs globais em cenas dev.
- Motivo: manter o FarmGrid isolado enquanto o `FarmPlot` segue como sistema ativo e confiavel do prototipo.
- Risco: o checkpoint nao resolve os logs globais; ele apenas registra a pendencia para investigacao futura.

## Decisão 34 - Presenca fisica do golem
- Problema: o golem parecia sem volume e passava visualmente por baixo de elementos do mundo.
- Decisão: ajustar a ordenacao visual com z_index por Y, mover a interacao para um ponto lateral/abaixo do lote e adicionar um sensor simples de proximidade.
- Motivo: melhorar a leitura espacial sem implementar pathfinding.
- Risco: o movimento continua em linha reta e pode atravessar obstaculos; isso fica para uma etapa futura.

## Decisão 35 - Recompensas compartilhadas da colheita
- Problema: a colheita manual já tinha bônus e drops raros, mas o golem ainda colhia só um item básico.
- Decisão: centralizar a geração das recompensas em `FarmPlot` para que a colheita manual e a do golem usem o mesmo conjunto de bônus.
- Motivo: manter paridade de jogo entre o que o jogador colhe na mão e o que o golem entrega ao Baú da Vila.
- Risco: o golem agora pode depositar mais de um tipo de item por viagem, então o balanceamento futuro precisa considerar esse volume extra.

## Decisão 36 - Navegacao simples do golem
- Problema: o golem ainda atravessava visualmente o caldeirão e não contornava obstáculos.
- Decisão: substituir o Tween direto por navegação simples com `NavigationAgent2D` e rota por waypoints quando a linha cruza o caldeirão.
- Motivo: dar um comportamento físico mais crível sem introduzir um sistema pesado de pathfinding agora.
- Risco: a solução ainda é híbrida e simples; obstáculos mais complexos continuarão exigindo refinamento depois.

## Decisão 37 - Caldeirão como obstáculo físico
- Problema: o caldeirão precisava bloquear o caminho do golem no mundo.
- Decisão: adicionar um obstáculo físico simples ao caldeirão e uma região de navegação básica na área jogável inicial.
- Motivo: tornar a navegação do protótipo previsível sem mexer na UI do caldeirão.
- Risco: o obstáculo é provisório e a área navegável ainda é ampla demais para um mapa com mais complexidade.

## Decisão 38 - Golem com corpo físico
- Problema: a navegação por `Node2D` ainda permitia leitura estranha e não respeitava colisão de forma confiável.
- Decisão: usar `CharacterBody2D` no golem físico, mantendo `NavigationAgent2D` como guia de rota.
- Motivo: impedir que o golem atravesse o caldeirão sem abrir escopo para pathfinding completo agora.
- Risco: a navegação continua provisória e pode precisar de refinamento quando a fazenda crescer.

## Decisão 39 - Desvio simples ao travar
- Problema: mesmo com colisão física, o golem podia encostar no caldeirão e ficar preso sem reação útil.
- Decisão: detectar travamento e calcular um waypoint de desvio simples ao redor do caldeirão antes de seguir o destino original.
- Motivo: destravar o coletor sem restaurar a rota manual em L nem implementar pathfinding completo ainda.
- Risco: o desvio é heurístico e pode precisar ser revisto quando a fazenda e os obstáculos crescerem.

## Decisão 40 - Terra arada em camada baixa
- Problema: o golem ainda podia parecer escondido pela terra arada e pela base visual dos lotes.
- Decisão: manter a terra/base do lote em camada baixa e dar ao golem um offset visual levemente acima do campo.
- Motivo: preservar a leitura espacial do protótipo sem mexer em coleta, depósito ou navegação.
- Risco: o sistema de camadas ainda é provisório e pode receber refinamento quando a cena crescer.

## Decisão 41 - Terra fora da herança do lote
- Problema: lotes mais abaixo na tela ainda podiam cobrir parcialmente o golem por herança de z do `FarmPlot`.
- Decisão: desligar a herança de z dos visuais de solo do lote e manter planta, VFX e tooltip com camadas próprias.
- Motivo: impedir que o chão de lotes inferiores cubra o golem sem mexer no fluxo do jogo.
- Risco: isso resolve a leitura atual, mas o sistema de camadas ainda continua provisório.

## Decisão 42 - Save mínimo do Baú da Vila
- Problema: o conteúdo do Baú da Vila podia ser perdido ao fechar o jogo antes da retirada.
- Decisão: salvar e restaurar o `inventory` do baú em `village_chest_inventory` dentro do `SaveManager`.
- Motivo: manter o ciclo do golem e do baú persistente sem mexer ainda nos lotes, crops ou no salvamento completo do mundo.
- Risco: o save continua mínimo e ainda não persiste o estado dos lotes/plantações.

## Decisão 43 - Debug Panel V1 temporario
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

## Decisão 43 - PocoManager ignora cenas dev
- Problema: cenas de desenvolvimento, como `FarmGridPreview`, estavam recebendo agua automaticamente pelo `PocoManager` global.
- Decisão: adicionar uma guarda para que o `PocoManager` nao processe geracao automatica de agua quando a cena atual estiver em `res://Scenes/dev/`.
- Motivo: limpar o ruido dos testes isolados sem remover o Autoload nem alterar o comportamento do jogo principal.
- Risco: a filtragem depende do caminho da cena e precisa continuar alinhada com a organizacao das cenas dev.

## Decisão 44 - Ferramenta Ativa V0 no jogo principal
- Problema: o jogo principal ainda nao tinha um estado global simples para a ferramenta ativa, embora o preview ja tivesse validado o conceito em laboratorio.
- Decisão: criar `Scripts/ToolManager.gd` como `Autoload`, com a `Enxada` como primeira ferramenta real apenas para selecao visual/global.
- Motivo: preparar a futura ponte entre UI, atalhos e sistemas de fazenda sem alterar o `FarmPlot` agora.
- Risco: se essa base for ligada cedo demais ao clique no mundo, pode quebrar o prototipo atual ou confundir a selecao de ferramenta com gameplay real.

## Decisão 45 - Limpeza tecnica de logs
- Problema: a selecao de ferramenta repetia log quando a mesma opcao era acionada de novo, e o caldeirao ainda tinha um print temporario de debug.
- Decisão: impedir log repetido no `ToolManager` quando a ferramenta ja estiver selecionada e remover o `DEBUG Cauldron: clique recebido`.
- Motivo: reduzir ruído de console sem mudar o comportamento do jogo principal.
- Risco: a limpeza so trata ruído de log; outras mensagens de debug podem continuar existindo por design em outras partes do projeto.

## Decisão 46 - Ferramentas visuais globais expandidas
- Problema: a base de ferramenta ativa precisava deixar de ser apenas `Enxada` e passar a espelhar o conjunto visual validado no preview.
- Decisão: expandir `ToolManager` e a UI principal para `Enxada`, `Semente`, `Regador` e `Colheita`, mantendo tudo sem ação real por enquanto.
- Motivo: preparar a navegação global de ferramentas sem tocar no `FarmPlot` nem no `FarmGrid`.
- Risco: a seleção global ainda não executa ação, então a UI pode sugerir mais capacidade do que o gameplay realmente oferece.

## Decisão 47 - Limpeza tecnica da UI
- Problema: a UI principal ainda exibia um print temporario ao abrir o Livro de Receitas, poluindo o console sem trazer valor de depuracao.
- Decisão: remover apenas `DEBUG UI: botão livro de receitas clicado`, mantendo warnings uteis e o comportamento normal da interface.
- Motivo: reduzir ruído de console sem mexer em fluxo de abertura, receitas ou gameplay.
- Risco: outros prints temporarios podem ainda existir em partes antigas do projeto e precisarem de limpeza separada.

## Decisão 48 - Toolbar principal sem Semente
- Problema: a toolbar principal misturava uma ferramenta de teste com as ferramentas reais do jogo.
- Decisão: manter `Semente` apenas no `FarmGridPreview` e deixar a toolbar principal com Enxada, Regador e Colheita.
- Motivo: alinhar a UI principal ao design atual sem perder a semente fake do laboratório isolado.
- Risco: a separação exige cuidado para não reaparecerem atalhos ou botões de Semente fora do preview.

## Decisão 49 - Agua fora da lista visual do inventario
- Problema: a agua era exibida como item comum na barra visual de inventário, embora já tivesse leitura dedicada no StatusPanel.
- Decisão: manter `GlobalInventory.inventario["agua"]` como fonte real, mas ocultar `agua` da lista visual de itens comuns.
- Motivo: deixar o contador de agua no StatusPanel como referência principal, sem mexer em save, FarmPlot ou PocoManager.
- Risco: qualquer nova UI que liste o inventário precisa lembrar desse filtro para não mostrar a água de novo.

## Decisão 50 - Prioridade da ferramenta ativa no lote
- Problema: com uma semente selecionada no inventário, o clique no lote podia plantar mesmo quando uma ferramenta ativa já havia sido escolhida.
- Decisão: dar prioridade à ferramenta ativa do `ToolManager` sobre a semente selecionada no lote.
- Motivo: evitar plantio acidental quando o jogador quer regar, usar enxada ou preparar a colheita.
- Risco: como Enxada e Colheita ainda não executam ação real no `FarmPlot`, a interação vira bloqueio intencional até o comportamento dessas ferramentas existir de fato.

## Decisão 51 - Separação entre ferramentas, sementes e água
- Problema: ferramentas, sementes e água estavam misturadas demais entre UI, inventário e interação de lote, deixando a leitura do jogo menos clara.
- Decisão: tratar ferramentas como modo de ação global via `ToolManager`, sementes como itens do inventário no jogo principal e água como recurso visual no `StatusPanel` com armazenamento interno em `GlobalInventory.inventario["agua"]`.
- Motivo: manter o protótipo legível sem quebrar o fluxo atual de plantio, rega, save e o laboratório isolado do FarmGrid.
- Risco: qualquer nova UI ou sistema de interação precisa respeitar essa separação para não reintroduzir a mistura entre item, recurso e ferramenta.

## Decisão 52 - Enxada V0 no FarmPlot atual
- Problema: o jogo principal ainda precisava de uma primeira ação real da Enxada sem abrir aragem livre nem migrar para o FarmGrid.
- Decisão: adicionar um flag simples de preparo no `FarmPlot`, permitir arar lote vazio com Enxada e exigir lote arado para plantio futuro, preservando o estado no save.
- Motivo: introduzir a Enxada como ação real de forma controlada, mantendo `FarmPlot` ativo e o `FarmGrid` isolado.
- Risco: a regra de plantio passa a depender do preparo do lote, então qualquer futura mudança no fluxo de sementes precisa respeitar esse estado.

## Decisão 53 - Area Preparavel V0 com lotes potenciais
- Problema: o jogador precisava sentir que novos campos podem ser criados sem instanciar lotes por clique nem migrar para o FarmGrid.
- Decisão: manter os 16 `FarmPlot` originais na mesma ordem e adicionar lotes potenciais extras no final da sequencia, todos iniciando com `arado = false`.
- Motivo: ampliar a area jogavel de forma segura, preservando saves antigos por ordem e evitando criar uma rota livre de instanciacao.
- Risco: a area continua baseada em `FarmPlot` fixo e visual provisório, então futuras mudanças na grade precisam preservar a ordem append-only.

## Decisão 54 - Visual da Area Preparavel
- Problema: lote nao arado ainda parecia campo pronto demais, o que atrapalhava a leitura da Area Preparavel V0.
- Decisão: usar uma aparencia provisoria mais natural/esverdeada quando o lote estiver vazio e nao arado, mantendo terra arada seca e molhada com as texturas adubadas ja existentes.
- Motivo: deixar claro o estado do solo sem criar asset novo nem mexer em save, golem ou FarmGrid.
- Risco: o visual natural ainda é provisório e pode precisar ser refinado quando a arte final da fazenda for definida.

## Decisão 55 - Decay Diario V0 manual
- Problema: o prototipo precisava validar a limpeza de lotes arados vazios sem conectar tempo real ou migrar para o FarmGrid.
- Decisão: criar um botão manual no Debug Panel que aplica decay apenas em `FarmPlot` vazios e arados, preservando lotes plantados e prontos para colher.
- Motivo: testar a regra de volta ao estado natural de forma controlada, sem mexer no `TimeManager`, no `SaveManager` ou no comportamento automático do jogo principal.
- Risco: como ainda é manual/debug, a futura transição para tempo real vai precisar reaproveitar a mesma regra sem duplicar lógica.

## Decisão 56 - Colheita V0 por ferramenta
- Problema: a ferramenta `Colheita` existia na toolbar, mas ainda não acionava a colheita manual do `FarmPlot`.
- Decisão: fazer a ferramenta `Colheita` reutilizar a mesma lógica manual de recompensa quando o lote estiver pronto, sem duplicar geração de drops e sem alterar o golem.
- Motivo: deixar a ferramenta ativa coerente com o fluxo já existente, reaproveitando o caminho manual que já calcula recompensas, bônus e reset do lote.
- Risco: como a Colheita ainda não cobre ações adicionais fora do estado pronto, qualquer expansão futura precisa manter o mesmo helper compartilhado.

## Decisão 57 - Checkpoint do loop de ferramentas
- Problema: o loop atual de ferramentas, água e sementes já estava funcional no protótipo, mas sem um checkpoint curto reunindo as regras centrais.
- Decisão: registrar o Loop de Ferramentas V0 como estado atual oficial do jogo principal, com ferramentas globais, sementes como item, água no StatusPanel e Decay Diário ainda manual/debug.
- Motivo: deixar claro o contrato arquitetural antes de novas expansões, evitando misturar ferramenta, item e recurso de novo.
- Risco: futuras mudanças em UI, plantio ou tempo real precisam respeitar esse checkpoint para não reabrir o acoplamento entre sistemas.

## Decisão 58 - Feedback visual das ferramentas
- Problema: o loop já funcionava, mas parte das respostas das ferramentas e avisos do `FarmPlot` ficava restrita ao console.
- Decisão: reaproveitar o texto flutuante existente da UI para mostrar feedback visual de Enxada, Regador, Colheita e avisos principais do lote.
- Motivo: melhorar a leitura do jogo sem criar popup novo e sem alterar regras de plantio, rega, colheita ou save.
- Risco: o feedback visual precisa continuar leve e consistente para não virar ruído ou sobreposição excessiva de mensagens.

## Decisão 59 - Filtragem de logs de agua
- Problema: os logs de `GlobalInventory` para `agua` geravam ruído constante no console, mesmo com a agua já aparecendo de forma dedicada no StatusPanel.
- Decisão: filtrar logs de adição e remoção quando `item_id == "agua"`, mantendo os demais logs de inventário.
- Motivo: reduzir ruído sem esconder o comportamento real do inventário para outros itens.
- Risco: como o inventário ainda é útil para depuração, qualquer novo caso especial precisa ser revisado para não esconder bugs importantes.

## Decisão 60 - Fishing System - Pesca de Ressonancia
- Problema: o jogo precisava de uma direção clara para pesca sem tratar o sistema como uma cena de laboratório isolada.
- Decisão: registrar a pesca como sistema integrado ao lago real da fazenda, com Vara de Pesca, áreas opcionais de movimento e um minigame de sincronia leve.
- Motivo: manter a pesca acessível, mágica e coerente com o ecossistema alquímico, sem quebrar o loop agrícola já estável.
- Risco: a primeira implementação precisa ser pequena e controlada para não acoplar pesca, inventário, caldeirão e tempo real ao mesmo tempo.

## Decisão 61 - Vara de Pesca como ferramenta visual global
- Problema: a direção de pesca já estava definida, mas faltava uma base visual na toolbar principal para a ferramenta futura.
- Decisão: incluir a `Vara de Pesca` como ferramenta visual/global no `ToolManager` e na toolbar do jogo principal, sem acionar pesca real ainda.
- Motivo: preparar a navegação da interface e deixar claro para o jogador onde a pesca futura vai entrar, sem mexer no loop agrícola.
- Risco: a presença da ferramenta pode sugerir funcionalidade ainda inexistente, então o feedback visual e a documentação precisam continuar deixando claro que a pesca real ainda não foi implementada.

## Decisão 62 - Lago da Fazenda V0 clicável
- Problema: a pesca precisava sair do papel e ganhar um ponto físico no mundo principal sem virar minigame completo.
- Decisão: criar um `FishingSpot` simples na cena principal que só responde ao clique quando a `Vara de Pesca` está ativa.
- Motivo: validar o ponto físico da pesca com feedback mínimo antes de abrir boia, sincronia, recompensas e áreas especiais.
- Risco: o lago existe apenas como base mínima por enquanto; a pescaria real e os efeitos mais ricos ficam para fases futuras.

## Decisão 63 - Boia V0 única e reposicionável
- Problema: o lago precisava de um primeiro estado visual da pesca sem multiplicar objetos ou criar fluxo de minigame cedo demais.
- Decisão: representar a pescaria com uma única boia ativa, que é reposicionada quando o jogador clica novamente com a Vara de Pesca.
- Motivo: manter o protótipo simples, legível e fácil de expandir para puxada, timing e recompensa depois.
- Risco: a boia ainda não tem comportamento de jogo além de posição visual, então o sistema real de pesca continua para etapas futuras.

## Decisão 64 - Puxada Fake V0 por timer
- Problema: a boia precisava evoluir para um segundo estado visual sem abrir ainda o minigame de sincronia.
- Decisão: usar um timer simples para mudar a boia para um estado de puxada fake após alguns segundos e encerrar o teste quando o jogador clicar de novo com a Vara ativa.
- Motivo: validar a leitura da pesca em pequenos passos, mantendo a implementação controlada e sem recompensa.
- Risco: o timer ainda não representa a mecânica final de pesca; ele é apenas a ponte visual para a etapa de sincronia futura.

## Decisão 65 - Popup de Sincronia V0 no lago
- Problema: a puxada fake já estava validada, mas faltava um ponto de interação simples para testar a sincronia sem criar um minigame grande.
- Decisão: abrir um popup leve de Pesca de Ressonância diretamente da UI principal quando a puxada fake estiver ativa e o jogador clicar de novo com a Vara de Pesca.
- Motivo: manter a pesca integrada ao lago da fazenda, com feedback claro e sem acoplar recompensa, inventário ou caldeirão nesta fase.
- Risco: o popup precisa continuar pequeno, legível e fácil de fechar para não competir com o loop agrícola.

## Decisão 66 - Popup aceita Espaço e clique em qualquer área
- Problema: o popup de sincronia estava preso ao clique exato na barra e permitia novo lançamento durante a etapa aberta.
- Decisão: fazer o popup aceitar Espaço e clique em qualquer área da janela, e bloquear nova boia enquanto a sincronia estiver ativa.
- Motivo: melhorar a usabilidade e evitar conflito com o FishingSpot sem transformar o protótipo em uma cópia literal de outro minigame.
- Risco: a janela precisa continuar leve e previsível para não competir com o loop agrícola nem com a leitura do lago.

## Decisão 67 - Encerrar pesca preserva a Vara de Pesca
- Problema: o minigame precisava fechar sem quebrar o fluxo de pesca contínua.
- Decisão: ao encerrar a sincronia, forçar a `Vara de Pesca` como ferramenta ativa e deixar apenas o `FishingSpot` voltar para `IDLE`.
- Motivo: permitir uma nova tentativa imediata no lago sem exigir re-seleção da ferramenta e sem depender do toggle de `select_fishing_rod()`.
- Risco: a UI precisa continuar atualizando o status da ferramenta de forma consistente depois do reset do lago.

## Decisão 68 - Recompensa Aquatica V0
- Problema: o popup de sincronia já validava timing e feedback, mas ainda não gerava uma recompensa simples para o jogador.
- Decisão: fazer o resultado do popup entregar `peixe_comum` para `Bom` e `escama_brilhante` para `Perfeito`, mantendo `Errou` sem item.
- Motivo: deixar a pesca com um retorno inicial concreto no inventário sem conectar ainda caldeirão, receitas ou árvore de alquimia.
- Risco: os nomes, o balanceamento e o catálogo de recompensas continuam provisórios e podem ser refinados depois.

## Decisão 69 - Áreas com Movimento V0 da pesca
- Problema: o lago já funcionava, mas ainda faltava um ponto visual especial que favorecesse a sincronia sem obrigar o jogador a pescá-lo.
- Decisão: adicionar uma área com movimento V0 no Lago da Fazenda, com visual sutil e bônus simples no popup quando a boia é lançada dentro dela.
- Motivo: reforçar a leitura de um ponto especial no lago sem transformar a pesca em um minigame punitivo.
- Regra atual: o resultado `GOOD` pode ser promovido para `PERFECT` quando a boia é lançada dentro da área favorecida.
- Risco: a área continua sendo um V0 provisório e pode receber nova arte, variação visual ou regras mais ricas depois.

## Decisão 70 - Visibilidade da área com movimento
- Problema: a área especial existia na lógica, mas ainda podia ficar difícil de enxergar no runtime.
- Decisão: reforçar o desenho da `MovingFishingArea` com anel, brilho e pulso visual mais fortes, sem mudar o boost da pesca.
- Motivo: garantir que o jogador veja claramente onde existe um ponto favorecido no lago.
- Risco: o visual ainda é provisório e pode ser refinado ou substituído depois.

## Decisão 71 - Catálogo de Itens V0
- Problema: itens, crops e recompensas estavam ficando espalhados entre UI, pesca, cultivo e dados legados.
- Decisão: centralizar metadados básicos em `Scripts/Database.gd`, reaproveitando o autoload que o projeto já usa.
- Motivo: preparar nomes, ícones, raridade, venda e tags sem criar um sistema novo desnecessário agora.
- Regra atual: a UI consulta o catálogo primeiro para ícones/emoji, e os IDs da pesca já estão registrados no mesmo catálogo.
- Risco: os valores e descrições continuam provisórios e ainda podem mudar quando venda, receitas e filtros forem refinados.
