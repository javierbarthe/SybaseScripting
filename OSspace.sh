#!/usr/bin/ksh

#####################################################
#                                                   #
# Este Control se encarga de revisar periodicamente #
# el estado de uso de los FileSystems y             #
# teniendo una aproximación con el % averiguar si   #
# paso un umbral y enviar una notificacion.         #
#                                                   #
#####################################################

#Variables Utilizadas
PathControl="/home/sybase/controles/OSspace/"
ServerName=`hostname`
Subject="${ServerName} - Control File System"

#---------------------------------------------Control-de-reproceso--------------------------------------------------------------
IDProcess=`echo $$`
ProcessName=OSspace.sh

#Obtengo el PID de Cron, en caso de ser varios los concateno con un | para luego poder usarlos en el EGREP
CronID=`ps -ef | grep '/usr/sbin/cron' | grep -v grep | awk '{print$2}'`
CronID=`echo ${CronID} | sed 's/ /\|/g'`

#Calculo Cuantos procesos son ejecutados por cron
#CountProcess=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | wc -l | awk '{print $1}'`
CountProcessConCron=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | egrep ${CronID} | grep -v grep | wc -l`
UserExecutor=`ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep | awk '{print $1}'`
ps -efa | grep ${ProcessName} | grep -v ${IDProcess} | grep -v grep > /home/sybase/controles/OSspace/CountProcess.tmp
CountProcess=` wc -l /home/sybase/controles/OSspace/CountProcess.tmp | awk '{print $1}'`
echo $CountProcess

if [[ ${CountProcess} -gt 2 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} en ejecucion por usuario ${UserExecutor} >> /home/sybase/controles/OSspace/ControlReEjecucion.log
exit
fi

if [[ ${CountprocessConCron} -gt 2 ]]
then
Fecha=`date`
echo ${Fecha} Proceso: ${ProcessName} Usuario ejecutando: cron >> /home/sybase/controles/OSspace/ControlReEjecucion.log
exit
fi
#-------------------------------------------------------------------------------------------------------------------------------

#Funciones

function RecreaArchivos
{
  rm ${PathControl}80_Porcen.txt;  echo "Mounted_On Nro_Alertado"               > ${PathControl}80_Porcen.txt
  rm ${PathControl}90_Porcen.txt;  echo "Mounted_On Nro_Alertado"               > ${PathControl}90_Porcen.txt
  rm ${PathControl}100_Porcen.txt; echo "Mounted_On Nro_Alertado"               > ${PathControl}100_Porcen.txt
  rm ${PathControl}Mail_Envio.txt; echo "Mounted_On Nro_Alertado Porcent"       > ${PathControl}Mail_Envio.txt
}

# Var $1 --> Archivo  Var $2 --> Patron
function EliminaEnArchivo
{
        cat ${PathControl}${1} | grep -v ${2}   > ${PathControl}Temp.tmp
        rm  ${PathControl}${1}
        cat ${PathControl}Temp.tmp              > ${PathControl}${1}
        rm  ${PathControl}Temp.tmp
}

function Fibonacci_Sequence
{
 case ${1} in
        Sumar )
                #Count_Mail=`cat ${PathControl}Count_Mail.txt`
                a=`cat ${PathControl}a.txt`
                b=`cat ${PathControl}b.txt`
                c=`expr ${a} + ${b} `
                echo ${b} > ${PathControl}a.txt
                echo ${c} > ${PathControl}b.txt
        ;;
        Set_Up )
                rm ${PathControl}a.txt;
                echo "1" > ${PathControl}a.txt
                rm ${PathControl}b.txt;
                echo "1" > ${PathControl}b.txt
                a=0; b=1; c=`expr ${a} + ${b} `; Count_Mail=0
                rm ${PathControl}Count_Mail.txt; echo "${Count_Mail}" > ${PathControl}Count_Mail.txt
        ;;
 esac
}

function Suma_Mail
{
 Count_Mail=`cat ${PathControl}Count_Mail.txt`
 Count_Mail=`expr ${Count_Mail} + 1 `
 echo ${Count_Mail} > ${PathControl}Count_Mail.txt
#Ultimo Valor de la serie de fibonacci guardado en la variable B
 c=`cat ${PathControl}b.txt`
}


#Chequeo rapido si un fileSystem supero el umbral inferior de 80%
UmbralUp=`df | grep -v -f ${PathControl}Excluidos.txt | awk '{print " "$4}' | egrep -c " 8[0-9]%| 9[0-9]%| 100%"`
if [[ ${UmbralUp} -eq 0 ]]; then
        echo "Ningun FS supera el umbral"
        RecreaArchivos
        Fibonacci_Sequence "Set_Up"
        exit
fi

#Recreo el archivo de Mail
rm ${PathControl}Mail_Envio.txt; echo "Mounted_On Nro_Alertado Porcent"       > ${PathControl}Mail_Envio.txt

#Recorro linea por linea el df para acomodar los alertados
df | grep -v -f ${PathControl}Excluidos.txt | awk '{print $7" "$4}' | egrep " 8[0-9]%| 9[0-9]%| 100" > ${PathControl}DF.txt
while read DF_Line ; do
        Mounted=`echo ${DF_Line} | awk '{print $1}'`
        Porcent=`echo ${DF_Line} | awk '{print $2}'`
        case ${Porcent} in
                        8[0-9]% )
                                  Existe_en_80=`cat ${PathControl}80_Porcen.txt | grep -c ${Mounted}`
                                  if [[ ${Existe_en_80} -eq 1 ]]; then
                                        Count_en_80=`cat ${PathControl}80_Porcen.txt | grep ${Mounted} | awk '{print $2}'`
                                        Count_en_80=`expr ${Count_en_80} + 1 `
                                        EliminaEnArchivo "80_Porcen.txt" "${Mounted}"
                                  else
                                        EliminaEnArchivo "90_Porcen.txt" "${Mounted}"
                                        EliminaEnArchivo "100_Porcen.txt" "${Mounted}"
                                        Count_en_80="1"
                                  fi

                                  echo ${Mounted}" "${Count_en_80}" "${Porcent} >> ${PathControl}Mail_Envio.txt
                                  echo ${Mounted}" "${Count_en_80}              >> ${PathControl}80_Porcen.txt
                                  if [[ ${Count_en_80} -gt 250 ]]; then
                                        echo ${Mounted} >> ${PathControl}Excluidos.txt
                                  fi
                        ;;

                        9[0-9]% )
                                  Existe_en_90=`cat ${PathControl}90_Porcen.txt | grep -c ${Mounted}`
                                  if [[ ${Existe_en_90} -eq 1 ]]; then
                                        Count_en_90=`cat ${PathControl}90_Porcen.txt | grep ${Mounted} | awk '{print $2}'`
                                        Count_en_90=`expr ${Count_en_90} + 1 `
                                        EliminaEnArchivo "90_Porcen.txt" "${Mounted}"
                                  else
                                        EliminaEnArchivo "80_Porcen.txt" "${Mounted}"
                                        EliminaEnArchivo "100_Porcen.txt" "${Mounted}"
                                        Count_en_90="1"
                                  fi

                                  echo ${Mounted}" "${Count_en_90}" "${Porcent} >> ${PathControl}Mail_Envio.txt
                                  echo ${Mounted}" "${Count_en_90}              >> ${PathControl}90_Porcen.txt
                                  if [[ ${Count_en_90} -gt 250 ]]; then
                                        echo ${Mounted} >> ${PathControl}Excluidos.txt
                                  fi
                        ;;

                        100% )
                                  Existe_en_100=`cat ${PathControl}100_Porcen.txt | grep -c ${Mounted}`
                                  if [[ ${Existe_en_100} -eq 1 ]]; then
                                        Count_en_100=`cat ${PathControl}100_Porcen.txt | grep ${Mounted} | awk '{print $2}'`
                                        Count_en_100=`expr ${Count_en_100} + 1 `
                                        EliminaEnArchivo "100_Porcen.txt" "${Mounted}"
                                  else
                                        EliminaEnArchivo "90_Porcen.txt" "${Mounted}"
                                        EliminaEnArchivo "80_Porcen.txt" "${Mounted}"
                                        Count_en_100="1"
                                  fi

                                  echo ${Mounted}" "${Count_en_100}" "${Porcent} >> ${PathControl}Mail_Envio.txt
                                  echo ${Mounted}" "${Count_en_100}              >> ${PathControl}100_Porcen.txt
                                  if [[ ${Count_en_100} -gt 250 ]]; then
                                        echo ${Mounted} >> ${PathControl}Excluidos.txt
                                  fi
                        ;;
        esac
done < ${PathControl}DF.txt

Suma_Mail

if [[ ${Count_Mail} -eq ${c} ]]; then
        echo "." >> ${PathControl}Mail_Envio.txt
        cat ${PathControl}Mail_Envio.txt | awk '{printf "%-20s%-20s%-20s\n", $1, $2, $3}' > ${PathControl}Envio_Mail.txt
 	mail -s "${Subject}" dba@mail.com.ar < ${PathControl}Envio_Mail.txt
        Fibonacci_Sequence "Sumar"
fi
