# Recipes Schema

## Estado Atual
O sistema de receitas do projeto está em transição híbrida: o catálogo rico vive em `Resource .tres` dentro de `Data/recipes/`, e o gameplay ainda mantém fallback legado em `Scripts/Database.gd` para compatibilidade.

### Como as receitas estão estruturadas hoje
- `Data/recipes/*.tres` usa `RecipeData` como formato principal para exibição e validação rica.
- `Database.receitas_alquimia` continua existindo como catálogo legado/provisório.
- O `RecipeResolver` centraliza a leitura dos dois formatos.
- Exemplos de IDs de Resource:
  - `agua_tomate_sol` -> `Data/recipes/agua_tomate_sol.tres`
  - `golem_coletor` -> `Data/recipes/golem_coletor.tres`

### Como o caldeirão lê receitas hoje
- `Scripts/Cauldron.gd` usa `RecipeResolver` para validar e resolver receitas.
- O resolver consulta primeiro `RecipeDatabase`/`Data/recipes/` e cai no legado apenas se não houver `RecipeData`.
- A produção em lote reconstrói ingredientes com o resolver central.
- O caldeirão valida:
  - se a receita existe;
  - se os ingredientes podem ser reconstruídos;
  - se o inventário tem quantidade suficiente;
  - se o lote cabe na capacidade atual, no caso de `golem_coletor`.

### Como o Livro de Receitas lê receitas hoje
- `Scripts/RecipeBookUI.gd` usa `GlobalInventory.receitas_descobertas`.
- Para exibir os detalhes, o livro consulta o `RecipeResolver`.
- Quando existe `RecipeData`, o livro exibe os campos ricos do resource.
- Quando não existe, cai no formato legado compatível.
- O livro calcula a quantidade máxima fabricável a partir do inventário atual.

## Limitações do Formato Atual
- Parte do conteúdo ainda vive em `Database.receitas_alquimia`.
- `receitas_descobertas` continua salvando IDs crus.
- O fluxo ainda precisa manter compatibilidade com saves antigos.
- O formato legado não carrega metadados ricos como descrição, categoria e tempo.
- Mesmo com a camada nova, o legado ainda existe como fallback temporário.

## Campos Que Faltam Para Escala
Para um sistema escalável, o formato deveria ter pelo menos:
- `id`
- `nome`
- `ingredientes`
- `resultado`
- `quantidade_resultado`
- `tempo_producao`
- `descricao`
- `categoria`
- `estacao_ideal`
- `desbloqueada_por_padrao`
- `recompensa_pontos_alquimia`
- `ordenacao`
- `versao_do_schema`

Campos opcionais úteis mais tarde:
- `icone`
- `cor_da_receita`
- `tags`
- `nivel`
- `custo_moedas`
- `requer_caldeirao`
- `requer_skill`

## Comparação de Formatos

### Resource `.tres`
Vantagens:
- Integra direto com Godot.
- Fácil de editar no Inspector.
- Bom para dados com estrutura rica.
- Suporta tipos fortes e referências nativas.

Desvantagens:
- Muito arquivo individual quando o catálogo cresce.
- Mais difícil de revisar em massa fora do editor.
- Menos amigável para exportação e processos externos.

### JSON
Vantagens:
- Fácil de gerar e ler.
- Bom para dados estruturados e exportáveis.
- Funciona bem com ferramentas externas.
- Fácil de versionar em texto.

Desvantagens:
- Menos seguro em tipos.
- Precisa de validação manual.
- Pode ficar menos confortável no Godot para edição direta.

### CSV
Vantagens:
- Ótimo para tabelas simples.
- Bom para edição em planilha.
- Fácil para balanceamento em lote.

Desvantagens:
- Ruim para listas aninhadas de ingredientes.
- Complica quando a receita tem estrutura rica.
- Exige parsing mais cuidadoso para campos compostos.

## Recomendação Para Este Projeto
Recomendação principal: **Resource `.tres` para receitas, com fallback legado apenas durante a transição**.

Motivos:
- O jogo é fortemente Godot-native.
- As receitas vão precisar de campos ricos, como ingredientes, resultado, tempo e descrição.
- O Editor da Godot facilita criar e revisar conteúdo sem código.
- O caldeirão e o Livro de Receitas ficam mais claros com dados tipados.

Recomendação prática:
- Manter o fallback legado só enquanto existirem saves ou IDs antigos em circulação.
- Migrar conteúdo em lotes pequenos quando fizer sentido.
- Se o time quiser edição em massa depois, exportar ferramentas auxiliares para JSON/CSV sem abandonar o Resource como formato principal.

## Preparação Estrutural Criada
Para adiantar a migração sem romper o fluxo atual, o projeto ganhou:
- `Scripts/data/RecipeData.gd`
- `Scripts/data/RecipeDatabase.gd`
- `Scripts/data/RecipeResolver.gd`
- `Data/recipes/*.tres`

Hoje esses arquivos já estão ligados ao jogo pela camada `RecipeResolver`, mas o legado continua disponível como fallback para saves e conteúdos antigos.

### Campos da primeira versão
O `RecipeData` inicial inclui:
- `id`
- `nome`
- `descricao`
- `categoria`
- `ingredientes`
- `resultado_item`
- `resultado_quantidade`
- `tempo_producao`
- `ordem_importa`
- `desbloqueada_por_padrao`
- `recompensa_pontos_alquimia`
- `tags`
- `versao_do_schema`

### Próxima etapa sugerida
Reduzir a dependência do legado apenas onde houver compatibilidade suficiente, mantendo:
- `RecipeResolver` como caminho principal;
- `RecipeDatabase` como base de leitura dos resources;
- suporte a saves antigos em `receitas_descobertas`;
- fallback temporário para `Database.receitas_alquimia` enquanto existirem IDs antigos em circulação.

## Leitor Estrutural Criado
Foi criada uma camada de leitura central:
- `Scripts/data/RecipeDatabase.gd`

Esse leitor:
- carrega `.tres` de `res://Data/recipes/`;
- valida campos básicos de `RecipeData`;
- compara ids novos com `Database.receitas_alquimia`;
- alimenta o `RecipeResolver`, que atende caldeirão e Livro de Receitas.

### Resultado esperado da comparação
O relatório deve mostrar:
- ids que existem apenas nos Resources;
- ids que existem apenas no sistema legado;
- uma base clara para planejar a migração sem desligar nada ainda.

## Uso Paralelo No Livro de Receitas
O Livro de Receitas usa o `RecipeResolver` para exibir dados ricos quando o `RecipeData` correspondente existe e está completo.

Pontos importantes:
- `RecipeResolver` escolhe o resource primeiro.
- `Database.receitas_alquimia` ainda serve como fallback para compatibilidade.
- Se um `RecipeData` faltar, estiver inválido ou incompleto, o livro cai automaticamente para a leitura antiga.
- Isso permite validar o novo formato sem arriscar o fluxo principal do caldeirão.

## Cobertura Atual
Todas as receitas legadas atuais já possuem um `.tres` correspondente em `Data/recipes/`.

Isso significa que:
- o `RecipeResolver` cobre o catálogo atual completo usando o `RecipeDatabase` como base;
- o Livro de Receitas pode exibir a versão rica quando houver `RecipeData`;
- o jogo ainda preserva `Database.receitas_alquimia` apenas como compatibilidade temporária.

## Resumo da Decisão
- O formato atual funciona para protótipo.
- Ele não escala bem.
- `Resource .tres` é a melhor base para este projeto.
- JSON e CSV podem servir como ferramentas de apoio, mas não como formato principal inicial.

## Snapshot de produção do caldeirão (save v4)

O novo campo opcional `cauldrons` mapeia o caminho relativo do produtor (atualmente `CauldronUI`) ao seu estado. Ele guarda a produção capturada no início, sem recalcular o resultado a partir do catálogo ao carregar:

- `IDLE`: sem produção pendente;
- `BREWING` / `READY`: `result_item`, `result_quantity`, `time_remaining`; pronto tem tempo zero e não é entregue durante o load;
- `BATCH`: `batch.recipe_id`, resultado/quantidade, `seconds_per_craft`, `total`, `completed`, `time_remaining`, `waiting_for_space`, `cancel_pending`, `ingredients` e `reservations`.

Cada reserva guarda `success`, `refunded`, `requirements` e `entries` com `item_id`, `quantity`, `source`. Somente crafts ainda não entregues possuem reserva; a quantidade de recibos deve coincidir com `total - completed`, e suas entradas devem reconstruir exatamente os ingredientes de cada craft. JSON converte números inteiros em floats: a validação aceita valores numericamente inteiros, mas recusa frações, negativos, origens desconhecidas e recibos já devolvidos.

`SaveManager` valida todos os estados antes de alterar o runtime e aplica o produtor somente após restaurar os estoques. O caldeirão para timers/animação anteriores e substitui o estado sem consumo/refund. Não concede descoberta novamente nem avança pelo tempo passado com o jogo fechado. Cancelamento parcial conserva somente as reservas não devolvidas.

Saves completos antigos sem o campo inicializam `IDLE`; não é possível reconstruir produção que o arquivo antigo nunca registrou. Payloads parciais usados por contratos agrícolas não apagam produção. Contagem/limite de golems do caminho abstrato legado são campos opcionais de `economy`, acompanhando o mesmo snapshot de entrega.

Teste dedicado: `Scenes/dev/CauldronPersistenceSmokeTest.tscn`. Ele usa JSON em memória e reconstrói a cena sem tocar no save pessoal. Capacidade da Mochila permanece desligada no gameplay.
