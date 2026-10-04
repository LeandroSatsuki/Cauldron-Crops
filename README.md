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

Checkpoint visual atual: camadas de solo estáveis, caldeirão limpo, grama suavizada, HUD opaco, trilhas/vegetação não interativas, golem de pedra, lago com margem e entrada distinta da corrupção. Dois pacotes de polimento; direção artística final e aceite manual ainda pendentes. Escopo e próximos passos em `docs/ROADMAP.md` e Decisões 96–97.

Checkpoint técnico seguinte: origem agrícola fixa no mundo, independente de resolução/câmera; grade abaixo do núcleo e pedra fora do pocket. Save v4/v3 preserva culturas e progresso, mas saves antigos passam ao layout canônico porque não registravam a posição física da origem. Contrato e teste manual em [Mapa da Fazenda](./docs/FARM_LAYOUT_PLAN.md) e Decisão 98.

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
- catálogo de itens e Mochila com 12 slots iniciais, expansível até 20 por marcos, com stacks padrão de 99;
- caldeirão com receitas, produção em lote e persistência de produção/reservas;
- livro de receitas descobertas;
- reposição determinística de sementes de trigo pelo Livro: carvão + água → 1 semente, ou 2 trigos → 3 sementes, sem desbloqueio/RNG;
- pesca com minigame de sincronia;
- coleção de pesca, eventos e descobertas opcionais;
- personagem físico com navegação por clique e exploração do bosque;
- estações e gerenciamento de água;
- save/load v4 do progresso principal, com compatibilidade legada;
- purificação de áreas e expansão da fazenda;
- golem coletor com prioridades de trabalho e talento de irrigação;
- piloto de semeadura opcional de trigo em quatro lotes, liberado pela Clareira restaurada, com retirada/transporte/plantio/devolução físicos e cargo persistido.

Loja, venda, requests legados e F10 permanecem desativados. A Mochila ganha +4 slots ao restaurar o Herbário e +4 na primeira coleta do Bosque, uma vez por marco, em qualquer ordem. A barra usa páginas de até 12 e o painel do baú mostra o progresso. Recusas preservam a origem/recompensa, e saves acima da capacidade atual carregam todas as quantidades sem truncamento. Marcos, capturas pendentes e produção do caldeirão integram o save v4. Validação manual integrada ainda pendente.

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

Playtest pós-V0: `tools/Export-CleanBuild.ps1 -Playtest -SmokeTest -RunRegressionSuite` exporta somente o commit atual em checkout isolado. Saída local em `Builds/Playtest/`, fora do Git; inclui EXE/PCK, `StartPlaytest.cmd` (compatibilidade OpenGL), manifesto/hashes, logs e cópia do checklist de `docs/ROADMAP.md`. A transformação exclusiva da build usa `%APPDATA%/CauldronCropsPlaytest`, sem ler/copiar o save habitual. É um ambiente separado que começa sem progresso; não substitui os aceites anteriores nem presume aprovação manual. O preset histórico abaixo permanece disponível.

O projeto possui o preset `Windows Desktop - Fase 1 Demo` em `export_presets.cfg`.

Para gerar uma build, instale os templates de exportação compatíveis com sua versão do Godot e exporte para a pasta `Builds/Fase1/`. Os binários são ignorados pelo Git e não fazem parte do repositório.

## Estado do desenvolvimento

Checkpoint mais recente (2026-10-04): **Ciclo Sustentável da Fazenda, incrementos 1–3 concluídos tecnicamente**. Recuperação/replantio e orientação distinguem Mochila para plantio manual e baú para golem. Pacote definitivo `Builds/Playtest/SustainableFarm-20261004`, fonte `8a1bc4a`: suíte limpa **52/52**, quatro reaberturas em novos processos (6 + 3 + 8 + 8), fixture adicional de replantio (2), startups headless/OpenGL e auditoria isolada do PCK aprovados. Inclui StartPlaytest.cmd, manifesto/hashes, logs e checklist **30 casos manuais pendentes** (24 intactos + 6 SC). Save separado CauldronCropsPlaytest, sem copiar/apagar progresso pessoal ou playtest anterior; save pessoal intacto. Auditoria não busca recursos no workspace e manifesto identifica a fonte capturada. SustainableFarm-20261003 é preliminar/substituído; GolemSower-20261003 é histórico, sem estas receitas. Técnica não equivale a aceite manual/arte/ritmo/balanceamento. Próximo: propor recorte delimitado de gameplay/progressão antes de ampliar sistemas reservados. Plano em [Sistema agrícola](./docs/FARM_SYSTEM_V2.md).

Checkpoint anterior (2026-10-03): Golem Semeador A–F concluído tecnicamente. Fonte `226bb72` exportada em cópia limpa, suíte **50/50**, mais duas reaberturas em processos separados (6 + 3 verificações), auditoria do PCK/dependências/save separado e startup do EXE headless/OpenGL sem erros. Pacote em `Builds/Playtest/GolemSower-20261003`, com StartPlaytest.cmd, manifesto/hashes, logs e checklist **24 casos** (16 anteriores + 8 semeador). Binários locais fora do Git; pacote anterior e save pessoal preservados. Ambiente `%APPDATA%/CauldronCropsPlaytest` não copia progresso pessoal, mas pode conter progresso de playtest anterior. Semear trigo fica OFF por padrão/legado e só usa sementes do baú, lotes vazios/arados e Primavera. Manual/arte/ritmo continuam pendentes; próximo recorte deve ser proposto antes de ampliar conteúdo.

### Histórico de checkpoints

Playtest anterior (2026-10-03): fonte `c43abae`, 46/46 smoke tests, auditoria e startup headless/OpenGL. Pacote local `Builds/Playtest/PostV0-20261003` preservado; seu checklist de 16 casos foi ampliado, sem transformar pendências em aprovações.

Checkpoint seguinte (2026-10-03): save prepara arquivo temporário verificado e mantém cópia anterior `.bak` antes de substituir o principal. Falhas são informadas, sem carregar backup automaticamente; formato v3/v4 e gameplay preservados. Testes de arquivo usam somente sandbox de QA. Save/load manual normal e demais casos do checklist continuam adiados; não provocar falhas no save pessoal.

Estado operacional consolidado (2026-10-03): suíte mais recente 43/43 no checkpoint `3d2240f`; esta atualização é documental, sem nova execução. Expansão/transferências/persistência da Mochila, produção/cancelamento comuns, colheita recusada persistida, layout agrícola e percurso/restauração/persistência após conclusão da Clareira tiveram aceites manuais específicos. Ajustes recentes de interface e casos-limite continuam pendentes. Consulte o [checklist integrado e riscos técnicos](./docs/ROADMAP.md#checklist-integrado--validação-manual-adiada); os checkpoints abaixo são históricos, não uma lista de testes todos ainda pendentes. Próxima recomendação técnica: proteger a gravação do save, sem mudar o formato ou gameplay; ainda não implementada.

Checkpoint atual de interface (2026-10-03): HUD/Mochila paginadas conforme largura; caldeirão opaco e compacto com ingredientes acessíveis, Livro redimensionável ao viewport e detalhes roláveis. Autor adiou os testes manuais; continuidade usa verificações automáticas e mantém checklist pendente em `docs/ROADMAP.md`. Não considerar esse checkpoint aprovação estética ou mudança de gameplay/save.

O fechamento da V0 foi aprovado, e o projeto está na evolução pós-V0 de exploração, armazenamento e Mochila. Conteúdo, arte, balanceamento e sistemas de progressão continuam em evolução.

Checkpoint de 2026-10-03: **segunda expedição / clareira recuperável** implementada após autorização para novo conteúdo. Descobrir o canteiro no Bosque ensina preparação; fabricar duas misturas na vila e levá-las na Mochila permite restaurar e aprender uma receita de Poção de Crescimento. Fonte renovável de carvão garante aquisição sem RNG. F5 no Bosque preserva a Fazenda em cache; F9 retorna à vila. Saves anteriores v3/v4 continuam compatíveis. Roteiro/contratos em [plano do Bosque](./docs/FIRST_EXTERNAL_REGION_VERTICAL_SLICE.md). Aceite manual, duração e balanceamento permanecem pendentes; 20–30 minutos ainda não são duração validada.

Checkpoint de 2026-10-01: Fase E implementada, 33/33 smoke tests passaram com expansão 12 → 16 → 20, compatibilidade com excesso legado e persistência de marcos/produções/capturas. Interface ampliada conferida por renderização OpenGL. Conforto da expansão, piloto e persistência do caldeirão ainda aguardam validação manual do autor. Cada fechamento de etapa inclui commit e push, conforme [AGENTS.md](./AGENTS.md).

Fechamento integrado posterior: 34/34 testes passaram. Colheita recusada agora preserva itens e bônus sorteados no save, para retomada manual ou pelo golem. A viagem real também valida expansão/HUD no retorno, depósito seletivo e save/load sem duplicação. Testes manuais permanecem pendentes.

Estabilização de coordenadas em 2026-10-02: 35/35 testes passaram, com quatro resoluções, resize/câmera, carga v4/v3 e retorno do Bosque. Layout renderizado conferido em OpenGL/D3D12; save pessoal intacto. Aceite manual do novo layout permanece pendente.

### Verificação técnica

Com `godot` disponível no terminal, um teste pode ser executado sem janela:

```bash
godot --headless --path . res://Scenes/dev/BackpackExpansionSmokeTest.tscn
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

- playtest do recorte da clareira: descoberta, Livro/preparo, carga pessoal, restauração, recompensa agrícola e save/load no Bosque;
- avaliar ritmo e clareza; o percurso funcional não equivale a duração/balanceamento final;
- validar separadamente os casos ainda pendentes de captura, entrega/refund bloqueados por capacidade e saves legados reais;
- revisar arte/UX com captura atual do autor. Os aceites funcionais anteriores estão registrados no contexto §45, sem presumir aprovação artística;
- não ampliar economia, NPCs ou outros conteúdos automaticamente.

## Autor

Desenvolvido por [Leandro Santos](https://github.com/LeandroSatsuki).
