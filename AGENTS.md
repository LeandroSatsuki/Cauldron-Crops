# Continuidade de Cauldron Crops

- Responder em português do Brasil e trabalhar em incrementos pequenos, preservando mudanças existentes.
- Consultar `docs/CAULDRON_CROPS_CONTEXT_MASTER.md`, o plano vigente e o código relacionado antes de implementar. Decisões humanas recentes prevalecem sobre documentação histórica.

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
