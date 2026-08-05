# Cauldron Crops

<p align="center">
  Jogo 2D de fazenda e alquimia em que plantações, receitas e golems formam um ciclo de descoberta e automação.
</p>

<p align="center">
  <img alt="Godot" src="https://img.shields.io/badge/Godot_4-478CBF?style=flat-square&logo=godotengine&logoColor=white">
  <img alt="GDScript" src="https://img.shields.io/badge/GDScript-478CBF?style=flat-square&logo=godotengine&logoColor=white">
  <img alt="Status" src="https://img.shields.io/badge/status-protótipo_jogável-D9A441?style=flat-square">
</p>

## Sobre o jogo

Cauldron Crops é um cozy farming game desenvolvido em Godot 4. O jogador cultiva ingredientes, experimenta combinações no caldeirão, descobre receitas e usa os resultados para evoluir e expandir a fazenda.

O diferencial do projeto é colocar a alquimia no centro da progressão. O caldeirão conecta agricultura, exploração, economia e automação, transformando cada descoberta em uma nova possibilidade de jogo.

## Loop principal

```text
plantar → regar → colher → combinar ingredientes → descobrir receitas → evoluir a fazenda
```

## Funcionalidades implementadas

- plantio, rega, crescimento e colheita;
- inventário global e catálogo de itens;
- caldeirão com receitas e produção em lote;
- livro de receitas descobertas;
- pesca com minigame de sincronia;
- economia e venda de itens;
- missões e árvore de habilidades;
- estações e gerenciamento de água;
- save/load do progresso principal;
- purificação de áreas e expansão da fazenda;
- golem coletor com prioridades de trabalho e talento de irrigação.

## Arquitetura

O projeto separa cenas, regras de gameplay e dados para permitir que os sistemas evoluam de forma independente.

| Área | Responsabilidade |
| --- | --- |
| `Scenes/` | Cenas do jogo, interfaces e elementos interativos |
| `Scripts/` | Regras de gameplay e gerenciadores globais |
| `Scripts/data/` | Modelos e resolução de receitas e do grid agrícola |
| `Data/recipes/` | Receitas declaradas como recursos do Godot |
| `Assets/` | Sprites, fontes e recursos visuais |
| `docs/` | Design, decisões técnicas, sistemas e roadmap |

Entre os componentes centrais estão `SaveManager`, `GlobalInventory`, `RecipeResolver`, `FarmGridManager`, `QuestManager` e a máquina de estados do golem.

## Executar o projeto

### Requisitos

- Godot 4.6.2 ou versão compatível;
- renderizador com suporte ao modo Forward Plus.

### Desenvolvimento

1. Clone o repositório:

   ```bash
   git clone https://github.com/LeandroSatsuki/Cauldron-Crops.git
   ```

2. Importe `project.godot` no Godot.
3. Execute a cena principal com **F6/F5** no editor.

### Demo para Windows

O projeto possui o preset `Windows Desktop - Fase 1 Demo` em `export_presets.cfg`.

Para gerar uma build, instale os templates de exportação compatíveis com sua versão do Godot e exporte para a pasta `Builds/Fase1/`. Os binários são ignorados pelo Git e não fazem parte do repositório.

## Estado do desenvolvimento

O projeto está em fase de protótipo jogável. O loop principal da fazenda já pode ser percorrido, enquanto conteúdo, arte, balanceamento e alguns sistemas de progressão continuam em evolução.

O código também contém uma implementação experimental de grid agrícola mantida isolada do fluxo principal até que a migração seja segura.

## Documentação

- [Game Design Document](./docs/GDD.md)
- [Roadmap](./docs/ROADMAP.md)
- [Sistema agrícola](./docs/FARM_SYSTEM_V2.md)
- [Sistema de pesca](./docs/FISHING_SYSTEM.md)
- [Modelo de receitas](./docs/RECIPES_SCHEMA.md)
- [Sistema de tempo](./docs/TIME_SYSTEM.md)
- [Decisões técnicas](./docs/DECISIONS.md)
- [Changelog](./docs/CHANGELOG.md)

## Próximos passos

- ampliar o catálogo de cultivos e receitas;
- aprofundar missões e progressão;
- evoluir o grid agrícola experimental;
- integrar melhor agricultura, pesca e alquimia;
- substituir placeholders e refinar UI, áudio e balanceamento.

## Autor

Desenvolvido por [Leandro Santos](https://github.com/LeandroSatsuki).
