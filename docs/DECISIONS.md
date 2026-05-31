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

## Decisão 14 - RecipeData criado sem acoplar ao jogo
- Problema: o projeto precisava de uma base tipada para receitas sem quebrar o fluxo atual.
- Decisão: criar `RecipeData` e receitas `.tres` de teste como camada estrutural paralela.
- Motivo: preparar a migração futura enquanto o caldeirao continua lendo `Database.receitas_alquimia`.
- Risco: dois formatos vivem ao mesmo tempo por enquanto, entao o acoplamento futuro precisara ser feito com cuidado.

## Decisão 15 - RecipeDatabase apenas de leitura
- Problema: o projeto precisava validar `Resource` de receitas sem trocar a fonte principal ainda.
- Decisão: criar `RecipeDatabase.gd` somente para carregar, validar e comparar receitas.
- Motivo: permitir a migração futura de forma segura, sem acoplar o caldeirao nesta etapa.
- Risco: a manutenção temporaria de dois sistemas de receita continua exigindo disciplina na migracao.

## Decisão 16 - Livro de Receitas em paralelo com fallback
- Problema: o Livro de Receitas precisava mostrar dados ricos sem abandonar a fonte antiga.
- Decisão: usar `RecipeDatabase` apenas para leitura e exibição complementar no Livro, mantendo `Database.receitas_alquimia` como fallback obrigatório.
- Motivo: validar o novo formato sem mexer no caldeirao nem na producao em lote.
- Risco: o jogo continua com dois caminhos de dados ativos até a migracao completa ser validada.

## Decisão 17 - Cobertura completa das receitas legadas
- Problema: ainda faltavam `.tres` para parte do catálogo legado.
- Decisão: criar `RecipeData` para todas as receitas que ainda só existiam em `Database.receitas_alquimia`.
- Motivo: permitir cobertura completa do `RecipeDatabase` sem mexer no fluxo funcional do jogo.
- Risco: a cobertura dos dados está completa, mas a fonte funcional principal ainda é o sistema legado até a migração final.

## Decisão 18 - Baú da Vila V1 sem UI
- Problema: o golem precisava de um destino físico simples para depositar itens.
- Decisão: criar um Baú da Vila V1 apenas como nó físico com inventário interno e console debug.
- Motivo: validar o ciclo colheita -> transporte -> depósito antes de qualquer interface.
- Risco: o baú ainda não tem UI, salvamento nem interação avançada.

## Decisão 19 - Colheita segura do golem
- Problema: a colheita automática antiga dependia de clique humano e era frágil para IA.
- Decisão: criar `harvest_by_golem()` no `FarmPlot` para colher 1 item básico sem usar `_on_plot_clicked()`.
- Motivo: separar a lógica do golem da lógica de interação manual.
- Risco: bônus extras, sementes bônus e variações sazonais ficam para depois.

## Decisão 20 - Golem físico V1 com depósito
- Problema: o golem físico existia só como placeholder visual.
- Decisão: ligar `Golem.gd` à cena e fazer o golem procurar lote maduro, colher e depositar no Baú da Vila.
- Motivo: validar o loop físico mínimo do coletor antes de upgrades e árvore de talentos.
- Risco: o `GolemManager` segue desligado e o sistema ainda não tem pathfinding nem UI do baú.

## Decisão 21 - UI simples do Baú da Vila
- Problema: os itens depositados pelo golem ficavam invisíveis para o jogador.
- Decisão: criar um painel simples para abrir o baú, listar o conteúdo e permitir `Retirar Tudo` para o inventário global.
- Motivo: manter o baú separado do inventário do jogador e tornar o fluxo claro antes do salvamento.
- Risco: retirada individual e persistência do baú ainda ficam para etapas futuras.
