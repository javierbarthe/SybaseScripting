#!/usr/bin/ksh
# DBProd.sta
# DB1:
#	/backup/db1_s1.bck
#	/backup/db1_s2.bck
#	
#DB2:
#    /backup/db2_s1.bck
#

export LANG="en_US"
. /sybase/SYBASE.sh > /dev/null 2>&1

OKRespuesta=NOT
while  [ ${OKRespuesta} = "NOT" ]
do
        clear
        PathScript=$Controles/Restore/
        echo "set nocount on" > ${PathScript}ListaDataBases.isql
        echo "select name from master..sysdatabases where name not in ('master', 'model', 'mon_db')"     >> ${PathScript}ListaDataBases.isql
        echo "and name not like 'tempdb%' and name not like 'sybsystem%' and name not like 'DBQA_tdb_%'" >> ${PathScript}ListaDataBases.isql
        echo "GO" >> ${PathScript}ListaDataBases.isql

        isql -U$login -P$pwd -S$DSQUERY -i${PathScript}ListaDataBases.isql -o${PathScript}ListaDataBases.out -Jiso_1 -w300 -b

        echo  "Selecciona la \033[1;35mbase\033[0m en la que se realizara el \033[1;35mrestore\033[0m:"
        j=0
        set -A ArrayBases
        for x in `cat ${PathScript}ListaDataBases.out`
        do
				j=`expr ${j} + 1`
                ArrayBases[${j}]=${x}
                echo "\033[1;36m${j}\033[0m\033[1;34m)\033[0m \033[1;39m${ArrayBases[${j}]}\033[0m"
        done
		
	echo "Ingrese Opcion: "
        read  Database
		OKDataBase=NOT
		
		while [ ${OKDataBase} = "NOT" ]
		do
			case ${Database} in
						[1-9] | [1-3][0-9] | 4[0-6] )
						clear
						echo "Usted eligio \033[1;39m${ArrayBases[${Database}]}\033[0m en \033[1;39mDBQA\033[0m"
						OKDataBase=OK
						;;
						* )
						echo "\033[1;31mSeleccione una opcion correcta\033[0m"
						OKDataBase=NOT
						read Database
						;;							
			esac
		done
		
        echo "Elija la \033[1;35mbase\033[0m de la cual se tomara el \033[1;35mbackup\033[0m productivo para restaurar:"

        j=0
        set -A ArrayBackup

        for x in `cat ${PathScript}DBProd.sta | grep ":" | cut -d: -f1`
        do
		j=`expr ${j} + 1`
                ArrayBackup[${j}]=${x}
                #echo "${j}) ${ArrayBackup[${j}]}"
		echo "\033[1;36m${j}\033[0m\033[1;34m)\033[0m \033[1;39m${ArrayBackup[${j}]}\033[0m"
        done

        echo "Ingrese Opcion: "
	read NrobackUp
		OKNrobackUp=NOT
		
		while [ ${OKNrobackUp} = "NOT" ]
		do
			case ${NrobackUp} in
						[1-9] | 1[0-9] | 2[0-5] )
						echo "Usted eligio \033[1;39m${ArrayBackup[${NrobackUp}]}\033[0m en \033[1;39mDBPRD\033[0m"
						OKNrobackUp=OK
						;;
						* )
						#echo Seleccione una opcion correcta
						echo "\033[1;31mSeleccione una opcion correcta\033[0m"
						OKNrobackUp=NOT
						read NrobackUp
						;;							
			esac
		done
				
		#Comprobacion de backups
		echo "Seleccione de los backups \033[1;35mDisponibles\033[0m:"
		
	if [[ -f ${PathScript}TempStanza.tmp ]]
        then
                rm ${PathScript}TempStanza.tmp
        fi
		
		#Backup de Hoy
		CuentaStripes=`cat ${PathScript}DBProd.sta | grep -p ${ArrayBackup[${NrobackUp}]} | grep -v AYER | grep -v ":" | grep -v '^$' | wc -l`
		cat ${PathScript}DBProd.sta | grep -p ${ArrayBackup[${NrobackUp}]} | grep -v AYER | grep -v ":" |grep -v '^$' > ${PathScript}TempStanza.tmp
        SumaTeAlgo=0
		for x in `cat ${PathScript}TempStanza.tmp`
		do
			if [[ -f ${x} ]]
			then
				SumaTeAlgo=`expr ${SumaTeAlgo} + 1`
			fi
		done	
		if [[ -f ${PathScript}OpcionesCorrectas.txt ]]
			then
				rm ${PathScript}OpcionesCorrectas.txt
				touch ${PathScript}OpcionesCorrectas.txt
			fi

		if [[ ${SumaTeAlgo} -eq ${CuentaStripes} ]]
		then
				echo "\033[1;36m1\033[0m\033[1;34m)\033[0m Bck Ultimo \033[1;32mDisponible\033[0m"
				echo "1 OK" >> ${PathScript}OpcionesCorrectas.txt
		else
				echo "\033[1;36m1\033[0m\033[1;34m)\033[0m Bck Ultimo \033[1;31mNO\033[0m Disponible \033[1;31m(Opcion NO Valida)\033[0m"
				echo "1 FAIL" >> ${PathScript}OpcionesCorrectas.txt
		fi
		
		#Backup de Ayer
                if [[ -f ${PathScript}TempStanza.tmp ]]
                then
                        rm ${PathScript}TempStanza.tmp
                fi

		CuentaStripes=`cat ${PathScript}DBProd.sta | grep -p ${ArrayBackup[${NrobackUp}]} | grep AYER | grep -v ":" | grep -v '^$' | wc -l`
        cat ${PathScript}DBProd.sta | grep -p ${ArrayBackup[${NrobackUp}]} | grep AYER | grep -v ":" | grep -v '^$' > ${PathScript}TempStanza.tmp
       	SumaTeAlgo=0

		for x in `cat ${PathScript}TempStanza.tmp`
		do
			if [[ -f ${x} ]]
			then
				SumaTeAlgo=`expr ${SumaTeAlgo} + 1`
			fi
		done
		
		if [[ ${SumaTeAlgo} -eq ${CuentaStripes} ]]
		then
				echo "\033[1;36m2\033[0m\033[1;34m)\033[0m Bck AYER \033[1;32mDisponible\033[0m"
				echo "2 OK" >> ${PathScript}OpcionesCorrectas.txt
		else
				echo "\033[1;36m2\033[0m\033[1;34m)\033[0m Bck AYER \033[1;31mNO\033[0m Disponible \033[1;31m(Opcion NO Valida)\033[0m"
				echo "2 FAIL" >> ${PathScript}OpcionesCorrectas.txt
		fi
	
		echo "\033[1;36m3\033[0m\033[1;34m)\033[0m Especificar ruta en la que se encuentra el archivo de Backup \033[1;33m(on your own RISK)\033[0m"
		read BackupRo
        	OKBackupRo=NOT
		
		while [[ ${OKBackupRo} = "NOT" ]]
		do
			case ${BackupRo} in
					1 )
					EsValid=`cat ${PathScript}OpcionesCorrectas.txt | grep OK | grep ${BackupRo} | wc -l`
					if [[ ${EsValid} -eq 1 ]]
					then
                            		OKBackupRo=OK
		cat ${PathScript}DBProd.sta | grep -p ${ArrayBackup[${NrobackUp}]} | grep -v AYER | grep -v ":" |grep -v '^$' > ${PathScript}TempStanza.tmp
					break;
					fi 
					;;
					
					2 )
					EsValid=`cat ${PathScript}OpcionesCorrectas.txt | grep OK | grep ${BackupRo} | wc -l`
					if [[ ${EsValid} -eq 1 ]]
					then
                                        OKBackupRo=OK
		cat ${PathScript}DBProd.sta | grep -p ${ArrayBackup[${NrobackUp}]} | grep AYER | grep -v ":" | grep -v '^$' > ${PathScript}TempStanza.tmp
					break;
					fi 
					;;	
					
					3 )
					CountBlank=0
					if [[ -f ${PathScript}TempStanza.tmp ]]
					then
						rm ${PathScript}TempStanza.tmp
						touch ${PathScript}TempStanza.tmp
					fi

					while  [ ${CountBlank} -eq 0 ]
					do
                			        echo "ingrese Path:"
                       			 	read  WhiteStripes
						if [[ -f ${WhiteStripes} ]]
						then
                        				echo ${WhiteStripes} >> ${PathScript}TempStanza.tmp
						else
							echo 'No existe Path'
                        				CountBlank=`echo ${WhiteStripes} | grep '^$' | wc -l`
						fi
					done
					break;
					;;
					
					* )
					;;							
			esac
                                        #echo Seleccione una opcion correcta
					echo "\033[1;31mSeleccione una opcion correcta\033[0m"
					echo " "
                                        OKBackupRo=NOT
                                        read BackupRo
		done
		
        j=1
        for x in `cat ${PathScript}TempStanza.tmp`
        do
                if [[ ${j} -eq 1 ]]
                then
                        echo "use master"                                              > ${PathScript}Restore_${ArrayBases[${Database}]}.isql
                        echo "go"                                                     >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
                        echo "load database ${ArrayBases[${Database}]} from '${x}'"   >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
                else
                        echo "stripe on '${x}'"                                       >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
                fi
                j=`expr ${j} + 1 `
        done

        echo "go"                                                                     >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "use master"                                                             >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "go"                                                                     >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "online database ${ArrayBases[${Database}]}"                             >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "go"                                                                     >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "use ${ArrayBases[${Database}]}"                                         >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "go"                                                                     >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "checkpoint"                                                             >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql
        echo "go"                                                                     >> ${PathScript}Restore_${ArrayBases[${Database}]}.isql

        clear
        echo "Usted eligio \033[1;35m${ArrayBases[${Database}]}\033[0m como \033[1;35mBase de Datos a pisar\033[0m"
        echo "Usted eligio \033[1;32m${ArrayBackup[${NrobackUp}]}\033[0m como \033[1;32mBackup productivo\033[0m "
        echo

        cat ${PathScript}Restore_${ArrayBases[${Database}]}.isql
	#${PathScript}Restore_${DataBase}.isql 
        echo
        echo "Estas Seguro que es correcto? [\033[1;32mYy\033[0m/\033[1;31mNn\033[0m]"
        
		read RespuestaAPregunta
		OKRespuestaAPregunta=NOT
		
		while [ ${OKRespuestaAPregunta} = "NOT" ]
		do
			case ${RespuestaAPregunta} in
					Y | y )
						echo "Comienzo Restore"
						OKRespuesta=YES
						break;
					;;
					N | n )
						echo "Vuelvo a empezar, aguarde por favor..."
						OKRespuesta=NOT
						sleep 2
						break;
					;;
					* )
						#echo "Ingrese una Opcion Correcta"
						echo "\033[1;31mIngrese una opcion correcta\033[0m"
						OKRespuestaAPregunta=NOT
						read RespuestaAPregunta
					;;
			esac
		done
done


#Dependiendo de la Base, se settea el Server para el ISQL
#-------------------------------------------

DataBase=${ArrayBases[${Database}]}

ServerDB=$DSQUERY

echo "Se realizara la tarea desde el servidor \033[1;33m${ServerDB}\033[0m"
#-------------------------------------------		

#Arma Consulta de Alias
#-------------------------------------------------------------------------------------------------------------------------------------------------
echo "Genero la consulta de \033[1;34mAlias\033[0m"
echo "set nocount on"                                                                                                 > ${PathScript}Sp_Alias.isql
echo "select 'sp_addalias '+\"'\"+suser_name(a.suid)+\"','dbo'\" +char(10)+\"go\" from ${DataBase}..sysalternates a" >> ${PathScript}Sp_Alias.isql
echo "GO"                                                                                                            >> ${PathScript}Sp_Alias.isql

isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_Alias.isql -o${PathScript}Sp_Alias.out -Jiso_1 -w300 -b
#-------------------------------------------------------------------------------------------------------------------------------------------------

#Para Settearle el 'Use database' arriba
#-----------------------------------------------------------
echo "USE ${DataBase}"         > ${PathScript}Temp.tmp
echo "GO"                     >> ${PathScript}Temp.tmp
cat ${PathScript}Sp_Alias.out >> ${PathScript}Temp.tmp
rm  ${PathScript}Sp_Alias.out
cat ${PathScript}Temp.tmp      > ${PathScript}Sp_Alias.out
rm  ${PathScript}Temp.tmp
#-----------------------------------------------------------

#Arma Consulta Grupos
#--------------------------------------------------------------------------------------------------------------------------------
echo "Genero la consulta de \033[1;33mGrupos\033[0m"
echo "set nocount on"   > ${PathScript}Sp_addgroup.isql
echo "Use ${DataBase}" >> ${PathScript}Sp_addgroup.isql
echo "go"              >> ${PathScript}Sp_addgroup.isql
echo "select 'sp_addgroup ' +\"'\" + name +\"'\"+ char(10) + 'go' from ${DataBase}..sysusers SU" >> ${PathScript}Sp_addgroup.isql
echo "where uid = gid and name <> 'public' and name not like '%_role'order by SU.uid"            >> ${PathScript}Sp_addgroup.isql
echo "go"              >> ${PathScript}Sp_addgroup.isql

isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_addgroup.isql -o${PathScript}Sp_addgroup.out -Jiso_1 -w300 -b
#--------------------------------------------------------------------------------------------------------------------------------

#Para Settearle el 'Use database' arriba
#-----------------------------------------------------------
echo "USE ${DataBase}"         > ${PathScript}Temp.tmp
echo "GO"                     >> ${PathScript}Temp.tmp
cat ${PathScript}Sp_addgroup.out >> ${PathScript}Temp.tmp
rm  ${PathScript}Sp_addgroup.out
cat ${PathScript}Temp.tmp      > ${PathScript}Sp_addgroup.out
rm  ${PathScript}Temp.tmp
#-----------------------------------------------------------

#--Cambiarle a un INNER JOIN
#Arma Consulta Users
#----------------------------------------------------------------------------------------------------------------------------------------------------------
echo "Genero la consulta de \033[1;32mUsuarios\033[0m"
echo "set nocount on"    > ${PathScript}Sp_adduser.isql
echo "Use ${DataBase}"  >> ${PathScript}Sp_adduser.isql
echo "go"               >> ${PathScript}Sp_adduser.isql
echo "select 'sp_adduser ' +\"'\" + (select SL.name from master..syslogins SL where SL.suid = SU.suid)"                     >> ${PathScript}Sp_adduser.isql
echo " +\"', '\" + SU.name +\"', '\"+ user_name(gid)+\"'\"+ char(10) + 'go' from ${DataBase}..sysusers SU where uid <> gid" >> ${PathScript}Sp_adduser.isql
echo "and name not in ('dbo','guest') order by SU.uid"                                                                      >> ${PathScript}Sp_adduser.isql
echo "go"               >> ${PathScript}Sp_adduser.isql

isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_adduser.isql -o${PathScript}Sp_adduser.out -Jiso_1 -w300 -b
#----------------------------------------------------------------------------------------------------------------------------------------------------------

#Para Settearle el 'Use database' arriba
#-----------------------------------------------------------
echo "USE ${DataBase}"           > ${PathScript}Temp.tmp
echo "GO"                       >> ${PathScript}Temp.tmp
cat ${PathScript}Sp_adduser.out >> ${PathScript}Temp.tmp
rm  ${PathScript}Sp_adduser.out
cat ${PathScript}Temp.tmp        > ${PathScript}Sp_adduser.out
rm  ${PathScript}Temp.tmp
#-----------------------------------------------------------

#Genero la consulta para los Permisos
#------------------------------------------------------------------------------------------------------------------------------------------------------
echo "Genero la consulta de \033[1;31mPermisos\033[0m"
echo "set nocount on"   > ${PathScript}GrantPermisos.isql
echo "Use ${DataBase}" >> ${PathScript}GrantPermisos.isql
echo "go"              >> ${PathScript}GrantPermisos.isql
echo "select case protecttype when 0 then 'grant with grant '" >> ${PathScript}GrantPermisos.isql
echo "when 1 then 'GRANT '"                                    >> ${PathScript}GrantPermisos.isql
echo "when 2 then 'REVOKE '"                                   >> ${PathScript}GrantPermisos.isql
echo "end + case action "                                      >> ${PathScript}GrantPermisos.isql
echo "when 151 then 'REFERENCES '"                             >> ${PathScript}GrantPermisos.isql
echo "when 167 then 'set proxy or set session authorization '" >> ${PathScript}GrantPermisos.isql
echo "when 187 then 'set statistics on '"                      >> ${PathScript}GrantPermisos.isql
echo "when 188 then 'set statistics off '"                     >> ${PathScript}GrantPermisos.isql
echo "when 193 then 'SELECT '"                                 >> ${PathScript}GrantPermisos.isql
echo "when 195 then 'INSERT '"                                 >> ${PathScript}GrantPermisos.isql
echo "when 196 then 'DELETE '"                                 >> ${PathScript}GrantPermisos.isql
echo "when 197 then 'UPDATE '"                                 >> ${PathScript}GrantPermisos.isql
echo "when 198 then 'create table '"                           >> ${PathScript}GrantPermisos.isql
echo "when 203 then 'create database '"                        >> ${PathScript}GrantPermisos.isql
echo "when 205 then 'grant '"                                  >> ${PathScript}GrantPermisos.isql
echo "when 206 then 'revoke '"                                 >> ${PathScript}GrantPermisos.isql
echo "when 207 then 'create view '"                            >> ${PathScript}GrantPermisos.isql
echo "when 221 then 'create trigger '"                         >> ${PathScript}GrantPermisos.isql
echo "when 222 then 'create procedure '"                       >> ${PathScript}GrantPermisos.isql
echo "when 224 then 'EXECUTE '"                                >> ${PathScript}GrantPermisos.isql
echo "when 228 then 'dump database '"                          >> ${PathScript}GrantPermisos.isql
echo "when 233 then 'create default '"                         >> ${PathScript}GrantPermisos.isql
echo "when 235 then 'dump transaction '"                       >> ${PathScript}GrantPermisos.isql
echo "when 236 then 'create rule '"                            >> ${PathScript}GrantPermisos.isql
echo "when 253 then 'connect '"                                >> ${PathScript}GrantPermisos.isql
echo "when 282 then 'delete statistics '"                      >> ${PathScript}GrantPermisos.isql
echo "when 317 then 'dbcc '"                                   >> ${PathScript}GrantPermisos.isql
echo "when 320 then 'truncate table '"                         >> ${PathScript}GrantPermisos.isql
echo "when 326 then 'update statistics '"                      >> ${PathScript}GrantPermisos.isql
echo "when 347 then 'set tracing '"                            >> ${PathScript}GrantPermisos.isql
echo "end + 'ON dbo.'+ ltrim(rtrim(convert (char(60),object_name(id))))+ ' TO ' + user_name(uid) + char(10) + 'go' " >> ${PathScript}GrantPermisos.isql
echo "from ${DataBase}..sysprotects"                           >> ${PathScript}GrantPermisos.isql
echo "go"                                                      >> ${PathScript}GrantPermisos.isql

isql -U$login -P$pwd -S${ServerDB} -i${PathScript}GrantPermisos.isql -o${PathScript}GrantPermisos.out -Jiso_1 -w300 -b
#------------------------------------------------------------------------------------------------------------------------------------------------------

#Para Settearle el 'Use database' arriba
#---------------------------------------------------------------
echo "USE ${DataBase}"              > ${PathScript}Temp.tmp
echo "GO"                          >> ${PathScript}Temp.tmp
cat ${PathScript}GrantPermisos.out >> ${PathScript}Temp.tmp
rm  ${PathScript}GrantPermisos.out
cat ${PathScript}Temp.tmp           > ${PathScript}GrantPermisos.out
rm  ${PathScript}Temp.tmp
#---------------------------------------------------------------

#Cuento las conexiones
#---------------------------------------------------------------------------------------------------------------------------
echo "set nocount on"                                                                  > ${PathScript}Count_Connections.isql
echo "select count(dbid) from master..sysprocesses where db_name(dbid)='${DataBase}'" >> ${PathScript}Count_Connections.isql
echo "GO"                                                                             >> ${PathScript}Count_Connections.isql
#---------------------------------------------------------------------------------------------------------------------------

#Aca no modifico por la Variable ${ServerDB} porque la idea es que mate las conexiones de los 2 lados
#----------------------------------------------------------------------------------------------------------------------------------
echo "Mato las conexiones"
isql -U$login -P$pwd -S$DSQUERY -i${PathScript}Count_Connections.isql -o${PathScript}Count_Connections.out -Jiso_1 -w300 -b

Count_Connections=`cat ${PathScript}Count_Connections.out`

echo "${Count_Connections} conexiones total"
#----------------------------------------------------------------------------------------------------------------------------------

#Mato las conexiones hasta que sean 0 de modo que pueda seguir con el restore correctamente
#--------------------------------------------------------------------------------------------------------------------------------------------------
while [[ ${Count_Connections} -gt 0 ]]
do
        echo "set nocount on"                                                                               > ${PathScript}Mata_Connections.isql
        echo "select 'kill '+ltrim(rtrim(convert(char(10),spid)))+char(10)+'go' from master..sysprocesses" >> ${PathScript}Mata_Connections.isql
        echo "where db_name(dbid)='${DataBase}'"                                                           >> ${PathScript}Mata_Connections.isql
        echo "GO"                                                                                          >> ${PathScript}Mata_Connections.isql

        isql -U$login -P$pwd -S$DSQUERY -i${PathScript}Mata_Connections.isql  -o${PathScript}Mata_Connections.out -Jiso_1 -w300 -b

		isql -U$login -P$pwd -S$DSQUERY -i${PathScript}Count_Connections.isql -o${PathScript}Count_Connections.out -Jiso_1 -w300 -b

		Count_Connections=`cat ${PathScript}Count_Connections.out`
done

echo "${Count_Connections} conexiones totales despues del \033[1;31mKill\033[0m"
#--------------------------------------------------------------------------------------------------------------------------------------------------

#Ejecuto el Restore
#------------------------------------------------------------------------------------------------------------------------------------------------
echo " "
echo " "
echo "Se ejecuta el Restore"
cat ${PathScript}Restore_${DataBase}.isql
isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Restore_${DataBase}.isql -o${PathScript}Restore_${DataBase}.out -Jiso_1 -w300 -b
Count_Restore=`cat ${PathScript}Restore_${DataBase}.out | grep -i "LOAD is complete (database ${DataBase})" | wc -l`
#------------------------------------------------------------------------------------------------------------------------------------------------
echo "Reviso si el \033[1;33mRestore\033[0m finalizo \033[1;32mexitosamente\033[0m"

#Si esta Ok el restore le plancho los permisos que tenia y le modifico el SP
#--------------------------------------------------------------------------------------------------------------------------------------------

if [[ ${Count_Restore} -gt 0 ]]
then
	echo "Load completado \033[1;32mcorrectamente\033[0m"
        #Cambio Configuracion
        #----------------------------------------------------------------------------------------------------------------------------
        echo "sp_configure 'allow updates to system tables',1" > ${PathScript}Sp_configure.isql
        echo "go"                                             >> ${PathScript}Sp_configure.isql

        isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_configure.isql -o${PathScript}Sp_configure.out -Jiso_1 -w300 -b
        #----------------------------------------------------------------------------------------------------------------------------

        #Borrado de los users, groups y todo lo demas
        #-------------------------------------------------------------------------------------------------------------------------------------
        echo "delete from ${DataBase}..sysprotects"    > ${PathScript}BorradoSystables.isql
        echo "go"                                     >> ${PathScript}BorradoSystables.isql

        echo "delete from ${DataBase}..sysalternates" >> ${PathScript}BorradoSystables.isql
        echo "go"                                     >> ${PathScript}BorradoSystables.isql

        echo "delete from ${DataBase}..sysusers where gid <> uid" >> ${PathScript}BorradoSystables.isql
        echo "and gid not in (select lr.lrid from ${DataBase}..sysroles lr) and suid <> 1 and name <> 'dbo'" >> ${PathScript}BorradoSystables.isql
        echo "go"                                     >> ${PathScript}BorradoSystables.isql

        echo "delete from ${DataBase}..sysusers where gid = uid" >> ${PathScript}BorradoSystables.isql
        echo "and gid not in (select lr.lrid from ${DataBase}..sysroles lr) and name <> 'public'" >> ${PathScript}BorradoSystables.isql
        echo "go"                                     >> ${PathScript}BorradoSystables.isql

        isql -U$login -P$pwd -S${ServerDB} -i${PathScript}BorradoSystables.isql -o${PathScript}BorradoSystables.out -Jiso_1 -w300 -b
        #------------------------------------------------------------------------------------------------------------------------------------

        #Cambio Configuracion
        #----------------------------------------------------------------------------------------------------------------------------
        echo "sp_configure 'allow updates to system tables',0" > ${PathScript}Sp_configure.isql
        echo "go"                                             >> ${PathScript}Sp_configure.isql

        isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_configure.isql -o${PathScript}Sp_configure.out -Jiso_1 -w300 -b
        #----------------------------------------------------------------------------------------------------------------------------

        #Agrega los Alias
        #--------------------------------------------------------------------------------------------------------------------------
        isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_Alias.out -o${PathScript}Agregados_Alias.out -Jiso_1 -w300 -b
        #----------------------------------------------------------------------------------------------------------------------------

        #Agrega los Grupos
        #------------------------------------------------------------------------------------------------------------------------------
        isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_addgroup.out -o${PathScript}Agregados_Grupos.out -Jiso_1 -w300 -b
        #------------------------------------------------------------------------------------------------------------------------------

        #Agrega los Users
        #----------------------------------------------------------------------------------------------------------------------------
        isql -U$login -P$pwd -S${ServerDB} -i${PathScript}Sp_adduser.out -o${PathScript}Agregados_Users.out -Jiso_1 -w300 -b
        #----------------------------------------------------------------------------------------------------------------------------

        #Agrega Permisos
        #----------------------------------------------------------------------------------------------------------------------------------
        isql -U$login -P$pwd -S${ServerDB} -i${PathScript}GrantPermisos.out -o${PathScript}Agregados_Permisos.out -Jiso_1 -w300 -b
        #----------------------------------------------------------------------------------------------------------------------------------

else

        echo "\033[1;33mRevisar BackUp asigando para\033[0m \033[1;31m${DataBase}\033[0m "
fi
#--------------------------------------------------------------------------------------------------------------------------------------------

#Comprime los archivos
#-------------------------------------------------------------------------------------------------------------
Year=`date '+%y'`
Mes=`date '+%m'`
Dia=`date '+%d'`
Hor=`date '+%H'`
Min=`date '+%M'`
tar -cvf ${PathScript}/${DataBase}_${Year}${Mes}${Dia}_${Hor}${Min}.tar ${PathScript}*.isql ${PathScript}*.out
rm ${PathScript}*.isql
rm ${PathScript}*.out
#-------------------------------------------------------------------------------------------------------------
