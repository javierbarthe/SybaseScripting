#!/usr/bin/ksh

export LANG="en_US"
. /sybase/SYBASE.sh > /dev/null 2>&1

#---------------------------------------------Control-de-reproceso--------------------------------------------------------------
IDProcess=`echo $$`
ProcessName=ConnControl.sh

#Obtengo el PID de Cron, en caso de ser varios los concateno con un | para luego poder usarlos en el EGREP
CronID=`ps -ef | grep '/usr/sbin/cron' | grep -v grep | awk '{print$2}'`
CronID=`echo ${CronID} | sed 's/ /\|/g'`

#Calculo Cuantos procesos son ejecutados por cron
#CountProcess=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | wc -l | awk '{print $1}'`
CountProcessConCron=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | egrep ${CronID} | grep -v grep | wc -l`
UserExecutor=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | awk '{print $1}'`
ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep > /home/sybase/controles/ConnectionsControl/CountProcess.tmp
CountProcess=` wc -l /home/sybase/controles/ConnectionsControl/CountProcess.tmp | awk '{print $1}'`
echo $CountProcess

if [[ ${CountProcess} -gt 2 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} en ejecucion por usuario ${UserExecutor} >> /home/sybase/controles/ConnectionsControl/ControlReEjecucion.log
exit
fi

if [[ ${CountprocessConCron} -gt 2 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} Usuario ejecutando: cron >> /home/sybase/controles/ConnectionsControl/ControlReEjecucion.log
exit
fi
#-------------------------------------------------------------------------------------------------------------------------------

PathControl=/home/sybase/controles/ConnectionsControl/

User=`grep -E "USER" /home/sybase/params.txt | awk '{print $2}'`
Pass=`grep -E "PASS" /home/sybase/params.txt | awk '{print $2}'`
Srv=`grep -E "SERVER_5200" /home/sybase/params.txt | awk '{print $2}`

echo 'set nocount on'					 > ${PathControl}Conn.isql
echo 'GO'						>> ${PathControl}Conn.isql
echo 'sp_monitorconfig "number of user connection"'	>> ${PathControl}Conn.isql
echo 'GO'						>> ${PathControl}Conn.isql


isql -U${User} -P${Pass} -S${Srv} -i${PathControl}Conn.isql -o${PathControl}Conn.out -Jiso_1 -b

Porcen=`more ${PathControl}Conn.out | tail -3 | head -1 | awk '{print $7}' | cut -f1 -d.`

if [[ ${Porcen} -ge 90 ]]; then	

	echo 'set nocount on'												 > ${PathControl}Count.isql
	echo 'GO'													>> ${PathControl}Count.isql
	echo 'select top 20 suser_name(suid) as "Usuario", db_name(dbid) as "Base", hostname, '				>> ${PathControl}Count.isql
	echo 'IPaddr as "IP Address", count(suid) as "Cantidad Conn" from master..sysprocesses'				>> ${PathControl}Count.isql
	echo 'group by suid, dbid, hostname, ipaddr having count(suid) > 20 order by 5 DESC'				>> ${PathControl}Count.isql
	echo 'GO'													>> ${PathControl}Count.isql

	isql -U${User} -P${Pass} -S${Srv} -i${PathControl}Count.isql -o ${PathControl}Count.out -Jiso_1 -w300
	echo '.' >> ${PathControl}Count.out
        FreeCon=`cat ${PathControl}Conn.out | grep number | awk '{print $5}'`
        UsedCon=`cat ${PathControl}Conn.out | grep number | awk '{print $6}'`
        echo "El numero de conexiones libres es: ${FreeCon}" >> ${PathControl}Count.out
        echo "El numero de conexiones activas es: ${UsedCon}" >> ${PathControl}Count.out 
	mail -s"${Srv} - Conexiones Alerta" dba@mail.com.ar < ${PathControl}Count.out
fi
