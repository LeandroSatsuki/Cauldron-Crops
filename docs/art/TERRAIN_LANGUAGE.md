# CAULDRON CROPS — TERRAIN LANGUAGE

**Versão:** 0.1 — especificação conceitual  
**Data:** 2026-10-05  
**Status:** DIREÇÃO / NÃO CONGELADO  
**Autoridade:** sujeito à aprovação do autor

---

## 0. Propósito

Este documento define como o terreno de Cauldron Crops deve funcionar visualmente como um sistema.

A grama não deve ser tratada como uma única textura final. Ela é a base sobre a qual clima, estação, território, agricultura, eventos, magia, corrupção e purificação poderão se expressar.

O objetivo é permitir variedade sem fazer cada região parecer pertencer a um jogo diferente.

## 1. Princípio central

> **O terreno deve parecer vivo, composto e específico do lugar, mas nunca parecer um conjunto aleatório de detalhes.**

A identidade deve vir de regras compartilhadas.

Variações de clima, estação e território devem modificar essas regras, não substituí-las.

## 2. O que deve permanecer consistente

Entre diferentes regiões e estados do mundo, devem permanecer reconhecíveis:

- densidade de pixel;
- escala visual;
- linguagem de silhuetas;
- tratamento de luz e sombra;
- lógica de contraste;
- filosofia de repetição;
- relação entre terreno e vegetação;
- leitura do solo cultivável;
- tratamento de transições;
- integração com os demais assets.

Uma região pode ter outra paleta e outra vegetação sem parecer um jogo diferente.

## 3. Camadas do terreno

O sistema visual deve ser pensado em camadas:

1. Terreno base
2. Variações de superfície
3. Transições
4. Solo cultivável
5. Vegetação espontânea
6. Elementos locais
7. Estado ambiental
8. Clima/evento
9. Iluminação/efeitos

Nem todas as camadas precisam existir em toda célula ou região.

## 4. Terreno base

A textura base deve ser relativamente estável e pouco chamativa.

Ela precisa:

- preencher grandes áreas sem repetição óbvia;
- sustentar objetos e personagens;
- permitir leitura de plantações;
- possuir textura suficiente para não parecer vazia;
- não competir com landmarks.

Evitar:

- padrões grandes facilmente reconhecíveis;
- ruído uniforme em toda a superfície;
- excesso de contraste;
- aparência 8-bit não intencional;
- textura tão detalhada que domine a tela.

## 5. Variações da superfície

A variação deve ocorrer em clusters, não em distribuição perfeitamente uniforme.

Exemplos:

- pequenos grupos de grama;
- diferenças sutis de tonalidade;
- pequenas pedras;
- folhas;
- flores;
- manchas de vegetação;
- pequenas áreas de solo exposto.

A variação deve parecer composta.

Não usar ruído aleatório como substituto de composição artística.

## 6. Repetição

A repetição da textura base é inevitável em grandes áreas.

O objetivo não é eliminá-la matematicamente.

O objetivo é tornar a repetição visualmente imperceptível.

Isso pode ser conseguido combinando:

- tiles alternativos;
- microvariações;
- vegetação;
- composição por clusters;
- áreas de respiro;
- mudanças de densidade;
- elementos de cenário.

Não aumentar detalhes simplesmente para esconder repetição.

## 7. Densidade visual

O terreno precisa possuir diferentes níveis de densidade.

### Baixa densidade
Áreas de descanso visual e leitura de gameplay.

### Média densidade
Estado normal de grande parte do ambiente.

### Alta densidade
Bordas, pontos de interesse, áreas mágicas, regiões especiais ou eventos.

A densidade deve ser uma ferramenta de composição.

## 8. Vegetação espontânea

Vegetação pequena deve funcionar como parte do terreno, não como decoração colocada aleatoriamente.

Elementos possíveis:

- tufos de grama;
- flores;
- folhas;
- pequenas plantas;
- cogumelos;
- pequenos arbustos;
- brotos;
- elementos mágicos raros.

A distribuição deve considerar:

- proximidade de landmarks;
- caminhos;
- áreas cultiváveis;
- regiões de interesse;
- visibilidade do jogador.

## 9. Áreas de respiro

Nem todo espaço precisa possuir detalhe.

Grandes áreas relativamente simples são necessárias para:

- leitura de personagens;
- leitura de plantações;
- navegação;
- contraste com áreas especiais;
- composição.

> **Detalhe só é valioso quando existe espaço visual para percebê-lo.**

## 10. Caminhos

Caminhos devem parecer consequência do uso do espaço.

Evitar linhas perfeitamente geométricas quando a ficção não justificar.

A linguagem pode utilizar:

- desgaste;
- pequenas diferenças de cor;
- bordas orgânicas;
- pequenas marcas;
- vegetação reduzida;
- pedras ou folhas ocasionais.

O caminho não deve parecer uma faixa desenhada sobre a grama.

## 11. Solo cultivável

O solo preparado precisa ser imediatamente distinguível do terreno natural.

A diferença pode vir de:

- cor;
- textura;
- borda;
- repetição;
- pequenas marcas;
- estado de umidade.

Não usar contraste excessivo a ponto de fazer a plantação parecer colocada sobre um painel separado.

A relação deve ser:

**terreno → solo preparado → planta**

e não:

**grama → quadrado marrom → sprite de planta.**

## 12. Clima

Clima deve alterar a leitura do ambiente sem necessariamente substituir o terreno inteiro.

### Chuva

Pode afetar:

- brilho;
- temperatura;
- saturação;
- umidade;
- pequenas poças;
- vegetação;
- reflexos;
- partículas.

### Tempo seco

Pode afetar:

- saturação;
- aparência do solo;
- densidade de vegetação;
- pequenas áreas de ressecamento.

### Neve

Se existir no design final, deve ser tratada como uma condição ambiental própria, com regras para:

- cobertura;
- acúmulo;
- bordas;
- vegetação;
- caminhos;
- solo cultivável.

Clima deve ser capaz de transformar a sensação da cena sem destruir a identidade visual base.

## 13. Estações

Estações devem modificar o ambiente de forma cumulativa.

Não limitar a:

> trocar verde por laranja.

Podem alterar:

- espécies presentes;
- densidade;
- flores;
- folhas caídas;
- cores secundárias;
- umidade;
- iluminação;
- elementos de chão.

A base visual deve continuar reconhecível.

## 14. Territórios

Cada território pode possuir uma identidade ambiental própria.

A diferenciação deve ocorrer através de uma combinação de:

- paleta;
- espécies;
- densidade;
- materiais;
- relevo visual;
- elementos locais;
- clima;
- iluminação;
- composição.

Não depender de uma única cor para comunicar o território.

Exemplos conceituais:

**Fazenda**
- natureza cultivável;
- vegetação moderada;
- caminhos;
- áreas abertas.

**Floresta**
- maior densidade;
- sombras;
- espécies diferentes;
- maior verticalidade visual.

**Pântano**
- umidade;
- vegetação específica;
- água;
- áreas de solo exposto.

Esses exemplos são direção conceitual, não definição final dos territórios do jogo.

## 15. Magia no terreno

A magia deve poder existir no ambiente sem transformar todo o chão em uma superfície luminosa.

Ela pode aparecer como:

- mudança localizada de cor;
- pequenas plantas incomuns;
- partículas raras;
- flores especiais;
- crescimento anormal;
- pequenas fontes luminosas;
- raízes;
- cristais;
- alterações de iluminação.

> **Magia deve modificar a natureza, não simplesmente sobrepor efeitos sobre ela.**

## 16. Corrupção

A corrupção deve alterar o sistema ambiental.

Não tratar como simples filtro de cor.

Ela pode afetar:

- ausência ou morte de vegetação;
- forma da vegetação;
- solo;
- pedras;
- raízes;
- água;
- iluminação;
- partículas;
- densidade;
- composição.

A corrupção deve possuir graus.

Conceitualmente:

**saudável → contaminado → fortemente corrompido**

O mapa deve poder comunicar esses estados mesmo sem interface.

## 17. Purificação

Purificação deve parecer restauração da vida.

Ela pode reintroduzir:

- vegetação;
- cor;
- água;
- flores;
- pequenas criaturas;
- elementos mágicos;
- iluminação mais saudável.

Evitar uma transformação instantânea baseada apenas em troca de textura quando a ficção permitir uma transição gradual.

A purificação deve ser visualmente recompensadora.

## 18. Eventos

Eventos temporários devem utilizar o sistema existente em vez de criar uma linguagem paralela.

Exemplos conceituais:

- chuva incomum;
- florescimento;
- queda de sementes;
- manifestação mágica;
- alteração temporária de vegetação;
- surgimento de pequenos elementos raros.

Eventos podem aumentar temporariamente a densidade visual em regiões específicas.

## 19. Relação com agricultura

A agricultura deve permanecer como uma camada claramente legível.

O terreno não pode competir com:

- brotos;
- plantas maduras;
- frutos;
- ferramentas;
- golems.

Em áreas cultivadas, a densidade de decoração deve ser reduzida onde prejudicar a leitura.

## 20. Relação com criaturas e golems

O terreno é o contexto visual das criaturas.

Portanto:

- animais precisam contrastar com o chão;
- golems precisam manter leitura de material;
- pequenos efeitos não devem esconder silhuetas;
- regiões especiais podem alterar o contraste, mas não podem tornar criaturas ilegíveis.

## 21. Proceduralidade

O projeto atual utiliza FarmLandscape.gd para gerar:

- trilhas;
- clareiras;
- tufos;
- flores.

Isso pode continuar existindo.

Porém, proceduralidade deve controlar distribuição, não inventar arbitrariamente a identidade visual.

Regra:

> **assets definem aparência; sistemas definem distribuição.**

Se um elemento procedural não consegue obedecer à direção visual, deve ser substituído, limitado ou convertido em composição de assets.

## 22. Shader

O projeto atual utiliza Shaders/farm_grass.gdshader para aplicar uma mistura de cor à grama.

Isso deve ser tratado como ferramenta técnica/prototípica.

Um shader pode auxiliar:

- clima;
- transições;
- variações sutis;
- estados temporários.

Mas não deve ser utilizado para substituir arte específica quando a mudança exigir nova forma, textura ou composição.

Regra:

> **Shader pode modificar o estado visual; não deve ser usado para fabricar uma nova identidade artística inteira a partir de uma textura única.**

## 23. Transições entre territórios

Territórios não devem terminar em uma linha artificial.

A transição pode utilizar:

- espécies intermediárias;
- mudança gradual de densidade;
- alteração progressiva de paleta;
- elementos compartilhados;
- caminhos;
- água;
- pedras;
- vegetação de borda.

O jogador deve perceber a mudança sem necessariamente enxergar uma fronteira de textura.

## 24. Regra de identidade entre regiões

Uma nova região deve responder positivamente a:

1. Ela parece visualmente diferente?
2. Ela ainda parece Cauldron Crops?
3. A pixel density continua coerente?
4. A linguagem de luz continua coerente?
5. As silhuetas continuam pertencendo ao mesmo universo?
6. O contraste continua funcional?
7. A região possui características próprias além de uma nova paleta?

Se a resposta à segunda pergunta for não, a região precisa ser revisada.

## 25. Benchmark de terreno

O primeiro teste de produção deverá conter:

- 1 tile de terreno base;
- 2–3 variações compatíveis;
- uma transição;
- uma pequena área de solo cultivável;
- 2–3 tipos de vegetação pequena;
- 1 flor;
- 1 planta agrícola;
- uma pequena composição de cenário.

O benchmark deve ser avaliado em repetição real dentro do Godot.

## 26. Teste de estresse do benchmark

Depois do primeiro benchmark, o mesmo conjunto deve ser testado conceitualmente em:

### Estado A
Terreno saudável.

### Estado B
Chuva.

### Estado C
Alteração sazonal.

### Estado D
Região diferente.

### Estado E
Corrupção.

### Estado F
Purificação.

O objetivo não é produzir seis versões finais.

O objetivo é verificar se a linguagem consegue suportar essas transformações sem quebrar.

## 27. Critérios de aprovação

O terreno será considerado bem-sucedido quando:

- não parecer um tile genérico;
- não denunciar repetição rapidamente;
- não parecer 8-bit sem intenção;
- não dominar visualmente a tela;
- suportar diferentes paletas;
- suportar diferentes densidades;
- permitir leitura clara da agricultura;
- permitir leitura clara de criaturas;
- aceitar mudanças de clima;
- aceitar mudanças de território;
- aceitar estados de corrupção/purificação;
- continuar reconhecível como Cauldron Crops.

## 28. O que não fazer

Não:

- gerar uma textura única e chamá-la de sistema de terreno;
- criar uma textura completamente diferente para cada clima;
- usar filtro de matiz como solução universal;
- preencher cada espaço vazio com decoração;
- usar ruído procedural excessivo;
- fazer toda magia brilhar;
- usar a mesma densidade de vegetação em todos os territórios;
- esconder repetição com microdetalhes;
- sacrificar legibilidade da agricultura pela decoração.

## 29. Próxima produção

A próxima especificação operacional deverá transformar este documento em um pedido para PixelLab contendo:

- referência de densidade;
- dimensões;
- tipo de tileset;
- necessidade de seamless/repeat;
- número de variações;
- regras de borda;
- paleta candidata;
- elementos proibidos;
- exemplos de uso;
- contexto de Godot.

**Não produzir em massa antes da avaliação do primeiro benchmark.**

---

## Estado

**Terrain Language conceitualmente definido.**

**Não é uma aprovação estética final.**

Próxima etapa: construir o Benchmark 01 — Terreno e produzir somente o conjunto mínimo necessário para testá-lo no contexto real do jogo.
