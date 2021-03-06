USE [CISPROD]
GO
/****** Object:  StoredProcedure [dbo].[sp_BillHistory]    Script Date: 3/8/2017 12:03:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_BillHistory]
as
;with MonthlyCycleBillCounts as (
select 
  year(d_billdate) as 'Year',
  month(d_billdate) as 'Month',
  st.C_CYCLE as 'BillCycle',
   sum(CASE st.C_BILLTYPE 
    WHEN 'CB' THEN st.sub_totals*-1 
  ELSE  
    st.sub_totals
  END) as BillTotals 
  from(
     select count(*)as sub_totals,c_billtype, c_Cycle, D_BILLDATE from advanced.bif951_c where c_billtype not in ('FB','AF') and year(d_billdate)>1991  group by c_billtype, c_cycle, D_BILLDATE ) st group by year(d_billdate), month(d_billdate),C_CYCLE 
	 )

SELECT Year, 
		CASE Month
		WHEN '1' then 'January'
		WHEN '2' then 'February'
		WHEN '3' then 'March'
		WHEN '4' then 'April'
		WHEN '5' then 'May'
		WHEN '6' then 'June'
		WHEN '7' then 'July'
		WHEN '8' then 'August'
		WHEN '9' then 'September'
		WHEN '10' then 'October'
		When '11' then 'November'
		WHEN '12' then 'Devember'
		END as Month_DSP,
        [01] AS 'Cycle 1', [02] AS 'Cycle 2', [03] AS 'Cycle 3', [04] AS 'Cycle 4', [05] AS 'Cycle 5', [06] AS 'Cycle 6', [07] AS 'Cycle 7'--, [08] as 'CUD', [99] as 'NOT SURE'
FROM 
MonthlyCycleBillCounts ps
PIVOT
(
SUM (ps.BillTotals)
FOR BillCycle IN
( [01],[02],[03],[04],[05],[06],[07])--,[08],[99])
) AS pvt order by Year, Month