<div align="center">

# Boleta Scalper Pro

### Painel de trading para MetaTrader 5 · `BoletaScalperPro.mq5`

**Execução manual com gestão avançada · XAUUSD & scalping**

[![MetaTrader 5](https://img.shields.io/badge/MetaTrader-5-00A79D?style=for-the-badge)](https://www.metatrader5.com)
[![MQL5](https://img.shields.io/badge/MQL5-Expert%20Advisor-004D40?style=for-the-badge)](https://www.mql5.com)
[![Uso](https://img.shields.io/badge/Uso-educacional%20%2F%20operacional-5C6BC0?style=for-the-badge)]()

*Copywriter · **Negueba Trader***

[Visão geral](#visão-geral) · [Proposta educacional](#proposta-educacional-e-manual-de-estudos) · [Como funciona](#como-a-boleta-funciona-por-dentro-boletascalperpromq5) · [O que faz](#o-que-este-ea-faz) · [Instalação](#como-instalar-no-metatrader-5) · [Tour](#tour-pelo-painel) · [Botões de gestão](#guia-didático-botões-trail-atr-e-step-tstt-xauusd) · [Arquitetura](#arquitetura-do-projeto) · [Defaults](#valores-padrão-scalper-xauusd) · [Fluxo](#fluxo-rápido-de-uso) · [Repo](#repositório)

</div>

---

## 📊 Visão geral

> **TL;DR** · Painel no gráfico → ajusta risco (incl. escada STEP opcional) → clica para operar → trailing (degraus ou ATR) e meta do dia acompanhados em tempo real.

**BoletaScalperPro** é um *Expert Advisor* (EA) que **não abre ordens sozinho** com base em sinais automáticos: ele oferece uma **boleta gráfica** sobre o gráfico do MT5 para você **comprar e vender com um clique**, ajustar **lote**, **TP/SL em pontos**, **presets** de perfil e usar **trailing** em **degraus (STEP TS/TT)**, **escada de trava opcional** e modo **ATR**. Tudo focado no símbolo do gráfico atual (ex.: **XAUUSD** na ZeroMarkets ou outro broker MT5).

| | |
|:---|:---|
| **Tipo** | EA de execução manual + gestão de posições abertas por ele |
| **Plataforma** | MetaTrader 5 |
| **Ficheiro principal** | `BoletaScalperPro.mq5` |
| **Ideal para** | Scalping e day trade com controle visual rápido |

---

## 🎓 Proposta educacional e manual de estudos

> **Objetivo pedagógico:** transformar cliques de execução em rotina técnica com método, disciplina e leitura de risco.

Esta boleta foi desenhada para apoiar o aluno no processo de tomada de decisão, não para "adivinhar mercado". Em linguagem de sala de aula:

1. **Leitura**: você define contexto (tendência, range, evento, volatilidade).
2. **Plano**: você fixa lote, SL, TP e gatilho antes da entrada.
3. **Execução**: escolhe o botão conforme o tipo de gestão (normal, ATR, STEP TS/TT).
4. **Acompanhamento**: usa INFO e status de gestão para validar se o plano está a ser cumprido.
5. **Revisão**: separa estratégias por modo (TS/TT/AT) para estudar desempenho depois.

### Roteiro didático sugerido (treino em demo)

| Semana | Foco | Meta de aprendizagem |
|:-------|:-----|:----------------------|
| **1** | **Modo normal (COMPRAR/VENDER)** | Entender relação TP/SL em pontos e impacto no financeiro por lote. |
| **2** | **STEP TS/TT** | Dominar gatilho, BE offset, trail move e escada de trava. |
| **3** | **TRAIL ATR** | Entender como o ATR altera a distância dinâmica de gestão em sessão volátil vs. sessão lenta. |
| **4** | **Comparação entre modos** | Medir consistência, drawdown e aderência ao plano para cada contexto. |

### Conduta operacional (ABNT2 · linguagem formal)

- Registre hipótese, entrada, modo escolhido, parâmetros e resultado final.
- Evite alterar parâmetros "no calor" da operação sem motivo técnico documentado.
- Priorize consistência de processo antes de buscar aumento de lote.
- Replique em conta demo até conseguir repetibilidade estatística mínima.

### Conversão didática oficial (XAUUSD)

Para os exemplos deste projeto, adote a seguinte proporção operacional:

- **0,01 lote a cada 100 pontos equivale a US$ 1,00**.

Com isso, fica simples escalar:

- **0,02 lote**: 100 pts ≈ **US$ 2,00**
- **0,05 lote**: 100 pts ≈ **US$ 5,00**
- **0,10 lote**: 100 pts ≈ **US$ 10,00**

> Regra de bolso para ensino:  
> **Resultado estimado (US$) = (Pontos / 100) × (Lote / 0,01)**.

---

## 🧠 Como a boleta funciona por dentro (`BoletaScalperPro.mq5`)

No ficheiro principal, a lógica é curta e objetiva, com quatro eventos:

- **`OnInit()`**: calcula posição inicial no gráfico e chama `Panel_InitBoleta(...)`.
- **`OnTick()`**: coleta PnL/posições, atualiza meta do dia, refresca painel e chama `GerenciarTrailing()`.
- **`OnChartEvent()`**: repassa cliques/edições/arrasto para `Panel_OnChartEvent(...)`.
- **`OnDeinit()`**: libera recursos (ex.: handle do ATR).

### Fluxo técnico do `OnTick()` (didático)

1. **Varredura de posições**: soma PnL total da conta, PnL do símbolo atual, contagem BUY/SELL e ticket de referência.
2. **Meta diária**: define base do dia (`metaDayStartBalance`), calcula `metaValor`, `pnlDia` e `faltaMeta`.
3. **Refresh visual**: atualiza bloco INFO em janela temporal (`PANEL_REFRESH_MS`) para não "pesar" a UI.
4. **Gestão ativa**: executa trailing (STEP/ATR) em todas as posições elegíveis do símbolo.

### Papel de cada modo de negociação (visão de professor)

| Modo | Mecânica | Quando o aluno tende a usar melhor |
|:-----|:---------|:-----------------------------------|
| **Normal** | Entra com SL/TP fixos, sem lógica extra de trailing automático específico. | Treino inicial de execução, disciplina de risco e leitura de payoff. |
| **TRAIL ATR** | Após gatilho + BE, move níveis com distância dinâmica (`ATR × ATR_Mult`). | Sessões com volatilidade variável, quando stop fixo fica "duro" demais. |
| **STEP TS** | Degraus fixos após gatilho; BE, trail move e escada opcional. | Operação mecânica com regras claras e repetíveis. |
| **STEP TT** | Mesma lógica do TS, alterando etiqueta/magic para separar contexto. | Estudos A/B no histórico, sem mudar algoritmo de gestão. |

### Exemplos práticos de escolha de modo

- **Exemplo 1 (abertura de Londres, ouro acelerando):** tendência limpa e ATR a subir. Estratégia didática: testar `TRAIL ATR` para permitir "respiração" da posição.  
  Simulação: lote **0,01**, avanço de **320 pts** ≈ **US$ 3,20**.
- **Exemplo 2 (mercado em range curto):** oscilação previsível em caixas. Estratégia didática: `STEP TS` com gatilho e trail mais curtos para travar parcial de movimento.  
  Simulação: lote **0,02**, avanço de **180 pts** ≈ **US$ 3,60**.
- **Exemplo 3 (duas leituras diferentes no mesmo dia):** usar `STEP TS` numa ideia e `STEP TT` noutra para separar histórico por etiqueta e comparar eficácia.  
  Simulação comparativa:  
  TS: lote **0,01**, +250 pts ≈ **US$ 2,50** · TT: lote **0,01**, +140 pts ≈ **US$ 1,40**.

> **Nota de ensino:** TS e TT não mudam a matemática da gestão; mudam a rastreabilidade da estratégia.

---

## ⚡ O que este EA faz

### Em resumo

> **Papel do EA:** *interface de execução* + *gestão das posições que ele próprio etiqueta* — não substitui a tua análise de mercado.

1. **Desenha um painel** escuro e moderno no gráfico (arrastável).
2. **Envia ordens** COMPRA/VENDA com SL e TP definidos em **pontos** do símbolo.
3. **Modos especiais** nos comentários/magic: trailing em degraus (**TS** / **TT**, com botões dedicados no painel) e trailing **ATR** (**AT**).
4. **Escada de trava** (opcional, só STEP): após o **gatilho de lucro**, pode exigir que o SL avance em degraus conforme o lucro a favor desde a entrada — configurável em **Lucro/degrau** e **Trava/degrau** (qualquer um a **0** desliga a escada).
5. **Atualiza o painel** com spread, ATR, PnL, contagem de posições, saldo e **meta diária** (% sobre o saldo do início do dia).
6. **Gerencia trailing** a cada tick nas posições que correspondem aos modos da boleta.
7. **Fecha posições** do símbolo atual: todas, só BUY ou só SELL.

### Detalhes técnicos (comportamento)

| Área | O que acontece |
|:-----|:---------------|
| **Ordens normais** | Botões COMPRAR / VENDER com TP/SL fixos em pontos a partir do preço de entrada. |
| **STEP TS / TT** | Trailing em degraus após o gatilho: *break-even* com offset, **Trail Move** e, se ativa, **escada** (Lucro/degrau + Trava/degrau). **TS** e **TT** usam a mesma lógica no código; mudam **magic** e **tag** no comentário (`7701` / `7702`). |
| **TRAIL ATR** | Abre com magic específico; após lucro mínimo, move SL/TP usando **ATR × multiplicador**, com passo de *break-even* configurável. |
| **Validação SL/TP** | Ajusta distâncias ao **stop level** e **freeze level** do símbolo para reduzir rejeições do servidor. |
| **Meta do dia** | Usa **equity** vs. saldo no início do dia civil; barra de progresso e texto “falta $X”. |
| **Performance UI** | Atualização do bloco de informações limitada em tempo (~250 ms), enquanto o trailing segue no tick. |
| **Logs** | Botão **LOG ON/OFF** controla mensagens no *Journal* do terminal. |

> **Importante**  
> O EA age sobre posições do **mesmo símbolo do gráfico**. Ordens manuais sem o formato de comentário da boleta aparecem como gestão **“manual”** no painel de status.

---

## 🧩 Arquitetura do projeto

> **Porquê modular?** · Separa **dados** (`Data_State`), **negócio de ordens** (`Trade_Core`) e **interface** (`Panel_UI`) — mais fácil de ler, testar ideias e evoluir sem um único ficheiro gigante.

O código está **modular** para facilitar manutenção e evolução:

| Módulo | Ficheiro | Papel |
|:-------|:---------|:------|
| **Model** | `Data_State.mqh` | Estado global, presets (incl. escada por preset), parâmetros numéricos, layout (`PANEL_W` / `PANEL_H`). |
| **Controller** | `Trade_Core.mqh` | `CTrade`, abertura/fecho, validações, trailing **STEP** (degraus + escada opcional), **ATR**, logs. |
| **View** | `Panel_UI.mqh` | Cores, grelha de edits alinhados, rótulos (incl. negrito onde aplicável), botões **STEP** / **ATR**, separador, eventos de clique e arraste. |
| **Orquestração** | `BoletaScalperPro.mq5` | `OnInit`, `OnTick`, `OnDeinit`, `OnChartEvent`. |

> O ficheiro `BoletaCódigoBase.mq5` é uma **versão monolítica de referência**; o dia a dia do projeto usa a versão modular acima.

---

## 📥 Como instalar no MetaTrader 5

### Opção A — Já estás na pasta correta do terminal

> **Caminho típico (Windows):**  
> `%AppData%\MetaQuotes\Terminal\<ID_do_terminal>\MQL5\Experts\Boleta-Modular\`

Se o projeto já está em:

`...\MetaQuotes\Terminal\<ID>\MQL5\Experts\Boleta-Modular\`

1. Abre o **MetaEditor** (F4 no MT5 ou menu *Ferramentas*).
2. No *Navegador*, abre `BoletaScalperPro.mq5`.
3. Clica **Compilar** (F7) e confirma **0 erros** na aba *Erros*.
4. No MT5, no *Navegador* → *Consultores Especializados*, arrasta **BoletaScalperPro** para o gráfico desejado (ex.: XAUUSD).
5. Em **AutoTrading**, permite execução algorítmica (botão verde na barra de ferramentas).

### Opção B — Clonar / copiar do GitHub

1. Clona o repositório (ou faz *Download ZIP*):  
   **https://github.com/NeguebaOficial/BoletaScalperPro**
2. Copia a pasta **`Boleta-Modular`** (ou os ficheiros `.mq5` + `.mqh`) para:  
   `MQL5\Experts\Boleta-Modular\`
3. Repete os passos **2–5** da Opção A.

### Permissões recomendadas ao anexar o EA

| Opção | Sugestão |
|:------|:---------|
| **Permitir trading algorítmico** | Ativado |
| **Permitir importação de DLLs** | Só se no futuro o EA usar DLL (hoje não é necessário) |

> **Dica**  
> Se alterares código, volta a **compilar** no MetaEditor antes de recarregar o EA no gráfico.

---

## 🖥️ Tour pelo painel

> **Mapa mental:** *topo* = lote e presets · *meio* = grelha de risco (TP, SL, gatilho, ATR, trail, escada, BE) · *separador* · *baixo* = botões de ordem e fecho · *rodapé* = telemetria e meta do dia.

### Cabeçalho · lote e presets

- **Título** da boleta e botão **LOG** para ligar/desligar prints no Journal.
- **Presets** **SCALP** · **NORMAL** · **SWING** — preenchem TP, SL, gatilho, trail move, BE offset, multiplicador ATR **e** pares **Lucro/degrau** + **Trava/degrau** da escada (valores distintos no SWING; ver `Data_State.mqh`).
- **Lote**: campo editável + atalhos **0,03 / 0,06 / 0,09** e **+ / −**.

### Parâmetros de ordem · risco, ATR e escada

Os rótulos no gráfico usam tipografia em **negrito** onde aplicável; os **edits numéricos** da grelha partilham a **mesma largura** (referência: campo **BE Offset**) para alinhamento visual.

| Rótulo no painel | Função |
|:-----------------|:-------|
| **Take Profit** | TP inicial em pontos. |
| **Stop Loss** | SL inicial em pontos. |
| **Gatilho** | Lucro mínimo em pontos para ativar BE / trailing nos modos geridos (**Start Lucro** no código). |
| **Periodo ATR** | Período do `iATR` usado no **TRAIL ATR**; ao alterar, o handle é recriado. |
| **ATR Mult** | Multiplicador do ATR no modo **TRAIL ATR**. |
| **Trail Move** | Passo em pontos do SL após o BE nos modos **STEP TS/TT** (complementa a escada, se ativa). |
| **Lucro/Degrau** | Só **STEP**: a cada *N* pontos de lucro a favor desde a entrada, sobe um degrau da escada. |
| **Trava/Degrau** | Só **STEP**: por cada degrau de lucro contabilizado, o SL exigido avança este número de pontos a favor **desde o preço de entrada** (compra: SL sobe; venda: SL desce). |
| **BE Offset** | Offset do *break-even* em pontos. |

> **Escada STEP:** só é aplicada se **Lucro/degrau** e **Trava/degrau** forem **ambos** maiores que zero. Se **qualquer um** for **0**, a escada não corre (nos STEP continua **BE** + **Trail Move**).

Entre esta grelha e os botões **COMPRAR / VENDER** existe um **separador horizontal** (linha discreta) e **espaço em branco** para ler o painel em dois blocos: *parâmetros* vs *ações*.

### Ações principais · entrar e sair

| Botão | Ação |
|:------|:-----|
| **COMPRAR / VENDER** | Ordem com SL/TP fixos (modo normal). |
| **TRAIL ATR BUY / SELL** | Abertura com gestão ATR. |
| **STEP TS BUY / SELL** | Abertura com trailing em degraus, magic **TS** (`7701`). |
| **STEP TT BUY / SELL** | Mesma lógica de degraus que **TS**, magic **TT** (`7702`) — útil para distinguir no histórico ou relatórios. |
| **FECHAR BUY / SELL** | Fecha só o lado indicado neste símbolo. |
| **FECHAR TODAS** | Fecha todas as posições **deste símbolo** no gráfico atual. |

### Guia didático: botões TRAIL ATR e STEP TS/TT (XAUUSD)

A boleta foi pensada para operar **XAUUSD** no MT5 com leitura em **pontos** do símbolo (os mesmos valores que vês nos campos **TP**, **SL** e **Gatilho**). Para mentalizar risco em scalping/day trade:

- Para este projeto, adota-se a equivalência didática: **0,01 lote a cada 100 pontos = US$ 1,00**.  
  Exemplo mental rápido: `180 pts` com `0,01` ≈ **US$ 1,80**; com `0,03` ≈ **US$ 5,40**.

Os seis botões verdes/vermelhos da grelha **não mudam o sentido da operação**: verde abre **compra**, vermelho abre **venda**. O que muda é **como a posição será gerida depois de aberta** (comentário + *magic* internos para o EA reconhecer o modo).

---

#### TRAIL ATR BUY / TRAIL ATR SELL

**Ideia:** o stop (e o alvo) acompanham a **volatilidade** recente do mercado, medida pelo **ATR**, em vez de avançarem só em passos fixos em pontos.

**Quando costuma fazer sentido:** quando queres que a gestão **respire** com o ouro — em sessões mais nervosas o ATR sobe e os níveis afastam-se; em consolidação o ATR desce e a gestão aperta. Combina bem com leituras de **impulso** ou **tendência intradia** em que não queres um SL “engessado” só por pontos fixos.

**O que acontece na prática (fases):**

1. **Abertura** — A ordem entra com o **SL** e **TP em pontos** que definiste (como em qualquer modo). O EA marca a posição como modo **ATR** (*magic* dedicado, etiqueta **AT** no comentário).
2. **Antes do gatilho** — Enquanto o preço **não** percorrer o lucro mínimo definido no campo **Gatilho** (o mesmo “Start Lucro” usado nos STEP), **não** há trailing ATR: o risco inicial mantém-se.
3. **Depois do gatilho — break-even** — Quando o lucro a favor atinge esse mínimo, o EA tenta puxar o SL para a zona de **break-even** com o **BE Offset** (em pontos): ou seja, não ficas “flat” no preço exato de entrada, mas com uma pequena **marga a favor** para cobrir spread e ruído.
4. **Trailing ATR** — Depois do BE, o EA passa a ajustar **SL** e **TP** com base na distância **ATR × ATR Mult** (lê **Periodo ATR** e **ATR Mult** no painel). Os níveis são recalculados conforme o mercado evolui, respeitando **stop level** e **freeze** do símbolo.

**Parâmetros que mais importam aqui:** **Gatilho**, **BE Offset**, **Periodo ATR**, **ATR Mult**, além do **TP/SL** inicial que ainda limitam o “esqueleto” da posição no início.

---

#### STEP TS BUY / STEP TS SELL e STEP TT BUY / STEP TT SELL

**Ideia:** gestão em **degraus fixos em pontos** — o mercado tem de andar **X** pontos a favor antes de ativar a lógica; depois o **SL** avança em **passos** configuráveis, com opcional **escada de trava**. O **TP** inicial permanece o que definiste nos edits (o EA não implementa um “trailing de TP” separado neste modo STEP).

**STEP TS vs STEP TT — diferença real para ti:**

- A **lógica de gestão é a mesma** nos dois (mesmos gatilhos, BE, *Trail Move*, escada).
- A diferença é **organizacional**: **TS** usa um *magic* e etiqueta **TS** no comentário; **TT** usa outro *magic* e etiqueta **TT**. Serve para **separar no histórico**, relatórios ou na cabeça (“estas entradas foram estratégia A vs B”) sem alterar o comportamento do trailing.

**O que acontece na prática (fases):**

1. **Abertura** — Compra ou venda com **SL** e **TP** iniciais em pontos (campos **Stop Loss** / **Take Profit**).
2. **Espera pelo gatilho** — Até o preço não andar **Gatilho** pontos a favor desde a entrada, o EA **não** move SL por trailing de degraus.
3. **Após o gatilho** — O EA trabalha para colocar o SL na região de **break-even + BE Offset** (igual filosofia ao ATR: proteger a operação com folga mínima).
4. **Trail Move** — Com o preço a continuar a favor, o SL pode avançar em **saltos** de **Trail Move** pontos (degraus), em vez de “colar” contínuo ao preço.
5. **Escada (opcional)** — Se **Lucro/Degrau** e **Trava/Degrau** forem **ambos** maiores que zero: a cada **Lucro/Degrau** pontos de lucro a favor desde a entrada, sobe um degrau que **exige** que o SL esteja pelo menos **Trava/Degrau** pontos a favor **desde o preço de entrada** (compras: SL sobe; vendas: SL desce). Se **qualquer um** dos dois for **0**, a escada fica desligada e ficam só BE + *Trail Move*.

**Exemplo numérico didático (XAUUSD, 0,01 lote):**  
Se **Gatilho** = 180 pts, precisas de **US$ 1,80** de movimento a favor para a gestão STEP “acordar” e começar a proteger/tracionar o SL.

**Exemplo com lote maior (0,05):**  
No mesmo gatilho de 180 pts, a exigência passa para **US$ 9,00** (cinco vezes maior).

**Quando costuma fazer sentido:** operações em que queres regras **claras e repetíveis** (“só mexo no stop depois de X pontos”, “ando o stop de Y em Y pontos”), típico de scalping com disciplina mecânica.

---

#### Como escolher entre ATR e STEP na mesa

| Situação típica | Sugestão de botão |
|:----------------|:------------------|
| Queres que o stop “sinta” volatilidade e **não** só passos fixos | **TRAIL ATR** |
| Queres regras fixas em **pontos** e opcional escada por lucro | **STEP TS** ou **STEP TT** (conforme queres etiquetar no histórico) |
| Só queres TP/SL fixos sem gestão automática depois da entrada | **COMPRAR** / **VENDER** |

**Regra prática:** configura primeiro **TP**, **SL** e **Gatilho** no painel (ou carrega um **preset**), imagina o movimento em **dólares** com a regra dos 100 pts, e só depois escolhe o botão da linha **ATR** ou **STEP** — o botão só escolhe o **modo de gestão**, não substitui o teu plano de risco nos edits.

### Zona **MOVER** · arrastar o painel

- Arrasta a **barra “MOVER”**, a **borda** ou o **painel** para reposicionar toda a interface.

### Bloco **INFO** · telemetria e meta

- **Spread** (pts) e leitura do **ATR**.
- **PnL** flutuante do símbolo e total da conta.
- **Open** — quantidade de BUY / SELL abertos no símbolo.
- **Saldo** e **Meta 3%** (percentual configurável em código: `MetaD_Percent`).
- **Barra** de progresso da meta do dia.
- **Gestão** — estado resumido (ex.: espera ATR, BE, *step*, *mult*, *manual*).

---

## 📋 Valores padrão scalper XAUUSD

Estes são os **defaults** da linha **SCALP** (espelhados no preset **SCALP**) em `Data_State.mqh`. **NORMAL** e **SWING** sobrescrevem TP/SL, gatilho, trail, BE, ATR mult e **pares da escada** — vê as constantes `PRESET_*` no mesmo ficheiro.

| Campo (UI / variável) | Valor default |
|:----------------------|-------------:|
| Lote inicial (`Lotes`) | 0,01 |
| Take Profit (`TP_Pontos`) | 1 000 pts |
| Stop Loss (`SL_Pontos`) | 1 200 pts |
| Gatilho / Start Lucro (`TrailStep_Pontos`) | 180 pts |
| ATR Period (`ATR_Period`) | 7 |
| ATR Mult (`ATR_Mult`) | 1,20 |
| Trail Move (`TrailMove_Pontos`) | 120 pts |
| Lucro/degrau (`RatchetProfitEvery_Pontos`) | 400 pts (0 = escada off) |
| Trava/degrau (`RatchetLockPts_Pontos`) | 100 pts |
| BE Offset (`BreakEvenOffset_Pontos`) | 100 pts |
| Altura do painel (`PANEL_H`) | 648 px |

> Ajusta sempre ao **teu risco**, ao **contrato do ouro** no broker e ao **stop level** mínimo. Depois de alterar o código, **recompila** e volta a anexar o EA (ou remove objetos antigos) para o layout do painel refletir mudanças de UI.

---

## ▶️ Fluxo rápido de uso

1. Anexa o EA no gráfico do ativo (ex.: **XAUUSD**).  
2. Confere **lote**, **TP/SL**, **Gatilho**, **Trail Move**, **BE** e, se fores usar **STEP**, **Lucro/Degrau** e **Trava/Degrau** (ou carrega um **preset**).  
3. Usa **COMPRAR** / **VENDER** (fixo), **STEP TS/TT** (degraus + escada opcional) ou **TRAIL ATR** conforme a tua leitura de mercado.  
4. Acompanha **INFO** e a **meta do dia**.  
5. Usa **FECHAR** se precisar sair rápido do símbolo.  

---

## 🔗 Repositório

**GitHub:** [github.com/NeguebaOficial/BoletaScalperPro](https://github.com/NeguebaOficial/BoletaScalperPro)

```bash
git clone https://github.com/NeguebaOficial/BoletaScalperPro.git
```

---

## ⚠️ Aviso legal

Trading envolve **risco de perda de capital**. Este software é uma **ferramenta operacional**; não constitui aconselhamento financeiro. Testa em **conta demo** antes de usar dinheiro real e garante que compreendes cada parâmetro e o funcionamento do teu broker.

---

<div align="center">

**Boleta Scalper Pro** · Negueba Trader · MetaTrader 5

*Boleta modular · execução com um clique · STEP / ATR · escada opcional · meta do dia*

</div>
