USE mon_db
go
IF OBJECT_ID('dbo.monBloqueos_collector_DB1') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monBloqueos_collector_DB1
    IF OBJECT_ID('dbo.monBloqueos_collector_DB1') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monBloqueos_collector_DB1 >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monBloqueos_collector_DB1 >>>'
END
go
CREATE PROCEDURE dbo.monBloqueos_collector_DB1
AS
BEGIN
                set nocount on                     
                declare @var INT
                                
                create table #sysproc
                (
				Fecha DATETIME not null,
				Spid int null,
				Kpid int null, 
				WaitEventID int null,
				Suid int null,
				Id int null,
				Hostname varchar(30) null, 
				Program_name varchar(30) null,
				Cmd varchar(30) null,
				Blocked int null,
				Dbid  smallint null,
				Tran_name varchar(64) null,
				Time_blocked int null,   
				Linenum int null,
				Loggedindatetime datetime  null,
				Ipaddr varchar(64)  null,
                )

                create table #bloquados_bloqueantes
                (
                SPID int not null,
                kpid int not null,
                linenumber int not null,
                blocked int  null,
                blockingKPID int null,
                )
                                
                create table #sqltext(
                  SPID   int  not null,
                  KPID   int  not null,
                  ServerUserID   int  not null,
                  LineNumber   int  not null,
                  SQLText   varchar(255)  null
                )
                
                create  table #monBloqueos_dba_db1_sqltext(
                   Fecha datetime not null,
                   SPID   int  not null,
                   KPID   int  not null,
                   ServerUserID   int  not null,
                   LineNumber   int  not null,
                   SQLText   varchar(255)  null
                )
                
    while (1=1)
    begin

	--CARGO TABLA
	declare @fecha DATETIME
	select @fecha = getdate()
	insert into #sysproc
	select 
	@fecha as Fecha,
	mp.spid, 
	mp.kpid, 
	mp.WaitEventID, 
	mp.serveruserid,
	mps.ProcedureID as id, 
	mp.hostname, 
	mp.application, 
	mp.command,
	case when isnull(mp.blockingspid,0) = 0
	     then 0
	     else mp.blockingspid
	     end as blockingspid, 	 	 
	mp.dbid, 
	mp.MasterTransactionID, 
	case when isnull(mp.blockingspid,0) = 0
	     then null
	     else mp.SecondsWaiting
	     end as SecWaiting, 
	mp.LineNumber, 
	DATEADD(ss, -mp.SecondsConnected, getdate()) loggedindatetime,   
	mpl.clientip as ipaddr
	from master..monprocess mp

	inner join master..monprocesslookup mpl
	on mp.spid = mpl.spid
	
	left join master..monprocessstatement mps
	on mp.spid = mps.spid
	
	left join (select
	bk_process.blockingspid,
	max(bk_process.SecondsWaiting) time_blocked
	from master..monprocess bk_process
	where bk_process.blockingspid > 0
	and bk_process.WaitEventID = 150
	group by bk_process.blockingspid
	) bk_process
	on bk_process.blockingspid = mp.spid

	where   (mp.blockingspid > 0 
	and mp.SecondsWaiting > 0
	and mp.WaitEventID = 150
	)
	or bk_process.blockingspid is not null
	
	
	
	
   while exists(Select 1 from #sysproc )
                               begin
                               
                               
                               select @fecha = getdate()
                               
                               insert into #sqltext
                               select SPID,
                               kpid,
                               ServerUserID,
                               LineNumber,
                               SQLText
                               from master..monProcessSQLtext
                               
                                               --CARGO TABLA #BLOQUEADOS_BLOQUEANTES 
                                               --cargo bloqueantes                      
                                               
                                               insert into #bloquados_bloqueantes
                                               select 
                                               blocked as SPID,
                                               1 as kpid,
                                               2 as linenumber,
                                               blocked = null,
                                               blockingKPID = null
                                               from #sysproc
                                               where blocked > 0
                                               group by blocked
                                               
                                               --updateo bloqueado    kpid
                               
                                               update #bloquados_bloqueantes
                                                               set kpid = procs.kpid
                                                               
                                               from #sysproc procs
                                               where procs.spid = #bloquados_bloqueantes.spid
                                               
                                               --updateo linenumber
                               
                                               update #bloquados_bloqueantes
                                                               set linenumber = procs.linenum
                                               from #sysproc procs
                                               where procs.spid = #bloquados_bloqueantes.spid
                               
                                               --cargo bloqueados        
                                               
                                               insert into #bloquados_bloqueantes
                                               select
                                                               spid,kpid,linenum,blocked,null
                                               from #sysproc 
                                               where blocked in (select SPID from #bloquados_bloqueantes)
                                               
                                               --FIN CARGO TABLA #BLOQUEADOS_BLOQUEANTES
                                               
                                               -- update blocked KPID
                                               
                                               update #bloquados_bloqueantes
                                                               set blockingKPID = #sysproc.kpid
                                               from #sysproc 
                                               where #sysproc.spid = #bloquados_bloqueantes.blocked
                                               
                                               
                                               -- update tiempo             
                                               
                                               update mon_db..monBloqueos_dba_db1
                               
                                                                               set time_blocked=procs.time_blocked
                               
                                               from #bloquados_bloqueantes block
                                                               
                                                               inner join #sysproc procs
                                                               on  procs.spid = block.spid
                                                               and procs.kpid = block.kpid
                                                               and procs.Linenum = block.linenumber
                                                               and procs.time_blocked > 0
                                                               
                                               where block.spid = mon_db..monBloqueos_dba_db1.spid
                                                               and block.kpid = mon_db..monBloqueos_dba_db1.kpid
                                                               and block.linenumber = mon_db..monBloqueos_dba_db1.linenum
                                                               and block.blocked = mon_db..monBloqueos_dba_db1.blocked
                               
                               -- insert 
                               
                                               insert into mon_db..monBloqueos_dba_db1
                                               select                                                   
                                                               sysproc.Fecha,
															   datepart(yy,sysproc.Fecha),
                                                               datepart(mm,sysproc.Fecha),
                                                               datepart(wk,sysproc.Fecha),
                                                               datepart(dd,sysproc.Fecha),
                                                               datepart(hh,sysproc.Fecha),
                                                               datepart(mi,sysproc.Fecha),
                                                               sysproc.spid, 
                                                               sysproc.kpid, 
                                                               sysproc.WaitEventID, 
                                                               sysproc.suid, 
                                                               sysproc.hostname, 
                                                               sysproc.program_name, 
                                                               sysproc.cmd, 
                                                               sysproc.blocked, 
                                                               bloq.blockingKPID,
                                                               sysproc.dbid, 
                                                               sysproc.tran_name, 
                                                               sysproc.time_blocked, 
                                                               sysproc.linenum, 
                                                               sysproc.loggedindatetime, 
                                                               sysproc.ipaddr,  
                                                               suser_name(sysproc.suid) as 'Usser', 
                                                               db_name(sysproc.dbid) as 'Base',
                                                               object_name(sysproc.id,sysproc.dbid) as 'SP'
                                                               
                                                               from #sysproc sysproc
                                               
                                                                               inner join #bloquados_bloqueantes bloq
                                                                               on bloq.SPID = sysproc.spid
                                                                               and bloq.KPID = sysproc.kpid
                                                                               and bloq.linenumber = sysproc.linenum
                                               
                                                                               left join mon_db..monBloqueos_dba_db1 monblock
                                                                               on monblock.spid = sysproc.spid              
                                                                               and monblock.kpid = sysproc.kpid           
                                                                               and monblock.linenum = sysproc.linenum          
                                                                               and monblock.blocked = sysproc.blocked
                                                               
                                                               where monblock.spid is null
                                               
                               
                                               --insert monbloqueos_sqltext
                                               
                                               
                                               insert into #monBloqueos_dba_db1_sqltext
                                                                               select    
                                                                                  @fecha as Fecha,
                                                                                  a.SPID, 
                                                                                  a.kpid, 
                                                                                  a.ServerUserID,
                                                                                  a.LineNumber,
                                                                                  a.SQLText
                                                                               from #sqltext a                 
                                               inner join #bloquados_bloqueantes b
                                               on b.spid = a.SPID
                                               and b.kpid = a.KPID
                                               order by a.spid asc

                                               insert into monBloqueos_dba_db1_sqltext
                                                                               select
                                                                                  @fecha as Fecha, 
                                                                                  a.SPID, 
                                                                                  a.kpid, 
                                                                                  a.ServerUserID,
                                                                                  a.LineNumber,
                                                                                  a.SQLText
                                                                               from #monBloqueos_dba_db1_sqltext a                             
                                               left join monBloqueos_dba_db1_sqltext b
                                               on b.spid = a.SPID
                                               and b.kpid = a.KPID
                                               where b.spid is null

                                               truncate table #sysproc
                                               
                                               waitfor delay "00:00:02"                                                             
								
												--CARGO TABLA
												
												
												select @fecha = getdate()
												insert into #sysproc
												select 
												@fecha as Fecha,
												mp.spid, 
												mp.kpid, 
												mp.WaitEventID, 
												mp.serveruserid,
												mps.ProcedureID as id, 
												mp.hostname, 
												mp.application, 
												mp.command, 
												case when isnull(mp.blockingspid,0) = 0
												then 0
												else mp.blockingspid
												end as blockingspid, 	 	 
												mp.dbid, 
												mp.MasterTransactionID, 
												case when isnull(mp.blockingspid,0) = 0
													 then null
													 else mp.SecondsWaiting
													 end as SecWaiting, 
												mp.LineNumber, 
												DATEADD(ss, -mp.SecondsConnected, getdate()) loggedindatetime,   
												mpl.clientip as ipaddr
												from master..monprocess mp
											
												inner join master..monprocesslookup mpl
												on mp.spid = mpl.spid
												
												left join master..monprocessstatement mps
												on mp.spid = mps.spid
												
												left join (select
												bk_process.blockingspid,
												max(bk_process.SecondsWaiting) time_blocked
												from master..monprocess bk_process
												where bk_process.blockingspid > 0
												and bk_process.WaitEventID = 150
												group by bk_process.blockingspid
												) bk_process
												on bk_process.blockingspid = mp.spid
											
												where   (mp.blockingspid > 0 
												and mp.SecondsWaiting > 0
												and mp.WaitEventID = 150
												)
												or bk_process.blockingspid is not null
                                               
                                               truncate table #bloquados_bloqueantes
                                               truncate table #monBloqueos_dba_db1_sqltext
                                               truncate table #sqltext
                               END
                                             
                if ( datepart(hh,getdate()) = 05)
                begin
                               break
                end
                               
        waitfor delay "00:05:00"
    end
END
go
EXEC sp_procxmode 'dbo.monBloqueos_collector_DB1', 'unchained'
go
IF OBJECT_ID('dbo.monBloqueos_collector_DB1') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monBloqueos_collector_DB1 >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monBloqueos_collector_DB1 >>>'
go
