#!/usr/bin/ksh

# bases.sql
# set nocount on
# select name from master..sysdatabases where name not in ('master', 'model', 'mon_db')
# and name not like 'tempdb%' and name not like 'sybsystem%'

export LANG="en_US"
. /sybase/SYBASE.sh > /dev/null 2>&1

User=`grep -E "USER" /home/sybase/params.txt | awk '{print $2}'`
Pass=`grep -E "PASS" /home/sybase/params.txt | awk '{print $2}'`
Srv=`grep -E "SERVER_5200" /home/sybase/params.txt | awk '{print $2}'`

PathScript=$Controles/ExtractDBSec

isql -U${User} -P${Pass} -S${Srv} -i${PathScript}Bases.sql -o${PathScript}Bases.out -Jiso_1 -w300 -b

for DataBase in `cat ${PathScript}Bases.out`
do

        ArchivoAlias=${PathScript}${DataBase}_Alias
        #Arma Consulta de Alias
        #-------------------------------------------------------------------------------------------------------------------------------------------
        echo "set nocount on"                                                                                                 > ${ArchivoAlias}.isql
        echo "select 'sp_addalias '+\"'\"+suser_name(a.suid)+\"','dbo'\" +char(10)+\"go\" from ${DataBase}..sysalternates a" >> ${ArchivoAlias}.isql
        echo "GO"                                                                                                            >> ${ArchivoAlias}.isql

        isql -U${User} -P${Pass} -S${Srv} -i${ArchivoAlias}.isql -o${ArchivoAlias}.out -Jiso_1 -w300 -b

        #Para Settearle el 'Use database' arriba
        echo "USE ${DataBase}"     > ${PathScript}Temp.tmp
        echo "GO"                 >> ${PathScript}Temp.tmp
        cat ${ArchivoAlias}.out   >> ${PathScript}Temp.tmp
        rm  ${ArchivoAlias}.out
        cat ${PathScript}Temp.tmp > ${ArchivoAlias}.out
        rm  ${PathScript}Temp.tmp
        #-------------------------------------------------------------------------------------------------------------------------------------------
#       rm ${ArchivoAlias}.isql

        ArchivoGrupos=${PathScript}${DataBase}_Grupos
        #Arma Consulta Grupos
        #------------------------------------------------------------------------------------------------------------------------
        echo "set nocount on"   > ${ArchivoGrupos}.isql
        echo "Use ${DataBase}" >> ${ArchivoGrupos}.isql
        echo "go"              >> ${ArchivoGrupos}.isql
        echo "select 'sp_addgroup ' +\"'\" + name +\"'\"+ char(10) + 'go' from ${DataBase}..sysusers SU" >> ${ArchivoGrupos}.isql
        echo "where uid = gid and name <> 'public' and name not like '%_role'order by SU.uid"            >> ${ArchivoGrupos}.isql
        echo "go"              >> ${ArchivoGrupos}.isql

        isql -U${User} -P${Pass} -S${Srv} -i${ArchivoGrupos}.isql -o${ArchivoGrupos}.out -Jiso_1 -w300 -b

        #Para Settearle el 'Use database' arriba
        echo "USE ${DataBase}"     > ${PathScript}Temp.tmp
        echo "GO"                 >> ${PathScript}Temp.tmp
        cat ${ArchivoGrupos}.out  >> ${PathScript}Temp.tmp
        rm  ${ArchivoGrupos}.out
        cat ${PathScript}Temp.tmp  > ${ArchivoGrupos}.out
        rm  ${PathScript}Temp.tmp
        #------------------------------------------------------------------------------------------------------------------------
        #rm ${ArchivoGrupos}.isql

        ArchivoUsuarios=${PathScript}${DataBase}_Usuarios
        #Arma Consulta Users
        #----------------------------------------------------------------------------------------------------------------------------------------------------
        echo "set nocount on"   > ${ArchivoUsuarios}.isql
        echo "Use ${DataBase}" >> ${ArchivoUsuarios}.isql
        echo "go"              >> ${ArchivoUsuarios}.isql
echo "select 'sp_adduser ' +\"'\" + (select SL.name from master..syslogins SL where SL.suid = SU.suid)"                     >> ${ArchivoUsuarios}.isql
echo " +\"', '\" + SU.name +\"', '\"+ user_name(gid)+\"'\"+ char(10) + 'go' from ${DataBase}..sysusers SU where uid <> gid" >> ${ArchivoUsuarios}.isql
echo "and name not in ('dbo','guest') order by SU.uid"                                                                      >> ${ArchivoUsuarios}.isql
        echo "go"              >> ${ArchivoUsuarios}.isql

        isql -U${User} -P${Pass} -S${Srv} -i${ArchivoUsuarios}.isql -o${ArchivoUsuarios}.out -Jiso_1 -w300 -b

        #Para Settearle el 'Use database' arriba
        echo "USE ${DataBase}"      > ${PathScript}Temp.tmp
        echo "GO"                  >> ${PathScript}Temp.tmp
        cat ${ArchivoUsuarios}.out >> ${PathScript}Temp.tmp
        rm  ${ArchivoUsuarios}.out
        cat ${PathScript}Temp.tmp   > ${ArchivoUsuarios}.out
        rm  ${PathScript}Temp.tmp
        #----------------------------------------------------------------------------------------------------------------------------------------------------
        #rm ${ArchivoUsuarios}.isql

        ArchivoPermisos=${PathScript}${DataBase}_Permisos
        #Genero la consulta para los Permisos
        #-----------------------------------------------------------------------------------------------------------------------------------------------
        echo "set nocount on"   > ${ArchivoPermisos}.isql
        echo "Use ${DataBase}" >> ${ArchivoPermisos}.isql
        echo "go"              >> ${ArchivoPermisos}.isql
        echo "select case protecttype when 0 then 'grant with grant '" >> ${ArchivoPermisos}.isql
        echo "when 1 then 'GRANT '"                                    >> ${ArchivoPermisos}.isql
        echo "when 2 then 'REVOKE '"                                   >> ${ArchivoPermisos}.isql
        echo "end + case action "                                      >> ${ArchivoPermisos}.isql
        echo "when 151 then 'REFERENCES '"                             >> ${ArchivoPermisos}.isql
        echo "when 167 then 'set proxy or set session authorization '" >> ${ArchivoPermisos}.isql
        echo "when 187 then 'set statistics on '"                      >> ${ArchivoPermisos}.isql
        echo "when 188 then 'set statistics off '"                     >> ${ArchivoPermisos}.isql
        echo "when 193 then 'SELECT '"                                 >> ${ArchivoPermisos}.isql
        echo "when 195 then 'INSERT '"                                 >> ${ArchivoPermisos}.isql
        echo "when 196 then 'DELETE '"                                 >> ${ArchivoPermisos}.isql
        echo "when 197 then 'UPDATE '"                                 >> ${ArchivoPermisos}.isql
        echo "when 198 then 'create table '"                           >> ${ArchivoPermisos}.isql
        echo "when 203 then 'create database '"                        >> ${ArchivoPermisos}.isql
        echo "when 205 then 'grant '"                                  >> ${ArchivoPermisos}.isql
        echo "when 206 then 'revoke '"                                 >> ${ArchivoPermisos}.isql
        echo "when 207 then 'create view '"                            >> ${ArchivoPermisos}.isql
        echo "when 221 then 'create trigger '"                         >> ${ArchivoPermisos}.isql
        echo "when 222 then 'create procedure '"                       >> ${ArchivoPermisos}.isql
        echo "when 224 then 'EXECUTE '"                                >> ${ArchivoPermisos}.isql
        echo "when 228 then 'dump database '"                          >> ${ArchivoPermisos}.isql
        echo "when 233 then 'create default '"                         >> ${ArchivoPermisos}.isql
        echo "when 235 then 'dump transaction '"                       >> ${ArchivoPermisos}.isql
        echo "when 236 then 'create rule '"                            >> ${ArchivoPermisos}.isql
        echo "when 253 then 'connect '"                                >> ${ArchivoPermisos}.isql
        echo "when 282 then 'delete statistics '"                      >> ${ArchivoPermisos}.isql
        echo "when 317 then 'dbcc '"                                   >> ${ArchivoPermisos}.isql
        echo "when 320 then 'truncate table '"                         >> ${ArchivoPermisos}.isql
        echo "when 326 then 'update statistics '"                      >> ${ArchivoPermisos}.isql
        echo "when 347 then 'set tracing '"                            >> ${ArchivoPermisos}.isql
        echo "end + 'ON dbo.'+ ltrim(rtrim(convert (char(60),object_name(id))))+ ' TO ' + user_name(uid) + char(10) + 'go' " >> ${ArchivoPermisos}.isql
        echo "from ${DataBase}..sysprotects"                           >> ${ArchivoPermisos}.isql
        echo "go"                                                      >> ${ArchivoPermisos}.isql

        isql -U${User} -P${Pass} -S${Srv} -i${ArchivoPermisos}.isql -o${ArchivoPermisos}.out -Jiso_1 -w300 -b

        #Para Settearle el 'Use database' arriba
        echo "USE ${DataBase}"      > ${PathScript}Temp.tmp
        echo "GO"                  >> ${PathScript}Temp.tmp
        cat ${ArchivoPermisos}.out >> ${PathScript}Temp.tmp
        rm  ${ArchivoPermisos}.out
        cat ${PathScript}Temp.tmp  > ${ArchivoPermisos}.out
        rm  ${PathScript}Temp.tmp
        #-----------------------------------------------------------------------------------------------------------------------------------------------
        #rm ${ArchivoPermisos}.isql
done

