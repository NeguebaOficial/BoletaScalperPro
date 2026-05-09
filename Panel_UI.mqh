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
// Bloco de parâmetros (grelha 3×3)
color COR_PARAM_SURFACE = (color)0x272C33;
color COR_PARAM_EDGE = (color)0x2D3641;
color COR_PARAM_INPUT_BG = (color)0x1E232A;
color COR_PARAM_INPUT_BORDER = (color)0x3E4A5A;
color COR_PARAM_TITLE = (color)0xA7BBC9;
color COR_SECTION_SURFACE = (color)0x252C34;
color COR_SECTION_EDGE = (color)0x2B3541;

#define BTN_FONT_REGULAR "Segoe UI"
#define BTN_FONT_BOLD "Arial Bold"

string objetos[69] = {
   "painelBorder", "painel", "lblTitulo", "lblLote", "editLote", "btnLot03", "btnLot06", "btnLot09",
   "btnLotPlus", "btnLotMinus",
   "headBlockBg",
   "paramBlockBg", "lblParamSecTitle",
   "lblTP", "editTP", "lblSL", "editSL",
   "lblTrailStep", "editTrailStep",
   "btnPresetScalp", "btnPresetNormal", "btnPresetSwing",
   "tradeBlockBg", "lblTradeModes",
   "btnBuy", "btnSell",
   "btnBuyATR", "btnSellATR",
   "btnBuyTrailTs", "btnSellTrailTs", "btnBuyTrailTt", "btnSellTrailTt",
   "lblATRPeriod", "editATRPeriod", "lblATRMul", "editATRMul",
   "lblTrailMove", "editTrailMove", "lblBEOffset", "editBEOffset",
   "lblRatchetEvery", "editRatchetEvery", "lblRatchetLock", "editRatchetLock",
   "closeBlockBg", "lblCloseModes",
   "paramSepLine",
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

//+------------------------------------------------------------------+
//| Validação numérica dos campos editáveis                          |
//+------------------------------------------------------------------+
bool TryParseInt(const string text, int &outValue)
  {
   string s = text;
   StringTrimLeft(s);
   StringTrimRight(s);
   int n = StringLen(s);
   if(n == 0) return false;
   for(int i = 0; i < n; i++)
     {
      ushort c = StringGetCharacter(s, i);
      if(c < '0' || c > '9') return false;
     }
   outValue = (int)StringToInteger(s);
   return true;
  }

bool TryParseDouble(const string text, double &outValue)
  {
   string s = text;
   StringTrimLeft(s);
   StringTrimRight(s);
   StringReplace(s, ",", ".");
   int n = StringLen(s);
   if(n == 0) return false;
   int dots = 0, digits = 0;
   for(int i = 0; i < n; i++)
     {
      ushort c = StringGetCharacter(s, i);
      if(c >= '0' && c <= '9')
         digits++;
      else if(c == '.')
        {
         dots++;
         if(dots > 1) return false;
        }
      else
         return false;
     }
   if(digits == 0) return false;
   outValue = StringToDouble(s);
   return true;
  }

//+------------------------------------------------------------------+
//| Lê o texto do edit, valida, atualiza estado e refresca o display |
//| Garante que o valor digitado seja "commitado" mesmo sem Enter.   |
//+------------------------------------------------------------------+
void ApplyEditValue(const string name)
  {
   if(ObjectFind(0, name) < 0) return;
   string text = ObjectGetString(0, name, OBJPROP_TEXT);

   if(name == "editLote")
     {
      double v;
      if(TryParseDouble(text, v))
        {
         if(v < 0.01) v = 0.01;
         Lotes = v;
        }
      UpdateEdit("editLote", Lotes);
      return;
     }
   if(name == "editTP")
     {
      int v;
      if(TryParseInt(text, v))
        {
         if(v < 0) v = 0;
         TP_Pontos = v;
        }
      UpdateEditInt("editTP", TP_Pontos);
      return;
     }
   if(name == "editSL")
     {
      int v;
      if(TryParseInt(text, v))
        {
         if(v < 0) v = 0;
         SL_Pontos = v;
        }
      UpdateEditInt("editSL", SL_Pontos);
      return;
     }
   if(name == "editTrailStep")
     {
      int v;
      if(TryParseInt(text, v))
        {
         if(v < 0) v = 0;
         TrailStep_Pontos = v;
        }
      UpdateEditInt("editTrailStep", TrailStep_Pontos);
      return;
     }
   if(name == "editATRPeriod")
     {
      int p;
      if(TryParseInt(text, p))
        {
         if(p < 1) p = 1;
         if(p != ATR_Period)
           {
            ATR_Period = p;
            if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
            atrHandle = iATR(_Symbol, _Period, ATR_Period);
           }
        }
      UpdateEditInt("editATRPeriod", ATR_Period);
      return;
     }
   if(name == "editATRMul")
     {
      double m;
      if(TryParseDouble(text, m))
        {
         if(m < 0.10) m = 0.10;
         ATR_Mult = m;
        }
      ObjectSetString(0, "editATRMul", OBJPROP_TEXT, DoubleToString(ATR_Mult, 2));
      return;
     }
   if(name == "editTrailMove")
     {
      int t;
      if(TryParseInt(text, t))
        {
         if(t < 1) t = 1;
         TrailMove_Pontos = t;
        }
      UpdateEditInt("editTrailMove", TrailMove_Pontos);
      return;
     }
   if(name == "editBEOffset")
     {
      int be;
      if(TryParseInt(text, be))
        {
         if(be < 0) be = 0;
         BreakEvenOffset_Pontos = be;
        }
      UpdateEditInt("editBEOffset", BreakEvenOffset_Pontos);
      return;
     }
   if(name == "editRatchetEvery")
     {
      int re;
      if(TryParseInt(text, re))
        {
         if(re < 0) re = 0;
         RatchetProfitEvery_Pontos = re;
        }
      UpdateEditInt("editRatchetEvery", RatchetProfitEvery_Pontos);
      return;
     }
   if(name == "editRatchetLock")
     {
      int rl;
      if(TryParseInt(text, rl))
        {
         if(rl < 0) rl = 0;
         RatchetLockPts_Pontos = rl;
        }
      UpdateEditInt("editRatchetLock", RatchetLockPts_Pontos);
      return;
     }
  }

void CommitAllEditFields()
  {
   ApplyEditValue("editLote");
   ApplyEditValue("editTP");
   ApplyEditValue("editSL");
   ApplyEditValue("editTrailStep");
   ApplyEditValue("editATRPeriod");
   ApplyEditValue("editATRMul");
   ApplyEditValue("editTrailMove");
   ApplyEditValue("editBEOffset");
   ApplyEditValue("editRatchetEvery");
   ApplyEditValue("editRatchetLock");
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
   if(ObjectFind(0, "editRatchetEvery") >= 0) UpdateEditInt("editRatchetEvery", RatchetProfitEvery_Pontos);
   if(ObjectFind(0, "editRatchetLock") >= 0) UpdateEditInt("editRatchetLock", RatchetLockPts_Pontos);
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
                   StringFormat("$%.2f  |  falta $%.2f", metaValor, faltaMeta));
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

void CreateEditParam(string name, int x, int y, int w, int h, string text)
  {
   CreateEdit(name, x, y, w, h, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, COR_PARAM_INPUT_BG);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, COR_PARAM_INPUT_BORDER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
  }

void CreateParamSurface(string name, int x, int y, int w, int h)
  {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, COR_PARAM_SURFACE);
   ObjectSetInteger(0, name, OBJPROP_COLOR, COR_PARAM_EDGE);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
  }

void CreateSectionSurface(string name, int x, int y, int w, int h)
  {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, COR_SECTION_SURFACE);
   ObjectSetInteger(0, name, OBJPROP_COLOR, COR_SECTION_EDGE);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
  }

void CreateLabel(string name, int x, int y, string text, color cor, int size, bool boldFont = false)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   string fontName = "Segoe UI Semilight";
   if(boldFont)
      fontName = BTN_FONT_BOLD;
   else if(cor == COR_BUY || cor == COR_SELL || cor == COR_BUY_SOFT || cor == COR_SELL_SOFT || cor == COR_LABEL || cor == COR_TEXTO || cor == COR_WARN || cor == COR_PARAM_TITLE)
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

   CreateSectionSurface("headBlockBg", x + 14, y + 32, PANEL_W - 28, 58);
   SetTooltip("headBlockBg", "Configuração de lote e presets rápidos.");

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

   const int PARAM_BLK_X = 14;
   const int PARAM_BLK_Y = 92;
   const int PARAM_BLK_W = PANEL_W - 28;
   const int PARAM_BLK_H = 162;
   const int PR_L1 = 110;
   const int PR_E1 = 127;
   const int PR_L2 = 158;
   const int PR_E2 = 175;
   const int PR_L3 = 206;
   const int PR_E3 = 223;
   const int PR_EDH = 28;

   CreateParamSurface("paramBlockBg", x + PARAM_BLK_X, y + PARAM_BLK_Y, PARAM_BLK_W, PARAM_BLK_H);
   SetTooltip("paramBlockBg", "Parâmetros de risco e gestão em pontos (XAUUSD).");

   CreateLabel("lblParamSecTitle", x + 22, y + 98, "Alvos · gatilho · trailing · escada", COR_TEXTO_MUTE, 8, false);
   SetTooltip("lblParamSecTitle", "Grelha de pontos: TP/SL, gatilho, ATR, trail, escada STEP e BE.");

   CreateLabel("lblTP", x + 20, y + PR_L1, "Take Profit", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editTP", x + 20, y + PR_E1, 70, PR_EDH, IntegerToString(TP_Pontos));
   SetTooltip("lblTP", "TP inicial em pontos (pts). Digits=2: 100 pts = $1.00 no XAUUSD.");
   SetTooltip("editTP", "TP inicial em pontos (pts). Digits=2: 100 pts = $1.00 no XAUUSD.");

   CreateLabel("lblSL", x + 170, y + PR_L1, "Stop Loss", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editSL", x + 170, y + PR_E1, 70, PR_EDH, IntegerToString(SL_Pontos));
   SetTooltip("lblSL", "SL inicial em pontos (pts). Deve ser maior que o spread e respeitar o stop level.");
   SetTooltip("editSL", "SL inicial em pontos (pts). Deve ser maior que o spread e respeitar o stop level.");

   CreateLabel("lblTrailStep", x + 290, y + PR_L1, "Gatilho", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editTrailStep", x + 290, y + PR_E1, 70, PR_EDH, IntegerToString(TrailStep_Pontos));
   SetTooltip("lblTrailStep", "Gatilho (lucro em pts) para BE/ATR e para STEP TS/TT. Antes disso não move SL/TP.");
   SetTooltip("editTrailStep", "Gatilho (lucro em pts) para BE/ATR e para STEP TS/TT. Antes disso não move SL/TP.");

   CreateLabel("lblATRPeriod", x + 20, y + PR_L2, "Periodo ATR", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editATRPeriod", x + 20, y + PR_E2, 70, PR_EDH, IntegerToString(ATR_Period));
   SetTooltip("lblATRPeriod", "Período do ATR usado no TRAIL ATR. Ex: 14. Quanto maior, mais 'lento' o trailing.");
   SetTooltip("editATRPeriod", "Período do ATR usado no TRAIL ATR. Ex: 14. Quanto maior, mais 'lento' o trailing.");

   CreateLabel("lblATRMul", x + 170, y + PR_L2, "ATR Mult", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editATRMul", x + 170, y + PR_E2, 70, PR_EDH, DoubleToString(ATR_Mult, 2));
   SetTooltip("lblATRMul", "Multiplicador do ATR no TRAIL ATR. Maior = SL/TP mais distantes (mais folga).");
   SetTooltip("editATRMul", "Multiplicador do ATR no TRAIL ATR. Maior = SL/TP mais distantes (mais folga).");

   CreateLabel("lblTrailMove", x + 290, y + PR_L2, "Trail Move", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editTrailMove", x + 290, y + PR_E2, 70, PR_EDH, IntegerToString(TrailMove_Pontos));
   SetTooltip("lblTrailMove", "Passo do SL após o BE (TS/TT). Complementa a escada Lucro/Trava, se ela estiver ativa.");
   SetTooltip("editTrailMove", "Passo do SL após o BE (TS/TT). Complementa a escada Lucro/Trava, se ela estiver ativa.");

   CreateLabel("lblRatchetEvery", x + 20, y + PR_L3, "Lucro/Degrau", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editRatchetEvery", x + 20, y + PR_E3, 70, PR_EDH, IntegerToString(RatchetProfitEvery_Pontos));
   SetTooltip("lblRatchetEvery", "STEP TS/TT: a cada X pts de lucro a favor (desde a entrada), sobe um degrau da escada. 0 = desliga escada.");
   SetTooltip("editRatchetEvery", "STEP TS/TT: a cada X pts de lucro a favor (desde a entrada), sobe um degrau. 0 = desliga.");

   CreateLabel("lblRatchetLock", x + 170, y + PR_L3, "Trava/Degrau", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editRatchetLock", x + 170, y + PR_E3, 70, PR_EDH, IntegerToString(RatchetLockPts_Pontos));
   SetTooltip("lblRatchetLock", "STEP TS/TT: cada degrau puxa o SL N pts a favor a partir da entrada (compra: acima; venda: abaixo).");
   SetTooltip("editRatchetLock", "STEP TS/TT: pts travados por degrau desde a entrada. Use com Lucro/degrau > 0.");

   CreateLabel("lblBEOffset", x + 290, y + PR_L3, "BE Offset", COR_PARAM_TITLE, 8, true);
   CreateEditParam("editBEOffset", x + 290, y + PR_E3, 70, PR_EDH, IntegerToString(BreakEvenOffset_Pontos));
   SetTooltip("lblBEOffset", "Offset do Break-Even em pts. 0 = SL no preço de entrada; >0 trava lucro no BE.");
   SetTooltip("editBEOffset", "Offset do Break-Even em pts. 0 = SL no preço de entrada; >0 trava lucro no BE.");

   CreateRectangle("paramSepLine", x + 18, y + 258, PANEL_W - 36, 2, COR_PARAM_EDGE);
   ObjectSetInteger(0, "paramSepLine", OBJPROP_BACK, false);
   ObjectSetInteger(0, "paramSepLine", OBJPROP_ZORDER, 4);
   ObjectSetInteger(0, "paramSepLine", OBJPROP_SELECTABLE, false);
   SetTooltip("paramSepLine", "Separa parâmetros das ações de ordem.");

   CreateSectionSurface("tradeBlockBg", x + 14, y + 260, PANEL_W - 28, 174);
   SetTooltip("tradeBlockBg", "Entradas por modo: normal, ATR e STEP.");
   CreateLabel("lblTradeModes", x + 22, y + 262, "Modos de entrada", COR_PARAM_TITLE, 8);
   SetTooltip("lblTradeModes", "Escolha entre ordem fixa, ATR ou STEP.");

   CreateButton("btnBuy", x + 20, y + 278, 160, 40, "COMPRAR", COR_BUY, true);
   SetTooltip("btnBuy", "Abre COMPRA com SL/TP fixos");
   CreateButton("btnSell", x + 200, y + 278, 160, 40, "VENDER", COR_SELL, true);
   SetTooltip("btnSell", "Abre VENDA com SL/TP fixos");

   CreateButton("btnBuyATR", x + 20, y + 328, 160, 32, "TRAIL ATR BUY", COR_BUY, true);
   SetTooltip("btnBuyATR", "COMPRA com trailing ATR");
   CreateButton("btnSellATR", x + 200, y + 328, 160, 32, "TRAIL ATR SELL", COR_SELL, true);
   SetTooltip("btnSellATR", "VENDA com trailing ATR");

   CreateButton("btnBuyTrailTs", x + 20, y + 364, 160, 30, "STEP TS BUY", COR_BUY, true);
   SetTooltip("btnBuyTrailTs", "COMPRA STEP TS: Start Lucro, Trail Move, BE Offset + escada Lucro/Trava (se ativa).");
   CreateButton("btnSellTrailTs", x + 200, y + 364, 160, 30, "STEP TS SELL", COR_SELL, true);
   SetTooltip("btnSellTrailTs", "VENDA STEP TS: Start Lucro, Trail Move, BE Offset + escada Lucro/Trava (se ativa).");

   CreateButton("btnBuyTrailTt", x + 20, y + 398, 160, 30, "STEP TT BUY", COR_BUY, true);
   SetTooltip("btnBuyTrailTt", "COMPRA STEP TT: mesma lógica do TS; magic TT + escada opcional.");
   CreateButton("btnSellTrailTt", x + 200, y + 398, 160, 30, "STEP TT SELL", COR_SELL, true);
   SetTooltip("btnSellTrailTt", "VENDA STEP TT: mesma lógica do TS; magic TT + escada opcional.");

   CreateSectionSurface("closeBlockBg", x + 14, y + 420, PANEL_W - 28, 94);
   SetTooltip("closeBlockBg", "Controles de saída e encerramento rápido.");
   CreateLabel("lblCloseModes", x + 22, y + 428, "Saída de posições", COR_PARAM_TITLE, 8);
   SetTooltip("lblCloseModes", "Fechamento parcial por lado ou total do símbolo.");

   CreateButton("btnCloseBuys", x + 20, y + 440, 160, 32, "FECHAR BUY", COR_BUY, true);
   SetTooltip("btnCloseBuys", "Fecha posições BUY apenas deste símbolo (gráfico atual).");
   CreateButton("btnCloseSells", x + 200, y + 440, 160, 32, "FECHAR SELL", COR_SELL, true);
   SetTooltip("btnCloseSells", "Fecha posições SELL apenas deste símbolo (gráfico atual).");
   CreateButton("btnCloseAll", x + 20, y + 480, 340, 32, "FECHAR TODAS", COR_NEUTRO, true);
   SetTooltip("btnCloseAll", "Fecha todas as posições deste símbolo no gráfico atual (não mexe em outros ativos).");

   CreateLabel("lblInfoTitulo", x + 20, y + 518, "INFO", COR_TEXTO, 11);
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

   int ySprATR = y + 550;
   int yPnL = y + 564;
   int yOpen = y + 578;
   int ySep1 = y + 588;
   int ySaldo = y + 594;
   int yMeta = y + 608;
   int yBar = y + 616;
   int yGestao = y + 628;

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

   CreateLabel("lblK_Meta", colL, yMeta, StringFormat("Meta %.0f%%", MetaD_Percent * 100.0), COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Meta", colV, yMeta, "$0.00 | falta $0.00", COR_TEXTO, 8);
   SetTooltip("lblV_Meta", "Meta do dia e quanto falta para bater.");

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
      CommitAllEditFields();

      if(sparam == "btnBuy") AbrirOrdem(true, MODE_NORMAL);
      if(sparam == "btnSell") AbrirOrdem(false, MODE_NORMAL);

      if(sparam == "btnBuyATR") AbrirOrdem(true, MODE_ATR);
      if(sparam == "btnSellATR") AbrirOrdem(false, MODE_ATR);

      if(sparam == "btnBuyTrailTs") AbrirOrdem(true, MODE_TRAIL_SL);
      if(sparam == "btnSellTrailTs") AbrirOrdem(false, MODE_TRAIL_SL);
      if(sparam == "btnBuyTrailTt") AbrirOrdem(true, MODE_TRAIL_TP);
      if(sparam == "btnSellTrailTt") AbrirOrdem(false, MODE_TRAIL_TP);

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
      ApplyEditValue(sparam);
     }
  }

#endif // PANEL_UI_MQH
