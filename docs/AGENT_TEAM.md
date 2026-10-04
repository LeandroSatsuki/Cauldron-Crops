# Equipe de especialistas — Cauldron Crops

## Divisão atual com Antigravity

Decisão humana de 2026-10-04, posterior à configuração dos cinco perfis: **Antigravity externo assume direção e produção de arte; Codex concentra código, integração funcional, testes e documentação.** O autor continua diretor criativo. Não há conexão automática ou memória compartilhada entre aplicativos comprovada: a passagem permanente é `docs/ART_HANDOFF.md`, a ser consultada pelo Antigravity.

Codex acrescenta uma nota ao final do documento em cada implementação com impacto visual: conteúdo realmente adicionado, IDs/caminhos, estados, representação provisória e limites técnicos. Usa assets existentes ou geometria mínima, sem criar conceito, paleta, textura ou animação final. Layout técnico pode garantir controles acessíveis e input correto; estética e acabamento ficam com Antigravity. Mudanças físicas, de renderização global ou de hierarquia funcional exigem coordenação antes de integração.

O perfil `cc_art` permanece no repositório como referência histórica, não como diretor artístico ativo nem consulta automática de Codex. As instruções abaixo sobre cinco perfis devem ser lidas com essa substituição de responsabilidade. Antigravity não é subagente iniciado por esta sessão.

## Autorização e alcance

Em 2026-10-04, o autor autorizou estruturar cinco especialistas com base na documentação existente. Esta etapa organiza papéis, referências e revisão; não implementa gameplay, narrativa, arte final ou sistemas reservados. O Poço já está fechado tecnicamente; seus 36 testes manuais continuam pendentes.

O autor é o diretor criativo e decide mudanças de direção. O agente principal coordena recortes, consultas, integração, documentação e publicação. Especialistas emitem pareceres; não substituem decisão humana nem ampliam a autorização da tarefa.

## Cinco perfis reutilizáveis

Perfis nativos em `.codex/agents/`, no formato documentado pelo Codex. Não são cinco chats com memória infalível ou cinco agentes permanentemente executando. Modelo/raciocínio são herdados da sessão, sem alteração de configurações globais ou aumento de concorrência. A referência de configuração é a [documentação oficial de subagentes](https://learn.chatgpt.com/docs/agent-configuration/subagents).

| Perfil | Quando consultar | Limite de atuação |
| --- | --- | --- |
| `cc_gameplay` | Nova decisão sobre mecânica, progressão, custo, recompensa, automação ou economia | Revisão somente leitura; não inventar conteúdo/balanceamento aprovado |
| `cc_art` | Referência histórica da equipe anterior; não acionado automaticamente | Direção e produção agora com Antigravity externo, pela passagem em `ART_HANDOFF.md` |
| `cc_narrative` | Lore, nome definitivo, NPC, diálogo, missão ou significado de descoberta | Revisão/proposta textual, sem canonizar hipótese ou implementar conteúdo |
| `cc_engineering` | Arquitetura, integração, persistência, navegação, implementação atribuída | Análise por padrão; escrita só em pedido de implementação autorizado e arquivos atribuídos |
| `cc_qa` | Revisão independente e fechamento de uma entrega | Revisor somente leitura; execução de testes que gravam fica com coordenador/engenharia em QA isolado |

O principal aciona somente os papéis pertinentes, não todos em toda correção mecânica. Novas decisões de gameplay passam por gameplay; arte é encaminhada ao Antigravity em `ART_HANDOFF.md`; mudanças narrativas passam por narrativa. Mudanças técnicas relevantes recebem engenharia e entregas materiais recebem QA independente. Se um papel já tem parecer para o mesmo recorte/versão, reaproveitar o parecer verificando o que mudou, em vez de duplicar revisão.

## Memória e precedência

1. Decisão humana explícita mais recente, dentro da autorização da tarefa.
2. Estado operacional vigente no início/último checkpoint do contexto mestre e no topo do ROADMAP.
3. Plano do recorte e decisões/contratos relacionados, considerando data/status.
4. Código e evidência de execução para confirmar o estado implementado, nunca para aprovar design por existência.
5. Histórico e hipóteses como contexto, não autorização nova.

Conflito entre fontes exige investigação/relato, não escolher silenciosamente uma delas. Documentos versionados são a memória oficial; o histórico do chat não substitui isso. Não copiar todo o contexto mestre para cada perfil. Cada consulta lê a base comum e apenas seções relacionadas ao pedido. Parecer que resultar em decisão aprovada é consolidado pelo principal nos documentos existentes, não em cinco diários concorrentes.

Base comum: `AGENTS.md`, esta página, abertura do `CAULDRON_CROPS_CONTEXT_MASTER.md` e “Etapa atual” de `ROADMAP.md`. A última seção operacional do contexto e a decisão relacionada só são necessárias quando a tarefa toca esse checkpoint. Resumo de integração deve informar fonte/versão, estado, limites, arquivos/evidências e pendências.

## Roteamento de documentos existentes

Todos os caminhos abaixo são relativos a `docs/`; consultar a parte do sistema que está sendo tratado, não ler a tabela inteira a cada solicitação.

| Papel | Fontes por assunto |
| --- | --- |
| Gameplay | Contexto §§2–8, 10–13, 21–22 e 41 para pilares/direções; `FARM_SYSTEM_V2.md` para recortes agrícolas/Poço; `PERSONAL_INVENTORY_ARCHITECTURE_PLAN.md` para Mochila; `FIRST_EXTERNAL_REGION_VERTICAL_SLICE.md` para exploração; decisões do sistema para economia/aquisição |
| Arte/UX | `GDD.md`, somente Referências/Estilo Visual Desejado/Placeholders; contexto §43; Decisões 96–97 e decisão visual pertinente; `ITEM_TEXTURE_BACKLOG.md` confrontado com catálogo/assets; `FARM_LAYOUT_PLAN.md` para limites técnicos e ROADMAP para aceites/pendências visuais |
| Narrativa | Contexto §§2–4, 6–7, 9, 12–19 e 39; `WORLD_STRUCTURE_DIRECTION.md`, separando Decidido de Direção de protótipo; plano da expedição/decisão de conteúdo relacionado |
| Engenharia | Plano do recorte ativo; `VILLAGE_RESOURCE_ACCESS_CONTRACT.md` para fontes/transação; plano da Mochila, `RECIPES_SCHEMA.md`, `FARM_GRID_CHECKPOINT.md`/`FARM_LAYOUT_PLAN.md` quando pertinentes; scripts/cenas/testes do sistema para confirmar implementação |
| QA/entrega | ROADMAP — Checklist integrado e riscos; fechamento técnico do recorte no contexto/Farm System; testes/logs/manifesto apontados na tarefa; `V0_RELEASE_NOTES.md`/`V0_RELEASE_CHECKLIST.md` apenas como baseline histórico da V0 |

### Fontes históricas que exigem cuidado

- GDD é visão geral antiga: lista venda/economia como atuais e save como reservado. Não governa ativação desses sistemas; save v4 existe, lojas/venda/F10 permanecem desativados.
- `WORLD_STRUCTURE_DIRECTION.md` contém descrições antigas de coleta externa runtime-only. Confirmar persistência/restauração no plano vigente e código; cache, snapshot e tempo de ausência na sessão não significam tempo offline.
- Guardiã, origem dos espíritos/golems, identidade narrativa do familiar e região celestial contêm hipóteses. Nome funcional/representação física implementada não os converte em cânone.
- Backlog de textura é levantamento técnico, não aprovação de pacote, licença ou direção final. O manifesto `asset-research/P02-golem-irrigador-assets/manifest.md` nele citado não está neste checkout; não considerar essa referência conferida.

## Direção artística versus protótipo

Confirmação humana de 2026-10-04: os moldes atuais não representam o acabamento desejado; a direção artística do jogo deve ser respeitada, não derivada desses moldes. A documentação já permite placeholders temporários (`GDD.md`, Placeholders), reserva arte final ao polimento (ROADMAP, Fase 5) e não presume aceite artístico pelos testes (contexto §43, Decisões 96–97).

A direção textual localizada é **pixel art 2D, top-down, cozy, legível, fazenda compacta/organizada e UI simples/charmosa**. Tiny Terraces é inspiração visual, sem copiar assets/personagens/UI. CastleVille/Gloom é referência conceitual de corrupção/expansão, não especificação de estilo. Decisão humana/referência explicitamente aprovada mais recente prevalece.

Formas procedurais do Poço, SVGs/moldes e blockouts de cenários, tema provisório e ícones de apoio são **visuais de protótipo**, mesmo quando melhoram legibilidade ou têm aprovação funcional. Isso não classifica todo asset existente como descartável; preservar trabalho do autor e verificar caso a caso. Uma troca futura de visual deve manter collider, picking, posição lógica e estados, salvo mudança funcional separadamente aprovada.

Nas fontes consultadas não há uma folha final aprovada de paleta com valores, escala/proporções, outline, sombreamento ou animação. Não escolher esses parâmetros agora ou declarar que o conceito humano não existe: registrar a lacuna documental e solicitar/localizar a referência quando uma produção visual realmente depender dela. O backlog também precisa ser atualizado contra o catálogo antes de iniciar produção; água é reserva fora dos slots, não razão para criar item carregável.

## Delegação, integração e proteção

- Definir pedido, recorte autorizado, papel, fontes, resultado esperado e modo leitura/escrita antes de iniciar. Para implementação, atribuir arquivos e dependências; dois escritores não recebem o mesmo arquivo sem coordenação explícita.
- Respeitar a concorrência fornecida pela sessão. Cinco perfis podem ser usados em rodadas; não pressupor cinco execuções simultâneas nem alterar limite/configuração global. Não delegar recursivamente ou publicar a partir dos especialistas.
- Quando a interface de delegação não expõe seleção do perfil nativo, o principal fornece o arquivo do perfil e pede sua leitura explícita; registra que foi delegação guiada por perfil, não carregamento nativo confirmado. Não alegar que salvar TOML já provou sua descoberta automática no app.
- Engenharia/coordenador executam QA que grava somente em caminhos isolados autorizados. Não ler/copiar/alterar save pessoal, acelerar timers no jogo real, reativar F10, apagar arte alheia ou tratar testes automáticos como aprovação manual.
- Pareceres trazem evidência e distinguem **decidido / implementado / testado automaticamente / aprovado manualmente / provisório / proposto / pendente**. Registrar conflitos/questões para o autor; um especialista não cria aprovação humana.
- O principal revê resultados, integra, valida proporcionalmente e fecha commit/push com arquivos explícitos. Perfis de projeto/documentação são parte desta entrega autorizada; credenciais, configuração pessoal, chats/logs privados, builds e saves nunca entram no Git.

## Uso e verificação

Exemplo de pedido: “Consulte `cc_gameplay` sobre o recorte aprovado e `cc_engineering` sobre persistência; mantenha leitura até apresentar os riscos. Depois consulte `cc_qa` sobre a implementação delimitada.” Necessidades visuais são registradas em `ART_HANDOFF.md` para Antigravity; narrativa só entra se houver conteúdo narrativo.

O validador `tools/Test-AgentProfiles.py` confere TOML, identidade dos cinco papéis, campos suportados usados, referências locais e políticas declaradas de leitura. Isso não prova julgamento correto, aplicação efetiva do sandbox no app ou descoberta/carregamento nativos. Pareceres de teste guiados pelos perfis são evidência separada; somente uma execução que exponha o papel nativo pode confirmar a integração nativa em uma sessão futura.

Checkpoint de 2026-10-04: cinco perfis/referências passaram e seis entradas inválidas foram recusadas pelo validador. Revisão independente do protocolo artístico e cinco cenários guiados (progressão/economia, referência visual, lore, diagnóstico de persistência e aceite manual) não encontraram falha crítica. Regras foram refinadas para reconhecer novas decisões humanas inequívocas sem ampliar escopo e tratar contagens de QA como baseline datado, não números fixos eternos. Auditoria atualizada passou no PCK VillageWell-20261004 existente; exportação futura exclui `.codex`/AGENTS. Sem nova build, execução da suíte completa, gameplay ou arte final; as 36 pendências manuais permanecem. Não houve seleção nativa comprovada: delegações desta etapa leram explicitamente os perfis.
