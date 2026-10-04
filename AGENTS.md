# Continuidade de Cauldron Crops

- Responder em português do Brasil e trabalhar em incrementos pequenos, preservando mudanças existentes.
- Consultar `docs/CAULDRON_CROPS_CONTEXT_MASTER.md`, o plano vigente e o código relacionado antes de implementar. Decisões humanas recentes prevalecem sobre documentação histórica.

## Especialistas e referências (autorizado em 2026-10-04)

- Usar `docs/AGENT_TEAM.md` como roteamento de leitura e responsabilidade. Perfis reutilizáveis: `cc_gameplay`, `cc_art`, `cc_narrative`, `cc_engineering` e `cc_qa` em `.codex/agents/`.
- Delegar consultas independentes aos papéis pertinentes: novas decisões de gameplay/arte/narrativa passam pelo especialista respectivo; mudanças técnicas relevantes recebem engenharia e entregas materiais recebem QA independente. Não acionar os cinco para cada edição mecânica ou repetir parecer inalterado.
- Cada tarefa declara modo leitura/escrita e resultado esperado; arquivos de implementação têm um responsável. Principal integra/publica, especialistas não fazem Git nem delegação recursiva. Respeitar concorrência da sessão, sem alterar configuração global.
- Visuais procedurais, SVGs/blockouts e tema de protótipo não são arte final aprovada. `cc_art` confronta com referências humanas/documentais; lacunas de paleta/escala não autorizam inventar estilo. Aceite funcional não é aceite artístico.
- Documentação versionada é memória oficial. Ler estado operacional vigente e fontes do assunto, não toda a história em cada pedido; planos/hipóteses históricos não reativam sistemas reservados.
- Se o mecanismo de delegação não selecionar perfil nativo, fornecer o arquivo e exigir leitura explícita; distinguir essa execução guiada de carregamento nativo confirmado.

## Fechamento de etapas e GitHub

O autor autorizou commit e push ao finalizar cada etapa em 2026-10-01. Esta regra substitui orientações históricas de não fazer commit.

1. Executar a validação proporcional à mudança e atualizar decisões/contexto quando necessário.
2. Distinguir implementação testada automaticamente de validação manual: se esta ainda estiver pendente, registrar e publicar como checkpoint, sem afirmar que a etapa foi aprovada pelo autor.
3. Conferir `git status`, diff e remoto/branch; selecionar somente arquivos do incremento e suas dependências. Não usar `git add .` indiscriminadamente.
4. Criar commit descritivo e enviar ao remoto configurado, verificando o resultado do push e a sincronização da branch.
5. Informar o commit enviado e testes/pendências no relatório final. Não pedir autorização repetida apenas para esse fechamento já autorizado.

- Não enviar segredos, saves pessoais, builds, `.godot/` ou arquivos locais de ferramentas de agentes.
- Não fazer push forçado nem descartar/regravar histórico do autor. Se o remoto avançar, preservar suas mudanças na integração; pedir direção quando houver conflito semântico que não possa ser resolvido com segurança.
- Alterações fora do incremento permanecem intactas e fora do commit; arquivos de arte só entram quando forem parte da entrega ou dependências necessárias.
