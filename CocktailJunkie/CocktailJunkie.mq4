//# vim:set foldmethod=marker:
// Copylith//{{{
//+------------------------------------------------------------------+
//|                                               CocktailJunkie.mq4 |
//|                              Copyright 2014, SENAGA Yusuke. |
//|                                               mi081321@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, SENAGA Yusuke."
#property link		"mi081321@gmail.com"
// }}}

// 外部参照//{{{
// MyInclude
#include "..\_common\_Include\Define.mqh"


// MyLib
#import "..\_common\_Lib\MyPosition.ex4"
void GetPositionBUY(double mg_dwDefaultLots = 0, int amount = ALL);
void GetPositionSELL(double mg_dwDefaultLots = 0, int amount = ALL);
void MyOrderClose();
int EmergencyLoss(int index = 0, int select = SELECT_BY_POS, int pips = 200);

#import "..\_common\_Lib\ParabolicSAR.ex4"
int ParabolicTrend(double SAR_Maximum = 0.2, double SAR_Step = 0.02, int n = 0);

#import "..\_common\_Lib\HeikinAshi.ex4"
double HeikinAshiOpen(int n = 0);
double HeikinAshiClose(int n = 0);
//}}}

// グローバル変数//{{{
#define ON		true
#define OFF		false

#define NONE	3

double g_dwCompareWindowSize	= 9999.0;
double g_dwNowWindowSize		= 9999.0;
double g_dwHalfWindowSize		= 9999.0;
double g_dwDefaultLots			= 0.0;
//}}}

int OnInit()//{{{
{
	if (!InitializeCurrency())
	{
		Print("ERROR : This Currency is not supported : ",  Symbol());
		return INIT_FAILED;
	}

	return INIT_SUCCEEDED;
}//}}}

void OnDeinit(const int reason)//{{{
{

}//}}}

void OnTick()//{{{
{
	static int mode;

	static bool bIsWindowOpen		= OFF;
	static bool bIsWindowClose		= OFF;

	static int heikinashi_flag		= OFF;
	static int parabolic_flag		= OFF;

	static bool OrderEnd_flag		= OFF;

	static double Saturday_Close	= 0.0;
	static double Monday_Open		= 0.0;

	SetWindowSize(iOpen(NULL, PERIOD_D1, 1), iClose(NULL, PERIOD_D1, 0));
	double dwWindowSize = GetWindowSize();

	g_dwHalfWindowSize = g_dwNowWindowSize / 2;

	if (DayOfWeek() != 1)
	{
		OrderEnd_flag = OFF;
	}

	bIsWindowOpen = IsWindowOpen(OrderEnd_flag);

	if (bIsWindowOpen == ON)
	{
		bool bModeResult = GetOpenDirection(mode);

		if (bModeResult)
		{
			Saturday_Close = iClose(NULL, PERIOD_D1, 1);
			Monday_Open	 = iOpen(NULL, PERIOD_D1, 0);
		}
	}

	bool windowGo_flag = IsMotherFucker(bIsWindowOpen, mode, Monday_Open);

	if (windowGo_flag == ON)
	{
		switch (mode)
		{
			case GOBUY:
				GetPositionBUY(g_dwDefaultLots);
				break;

			case GOSELL:
				GetPositionSELL(g_dwDefaultLots);
				break;
		}
	}

//-- Position_Back
	if (EmergencyLoss() == true)
	{
		bIsWindowClose	= OFF;
		heikinashi_flag		= OFF;
		parabolic_flag		= OFF;
		OrderEnd_flag		= ON;
	}

	if (OrdersTotal() != 0)
	{
		if (OrderSelect(0, SELECT_BY_POS) == true)
		{
			switch (OrderType())
			{
				case OP_BUY:
					if (Close[1] > Saturday_Close)
					{
						bIsWindowClose = ON;
						if (HeikinAshiOpen(1) <= HeikinAshiClose(1) && HeikinAshiOpen(0) >= HeikinAshiClose(0))
						{
							heikinashi_flag = ON;
						}
						if (ParabolicTrend(0.2, 0.02, 0) == GOSELL)
						{
							parabolic_flag = ON;
						}
					}

					if (bIsWindowClose == ON && heikinashi_flag == ON && parabolic_flag == ON)
					{
						bIsWindowClose	= OFF;
						heikinashi_flag		= OFF;
						parabolic_flag		= OFF;
						OrderEnd_flag		= ON;
						MyOrderClose();
					}
					else if (bIsWindowClose == ON && Close[1] < Saturday_Close)
					{
						bIsWindowClose	= OFF;
						heikinashi_flag		= OFF;
						parabolic_flag		= OFF;
						OrderEnd_flag		= ON;
						MyOrderClose();
					}
					break;
				case OP_SELL:
					if (Close[1] < Saturday_Close)
					{
						bIsWindowClose = ON;
						if (HeikinAshiOpen(1) >= HeikinAshiClose(1) && HeikinAshiOpen(0) <= HeikinAshiClose(0))
						{
							heikinashi_flag = ON;
						}
						if (ParabolicTrend(0.2, 0.02, 0) == GOBUY)
						{
							parabolic_flag = ON;
						}
					}

					if (bIsWindowClose == ON && heikinashi_flag == ON && parabolic_flag == ON)
					  {
						bIsWindowClose	= OFF;
						heikinashi_flag		= OFF;
						parabolic_flag		= OFF;
						OrderEnd_flag		= ON;
						MyOrderClose();
					}
					else if (bIsWindowClose == ON && Close[1] > Saturday_Close)
					{
						bIsWindowClose	= OFF;
						heikinashi_flag		= OFF;
						parabolic_flag		= OFF;
						OrderEnd_flag		= ON;
						MyOrderClose();
					}
					break;
			}
		}
	}

}//}}}

bool IsWindowOpen(int OrderEnd_flag)//{{{
{
	bool bResult = false;

	if (OrderEnd_flag == ON)
	{
		// ここでリターンしなければならないのか？
		bResult = false;
	}
	if (DayOfWeek() == 1 && OrdersTotal() == 0)
	{
		if (g_dwCompareWindowSize < g_dwNowWindowSize)
		{
			// ここでリターンしなければならないのか？
			bResult = true;
		}
	}

	if (DayOfWeek() != 0)
	{
		// ここでリターンしなければならないのか？
		bResult = false;
	}

	return bResult;
}//}}}

bool GetOpenDirection(int& nMode)//{{{
{
	bool bResult = false;

	if (iOpen(NULL, PERIOD_D1, 0) < iClose(NULL, PERIOD_D1, 1))
	{
		nMode = GOBUY;
		bResult = true;
	}
	else if (iOpen(NULL, PERIOD_D1, 0) > iClose(NULL, PERIOD_D1, 1))
	{
		nMode = GOSELL;
		bResult = true;
	}

	return bResult;
}//}}}

bool IsMotherFucker(int open_flag, int mode, double monday)//{{{
{
	// ポジションゲットの判定
	bool bResult = false;

	if (DayOfWeek() < 4)
	{
		if (open_flag == ON)
		{
			switch (mode)
			{
			case GOBUY:
				//if (Close[0] /* + g_dwHalfWindowSize */ >= monday){
				if (Close[0] <= monday && HeikinAshiOpen(2) >= HeikinAshiClose(2) && 
					HeikinAshiOpen(1) >= HeikinAshiClose(1) && HeikinAshiOpen(0) <= HeikinAshiClose(0))
				{
					bResult = true;
				}
				//}
				break;
			case GOSELL:
				//if (Close[0] /* + g_dwHalfWindowSize */ <= monday){
				if (Close[0] >= monday && HeikinAshiOpen(2) <= HeikinAshiClose(2) && 
					HeikinAshiOpen(1) <= HeikinAshiClose(1) && HeikinAshiOpen(0) >= HeikinAshiClose(0))
				{
					bResult = true;
				}
				//}
				break;
			default:
				break;
			}
		}
	}

	return bResult;
}//}}}

bool IsCherryBoy()//{{{
{
	// ポジションリリースの判定
	bool bResult = false;


	return bResult;
}//}}}

void SetWindowSize(double begin, double end)//{{{
{
	if (begin < end)
	{
		g_dwNowWindowSize= end - begin;
	}
	else
	{
		g_dwNowWindowSize = begin - end;
	}
}//}}}

double GetWindowSize()//{{{
{
	return g_dwNowWindowSize;
}//}}}

int GetPositionCount()//{{{
{
	int nPositionCount = OrdersTotal();

	return nPositionCount;
}//}}}

bool InitializeCurrency()//{{{
{
	bool bResult = true;

	if (Symbol()=="USDJPY")
	{
		g_dwCompareWindowSize = 0.015;
		g_dwDefaultLots = 0.2;
	}
	else if (Symbol()=="EURJPY")
	{
		g_dwCompareWindowSize = 0.020;
		g_dwDefaultLots = 0.2;
	}
	else if (Symbol()=="EURUSD")
	{
		g_dwCompareWindowSize = 0.00015;
		g_dwDefaultLots = 0.2;
	}
	else if (Symbol()=="EURGBP")
	{
		g_dwCompareWindowSize = 0.00015;
		g_dwDefaultLots = 0.2;
	}
	else if (Symbol()=="EURTRY")
	{
		g_dwCompareWindowSize = 0.00015;
		g_dwDefaultLots = 0.2;
	}
	else
	{
		bResult = false;
	}

	return bResult;
}//}}}

