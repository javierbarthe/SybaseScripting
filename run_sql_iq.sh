#!/usr/bin/ksh
set -
############################################################################
#
# Programa: run_sql_iq.sh
# Version: 0.2
# Autor: Varios
# Descripcion: Este script ejecuta sqls de IQ
# Historial de Actualizaciones:
# 2017-07-11 - 0	- Comienzo de modificacion para control-m
############################################################################

# -- Seteos, controles de paths iniciales y carga de archivos de ambiente ----

# -- Cargo el archivo de funciones de Control-M
. /aplicaciones/controlm/${VG_AMBIENTE_CTM}/etc/funciones_ctm.scr > /dev/null 2>&1

Cargo_Profile $ENTORNO
P_CRPS=$?

if [ $P_CRPS -ne 0 ]
then
  echo "No se ha podido cargar el profile para Control-M.  Codigo de retorno: ${P_CRPS}"
  exit ${P_CRPS}
fi

#
# -- Programa Principal -----------------------------------
#

# -- Compruebo cantidad de parametros recibidos -----------

if [ $# -lt 3 ]
then
  echo "Cantidad de parametros incorrecta!"
  exit 10
fi

# -- Conformo ejecucion y entorno segun parametros enviados -----------
INI=1
while [ $# -gt 0 ]
do
    if [ ${INI} -eq 1 ]
    then
	INST=$1
    fi

    if [ ${INI} -eq 2 ]
    then
	BASE=$1
    fi

    if [ ${INI} -eq 3 ]
    then
	SP=$1
	CMD="exec @retorno ="$1" "
    fi

    if [ ${INI} -gt 3 ]
    then
	if [ $# -eq 1 ]
	then
		CMD=${CMD}${1}
	else
		CMD=${CMD}${1}", "
	fi
    fi
    shift
INI=$INI+1
done

# -- Asigno parametros recibidos --------------------------

PATH_OUT=/aplicaciones/controlm/${VG_AMBIENTE_CTM}/scripts/output/salida_$$_${SP}.out	# Path del output
PATH_ERR=/aplicaciones/controlm/${VG_AMBIENTE_CTM}/scripts/output/errores__$$_${SP}.out # Salida de error
echo $PATH_OUT
echo "Ejecutando...: DBISQL "
EJECUTO=$SP $FECHA
echo "-----------------------------------------------------------------------"
dbisql -nogui -c "uid=${SYBUSR};pwd=${SYBPWD};eng=${INST};dbn=${BASE}" > ${PATH_OUT} 2> ${PATH_ERR} <<%%%
declare @retorno integer
${CMD}
select 'RETORNO: '+convert(varchar(10),@retorno)
%%%
crcom=$?
echo ${INST}
echo ${BASE}
echo ${CMD}
echo ${PATH_OUT}
echo ${PATH_ERR}

if [ $crcom -ne 0 ]
then
  echo "Error al ejecutar el Archivo Sql.  Codigo de retorno del sql: $crcom "
  crps=254
  exit ${crps}
fi
echo "---------------------------------------------------------------------"

CTRLERR=`grep 'SQLCODE' ${PATH_ERR} | awk -F, '{print $1}' | awk -F= '{print $2}'`
chrlenctrlerr=${#CTRLERR}
if [ ${chrlenctrlerr} -gt 0 ]
then
        echo "ERROR"
        cat ${PATH_OUT} | egrep -v "rows|^$"
		cat ${PATH_ERR}
        exit ${CTRLERR}
fi

CTRL=`grep 'RETORNO' ${PATH_OUT} | awk '{print $2}'`
chrlenctrl=${#CTRL}
if [ ${chrlenctrl} -gt 0 ]
then
		cat ${PATH_OUT} | egrep -v "rows|^$"
		cat ${PATH_ERR}
        exit ${CTRL}
fi

echo "OK"
cat ${PATH_OUT} | egrep -v "rows|^$"
cat ${PATH_ERR}
exit 0
