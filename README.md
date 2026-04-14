<div align="center">

# Boleta Scalper Pro

### Painel de trading para MetaTrader 5 · `BoletaScalperPro.mq5`

**Execução manual com gestão avançada · XAUUSD & scalping**

[![MetaTrader 5](https://img.shields.io/badge/MetaTrader-5-00A79D?style=for-the-badge)](https://www.metatrader5.com)
[![MQL5](https://img.shields.io/badge/MQL5-Expert%20Advisor-004D40?style=for-the-badge)](https://www.mql5.com)
[![Uso](https://img.shields.io/badge/Uso-educacional%20%2F%20operacional-5C6BC0?style=for-the-badge)]()

*Copywriter · **Negueba Trader***

[Visão geral](#visão-geral) · [O que faz](#o-que-este-ea-faz) · [Instalação](#como-instalar-no-metatrader-5) · [Tour](#tour-pelo-painel) · [Arquitetura](#arquitetura-do-projeto) · [Defaults](#valores-padrão-scalper-xauusd) · [Fluxo](#fluxo-rápido-de-uso) · [Repo](#repositório)

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
