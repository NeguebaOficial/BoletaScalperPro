//+------------------------------------------------------------------+
//| Data_State.mqh — estado, presets, constantes de layout (Model)   |
//+------------------------------------------------------------------+
#ifndef DATA_STATE_MQH
#define DATA_STATE_MQH

// ================= VARIÁVEIS DE ESTADO / PARÂMETROS =================
double Lotes = 0.01;
int TP_Pontos = 800;
int SL_Pontos = 900;
int TrailStep_Pontos = 400;
int BreakEvenOffset_Pontos = 0;
int TrailMove_Pontos = 100;

// Presets (XAUUSD ~spread 40 pts)
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

int MODE_NORMAL = 0;
int MODE_TRAIL_SL = 1;
int MODE_TRAIL_TP = 2;
int MODE_ATR = 3;

long MAGIC_NORMAL = 7700;
long MAGIC_TRAIL_SL = 7701;
long MAGIC_TRAIL_TP = 7702;
long MAGIC_ATR_TRAIL = 7703;

int ATR_Period = 14;
double ATR_Mult = 2.0;
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
const int PANEL_H = 548;
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
   else
     {
      TP_Pontos = PRESET_NORMAL_TP;
      SL_Pontos = PRESET_NORMAL_SL;
      TrailStep_Pontos = PRESET_NORMAL_START;
      TrailMove_Pontos = PRESET_NORMAL_TRAILMOVE;
      BreakEvenOffset_Pontos = PRESET_NORMAL_BEOFFSET;
      ATR_Mult = PRESET_NORMAL_ATRMUL;
     }
  }

#endif // DATA_STATE_MQH
