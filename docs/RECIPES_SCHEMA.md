# Recipes Schema

## Estado Atual
O sistema de receitas do projeto ainda é baseado em `Dictionary` dentro de `Scripts/Database.gd`.

### Como as receitas estão estruturadas hoje
- `Database.receitas_alquimia` é um `Dictionary`.
- A chave é uma string no formato `ingrediente1_ingrediente2`.
- O valor é a `String` do resultado.
- Exemplo:
  - `agua_trigo -> pocao_crescimento`
  - `palha_rara_rama_encantada -> golem_coletor`

### Como o caldeirão lê receitas hoje
- `Scripts/Cauldron.gd` consulta `Database.receitas_alquimia` diretamente.
- O caldeirão monta a chave combinando os dois ingredientes em ordem direta e invertida.
- A produção em lote usa `Database.obter_ingredientes_receita(recipe_id)` para reconstruir a lista de ingredientes a partir da chave.
- O caldeirão valida:
  - se a receita existe;
  - se os ingredientes podem ser reconstruídos;
  - se o inventário tem quantidade suficiente;
  - se o lote cabe na capacidade atual, no caso de `golem_coletor`.

### Como o Livro de Receitas lê receitas hoje
- `Scripts/RecipeBookUI.gd` usa `GlobalInventory.receitas_descobertas`.
- Para exibir os detalhes, o livro verifica se a receita existe em `Database.receitas_alquimia`.
- Em seguida, chama `Database.obter_ingredientes_receita(recipe_id)` para reconstruir os ingredientes.
- O livro calcula a quantidade máxima fabricável a partir do inventário atual.

## Limitações do Formato Atual
- As receitas não têm estrutura rica.
- A lista de ingredientes não fica salva de forma explícita.
- Não há nome de exibição separado da chave.
- Não há categoria, raridade, custo de fabricação, tempo, descrição, estação ou tags.
- Não há versão de esquema.
- Não há metadados para ordenar, filtrar ou localizar receitas com facilidade.
- O formato fica difícil de manter quando a quantidade de receitas cresce.

## Campos Que Faltam Para o Futuro
Para um sistema escalável, o formato futuro deveria ter pelo menos:
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
Recomendação principal: **Resource `.tres` para receitas, depois que o loop mínimo estiver estável.**

Motivos:
- O jogo é fortemente Godot-native.
- As receitas vão precisar de campos ricos, como ingredientes, resultado, tempo e descrição.
- O Editor da Godot facilita criar e revisar conteúdo sem código.
- O caldeirão e o Livro de Receitas vão ganhar mais clareza com dados tipados.

Recomendação prática:
- Manter o formato atual apenas enquanto o protótipo está sendo estabilizado.
- Quando for migrar, começar por um tipo de `Resource` para receita.
- Se o time quiser edição em massa depois, exportar ferramentas auxiliares para JSON/CSV sem abandonar o Resource como formato principal.

## Preparacao Estrutural Criada
Para adiantar a migracao sem tocar no fluxo atual, o projeto ganhou:
- `Scripts/data/RecipeData.gd`
- `Data/recipes/pocao_crescimento_basica.tres`
- `Data/recipes/golem_coletor.tres`

Esses arquivos existem apenas como base estrutural. O caldeirao continua lendo `Database.receitas_alquimia`, e o novo `Resource` ainda nao esta ligado ao jogo nesta etapa.

### Campos da primeira versao
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

### Proxima etapa sugerida
Criar um `RecipeDatabase.gd` separado para:
- carregar `Resource .tres`;
- comparar o novo formato com o esquema antigo de `Database.gd`;
- validar compatibilidade antes de trocar a fonte real do caldeirao.

## Leitor Estrutural Criado
Foi criada uma camada de leitura apenas para preparacao:
- `Scripts/data/RecipeDatabase.gd`

Esse leitor:
- carrega `.tres` de `res://Data/recipes/`;
- valida campos basicos de `RecipeData`;
- compara ids novos com `Database.receitas_alquimia`;
- nao substitui o sistema antigo e nao se conecta ao caldeirao ainda.

### Resultado esperado da comparacao
O relatorio deve mostrar:
- ids que existem apenas nos Resources;
- ids que existem apenas no sistema legado;
- uma base clara para planejar a migracao futura sem desligar nada ainda.

## Uso Paralelo No Livro de Receitas
O Livro de Receitas agora usa o `RecipeDatabase` apenas para exibir dados ricos quando o `RecipeData` correspondente existe e esta completo.

Pontos importantes:
- `Database.receitas_alquimia` continua sendo a fonte funcional do gameplay e da producao em lote.
- `RecipeDatabase` entra apenas como camada de leitura e apresentacao.
- Se um `RecipeData` faltar, estiver invalido ou incompleto, o livro cai automaticamente para a leitura antiga.
- Isso permite validar o novo formato sem arriscar o fluxo principal do caldeirao.

## Cobertura Atual
Todas as receitas legadas atuais já possuem um `.tres` correspondente em `Data/recipes/`.

Isso significa que:
- o `RecipeDatabase` consegue cobrir o catálogo atual completo;
- o Livro de Receitas pode exibir a versão rica quando houver `RecipeData`;
- o jogo ainda continua usando `Database.receitas_alquimia` como fonte funcional da produção.

## Resumo da Decisão
- O formato atual funciona para protótipo.
- Ele não escala bem.
- `Resource .tres` é a melhor base para o futuro deste projeto.
- JSON e CSV podem servir como ferramentas de apoio, mas não como formato principal inicial.
