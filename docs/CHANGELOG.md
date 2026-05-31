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
