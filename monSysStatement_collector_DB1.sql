USE mon_db
go
IF OBJECT_ID('dbo.monSysStatement_collector_DB1') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monSysStatement_collector_DB1
    IF OBJECT_ID('dbo.monSysStatement_collector_DB1') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monSysStatement_collector_DB1 >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monSysStatement_collector_DB1 >>>'
END
go
CREATE PROCEDURE dbo.monSysStatement_collector_DB1
AS
BEGIN
    declare @ciclos            integer
    declare @p_logicalread integer
    declare @fecha datetime
    
    set  @p_logicalread = 5000 
    set @fecha = getdate()
    
    set @ciclos =  (((23 - datepart(hh, @fecha))*60*60)/30)

    while (@ciclos>0)
    begin
         insert into monSysStatement_dba_db1
         select     
            DB_NAME(master..monSysStatement.DBID) as Base,
            OBJECT_NAME(ProcedureID,master..monSysStatement.DBID) as SP,
            SUSER_NAME(sp.ServerUserID) as Usuario,
            sp.HostName,
            sp.Application,
            master..monSysStatement.SPID,
            master..monSysStatement.KPID,
            master..monSysStatement.DBID,
            master..monSysStatement.ProcedureID,
            master..monSysStatement.PlanID,
            master..monSysStatement.BatchID,
            master..monSysStatement.ContextID,
            master..monSysStatement.LineNumber,
            master..monSysStatement.CpuTime,
            master..monSysStatement.WaitTime,
            master..monSysStatement.MemUsageKB,
            master..monSysStatement.PhysicalReads,
            master..monSysStatement.LogicalReads,
            master..monSysStatement.PagesModified,
            master..monSysStatement.PacketsSent,
            master..monSysStatement.PacketsReceived,
            master..monSysStatement.NetworkPacketSize,
            master..monSysStatement.PlansAltered,
            master..monSysStatement.RowsAffected,
            master..monSysStatement.ErrorStatus,
            master..monSysStatement.StartTime,
            master..monSysStatement.EndTime
--            into mon_db..monSysStatement_dba
            from master..monSysStatement, master..monprocess sp
            where (master..monSysStatement.LogicalReads > @p_logicalread -- 5000
                  or master..monSysStatement.WaitTime > 0
                  or master..monSysStatement.PhysicalReads > 100    
                  or master..monSysStatement.CpuTime > 1000  ) and 
                  master..monSysStatement.SPID *= sp.spid and
                  master..monSysStatement.KPID *= sp.kpid
            and DB_NAME(master..monSysStatement.DBID) not in ('sybsystemprocs')
          
        select @ciclos= @ciclos-1

        waitfor delay "00:00:30"
    end
END
go
EXEC sp_procxmode 'dbo.monSysStatement_collector_DB1', 'unchained'
go
IF OBJECT_ID('dbo.monSysStatement_collector_DB1') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monSysStatement_collector_DB1 >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monSysStatement_collector_DB1 >>>'
go
