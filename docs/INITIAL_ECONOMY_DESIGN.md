# Economia inicial e destino dos excedentes

**Fase A de design, 2026-10-05. Somente proposta; implementação não autorizada.** Após o fechamento técnico do abastecimento físico de sementes, o autor respondeu “aprovado”. Esta consulta identifica o próximo objetivo de gameplay, sem interpretar a resposta como aprovação de preços, comércio, NPCs ou benefícios ainda não apresentados.

A recomendação é fechar o percurso **produção → excedente escolhido → moeda universal → uma possibilidade útil ao jogador**. A saída de baixo atrito já é direção aprovada pela Decisão 84; sua representação, seus valores e o primeiro uso público da moeda ainda precisam de decisão. Venda sem esse uso apenas troca recursos parados por moeda parada.

## Estado confirmado

O baseline executável continua sendo `8b73dc6`, pacote `Builds/Playtest/SeedDelivery-20261005`, com fechamento documental `aeb4333`. As 71/71 regressões, 17 reaberturas e 10 fixtures são evidência da entrega anterior, não execução desta consulta. Os 80 casos manuais permanecem pendentes e intactos; aprovação para continuar não os homologa.

Cultivo de Trigo/Tomate, semeadura seletiva, colheita física, produção finita de sementes e depósito já se conectam. O Village Storage não possui limite implementado: a lacuna é dar propósito recorrente à produção após os objetivos atuais, não resolver um baú cheio.

`SellMenu.gd` usa valores provisórios e remove itens exclusivamente da Mochila. A entrada normal do inventário em `UI.gd` não ativa essa venda. `EconomyManager` conserva o contador legado; `SaveManager.gd` carrega moeda por coerção inteira, sem o domínio estrito necessário para um novo contrato econômico. A existência desses scripts não autoriza reativá-los.

## Comparação dos próximos recortes

| Recorte | Valor para o jogador | Dependência ainda aberta |
| --- | --- | --- |
| Destino dos excedentes | Motivo recorrente para produzir e escolher entre usos | Representação da troca e primeiro uso útil da moeda, além de elegibilidade e taxas |
| Segunda restauração | Novo objetivo de reconstrução e descoberta | Possibilidade realmente nova, localização, gate, custo e recompensa; marcadores futuros não são projetos funcionais |
| Abóbora | Terceiro cultivo e diversificação agrícola | Acesso adequado ao Outono e uso regular aprovado; Elixir permanece sem efeito funcional autorizado |

Outra fonte renovável ou mais lotes tenderiam a ampliar quantidade, sem garantir uma nova escolha. A Abóbora possui semente determinística por Tomate + Raiz, mas fabricar a semente não resolve sua estação nem o destino da colheita. Nenhuma alternativa está autorizada por esta comparação.

## Fronteira econômica recomendada

Estes limites são candidatos, não um contrato completo para B–E:

- Uma ação manual na vila, com item, quantidade e total explicitamente confirmados. O baú físico existente pode ser ponto de acesso técnico, mas isso não o transforma automaticamente em loja ou mecanismo narrativo de comércio.
- Consumo direto do Village Storage quando aprovado, preservando a separação da Mochila. Definir a origem pessoal ou complementar no contrato; não fundir estoques, retirar automaticamente tudo ou vender cargas/reservas que já pertencem a outra tarefa.
- Lista inicial pequena de comuns regularmente acessíveis. Não converter `valor_base`, `pode_vender` ou `Database.precos` em balanceamento aprovado. Declarar o que o piloto cobre e o que falta para a direção universal; uma lista parcial não atende todo o catálogo.
- Um primeiro uso funcional da moeda antes de publicar o sistema. Aquisição alternativa de materiais comuns ou melhoria com nova função são caminhos para discussão, não conteúdo escolhido. Compra de sementes, lojas iniciais e NPCs não voltam por consequência.
- Escolha de produzir, reservar ou trocar; sem venda automática, metas aleatórias ou obrigação de praticar todas as atividades. Progresso obrigatório mantém caminho determinístico apropriado.
- Sem trabalho remoto no Bosque, simulação offline, rede de baús, segundo golem, mastery, lore ou arte final. Antigravity mantém direção e produção artística.

## Decisão humana necessária

A próxima decisão deve aprovar conjuntamente **como a troca se apresenta** e **o que a moeda permite fazer pela primeira vez**. O nome/lore monetário continua aberto; usar “Moedas” provisoriamente exige confirmação, não assumir Gold.

Aquisição alternativa de materiais favorece quem quer progredir com suas atividades preferidas, mas precisa preservar o valor da exploração e não ressuscitar a loja inicial retirada. Uma melhoria pode criar um objetivo claro, mas seu benefício precisa ser escolhido antes: não inventar mais slots, capacidade do baú ou bônus numérico para justificar a venda.

Depois dessa decisão, formular itens, taxas, custo do benefício, desbloqueio e interação completa. **B–E não começam apenas com aprovação da direção geral:** o autor precisa confirmar o contrato delimitado. Se nenhum primeiro uso econômico combinar com o projeto, retornar à segunda restauração e escolher a nova possibilidade que ela abre.

## Plano técnico condicionado ao contrato

1. **B, transações e dados:** domínio pequeno de troca e primeiro uso, elegibilidade explícita, confirmação e consumo/crédito atômicos. Recibo por origem, saldo inteiro não negativo, limites numéricos e proteção de reentrada. Revisar ciclos de fabricação/recompra; não criar framework antecipado.
2. **C, persistência:** preflight de estado efetivo e writer antes de mutação/I/O, compatibilidade completa/parcial, replay e reabertura sem duplicação. Preservar saldo legado válido sem premiar ou zerar silenciosamente; definir tratamento de valores incompatíveis no contrato.
3. **D, interação:** acesso contextual com aproximação, painel opaco, quantidade, total e confirmação/cancelamento. Revalidar origem, saldo, contexto e geração; não vender pela simples seleção do item. Registrar somente implementação visual real em ART_HANDOFF.
4. **E, fechamento:** recusas/rollback, capacidades, concorrência com caldeirão/golem, saldo/preços/limites, save/load/viagem e ciclos econômicos. QA isolado, regressões, pacote limpo e novos roteiros sem apagar os 80 atuais. Automação não homologa ritmo, conforto, arte ou balanceamento.

## Fontes e validação desta consulta

Gameplay e engenharia fizeram consultas independentes somente leitura, guiadas pela leitura explícita dos perfis; não houve carregamento nativo confirmado. Fontes: Decisão 84, contexto §88, ROADMAP vigente, FARM_SYSTEM_V2, FIRST_EXTERNAL_REGION_VERTICAL_SLICE, TIME_SYSTEM, `VillageChest.gd`, `SellMenu.gd`, `EconomyManager.gd`, `SaveManager.gd`, `RestorationProject.gd`, `Main.gd`, `Database.gd`, `FarmPlot.gd` e receitas de Semente de Outono/Elixir.

Esta fase altera somente documentação. Nenhum jogo, teste ou exportação novo; nenhum save pessoal acessado ou arte concorrente integrada. Não há nota de conteúdo entregue em ART_HANDOFF. Revisão documental confere limites e preservação do checklist, não aprova design.

QA independente em leitura guiada não encontrou bloqueador material: claims confrontados com código e Decisão 84, diff próprio sem erros de whitespace, 80 entradas manuais idênticas ao HEAD em texto/ordem e nenhuma concluída. Parecer não aprova design ou recertifica a build. Publicação seleciona os quatro documentos próprios, excluindo o hunk artístico do contexto §71 e demais alterações externas.
