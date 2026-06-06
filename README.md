# Cauldron Crops

## 1. Visão Geral do Projeto
**Cauldron Crops** é um jogo de simulação e automação de fazenda em 2D desenvolvido no motor **Godot 4**. O loop principal do jogo envolve o plantio de sementes, regadura, colheita de insumos, cozimento de poções em um caldeirão alquímico e a compra/gerenciamento de Golems de metal/madeira para automatizar as tarefas agrícolas.

---

## 2. Arquitetura de Grid (Grid Snap)
Para garantir uma organização estilo tabuleiro de xadrez (similar a jogos como *Stardew Valley*), os lotes de plantação possuem um alinhamento matemático rígido ao grid do mundo.
- **Tamanho do Grid**: `64x64` pixels, definido pela constante `GRID_SIZE = 64` no topo de [FarmPlot.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/FarmPlot.gd).
- **Snap Matemático**: Na inicialização do objeto (`_ready()`), a posição global do lote é travada para o múltiplo mais próximo do tamanho do grid:
  ```gdscript
  var snap_x = round(global_position.x / GRID_SIZE) * GRID_SIZE
  var snap_y = round(global_position.y / GRID_SIZE) * GRID_SIZE
  global_position = Vector2(snap_x, snap_y)
  ```
Isso garante que, mesmo que o jogador posicione ou instancie um lote de forma imprecisa, ele será alinhado automaticamente à célula do grid correspondente.

---

## 3. Mecânicas de Plantação ([FarmPlot.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/FarmPlot.gd))

### 3.1. Crescimento Baseado em Tempo
Cada lote funciona com uma máquina de estados simples (`VAZIO`, `CRESCENDO`, `PRONTO_PARA_COLHER`). O ciclo de crescimento é controlado por um nó `Timer` interno (configurado como *one-shot*). O tempo padrão de crescimento é definido na base de dados de sementes (`Database`), sendo acelerado sob certas condições (ex: solo regado reduz o tempo em 20%; estação do Verão concede outros 20% de aceleração).

### 3.2. Hidratação e Sobrevivência
O lote pode ser regado utilizando água do inventário. Se um lote não estiver regado ao final do temporizador de crescimento, há **20% de chance** de a planta morrer de sede (retornando ao estado `VAZIO` com o log `"A planta morreu de sede!"`), a menos que a estação atual seja o Inverno.

### 3.3. Animação de Feedback ("Game Juice")
As plantas reagem ao toque físico de corpos em movimento (como o jogador ou os Golems).
- **Sensor de Colisão**: Um nó `Area2D` chamado `SwayArea` com um `CollisionShape2D` (retangular) detecta a entrada de corpos.
- **Balanço via Tween**: Quando o sinal `body_entered` é disparado, a função `_on_sway_area_body_entered` executa um balanço dinâmico usando `Tween` para inclinar o sprite `10` graus para a direita, `-10` graus para a esquerda e suavemente retornar ao centro (`0` graus):
  ```gdscript
  var tween = create_tween()
  tween.tween_property($SpritePlanta, "rotation_degrees", 10.0, 0.1)
  tween.tween_property($SpritePlanta, "rotation_degrees", -10.0, 0.1)
  tween.tween_property($SpritePlanta, "rotation_degrees", 0.0, 0.15)
  ```

### 3.4. Renderização de Texturas Individuais e Offsets
As imagens das plantas são carregadas de forma dinâmica. Para evitar que os sprites flutuem ou fiquem desalinhados por conta de áreas transparentes variáveis nos arquivos de pixel art, todas as imagens de colheita no diretório `res://Assets/` são recortadas rente às suas bordas ativas (usando bounding boxes).
- **Alinhamento Universal de Altura**: A base/raiz da planta é matematicamente posicionada na coordenada `y = 0` do lote através de um cálculo baseado na altura real da textura:
  ```gdscript
  $SpritePlanta.offset = Vector2(0, -textura.get_height() / 2.0)
  ```
- **Escala de Renderização**: A propriedade de escala do sprite da planta é configurada para `Vector2(0.25, 0.5)` para gerar um crescimento retangular (alto e fino) ou `Vector2(0.18, 0.18)` dependendo do ajuste visual desejado pelo jogador no Godot Editor.
- **Grupos do Nó**:
  - `lotes_terra`: Utilizado por gerenciadores globais para disparar ações automáticas e atualizações de UI.
  - `lote_plantacao`: Utilizado pela IA dos Golems para localizar plantas prontas para coleta.

---

## 4. Sistema de Automação e IA do Golem

A automação do trabalho agrícola é realizada de duas formas que atualmente coexistem (veja a seção *Problemas Conhecidos*).

### 4.1. Cérebro Físico do Golem ([Golem.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/Golem.gd))
Cada Golem físico no cenário possui um script de comportamento baseado em máquina de estados rígida (`IDLE`, `MOVING`, `HARVESTING`, `RETURNING`).
- **Ciclo de Pensamento**: A cada 1.0 segundo, o Golem no estado `IDLE` vasculha os lotes do grupo `"lote_plantacao"`.
- **Comunicação por Variável**: Ele identifica lotes onde a variável `pronto_para_colher` é `true`. Ao selecionar um lote como `alvo_atual`, o Golem muda seu estado para `MOVING` e inicia sua trajetória.
- **Movimentação baseada em Grid**: A viagem é calculada para manter uma velocidade rigorosamente constante de **2 blocos do grid por segundo** (tempo de viagem = `0.5` segundos por bloco de `64` pixels):
  ```gdscript
  var distancia_pixels = global_position.distance_to(destino)
  var distancia_em_blocos = distancia_pixels / GRID_SIZE
  var tempo_viagem = distancia_em_blocos * TEMPO_POR_BLOCO
  ```
- **Coleta**: Ao atingir o lote, o Golem entra no estado `HARVESTING` por 1.0 segundo (tempo de colheita simulado) e reseta o lote (`pronto_para_colher = false`). Em seguida, entra em `RETURNING` para voltar para a sua base de origem e redefinir o ciclo para `IDLE`.

### 4.2. Gerenciador Global de Golems ([GolemManager.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/GolemManager.gd))
Um script Autoload global que atua como um sistema de colheita passiva automática em segundo plano.
- A cada 4.0 segundos, se a contagem global de golems ativa for maior que zero, ele coleta instantaneamente e à distância até `total_golems * 2` plantas maduras no grupo `"lotes_terra"`, simulando a colheita direta chamando a função `_on_plot_clicked()` de cada lote de terra maduro.

---

## 5. Economia e Inventário ([EconomyManager.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/EconomyManager.gd))
Centraliza o controle financeiro e limites de automação da fazenda.
- **Moedas (`moedas`)**: Moeda corrente adicionada através da venda de produtos colhidos e usada para transações.
- **Controle de Golems**:
  - `total_golems`: Define o número de golems ativos que o jogador possui. Inicializado em `1` para contar o golem que já inicia fisicamente inserido no mapa.
  - `max_golems`: Limite máximo de golems que podem ser adquiridos (padrão = `5`).

---

## 6. Ferramentas Auxiliares

### 6.1. Fatiador de Sprite Sheets ([fatiador_plantas.py](file:///e:/Cauldron%20Crops/cauldron-crops/fatiador_plantas.py))
Um script em Python na raiz do projeto que lê as duas planilhas de sprites matriciais das plantas (`crops_1.png` e `crops_2.png` com dimensões `1024x768` pixels contendo 4 colunas e 3 linhas cada) e as divide em 24 imagens individuais de `256x256` pixels. As imagens fatiadas são salvas no formato `[nome_da_planta]_[estagio].png` na pasta de Assets do Godot.

### 6.2. Script de Corte de Bordas ([scratch/process_crop_images.py](file:///C:/Users/lpsan/.gemini/antigravity-ide/brain/dd3d33fc-cb00-4f97-8dcd-71cb720c1f3d/scratch/process_crop_images.py))
Um script complementar desenvolvido em Python que analisa todos os arquivos PNG individuais de plantação gerados na pasta `res://Assets/` (incluindo as novas sprites personalizadas enviadas pelo usuário para o trigo), calcula a `getbbox()` de pixels visíveis e descarta todo o excesso de fundo transparente. Isso permite que a lógica de renderização dinâmica de offsets no Godot alinhe as bases dos sprites perfeitamente ao chão sem ajustes manuais.

---

## 7. Problemas Conhecidos e Próximos Passos

### Conflito: Auto-colheita em 4 segundos vs. Coleta do Golem
- **Descrição do Problema**: Atualmente, a colheita automática realizada pelo [GolemManager.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/GolemManager.gd) e a locomoção física do Golem em [Golem.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/Golem.gd) entram em conflito direto. A cada 4 segundos, o `GolemManager` coleta instantaneamente e de forma invisível as plantas maduras remotas. Quando o Golem físico calcula sua rota e caminha até o lote maduro selecionado, a planta frequentemente já foi colhida e resetada à distância pelo loop do `GolemManager`, tornando a movimentação e animação física do Golem redundantes e ineficientes.
- **Resolução Recomendada**: Para que o comportamento visual de IA do Golem faça sentido, a rotina de colheita remota instantânea do [GolemManager.gd](file:///e:/Cauldron%20Crops/cauldron-crops/Scripts/GolemManager.gd) deve ser desativada ou integrada diretamente à colheita física dos Golems, permitindo que apenas golems físicos realizem as colheitas ou que o `GolemManager` sirva apenas para gerenciar o spawn físico dos robôs.

## 8. Execução e exportação da demo da Fase 1
- Versão usada: Godot 4.6.2.
- Para abrir o projeto, abra a pasta `E:/Cauldron Crops/cauldron-crops` na Godot ou carregue diretamente `project.godot`.
- Para rodar localmente, execute a cena principal definida em `project.godot` (`Scenes/Main.tscn`) com Play/F5 no editor.
- Para exportar a demo Windows, use o preset `Windows Desktop - Fase 1 Demo` e exporte para `Builds/Fase1/CauldronCrops_Fase1.exe`.
- Se o editor solicitar export templates, instale os templates da mesma versão da Godot (4.6.2) antes de exportar.
- A demo exportada da Fase 1 foi gerada com sucesso e validada manualmente; os artefatos locais ficam em `Builds/Fase1/` e não devem ser versionados.
