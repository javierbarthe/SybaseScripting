CREATE PROCEDURE dbo.WorkLoadCapture
(
	@catindad_seg_x_ciclo	int,
	@cantidad_minutos		int,
	@p_logicalread 			integer -- parametro de logical reads
)
AS
BEGIN
    
    declare @fecha datetime
    declare @sql varchar(5000)
    declare @trazaid char(8)
    declare @hora char(2)
    declare @cantidad_ciclo_act		int,
			@cantidad_ciclo_tot		int,
			@cilcos_x_minuto		int,
			@WAITFOR_DELAY			varchar(100)
    
    if @p_logicalread is null
	begin
		set @p_logicalread = 5000 
	end
	
	if @catindad_seg_x_ciclo is null 
	begin
		set @catindad_seg_x_ciclo	= 30
	end
	
	if @cantidad_minutos is null
	begin
		set @cantidad_minutos		= 120
	end
	
    set @fecha = getdate()
    set @trazaid = convert(varchar,getdate(),112)
    set @hora = convert(char(2),datepart(hh, @fecha))
    
    	
	set @cilcos_x_minuto = 60 /*60seg=1min*/ / @catindad_seg_x_ciclo
	
	set @cantidad_ciclo_act = 0
	set @cantidad_ciclo_tot = @cantidad_minutos * @cilcos_x_minuto --(cilcos)
	
	set @WAITFOR_DELAY = 'WAITFOR DELAY ''<hora>:<minuto>:<segundos>'''
	
	set @WAITFOR_DELAY = str_replace(@WAITFOR_DELAY,'<hora>','00')
	set @WAITFOR_DELAY = str_replace(@WAITFOR_DELAY,'<minuto>','00')
	
	set @WAITFOR_DELAY = str_replace(@WAITFOR_DELAY,'<segundos>', case when CHAR_LENGTH(cast(@catindad_seg_x_ciclo as varchar(2))) = 2 
																	then cast(@catindad_seg_x_ciclo as varchar(2) )
																	else '0'+cast(@catindad_seg_x_ciclo as varchar(1) )
																	end 
							)
    
    
   create table #monsysstatmp(
							   SPID   int  not null,
							   InstanceID   tinyint  not null,
							   KPID   int  not null,
							   DBID   int  not null,
							   ProcedureID   int  not null,
							   PlanID   int  not null,
							   BatchID   int  not null,
							   ContextID   int  not null,
							   LineNumber   int  not null,
							   CpuTime   int  not null,
							   WaitTime   int  not null,
							   MemUsageKB   int  not null,
							   PhysicalReads   int  not null,
							   LogicalReads   int  not null,
							   PagesModified   int  not null,
							   PacketsSent   int  not null,
							   PacketsReceived   int  not null,
							   NetworkPacketSize   int  not null,
							   PlansAltered   int  not null,
							   RowsAffected   int  not null,
							   ErrorStatus   int  not null,
							   HashKey   int  not null,
							   SsqlId   int  not null,
							   ProcNestLevel   int  not null,
							   StatementNumber   int  not null,
							   DBName   varchar(30)  null,
							   StartTime   datetime  null,
							   EndTime   datetime  null
							)
    
    create table #monsyssqltmp(
							   SPID   int  not null,
							   InstanceID   tinyint  not null,
							   KPID   int  not null,
							   ServerUserID   int  not null,
							   BatchID   int  not null,
							   SequenceInBatch   int  not null,
							   SQLText   varchar(255)  null
							 )


	set @sql = 'create table monsysstatement_'+@trazaid+@hora+'(
							   SPID   int  not null,
							   InstanceID   tinyint  not null,
							   KPID   int  not null,
							   DBID   int  not null,
							   ProcedureID   int  not null,
							   PlanID   int  not null,
							   BatchID   int  not null,
							   ContextID   int  not null,
							   LineNumber   int  not null,
							   CpuTime   int  not null,
							   WaitTime   int  not null,
							   MemUsageKB   int  not null,
							   PhysicalReads   int  not null,
							   LogicalReads   int  not null,
							   PagesModified   int  not null,
							   PacketsSent   int  not null,
							   PacketsReceived   int  not null,
							   NetworkPacketSize   int  not null,
							   PlansAltered   int  not null,
							   RowsAffected   int  not null,
							   ErrorStatus   int  not null,
							   HashKey   int  not null,
							   SsqlId   int  not null,
							   ProcNestLevel   int  not null,
							   StatementNumber   int  not null,
							   DBName   varchar(30)  null,
							   StartTime   datetime  null,
							   EndTime   datetime  null
							)'

	exec (@sql)
	
	set @sql = 'create table monsyssqltext_'+@trazaid+@hora+'(
							   SPID   int  not null,
							   InstanceID   tinyint  not null,
							   KPID   int  not null,
							   ServerUserID   int  not null,
							   BatchID   int  not null,
							   SequenceInBatch   int  not null,
							   SQLText   varchar(255)  null
							 )'
							 
	exec (@sql)
    
    set @cantidad_ciclo_act = 1
    
    while @cantidad_ciclo_act <= @cantidad_ciclo_tot
    begin
    	
    	truncate table #monsysstatmp
    	truncate table #monsyssqltmp
    	
    	insert into #monsysstatmp select [master]..monsysstatement.SPID, [master]..monsysstatement.InstanceID, [master]..monsysstatement.KPID, [master]..monsysstatement.DBID, [master]..monsysstatement.ProcedureID, [master]..monsysstatement.PlanID, [master]..monsysstatement.BatchID, [master]..monsysstatement.ContextID, [master]..monsysstatement.LineNumber, [master]..monsysstatement.CpuTime, [master]..monsysstatement.WaitTime, [master]..monsysstatement.MemUsageKB, [master]..monsysstatement.PhysicalReads, [master]..monsysstatement.LogicalReads, [master]..monsysstatement.PagesModified, [master]..monsysstatement.PacketsSent, [master]..monsysstatement.PacketsReceived, [master]..monsysstatement.NetworkPacketSize, [master]..monsysstatement.PlansAltered, [master]..monsysstatement.RowsAffected, [master]..monsysstatement.ErrorStatus, [master]..monsysstatement.HashKey, [master]..monsysstatement.SsqlId, [master]..monsysstatement.ProcNestLevel, [master]..monsysstatement.StatementNumber, [master]..monsysstatement.DBName, [master]..monsysstatement.StartTime, [master]..monsysstatement.EndTime from master..monsysstatement
    	
    	insert into #monsyssqltmp select [master]..monsyssqltext.SPID, [master]..monsyssqltext.InstanceID, [master]..monsyssqltext.KPID, [master]..monsyssqltext.ServerUserID, [master]..monsyssqltext.BatchID, [master]..monsyssqltext.SequenceInBatch, [master]..monsyssqltext.SQLText from master..monsyssqltext
    	
    	set @sql = 'insert into monsysstatement_'+@trazaid+@hora+' select a.* from #monsysstatmp a where (a.LogicalReads > @p_logicalread
																								or a.WaitTime > 0
																								or a.PhysicalReads > 100    
																								or a.CpuTime > 1000 ) '
      	exec (@sql)
    	
    	set @sql = 'insert into monsyssqltext_'+@trazaid+@hora+' select b.* from #monsyssqltmp b inner join #monsysstatmp a on b.SPID = a.SPID and b.KPID = a.KPID and b.BatchID = a.BatchID
					where (a.LogicalReads > @p_logicalread or a.WaitTime > 0 or a.PhysicalReads > 100 or a.CpuTime > 1000  )'
    	
    	exec (@sql)
    	  
        set @cantidad_ciclo_act = @cantidad_ciclo_act + 1
	
		set @sql = @WAITFOR_DELAY
				
		exec (@sql)		
		
    end
END
go