//+------------------------------------------------------------------+
//| Expert Advisor: Boleta Scalper PRO V4_melhorias (base V2 + eficiência / clareza / segurança)|
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;

// ================= CORES =================
color COR_BG     = (color)0x1E1E1E;
color COR_CARD   = (color)0x252526;
color COR_TEXTO  = clrWhite;
color COR_LABEL  = clrSilver;
color COR_BUY    = C'46,180,80';   // verde (botões de compra)
color COR_SELL   = C'230,60,60';   // vermelho (botões de venda)
// Cores "soft" para dashboard (mais leve e menos vibrante)
color COR_TEXTO_MUTE = (color)0xBDBDBD;
color COR_BUY_SOFT  = C'70,190,120';
color COR_SELL_SOFT = C'220,90,90';
color COR_WARN      = C'255,175,60';
color COR_NEUTRO = (color)0x3A3A3A;
color COR_AZUL   = (color)0x2979FF;

// Fontes dos botões (OBJ_BUTTON não usa OBJPROP_FONTSTYLE no MT5 — negrito via família "Bold")
#define BTN_FONT_REGULAR "Segoe UI"
#define BTN_FONT_BOLD    "Arial Bold"

// ================= VARIÁVEIS =================
double Lotes = 0.01;
int TP_Pontos = 800;          
int SL_Pontos = 900;          
int TrailStep_Pontos = 400;   
int BreakEvenOffset_Pontos = 0;   // deslocamento do BE (0 = preço de entrada)
int TrailMove_Pontos = 100;       // avanço do trailing após BE (em pontos)

// Presets (XAUUSD ~spread 40 pts) - preenche campos rapidamente
int PRESET_SCALP_TP = 9000;
int PRESET_SCALP_SL = 1200;
int PRESET_SCALP_START = 250;
int PRESET_SCALP_TRAILMOVE = 50;
int PRESET_SCALP_BEOFFSET = 50;
double PRESET_SCALP_ATRMUL = 1.50;

int PRESET_NORMAL_TP = 9000;
int PRESET_NORMAL_SL = 900;
int PRESET_NORMAL_START = 450;
int PRESET_NORMAL_TRAILMOVE = 100;
int PRESET_NORMAL_BEOFFSET = 80;
double PRESET_NORMAL_ATRMUL = 2.00;

int PRESET_SWING_TP = 9000;
int PRESET_SWING_SL = 2500;
int PRESET_SWING_START = 1000;
int PRESET_SWING_TRAILMOVE = 300;
int PRESET_SWING_BEOFFSET = 150;
double PRESET_SWING_ATRMUL = 2.50;

// Modos de execução (para separar botões)
int MODE_NORMAL   = 0;
int MODE_TRAIL_SL = 1;
int MODE_TRAIL_TP = 2;
int MODE_ATR      = 3;

// Magic numbers separados para identificar trades
long MAGIC_NORMAL   = 7700;
long MAGIC_TRAIL_SL = 7701;
long MAGIC_TRAIL_TP = 7702;
long MAGIC_ATR_TRAIL = 7703;

// Parâmetros ATR
int    ATR_Period = 14;
double ATR_Mult   = 2.0;      
int    atrHandle  = INVALID_HANDLE;

// Logs (para não poluir o Journal no ao vivo)
bool EnableLogs = true;

// Meta diária (3% do saldo no início do dia)
double MetaD_Percent = 0.03;
datetime metaDay = 0;
double metaDayStartBalance = 0.0;

// Painel: reduz chamadas a ObjectSet* (ms entre atualizações; trailing segue em todo tick)
const ulong PANEL_REFRESH_MS = 250;

// ===== DRAG =====
int lastPanelX = 0;
int lastPanelY = 0;
const int PANEL_W = 380;
const int PANEL_H = 548;
const int PANEL_BORDER_PAD = 2;
const int DRAG_X_OFF = 225;
const int DRAG_Y_OFF = 8;
const int DRAG_W = 70;
const int DRAG_H = 22;

// Barra de progresso da meta (pixels no gráfico)
int metaBarX = 0;
int metaBarY = 0;
int metaBarW = 0;
int metaBarH = 6;

string objetos[53] = {
   "painelBorder","painel","lblTitulo","lblLote","editLote","btnLot03","btnLot06","btnLot09",
   "btnLotPlus","btnLotMinus","lblTP","editTP","lblSL","editSL",
   "lblTrailStep","editTrailStep",
   "btnPresetScalp","btnPresetNormal","btnPresetSwing",
   "btnBuy","btnSell",
   "btnBuyATR","btnSellATR",
   "lblATRPeriod","editATRPeriod","lblATRMul","editATRMul",
   "lblTrailMove","editTrailMove","lblBEOffset","editBEOffset",
   "btnLogs",
   "btnCloseAll","btnCloseBuys","btnCloseSells",
   "lblInfoTitulo",
   "lblK_SprATR","lblV_SprATR",
   "lblK_PnL","lblV_PnL",
   "lblK_Open","lblV_Open",
   "lblK_Saldo","lblV_Saldo",
   "lblK_Meta","lblV_Meta",
   "lblSepOpenMeta",
   "barMetaBG","barMetaFill",
   "lblK_Gestao","lblV_Gestao","lblMover",
   "dragHandle"
};

void UpdateEditInt(const string name,const int value)
{
   ObjectSetString(0,name,OBJPROP_TEXT,IntegerToString(value));
}

void ApplyPreset(const int presetId)
{
   // 0=scalp, 1=normal, 2=swing
   if(presetId == 0)
   {
      TP_Pontos = PRESET_SCALP_TP;
      SL_Pontos = PRESET_SCALP_SL;
      TrailStep_Pontos = PRESET_SCALP_START;
      TrailMove_Pontos = PRESET_SCALP_TRAILMOVE;
      BreakEvenOffset_Pontos = PRESET_SCALP_BEOFFSET;
      ATR_Mult = PRESET_SCALP_ATRMUL;
   }
   else if(presetId == 2)
   {
      TP_Pontos = PRESET_SWING_TP;
      SL_Pontos = PRESET_SWING_SL;
      TrailStep_Pontos = PRESET_SWING_START;
      TrailMove_Pontos = PRESET_SWING_TRAILMOVE;
      BreakEvenOffset_Pontos = PRESET_SWING_BEOFFSET;
      ATR_Mult = PRESET_SWING_ATRMUL;
   }
   else // normal
   {
      TP_Pontos = PRESET_NORMAL_TP;
      SL_Pontos = PRESET_NORMAL_SL;
      TrailStep_Pontos = PRESET_NORMAL_START;
      TrailMove_Pontos = PRESET_NORMAL_TRAILMOVE;
      BreakEvenOffset_Pontos = PRESET_NORMAL_BEOFFSET;
      ATR_Mult = PRESET_NORMAL_ATRMUL;
   }

   // Rebate na UI
   if(ObjectFind(0,"editTP")>=0) UpdateEditInt("editTP", TP_Pontos);
   if(ObjectFind(0,"editSL")>=0) UpdateEditInt("editSL", SL_Pontos);
   if(ObjectFind(0,"editTrailStep")>=0) UpdateEditInt("editTrailStep", TrailStep_Pontos);
   if(ObjectFind(0,"editTrailMove")>=0) UpdateEditInt("editTrailMove", TrailMove_Pontos);
   if(ObjectFind(0,"editBEOffset")>=0) UpdateEditInt("editBEOffset", BreakEvenOffset_Pontos);
   if(ObjectFind(0,"editATRMul")>=0) ObjectSetString(0,"editATRMul",OBJPROP_TEXT,DoubleToString(ATR_Mult,2));
}

void Log(const string msg)
{
   if(EnableLogs) Print(msg);
}

string LogsButtonText()
{
   return EnableLogs ? "LOG: ON" : "LOG: OFF";
}

color LogsButtonColor()
{
   return EnableLogs ? COR_AZUL : COR_NEUTRO;
}

int ContarAbertas(){ return PositionsTotal(); }
double GetSaldo(){ return AccountInfoDouble(ACCOUNT_BALANCE); }

// Point do símbolo (evita misturar com outro _Point se o contexto mudar)
double SymbolPointSafe(const string symbol)
{
   double p = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(p <= 0.0) p = _Point;
   return p;
}

//+------------------------------------------------------------------+
double MinStopsDistancePrice(const string symbol)
{
   int stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double pt = SymbolPointSafe(symbol);
   return (stopsLevel + 2) * pt;
}

double FreezeDistancePrice(const string symbol)
{
   int freezeLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double pt = SymbolPointSafe(symbol);
   return (freezeLevel + 2) * pt;
}

bool ValidateOpenSLTP(const string symbol,const bool isBuy,const double price,double &sl,double &tp)
{
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);

   double minDist = MinStopsDistancePrice(symbol);
   if(minDist <= 0.0) minDist = 0.0;

   // Garante que SL/TP não fiquem "colados" no preço atual (evita retcodes por stops level)
   if(isBuy)
   {
      double ref = (ask > 0.0 ? ask : price);
      if(sl > 0.0 && (ref - sl) < minDist) sl = ref - minDist;
      if(tp > 0.0 && (tp - ref) < minDist) tp = ref + minDist;
      if(sl > 0.0 && sl >= ref) sl = ref - minDist;
      if(tp > 0.0 && tp <= ref) tp = ref + minDist;
   }
   else
   {
      double ref = (bid > 0.0 ? bid : price);
      if(sl > 0.0 && (sl - ref) < minDist) sl = ref + minDist;
      if(tp > 0.0 && (ref - tp) < minDist) tp = ref - minDist;
      if(sl > 0.0 && sl <= ref) sl = ref + minDist;
      if(tp > 0.0 && tp >= ref) tp = ref - minDist;
   }

   // Checagem final simples
   if(isBuy && sl > 0.0 && sl >= ask) return false;
   if(isBuy && tp > 0.0 && tp <= ask) return false;
   if(!isBuy && sl > 0.0 && sl <= bid) return false;
   if(!isBuy && tp > 0.0 && tp >= bid) return false;

   return true;
}

double GetAtrValue()
{
   if(atrHandle == INVALID_HANDLE) return 0.0;
   double atrArr[1];
   if(CopyBuffer(atrHandle, 0, 0, 1, atrArr) <= 0) return 0.0;
   return atrArr[0];
}

datetime DayKey(datetime t)
{
   MqlDateTime s;
   TimeToStruct(t, s);
   s.hour = 0; s.min = 0; s.sec = 0;
   return StructToTime(s);
}

string BuildManagementStatus(const long magic,const string tag,const int posType,const double openPrice,const double curSL,
                             const double bid,const double ask,const int stepPts,const double symPoint)
{
   // status simples e didático (symPoint alinhado a GerenciarTrailing / símbolo do gráfico)
   if(magic == MAGIC_ATR_TRAIL && tag == "AT")
   {
      double triggerDistPrice = MathMax(stepPts * symPoint, TrailStep_Pontos * symPoint);
      bool triggered = false;
      if(posType == POSITION_TYPE_BUY)  triggered = (bid - openPrice) >= triggerDistPrice;
      if(posType == POSITION_TYPE_SELL) triggered = (openPrice - ask) >= triggerDistPrice;
      if(!triggered) return "ATR wait";

      double beOffset = BreakEvenOffset_Pontos * symPoint;
      double bePrice  = (posType == POSITION_TYPE_BUY) ? (openPrice + beOffset) : (openPrice - beOffset);
      if(posType == POSITION_TYPE_BUY)
      {
         if(curSL + symPoint < bePrice) return "ATR BE";
      }
      else
      {
         if(curSL - symPoint > bePrice || curSL == 0.0) return "ATR BE";
      }
      return "ATR trail";
   }

   if((magic == MAGIC_TRAIL_SL && tag == "TS") || (magic == MAGIC_TRAIL_TP && tag == "TT"))
   {
      double triggerPrice = TrailStep_Pontos * symPoint;
      bool triggered = false;
      if(posType == POSITION_TYPE_BUY)  triggered = (bid - openPrice) >= triggerPrice;
      if(posType == POSITION_TYPE_SELL) triggered = (openPrice - ask) >= triggerPrice;
      return triggered ? "STEP on" : "STEP wait";
   }

   return "—";
}

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

   ObjectSetString(0,"lblV_SprATR",OBJPROP_TEXT,
      StringFormat("%.0f pts | ATR(%d) %s", spreadDisp, ATR_Period, atrTxt));
   ObjectSetInteger(0,"lblV_SprATR",OBJPROP_COLOR, COR_TEXTO);

   ObjectSetString(0,"lblV_PnL",OBJPROP_TEXT,
      StringFormat("flt $%.2f | tot $%.2f", pnlSymbol, pnlTotal));
   ObjectSetInteger(0,"lblV_PnL",OBJPROP_COLOR, pnlSymbol >= 0.0 ? COR_BUY_SOFT : COR_SELL_SOFT);

   ObjectSetString(0,"lblV_Open",OBJPROP_TEXT,
      StringFormat("▲ %d  ▼ %d", openBuy, openSell));
   ObjectSetInteger(0,"lblV_Open",OBJPROP_COLOR, COR_TEXTO);

   // Saldo acima da meta
   ObjectSetString(0,"lblV_Saldo",OBJPROP_TEXT,
      StringFormat("$%.2f", saldo));
   ObjectSetInteger(0,"lblV_Saldo",OBJPROP_COLOR, COR_TEXTO);

   ObjectSetString(0,"lblV_Meta",OBJPROP_TEXT,
      StringFormat("$%.0f  |  falta $%.0f", metaValor, faltaMeta));
   ObjectSetInteger(0,"lblV_Meta",OBJPROP_COLOR, COR_TEXTO);

   // Barra: progresso de meta do dia (pnlDia/metaValor), clamped 0..1
   double pnlDia = metaValor - faltaMeta;
   double prog = 0.0;
   if(metaValor > 0.0) prog = pnlDia / metaValor;
   if(prog < 0.0) prog = 0.0;
   if(prog > 1.0) prog = 1.0;

   int fillW = (int)MathRound(metaBarW * prog);
   if(fillW < 0) fillW = 0;
   if(fillW > metaBarW) fillW = metaBarW;

   ObjectSetInteger(0,"barMetaFill",OBJPROP_XSIZE, fillW);
   color barCor = metaBatida ? COR_BUY_SOFT : COR_NEUTRO;
   ObjectSetInteger(0,"barMetaFill",OBJPROP_BGCOLOR, barCor);

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

   ObjectSetString(0,"lblV_Gestao",OBJPROP_TEXT, g);
   ObjectSetInteger(0,"lblV_Gestao",OBJPROP_COLOR, corGest);
}

//+------------------------------------------------------------------+
void OnTick()
{
   string symbol = _Symbol;
   double pnlTotal  = 0.0;
   double pnlSymbol = 0.0;
   int posCount = 0;
   int openBuy = 0;
   int openSell = 0;
   ulong firstTicket = 0;

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(!PositionSelectByTicket(t)) continue;
      double pr = PositionGetDouble(POSITION_PROFIT);
      pnlTotal += pr;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      posCount++;
      pnlSymbol += pr;
      int ptype = (int)PositionGetInteger(POSITION_TYPE);
      if(ptype == POSITION_TYPE_BUY) openBuy++;
      else if(ptype == POSITION_TYPE_SELL) openSell++;
      if(firstTicket == 0) firstTicket = t;
   }

   double saldo = GetSaldo();

   datetime today = DayKey(TimeCurrent());
   if(metaDay != today || metaDayStartBalance <= 0.0)
   {
      metaDay = today;
      metaDayStartBalance = saldo;
   }
   double metaValor = metaDayStartBalance * MetaD_Percent;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnlDia = equity - metaDayStartBalance;
   double faltaMeta = MathMax(0.0, metaValor - pnlDia);
   bool metaBatida = (pnlDia >= metaValor);

   static ulong s_lastPanelMs = 0;
   ulong nowMs = GetTickCount();
   if(s_lastPanelMs == 0 || (nowMs - s_lastPanelMs) >= PANEL_REFRESH_MS)
   {
      s_lastPanelMs = nowMs;
      AtualizarPainelInformacao(symbol, pnlTotal, pnlSymbol, posCount, openBuy, openSell, firstTicket,
                                saldo, metaValor, faltaMeta, metaBatida);
   }

   GerenciarTrailing();
}

//+------------------------------------------------------------------+
void AbrirOrdem(bool isBuy,int modo)
{
   string symbol = _Symbol;
   double pt = SymbolPointSafe(symbol);

   double price = isBuy ? SymbolInfoDouble(symbol, SYMBOL_ASK)
                        : SymbolInfoDouble(symbol, SYMBOL_BID);

   double tp = 0.0;
   if(TP_Pontos > 0)
      tp = isBuy ? price + TP_Pontos * pt
                 : price - TP_Pontos * pt;

   double sl = isBuy ? price - SL_Pontos * pt
                     : price + SL_Pontos * pt;

   string comment = "";
   long magic = MAGIC_NORMAL;

   if(modo==MODE_TRAIL_SL)
   {
      magic = MAGIC_TRAIL_SL;
      comment = StringFormat("TS,%d,%d,%d", SL_Pontos, TP_Pontos, TrailStep_Pontos);
   }
   else if(modo==MODE_TRAIL_TP)
   {
      magic = MAGIC_TRAIL_TP;
      comment = StringFormat("TT,%d,%d,%d", SL_Pontos, TP_Pontos, TrailStep_Pontos);
   }
   else if(modo==MODE_ATR)
   {
      magic = MAGIC_ATR_TRAIL;
      comment = StringFormat("AT,%d,%d,%d", SL_Pontos, TP_Pontos, TrailStep_Pontos);
   }

   trade.SetExpertMagicNumber(magic);

   if(!ValidateOpenSLTP(symbol, isBuy, price, sl, tp))
   {
      Log(StringFormat("Abertura: SL/TP inválidos após validação. symbol=%s isBuy=%s",
                       symbol, (isBuy ? "true" : "false")));
      return;
   }

   bool ok = false;
   if(isBuy) ok = trade.Buy(Lotes, symbol, price, sl, tp, comment);
   else      ok = trade.Sell(Lotes, symbol, price, sl, tp, comment);

   if(!ok)
   {
      Log(StringFormat("Abertura falhou. retcode=%d desc=%s symbol=%s lots=%s sl=%s tp=%s",
                       (int)trade.ResultRetcode(),
                       trade.ResultRetcodeDescription(),
                       symbol,
                       DoubleToString(Lotes, 2),
                       DoubleToString(sl, _Digits),
                       DoubleToString(tp, _Digits)));
   }
}

//+------------------------------------------------------------------+
bool ParseTrailComment(const string c,string &tag,int &slPts,int &tpPts,int &stepPts)
{
   string parts[];
   ArrayResize(parts, 5); // CORREÇÃO 1: Pré-alocando para acalmar a análise estática do compilador
   
   ushort delim = ',';
   int n = StringSplit(c, delim, parts);
   if(n < 4) return false;

   tag = parts[0];
   slPts = (int)StringToInteger(parts[1]);
   tpPts = (int)StringToInteger(parts[2]);
   stepPts = (int)StringToInteger(parts[3]);

   return (slPts > 0 && stepPts > 0 && tpPts >= 0);
}

void GerenciarTrailing()
{
   string symbol = _Symbol;
   double pt = SymbolPointSafe(symbol);

   double minDist = MinStopsDistancePrice(symbol);
   double freezeDist = FreezeDistancePrice(symbol);
   double distGuard = MathMax(minDist, freezeDist);

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);

   double atrVal = 0.0;
   bool atrOk = false;
   if(atrHandle != INVALID_HANDLE)
   {
      double atrBuf[1];
      if(CopyBuffer(atrHandle, 0, 0, 1, atrBuf) > 0 && atrBuf[0] > 0.0)
      {
         atrVal = atrBuf[0];
         atrOk = true;
      }
   }

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;

      string posSymbol = PositionGetString(POSITION_SYMBOL);
      if(posSymbol != symbol) continue;

      long magic = PositionGetInteger(POSITION_MAGIC);
      if(magic != MAGIC_TRAIL_SL && magic != MAGIC_TRAIL_TP && magic != MAGIC_ATR_TRAIL)
         continue;

      string comment = PositionGetString(POSITION_COMMENT);
      string tag;
      int slPts = 0, tpPts = 0, stepPts = 0;
      if(!ParseTrailComment(comment, tag, slPts, tpPts, stepPts))
         continue;

      bool tagValida = (tag == "TS" || tag == "TT" || tag == "AT");
      if(!tagValida)
         continue;

      // Pegamos os dados da posição
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL    = PositionGetDouble(POSITION_SL);
      double curTP    = PositionGetDouble(POSITION_TP);
      int posType     = (int)PositionGetInteger(POSITION_TYPE);

      // ------------------------- ATR Trailing (SL e TP avançando com BE)
      if(magic == MAGIC_ATR_TRAIL)
      {
         // Esperado: AT,SLp,TPp,TRIGGERp
         if(tag != "AT") continue;

         if(!atrOk) continue;

         // gatilho: só ativa depois de lucro a favor >= stepPts (comentário) OU TrailStep_Pontos (UI), o que for maior
         double triggerDistPrice = MathMax(stepPts * pt, TrailStep_Pontos * pt);
         bool triggered = false;
         if(posType == POSITION_TYPE_BUY)  triggered = (bid - openPrice) >= triggerDistPrice;
         if(posType == POSITION_TYPE_SELL) triggered = (openPrice - ask) >= triggerDistPrice;
         if(!triggered) continue;

         // Preço de BreakEven com offset vindo da UI
         double beOffset = BreakEvenOffset_Pontos * pt;
         double bePriceBuy  = openPrice + beOffset;
         double bePriceSell = openPrice - beOffset;

         // Distância dinâmica (em preço)
         double dist = atrVal * ATR_Mult;
         if(dist <= 0.0) continue;

         // Níveis iniciais (para garantir "nunca recua" vs o estado inicial)
         double initialSL = (posType == POSITION_TYPE_BUY)
                              ? (openPrice - slPts * pt)
                              : (openPrice + slPts * pt);
         double initialTP = 0.0;
         if(tpPts > 0)
            initialTP = (posType == POSITION_TYPE_BUY)
                           ? (openPrice + tpPts * pt)
                           : (openPrice - tpPts * pt);

         // Se ainda não estamos em BE, primeiro passo é levar SL para o BE
         if(posType == POSITION_TYPE_BUY)
         {
            if(curSL + pt < bePriceBuy)
            {
               double desiredSL_BE = bePriceBuy;
               double desiredTP_BE = (curTP > 0.0) ? curTP : initialTP;

               // valida distância mínima
               if((bid - desiredSL_BE) >= distGuard && (desiredTP_BE - ask) >= distGuard)
               {
                  if(!trade.PositionModify(ticket, desiredSL_BE, desiredTP_BE))
                     Log(StringFormat("BE ATR (BUY) falhou. retcode=%d desc=%s ticket=%I64u",
                                      (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
               }

               continue; // nesta passada só fazemos o BE
            }
         }
         else // SELL
         {
            if(curSL - pt > bePriceSell || curSL == 0.0)
            {
               double desiredSL_BE = bePriceSell;
               double desiredTP_BE = (curTP > 0.0) ? curTP : initialTP;

               if((desiredSL_BE - ask) >= distGuard && (bid - desiredTP_BE) >= distGuard)
               {
                  if(!trade.PositionModify(ticket, desiredSL_BE, desiredTP_BE))
                     Log(StringFormat("BE ATR (SELL) falhou. retcode=%d desc=%s ticket=%I64u",
                                      (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
               }

               continue;
            }
         }

         // A partir daqui, já em BE: Candidatos pelo ATR (seguem a direção)
         double candSL = (posType == POSITION_TYPE_BUY)
                          ? (bid - dist)
                          : (ask + dist);
         double candTP = (posType == POSITION_TYPE_BUY)
                          ? (ask + dist)
                          : (bid - dist);

         // Nunca recua: SL/TP só melhoram em relação ao que já está no trade, ao inicial e ao BE.
         double desiredSL = candSL;
         double desiredTP = candTP;
         if(posType == POSITION_TYPE_BUY)
         {
            desiredSL = MathMax(curSL, desiredSL);
            desiredTP = MathMax(curTP, desiredTP);
            desiredSL = MathMax(desiredSL, initialSL);
            desiredSL = MathMax(desiredSL, bePriceBuy);  // nunca abaixo do BE
            if(tpPts > 0)
               desiredTP = MathMax(desiredTP, initialTP);
         }
         else
         {
            desiredSL = MathMin(curSL, desiredSL);
            desiredTP = MathMin(curTP, desiredTP);
            desiredSL = MathMin(desiredSL, initialSL);
            desiredSL = MathMin(desiredSL, bePriceSell); // nunca acima do BE (em SELL)
            if(tpPts > 0)
               desiredTP = MathMin(desiredTP, initialTP);
         }

         // Se não mudou de verdade, ignora
         if(MathAbs(desiredSL - curSL) < pt && MathAbs(desiredTP - curTP) < pt)
            continue;

         // Valida distância mínima antes de enviar
         bool shouldModify = false;
         if(posType == POSITION_TYPE_BUY)
         {
            if((bid - desiredSL) >= distGuard && (desiredTP - ask) >= distGuard)
               shouldModify = true;
         }
         else
         {
            if((desiredSL - ask) >= distGuard && (bid - desiredTP) >= distGuard)
               shouldModify = true;
         }

         if(!shouldModify) continue;

         if(!trade.PositionModify(ticket, desiredSL, desiredTP))
         {
            Log(StringFormat("ATR trailing falhou. retcode=%d desc=%s ticket=%I64u",
                             (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
         }

         continue; // ATR já tratado
      }

      // ------------------------- BreakEven + Trailing em degraus (não-ATR)
      // BreakEven: trigger pela UI; trailing step e offset configuráveis por variável.
      double triggerPrice = TrailStep_Pontos * pt;
      double stepMove     = TrailMove_Pontos * pt;
      double beOffset     = BreakEvenOffset_Pontos * pt;

      double newSL = 0;

      if(posType == POSITION_TYPE_BUY)
      {
         // 1. Verifica se atingiu o lucro mínimo para o primeiro BreakEven
         if(bid >= openPrice + triggerPrice)
         {
            double bePrice = openPrice + beOffset;

            // Se o SL ainda está abaixo do BE, move para o BE.
            if(curSL < bePrice) newSL = bePrice;
            else 
            {
               // 2. Lógica de trailing em degraus após o BE.
               if(bid > curSL + stepMove + minDist)
               {
                  newSL = curSL + stepMove;
               }
            }
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         // 1. Verifica BreakEven para Venda
         if(ask <= openPrice - triggerPrice)
         {
            double bePrice = openPrice - beOffset;

            if(curSL > bePrice || curSL == 0) newSL = bePrice;
            else 
            {
               // 2. Trailing em degraus após o BE.
               if(ask < curSL - stepMove - minDist)
               {
                  newSL = curSL - stepMove;
               }
            }
         }
      }

      // Se calculamos um novo SL e ele é diferente do atual, aplicamos a mudança
      if(newSL > 0 && MathAbs(newSL - curSL) > pt)
      {
         // valida stops/freeze
         if(posType == POSITION_TYPE_BUY)
         {
            if((bid - newSL) < distGuard) continue;
         }
         else
         {
            if((newSL - ask) < distGuard) continue;
         }

         if(!trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
            Log(StringFormat("Step trailing falhou. retcode=%d desc=%s ticket=%I64u",
                             (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
      }
   }
}

//+------------------------------------------------------------------+
int OnInit()
{
   int largura = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int x = largura - 400;
   int y = 10;

   lastPanelX = x;
   lastPanelY = y;

   // Borda (simulada) um pouco mais grossa (2px)
   CreateRectangle("painelBorder", x-PANEL_BORDER_PAD, y-PANEL_BORDER_PAD, PANEL_W+4, PANEL_H+4, COR_NEUTRO);
   // IMPORTANTE: BACK=false para não ficar atrás do gráfico
   ObjectSetInteger(0,"painelBorder",OBJPROP_BACK,false);
   ObjectSetInteger(0,"painelBorder",OBJPROP_ZORDER,0);
   ObjectSetInteger(0,"painelBorder",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"painelBorder",OBJPROP_SELECTED,false);

   // Painel principal
   CreateRectangle("painel", x, y, PANEL_W, PANEL_H, COR_BG);
   ObjectSetInteger(0,"painel",OBJPROP_BACK,false);
   ObjectSetInteger(0,"painel",OBJPROP_ZORDER,1);
   ObjectSetInteger(0,"painel",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"painel",OBJPROP_SELECTED,false);

   // Alça dedicada para arrastar (ao lado esquerdo do botão LOG)
   CreateRectangle("dragHandle", x + DRAG_X_OFF, y + DRAG_Y_OFF, DRAG_W, DRAG_H, clrGray);
   ObjectSetInteger(0,"dragHandle",OBJPROP_BACK,false);
   ObjectSetInteger(0,"dragHandle",OBJPROP_ZORDER,25);
   ObjectSetInteger(0,"dragHandle",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"dragHandle",OBJPROP_SELECTED,false);
   SetTooltip("dragHandle","Arraste aqui para mover o painel");

   atrHandle = iATR(_Symbol, _Period, ATR_Period);
   if(atrHandle == INVALID_HANDLE)
      Log("ATR: handle inválido. Verifique ATR_Period.");

   CreateLabel("lblTitulo", x+20, y+10, "Boleta Negueba Trader", COR_TEXTO, 11);
   
   // Toggle de logs (topo direito, não interfere no layout)
   CreateButton("btnLogs", x+300, y+8, 70, 22, LogsButtonText(), LogsButtonColor(), false);
   SetTooltip("btnLogs","Liga/desliga logs no Journal (erros e eventos da boleta).");
   
   CreateLabel("lblLote", x+20, y+40, "Lote", COR_LABEL, 9);
   CreateEdit("editLote", x+20, y+60, 80, 28, DoubleToString(Lotes,2));
   SetTooltip("lblLote","Volume da ordem (lotes). Ex: 0.01. Ajuste conforme seu risco.");
   SetTooltip("editLote","Volume da ordem (lotes). Ex: 0.01. Ajuste conforme seu risco.");

   // Presets (Scalp / Normal / Swing) - linha acima dos botões de lote
   CreateButton("btnPresetScalp",  x+110, y+34, 70, 20, "SCALP",  COR_NEUTRO, false);
   CreateButton("btnPresetNormal", x+185, y+34, 70, 20, "NORMAL", COR_NEUTRO, false);
   CreateButton("btnPresetSwing",  x+260, y+34, 70, 20, "SWING",  COR_NEUTRO, false);
   CreateLabel("lblMover", x + DRAG_X_OFF + (DRAG_W/2), y + DRAG_Y_OFF + (DRAG_H/2), "MOVER", COR_TEXTO, 8);
   ObjectSetInteger(0,"lblMover",OBJPROP_ANCHOR,ANCHOR_CENTER);
   SetTooltip("btnPresetScalp","Preset SCALP (XAUUSD): preenche TP/SL/Start/TrailMove/BE/ATR Mult.");
   SetTooltip("btnPresetNormal","Preset NORMAL (XAUUSD): preenche TP/SL/Start/TrailMove/BE/ATR Mult.");
   SetTooltip("btnPresetSwing","Preset SWING (XAUUSD): preenche TP/SL/Start/TrailMove/BE/ATR Mult.");
   SetTooltip("lblMover","Use a barra ao fundo para arrastar o painel.");

   CreateButton("btnLot03", x+110, y+60, 55, 28, "0.03", COR_AZUL, false);
   SetTooltip("btnLot03","Lote fixo: 0.03");
   CreateButton("btnLot06", x+170, y+60, 55, 28, "0.06", COR_AZUL, false);
   SetTooltip("btnLot06","Lote fixo: 0.06");
   CreateButton("btnLot09", x+230, y+60, 55, 28, "0.09", COR_AZUL, false);
   SetTooltip("btnLot09","Lote fixo: 0.09");

   CreateButton("btnLotPlus", x+295, y+60, 30, 28, "+", COR_BUY, true);
   SetTooltip("btnLotPlus","Aumenta o lote em +0.01 (mín. 0.01)");
   CreateButton("btnLotMinus", x+330, y+60, 30, 28, "-", COR_SELL, true);
   SetTooltip("btnLotMinus","Diminui o lote em -0.01 (mín. 0.01)");

   CreateLabel("lblTP", x+20, y+100, "Take Profit", COR_LABEL, 9);
   CreateEdit("editTP", x+20, y+120, 130, 28, IntegerToString(TP_Pontos));
   SetTooltip("lblTP","TP inicial em pontos (pts). Digits=2: 100 pts = $1.00 no XAUUSD.");
   SetTooltip("editTP","TP inicial em pontos (pts). Digits=2: 100 pts = $1.00 no XAUUSD.");

   CreateLabel("lblSL", x+170, y+100, "Stop Loss", COR_LABEL, 9);
   CreateEdit("editSL", x+170, y+120, 130, 28, IntegerToString(SL_Pontos));
   SetTooltip("lblSL","SL inicial em pontos (pts). Deve ser maior que o spread e respeitar o stop level.");
   SetTooltip("editSL","SL inicial em pontos (pts). Deve ser maior que o spread e respeitar o stop level.");

   CreateLabel("lblTrailStep", x+290, y+100, "Start Lucro pts", COR_LABEL, 9);
   CreateEdit("editTrailStep", x+290, y+120, 70, 28, IntegerToString(TrailStep_Pontos));
   SetTooltip("lblTrailStep","Gatilho (lucro em pts) para ativar a gestão (BE/ATR). Antes disso não move SL/TP.");
   SetTooltip("editTrailStep","Gatilho (lucro em pts) para ativar a gestão (BE/ATR). Antes disso não move SL/TP.");

   // Linha de parâmetros abaixo da linha TP/SL/Start, em 3 colunas
   CreateLabel("lblATRPeriod", x+20, y+160, "ATR Period", COR_LABEL, 9);
   CreateEdit("editATRPeriod", x+20, y+178, 130, 24, IntegerToString(ATR_Period));
   SetTooltip("lblATRPeriod","Período do ATR usado no TRAIL ATR. Ex: 14. Quanto maior, mais 'lento' o trailing.");
   SetTooltip("editATRPeriod","Período do ATR usado no TRAIL ATR. Ex: 14. Quanto maior, mais 'lento' o trailing.");

   CreateLabel("lblATRMul", x+170, y+160, "ATR Mult", COR_LABEL, 9);
   CreateEdit("editATRMul", x+170, y+178, 130, 24, DoubleToString(ATR_Mult,2));
   SetTooltip("lblATRMul","Multiplicador do ATR no TRAIL ATR. Maior = SL/TP mais distantes (mais folga).");
   SetTooltip("editATRMul","Multiplicador do ATR no TRAIL ATR. Maior = SL/TP mais distantes (mais folga).");

   CreateLabel("lblTrailMove", x+290, y+160, "Trail Move", COR_LABEL, 9);
   CreateEdit("editTrailMove", x+290, y+178, 70, 24, IntegerToString(TrailMove_Pontos));
   SetTooltip("lblTrailMove","Passo do trailing em degraus (pts) nos modos não-ATR (TS/TT).");
   SetTooltip("editTrailMove","Passo do trailing em degraus (pts) nos modos não-ATR (TS/TT).");

   // Linha extra para configuração do break-even offset
   CreateLabel("lblBEOffset", x+290, y+206, "BE Offset", COR_LABEL, 9);
   CreateEdit("editBEOffset", x+290, y+224, 70, 24, IntegerToString(BreakEvenOffset_Pontos));
   SetTooltip("lblBEOffset","Offset do Break-Even em pts. 0 = SL no preço de entrada; >0 trava lucro no BE.");
   SetTooltip("editBEOffset","Offset do Break-Even em pts. 0 = SL no preço de entrada; >0 trava lucro no BE.");

   CreateButton("btnBuy", x+20, y+250, 160, 40, "COMPRAR", COR_BUY, true);
   SetTooltip("btnBuy","Abre COMPRA com SL/TP fixos");
   CreateButton("btnSell", x+200, y+250, 160, 40, "VENDER", COR_SELL, true);
   SetTooltip("btnSell","Abre VENDA com SL/TP fixos");

   CreateButton("btnBuyATR", x+20,  y+300, 160, 32, "TRAIL ATR BUY",  COR_BUY, true);
   SetTooltip("btnBuyATR","COMPRA com trailing ATR");
   CreateButton("btnSellATR", x+200, y+300, 160, 32, "TRAIL ATR SELL", COR_SELL, true);
   SetTooltip("btnSellATR","VENDA com trailing ATR");

   // Fechamentos alinhados abaixo dos TRAIL ATR
   CreateButton("btnCloseBuys",  x+20,  y+340, 160, 32, "FECHAR BUY",  COR_BUY, true);
   SetTooltip("btnCloseBuys","Fecha posições BUY apenas deste símbolo (gráfico atual).");
   CreateButton("btnCloseSells", x+200, y+340, 160, 32, "FECHAR SELL", COR_SELL, true);
   SetTooltip("btnCloseSells","Fecha posições SELL apenas deste símbolo (gráfico atual).");
   CreateButton("btnCloseAll",   x+20,  y+380, 340, 32, "FECHAR TODAS", COR_NEUTRO, true);
   SetTooltip("btnCloseAll","Fecha todas as posições deste símbolo no gráfico atual (não mexe em outros ativos).");

   // Título do painel de informações
   CreateLabel("lblInfoTitulo", x+20, y+418, "INFO", COR_TEXTO, 11);
   SetTooltip("lblInfoTitulo","Indicadores e progresso da meta do dia.");

   // Card de informações: grid 2 colunas + barra de progresso da meta
   // Remove objetos antigos do card (se existirem) para evitar sobreposição ao recarregar o EA.
   ObjectDelete(0,"lblLucro");
   ObjectDelete(0,"lblTrades");
   ObjectDelete(0,"lblSepMeta");
   ObjectDelete(0,"lblPosBS");
   ObjectDelete(0,"lblSaldo");
   ObjectDelete(0,"lblSepStatus");
   ObjectDelete(0,"lblInfo4");

   int colL = x + 20;
   int colV = x + 175;

   int ySprATR = y + 450;
   int yPnL    = y + 464;
   int yOpen   = y + 478;
   int ySep1    = y + 488;
   int ySaldo  = y + 494;
   int yMeta   = y + 508;
   int yBar    = y + 516;
   int yGestao = y + 528;

   metaBarX = colL;
   metaBarY = yBar;
   metaBarW = 340;
   metaBarH = 6;

   // Linhas horizontais (separação visual)
   CreateLabel("lblSepOpenMeta", colL, ySep1, "────────────────", COR_NEUTRO, 8);

   // Spread / ATR
   CreateLabel("lblK_SprATR", colL, ySprATR, "Spread", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_SprATR", colV, ySprATR, "--", COR_TEXTO, 8);
   SetTooltip("lblV_SprATR","Spread em pts e ATR do período configurado.");

   // PnL / tot
   CreateLabel("lblK_PnL", colL, yPnL, "PnL", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_PnL", colV, yPnL, "$0.00 | tot $0.00", COR_TEXTO, 8);
   SetTooltip("lblV_PnL","PnL flutuante deste símbolo e total da conta.");

   // Open buy/sell
   CreateLabel("lblK_Open", colL, yOpen, "Open", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Open", colV, yOpen, "▲0  ▼0", COR_TEXTO, 8);
   SetTooltip("lblV_Open","Quantidade de posições BUY e SELL abertas neste símbolo.");

   // Saldo (acima da meta 3%)
   CreateLabel("lblK_Saldo", colL, ySaldo, "Saldo", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Saldo", colV, ySaldo, "$0.00", COR_TEXTO, 8);
   SetTooltip("lblV_Saldo","Saldo (Account Balance).");

   // Meta 3% e barra
   CreateLabel("lblK_Meta", colL, yMeta, "Meta 3%", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Meta", colV, yMeta, "$0 | falta $0", COR_TEXTO, 8);
   SetTooltip("lblV_Meta","Meta do dia (3%) e quanto falta para bater.");

   CreateRectangle("barMetaBG", metaBarX, metaBarY, metaBarW, metaBarH, COR_CARD);
   CreateRectangle("barMetaFill", metaBarX, metaBarY, 0, metaBarH, COR_BUY_SOFT);

   // Gestão
   CreateLabel("lblK_Gestao", colL, yGestao, "Gestão", COR_TEXTO_MUTE, 8);
   CreateLabel("lblV_Gestao", colV, yGestao, "—", COR_LABEL, 8);
   SetTooltip("lblV_Gestao","Estado atual da gestão (ATR/BE/STEP).");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void CreateRectangle(string name,int x,int y,int w,int h,color cor)
{
   ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,cor);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);   // garante que retângulos não cubram labels
   ObjectSetInteger(0,name,OBJPROP_ZORDER,0);
}

void CreateButton(string name,int x,int y,int w,int h,string text,color cor,bool textoNegrito=false)
{
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,cor);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetString(0,name,OBJPROP_FONT, textoNegrito ? BTN_FONT_BOLD : BTN_FONT_REGULAR);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,10);
}

void SetTooltip(string name,string tooltip)
{
   ObjectSetString(0,name,OBJPROP_TOOLTIP,tooltip);
}

void CreateEdit(string name,int x,int y,int w,int h,string text)
{
   ObjectCreate(0,name,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,COR_CARD);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
   ObjectSetInteger(0,name,OBJPROP_ZORDER,10);
}

void CreateLabel(string name,int x,int y,string text,color cor,int size)
{
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   // Hierarquia visual (estilo profissional):
   // - rótulos em cinza: Segoe UI Semilight
   // - valores (cores de destaque): Segoe UI Bold
   string fontName = "Segoe UI Semilight";
   // Usar "Semibold" (mais consistente no MT5) para valores destacados
   if(cor == COR_BUY || cor == COR_SELL || cor == COR_BUY_SOFT || cor == COR_SELL_SOFT || cor == COR_LABEL || cor == COR_TEXTO || cor == COR_WARN)
      fontName = "Segoe UI Semibold";
   ObjectSetString(0,name,OBJPROP_FONT,fontName);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,10);
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_DRAG && (sparam=="painel" || sparam=="painelBorder" || sparam=="dragHandle"))
   {
      int newX = 0;
      int newY = 0;
      bool draggingHandle = (sparam=="dragHandle");
      if(sparam=="painelBorder")
      {
         newX = (int)ObjectGetInteger(0,"painelBorder",OBJPROP_XDISTANCE) + PANEL_BORDER_PAD;
         newY = (int)ObjectGetInteger(0,"painelBorder",OBJPROP_YDISTANCE) + PANEL_BORDER_PAD;
         ObjectSetInteger(0,"painel",OBJPROP_XDISTANCE,newX);
         ObjectSetInteger(0,"painel",OBJPROP_YDISTANCE,newY);
      }
      else if(draggingHandle)
      {
         int hx = (int)ObjectGetInteger(0,"dragHandle",OBJPROP_XDISTANCE);
         int hy = (int)ObjectGetInteger(0,"dragHandle",OBJPROP_YDISTANCE);
         newX = hx - DRAG_X_OFF;
         newY = hy - DRAG_Y_OFF;
         ObjectSetInteger(0,"painel",OBJPROP_XDISTANCE,newX);
         ObjectSetInteger(0,"painel",OBJPROP_YDISTANCE,newY);
         ObjectSetInteger(0,"painelBorder",OBJPROP_XDISTANCE,newX-PANEL_BORDER_PAD);
         ObjectSetInteger(0,"painelBorder",OBJPROP_YDISTANCE,newY-PANEL_BORDER_PAD);
      }
      else
      {
         newX = (int)ObjectGetInteger(0,"painel",OBJPROP_XDISTANCE);
         newY = (int)ObjectGetInteger(0,"painel",OBJPROP_YDISTANCE);
         ObjectSetInteger(0,"painelBorder",OBJPROP_XDISTANCE,newX-PANEL_BORDER_PAD);
         ObjectSetInteger(0,"painelBorder",OBJPROP_YDISTANCE,newY-PANEL_BORDER_PAD);
      }

      int dx = newX - lastPanelX;
      int dy = newY - lastPanelY;

      for(int i=0;i<ArraySize(objetos);i++)
      {
         string nome = objetos[i];
         if(ObjectFind(0,nome)>=0 && nome!="painel" && nome!="painelBorder" && !(draggingHandle && nome=="dragHandle"))
         {
            int ox = (int)ObjectGetInteger(0,nome,OBJPROP_XDISTANCE);
            int oy = (int)ObjectGetInteger(0,nome,OBJPROP_YDISTANCE);

            ObjectSetInteger(0,nome,OBJPROP_XDISTANCE,ox+dx);
            ObjectSetInteger(0,nome,OBJPROP_YDISTANCE,oy+dy);
         }
      }

      lastPanelX = newX;
      lastPanelY = newY;
   }

   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam=="btnBuy") AbrirOrdem(true, MODE_NORMAL);
      if(sparam=="btnSell") AbrirOrdem(false, MODE_NORMAL);

      if(sparam=="btnBuyATR") AbrirOrdem(true, MODE_ATR);
      if(sparam=="btnSellATR") AbrirOrdem(false, MODE_ATR);

      if(sparam=="btnLogs")
      {
         EnableLogs = !EnableLogs;
         ObjectSetString(0, "btnLogs", OBJPROP_TEXT, LogsButtonText());
         ObjectSetInteger(0, "btnLogs", OBJPROP_BGCOLOR, LogsButtonColor());
      }

      if(sparam=="btnCloseAll") FecharTodas();
      if(sparam=="btnCloseBuys") FecharTipo(POSITION_TYPE_BUY);
      if(sparam=="btnCloseSells") FecharTipo(POSITION_TYPE_SELL);

      if(sparam=="btnLot03") { Lotes=0.03; UpdateEdit("editLote",Lotes); }
      if(sparam=="btnLot06") { Lotes=0.06; UpdateEdit("editLote",Lotes); }
      if(sparam=="btnLot09") { Lotes=0.09; UpdateEdit("editLote",Lotes); }

      if(sparam=="btnLotPlus") { Lotes+=0.01; UpdateEdit("editLote",Lotes); }
      if(sparam=="btnLotMinus") { Lotes=MathMax(0.01,Lotes-0.01); UpdateEdit("editLote",Lotes); }

      if(sparam=="btnPresetScalp")  ApplyPreset(0);
      if(sparam=="btnPresetNormal") ApplyPreset(1);
      if(sparam=="btnPresetSwing")  ApplyPreset(2);
   }

   if(id==CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(sparam=="editLote") Lotes = StringToDouble(ObjectGetString(0,"editLote",OBJPROP_TEXT));
      if(sparam=="editTP")   TP_Pontos = (int)StringToInteger(ObjectGetString(0,"editTP",OBJPROP_TEXT));
      if(sparam=="editSL")   SL_Pontos = (int)StringToInteger(ObjectGetString(0,"editSL",OBJPROP_TEXT));
      if(sparam=="editTrailStep") TrailStep_Pontos = (int)StringToInteger(ObjectGetString(0,"editTrailStep",OBJPROP_TEXT));

      if(sparam=="editATRPeriod")
      {
         int p = (int)StringToInteger(ObjectGetString(0,"editATRPeriod",OBJPROP_TEXT));
         if(p < 1) p = 1;
         if(p != ATR_Period)
         {
            ATR_Period = p;
            if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
            atrHandle = iATR(_Symbol, _Period, ATR_Period);
         }
      }
      if(sparam=="editATRMul")
      {
         double m = StringToDouble(ObjectGetString(0,"editATRMul",OBJPROP_TEXT));
         if(m <= 0.0) m = 0.1;
         ATR_Mult = m;
      }
      if(sparam=="editTrailMove")
      {
         int t = (int)StringToInteger(ObjectGetString(0,"editTrailMove",OBJPROP_TEXT));
         if(t < 1) t = 1;
         TrailMove_Pontos = t;
      }
      if(sparam=="editBEOffset")
      {
         int be = (int)StringToInteger(ObjectGetString(0,"editBEOffset",OBJPROP_TEXT));
         if(be < 0) be = 0;
         BreakEvenOffset_Pontos = be;
      }
   }
}

//+------------------------------------------------------------------+
void UpdateEdit(string name,double value)
{
   ObjectSetString(0,name,OBJPROP_TEXT,DoubleToString(value,2));
}

void FecharTodas()
{
   string sym = _Symbol;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != sym) continue;
      if(!trade.PositionClose(ticket))
         Log(StringFormat("FecharTodas: falhou. retcode=%d desc=%s ticket=%I64u",
                          (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
   }
}

void FecharTipo(int tipo)
{
   string sym = _Symbol;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != sym) continue;
      int posType = (int)PositionGetInteger(POSITION_TYPE);
      if(posType != tipo) continue;
      if(!trade.PositionClose(ticket))
         Log(StringFormat("FecharTipo: falhou. retcode=%d desc=%s ticket=%I64u",
                          (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
   }
}

void OnDeinit(const int reason)
{
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   atrHandle = INVALID_HANDLE;
}