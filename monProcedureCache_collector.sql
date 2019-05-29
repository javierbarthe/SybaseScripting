USE mon_db
go
IF OBJECT_ID('dbo.monProcedureCache_collector') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monProcedureCache_collector
    IF OBJECT_ID('dbo.monProcedureCache_collector') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monProcedureCache_collector >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monProcedureCache_collector >>>'
END
go
CREATE PROCEDURE dbo.monProcedureCache_collector
AS
BEGIN
 while (1=1)
    begin
	insert into mon_db..monProcedureCache_dba_DB1	
	select 
	b.DBName, 
	b.ObjectName,
	b.ObjectType
	from master..monCachedProcedures b
         
    left join mon_db..monProcedureCache_dba_DB1 mpc
    on mpc.DBName = b.DBName              
    
    where mpc.DBName is null
     and mpc.ObjectName is null
     and b.DBname not in ('master','mon_db','model')
     and b.DBname not like 'temp%'
     and b.DBname not like 'sybs%'     
    
    group by 
    b.DBName, 
	b.ObjectName,
	b.ObjectType
	
	waitfor delay "00:30:00"
    end
END
go
EXEC sp_procxmode 'dbo.monProcedureCache_collector', 'unchained'
go
IF OBJECT_ID('dbo.monProcedureCache_collector') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monProcedureCache_collector >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monProcedureCache_collector >>>'
go
