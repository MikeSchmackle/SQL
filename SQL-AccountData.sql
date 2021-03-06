USE [CISPROD]
GO
/****** Object:  StoredProcedure [dbo].[sp_LeakInqury]    Script Date: 3/8/2017 12:04:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_LeakInqury] as 

/*Retrieve the most recent Meter for the specified Account# */
;WITH Meters AS (
		select	c_account, 
				C_METER,
				C_REMOTEID, 
				c_service,
				C_READTYPE,
				D_DATEINSTALLED,
				C_LATITUDE,
				C_LONGITUDE,
				N_REMREADING,
				Row_number() OVER(PARTITION BY c_account ORDER BY D_dateInstalled DESC) AS SeqNo
from 
				advanced.BIF005 group by C_ACCOUNT, C_METER, C_REMOTEID, c_service, c_readtype, D_DATEINSTALLED,C_LATITUDE,C_LONGITUDE,N_REMREADING
), 
/*Retrieve the most recent Reading for the specified Account# */
Readings AS (
		select	c_account, 
				N_READING, 
				T_READDATE,
				Row_number() OVER(PARTITION BY C_ACCOUNT ORDER BY T_ReadDate DESC) AS SeqNo
from 
				advanced.BIF016 group by C_ACCOUNT, N_READING, T_READDATE
),


/***************************************************************************************************************  
    NAME:        Retrieve Customer Information Dataset 
    DESCRIPTION: Used for troubleshooting meters in the field

    -- Not registering any usage ( Stuck?)

    -- Vacant Accounts with usage.  IE Potentially a tenant that has moved in, and hasn't signed up for service
****************************************************************************************************************/


CustomerInformation as (
		select DISTINCT  
				b.C_CYCLE as Cycle,
				c.C_DESCRIPTION as 'ACCOUNT Type',
				c9.C_DESCRIPTION as Service,
				CASE  WHEN b.C_ACCOUNTSTATUS = 'AC' THEN 'ACTIVE'
					  WHEN b.C_ACCOUNTSTATUS = 'IN' THEN 'NEW SERVICE'
					  WHEN b.C_ACCOUNTSTATUS = 'OB' THEN 'REMOVED'
					  WHEN b.c_accountstatus in ('FI','VA') THEN 'VACANT'
				      ELSE b.C_ACCOUNTSTATUS
			    END AS Status,
				LTRIM ( RTRIM ( bf.C_FIRSTNAME ) + ' ' ) + LTRIM ( RTRIM ( bf.C_MIDDLENAME ) + ' ' ) + LTRIM ( RTRIM ( bf.C_LASTNAME ) + ' ' ) AS Customer,
				LTRIM ( RTRIM (b2.c_streetnum) + ' ')+LTRIM ( RTRIM ( b2.C_STREETPREFIX)+' ')+LTRIM ( RTRIM ( b2.c_street)+' ')+LTRIM ( RTRIM (b2.c_streetsuffix)+' ')as StreetAddress,
				b5.C_LATITUDE,
				b5.C_LONGITUDE,
				b.C_ACCOUNT as Account,
				b.C_CUSTOMER as CustomerNo, 
				b.C_ACCOUNTTYPE,
				b5.C_METER as Meter, 
				rtrim(ltrim(b5.C_REMOTEID)) as C_REMOTEID,
				b5.C_SERVICE as ServiceCode,
				b5.C_READTYPE,
				bs.n_reading  as Reading, 
				b5.N_REMREADING as oREading,
				--cast(bs.t_readdate as date) as 'Date of Reading',
				bs.t_readdate as 'Date of Reading', 
				--cast(b.D_MOVEIN as date) as 'Move In Date',
				b.D_MOVEIN as 'Move In Date',
				ROW_NUMBER() OVER ( PARTITION BY  B.C_account order by b.c_accountstatus, b.d_effectivedate desc ) AS SeqNo
		FROM  
				advanced.bif003 b 
		INNER JOIN
				advanced.BIF004 b4 on b.C_ACCOUNT = b4.C_ACCOUNT 
		INNER JOIN
				( select * from Meters where  SeqNo = 1 ) b5 on b5.C_ACCOUNT = b.C_ACCOUNT
		INNER JOIN 
				advanced.bif001 bf on b.C_CUSTOMER = bf.C_CUSTOMER 
		INNER JOIN
				(select * from Readings where  SeqNo = 1) bs on bs.C_ACCOUNT = b.C_ACCOUNT  
        INNER JOIN 
				advanced.con009 c9 on b5.c_service = c9.C_SERVICE
        INNER JOIN 
			    advanced.BIF002 B2 on b2.C_ACCOUNT = b.C_ACCOUNT
        INNER JOIN 
				advanced.CON013 c on c.C_ACCOUNTTYPE = b.C_ACCOUNTTYPE
	
)

/***************************************************************************************************************  
    NAME:        Retrieve Customer Information Dataset 
    DESCRIPTION: Used for troubleshooting meters in the field

    -- Not registering any usage ( Stuck?)

    -- Vacant Accounts with usage.  IE Potentially a tenant that has moved in, and hasn't signed up for service
****************************************************************************************************************/

SELECT *
FROM 
			CustomerInformation
WHERE 
			SeqNo = 1  and servicecode not in ('40','50') order by CYCLE, Service, STATUS, Reading