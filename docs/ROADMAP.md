# Roadmap

## Fase 0 - Estado Atual
- O projeto já possui sistemas iniciais.
- O golem automático foi desativado temporariamente para estabilizar testes manuais.

## Fase 1 - Loop Mínimo Jogável
- Plantar.
- Colher.
- Inventário.
- Caldeirão.
- Receita descoberta.
- Feedback visual mínimo.

## Fase 2 - Estabilização
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
