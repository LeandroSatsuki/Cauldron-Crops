# Roadmap

## Fase 0 - Estado Atual
- O projeto já possui sistemas iniciais.
- O golem automático foi desativado temporariamente para estabilizar testes manuais.

## Fase 1.5 - Ajudantes e gestão runtime-only
- Interface do Golem V0 adicionada para expor status, talento, tarefa atual e prioridade de trabalho.
- A prioridade do golem permanece runtime-only nesta V0; reiniciar o jogo volta ao comportamento padrão.
- O Golem Irrigador passou a regar lotes plantados e secos quando o talento está desbloqueado, sem criar um novo golem.

## Fase 1 - Protótipo jogável do loop principal

### Objetivo da Fase 1
Entregar um protótipo jogável e estável do loop principal da fazenda, com plantio, cultivo, colheita, uso do caldeirão, descoberta de receitas e persistência mínima suficiente para testar uma sessão inteira.

### O que já está concluído
- Inventário base.
- Agricultura em lotes fixos.
- Enxada preparando lotes.
- Plantio.
- Rega.
- Colheita.
- Caldeirão.
- Livro de Receitas.
- Produção em lote.
- Save/load mínimo.
- Golem coletor básico.
- Painel de Purificação V0.
- Expansão V0 pós-purificação.
- UX V1 do Painel de Purificação.
- Feedback Visual V0 da Purificação.
- Correção de UI para evitar erro de `current_scene` nulo.
- Teste de loop completo da Fase 1 em save limpo validado manualmente.
- Build/demo Windows da Fase 1 gerada com sucesso e validada manualmente.

### O que ainda falta para fechar a Fase 1
- Conteúdo mínimo de receitas.
- Tutorial/objetivos mínimos para guiar o jogador.
- Auditoria final de save/load.
- Decisão sobre segunda área corrompida.
- Limpeza/registro dos warnings antigos.
- Registro final da build/demo já validada.

### O que fica explicitamente fora da Fase 1
- FarmGrid livre.
- Migração completa de receitas para `Resource .tres`.
- Sistema grande de construção.
- Balanceamento profundo.
- Automação completa avançada.
- Arte final de todos os sistemas.
- Refatoração grande de save.

### Critérios objetivos para considerar a Fase 1 fechada
- Um save novo permite completar o loop principal sem bloqueio crítico.
- O jogador consegue plantar, regar, colher, cozinhar e descobrir receitas sem instrução externa.
- O save/load preserva o estado mínimo necessário para retomar a sessão sem perda de progresso essencial.
- A purificação V0 e a expansão V0 funcionam de forma reproduzível em uma sessão limpa.
- Não há erros vermelhos no headless do fluxo principal.
- Os warnings antigos estão documentados ou aceitos como dívida técnica consciente.
- Existe uma build/demo Windows da Fase 1 gerada com sucesso, validada manualmente e pronta para distribuição local.

### Próxima tarefa recomendada
Avançar para o conteúdo mínimo da Fase 1 remanescente e manter a documentação da build/demo como referência de release local.

## Fase 1.5 - Layout macro e preparação da fazenda
- Documentar o layout macro da fazenda.
- Fazer blockout visual leve do mapa, sem gameplay novo.
- Reservar espaço para a segunda área corrompida.
- Definir zonas principais por função.
- Manter a Fase 1 funcional intacta enquanto a fazenda ganha forma maior.
- Criar a Missão Inicial V0 runtime-only, separada do QuestManager, para guiar o loop principal sem persistência.
- Evoluir o golem físico existente com o talento `Golem Irrigador`, preservando a coleta e adicionando suporte a rega sem criar uma entidade nova.

## Fase 2 - Solo livre e expansão sistêmica
- Implementar solo livre / FarmGrid real.
- Permitir criação e remoção de lotes.
- Tornar a segunda área corrompida funcional.
- Expandir o save de forma maior, se necessário.
- Avaliar a migração real para FarmGrid, se aprovada.
- Corrigir a UI do caldeirão.
- Revisar o inventário.
- Revisar a venda.
- Corrigir o golem físico ou mantê-lo desativado.
- Preparar o salvamento.
- Expandir a UI de status para leitura rápida do estado geral.

## Fase 3 - Dados Escaláveis
- Decidir o formato para crops, itens e receitas.
- Avaliar `Resource .tres`, JSON ou CSV.
- Criar um padrão de receitas.
- Limpar logs temporários da pesca que já não servem mais para diagnóstico.
- Documentar a arquitetura futura de tempo real antes de conectar gameplay.
- Criar a base do `TimeManager` sem integrar ao gameplay ainda.
- Documentar o Farm System V2 antes de qualquer migração da fazenda.
- Criar `FarmTileData` como estrutura isolada para o grid futuro.
- Criar `FarmGridManager` como coordenador isolado do grid futuro.
- Criar smoke tests manuais para validar a fundação do grid.
- Adicionar um botão temporário no Debug Panel para rodar o smoke test manual.
- Criar uma cena de preview visual isolada para testar o FarmGrid em memória.
- Visualizar tipos de solo alquímico no preview isolado do FarmGrid.
- Testar ferramenta ativa Enxada e decay diario no preview isolado do FarmGrid.
- Adicionar Decay Diario V0 manual/debug no Debug Panel do jogo principal para validar lotes arados vazios.
- Testar ferramenta fake Semente para validar plantio e proteção contra decay.
- Testar ferramenta fake Regador para validar molhar terra arada e plantio.
- Testar crescimento fake em tiles irrigados com a tecla `G` e marcadores visuais por estagio.
- Testar ferramenta fake Colheita para fechar o loop minimo no preview isolado do FarmGrid.
- Registrar o checkpoint oficial do FarmGrid e investigar os logs globais em cenas dev.
- Criar a base da Ferramenta Ativa V0 no jogo principal com `ToolManager`.
- Exibir a ferramenta ativa no StatusPanel e selecionar `Enxada` por botão e tecla `1`.
- Expandir a seleção global para `Semente`, `Regador` e `Colheita` sem ações reais.
- Fazer `Colheita` agir de verdade no `FarmPlot` usando a recompensa manual já existente.
- Aplicar icones provisorios na Barra de Ferramentas V0 sem alterar a selecao global.
- Ajustar a toolbar principal para ficar só com Enxada, Regador e Colheita, mantendo Semente apenas no FarmGridPreview.
- Separar a agua da lista visual de inventário e usar o StatusPanel como referencia principal de agua.
- Dar prioridade da ferramenta ativa sobre a semente selecionada no clique do FarmPlot.
- Consolidar a separacao entre ferramentas, sementes e agua antes de qualquer migracao maior.
- Aplicar a Enxada V0 experimental nos `FarmPlot` atuais, sem abrir aragem livre no mapa.
- Fazer o plantio respeitar lote arado antes de qualquer migracao grande da fazenda em grid.
- Expandir a area preparavel com lotes potenciais append-only, mantendo os 16 lotes originais intactos.
- Refinar a leitura visual da area preparavel e do solo natural sem criar novos assets agora.
- Consolidar o checkpoint do Loop de Ferramentas V0 antes de abrir novos caminhos de ação.
- Ampliar feedback visual para ferramentas e avisos do FarmPlot sem poluir a interface.
- Planejar feedback visual/flutuante para ações de ferramenta sem transformar a toolbar em inventário.
- Continuar melhorando mensagens de erro e avisos do FarmPlot para reduzir ruído durante testes.
- Seguir limpando logs repetitivos e revisar se outros recursos especiais merecem filtragem semelhante à agua.
- Refinar o Decay Diário manual antes de ligar qualquer virada de dia automatizada.
- Planejar a futura integração com tempo real sem quebrar o protótipo atual.
- Manter o FarmGrid em laboratório até a migração ser planejada com segurança.
- Documentar Fishing System.
- Consolidar a Vara de Pesca como ferramenta visual/global no jogo principal.
- Criar Vara de Pesca como ferramenta futura.
- Consolidar o Lago da Fazenda V0 como ponto físico/clicável da fazenda.
- Refinar FishingSpot V0 sem sair do loop mínimo.
- Adicionar boia V0 única e reposicionável no ponto clicado do lago.
- Adicionar puxada fake V0 com timer e estado visual da linha.
- Consolidar o Popup de Sincronia V0 da pesca.
- Consolidar a Recompensa Aquática V0.
- Consolidar as Áreas com Movimento V0 no Lago da Fazenda e revisar o boost de sincronia.
- Reforçar a leitura visual do ponto favorecido do lago até ele ficar legível em qualquer resolução alvo.
- Expandir o Catálogo de Itens V0 conforme a UI, a pesca e as crops forem pedindo metadados novos.
- Garantir que o popup da pesca consuma Espaço e force a Vara ativa ao fechar.
- Consolidar a Vara de Pesca como ferramenta visual/global na toolbar principal antes da pesca real.
- Documentar o Sistema de Expansão e Purificação da Fazenda como pilar central do mapa final.
- Definir o visual da primeira área bloqueada da fazenda.
- Preparar a arquitetura do `Main.gd` para múltiplas áreas de expansão por `obstacle_id` antes de adicionar a V1.
- Obstáculo Mágico V0 evoluído para um `PurificationPanel` com entrega parcial persistente.

- Ligar pesca, agricultura e alquimia como fontes dos requisitos da purificação.
- Manter o sistema provisório de debug enquanto o caldeirão ainda não cria esses itens de forma real.
- Ligar a receita V0 `agua` + `peixe_comum` para produzir `pocao_purificadora_fraca` no caldeirão.
- Garantir que o livro e o modo lote reconstruam essa receita via `RECEITA_ITEM_IDS`.
- Validar o save/load parcial com F5/F9 antes de expandir para outras áreas.
- Liberar uma pequena área com `FarmPlot` potenciais após a purificação.
- Consolidar o Obstáculo Mágico V0 com item provisório e save mínimo antes de expandir áreas.
- Expansão V0 já implementada como pocket fixo 2x2 de `FarmPlot` liberado pela purificação.
- Só depois conectar com inventário, caldeirão e árvore de alquimia.

## Fase 4 - Conteúdo
- Novas crops.
- Novas receitas.
- Missões.
- Progressão.
- Upgrades.
- Conceber a futura transição de lotes fixos para grid/tile sem alterar o protótipo atual.

## Fase 5 - Polimento
- Arte final pixel art.
- Áudio.
- Animações.
- Balanceamento.
- UX.
- Refinar a UI de status e os indicadores provisórios.
- Integrar o tempo real apenas quando o protótipo estiver estável.
- Adicionar feedback visual provisório para a conclusão da purificação.
