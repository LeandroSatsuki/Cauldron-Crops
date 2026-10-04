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
Inclui 24 casos anteriores e 6 do Ciclo Sustentavel (SC-01 a SC-06).
Clareira restaurada libera Semear trigo no painel do golem, sem ativar.
O piloto usa trigo, Primavera, quatro lotes iniciais arados e sementes
depositadas no Bau da Vila. Nao ara sozinho nem usa a Mochila.
No Livro: 1 carvao + 1 agua gera 1 Semente de Trigo; 2 trigos geram 3.
Carvao vem do Bosque e agua da reserva regenerada pelo poco, fora dos slots.
As receitas estao disponiveis por padrao, levam 2 segundos por craft
e nao concedem pontos de alquimia. Eventos de colheita antigos permanecem.
Resultado vai para a Mochila: plante manualmente ou deposite para o golem.
Salvar producao em andamento e condicional: se terminou antes, nao executado.
Registre ID, aprovado/falhou/nao executado, resolucao e observado.
Nao force estados indisponiveis nem provoque falhas de gravacao.
Aprovacao tecnica de startup nao significa aprovacao manual do gameplay.

build-manifest.json identifica commit, hashes e verificacoes executadas.
Logs contem evidencias tecnicas; nao sao arquivos de progresso.
