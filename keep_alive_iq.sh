#!/usr/bin/sh
############################################################################
#
# Programa: keep_alive_iq
# Version: 0.1
# Descripcion: Control para verificar la disponibilidad de sybase iq
# Historial de Actualizaciones:
# 2017-07-12 - 0.1  - Keep Alive Sybase IQ
############################################################################

ARCH_SQL=test_script    #Archivo sql a ejecutar
PATH_CTRL=${HOME}/      # Path del Archivo sql a ejecutar
INST=pr_iqprod                  # Instancia
BASE=cobisiq                    # Base
SYBUSR=monitoreo
SYBPWD=passw0rd
echo "Ejecutando...: DBISQL "
echo "-----------------------------------------------------------------------"
dbisql -nogui -c "uid=${SYBUSR};pwd=${SYBPWD};eng=${INST};dbn=${BASE}" ${PATH_CTRL}${ARCH_SQL}.sql > ${PATH_CTRL}${ARCH_SQL}.out &
sleep 20
CTRL=`grep 'OK' ${PATH_CTRL}${ARCH_SQL}.out`
chrlenctrl=${#CTRL}
if [ ${chrlenctrl} -eq 0 ]
then
        echo "ERROR"
        echo "ERROR EN LA RESPUESTA O DEMORA" > ${PATH_CTRL}/Salida.out
        exit
else
        echo "OK"
        echo "OK" > ${PATH_CTRL}/Salida.out
fi
echo "-----------------------------------------------------------------------"
echo "FIN"