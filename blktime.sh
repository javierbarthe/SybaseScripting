#!/usr/bin/ksh
#
# proceso.sql
#IF OBJECT_ID('dbo.blktime') IS NOT NULL
#BEGIN
#    DROP PROCEDURE dbo.blktime
#    IF OBJECT_ID('dbo.blktime') IS NOT NULL
#        PRINT '<<< FAILED DROPPING PROCEDURE dbo.blktime >>>'
#    ELSE
#        PRINT '<<< DROPPED PROCEDURE dbo.blktime >>>'
#END
#go
#create procedure dbo.blktime
#as     
#	set nocount on     
#	declare @var INT
#	declare @block INT
#
#	select a.SPID, a.InstanceID, a.KPID, a.ServerUserID, a.OrigServerUserID, a.BatchID, a.ContextID, a.LineNumber, a.SecondsConnected, a.DBID, a.EngineNumber, a.Priority, a.FamilyID, a.[Login], a.Application, a.Command, a.NumChildren, a.SecondsWaiting, a.WaitEventID, a.BlockingSPID, a.BlockingXLOID, a.DBName, a.EngineGroupName, a.ExecutionClass, a.MasterTransactionID, a.HostName, a.ClientName, a.ClientHostName, a.ClientApplName,b.clientip 
#	into #tmp1
#	from master..monprocess a
#	inner join master..monprocesslookup b
#	on a.spid = b.spid
#	and a.kpid = b.kpid
#
#	   
#	select @var=(Select count(spid) from #tmp1 where BlockingSPID is not null and SecondsWaiting > 120 and WaitEventID = 150)	  
#	select @block=(Select count(spid) from #tmp1 where BlockingSPID is not null and SecondsWaiting > 3599 and WaitEventID = 150) 
#		
#	if (@block > 0)
#	BEGIN
#		
# 		select 'ALERTA BLOQUEOS > 1 hora' 
# 		select ' '
# 		select SecondsWaiting as TiempoBloqueado
# 		from #tmp1
#		where SecondsWaiting > 3599
#		and WaitEventID = 150
#		and BlockingSPID is not null
#		select ' '
#	END  
# 
#	if (@var > 0)     
#	BEGIN     
#		-- Lista las bases donde hay lockeos   
#		set nocount on   
#		select  distinct DBName as 'Hay bloqueos en las DBs'    
#		from #tmp1
#		where WaitEventID = 150 and BlockingSPID is not null     
#   
#		select ' '     
#   
#		-- Lista la cantidad total de procesos locked   
#		set nocount on    
#		select count (*) as "Cant Proc Bloqueados" from #tmp1 where BlockingSPID is not null 
#		   
#		select ' '     
#   
#		-- Lista los procesos lockeados por SPID   
#		set nocount on    
#		select 	convert(varchar(16),(select a.clientip from #tmp1 a where a.spid = b.BlockingSPID)) "IP Address",   
#				 b.BlockingSPID SPID, b.DBName Base, count (b.BlockingSPID) "Proc Bloq por SPID"    
#		from #tmp1 b    
#		where b.BlockingSPID <> 0    
#		group by b.BlockingSPID , dbid   
#   
#		select ' '    
#   
# 		set nocount on    
#		select 'Detalle SPIDs bloqueados'     
#		select ' '    
#		select a.spid,a.login,a.command,b.ObjectName,a.dbname,a.application,a.clientip,a.blockingspid,a.secondswaiting as tiempo_bloqueado from #tmp1 a
#		left join master..monProcessProcedures b
#		on a.spid = b.spid
#		where a.BlockingSPID is not null and a.WaitEventID = 150    
#	END   
#     
#	DECLARE abc CURSOR FOR     
#	select distinct BlockingSPID from #tmp1 where BlockingSPID is not null 
#    
#	if (@var > 0)     
#	BEGIN     
#		declare @Count INT     
#		select @Count = count(distinct BlockingSPID) from #tmp1     
#		if( @Count > 0 )     
#		BEGIN     
#				open abc     
#				declare @SPID int     
#				declare @KPID int     
#				declare @showplan varchar(255)     
#				fetch abc into @SPID    
#				while (@@sqlstatus = 0)       
#				BEGIN     
#					select 'Detalles SPIDs que genera los bloqueos'     
#					select ' '    
#					select a.spid,a.login,a.command,b.ObjectName,a.dbname,a.application,a.clientip,a.blockingspid 
#					from #tmp1 a
#					left join master..monProcessProcedures b
#					on a.spid = b.spid
#					where a.spid = @SPID  
#									
#					fetch abc into @SPID   
#					select ' '     
#					select ' '     
#				END     
#			CLOSE abc     
#			DEALLOCATE cursor abc     
#		END     
#	END     
#	ELSE     
#		BEGIN     
#			DEALLOCATE cursor abc     
#		END
#go
#EXEC sp_procxmode 'dbo.blktime', 'unchained'
#go
#IF OBJECT_ID('dbo.blktime') IS NOT NULL
#    PRINT '<<< CREATED PROCEDURE dbo.blktime >>>'
#ELSE
#    PRINT '<<< FAILED CREATING PROCEDURE dbo.blktime >>>'
#go
export LANG="en_US"
. $SYBASE/SYBASE.sh > /dev/null 2>&1

#---------------------------------------------Control-de-reproceso--------------------------------------------------------------
IDProcess=`echo $$`
ProcessName=blktime.sh

#Obtengo el PID de Cron, en caso de ser varios los concateno con un | para luego poder usarlos en el EGREP
CronID=`ps -ef | grep '/usr/sbin/cron' | grep -v grep | awk '{print$2}'`
CronID=`echo ${CronID} | sed 's/ /\|/g'`

#Calculo Cuantos procesos son ejecutados por cron

CountProcessConCron=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | egrep ${CronID} | grep -v grep | wc -l`
UserExecutor=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | awk '{print $1}'`

ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep > $CONTROLES/blktime/CountProcess.tmp
CountProcess=`wc -l $CONTROLES/blktime/CountProcess.tmp | awk '{print $1}'`

if [[ ${CountProcess} -gt 1 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} en ejecucion por usuario ${UserExecutor} >> $CONTROLES/blktime/ControlReEjecucion.log
exit
fi

if [[ ${CountprocessConCron} -gt 1 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} Usuario ejecutando: cron >> $CONTROLES/blktime/ControlReEjecucion.log
exit
fi
#-------------------------------------------------------------------------------------------------------------------------------

User=`grep -E "USER" /home/sybase/params.txt | awk '{print $2}'`
Pass=`grep -E "PASS" /home/sybase/params.txt | awk '{print $2}'`
Srv=`grep -E "SERVER_5200" /home/sybase/params.txt | awk '{print $2}'`

isql -U${User} -P${Pass} -S${Srv} -i$CONTROLES/blktime/proceso.sql -o$CONTROLES/blktime/blktime.out -w500 -Jiso_1

HAY=`grep -E "Hay bloqueos" $CONTROLES/blktime/blktime.out | awk '{print $1}'`

if [ ! -z $HAY ]
then
                print "." >> $CONTROLES/blktime/blktime.out
                mail -s "${Srv} - BLK PROC" dba@mail.com.ar < $CONTROLES/blktime/blktime.out
fi
