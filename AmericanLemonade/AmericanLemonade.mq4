//+------------------------------------------------------------------+
//|                                             AmericanLemonade.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict


int dwPreOrderTime = 0.0;
int nArrayMgicNumberList[100000] = {0};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
    dwPreOrderTime = Seconds();
    
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    OrderJudge();
    
    
}

void OrderJudge()
{
    //--------------------------------------------- Order -> ---------------------------------------------
    // オーダーのトータルが198以下ですか
    if ( OrdersTotal() <= 198 )
    {
        // 証拠金維持率が 200% 以上ですか
        if ( ( AccountFreeMargin() * 1.40 ) > AccountBalance() )
        {
            // 前の取引から5秒以上経ちましたか
            if ( ( Seconds() + 60 - dwPreOrderTime ) % 60 >= 5 )
            {
                // オーダーのマジックナンバーを決めます
                for ( int i = 0; i < ArrayRange( nArrayMgicNumberList, 0 ); i++ )
                {
                    if ( nArrayMgicNumberList[i] == 0 )
                    {
                        OrderSend( Symbol(), OP_BUY,  0.01, Ask, 3, 0, 0, "Buy",  i, 0, Red );
                        OrderSelect( OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES );
                        OrderModify( OrderTicket(), OrderOpenPrice(), 0, OrderOpenPrice() + 0.00030, 0, Red );
                        for ( int j = i + 1; j < ArrayRange( nArrayMgicNumberList, 0 ); j++ )
                        {
                            if ( nArrayMgicNumberList[j] == 0 )
                            {
                                OrderSend( Symbol(), OP_SELL, 0.01, Bid, 3, 0, 0, "Sell", j, 0, Blue );
                                OrderSelect( OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES );
                                OrderModify( OrderTicket(), OrderOpenPrice(), 0, OrderOpenPrice() - 0.00030, 0, Blue );
                                
                                nArrayMgicNumberList[j] = 1;
                                dwPreOrderTime = Seconds();
                                break;
                            }
                        }
                        nArrayMgicNumberList[i] = 1;
                        dwPreOrderTime = Seconds();
                        break;
                    }
                }
            }
        }
    }
    //--------------------------------------------- <- Order ---------------------------------------------
}

void CloseTPJudge()
{
    for ( int i = 0; i < OrdersTotal(); i++ )
    {
        bool bSelectedRet = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
        if ( bSelectedRet != false )
        {
            int nType = OrderType();
            //switch(nType)
            {
                //case OP_BUY:
                
            }
        }
    }
    
}
//+------------------------------------------------------------------+
