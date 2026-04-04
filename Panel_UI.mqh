//+------------------------------------------------------------------+
//| Panel_UI.mqh — cores, objetos gráficos, painel, eventos de UI    |
//+------------------------------------------------------------------+
#ifndef PANEL_UI_MQH
#define PANEL_UI_MQH

#include "Trade_Core.mqh"

// ================= CORES =================
color COR_BG = (color)0x1E1E1E;
color COR_CARD = (color)0x252526;
color COR_TEXTO = clrWhite;
color COR_LABEL = clrSilver;
color COR_BUY = C'46,180,80';
color COR_SELL = C'230,60,60';
color COR_TEXTO_MUTE = (color)0xBDBDBD;
color COR_BUY_SOFT = C'70,190,120';
color COR_SELL_SOFT = C'220,90,90';
color COR_WARN = C'255,175,60';
color COR_NEUTRO = (color)0x3A3A3A;
color COR_AZUL = (color)0x2979FF;

#define BTN_FONT_REGULAR "Segoe UI"
#define BTN_FONT_BOLD "Arial Bold"

string objetos[53] = {
   "painelBorder", "painel", "lblTitulo", "lblLote", "editLote", "btnLot03", "btnLot06", "btnLot09",
   "btnLotPlus", "btnLotMinus", "lblTP", "editTP", "lblSL", "editSL",
   "lblTrailStep", "editTrailStep",
   "btnPresetScalp", "btnPresetNormal", "btnPresetSwing",
   "btnBuy", "btnSell",
   "btnBuyATR", "btnSellATR",
   "lblATRPeriod", "editATRPeriod", "lblATRMul", "editATRMul",
   "lblTrailMove", "editTrailMove", "lblBEOffset", "editBEOffset",
   "btnLogs",
   "btnCloseAll", "btnCloseBuys", "btnCloseSells",
   "lblInfoTitulo",
   "lblK_SprATR", "lblV_SprATR",
   "lblK_PnL", "lblV_PnL",
   "lblK_Open", "lblV_Open",
   "lblK_Saldo", "lblV_Saldo",
   "lblK_Meta", "lblV_Meta",
   "lblSepOpenMeta",
   "barMetaBG", "barMetaFill",
   "lblK_Gestao", "lblV_Gestao", "lblMover",
   "dragHandle"};

//+------------------------------------------------------------------+
void UpdateEditInt(const string name, const int value)
  {
   ObjectSetString(0, name, OBJPROP_TEXT, IntegerToString(value));
  }

void UpdateEdit(const string name, double value)
  {
   ObjectSetString(0, name, OBJPROP_TEXT, DoubleToString(value, 2));
  }

void ApplyPreset(const int presetId)
  {
   ApplyPresetToState(presetId);

   if(ObjectFind(0, "editTP") >= 0) UpdateEditInt("editTP", TP_Pontos);
   if(ObjectFind(0, "editSL") >= 0) UpdateEditInt("editSL", SL_Pontos);
   if(ObjectFind(0, "editTrailStep") >= 0) UpdateEditInt("editTrailStep", TrailStep_Pontos);
   if(ObjectFind(0, "editTrailMove") >= 0) UpdateEditInt("editTrailMove", TrailMove_Pontos);
   if(ObjectFind(0, "editBEOffset") >= 0) UpdateEditInt("editBEOffset", BreakEvenOffset_Pontos);
   if(ObjectFind(0, "editATRMul") >= 0) ObjectSetString(0, "editATRMul", OBJPROP_TEXT, DoubleToString(ATR_Mult, 2));
  }

string LogsButtonText() { return EnableLogs ? "LOG: ON" : "LOG: OFF"; }

color LogsButtonColor() { return EnableLogs ? COR_AZUL : COR_NEUTRO; }

//+------------------------------------------------------------------+
void AtualizarPainelInformacao(const string symbol,
                               const double pnlTotal,
                               const double pnlSymbol,
                               const int posCount,
                               const int openBuy,
                               const int openSell,
                               const ulong firstTicket,
                               const double saldo,
                               const double metaValor,
                               const double faltaMeta,
                               const bool metaBatida)
  {
   double symPoint = SymbolPointSafe(symbol);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double spreadPts = (ask > 0.0 && bid > 0.0 && symPoint > 0.0) ? ((ask - bid) / symPoint) : 0.0;
   double atrVal = GetAtrValue();

   double spreadDisp = MathAbs(spreadPts);
   string atrTxt = (atrVal > 0.0 ? DoubleToString(atrVal, _Digits) : "--");

   ObjectSetString(0, "lblV_SprATR", OBJPROP_TEXT,
                   StringFormat("%.0f pts | ATR(%d) %s", spreadDisp, ATR_Period, atrTxt));
   ObjectSetInteger(0, "lblV_SprATR", OBJPROP_COLOR, COR_TEXTO);

   ObjectSetString(0, "lblV_PnL", OBJPROP_TEXT,
                   StringFormat("flt $%.2f | tot $%.2f", pnlSymbol, pnlTotal));
   ObjectSetInteger(0, "lblV_PnL", OBJPROP_COLOR, pnlSymbol >= 0.0 ? COR_BUY_SOFT : COR_SELL_SOFT);

   ObjectSetString(0, "lblV_Open", OBJPROP_TEXT,
                   StringFormat("▲ %d  ▼ %d", openBuy, openSell));
   ObjectSetInteger(0, "lblV_Open", OBJPROP_COLOR, COR_TEXTO);

   ObjectSetString(0, "lblV_Saldo", OBJPROP_TEXT,
                   StringFormat("$%.2f", saldo));
   ObjectSetInteger(0, "lblV_Saldo", OBJPROP_COLOR, COR_TEXTO);

   ObjectSetString(0, "lblV_Meta", OBJPROP_TEXT,
                   StringFormat("$%.0f  |  falta $%.0f", metaValor, faltaMeta));
   ObjectSetInteger(0, "lblV_Meta", OBJPROP_COLOR, COR_TEXTO);

   double pnlDia = metaValor - faltaMeta;
   double prog = 0.0;
   if(metaValor > 0.0) prog = pnlDia / metaValor;
   if(prog < 0.0) prog = 0.0;
   if(prog > 1.0) prog = 1.0;

   int fillW = (int)MathRound(metaBarW * prog);
   if(fillW < 0) fillW = 0;
   if(fillW > metaBarW) fillW = metaBarW;

   ObjectSetInteger(0, "barMetaFill", OBJPROP_XSIZE, fillW);
   color barCor = metaBatida ? COR_BUY_SOFT : COR_NEUTRO;
   ObjectSetInteger(0, "barMetaFill", OBJPROP_BGCOLOR, barCor);

   string status = "—";
   if(posCount == 1 && firstTicket != 0 && PositionSelectByTicket(firstTicket))
     {
      long magic = PositionGetInteger(POSITION_MAGIC);
      string comment = PositionGetString(POSITION_COMMENT);
      string tag;
      int slPts = 0, tpPts = 0, stepPts = 0;
      if(ParseTrailComment(comment, tag, slPts, tpPts, stepPts))
        {
         int posType = (int)PositionGetInteger(POSITION_TYPE);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double curSL = PositionGetDouble(POSITION_SL);
         status = BuildManagementStatus(magic, tag, posType, openPrice, curSL, bid, ask, stepPts, symPoint);
        }
      else
         status = "manual";
     }
   else if(posCount > 1)
      status = "mult";

   string g;
   if(metaBatida)
      g = (status == "—" ? "OK" : StringFormat("OK · %s", status));
   else
      g = status;

   color corGest = metaBatida ? COR_BUY_SOFT : COR_LABEL;
   if(!metaBatida && StringFind(status, "wait") >= 0)
      corGest = COR_WARN;

   ObjectSetString(0, "lblV_Gestao", OBJPROP_TEXT, g);
   ObjectSetInteger(0, "lblV_Gestao", OBJPROP_COLOR, corGest);
  }

//+------------------------------------------------------------------+
void CreateRectangle(string name, int x, int y, int w, int h, color cor)
  {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, cor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
  }

void CreateButton(string name, int x, int y, int w, int h, string text, color cor, bool textoNegrito = false)
  {
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, cor);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, name, OBJPROP_FONT, textoNegrito ? BTN_FONT_BOLD : BTN_FONT_REGULAR);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
  }

void SetTooltip(string name, string tooltip)
  {
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
  }

void CreateEdit(string name, int x, int y, int w, int h, string text)
  {
   ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, COR_CARD);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
  }

void CreateLabel(string name, int x, int y, string text, color cor, int size)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   string fontName = "Segoe UI Semilight";
   if(cor == COR_BUY || cor == COR_SELL || cor == COR_BUY_SOFT || cor == COR_SELL_SOFT || cor == COR_LABEL || cor == COR_TEXTO || cor == COR_WARN)
      fontName = "Segoe UI Semibold";
   ObjectSetString(0, name, OBJPROP_FONT, fontName);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
  }

//+------------------------------------------------------------------+
void Panel_InitBoleta(const int x, const int y)
  {
   lastPanelX = x;
   lastPanelY = y;

   CreateRectangle("painelBorder", x - PANEL_BORDER_PAD, y - PANEL_BORDER_PAD, PANEL_W + 4, PANEL_H + 4, COR_NEUTRO);
   ObjectSetInteger(0, "painelBorder", OBJPROP_BACK, false);
   ObjectSetInteger(0, "painelBorder", OBJPROP_ZORDER, 0);
   ObjectSetInteger(0, "painelBorder", OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, "painelBorder", OBJPROP_SELECTED, false);

   CreateRectangle("painel", x, y, PANEL_W, PANEL_H, COR_BG);
   ObjectSetInteger(0, "painel", OBJPROP_BACK, false);
   ObjectSetInteger(0, "painel", OBJPROP_ZORDER, 1);
   ObjectSetInteger(0, "painel", OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, "painel", OBJPROP_SELECTED, false);

   CreateRectangle("dragHandle", x + DRAG_X_OFF, y + DRAG_Y_OFF, DRAG_W, DRAG_H, clrGray);
   ObjectSetInteger(0, "dragHandle", OBJPROP_BACK, false);
   ObjectSetInteger(0, "dragHandle", OBJPROP_ZORDER, 25);
   ObjectSetInteger(0, "dragHandle", OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, "dragHandle", OBJPROP_SELECTED, false);
   SetTooltip("dragHandle", "Arraste aqui para mover o painel");

   atrHandle = iATR(_Symbol, _Period, ATR_Period);
   if(atrHandle == INVALID_HANDLE)
      Log("ATR: handle inválido. Verifique ATR_Period.");

   CreateLabel("lblTitulo", x + 20, y + 10, "Boleta Negueba Trader", COR_TEXTO, 11);

   CreateButton("btnLogs", x + 300, y + 8, 70, 22, LogsButtonText(), LogsButtonColor(), false);
   SetTooltip("btnLogs", "Liga/desliga logs no Journal (erros e eventos da boleta).");

   CreateLabel("lblLote", x + 20, y + 40, "Lote", COR_LABEL, 9);
   CreateEdit("editLote", x + 20, y + 60, 80, 28, DoubleToString(Lotes, 2));
   SetTooltip("lblLote", "Volume da ordem (lotes). Ex: 0.01. Ajuste conforme seu risco.");
   SetTooltip("editLote", "Volume da ordem (lotes). Ex: 0.01. Ajuste conforme seu risco.");

   CreateButton("btnPresetScalp", x + 110, y + 34, 70, 20, "SCALP", COR_NEUTRO, false);
   CreateButton("btnPresetNormal", x + 185, y + 34, 70, 20, "NORMAL", COR_NEUTRO, false);
   CreateButton("btnPresetSwing", x + 260, y + 34, 70, 20, "SWING", COR_NEUTRO, false);
   CreateLabel("lblMover", x + DRAG_X_OFF + (DRAG_W / 2), y + DRAG_Y_OFF + (DRAG_H / 2), "MOVER", COR_TEXTO, 8);
   ObjectSetInteger(0, "lblMover", OBJPROP_ANCHOR, ANCHOR_CENTER);
   SetTooltip("btnPresetScalp", "Preset SCALP (XAUUSD): preenche TP/SL/Start/TrailMove/BE/ATR Mult.");
   SetTooltip("btnPresetNormal", "Preset NORMAL (XAUUSD): preenche TP/SL/Start/TrailMove/BE/ATR Mult.");
   SetTooltip("btnPresetSwing", "Preset SWING (XAUUSD): preenche TP/SL/Start/TrailMove/BE/ATR Mult.");
   SetTooltip("lblMover", "Use a barra ao fundo para arrastar o painel.");

   CreateButton("btnLot03", x + 110, y + 60, 55, 28, "0.03", COR_AZUL, false);
   SetTooltip("btnLot03", "Lote fixo: 0.03");
   CreateButton("btnLot06", x + 170, y + 60, 55, 28, "0.06", COR_AZUL, false);
   SetTooltip("btnLot06", "Lote fixo: 0.06");
   CreateButton("btnLot09", x + 230, y + 60, 55, 28, "0.09", COR_AZUL, false);
   SetTooltip("btnLot09", "Lote fixo: 0.09");

   CreateButton("btnLotPlus", x + 295, y + 60, 30, 28, "+", COR_BUY, true);
   SetTooltip("btnLotPlus", "Aumenta o lote em +0.01 (mín. 0.01)");
   CreateButton("btnLotMinus", x + 330, y + 60, 30, 28, "-", COR_SELL, true);
   SetTooltip("btnLotMinus", "Diminui o lote em -0.01 (mín. 0.01)");

   CreateLabel("lblTP", x + 20, y + 100, "Take Profit", COR_LABEL, 9);
   CreateEdit("editTP", x + 20, y + 120, 130, 28, IntegerToString(TP_Pontos));
   SetTooltip("lblTP", "TP inicial em pontos (pts). Digits=2: 100 pts = $1.00 no XAUUSD.");
   SetTooltip("editTP", "TP inicial em pontos (pts). Digits=2: 100 pts = $1.00 no XAUUSD.");

   CreateLabel("lblSL", x + 170, y + 100, "Stop Loss", COR_LABEL, 9);
   CreateEdit("editSL", x + 170, y + 120, 130, 28, IntegerToString(SL_Pontos));
   SetTooltip("lblSL", "SL inicial em pontos (pts). Deve ser maior que o spread e respeitar o stop level.");
   SetTooltip("editSL", "SL inicial em pontos (pts). Deve ser maior que o spread e respeitar o stop level.");

   CreateLabel("lblTrailStep", x + 290, y + 100, "Start Lucro pts", COR_LABEL, 9);
   CreateEdit("editTrailStep", x + 290, y + 120, 70, 28, IntegerToString(TrailStep_Pontos));
   SetTooltip("lblTrailStep", "Gatilho (lucro em pts) para ativar a gestão (BE/ATR). Antes disso não move SL/TP.");
   SetTooltip("editTrailStep", "Gatilho (lucro em pts) para ativar a gestão (BE/ATR). Antes disso não move SL/TP.");

   CreateLabel("lblATRPeriod", x + 20, y + 160, "ATR Period", COR_LABEL, 9);
   CreateEdit("editATRPeriod", x + 20, y + 178, 130, 24, IntegerToString(ATR_Period));
   SetTooltip("lblATRPeriod", "Período do ATR usado no TRAIL ATR. Ex: 14. Quanto maior, mais 'lento' o trailing.");
   SetTooltip("editATRPeriod", "Período do ATR usado no TRAIL ATR. Ex: 14. Quanto maior, mais 'lento' o trailing.");

   CreateLabel("lblATRMul", x + 170, y + 160, "ATR Mult", COR_LABEL, 9);
   CreateEdit("editATRMul", x + 170, y + 178, 130, 24, DoubleToString(ATR_Mult, 2));
   SetTooltip("lblATRMul", "Multiplicador do ATR no TRAIL ATR. Maior = SL/TP mais distantes (mais folga).");
   SetTooltip("editATRMul", "Multiplicador do ATR no TRAIL ATR. Maior = SL/TP mais distantes (mais folga).");

   CreateLabel("lblTrailMove", x + 290, y + 160, "Trail Move", COR_LABEL, 9);
   CreateEdit("editTrailMove", x + 290, y + 178, 70, 24, IntegerToString(TrailMove_Pontos));
   SetTooltip("lblTrailMove", "Passo do trailing em degraus (pts) nos modos não-ATR (TS/TT).");
   SetTooltip("editTrailMove", "Passo do trailing em degraus (pts) nos modos não-ATR (TS/TT).");

   CreateLabel("lblBEOffset", x + 290, y + 206, "BE Offset", COR_LABEL, 9);
   CreateEdit("editBEOffset", x + 290, y + 224, 70, 24, IntegerToString(BreakEvenOffset_Pontos));
   SetTooltip("lblBEOffset", "Offset do Break-Even em pts. 0 = SL no preço de entrada; >0 trava lucro no BE.");
   SetTooltip("editBEOffset", "Offset do Break-Even em pts. 0 = SL no preço de entrada; >0 trava lucro no BE.");

   CreateButton("btnBuy", x + 20, y + 250, 160, 40, "COMPRAR", COR_BUY, true);
   SetTooltip("btnBuy", "Abre COMPRA com SL/TP fixos");
   CreateButton("btnSell", x + 200, y + 250, 160, 40, "VENDER", COR_SELL, true);
   SetTooltip("btnSell", "Abre VENDA com SL/TP fixos");

   CreateButton("btnBuyATR", x + 20, y + 300, 160, 32, "TRAIL ATR BUY", COR_BUY, true);
   SetTooltip("btnBuyATR", "COMPRA com trailing ATR");
   CreateButton("btnSellATR", x + 200, y + 300, 160, 32, "TRAIL ATR SELL", COR_SELL, true);
   SetTooltip("btnSellATR", "VENDA com trailing ATR");

   CreateButton("btnCloseBuys", x + 20, y + 340, 160, 32, "FECHAR BUY", COR_BUY, true);
   SetTooltip("btnCloseBuys", "Fecha posições BUY apenas deste símbolo (gráfico atual).");
   CreateButton("btnCloseSells", x + 200, y + 340, 160, 32, "FECHAR SELL", COR_SELL, true);
   SetTooltip("btnCloseSells", "Fecha posições SELL apenas deste símbolo (gráfico atual).");
   CreateButton("btnCloseAll", x + 20, y + 380, 340, 32, "FECHAR TODAS", COR_NEUTRO, true);
   SetTooltip("btnCloseAll", "Fecha todas as posições deste símbolo no gráfico atual (não mexe em outros ativos).");

   CreateLabel("lblInfoTitulo", x + 20, y + 418, "INFO", COR_TEXTO, 11);
   SetTooltip("lblInfoTitulo", "Indicadores e progresso da meta do dia.");

   ObjectDelete(0, "lblLucro");
   ObjectDelete(0, "lblTrades");
   ObjectDelete(0, "lblSepMeta");
   ObjectDelete(0, "lblPosBS");
   ObjectDelete(0, "lblSaldo");
   ObjectDelete(0, "lblSepStatus");
   ObjectDelete(0, "lblInfo4");

   int colL = x + 20;
   int colV = x + 175;

   int ySprATR = y + 450;
   int yPnL = y + 464;
   int yOpen = y + 478;
   int ySep1 = y + 488;
   int ySaldo = y + 494;
   int yMeta = y + 508;
   int yBar = y + 516;
   int yGestao = y + 528;

   metaBarX = colL;
   metaBarY = yBar;
   metaBarW = 340;
   metaBarH = 6;

   CreateLabel("lblSepOpenMeta", colL, ySep1, "────────────────", COR_NEUTRO, 8);

   CreateLabel("lblK_SprATR", colL, ySprATR, "Spread", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_SprATR", colV, ySprATR, "--", COR_TEXTO, 8);
   SetTooltip("lblV_SprATR", "Spread em pts e ATR do período configurado.");

   CreateLabel("lblK_PnL", colL, yPnL, "PnL", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_PnL", colV, yPnL, "$0.00 | tot $0.00", COR_TEXTO, 8);
   SetTooltip("lblV_PnL", "PnL flutuante deste símbolo e total da conta.");

   CreateLabel("lblK_Open", colL, yOpen, "Open", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Open", colV, yOpen, "▲0  ▼0", COR_TEXTO, 8);
   SetTooltip("lblV_Open", "Quantidade de posições BUY e SELL abertas neste símbolo.");

   CreateLabel("lblK_Saldo", colL, ySaldo, "Saldo", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Saldo", colV, ySaldo, "$0.00", COR_TEXTO, 8);
   SetTooltip("lblV_Saldo", "Saldo (Account Balance).");

   CreateLabel("lblK_Meta", colL, yMeta, "Meta 3%", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Meta", colV, yMeta, "$0 | falta $0", COR_TEXTO, 8);
   SetTooltip("lblV_Meta", "Meta do dia (3%) e quanto falta para bater.");

   CreateRectangle("barMetaBG", metaBarX, metaBarY, metaBarW, metaBarH, COR_CARD);
   CreateRectangle("barMetaFill", metaBarX, metaBarY, 0, metaBarH, COR_BUY_SOFT);

   CreateLabel("lblK_Gestao", colL, yGestao, "Gestão", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Gestao", colV, yGestao, "—", COR_LABEL, 8);
   SetTooltip("lblV_Gestao", "Estado atual da gestão (ATR/BE/STEP).");
  }

//+------------------------------------------------------------------+
void Panel_OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_DRAG && (sparam == "painel" || sparam == "painelBorder" || sparam == "dragHandle"))
     {
      int newX = 0;
      int newY = 0;
      bool draggingHandle = (sparam == "dragHandle");
      if(sparam == "painelBorder")
        {
         newX = (int)ObjectGetInteger(0, "painelBorder", OBJPROP_XDISTANCE) + PANEL_BORDER_PAD;
         newY = (int)ObjectGetInteger(0, "painelBorder", OBJPROP_YDISTANCE) + PANEL_BORDER_PAD;
         ObjectSetInteger(0, "painel", OBJPROP_XDISTANCE, newX);
         ObjectSetInteger(0, "painel", OBJPROP_YDISTANCE, newY);
        }
      else if(draggingHandle)
        {
         int hx = (int)ObjectGetInteger(0, "dragHandle", OBJPROP_XDISTANCE);
         int hy = (int)ObjectGetInteger(0, "dragHandle", OBJPROP_YDISTANCE);
         newX = hx - DRAG_X_OFF;
         newY = hy - DRAG_Y_OFF;
         ObjectSetInteger(0, "painel", OBJPROP_XDISTANCE, newX);
         ObjectSetInteger(0, "painel", OBJPROP_YDISTANCE, newY);
         ObjectSetInteger(0, "painelBorder", OBJPROP_XDISTANCE, newX - PANEL_BORDER_PAD);
         ObjectSetInteger(0, "painelBorder", OBJPROP_YDISTANCE, newY - PANEL_BORDER_PAD);
        }
      else
        {
         newX = (int)ObjectGetInteger(0, "painel", OBJPROP_XDISTANCE);
         newY = (int)ObjectGetInteger(0, "painel", OBJPROP_YDISTANCE);
         ObjectSetInteger(0, "painelBorder", OBJPROP_XDISTANCE, newX - PANEL_BORDER_PAD);
         ObjectSetInteger(0, "painelBorder", OBJPROP_YDISTANCE, newY - PANEL_BORDER_PAD);
        }

      int dx = newX - lastPanelX;
      int dy = newY - lastPanelY;

      for(int i = 0; i < ArraySize(objetos); i++)
        {
         string nome = objetos[i];
         if(ObjectFind(0, nome) >= 0 && nome != "painel" && nome != "painelBorder" && !(draggingHandle && nome == "dragHandle"))
           {
            int ox = (int)ObjectGetInteger(0, nome, OBJPROP_XDISTANCE);
            int oy = (int)ObjectGetInteger(0, nome, OBJPROP_YDISTANCE);

            ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, ox + dx);
            ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, oy + dy);
           }
        }

      lastPanelX = newX;
      lastPanelY = newY;
     }

   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == "btnBuy") AbrirOrdem(true, MODE_NORMAL);
      if(sparam == "btnSell") AbrirOrdem(false, MODE_NORMAL);

      if(sparam == "btnBuyATR") AbrirOrdem(true, MODE_ATR);
      if(sparam == "btnSellATR") AbrirOrdem(false, MODE_ATR);

      if(sparam == "btnLogs")
        {
         EnableLogs = !EnableLogs;
         ObjectSetString(0, "btnLogs", OBJPROP_TEXT, LogsButtonText());
         ObjectSetInteger(0, "btnLogs", OBJPROP_BGCOLOR, LogsButtonColor());
        }

      if(sparam == "btnCloseAll") FecharTodas();
      if(sparam == "btnCloseBuys") FecharTipo(POSITION_TYPE_BUY);
      if(sparam == "btnCloseSells") FecharTipo(POSITION_TYPE_SELL);

      if(sparam == "btnLot03")
        {
         Lotes = 0.03;
         UpdateEdit("editLote", Lotes);
        }
      if(sparam == "btnLot06")
        {
         Lotes = 0.06;
         UpdateEdit("editLote", Lotes);
        }
      if(sparam == "btnLot09")
        {
         Lotes = 0.09;
         UpdateEdit("editLote", Lotes);
        }

      if(sparam == "btnLotPlus")
        {
         Lotes += 0.01;
         UpdateEdit("editLote", Lotes);
        }
      if(sparam == "btnLotMinus")
        {
         Lotes = MathMax(0.01, Lotes - 0.01);
         UpdateEdit("editLote", Lotes);
        }

      if(sparam == "btnPresetScalp") ApplyPreset(0);
      if(sparam == "btnPresetNormal") ApplyPreset(1);
      if(sparam == "btnPresetSwing") ApplyPreset(2);
     }

   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      if(sparam == "editLote") Lotes = StringToDouble(ObjectGetString(0, "editLote", OBJPROP_TEXT));
      if(sparam == "editTP") TP_Pontos = (int)StringToInteger(ObjectGetString(0, "editTP", OBJPROP_TEXT));
      if(sparam == "editSL") SL_Pontos = (int)StringToInteger(ObjectGetString(0, "editSL", OBJPROP_TEXT));
      if(sparam == "editTrailStep") TrailStep_Pontos = (int)StringToInteger(ObjectGetString(0, "editTrailStep", OBJPROP_TEXT));

      if(sparam == "editATRPeriod")
        {
         int p = (int)StringToInteger(ObjectGetString(0, "editATRPeriod", OBJPROP_TEXT));
         if(p < 1) p = 1;
         if(p != ATR_Period)
           {
            ATR_Period = p;
            if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
            atrHandle = iATR(_Symbol, _Period, ATR_Period);
           }
        }
      if(sparam == "editATRMul")
        {
         double m = StringToDouble(ObjectGetString(0, "editATRMul", OBJPROP_TEXT));
         if(m <= 0.0) m = 0.1;
         ATR_Mult = m;
        }
      if(sparam == "editTrailMove")
        {
         int t = (int)StringToInteger(ObjectGetString(0, "editTrailMove", OBJPROP_TEXT));
         if(t < 1) t = 1;
         TrailMove_Pontos = t;
        }
      if(sparam == "editBEOffset")
        {
         int be = (int)StringToInteger(ObjectGetString(0, "editBEOffset", OBJPROP_TEXT));
         if(be < 0) be = 0;
         BreakEvenOffset_Pontos = be;
        }
     }
  }

#endif // PANEL_UI_MQH
