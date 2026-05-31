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
