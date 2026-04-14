//+------------------------------------------------------------------+
//| Data_State.mqh — estado, presets, constantes de layout (Model)   |
//+------------------------------------------------------------------+
#ifndef DATA_STATE_MQH
#define DATA_STATE_MQH

// ================= VARIÁVEIS DE ESTADO / PARÂMETROS =================
// Defaults de operação (XAUUSD / scalper — alinhados ao painel)
double Lotes = 0.01;
int TP_Pontos = 1000;
int SL_Pontos = 1200;
int TrailStep_Pontos = 180;
int BreakEvenOffset_Pontos = 100;
int TrailMove_Pontos = 120;

// Escada de trava (só STEP TS/TT): a cada RatchetProfitEvery_Pontos de lucro a favor desde a entrada,
// o SL mínimo (BUY) / máximo (SELL) avança RatchetLockPts_Pontos desde a entrada. 0 em "Lucro/degrau" desliga.
int RatchetProfitEvery_Pontos = 400;
int RatchetLockPts_Pontos = 100;

// Presets (XAUUSD ~spread 40 pts) — SCALP espelha os defaults acima
int PRESET_SCALP_TP = 1000;
int PRESET_SCALP_SL = 1200;
int PRESET_SCALP_START = 180;
int PRESET_SCALP_TRAILMOVE = 120;
int PRESET_SCALP_BEOFFSET = 100;
double PRESET_SCALP_ATRMUL = 1.20;
int PRESET_SCALP_RATCHEVERY = 400;
int PRESET_SCALP_RATCHECK = 100;

int PRESET_NORMAL_TP = 9000;
int PRESET_NORMAL_SL = 900;
int PRESET_NORMAL_START = 450;
int PRESET_NORMAL_TRAILMOVE = 100;
int PRESET_NORMAL_BEOFFSET = 80;
double PRESET_NORMAL_ATRMUL = 2.00;
int PRESET_NORMAL_RATCHEVERY = 400;
int PRESET_NORMAL_RATCHECK = 100;

int PRESET_SWING_TP = 9000;
int PRESET_SWING_SL = 2500;
int PRESET_SWING_START = 1000;
int PRESET_SWING_TRAILMOVE = 300;
int PRESET_SWING_BEOFFSET = 150;
double PRESET_SWING_ATRMUL = 2.50;
int PRESET_SWING_RATCHEVERY = 800;
int PRESET_SWING_RATCHECK = 200;

int MODE_NORMAL = 0;
int MODE_TRAIL_SL = 1;
int MODE_TRAIL_TP = 2;
int MODE_ATR = 3;

long MAGIC_NORMAL = 7700;
long MAGIC_TRAIL_SL = 7701;
long MAGIC_TRAIL_TP = 7702;
long MAGIC_ATR_TRAIL = 7703;

int ATR_Period = 7;
double ATR_Mult = 1.20;
int atrHandle = INVALID_HANDLE;

bool EnableLogs = true;

double MetaD_Percent = 0.03;
datetime metaDay = 0;
double metaDayStartBalance = 0.0;

const ulong PANEL_REFRESH_MS = 250;

// ===== Posição do painel (arrastar) =====
int lastPanelX = 0;
int lastPanelY = 0;
const int PANEL_W = 380;
const int PANEL_H = 648;
const int PANEL_BORDER_PAD = 2;
const int DRAG_X_OFF = 225;
const int DRAG_Y_OFF = 8;
const int DRAG_W = 70;
const int DRAG_H = 22;

// Barra de progresso da meta
int metaBarX = 0;
int metaBarY = 0;
int metaBarW = 0;
int metaBarH = 6;

//+------------------------------------------------------------------+
//| Aplica valores de preset apenas ao estado (sem UI)               |
//+------------------------------------------------------------------+
void ApplyPresetToState(const int presetId)
  {
   if(presetId == 0)
     {
      TP_Pontos = PRESET_SCALP_TP;
      SL_Pontos = PRESET_SCALP_SL;
      TrailStep_Pontos = PRESET_SCALP_START;
      TrailMove_Pontos = PRESET_SCALP_TRAILMOVE;
      BreakEvenOffset_Pontos = PRESET_SCALP_BEOFFSET;
      ATR_Mult = PRESET_SCALP_ATRMUL;
      RatchetProfitEvery_Pontos = PRESET_SCALP_RATCHEVERY;
      RatchetLockPts_Pontos = PRESET_SCALP_RATCHECK;
     }
   else if(presetId == 2)
     {
      TP_Pontos = PRESET_SWING_TP;
      SL_Pontos = PRESET_SWING_SL;
      TrailStep_Pontos = PRESET_SWING_START;
      TrailMove_Pontos = PRESET_SWING_TRAILMOVE;
      BreakEvenOffset_Pontos = PRESET_SWING_BEOFFSET;
      ATR_Mult = PRESET_SWING_ATRMUL;
      RatchetProfitEvery_Pontos = PRESET_SWING_RATCHEVERY;
      RatchetLockPts_Pontos = PRESET_SWING_RATCHECK;
     }
   else
     {
      TP_Pontos = PRESET_NORMAL_TP;
      SL_Pontos = PRESET_NORMAL_SL;
      TrailStep_Pontos = PRESET_NORMAL_START;
      TrailMove_Pontos = PRESET_NORMAL_TRAILMOVE;
      BreakEvenOffset_Pontos = PRESET_NORMAL_BEOFFSET;
      ATR_Mult = PRESET_NORMAL_ATRMUL;
      RatchetProfitEvery_Pontos = PRESET_NORMAL_RATCHEVERY;
      RatchetLockPts_Pontos = PRESET_NORMAL_RATCHECK;
     }
  }

#endif // DATA_STATE_MQH
