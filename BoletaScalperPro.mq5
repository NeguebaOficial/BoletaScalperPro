//+------------------------------------------------------------------+
//|                                              BoletaScalperPro.mq5 |
//|                                     Copywriter Negueba Trader     |
//|  Modular: Data_State / Trade_Core / Panel_UI                    |
//+------------------------------------------------------------------+
#property copyright "Negueba Trader"
#property version "1.00"

#include "Panel_UI.mqh"

//+------------------------------------------------------------------+
int OnInit()
  {
   int largura = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int x = largura - 400;
   int y = 10;

   Panel_InitBoleta(x, y);
   return (INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Trade_ReleaseAtrHandle();
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   string symbol = _Symbol;
   double pnlTotal = 0.0;
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
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   Panel_OnChartEvent(id, lparam, dparam, sparam);
  }
