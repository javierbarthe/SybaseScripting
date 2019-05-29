#!/usr/bin/ksh
export LANG="en_US"
. /sybase/SYBASE.sh > /dev/null 2>&1

# Defino variable Path
Path=/home/sybase/controles/InstalacionAudit

# functions:
func_1 () {
echo "Instalacion Auditoria\n"
Validacion=NOT
echo "Esta seguro que desea realizar la instalacion de la auditoria? Y/N"
echo ""
read respuesta
echo ""
while [ ${Validacion} = "NOT" ]
do
	case ${respuesta} in
	Y | y ) 
			clear
			echo "-----------------------------------------------------------------"
			echo "Datos de conexion"
			echo "-----------------------------------------------------------------\n"
			echo "Ingresar servidor en formato IP:Puerto"
			echo "Ejemplo: 192.168.1.155:5005"
			echo ""
			read Serv
			echo ""
			echo "Ingresar Usuario"
			echo ""
			read User
			echo ""
			echo "Ingresar Password"
			echo ""
			read Pass
			echo ""
			echo "La ruta del installsecurity"
			echo "Por defecto es: /sybase/ASE-15_0/scripts/installsecurity"
			echo "Desea cambiarla? Y/N"
			echo ""
			read rta
			echo ""
			valida_1 ${rta}
			if [[ ${rta} = "y" ]] || [[ ${rta} = "Y" ]] 
			then
			echo "Ingrese ruta del installsecurity"
			echo ""
			read instsec
			echo ""
			echo "Usted eligio la ruta: ${instsec} ¿es correcta? Y/N"
			echo ""
			read rta4
			echo ""
			valida_1 ${rta4}
			rta4=`echo ${aux}`
			valida_installsecurity ${rta4}		
			else
			instsec=/sybase/ASE-15_0/scripts/installsecurity
			fi

			clear
			echo "-----------------------------------------------------------------"
			echo "Informacion de la base"
			echo "-----------------------------------------------------------------\n"
			echo "Por favor, ingrese el device para datos"
			echo ""
			read ddatos
			echo ""
			echo "Por favor, ingrese el device para log"
			echo ""			
			read dlog
			echo ""
			echo "Por favor, ingrese el device para audit table"
			echo ""				
			read daudit		
			echo ""
			echo "\nUsted eligio el device ${ddatos} para los datos, ¿es correcto? Y/N"
			echo ""
			read rta
			echo ""
			valida_1 ${rta}
			rta=`echo ${aux}`
			valida_datos ${rta}	
			
			echo "Usted eligio el device ${dlog} para el log, ¿es correcto? Y/N"
			echo ""
			read rta2
			echo ""
			valida_1 ${rta2}
			rta2=`echo ${aux}`
			valida_log ${rta2}
			
			echo "Usted eligio el device ${daudit} para el audit table, ¿es correcto? Y/N"
			echo ""
			read rta3
			echo ""
			valida_1 ${rta3}
			rta3=`echo ${aux}`
			valida_audit ${rta3}	
			echo ""
			echo "Por favor, ingrese el tamaño de los datos en MB"
			echo ""
			read tdatos
			echo ""
			echo "Por favor, ingrese el tamaño del log en MB"
			echo ""
			read tlog	
			echo ""			
			echo "Por favor, ingrese el tamaño para audit table"
			echo ""
			read taudit
			echo ""
			clear			
			echo "Resumen de creacion de base:\n"
			echo "-----------------------------------------------------------------"
			echo "Datos de la conexion"
			echo "-----------------------------------------------------------------\n"
			echo "Servidor: ${Serv}"
			echo "Usuario: ${User}"
			echo "Password: ${Pass}"
			echo "Ruta install security: ${instsec}\n"
			echo "-----------------------------------------------------------------"
			echo "Informacion de la base"
			echo "-----------------------------------------------------------------\n"
			echo "Device de datos: ${ddatos}"
			echo "Tamaño en MB: ${tdatos}"
			echo "Device de log: ${dlog}"
			echo "Tamaño en MB: ${tlog}"
			echo "Device de Audit Table: ${daudit}"
			echo "Tamaño en MB: ${taudit}\n"
			echo "-----------------------------------------------------------------\n"
				
			echo "Desea continuar con la creacion? Y/N"
			echo ""
			read rta
			echo ""
			valida_1 ${rta}		

			if [[ ${rta} = "y" ]] || [[ ${rta} = "Y" ]]
			then
			clear
			echo "select * from master..sysdatabases where name = 'sybsecurity'" > ${Path}/validabase.isql
			echo "go" >> ${Path}/validabase.isql
			isql -U${User} -P${Pass} -S${Serv} -i${Path}/validabase.isql -o${Path}/validabase.out			
			valida=`cat ${Path}/validabase.out | grep "sybsecurity" | wc -l | awk '{print $1}'`
			
			if [[ ${valida} -gt 0 ]]
			then
			echo "La base ya existe"
			echo "Abortando la instalacion"
			break;
			fi
			clear
			echo "El programa de instalacion comenzara a crear la base"
			echo "Por favor, espere.."
			echo "use master" > ${Path}/CreacionBase.isql
			echo "GO" >> ${Path}/CreacionBase.isql
			echo "create database sybsecurity" >> ${Path}/CreacionBase.isql
			echo "on ${ddatos} = '${tdatos}M'" >> ${Path}/CreacionBase.isql
			echo "log on ${dlog} = '${tlog}M'" >> ${Path}/CreacionBase.isql
			echo "GO" >> ${Path}/CreacionBase.isql
			echo "sp_dboption sybsecurity,'select into',true" >> ${Path}/CreacionBase.isql
			echo "go" >> ${Path}/CreacionBase.isql
			echo "sp_dboption sybsecurity,'trunc log on chkpt',true" >> ${Path}/CreacionBase.isql
			echo "go" >> ${Path}/CreacionBase.isql			
			isql -U${User} -P${Pass} -S${Serv} -i${Path}/CreacionBase.isql -o${Path}/CreacionBase.out
			isql -U${User} -P${Pass} -S${Serv} -i${instsec} -o${instsec}.out
			echo "Comenzando modificacion de segmentos"
			echo "use master" > ${Path}/UpdateBase.isql
			echo "GO" >> ${Path}/UpdateBase.isql			
			echo "alter database sybsecurity on ${daudit} = '${taudit}M'" >> ${Path}/UpdateBase.isql
			echo "go" >> ${Path}/UpdateBase.isql
			echo "use sybsecurity" >> ${Path}/UpdateBase.isql	
			echo "go" >> ${Path}/UpdateBase.isql
			echo "sp_extendsegment aud_seg_01, sybsecurity, ${daudit}" >> ${Path}/UpdateBase.isql
			echo "go" >> ${Path}/UpdateBase.isql
			echo "sp_dropsegment 'default', sybsecurity, ${daudit}" >> ${Path}/UpdateBase.isql
			echo "go" >> ${Path}/UpdateBase.isql
			echo "sp_dropsegment 'system', sybsecurity, ${daudit}" >> ${Path}/UpdateBase.isql
			echo "go" >> ${Path}/UpdateBase.isql
			echo "sp_dropsegment aud_seg_01, sybsecurity, ${ddatos}" >> ${Path}/UpdateBase.isql
			echo "go" >> ${Path}/UpdateBase.isql
			echo "sp_configure 'audit queue size', 500" >> ${Path}/UpdateBase.isql
			echo "go" >> ${Path}/UpdateBase.isql

			clear
			isql -U${User} -P${Pass} -S${Serv} -i${Path}/UpdateBase.isql -o${Path}/UpdateBase.out			
			clear
			
			echo "Fin de proceso de instalacion"
			break;
			fi
			
			clear
			echo "Proceso abortado"
			
		break;
		;;
		
	N | n )
	
		echo "Usted eligio no realizar la creacion de la base"
		echo "Volviendo al MENU"
		break;
		;;
		
	* )
		echo "Seleccione una opcion correcta:"
		echo ""
		read respuesta
		echo ""
		;;	
	esac
done			
}


valida_1(){
		aux=$1
		while [ ${aux} != "Y" ] && [ ${aux} != "y" ] && [ ${aux} != "N" ] && [ ${aux} != "n" ]
		do
		echo "Por favor, responda con Y/N"
		echo ""
		read aux
		echo ""
		done
}
valida_datos(){
		aux2=$1
		while [ ${aux2} = "n" ] || [ ${aux2} = "N" ]
		do
		echo "Por favor, reingrese el device de datos correspondiente"
		echo ""
		read ddatos
		echo ""
		echo "El device que eligio es: ${ddatos}"
		echo "Es correcto? Y/N"
		echo ""
		read aux2
		echo ""
		#valida_rta
			while [ ${aux2} != "Y" ] && [ ${aux2} != "y" ] && [ ${aux2} != "N" ] && [ ${aux2} != "n" ]
			do
			echo "Por favor, responda con Y/N"
			echo ""
			read aux2
			echo ""
			done
		done
}
valida_log(){
		aux2=$1
		while [ ${aux2} = "n" ] || [ ${aux2} = "N" ]
		do
		echo "Por favor, reingrese el device de log correspondiente"
		read dlog
		echo "El device que eligio es: ${dlog}"
		echo "Es correcto? Y/N"
		echo ""
		read aux2
		echo ""
		#valida_rta
			while [ ${aux2} != "Y" ] && [ ${aux2} != "y" ] && [ ${aux2} != "N" ] && [ ${aux2} != "n" ]
			do
			echo "Por favor, responda con Y/N"
			echo ""
			read aux2
			echo ""
			done
		done
}
valida_audit(){
		aux3=$1
		while [ ${aux3} = "n" ] || [ ${aux3} = "N" ]
		do
		echo "Por favor, reingrese el device de audit table correspondiente"
		echo ""
		read daudit
		echo ""
		echo "El device que eligio es: ${daudit}"
		echo "Es correcto? Y/N"
		echo ""
		read aux3
		echo ""
		#valida_rta
			while [ ${aux3} != "Y" ] && [ ${aux3} != "y" ] && [ ${aux3} != "N" ] && [ ${aux3} != "n" ]
			do
			echo "Por favor, responda con Y/N"
			read aux3
			echo ""
			done
		done
}
valida_installsecurity(){
		aux3=$1
		while [ ${aux3} = "n" ] || [ ${aux3} = "N" ]
		do
		echo "Por favor, reingrese la ruta del installsecurity"
		echo ""
		read instsec
		echo ""
		echo "La ruta que eligio es: ${instsec}"
		echo "Es correcta? Y/N"
		read aux3
		#valida_rta
			while [ ${aux3} != "Y" ] && [ ${aux3} != "y" ] && [ ${aux3} != "N" ] && [ ${aux3} != "n" ]
			do
			echo "Por favor, responda con Y/N"
			read aux3
			echo ""
			done
		done
}


menu_list () {
clear
        echo "##############################################################"
        echo "####           Menu Interactivo  install audit            ####"
        echo "#### Este programa fue desarrollado por DBACentral_SYBASE ####"
        echo "##############################################################\n\n\n"
        echo "---------------------"
        echo "Seleccione su opcion"
        echo "---------------------\n"
        echo "1)\tPresionar 1 para: --Instalar auditoria-- "
        echo "2)\tPresionar 2 para: --Ingrese opcion aqui-- "
        echo "3)\tPresionar 3 para: --Ingrese opcion aqui-- "
        echo "4)\tPresionar 4 para: --Ingrese opcion aqui-- "
        echo "5)\tPresionar 5 para: --Ingrese opcion aqui-- "
        echo "6)\tPresionar 6 para: --Ingrese opcion aqui-- "
        echo "7)\tPresionar 7 para: --Ingrese opcion aqui--\n "
        echo "Presionar q|Q para: Salir del programa \n"
}

go_ahead () {
tput smso
echo "Seleccione cualquier tecla para volver al menu  \c"
tput rmso
oldstty=`stty -g`
stty -icanon -echo min 1 time 0
dd bs=1 count=1 >/dev/null 2>&1
stty "$oldstty"
echo
}
func_select () {
tput smso
echo "\nPor favor ingrese su opcion ( )\b\b\c"
read selection
tput rmso
case $selection in
     1) clear ; func_1 ; go_ahead ;;
     q|Q) tput rmso ; clear ; exit 0 ;;
esac
}
#
# Here is where is gets looped - basically forever, until
# the "q" option is selected, causing an explicit exit
#
while `true`
do
menu_list
func_select
done

