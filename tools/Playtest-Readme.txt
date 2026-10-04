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
Inclui 50 casos: 45 anteriores preservados e 5 de Aceleradora (AC).
Clareira restaurada libera Semear trigo no painel do golem, sem ativar.
O piloto usa trigo, Primavera, quatro lotes iniciais arados e sementes
depositadas no Bau da Vila. Nao ara sozinho nem usa a Mochila.
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
