# Farm Expansion System — Purificação da Fazenda

## Visão geral

A fazenda final será grande, fixa e artesanal, dividida em áreas bloqueadas ou corrompidas.

A expansão não deve ser infinita, procedural ou livre neste momento. A ideia é ter áreas planejadas, com identidade própria e desbloqueios progressivos que façam a fazenda parecer viva, antiga e em restauração.

## Decisão de tamanho da fazenda

- Fazenda final: média/grande.
- Mapa fixo e artesanal.
- Dividida em aproximadamente 5 ou 6 áreas principais.
- O jogador começa com uma área inicial pequena e funcional.
- Áreas bloqueadas são purificadas com alquimia.
- Não haverá crescimento infinito do mapa no escopo atual.
- Não haverá geração procedural de áreas no escopo atual.

## Estrutura sugerida de áreas

### 1. Área Inicial

Disponível desde o começo.

Contém os primeiros `FarmPlot`, o caldeirão, o Baú da Vila e o loop básico de cultivo.

### 2. Área do Lago

Contém pesca e pontos de ressonância aquática.

Já começou a existir com o Lago da Fazenda V0.

### 3. Área das Raízes Escuras

Bloqueada por corrupção vegetal.

Pode liberar novos lotes, raízes raras e plantas sombrias.

### 4. Área das Criaturas Mágicas

Espaço futuro para fazendinhas e animais mágicos.

Pode liberar criaturas, produção passiva e ingredientes.

### 5. Área das Ruínas Alquímicas

Pode liberar receitas, melhorias do caldeirão e segredos.

### 6. Área do Coração Corrompido

Região final ligada ao mal maior e ao objetivo central de purificar a fazenda.

Esses nomes são provisórios.

## Objetivo central

O objetivo maior do jogo é restaurar a fazenda e purificar a corrupção mágica que tomou o lugar.

A expansão não é só aumento de espaço. Ela representa avanço narrativo, mecânico e visual.

## Como o desbloqueio funciona

Conceito planejado:

1. A área está bloqueada por obstáculo, névoa, raiz, cristal ou corrupção.
2. O jogador produz um item de purificação no caldeirão.
3. O jogador interage com o bloqueio.
4. O item é consumido.
5. A área é purificada.
6. Novos lotes, recursos ou sistemas ficam disponíveis.

## Relação com o caldeirão

O caldeirão deve ser o centro da progressão de purificação.

Exemplos futuros:

- Poção Purificadora Fraca
- Essência de Clareira
- Solvente de Raízes
- Tônico Lunar
- Elixir de Purificação Profunda

Receita V0 já ligada ao fluxo atual:

- `agua` + `peixe_comum` -> `pocao_purificadora_fraca`

Essa rota conecta pesca ao catalisador de purificação sem encerrar o sistema completo de áreas.

## Relação com o Catálogo de Itens

O Catálogo de Itens V0 prepara esse sistema porque os desbloqueios poderão consultar:

- `valor_base`
- `categoria`
- `raridade`
- `tags`
- `pode_usar_em_receita`
- `origem`
- `descricao`

Exemplo futuro:

Uma área bloqueada pode exigir item com tag `purificacao`, `aquatico`, `magico` ou `sazonal`.

## Relação com plantas

Áreas purificadas podem liberar:

- novas sementes;
- crops raros;
- plantas sazonais;
- ingredientes sombrios;
- plantas lunares;
- plantas aquáticas.

Não adicionar plantas novas agora.

## Relação com pesca

A pesca pode alimentar a purificação com ingredientes aquáticos.

Exemplos:

- `escama_brilhante` futuro
- `lodo_de_lago` futuro
- `peixe_comum` como ponte direta para a Poção Purificadora Fraca V0

A Área do Lago pode ter upgrades e pontos de movimento melhores conforme a fazenda é purificada.

## Relação com criaturas mágicas

Fazendinhas e animais mágicos devem entrar como área futura desbloqueável.

Exemplos:

- criatura de lã mágica;
- criatura produtora de leite alquímico;
- criatura que gera ovos ou cristais;
- criatura ligada à purificação.

Não implementar criaturas agora.

## Versão mínima recomendada

A V0 futura deve ser pequena:

- um único obstáculo mágico estático bloqueia uma pequena área com alguns `FarmPlot` potenciais;
- obstáculo visual;
- interação simples;
- checagem de item no inventário;
- consumo de um item de purificação;
- remoção do obstáculo;
- liberação visual da área;
- save do estado desbloqueado.

## Obstáculo Mágico V0

A primeira implementação prática já pode existir como um único obstáculo estático no mapa principal.

Nesta V0:

- o obstáculo usa uma lista provisória de requisitos de purificação;
- a lista V0 inclui `pocao_purificadora_fraca`, `escama_brilhante` e `trigo`;
- a poção purificadora fraca continua sendo apenas um requisito, não o custo inteiro;
- o obstáculo responde ao clique e só purifica quando todos os requisitos estão presentes;
- ao purificar, todos os requisitos são consumidos;
- a purificação é salva em `farm_expansion.purification_obstacles`;
- o obstáculo some/desativa ao ser purificado;
- o primeiro pocket bloqueado já ganha uma Área Bloqueada V0 visível;
- o pocket usa 4 `FarmPlot` potenciais em arranjo 2x2;
- os lotes ficam ocultos/bloqueados antes da purificação e são revelados depois;
- a expansão é append-only para proteger saves antigos e a ordem dos lotes.

Por enquanto, não existe receita real no caldeirão para gerar esses requisitos. A Poção Purificadora Fraca, a Escama Brilhante e o Trigo ainda entram como catalisadores/progressão provisória para validar o loop entre pesca, agricultura e desbloqueio de área.

## Área Bloqueada V0

A Área Bloqueada V0 é a primeira leitura visual de expansão da fazenda.

Ela serve para mostrar que existe um pocket corrompido atrás do obstáculo e que esse espaço será liberado mais tarde.

Regras desta versão:

- a área corrompida é visível antes da purificação;
- o obstáculo fica em frente ou ao lado desse pocket;
- o pocket é pequeno e usa `FarmPlot` já conhecidos pelo jogo;
- a área some quando a purificação é concluída;
- o pocket revelado passa a funcionar como parte normal da fazenda;
- o save preserva o estado desbloqueado sem reordenar os lotes antigos.

## O que evitar agora

- Não criar sistema completo de neblina.
- Não criar várias áreas desbloqueáveis agora.
- Não criar custos complexos.
- Não criar economia pesada.
- Não criar mapa procedural.
- Não substituir `FarmPlot` por `FarmGrid`.
- Não conectar tudo ao tempo real agora.
- Não bloquear o jogador com grind excessivo.

## Decisão atual

- O sistema foi aprovado como pilar central.
- A documentação fica pronta agora.
- A implementação completa fica para depois.
- A primeira implementação prática já virou Obstáculo Mágico V0.
- `FarmPlot` continua ativo.
- `FarmGrid` continua isolado.
- Pesca e Catálogo de Itens já preparam esse caminho.
