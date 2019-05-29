#!/usr/bin/ksh
Dir=$Controles/RepCheckLog
#---------------------------------------------Control-de-reproceso--------------------------------------------------------------
IDProcess=`echo $$`
ProcessName=repchecklog.sh

#Obtengo el PID de Cron, en caso de ser varios los concateno con un | para luego poder usarlos en el EGREP
CronID=`ps -ef | grep '/usr/sbin/cron' | grep -v grep | awk '{print$2}'`
CronID=`echo ${CronID} | sed 's/ /\|/g'`

#Calculo Cuantos procesos son ejecutados por cron
CountProcessConCron=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | egrep ${CronID} | grep -v grep | wc -l`
UserExecutor=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | awk '{print $1}'`
ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep > $Dir/CountProcess.tmp
CountProcess=` wc -l $Dir/CountProcess.tmp | awk '{print $1}'`
echo $CountProcess


if [[ ${CountProcess} -gt 0 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} en ejecucion por usuario ${UserExecutor} >> $Dir/ControlReEjecucion.log
exit
fi

if [[ ${CountprocessConCron} -gt 0 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} Usuario ejecutando: cron >> $Dir/ControlReEjecucion.log
exit
fi
#-------------------------------------------------------------------------------------------------------------------------------

cp $SYBASE/$SYBASE_REP/install/RS.log $Dir/logcompleto.log

diff -u $Dir/logcompleto.log $Dir/loganterior.log > $Dir/tmp.log

year=`date | awk '{print $6}'` 

egrep -i '((E. '$year')|(H. '$year')|(N. '$year')|(F. '$year')|(W. '$year'))' $Dir/tmp.log | grep -v "WARNING #5185" > $Dir/errores.log

cp $Dir/logcompleto.log $Dir/loganterior.log

rm $Dir/tmp.log

rm $Dir/logcompleto.log

salida=`cat $Dir/errores.log | wc -l | awk '{print $1}'`

if [[ ${salida} -gt 0 ]]
        then
                echo "." >> $Dir/errores.log
                mail -s "RS - RepCheckLog" dba@mail.com.ar < $Dir/errores.log
fi
