# Sistema de Tempo

## Visão Geral

O sistema final de tempo do Cauldron Crops será baseado em tempo real, mas durante o protótipo ele deve permanecer em modo debug e controlável.

A ideia é que o jogo acompanhe o horário local do jogador, sem forçar essa regra no desenvolvimento enquanto o loop principal ainda está em validação.

## Regra Final Pretendida

* 1 dia real equivale a 1 dia do jogo.
* A virada do dia acontece às 00:00, usando o horário local do jogador.
* 7 dias reais formam uma estação.
* 4 estações formam um ciclo completo.
* Ordem das estações:
  * Primavera
  * Verão
  * Outono
  * Inverno

## Modo Debug

Durante o desenvolvimento, o tempo real deve ficar desligado por padrão.

O futuro `TimeManager` deve expor algo como:

```text
real_time_enabled = false
```

E permitir ferramentas de teste como:

* avançar 1 dia;
* avançar 1 semana;
* forçar próxima estação;
* resetar para Primavera Ano 1.

Esses comandos devem ser acessados por Debug Panel ou por ferramenta temporária de teste.

## Motivo da Decisão

Tempo real combina com o clima cozy e com a sensação de retorno diário do jogador. Esse tipo de sistema também ajuda a criar rotina e expectativa para estações, colheitas e eventos.

Ao mesmo tempo, ativar isso cedo demais atrapalharia os testes. O desenvolvedor ficaria preso a esperar dias reais para validar crops, estações, receitas, eventos e demais sistemas dependentes do tempo.

## Riscos de Tempo Real

* O jogador pode ficar dias sem entrar e perder progresso percebido.
* Crops podem morrer de forma frustrante.
* Golems podem coletar offline sem controle claro.
* O save pode precisar processar vários dias acumulados.
* As estações podem mudar enquanto o jogador não está jogando.
* Fica mais difícil testar sistemas dependentes de tempo.

## Regra de Tempo Real Suave

A recomendação para o futuro é evitar punição agressiva.

Exemplos de proteção futura:

* limitar penalidade offline;
* permitir que golems protejam parte da fazenda;
* criar poções de conservação;
* criar estufa;
* criar talentos de alquimia para reduzir perdas offline;
* não destruir tudo automaticamente se o jogador ficou ausente.

## Sistemas Afetados

* Plantações.
* Poço e água.
* Estações.
* Golems.
* Baú da Vila.
* Quests.
* Receitas sazonais.
* Eventos.
* Salvamento.
* Economia.

## Futuro TimeManager

Estrutura futura prevista, sem implementação nesta etapa:

* `TimeManager.gd` como Autoload.
* Guardar data real do último login.
* Guardar dia atual do jogo.
* Guardar estação atual.
* Guardar ano.
* Calcular quantos dias reais passaram.
* Processar viradas pendentes.
* Expor modo debug.
* Salvar e carregar estado pelo `SaveManager`.

## Plano de Implementação Futuro

### Fase 1

* Documentação do sistema de tempo.

### Fase 2

* Criar `TimeManager.gd` sem conectar gameplay.

### Fase 3

* Integrar com `SeasonManager`.

### Fase 4

* Adicionar comandos de debug.

### Fase 5

* Integrar plantações.

### Fase 6

* Integrar poço, golems e quests.

### Fase 7

* Ativar o modo real apenas quando o protótipo estiver estável.

## Decisão Atual

* Tempo real está aprovado como direção final.
* O desenvolvimento fica em modo debug/controlável.
* Nenhuma implementação agora.
