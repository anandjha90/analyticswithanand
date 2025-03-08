Here are some more challenging and unique Power BI DAX interview questions.
These questions will help you strengthen your DAX skills and tackle real-world scenarios effectively.

1. Write a DAX formula to calculate the number of days between a customer’s first and last purchase.

DATEDIFF(
CALCULATE(MIN(Sales[Date]), ALLEXCEPT(Sales, Sales[CustomerID])),
CALCULATE(MAX(Sales[Date]), ALLEXCEPT(Sales, Sales[CustomerID])),
DAY
)

2. How do you find the top 2 best-selling products per category dynamically?

TOPN(2,
FILTER(
SUMMARIZE(ALL(Sales), Sales[Category], Sales[ProductID], “TotalSales”, SUM(Sales[SalesAmount])),
Sales[Category] = MAX(Sales[Category])
),
[TotalSales], DESC
)

3. Write a DAX measure to count active customers who made at least one purchase in the last 12 months.

CALCULATE(
DISTINCTCOUNT(Sales[CustomerID]),
FILTER(ALL(Sales), Sales[Date] >= TODAY() - 365)
)

4. How do you calculate the total revenue contributed by the top 20% of transactions?

CALCULATE(
SUM(Sales[SalesAmount]),
FILTER(
ALL(Sales),
RANKX(ALL(Sales), Sales[SalesAmount], , DESC) <= COUNTROWS(Sales) * 0.2
)
)

5. Write a DAX formula to calculate the average time gap (in days) between consecutive purchases for each customer.

AVERAGEX(
FILTER(
ADDCOLUMNS(
Sales,
“PreviousPurchaseDate”, CALCULATE(MAX(Sales[Date]), Sales[Date] < EARLIER(Sales[Date]))
),
NOT(ISBLANK([PreviousPurchaseDate]))
),
DATEDIFF([PreviousPurchaseDate], Sales[Date], DAY)
)

6. How do you identify customers who purchased in at least 2 different product categories?

CALCULATE(
DISTINCTCOUNT(Sales[CustomerID]),
FILTER(
VALUES(Sales[CustomerID]),
CALCULATE(DISTINCTCOUNT(Sales[Category])) >= 2
)
)

7. Write a DAX measure to find the most recent sales amount before a selected date.

CALCULATE(
SUM(Sales[SalesAmount]),
FILTER(ALL(Sales), Sales[Date] < SELECTEDVALUE(Sales[Date]))
)

8. How do you calculate the cumulative distinct count of customers over time?

CALCULATE(
DISTINCTCOUNT(Sales[CustomerID]),
FILTER(ALL(Sales), Sales[Date] <= MAX(Sales[Date]))
)

9. Write a DAX formula to get the last non-empty sales value for each product.

LOOKUPVALUE(
Sales[SalesAmount],
Sales[Date], MAXX(FILTER(ALL(Sales), NOT(ISBLANK(Sales[SalesAmount])) && Sales[ProductID] = MAX(Sales[ProductID])), Sales[Date])
)

10. How do you determine the sales percentage change between the first and last months of each year?

(DIVIDE(
CALCULATE(SUM(Sales[SalesAmount]), ENDOFYEAR(Sales[Date])),
CALCULATE(SUM(Sales[SalesAmount]), STARTOFYEAR(Sales[Date]))
) - 1) * 100

11.Write a DAX formula to calculate the running total of sales but reset every 6 months dynamically.

CALCULATE(SUM(Sales[SalesAmount]),
FILTER(ALL(Sales),
DATEDIFF(STARTOFMONTH(Sales[Date]), MAX(Sales[Date]), MONTH) % 6 = 0 &&
Sales[Date] <= MAX(Sales[Date])))

12.How do you calculate the number of unique customers who made a purchase in at least 3 different months?

CALCULATE(DISTINCTCOUNT(Sales[CustomerID]),
FILTER(VALUES(Sales[CustomerID]),
CALCULATE(DISTINCTCOUNT(Sales[Month]), Sales[Month] <> BLANK()) >= 3))

13.Write a DAX measure to find the second-highest sales amount for each product.

TOPN(1,
FILTER(
SUMMARIZE(ALL(Sales), Sales[ProductID], “Sales”, SUM(Sales[SalesAmount])),
[Sales] < MAXX(ALL(Sales), SUM(Sales[SalesAmount]))
),
[Sales], DESC
)

14.How do you calculate the contribution percentage of the top 10% of customers by revenue?

CALCULATE(SUM(Sales[SalesAmount]),
FILTER(ALL(Sales[CustomerID]),
RANKX(ALL(Sales[CustomerID]), SUM(Sales[SalesAmount]), , DESC) <= COUNTROWS(Sales) * 0.1))
/ SUM(Sales[SalesAmount])

15.Write a DAX formula to calculate the difference between the highest and lowest sales in a given category.

MAX(Sales[SalesAmount]) - MIN(Sales[SalesAmount])

16.How do you count customers who made purchases in the last 90 days but not in the previous 90 days?

CALCULATE(DISTINCTCOUNT(Sales[CustomerID]),
FILTER(ALL(Sales),
Sales[Date] >= TODAY() - 90 &&
NOT Sales[Date] >= TODAY() - 180 && Sales[Date] < TODAY() - 90))

17.Write a DAX measure to get the first and last purchase date of each customer in a single measure.

VAR FirstPurchase = CALCULATE(MIN(Sales[Date]), ALLEXCEPT(Sales, Sales[CustomerID]))
VAR LastPurchase = CALCULATE(MAX(Sales[Date]), ALLEXCEPT(Sales, Sales[CustomerID]))
RETURN FirstPurchase & “ - “ & LastPurchase

18.How do you calculate the revenue difference between the current month and the same month last year?

SUM(Sales[SalesAmount]) -
CALCULATE(SUM(Sales[SalesAmount]), SAMEPERIODLASTYEAR(Sales[Date]))

19.Write a DAX formula to find the top-selling product in each region dynamically.

TOPN(1,
SUMMARIZE(ALL(Sales), Sales[Region], Sales[ProductID], “TotalSales”, SUM(Sales[SalesAmount])),
[TotalSales], DESC
)

20.How do you calculate the average revenue per customer but exclude outliers (top and bottom 5%)?

AVERAGEX(
FILTER(ALL(Sales),
RANKX(ALL(Sales), Sales[SalesAmount], , ASC) > COUNTROWS(Sales) * 0.05 &&
RANKX(ALL(Sales), Sales[SalesAmount], , DESC) > COUNTROWS(Sales) * 0.05
),
Sales[SalesAmount]
)

21. Write a DAX formula to calculate the percentage change in sales compared to the previous month.

(SUM(Sales[SalesAmount]) - CALCULATE(SUM(Sales[SalesAmount]), PREVIOUSMONTH(Sales[Date]))) /
CALCULATE(SUM(Sales[SalesAmount]), PREVIOUSMONTH(Sales[Date]))


22. How do you calculate a rolling total of sales for the last 6 months?

CALCULATE(SUM(Sales[SalesAmount]), DATESINPERIOD(Sales[Date], MAX(Sales[Date]), -6, MONTH))

23. Write a DAX measure to count customers who purchased a product for the first time in a given month.

CALCULATE(DISTINCTCOUNT(Sales[CustomerID]),
FILTER(VALUES(Sales[CustomerID]), CALCULATE(MIN(Sales[Date])) = MIN(Sales[Date])))


24. How do you dynamically calculate the top 3 customers contributing the most revenue?

CALCULATE(SUM(Sales[SalesAmount]),
TOPN(3, VALUES(Sales[CustomerID]), SUM(Sales[SalesAmount]), DESC))

25. Write a DAX formula to find the median sales amount per category.

MEDIANX(FILTER(ALL(Sales), Sales[Category] = MAX(Sales[Category])), Sales[SalesAmount])

26. How do you calculate the running total of sales but reset at the start of each year?

CALCULATE(SUM(Sales[SalesAmount]),
FILTER(ALL(Sales), Sales[Year] = MAX(Sales[Year]) && Sales[Date] <= MAX(Sales[Date])))

27. Write a DAX measure to find the highest revenue day for each product.

CALCULATE(MAX(Sales[SalesAmount]), ALLEXCEPT(Sales, Sales[ProductID], Sales[Date]))


28. How do you calculate the number of months since a customer’s last purchase?

DATEDIFF(CALCULATE(MAX(Sales[Date]), ALLEXCEPT(Sales, Sales[CustomerID])), TODAY(), MONTH)


29. Write a DAX formula to find the percentage of total sales for each product.

SUM(Sales[SalesAmount]) / CALCULATE(SUM(Sales[SalesAmount]), ALL(Sales))


30. How do you calculate total revenue excluding the highest and lowest 5% of transactions?

CALCULATE(SUM(Sales[SalesAmount]),
FILTER(ALL(Sales),
RANKX(ALL(Sales), Sales[SalesAmount], , ASC) > COUNTROWS(Sales) * 0.05 &&
RANKX(ALL(Sales), Sales[SalesAmount], , DESC) > COUNTROWS(Sales) * 0.05))

31.Write a DAX formula to calculate the difference between current and previous row values. 

DifferenceFromPrevious = 
Sales[SalesAmount] - 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 OFFSET(-1, Sales[SalesAmount], ORDERBY(Sales[Date], ASC))
)

32. How do you calculate the moving average of sales over the last 3 months? 

MovingAvg3Months = 
AVERAGEX(
 DATESINPERIOD(Sales[Date], MAX(Sales[Date]), -3, MONTH), 
 CALCULATE(SUM(Sales[SalesAmount]))
)

33. Write a DAX measure to count customers who made purchases in two consecutive months. 

CustomersConsecutiveMonths = 
CALCULATE(
 DISTINCTCOUNT(Sales[CustomerID]), 
 INTERSECT(
 VALUES(Sales[CustomerID]), 
 CALCULATETABLE(VALUES(Sales[CustomerID]), PREVIOUSMONTH(Sales[Date]))
 )
)


34. How do you calculate the total sales contribution of the top 5 products dynamically? 

CALCULATE(
 SUM(Sales[SalesAmount]), 
 TOPN(5, VALUES(Sales[ProductID]), SUM(Sales[SalesAmount]), DESC)
)

35. Write a DAX formula to calculate the highest sales recorded in each month. 

MaxSalesPerMonth = 
CALCULATE(
 MAX(Sales[SalesAmount]), 
 ALLEXCEPT(Sales, Sales[Month])
)

36. How do you create a dynamic ranking of products based on total sales? 

ProductRanking = 
RANKX(
 ALL(Sales[ProductID]), 
 SUM(Sales[SalesAmount]), 
 , DESC, DENSE
)


37. Write a DAX measure to calculate the cumulative total of sales but reset at the start of each quarter. 

CumulativeSalesQuarterly = 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 FILTER(
 ALL(Sales), 
 Sales[Quarter] = MAX(Sales[Quarter]) && Sales[Date] <= MAX(Sales[Date])
 )
)

38. How do you find the first purchase date of each customer? 

FirstPurchaseDate = 
CALCULATE(
 MIN(Sales[Date]), 
 ALLEXCEPT(Sales, Sales[CustomerID])
)


39. Write a DAX formula to calculate the ratio of a product’s sales to the highest-selling product’s sales. 

SalesToTopProductRatio = 
DIVIDE(
 SUM(Sales[SalesAmount]), 
 CALCULATE(MAXX(ALL(Sales), SUM(Sales[SalesAmount])))
)


40. How do you calculate total revenue excluding the bottom 10% of sales transactions?

RevenueExcludingBottom10 = 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 FILTER(
 ALL(Sales), 
 RANKX(ALL(Sales), Sales[SalesAmount], , ASC) > COUNTROWS(Sales) * 0.1
 )
)

41. How do you calculate the running total of sales in DAX?

RunningTotalSales = 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 FILTER(
 ALL(Sales[Date]), 
 Sales[Date] <= MAX(Sales[Date])
 )
)

42. Write a DAX formula to find the total sales for the last 3 months dynamically.
 
Last3MonthsSales = 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 DATESINPERIOD(Sales[Date], MAX(Sales[Date]), -3, MONTH)
)
 
43.How do you calculate the percentage contribution of each product to total sales?
SalesPercentage = 
DIVIDE(
 SUM(Sales[SalesAmount]), 
 CALCULATE(SUM(Sales[SalesAmount]), ALL(Sales))
)

44.Write a DAX measure to calculate year-over-year (YoY) growth in sales.
 
YoYGrowth = 
VAR CurrentYearSales = SUM(Sales[SalesAmount])
VAR PreviousYearSales = CALCULATE(SUM(Sales[SalesAmount]), SAMEPERIODLASTYEAR(Sales[Date]))
RETURN 
 DIVIDE(CurrentYearSales - PreviousYearSales, PreviousYearSales) 

45.How do you count distinct customers who made a purchase in the last 6 months?

DistinctCustomers6M = 
CALCULATE(
 DISTINCTCOUNT(Sales[CustomerID]), 
 DATESINPERIOD(Sales[Date], MAX(Sales[Date]), -6, MONTH)
)

46.Write a DAX formula to find the top 3 best-selling products dynamically.

Top3Products = 
TOPN(3, SUMMARIZE(Sales, Products[ProductName], "TotalSales", SUM(Sales[SalesAmount])), [TotalSales], DESC)

47.How do you calculate the average sales per customer?

AvgSalesPerCustomer = 
DIVIDE(
 SUM(Sales[SalesAmount]), 
 DISTINCTCOUNT(Sales[CustomerID])
) 

48.Write a DAX measure to display cumulative sales but reset at each year’s start.

 CumulativeSalesYearly = 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 FILTER(
 ALL(Sales), 
 Sales[Year] = MAX(Sales[Year]) && Sales[Date] <= MAX(Sales[Date])
 )
)
 
49.How do you compare the current month’s sales with the previous month’s sales?
 
SalesPreviousMonth = 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 PREVIOUSMONTH(Sales[Date])
)

50.Write a DAX formula to calculate the total revenue only for the top 10 customers.

Top10CustomerRevenue = 
CALCULATE(
 SUM(Sales[SalesAmount]), 
 TOPN(10, VALUES(Sales[CustomerID]), SUM(Sales[SalesAmount]), DESC)
)

51. Write a DAX formula to calculate the total sales made during weekends only.

CALCULATE(
SUM(Sales[SalesAmount]),
FILTER(ALL(Sales), WEEKDAY(Sales[Date], 2) >= 6))

52. How do you find customers who made exactly three purchases in a given year?

CALCULATE(
DISTINCTCOUNT(Sales[CustomerID]),
FILTER(VALUES(Sales[CustomerID]),
CALCULATE(COUNT(Sales[OrderID]), Sales[Year] = MAX(Sales[Year])) = 3))
 
53. Write a DAX measure to calculate the percentage of returning customers each month.

DIVIDE(
CALCULATE(
DISTINCTCOUNT(Sales[CustomerID]),
FILTER(ALL(Sales), Sales[Date] >= EOMONTH(MAX(Sales[Date]), -1) + 1 &&
Sales[Date] <= EOMONTH(MAX(Sales[Date]), 0) &&
Sales[CustomerID] IN VALUES(Sales[CustomerID]))),
DISTINCTCOUNT(Sales[CustomerID]))

54. How do you find the top-selling product in each month dynamically?

TOPN(1,
SUMMARIZE(ALL(Sales), Sales[Month], Sales[ProductID], “TotalSales”, SUM(Sales[SalesAmount])),
[TotalSales], DESC)

55. Write a DAX formula to calculate the running total of sales but reset when sales drop below a certain threshold.

VAR RunningTotal =
CALCULATE(
SUM(Sales[SalesAmount]),
FILTER(ALL(Sales), Sales[Date] <= MAX(Sales[Date]))
)
RETURN
IF(RunningTotal >= 1000, RunningTotal, 0)

56. How do you determine the longest gap (in days) between any two purchases for each customer?
 
MAXX(ADDCOLUMNS(Sales,“PreviousPurchase”, 
     CALCULATE(MAX(Sales[Date]), Sales[Date] < EARLIER(Sales[Date]))),
     DATEDIFF([PreviousPurchase], Sales[Date], DAY))

57. Write a DAX measure to calculate the total sales in the most recent completed month.

CALCULATE(SUM(Sales[SalesAmount])
         ,FILTER(ALL(Sales), Sales[Date] >= EOMONTH(TODAY(), -2) + 1 && Sales[Date] <= EOMONTH(TODAY(), -1)))

58. How do you identify customers whose first and last purchases were in different years?

CALCULATE(DISTINCTCOUNT(Sales[CustomerID]),
FILTER(VALUES(Sales[CustomerID]),
YEAR(CALCULATE(MIN(Sales[Date]))) <> YEAR(CALCULATE(MAX(Sales[Date])))))

59. Write a DAX formula to calculate the average revenue per order, excluding orders below the 25th percentile.

AVERAGEX(
FILTER(ALL(Sales),
Sales[SalesAmount] > PERCENTILEX.INC(ALL(Sales), Sales[SalesAmount], 0.25)),Sales[SalesAmount])

 
60. How do you find the most frequently purchased product for each customer?

TOPN(1,
SUMMARIZE(ALL(Sales), Sales[CustomerID], Sales[ProductID], “PurchaseCount”, COUNT(Sales[OrderID])),
[PurchaseCount], DESC
)
