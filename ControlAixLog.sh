#!/usr/bin/ksh

#---------------------------------------------Control-de-reproceso--------------------------------------------------------------
IDProcess=`echo $$`
ProcessName=ControlAixLog.sh

#Obtengo el PID de Cron, en caso de ser varios los concateno con un | para luego poder usarlos en el EGREP
CronID=`ps -ef | grep '/usr/sbin/cron' | grep -v grep | awk '{print$2}'`
CronID=`echo ${CronID} | sed 's/ /\|/g'`

#Calculo Cuantos procesos son ejecutados por cron
CountProcessConCron=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | egrep ${CronID} | grep -v grep | wc -l`
UserExecutor=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | awk '{print $1}'`

ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep > /home/sybase/controles/ControlAixLog/CountProcess.tmp
CountProcess=` wc -l /home/sybase/controles/ControlAixLog/CountProcess.tmp | awk '{print $1}'`

if [[ ${CountProcess} -gt 0 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} en ejecucion por usuario ${UserExecutor} >> /home/sybase/controles/ControlAixLog/ControlReEjecucion.log
exit
fi

if [[ ${CountprocessConCron} -gt 0 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} Usuario ejecutando: cron >> /home/sybase/controles/ControlAixLog/ControlReEjecucion.log
exit
fi
#-------------------------------------------------------------------------------------------------------------------------------


PathControles=/home/sybase/controles/ControlAixLog/
Mes=`date '+%m'`
Dia=`date '+%d'`
Min=`date '+%M'`
Yea=`date '+%y'`
Hor=`date '+%H'`

Srv=`grep -E "SERVER_5200" /home/sybase/params.txt | awk '{print $2}'`

echo ${Mes}${Dia}${Hor}${Min}${Yea}


if [ ${Min} -le 14 ]
then
        HorAnt=`expr ${Hor} - 1`
        echo ${HorAnt}
        Fecha=${Mes}${Dia}${HorAnt}45${Yea}
else
        if [ ${Min} -le 29 ]
        then
                Fecha=${Mes}${Dia}${Hor}00${Yea}
        else
                if [ ${Min} -le 44 ]
                then
                        Fecha=${Mes}${Dia}${Hor}15${Yea}
                else
                        if [ ${Min} -le 59 ]
                        then
                                Fecha=${Mes}${Dia}${Hor}30${Yea}
                        fi
                fi
        fi

fi

echo ${Fecha}

errpt -a -s ${Fecha} > ${PathControles}LogAix.log

NumberOf0=`cat ${PathControles}LogAix.log | wc -l`


if [ ${NumberOf0} -ge 1 ]
then
        echo "."            >> ${PathControles}LogAix.log
        mail -s "${Srv} - Errores en el Log de AIX" dba@mail.com.ar < ${PathControles}LogAix.log
fi
