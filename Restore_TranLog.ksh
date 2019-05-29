#!/usr/bin/ksh

EXCLUDE="cob_distrib|sys|master|model|sybs"

ChkErr(){ if [ $1 != 0 ] ; then exit $1 ; fi }

RestoreTranLogBase(){
	echo "--- Restore TranLog Base: $1 ---"
	# aca habria que agregar algo para poder hacer que tome la diferencia entre horas
	ls -p /dumps/tranlog/ | grep -v / | grep $1_ | grep ${DiaActual} | grep 'full.dmp' | awk -F ''$1'_|.full' '{print $2}' | while read Base_TrunLog_Full_hora
	do
	
		acum="$acum$Base_TrunLog_Full_hora\n"

	done
	
	ls -p /dumps/tranlog/ | grep -v / | grep $1- | grep ${DiaActual} | grep 'tran.dmp' | awk -F ''$1'-|.tran' '{print $2}' |while read Base_TrunLog_hora
	do
	
		acum="$acum$Base_TrunLog_hora\n"

	done
	
	salida="use master\ngo\n"
	
	echo $acum | sort | while read HoraDumpTranLogFormateada
	do
	
		if [ -z != $HoraDumpTranLogFormateada ] 
		then
		
			##tran.dmp
			fileTranLog=$(ls -p /dumps/tranlog/ | grep $1- | grep ${HoraDumpTranLogFormateada})
		
			if [ -z != $fileTranLog ] 
			then
			
				HoraDumpTranLog=`echo ${fileTranLog} | awk -F '${DiaActual}|-' '{print $2}' | awk '{ print substr( $1,8, 5) }' | sed 's/\.//' | sed 's/^0//g'`
				
				if [[ ${HoraDumpTranLog} -le ${HoraActualMenosUna} ]]
				then
				
					salida="$salida load transaction $1 from '/dumps/tranlog/${fileTranLog}'\ngo\n"
				
				fi
				
			else
			
				##full.dmp
				fileTranLog=$(ls -p /dumps/tranlog/ | grep $1_ | grep ${HoraDumpTranLogFormateada})

				HoraDumpTranLog=`echo ${fileTranLog} | awk -F '${DiaActual}|-' '{print $2}' | awk '{ print substr( $1,8, 5) }' | sed 's/\.//' | sed 's/^0//g'`
			
				if [[ ${HoraDumpTranLog} -le ${HoraActualMenosUna} ]]
				then
				
					salida="$salida load database $1 from '/dumps/tranlog/${fileTranLog}'\ngo\n"
				
				fi
			
			fi
		
		fi		
		
		echo $salida
		
	done
	
	echo $salida
	
	#isql -U$login -P$pwd -S$DSQUERY -W900 --retserverror << ScriptSql
	#		$(echo $salida)
	#ScriptSql
	ChkErr $?
	
	acum=""
	salida=""
	
	echo "--------------------------------"
}

find /dumps -type d -name 'BKP_*_despues_*' 2>/dev/null|sort|tail -1

HoraActualMenosUna=`TZ=+4;date +%H%M | sed 's/^0//g'`

DiaActual=`date +%y%m%d`

PathUltimosBackups=$(find /dumps -type d -name 'BKP_*_despues_*' 2>/dev/null|sort|tail -1)

find ${PathUltimosBackups} -type f -name '*.dmp' |sed "s:_s[0-9]\.dmp::"|awk -F/ '$0=$4'|uniq|egrep -v "(${EXCLUDE})"|while read cadabase
do
	RestoreTranLogBase $cadabase

	acum=""
	salida=""
	
done

exit 0;

