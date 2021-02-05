//+------------------------------------------------------------------+
//|                                                     ImaNoise.mq5 |
//|                                     Copyright 2020, Hadi Hammoud |
//|          https://www.facebook.com/profile.php?id=100005345026100 |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+





#property copyright "Copyright 2020, Hadi Hammoud "



#property link "https://www.facebook.com/profile.php?id=100005345026100"



#property version "1.00"



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



input double FIRST_TAKE_PROFIT = 50;
input double SECOND_TAKE_PROFIT = 50;
input double THIRD_TAKE_PROFIT = 50;
input double FOURTH_TAKE_PROFIT = 50;

input double FIRST_INTERVAL = 25;
input double SECOND_INTERVAL = 50;
input double THIRD_INTERVAL = 50;
input double FOURTH_INTERVAL = 50;

input double FIRST_LOT = 0.02;
input double SECOND_LOT = 0.02;
input double THIRD_LOT = 0.02;
input double FOURTH_LOT = 0.02;

input int MAX_OPERATIONS  = 4;


input int MA_PERIOD = 1260;
input int CANDLE_SHITFT = 1;




bool isAbove;
bool awaitingFirstCross = true;
bool isNewBar = false;

int operationsNumber;

double lastAskPrice = 0;
double lastBidPrice = 0;
double maValue = 0;





int OnInit()



  {
   if(!maHandle.Create(Symbol(), PERIOD_M1, MA_PERIOD, 7, MODE_SMMA, PRICE_MEDIAN))
      return INIT_FAILED;
   maHandle.Redrawer(true);
//if(!isAccountValid())
// return INIT_FAILED;
   trade.SetExpertMagicNumber(MAGIC_NUMBER);
   return (INIT_SUCCEEDED);
  }


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
   isNewBar = checkIfNewBar();

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
               if(maValue + FIRST_INTERVAL * _Point <= symbolInfo.Bid())
                 {
                  openFirstBuy();
                 }
              }
            else
               if(operationsNumber < MAX_OPERATIONS)
                 {
                  if(lastAskPrice + getInterval() * _Point < symbolInfo.Bid())
                    {
                     openAnotherBuy();
                    }
                 }
           }
         else
           {
            if(operationsNumber == 0)
              {
               if(maValue - FIRST_INTERVAL * _Point >= symbolInfo.Bid())
                 {
                  openFirstSell();
                 }
              }
            else
               if(operationsNumber < MAX_OPERATIONS)
                 {
                  if(lastBidPrice - getInterval() * _Point > symbolInfo.Bid())
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
   switch(operationsNumber)
     {
      case 0:
         return FIRST_LOT;
         break;
      case 1:
         return SECOND_LOT;
         break;
      case 2:
         return THIRD_LOT;
         break;
      case 3:
         return FOURTH_LOT;
         break;
      default:
         return FOURTH_LOT;
         break;
     }
  }



void openFirstSell()



  {
   if(trade.SellStop(getLot(), symbolInfo.Bid(), _Symbol, NormalizeDouble(maValue, Digits()), symbolInfo.Bid() - getTakeProfitInput() * _Point))
     {
      operationsNumber = 1;
      lastBidPrice = symbolInfo.Bid();
      Print("Sell oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Bid());
     }
   else
     {
      Print("Sell oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription());
     }
  }



void openAnotherSell()



  {
   if(trade.SellStop(getLot(), symbolInfo.Bid(), _Symbol, NormalizeDouble(maValue, Digits()), symbolInfo.Bid() - getTakeProfitInput() * _Point))
     {
      operationsNumber++;
      lastBidPrice = symbolInfo.Bid();
      Print("Sell oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Bid());
     }
   else
     {
      Print("Sell oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription());
     }
  }



void openFirstBuy()



  {
   if(trade.BuyStop(getLot(), symbolInfo.Ask(), _Symbol, NormalizeDouble(maValue, Digits()), symbolInfo.Ask() + getTakeProfitInput() * _Point))
     {
      operationsNumber = 1;
      lastAskPrice = symbolInfo.Ask();
      Print("Buy oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Ask(), "\nMA value of: ", maValue);
     }
   else
     {
      Print("Buy oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription(), "oneMa: ", maValue);
     }
  }

void openAnotherBuy()



  {
   if(trade.BuyStop(getLot(), symbolInfo.Ask(), _Symbol, NormalizeDouble(maValue, Digits()), symbolInfo.Ask() + getTakeProfitInput() * _Point))
     {
      operationsNumber++;
      lastAskPrice = symbolInfo.Ask();
      Print("Buy oparation number: ", operationsNumber, " succeeded with\nPrice: ", symbolInfo.Ask());
     }
   else
     {
      Print("Buy oparation failed, Return code: ", trade.ResultRetcode(), ". Code descriptino: ", trade.ResultRetcodeDescription());
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
   if(!isNewBar)
      return noCrossing;
   maHandle.Refresh();
   maValue = maHandle.Main(CANDLE_SHITFT);
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
   if(!isNewBar || PositionsTotal() == 0)
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      string symbol = PositionGetSymbol(i);
      if(positionInfo.SelectByIndex(i))
        {
         ulong ticket = positionInfo.Ticket();
         double sl = positionInfo.StopLoss();
         double newSl = NormalizeDouble(maValue, Digits());
         double tp = positionInfo.TakeProfit();
         if(sl != newSl)
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
bool checkIfNewBar()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time = 0;
//--- current time
   datetime lastbar_time = SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);
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


bool isAccountValid()



  {
   long login = account.Login();
   Print("Login = ", login);
   if(account.TradeMode() == ACCOUNT_TRADE_MODE_REAL)
     {
      MessageBox("Trading on a real account is forbidden");
      return false;
     }
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
   return true;
  } //+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
