//+------------------------------------------------------------------+
//|                                                     ImaNoise.mq5 |
//|                                     Copyright 2020, Hadi Hammoud |
//|          https://www.facebook.com/profile.php?id=100005345026100 |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+





#property copyright "Copyright 2020, Hadi Hammoud "
#property link "https://www.facebook.com/profile.php?id=100005345026100"
#property version "1.00"

#property script_show_inputs


#include <Trade/Trade.mqh>



#include <Trade\AccountInfo.mqh>



#include <Trade/SymbolInfo.mqh>



#include <Trade\PositionInfo.mqh>



#include <Indicators\Trend.mqh>



//+------------------------------------------------------------------+



//| Expert initialization function                                   |



//+------------------------------------------------------------------+



static int MAGIC_NUMBER = 2134139412;



CTrade trade;

CAccountInfo account;

CSymbolInfo symbolInfo;

CPositionInfo positionInfo;

CiMA maHandle;



input double FIRST_TAKE_PROFIT = 1300;
input double SECOND_TAKE_PROFIT = 1270;
input double THIRD_TAKE_PROFIT = 1240;
input double FOURTH_TAKE_PROFIT = 410;

input double FIRST_INTERVAL = 60;
input double SECOND_INTERVAL = 25;
input double THIRD_INTERVAL = 25;
input double FOURTH_INTERVAL = 25;

input double FIRST_LOT = 0.01;
input double SECOND_LOT = 0.08;
input double THIRD_LOT = 0.08;
input double FOURTH_LOT = 0.02;

input int MAX_OPERATIONS  = 3;


input int MA_PERIOD = 5040;
input int CANDLE_SHITFT = 1;




bool isAbove;
bool awaitingFirstCross = true;


int operationsNumber = 0;

double lastAskPrice = 0;
double lastBidPrice = 0;
double lastMaValue = 0;
double maValue = 0;





int OnInit()



  {
   if(!maHandle.Create(Symbol(), PERIOD_M1, MA_PERIOD, 7, MODE_SMMA, PRICE_MEDIAN))
      return INIT_FAILED;
   maHandle.Redrawer(true);
   if(!isAccountValid())
      return INIT_FAILED;
   printAllowedOperations(_Symbol);
   trade.SetExpertMagicNumber(MAGIC_NUMBER);
   return (INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   if(trans.symbol != Symbol())
      return;
   if(HistoryDealSelect(trans.deal) == true)
     {
      ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON) HistoryDealGetInteger(trans.deal, DEAL_REASON);
      if(reason == DEAL_REASON_SL)
        {
         operationsNumber = 0;
         Print("SL activated");
        }
     }
  }


void OnTick()


  {
 //  isNewBar = checkIfNewBar();
// if(!isNewBar)
// {
//return;
// }
   if(!symbolInfo.RefreshRates())
      return;
   switch(didCross())
     {
      case noCrossing:
         if(awaitingFirstCross)
            return;
         if(isAbove)
           {
            if(operationsNumber == 0)
              {
               if(symbolInfo.Ask() >= maValue + FIRST_INTERVAL * _Point && symbolInfo.Ask() <= maValue + FIRST_INTERVAL * _Point + (10 * _Point))
                 {
                  openFirstBuy();
                 }
              }
            else
               if(operationsNumber < MAX_OPERATIONS)
                 {
                  if(symbolInfo.Ask() >= lastAskPrice + getInterval() * _Point&&symbolInfo.Ask() <=(10 * _Point)+lastAskPrice + getInterval())
                    {
                     openAnotherBuy();
                    }
                 }
           }
         else
           {
            if(operationsNumber == 0)
              {
               if(symbolInfo.Bid()  <= maValue - FIRST_INTERVAL * _Point && symbolInfo.Bid()>=maValue - FIRST_INTERVAL * _Point-(10 * _Point))
                 {
                  openFirstSell();
                 }
              }
            else
               if(operationsNumber < MAX_OPERATIONS)
                 {
                  if(symbolInfo.Bid() <= lastBidPrice - getInterval() * _Point && symbolInfo.Bid()>=lastBidPrice - getInterval()* _Point-(10 * _Point))
                    {
                     openAnotherSell();
                    }
                 }
           }
         break;
      case crossFromAbove:
         if(awaitingFirstCross)
            awaitingFirstCross = false;
         Print("Cross from above");
         operationsNumber = 0;
         isAbove = false;
         break;
      case crossFromBelow:
         if(awaitingFirstCross)
            awaitingFirstCross = false;
         Print("Cross from below");
         operationsNumber = 0;
         isAbove = true;
         break;
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   updateStopLoss();
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getInterval()
  {
   switch(operationsNumber)
     {
      case 0:
         return FIRST_INTERVAL;
         break;
      case 1:
         return SECOND_INTERVAL;
         break;
      case 2:
         return THIRD_INTERVAL;
         break;
      case 3:
         return FOURTH_INTERVAL;
         break;
      default:
         return FOURTH_INTERVAL;
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getTakeProfitInput()
  {
   switch(operationsNumber)
     {
      case 0:
         return FIRST_TAKE_PROFIT;
         break;
      case 1:
         return SECOND_TAKE_PROFIT;
         break;
      case 2:
         return THIRD_TAKE_PROFIT;
         break;
      case 3:
         return FOURTH_TAKE_PROFIT;
         break;
      default:
         return FOURTH_TAKE_PROFIT;
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getLot()
  {
   double lotToUse;
   switch(operationsNumber)
     {
      case 0:
         lotToUse = FIRST_LOT;
         break;
      case 1:
         lotToUse = SECOND_LOT;
         break;
      case 2:
         lotToUse = THIRD_LOT;
         break;
      case 3:
         lotToUse = FOURTH_LOT;
         break;
      default:
         lotToUse = FOURTH_LOT;
         break;
     }
   return NormalizeLots(lotToUse);
  }



void openFirstSell()



  {
   double sl = maValue;
   if(trade.Sell(getLot(), _Symbol, NormalizePrice(symbolInfo.Bid()),  sl, symbolInfo.Bid() - getTakeProfitInput() * _Point))
     {
      operationsNumber = 1;
      lastBidPrice = symbolInfo.Bid();
      Print("Sell oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Bid());
     }
   else
     {
      Print("Sell oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription());
      printData();
     }
  }



void openAnotherSell()



  {
   double sl = maValue;
   if(trade.Sell(getLot(), _Symbol, NormalizePrice(symbolInfo.Bid()), sl, symbolInfo.Bid() - getTakeProfitInput() * _Point))
     {
      operationsNumber++;
      lastBidPrice = symbolInfo.Bid();
      Print("Sell oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Bid());
     }
   else
     {
      Print("Sell oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription());
      printData();
     }
  }



void openFirstBuy()



  {
   double sl = maValue;
   if(trade.Buy(getLot(), _Symbol, NormalizePrice(symbolInfo.Ask()), sl, symbolInfo.Ask() + getTakeProfitInput() * _Point))
     {
      operationsNumber = 1;
      lastAskPrice = symbolInfo.Ask();
      Print("Buy oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Ask(), "\nMA value of: ", maValue);
     }
   else
     {
      Print("Buy oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription(), "oneMa: ", maValue);
      printData();
     }
  }

void openAnotherBuy()



  {
   double sl = maValue;
   if(trade.Buy(getLot(), _Symbol, NormalizePrice(symbolInfo.Ask()), sl, symbolInfo.Ask() + getTakeProfitInput() * _Point))
     {
      operationsNumber++;
      lastAskPrice = symbolInfo.Ask();
      Print("Buy oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Ask());
     }
   else
     {
      Print("Buy oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription());
      printData();
     }
  }



enum CrossType
  {
   crossFromBelow,
   crossFromAbove,
   noCrossing,
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CrossType didCross()
  {
   maHandle.Refresh();
   maValue = NormalizeDouble(maHandle.Main(CANDLE_SHITFT), Digits());
   lastMaValue = NormalizeDouble(maHandle.Main(CANDLE_SHITFT + 1), Digits());
//   if(!isNewBar)
  //    return noCrossing;
 
   double openPrice = iOpen(_Symbol, PERIOD_CURRENT, CANDLE_SHITFT);
   double closePrice = iClose(_Symbol, PERIOD_CURRENT, CANDLE_SHITFT);
   if(openPrice  > maValue && closePrice  < maValue)
     {
      return crossFromAbove;
     }
   else
      if(openPrice   < maValue && closePrice  > maValue)
        {
         return crossFromBelow;
        }
      else
        {
         return noCrossing;
        }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void updateStopLoss()
  {
   if(PositionsTotal() == 0)
      return;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(positionInfo.SelectByIndex(i))
        {
         ulong ticket = positionInfo.Ticket();
         double sl = positionInfo.StopLoss();
         double newSl = NormalizeDouble(maValue, Digits());
         double tp = positionInfo.TakeProfit();
     
         if(sl != newSl && sl!=lastMaValue)
           {
            if(!trade.PositionModify(ticket, newSl, tp))
              {
               Print("Modify oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription(), "attempted sl: ", maValue);
              }
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizePrice(double p)
  {
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return NormalizeDouble((MathRound(p / ts) * ts), _Digits);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizeLots(double p)
  {
   double ls = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   return (MathRound(p / ls) * ls);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printData()
  {
   Print("Operation number: ", operationsNumber, "\nMa value: ", maValue, "\nStop loss:", NormalizeDouble(maValue, Digits()), "\nAsk price:", SymbolInfoDouble(_Symbol, SYMBOL_ASK), "\nBid price: ", SymbolInfoDouble(_Symbol, SYMBOL_BID));
  }


bool isAccountValid()



  {
   long login = account.Login();
   Print("Login = ", login);
   if(!account.TradeAllowed())
     {
      MessageBox("Trading on this account is forbidden");
      return false;
     }
   if(!account.TradeExpert())
     {
      MessageBox("Automated trading on this account is forbidden");
      return false;
     }
   Print("Balnce = ", account.Balance());
   Print("Profit = ", account.Profit());
   Print("Equity = ", account.Equity());
   Print("Curreny = ", account.Currency());
   Print("Margin = ", account.Margin());
   MqlDateTime now, expiry;
   datetime d1 = iTime(Symbol(), PERIOD_H1, 0);
   datetime d2 = D'2021.8.9';
   TimeToStruct(d1, now);
   TimeToStruct(d2, expiry);
   if(now.mon > expiry.mon)
     {
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printAllowedOperations(string symbol)
  {
//--- receive the value of the property describing allowed order types
   int symbol_order_mode = (int)SymbolInfoInteger(symbol, SYMBOL_ORDER_MODE);
//--- check for market orders (Market Execution)
   if((SYMBOL_ORDER_MARKET & symbol_order_mode) == SYMBOL_ORDER_MARKET)
      Print(symbol + ": Market orders are allowed (Buy and Sell)");
//--- check for Limit orders
   if((SYMBOL_ORDER_LIMIT & symbol_order_mode) == SYMBOL_ORDER_LIMIT)
      Print(symbol + ": Buy Limit and Sell Limit orders are allowed");
//--- check for Stop orders
   if((SYMBOL_ORDER_STOP & symbol_order_mode) == SYMBOL_ORDER_STOP)
      Print(symbol + ": Buy Stop and Sell Stop orders are allowed");
//--- check for Stop Limit orders
   if((SYMBOL_ORDER_STOP_LIMIT & symbol_order_mode) == SYMBOL_ORDER_STOP_LIMIT)
      Print(symbol + ": Buy Stop Limit and Sell Stop Limit orders are allowed");
//--- check if placing a Stop Loss orders is allowed
   if((SYMBOL_ORDER_SL & symbol_order_mode) == SYMBOL_ORDER_SL)
      Print(symbol + ": Stop Loss orders are allowed");
//--- check if placing a Take Profit orders is allowed
   if((SYMBOL_ORDER_TP & symbol_order_mode) == SYMBOL_ORDER_TP)
      Print(symbol + ": Take Profit orders are allowed");
//--- check if closing a position by an opposite one is allowed
   if((SYMBOL_ORDER_TP & symbol_order_mode) == SYMBOL_ORDER_CLOSEBY)
      Print(symbol + ": Close by allowed");
//---
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkIfNewBar()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time = 0;
//--- current time
   datetime lastbar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
//SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);
//--- if it is the first call of the function
   if(last_time == 0)
     {
      //--- set the time and exit
      last_time = lastbar_time;
      return(false);
     }
//--- if the time differs
   if(last_time != lastbar_time)
     {
      //--- memorize the time and return true
      last_time = lastbar_time;
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }



//+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
