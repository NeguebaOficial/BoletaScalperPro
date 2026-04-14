//+------------------------------------------------------------------+
//| Trade_Core.mqh — CTrade, ordens, trailing, utilitários símbolo   |
//+------------------------------------------------------------------+
#ifndef TRADE_CORE_MQH
#define TRADE_CORE_MQH

#include <Trade/Trade.mqh>
#include "Data_State.mqh"

CTrade trade;

//+------------------------------------------------------------------+
void Log(const string msg)
  {
   if(EnableLogs) Print(msg);
  }

int ContarAbertas() { return PositionsTotal(); }
double GetSaldo() { return AccountInfoDouble(ACCOUNT_BALANCE); }

double SymbolPointSafe(const string symbol)
  {
   double p = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(p <= 0.0) p = _Point;
   return p;
  }

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

bool ValidateOpenSLTP(const string symbol, const bool isBuy, const double price, double &sl, double &tp)
  {
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);

   double minDist = MinStopsDistancePrice(symbol);
   if(minDist <= 0.0) minDist = 0.0;

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
   s.hour = 0;
   s.min = 0;
   s.sec = 0;
   return StructToTime(s);
  }

string BuildManagementStatus(const long magic, const string tag, const int posType, const double openPrice, const double curSL,
                             const double bid, const double ask, const int stepPts, const double symPoint)
  {
   if(magic == MAGIC_ATR_TRAIL && tag == "AT")
     {
      double triggerDistPrice = MathMax(stepPts * symPoint, TrailStep_Pontos * symPoint);
      bool triggered = false;
      if(posType == POSITION_TYPE_BUY) triggered = (bid - openPrice) >= triggerDistPrice;
      if(posType == POSITION_TYPE_SELL) triggered = (openPrice - ask) >= triggerDistPrice;
      if(!triggered) return "ATR wait";

      double beOffset = BreakEvenOffset_Pontos * symPoint;
      double bePrice = (posType == POSITION_TYPE_BUY) ? (openPrice + beOffset) : (openPrice - beOffset);
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
      if(posType == POSITION_TYPE_BUY) triggered = (bid - openPrice) >= triggerPrice;
      if(posType == POSITION_TYPE_SELL) triggered = (openPrice - ask) >= triggerPrice;
      return triggered ? "STEP on" : "STEP wait";
     }

   return "—";
  }

bool ParseTrailComment(const string c, string &tag, int &slPts, int &tpPts, int &stepPts)
  {
   string parts[];
   ArrayResize(parts, 5);

   ushort delim = ',';
   int n = StringSplit(c, delim, parts);
   if(n < 4) return false;

   tag = parts[0];
   slPts = (int)StringToInteger(parts[1]);
   tpPts = (int)StringToInteger(parts[2]);
   stepPts = (int)StringToInteger(parts[3]);

   return (slPts > 0 && stepPts > 0 && tpPts >= 0);
  }

void AbrirOrdem(bool isBuy, int modo)
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

   if(modo == MODE_TRAIL_SL)
     {
      magic = MAGIC_TRAIL_SL;
      comment = StringFormat("TS,%d,%d,%d", SL_Pontos, TP_Pontos, TrailStep_Pontos);
     }
   else if(modo == MODE_TRAIL_TP)
     {
      magic = MAGIC_TRAIL_TP;
      comment = StringFormat("TT,%d,%d,%d", SL_Pontos, TP_Pontos, TrailStep_Pontos);
     }
   else if(modo == MODE_ATR)
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
   else ok = trade.Sell(Lotes, symbol, price, sl, tp, comment);

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

   for(int i = PositionsTotal() - 1; i >= 0; i--)
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

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double curTP = PositionGetDouble(POSITION_TP);
      int posType = (int)PositionGetInteger(POSITION_TYPE);

      if(magic == MAGIC_ATR_TRAIL)
        {
         if(tag != "AT") continue;

         if(!atrOk) continue;

         double triggerDistPrice = MathMax(stepPts * pt, TrailStep_Pontos * pt);
         bool triggered = false;
         if(posType == POSITION_TYPE_BUY) triggered = (bid - openPrice) >= triggerDistPrice;
         if(posType == POSITION_TYPE_SELL) triggered = (openPrice - ask) >= triggerDistPrice;
         if(!triggered) continue;

         double beOffset = BreakEvenOffset_Pontos * pt;
         double bePriceBuy = openPrice + beOffset;
         double bePriceSell = openPrice - beOffset;

         double dist = atrVal * ATR_Mult;
         if(dist <= 0.0) continue;

         double initialSL = (posType == POSITION_TYPE_BUY)
                               ? (openPrice - slPts * pt)
                               : (openPrice + slPts * pt);
         double initialTP = 0.0;
         if(tpPts > 0)
            initialTP = (posType == POSITION_TYPE_BUY)
                           ? (openPrice + tpPts * pt)
                           : (openPrice - tpPts * pt);

         if(posType == POSITION_TYPE_BUY)
           {
            if(curSL + pt < bePriceBuy)
              {
               double desiredSL_BE = bePriceBuy;
               double desiredTP_BE = (curTP > 0.0) ? curTP : initialTP;

               if((bid - desiredSL_BE) >= distGuard && (desiredTP_BE - ask) >= distGuard)
                 {
                  if(!trade.PositionModify(ticket, desiredSL_BE, desiredTP_BE))
                     Log(StringFormat("BE ATR (BUY) falhou. retcode=%d desc=%s ticket=%I64u",
                                      (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
                 }

               continue;
              }
           }
         else
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

         double candSL = (posType == POSITION_TYPE_BUY)
                            ? (bid - dist)
                            : (ask + dist);
         double candTP = (posType == POSITION_TYPE_BUY)
                            ? (ask + dist)
                            : (bid - dist);

         double desiredSL = candSL;
         double desiredTP = candTP;
         if(posType == POSITION_TYPE_BUY)
           {
            desiredSL = MathMax(curSL, desiredSL);
            desiredTP = MathMax(curTP, desiredTP);
            desiredSL = MathMax(desiredSL, initialSL);
            desiredSL = MathMax(desiredSL, bePriceBuy);
            if(tpPts > 0)
               desiredTP = MathMax(desiredTP, initialTP);
           }
         else
           {
            desiredSL = MathMin(curSL, desiredSL);
            desiredTP = MathMin(curTP, desiredTP);
            desiredSL = MathMin(desiredSL, initialSL);
            desiredSL = MathMin(desiredSL, bePriceSell);
            if(tpPts > 0)
               desiredTP = MathMin(desiredTP, initialTP);
           }

         if(MathAbs(desiredSL - curSL) < pt && MathAbs(desiredTP - curTP) < pt)
            continue;

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

         continue;
        }

      double triggerPrice = TrailStep_Pontos * pt;
      double stepMove = TrailMove_Pontos * pt;
      double beOffset = BreakEvenOffset_Pontos * pt;

      double newSL = 0;

      if(posType == POSITION_TYPE_BUY)
        {
         if(bid >= openPrice + triggerPrice)
           {
            double bePrice = openPrice + beOffset;

            double classicTarget = curSL;
            if(curSL < bePrice)
               classicTarget = bePrice;
            else if(bid > curSL + stepMove + minDist)
               classicTarget = curSL + stepMove;

            double ratchetSL = 0.0;
            int nR = 0;
            if(RatchetProfitEvery_Pontos > 0 && RatchetLockPts_Pontos > 0)
              {
               double profitPts = (bid - openPrice) / pt;
               nR = (int)MathFloor(profitPts / (double)RatchetProfitEvery_Pontos);
               if(nR >= 1)
                  ratchetSL = openPrice + (double)nR * RatchetLockPts_Pontos * pt;
              }

            double targetSL = classicTarget;
            if(nR >= 1 && ratchetSL > 0.0)
               targetSL = MathMax(classicTarget, ratchetSL);

            if(MathAbs(targetSL - curSL) > pt)
               newSL = targetSL;
           }
        }
      else if(posType == POSITION_TYPE_SELL)
        {
         if(ask <= openPrice - triggerPrice)
           {
            double bePrice = openPrice - beOffset;

            double classicTarget = curSL;
            if(curSL > bePrice || curSL == 0.0)
               classicTarget = bePrice;
            else if(ask < curSL - stepMove - minDist)
               classicTarget = curSL - stepMove;

            double ratchetSL = 0.0;
            int nR = 0;
            if(RatchetProfitEvery_Pontos > 0 && RatchetLockPts_Pontos > 0)
              {
               double profitPts = (openPrice - ask) / pt;
               nR = (int)MathFloor(profitPts / (double)RatchetProfitEvery_Pontos);
               if(nR >= 1)
                  ratchetSL = openPrice - (double)nR * RatchetLockPts_Pontos * pt;
              }

            double targetSL = classicTarget;
            if(nR >= 1)
               targetSL = MathMin(classicTarget, ratchetSL);

            if(MathAbs(targetSL - curSL) > pt)
               newSL = targetSL;
           }
        }

      if(newSL > 0 && MathAbs(newSL - curSL) > pt)
        {
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

void FecharTodas()
  {
   string sym = _Symbol;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
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
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != sym) continue;
      int posType = (int)PositionGetInteger(POSITION_TYPE);
      if(posType != tipo) continue;
      if(!trade.PositionClose(ticket))
         Log(StringFormat("FecharTipo: falhou. retcode=%d desc=%s ticket=%I64u",
                          (int)trade.ResultRetcode(), trade.ResultRetcodeDescription(), ticket));
     }
  }

void Trade_ReleaseAtrHandle()
  {
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   atrHandle = INVALID_HANDLE;
  }

#endif // TRADE_CORE_MQH
