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
- piloto de agricultura livre com política de solo válido;
- Mochila e Village Storage separados, com transferência seletiva em painéis opacos;
- catálogo de itens e pilhas visuais, com base de 12 slots e stacks padrão de 99;
- caldeirão com receitas, produção em lote e persistência de produção/reservas;
- livro de receitas descobertas;
- pesca com minigame de sincronia;
- coleção de pesca, eventos e descobertas opcionais;
- personagem físico com navegação por clique e exploração do bosque;
- estações e gerenciamento de água;
- save/load v4 do progresso principal, com compatibilidade legada;
- purificação de áreas e expansão da fazenda;
- golem coletor com prioridades de trabalho e talento de irrigação.

Loja, venda, requests legados e F10 permanecem desativados na experiência atual. A capacidade da Mochila ainda não recusa itens no gameplay normal; a ativação é um próximo incremento, não uma funcionalidade já liberada.

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

`FarmPlot` continua sendo a autoridade do cultivo, alinhado a células de `80 × 80` pixels. `FarmGridManager` é índice/bridge/snapshot, não uma segunda autoridade de gameplay. A renderização de `SpriteTerra` cobre a célula sem bordas de grama; as plantas ficam ancoradas pela base. O golem físico preserva a logística visível colher → carregar → depositar; o `GolemManager` legado permanece desligado.

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

O fechamento da V0 foi aprovado, e o projeto está na evolução pós-V0 de exploração, armazenamento e Mochila. Conteúdo, arte, balanceamento e sistemas de progressão continuam em evolução.

Checkpoint de 2026-10-01: 31 smoke tests passaram. A persistência do caldeirão foi implementada e ainda aguarda validação manual do autor; a capacidade da Mochila permanece desligada. Cada fechamento de etapa inclui commit e push, conforme [AGENTS.md](./AGENTS.md).

### Verificação técnica

Com `godot` disponível no terminal, um teste pode ser executado sem janela:

```bash
godot --headless --path . res://Scenes/dev/CauldronPersistenceSmokeTest.tscn
```

As cenas de smoke test ficam em `Scenes/dev/`; testes automáticos não substituem a validação visual/manual.

## Documentação

- [Contexto mestre e continuidade](./docs/CAULDRON_CROPS_CONTEXT_MASTER.md)
- [Plano da Mochila](./docs/PERSONAL_INVENTORY_ARCHITECTURE_PLAN.md)
- [Contrato de recursos da vila](./docs/VILLAGE_RESOURCE_ACCESS_CONTRACT.md)
- [Game Design Document](./docs/GDD.md)
- [Roadmap](./docs/ROADMAP.md)
- [Sistema agrícola](./docs/FARM_SYSTEM_V2.md)
- [Sistema de pesca](./docs/FISHING_SYSTEM.md)
- [Modelo de receitas](./docs/RECIPES_SCHEMA.md)
- [Sistema de tempo](./docs/TIME_SYSTEM.md)
- [Decisões técnicas](./docs/DECISIONS.md)
- [Changelog](./docs/CHANGELOG.md)

## Próximos passos

- validar manualmente save/load e cancelamento da produção do caldeirão;
- após aprovação, ativar de forma controlada o piloto de capacidade 12 × 99;
- balanceamento, expansão e conteúdo adicional permanecem para incrementos próprios, sem antecipar economia ou NPCs.

## Autor

Desenvolvido por [Leandro Santos](https://github.com/LeandroSatsuki).
