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

Não implementar receitas agora.

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

- `escama_brilhante`
- `peixe_comum`
- `gota_lunar` futura
- `lodo_de_lago` futuro

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
- A primeira implementação futura deve ser Obstáculo Mágico V0.
- `FarmPlot` continua ativo.
- `FarmGrid` continua isolado.
- Pesca e Catálogo de Itens já preparam esse caminho.
