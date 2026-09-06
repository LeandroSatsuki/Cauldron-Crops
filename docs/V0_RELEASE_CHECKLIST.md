# Checklist de Release — V0

Use uma build limpa e, para testar a rota completa, inicie um save novo.

## Sessão principal

- O mapa abre sem caixas, contornos ou rótulos técnicos de layout.
- Arar, plantar, regar, crescer e colher funcionam em um lote inicial.
- A área piloto de agricultura livre aceita uma célula válida e recusa água, obstáculos e corrupção.
- O golem procura uma planta pronta, colhe, carrega e retorna ao ponto de descanso.
- O lago permite iniciar a pesca com a vara e concluir a sincronia.
- O caldeirão respeita a receita, quantidade, tempo, recompensa e cancelamento.

## Progressão e descoberta

- O evento previsível, uma Colheita Dourada e um Fragmento Celestial podem ser observados sem bloquear a sessão.
- A coleção de pesca registra os dois itens e concede o bônus ao ser concluída.
- A primeira área aceita entregas parciais, purifica depois de completa e libera os quatro lotes 2x2.
- A Pedra das Marcas aparece após a purificação e pode ser investigada uma vez.
- O Herbário das Marcas aparece ao lado dos lotes liberados, nunca sobre eles; com 5 Trigo e 1 Água, restaura e concede uma Rama Encantada.

## Persistência

- Salve antes e depois da purificação; recarregue e confirme o estado dos lotes, obstáculo, lore e Herbário.
- Salve após restaurar o Herbário; recarregue e confirme que a recompensa não é entregue novamente.

## Interface e segurança da V0

- `F10` não abre ferramentas de desenvolvimento e o painel de debug exige habilitação explícita no editor.
- Clicar em item comum, inclusive com o botão direito, não abre venda nem bloqueia as ações do jogo.
- Semente e ferramenta são modos exclusivos; selecionar um desmarca o outro.
- A Vara de Pesca permanece selecionada ao usar Espaço fora da janela de sincronia.
- O painel de objetivos inicia no canto superior direito, pode ser minimizado e desaparece após sua conclusão.
- Loja de recursos, loja de aprimoramentos, venda, sono, árvore de habilidades e mural de demandas não são acessíveis na V0.
- O HUD mostra apenas estação/ano, água, golem e ferramenta ativa.

## Portão da Release Candidate

- Executar todos os smoke tests em projeto limpo.
- Exportar a build a partir de um commit isolado, sem incorporar alterações locais paralelas.
- Realizar a rota completa em save novo e repetir os pontos críticos em um save anterior compatível.
- Não introduzir economia, NPCs, armazenamento compartilhado ou outras regras reservadas durante o fechamento.

## Critério de aprovação

A V0 está pronta para fechar quando o loop puder ser realizado sem sobreposição visual, clique ambíguo, duplicação de lote ou perda de estado após carregar.
