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
