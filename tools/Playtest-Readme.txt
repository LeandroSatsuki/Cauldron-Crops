Cauldron Crops - Playtest pos-V0

Abra StartPlaytest.cmd para usar o renderizador de compatibilidade.
Mantenha o EXE e o PCK juntos. Nao e necessario instalar Godot.

Esta build usa um save separado em:
%APPDATA%\CauldronCropsPlaytest\savegame.json
Nao copia/carrega o save habitual da versao de desenvolvimento.
O playtest comeca sem progresso anterior. Nao apague seu save habitual.
Builds de playtest posteriores usam este mesmo ambiente separado; se ja
existir progresso de playtest, ele permanece disponivel. Nao apague-o.
Nao copie saves antigos para este ambiente sem planejar uma copia segura.

F5 salva; F9 carrega. F10 permanece desativado.
CHECKLIST.md contem os casos pendentes e os aceites anteriores.
Inclui 75 casos: 70 anteriores preservados e 5 do Herbario produtivo (HP).
Herbario produtivo: ponto a leste do projeto, apos Herbario e Clareira restaurados.
Melhoria opcional, investimento unico8 trigos+2 tomates+1 Mistura Restauradora.
Bau da Vila primeiro, Mochila complementar; abrir/cancelar nao gasta.
Primeira coleta pronta no ponto, nao presente automatico. Cada coleta entrega
1 Raiz Gelida na Mochila e renova em90s de sessao, inclusive no Bosque.
Maximo uma pronta, sem acumulo/offline. Sem espaco, preserva a disponibilidade.
Save/carregar/reabrir conservam restante, sem cobrar ou entregar novamente.
Nao e cultura ou trabalho de golem; fonte do Bosque continua independente45s.
Tomate do Sol pode ser plantado na Primavera ou no Verao, sem mudar estacao.
No Livro: 1 trigo + 1 agua -> 1 Semente de Tomate, 2 segundos/zero XP,
receita conhecida desde o inicio e repetivel, mesmo sem tomate anterior.
Resultado na Mochila; plantar exige semente pessoal e rega normal.
O golem pode semear Trigo OU Tomate por escolha no painel. Nao ha calendario publico novo,
efeito novo de Elixir ou beneficio de Solo Vivo para tomate.
Adubo Flamejante: misture 1 tomate + 1 trigo -> 1 adubo/2 segundos;
a primeira descoberta ensina a receita e concede o ponto de alquimia vigente.
Consulte o adubo na Mochila -> Aplicar -> clique num tomate crescendo/maduro.
O personagem se aproxima; custa 1 adubo pessoal somente na chegada valida.
Uma aplicacao por planta acrescenta +2 tomates a sua colheita (base 3),
sem multiplicar sementes/drops, acelerar ou regar. Planta morta perde o adubo.
Cancelar ou trocar de cultura durante a caminhada nao gasta. Falta de espaco
conserva o resultado calculado; save/load e golem nao repetem o bonus.
No Bosque, fonte de Raiz Gelida perto da bifurcacao inicial (960,630).
Entrega 1 na Mochila e renova em 45 segundos de jogo aberto, inclusive
durante tempo na vila. Sem espaco, preserva o recurso e nao inicia espera.
Sem requisito de restauracao/purificacao ou progresso offline.
Trigo + raiz gera Crescimento; peixe comum + raiz gera Infusao Purificadora.
Receitas existentes, dois segundos, descoberta pela mistura normal.
Coleta nao concede receita, XP, marco ou slots. Visual provisorio; arte
com Antigravity. Carvao continua 2 unidades/45s e independente da Raiz.
Clareira restaurada libera a semeadura no painel, sem ativar.
Escolha Trigo (Primavera) OU Tomate (Primavera/Verao), sem ligar a habilidade
automaticamente ou mudar sua ferramenta/semente pessoal. Usa quatro lotes
iniciais arados e sementes no Bau da Vila. Nao ara nem usa a Mochila.
Se faltar a semente escolhida, nao usa outra como fallback. Sementes precisam
ser fabricadas e depositadas pelo jogador; nao e um ciclo autossuficiente.
Troca bloqueada durante ida ao bau/tarefa/carga de sementes, inclusive pausa
e devolucao. Desligar permite devolver fisicamente a unidade original;
retome prioridade mista se pausado. Escolha e carga conservadas no save.
Nos roteiros antigos de semeadura, usar Trigo como comportamento padrao;
SS-01 a SS-05 verificam a nova escolha explicita e o plantio de tomate.
No Livro: 1 carvao + 1 agua gera 1 Semente de Trigo; 2 trigos geram 3.
Carvao vem do Bosque e agua da reserva regenerada pelo poco, fora dos slots.
As receitas estao disponiveis por padrao, levam 2 segundos por craft
e nao concedem pontos de alquimia. Eventos de colheita antigos permanecem.
Resultado vai para a Mochila: plante manualmente ou deposite para o golem.
Salvar producao em andamento e condicional: se terminou antes, nao executado.
Poco fisico fica acima dos canteiros, proximo ao nucleo da vila.
Clique para aproximar e abrir, mesmo com ferramenta selecionada.
Projeto opcional: Clareira restaurada, 8 trigos + 1 mistura restauradora.
Consome bau primeiro e complementa pela Mochila; capacidade 10 para 20.
Nao enche agua instantaneamente nem acelera regeneracao. Sem tempo offline.
Talento antigo de 1 ponto continua alternativa sem acumular/pagar duas vezes.
O painel mostra a reserva; nao retira agua manualmente para a Mochila.
Clareira restaurada ensina Solo Vivo: 1 trigo + 1 Mistura -> 1 preparo,
2 segundos/zero XP. Consulte na Mochila, clique Aplicar e escolha o lote
marcado vazio/arado. O personagem se aproxima; so aplica/gasta ao chegar.
Tratamento permanente: primeira rega normal; depois de colher trigo regado,
o lote conserva umidade para replantar trigo. Outros cultivos sao permitidos,
mas nao recebem essa umidade; reaplicacao/outro lote recusam sem gasto.
Pocao de Crescimento: consulte o frasco ou Aplicar crescimento no Caderno.
Escolha Aplicar e uma planta crescendo. Primeiro alvo valido abre um frasco,
usa uma das tres doses e deixa duas; doses antigas sao usadas primeiro.
Clique normal nao gasta doses. Cancelar/botao direito/Escape preservam doses.
Ferramenta, semente, outro controle da UI, modal/viagem/load cancelam o modo.
Depois de aplicar, o modo termina; para aplicar outra dose, escolha novamente.
Mistura e purificacao continuam ingredientes/projetos, nao uso livre no mapa.
No bau, clicar num item continua abrindo transferencia por quantidade.
Cartao/faixa/contorno sao visuais provisorios, nao arte final aprovada.
Pocao Aceleradora: use Golem -> Preparar proxima entrega, sem aproximar.
Um frasco da Mochila e usado so ao iniciar uma nova entrega de colheita.
Deslocamento +50% ate o bau, sem acelerar outras tarefas ou repetir sozinho.
Preparar nao gasta/reserva; cancelar antes do uso e gratuito. Fechar/Escape
nao cancelam preparo. Depois de usado, conserva ate deposito unico,
incluindo pausa/retomada/viagem/save. Entrega normal ja iniciada nao muda.
Titulo/Fechar fixos; role o conteudo para acessar todos os controles.
Registre ID, aprovado/falhou/nao executado, resolucao e observado.
Nao force estados indisponiveis nem provoque falhas de gravacao.
Aprovacao tecnica de startup nao significa aprovacao manual do gameplay.

build-manifest.json identifica commit, hashes e verificacoes executadas.
Logs contem evidencias tecnicas; nao sao arquivos de progresso.
