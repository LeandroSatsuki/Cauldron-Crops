# CAULDRON CROPS — TERRAIN BENCHMARK 01

**Versão:** 0.1  
**Data:** 2026-10-05  
**Status:** TESTE ARTÍSTICO — NÃO FINAL

## Objetivo

Testar a linguagem visual do terreno antes de produzir assets em escala.

Este benchmark não deve substituir imediatamente o terreno atual do jogo. Ele existe para responder:

> "Esta linguagem visual funciona em uma área real de Cauldron Crops?"

## Escopo mínimo

Produzir somente:

1. terreno base;
2. 2–3 variações do terreno base;
3. uma transição para solo preparado;
4. uma pequena seleção de vegetação espontânea;
5. uma flor;
6. uma planta agrícola;
7. uma pequena composição demonstrando repetição.

Não produzir ainda:
- dezenas de tiles;
- múltiplos biomas;
- versões sazonais completas;
- corrupção completa;
- UI;
- grandes árvores;
- produção em massa.

## Pré-condição

Antes de gerar:

1. consultar ART_BIBLE.md;
2. consultar TERRAIN_LANGUAGE.md;
3. inspecionar os assets atuais;
4. determinar a densidade de pixel visual real do projeto;
5. não assumir 16x16, 32x32, 64x64 ou 128x128 sem evidência;
6. usar o terreno atual apenas como referência técnica de função, não como aprovação estética;
7. considerar que o objetivo é substituir a linguagem visual, não melhorar superficialmente o tile existente.

## Direção visual

A natureza deve ser:
- rica;
- orgânica;
- mágica sem ser neon;
- detalhada sem ser ruidosa;
- acolhedora;
- visualmente interessante em grandes áreas.

A inspiração cromática pode considerar a riqueza e a atmosfera de Sun Haven, mas não copiar formas, tiles, composição ou identidade.

A identidade deve continuar sendo Cauldron Crops.

## Terreno

O terreno base deve:
- funcionar em repetição;
- possuir variações discretas;
- não apresentar padrões grandes óbvios;
- não depender de ruído aleatório;
- não parecer 8-bit;
- não parecer uma textura digital suavizada;
- permitir que plantas, criaturas e objetos sejam o foco.

## Vegetação

A vegetação espontânea deve ser composta em pequenos clusters.

Evitar preencher todos os espaços.

O benchmark deve demonstrar:
- área com baixa densidade;
- área com densidade média;
- pequeno ponto de maior densidade.

## Solo cultivável

A transição deve parecer pertencer ao mesmo terreno.

Evitar o efeito:
"grama verde + quadrado marrom".

O solo deve possuir bordas e textura compatíveis com a linguagem do terreno.

## Planta

A planta deve ser usada somente como teste de integração.

Ela precisa:
- permanecer legível;
- possuir contraste suficiente;
- não desaparecer no terreno;
- não parecer importada de outro jogo.

Não gerar uma nova família de crops neste benchmark.

## Magia

A magia não deve ser adicionada apenas através de brilho roxo.

O benchmark pode conter no máximo pequenos indícios de fantasia na vegetação/ambiente.

A função principal é validar a natureza, não demonstrar efeitos mágicos.

## Teste de repetição

A saída deve ser visualizada em uma área suficientemente grande para identificar:
- repetição;
- padrões;
- excesso de ruído;
- diferença entre variações;
- densidade de vegetação.

## Teste de integração

O benchmark deve ser testado ao lado de:
- uma planta;
- um objeto;
- um golem;
- um elemento de cenário;
- o caldeirão de referência provisório.

O objetivo é detectar incompatibilidades, não preservar os assets atuais.

## Critérios de aprovação

Avaliar de 0–5:

- identidade Cauldron Crops;
- pixel density;
- repetição;
- silhueta;
- paleta;
- contraste;
- densidade;
- integração com agricultura;
- integração com criaturas;
- potencial para clima;
- potencial para territórios;
- potencial para corrupção/purificação.

Nenhum resultado deve ser considerado final apenas porque obteve boa pontuação isoladamente.

## Prompt operacional para o agente de arte

"Você está trabalhando como diretor de arte e produtor de pixel art de Cauldron Crops. Antes de gerar qualquer coisa, leia docs/art/ART_BIBLE.md e docs/art/TERRAIN_LANGUAGE.md e inspecione os assets atuais do projeto. Não assuma uma resolução fixa de 16x16, 32x32, 64x64 ou 128x128. Determine a densidade de pixel a partir dos assets e da escala real do projeto.

Crie apenas um benchmark de terreno, não produção final: terreno base repetível, 2–3 variações compatíveis, transição para solo cultivável, pequena vegetação espontânea, uma flor e uma planta agrícola para teste de integração.

O terreno deve parecer vivo, orgânico e fantástico, mas não genérico. A natureza deve ser rica sem ficar visualmente ruidosa. Use variação por clusters e áreas de respiro. Não use ruído procedural como substituto de composição. Evite aparência 8-bit, outlines pretos pesados, excesso de microdetalhes, saturação uniforme e padrões grandes facilmente repetíveis.

Sun Haven pode informar riqueza cromática e atmosfera, mas não copie sua forma, tiles ou identidade.

A magia de Cauldron Crops deve ser orgânica ao mundo. Não transforme o terreno em uma superfície neon nem aplique simplesmente roxo/brilho para comunicar fantasia.

A saída será testada no Godot em repetição real e comparada com os demais assets. Preserve a densidade de pixel e a escala visual do projeto. Não faça upscale ou downscale arbitrário.

Prioridade: linguagem do terreno > beleza isolada do tile.

Antes de considerar o resultado aprovado, mostre o benchmark em contexto de repetição e explique quais decisões visuais foram tomadas e quais ainda permanecem abertas."

## Próximo passo

Gerar somente este benchmark, avaliar no Godot e decidir:
- aprovar;
- iterar;
- rejeitar.

Depois disso a Art Bible poderá receber as regras que sobreviverem ao teste.
