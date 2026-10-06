# Economia inicial e destino dos excedentes

**Contrato candidato, Fase A, 2026-10-05. Aguardando aprovação integral antes de B–E.** O autor autorizou continuar após a recomendação de aquisição alternativa de materiais. O recorte abaixo concretiza essa recomendação; preços, gate e representação comercial ainda não foram aprovados.

O percurso proposto é **produção → excedente do baú escolhido → Moedas → Carvão ou Raiz Gélida no baú → receitas e projetos existentes**. A coleta continua disponível sem moeda. Isso introduz comércio limitado no protótipo, não apenas uma melhoria de armazenamento; não reativa a loja antiga nem define sua representação narrativa final.

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

## Acesso e representação propostos

Após restaurar a Clareira, abrir fisicamente o Baú da Vila oferece um botão **Troca**. O gate protege a primeira expedição/restauração e não exige Herbário produtivo, semeador ligado ou talento. Saves com a Clareira restaurada tornam-se elegíveis, sem prêmio, crédito inicial ou transação automática.

O painel usa **Moedas** como rótulo provisório da unidade universal, fora dos slots. Não pressupõe Gold, comerciante, mensageiro ou mecanismo mágico. Aceitar este piloto significa autorizar explicitamente uma interface comercial abstrata no baú, posterior à Clareira; caso essa representação não combine com a história, deve ser substituída antes da implementação. Antigravity mantém direção e produção artística.

## Itens e preços de piloto

Valores por unidade, candidatos para teste, não derivados automaticamente dos preços legados nem balanceamento homologado:

| Item | Receber ao vender | Pagar para obter |
| --- | ---: | ---: |
| Trigo `trigo` | 1 | Não disponível |
| Tomate do Sol `tomate_sol` | 2 | Não disponível |
| Carvão `carvao` | 1 | 4 |
| Raiz Gélida `raiz_gelida` | 2 | 6 |
| Peixe Comum `peixe_comum` | 1 | Não disponível |

Somente esses cinco IDs entram na venda. Água, sementes, consumíveis, Mistura, crafts, raros, colecionáveis e Abóbora permanecem fora. A Abóbora ainda carece de acesso sazonal público adequado; não abrir cultivo, Elixir ou estação por consequência. Este piloto cobre cinco recursos comuns, não cumpre ainda a saída universal de todo o catálogo da Decisão 84.

Cada operação aceita de **1 a 99 unidades**, escolhidas manualmente, e exige confirmação. Compra não tem fila, estoque comercial finito, timer, pedido automático ou progresso offline; entrega imediatamente no mesmo Village Storage como transação local abstrata. Não simula produção/coleta/transporte de golem.

## Origem e confirmação

Venda retira exclusivamente do estoque autoritativo do Baú da Vila ativa. Compra debita a carteira e acrescenta exclusivamente ao mesmo baú. Mochila não complementa a venda nem recebe compras; é preciso depositar pessoalmente recursos externos antes de negociá-los. Reservas já retiradas pelo caldeirão, resultados prontos, cargos de colheita/semente/logística e baú cacheado não são estoque negociável.

O fluxo é abrir baú → Troca → escolher Vender ou Obter materiais → item → quantidade → conferir total e saldo resultante → confirmar. Manter ícone/nome, estoque disponível, quantidade e moeda explícitos, em painel opaco. Os painéis lado a lado de Mochila/baú e suas transferências continuam; troca e transferência não podem estar ativas simultaneamente. Fechar a troca retorna ao baú; Esc/cancelamento não gastam. Sem nova HUD fixa, venda por clique simples/direito, vender tudo ou seleção obrigatória de item/ferramenta.

Confirmar exige vila ativa, ausência de transição/load, Clareira restaurada, baú direto válido, personagem no alcance contextual seguro calculado pelo Main a partir do pedido-base de 52 pixels e geração vigente. Esse alcance considera obstáculo, raio do personagem e margem; não impor 52 como limiar final, o que poderia recusar o jogador após a própria aproximação parar em posição válida. Alterar intenção, fechar painel, load ou viagem invalida callbacks. Revalidar saldo e estoque bruto antes do commit; quantidade impossível recusa integralmente, nunca vende o restante ou ajusta o número silenciosamente. Aumento do estoque pode manter a quantidade escolhida. Confirmação duplamente acionada não repete a operação.

Venda de ingredientes é escolha do jogador: mostrar a origem e o total, mas não reservar automaticamente recursos para receitas futuras ou recomprar sozinho. Falha conserva todos os recursos e moeda; só publicar feedback/atualização após o par estoque/carteira estar coerente.

## Utilidade e consequências para o loop

Carvão comprado permite recuperar sementes de Trigo e fabricar Mistura Restauradora; Raiz comprada participa de Crescimento e Infusão Purificadora. Comprar não concede flags de descoberta, receita, XP, restauração, coleta do Bosque ou marco da Mochila. Fontes existentes e seus intervalos permanecem.

Uma Raiz custaria seis trigos ou três tomates vendidos. Isso pode reduzir ou substituir expedições posteriores para adquirir essas unidades; o gate protege a primeira expedição, não sua frequência futura. É uma escolha deliberada entre atividades, não promessa de que a exploração mantém a mesma atratividade. Cultivos de 3–6 segundos continuam, sem alongar timers para justificar preços.

Compra/revenda direta perde moeda: Carvão 4→1, Raiz 6→2. As receitas atuais que consomem esses materiais produzem sementes/consumíveis/crafts excluídos da venda, não uma conversão alquímica direta lucrativa entre os cinco comuns. Agricultura pode gerar valor como pretendido: a colheita base é **uma unidade**, e dois trigos → três sementes → três colheitas de trigo rendem um trigo líquido antes de água/tempo/trabalho. Adubo acrescenta dois tomates à cultura elegível; não tratar toda colheita como base três nem RNG como rendimento garantido. Isto não demonstra balanceamento global ou ausência de toda exploração econômica futura.

## Transações e salvamento

Carteira aceita saldo inteiro não negativo até **9.007.199.254.740.991**, o maior inteiro seguro no percurso JSON adotado para o piloto. Validar tipo, finitude, integralidade e limite antes de converter, multiplicar, somar ou debitar; booleanos, strings e números fracionários não viram moeda por coerção. Quantidade de troca permanece 1–99, independentemente do stack pessoal. Estoque do item operado e seu resultado precisam estar no intervalo seguro; estoque legado maior bloqueia aquela troca sem truncar ou invalidar todo o v4 por essa nova política.

Commit síncrono com proteção de reentrada e save/load durante a operação: validar ambos os lados, aplicar retirada/crédito ou débito/depósito, conferir resultado e só então notificar. Não usar `VillageResourceAccess.consume()`, que completa pela Mochila, nem os métodos permissivos atuais como substitutos de preflight. Uma falha inesperada precisa restaurar o par exato, não adicionar um refund reexecutável.

Preservar save v4 e saldo legado válido exatamente. Completo sem campo monetário inicia em zero; parcial sem o campo preserva o saldo runtime. Campo monetário explícito inválido ou container econômico inválido recusa antes de mutação, retorno à vila ou I/O, sem zerar/reparar silenciosamente. Container explícito de `village_chest_inventory` deve ser um Dictionary, não convertido silenciosamente em baú vazio. Writer valida a carteira e recusa enquanto houver transação; arquivo anterior permanece. Ter saldo positivo antes da Clareira é compatível com legado: o gate restringe comandos, não validade da carteira.

Não persistir intenção, cotação, callbacks, histórico de trocas ou nova flag de desbloqueio. Load aceito fecha/resetará intenção e não executa transações. Carteira e baú continuam substituições independentes em snapshots parciais, sujeitos à validação de seus valores efetivos: isso **não** garante conservação entre snapshots parciais arbitrariamente montados nem é sistema anticheat. Não ampliar incidentalmente as regras de todos os estoques antigos.

## Aprovação necessária

Confirmar conjuntamente **comércio provisório pelo baú após Clareira, rótulo Moedas, cinco preços de venda e duas compras da tabela, estoque exclusivamente Village Storage, operações manuais de 1–99 com confirmação, compras imediatas locais, efeito possível sobre expedições e regras de transação/persistência acima**. Só então executar B–E. Nenhuma loja antiga, compra de sementes, NPC, Dormir pago, requests, F10, calendário, mapa, espécie, segundo ator, mastery ou tempo offline é autorizada por consequência.

## Plano técnico condicionado ao contrato

1. **B, transações e dados:** tabela própria dos cinco IDs/duas compras, consulta/commit Storage-only, guard e rollback exato de estoque/carteira. Domínio limitado, sem framework econômico, registro persistente de transações ou ingestão de preços legados.
2. **C, persistência:** preflight monetário/writer, completo antigo/default zero/parcial, saldo/container explícito inválido e reabertura; intenção invalidada e saldo independente do gate. Recusa preserva runtime/arquivo, sem normalizar estoques alheios.
3. **D, interação:** botão condicionado no baú, painel opaco e confirmação por item/quantidade/total/saldo; exclusão com transferência, ferramentas/picking/atalhos preservados e cancelamento por geração/contexto. Registrar somente implementação visual real em ART_HANDOFF.
4. **E, fechamento:** cada ID/preço, 1/99/0/fracionário/overflow, estoque/saldo insuficiente ou legado excessivo, rollback/reentrada/callbacks obsoletos, distâncias/cena/cache/viagem, snapshot completo/parcial e arquivo anterior. Conferir cargos/reservas/receitas/marcos intactos e compra/revenda sem lucro direto. QA isolado, regressões, pacote limpo e novos roteiros sem apagar os 80 atuais. Automação não homologa ritmo, conforto, arte ou balanceamento.

## Fontes e validação desta consulta

Gameplay e engenharia revisaram o candidato em leitura guiada pelos perfis, sem aprovação de design. Gameplay recomendou excluir Abóbora, reconhecer comércio e substituição possível de coleta; engenharia delimitou estoque bruto, números seguros, reentrada e o limite de conservação dos snapshots parciais. Fontes: Decisão 84, contexto §88, ROADMAP vigente, FARM_SYSTEM_V2, FIRST_EXTERNAL_REGION_VERTICAL_SLICE, `VillageChest.gd`, `VillageChestPanel.gd`, `VillageResourceAccess.gd`, `SellMenu.gd`, `EconomyManager.gd`, `SaveManager.gd`, `Database.gd`, `FarmPlot.gd` e receitas atuais.

Esta fase altera somente documentação. Nenhum jogo, teste ou exportação novo; nenhum save pessoal acessado ou arte concorrente integrada. Não há nota de conteúdo entregue em ART_HANDOFF. Revisão documental confere limites e preservação do checklist, não aprova design.

QA independente deste contrato concluiu sem bloqueadores após corrigir o alcance de confirmação: os 52 pixels são pedido-base, não limiar efetivo; a validação futura reutiliza o cálculo seguro do Main. Os 80 textos/ordem manuais são idênticos ao HEAD e permanecem pendentes. O parecer não aprova design, preços, lore ou runtime. Publicação seleciona somente os quatro documentos próprios; alterações artísticas concorrentes, inclusive o hunk do contexto §71, ficam fora. A revisão inicial `e6a6e5e` permanece histórica.
