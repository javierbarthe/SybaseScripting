USE mon_db
go
IF OBJECT_ID('dbo.monSysSqlText_collector') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monSysSqlText_collector
    IF OBJECT_ID('dbo.monSysSqlText_collector') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monSysSqlText_collector >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monSysSqlText_collector >>>'
END
go
CREATE PROCEDURE dbo.monSysSqlText_collector
AS
BEGIN
    declare @ciclos 	integer
    declare @fecha datetime
    
    set @fecha = getdate()
    
    set @ciclos =  (((23 - datepart(hh, @fecha))*60)/2)

    while (@ciclos>0)
    begin
		insert into mon_db..monSysSQLText_DB1
		select
        getdate() as Fecha,SPID, InstanceID, KPID, ServerUserID, BatchID, SequenceInBatch, SQLText
        from master..monSysSQLText
            
        select @ciclos= @ciclos-1

        waitfor delay "00:02:00"
    end
END
go
EXEC sp_procxmode 'dbo.monSysSqlText_collector', 'unchained'
go
IF OBJECT_ID('dbo.monSysSqlText_collector') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monSysSqlText_collector >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monSysSqlText_collector >>>'
go
