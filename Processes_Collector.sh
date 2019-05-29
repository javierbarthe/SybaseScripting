#!/usr/bin/ksh

#insert into monSysProcesses_1
#select 
#getdate() as Fecha ,a.spid,a.kpid,object_name(b.ProcedureID,a.dbid) as SP,a.BlockingSPID,a.EngineNumber,a.WaitEventID,a.ServerUserID,a.HostName,a.Application,a.command,b.cputime,b.LineNumber,b.PhysicalReads,b.LogicalReads,a.dbname,a.login,a.SecondsConnected,c.ClientIP 
#from master..monprocess a
#inner join master..monprocessstatement b
#on a.spid = b.spid
#inner join master..monprocesslookup c
#on a.spid = c.spid
#where a.Application <> "isql - control sysprocesses"

. /sybase/SYBASE.sh > /dev/null 2>&1

User=`grep -E "USER" /home/sybase/params.txt | awk '{print $2}'`
Pass=`grep -E "PASS" /home/sybase/params.txt | awk '{print $2}'`
Srv=`grep -E "SERVER_5200" /home/sybase/params.txt | awk '{print $2}'`

PathControl=/home/sybase/controles/sysprocesses/

#---------------------------------------------Control-de-reproceso--------------------------------------------------------------
IDProcess=`echo $$`
ProcessName=sysprocesses.sh

#Obtengo el PID de Cron, en caso de ser varios los concateno con un | para luego poder usarlos en el EGREP
CronID=`ps -ef | grep '/usr/sbin/cron' | grep -v grep | awk '{print$2}'`
CronID=`echo ${CronID} | sed 's/ /\|/g'`

#Calculo Cuantos procesos son ejecutados por cron
#CountProcess=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | wc -l | awk '{print $1}'`
CountProcessConCron=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | egrep ${CronID} | grep -v grep | wc -l`
UserExecutor=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | awk '{print $1}'`
ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep > /home/sybase/controles/sysprocesses/CountProcess.tmp
CountProcess=` wc -l /home/sybase/controles/sysprocesses/CountProcess.tmp | awk '{print $1}'`
echo $CountProcess

if [[ ${CountProcess} -gt 2 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} en ejecucion por usuario ${UserExecutor} >> /home/sybase/controles/sysprocesses/ControlReEjecucion.log
exit
fi

if [[ ${CountprocessConCron} -gt 2 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} Usuario ejecutando: cron >> /home/sybase/controles/sysprocesses/ControlReEjecucion.log
exit
fi
#-------------------------------------------------------------------------------------------------------------------------------


isql -U${User} -P${Pass} -S${Srv} -i/home/sybase/controles/sysprocesses/sysprocesses.sql -o/home/sybase/controles/sysprocesses/sysprocesses.out -w1000 -Jiso_1 --appname 'isql - control sysprocesses'

