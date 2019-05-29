#!/usr/bin/ksh

# plandb.sql
# sp_plan_dbccdb

# bases.sql
# select 'Base: ' + name
# from master..sysdatabases
# where name not like 'tempdb%'
# and name not in ('Audit_SMG','master','model','sybsystemprocs','sybsystemdb','dbccdb','mon_db','sybsecurity')


export LANG="en_US"
. /sybase/SYBASE.sh > /dev/null 2>&1

User=`grep -E "USER" /home/sybase/params.txt | awk '{print $2}'`
Pass=`grep -E "PASS" /home/sybase/params.txt | awk '{print $2}'`
Srv=`grep -E "SERVER_5200" /home/sybase/params.txt | awk '{print $2}'`

Pathh=/home/sybase/controles/Integridad

if [[ -e ${Pathh}/mensaje_final.msg ]]
then
        rm ${Pathh}/mensaje_final.msg
fi

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/bases.sql -o${Pathh}/bases.out -w350

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/plandb.sql -o${Pathh}/plandb.out -w350

for var in $(grep -E "Base:" ${Pathh}/bases.out | awk '{print $2}');do

SCAN=`grep -w $var ${Pathh}/plandb.out | awk '{print $2}'`
print sp_dbcc_createws dbccdb,scanseg, scan_$var,scan,'"'${SCAN}'"' > ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out

TEXT=`grep -w $var ${Pathh}/plandb.out | awk '{print $3}'`

print sp_dbcc_createws dbccdb,textseg, text_$var,text,'"'${TEXT}'"' >> ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/salida.out -o${Pathh}/espacios.out -w350

print "RESULTADO DE LA CREACION DE LOS WS  - INICIO PROCESO DB: " $var >> ${Pathh}/espacios.out
print "." >> ${Pathh}/espacios.out

cat ${Pathh}/espacios.out > ${Pathh}/mensaje.msg

CACHE=`grep -w $var ${Pathh}/plandb.out | awk '{print $4}'`
PROC=`grep -w $var ${Pathh}/plandb.out | awk '{print $6}'`

print sp_dbcc_updateconfig $var, '"'scan workspace'"', scan_$var > ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out 
print sp_dbcc_updateconfig $var, '"'text workspace'"', text_$var >> ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out 
print sp_dbcc_updateconfig $var, '"'max worker processes'"', '"'$PROC'"' >> ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out
print sp_dbcc_updateconfig $var, '"'dbcc named cache'"', '"'default data cache'"', '"'${CACHE}'"' >> ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/salida.out -o${Pathh}/configuraciones.out -w350

print "RESULTADO DE LAS CONFIGURACIONES" >> ${Pathh}/configuraciones.out
print "." >> ${Pathh}/configuraciones.out

cat ${Pathh}/configuraciones.out >> ${Pathh}/mensaje.msg

print dbcc checkstorage"("$var")" > ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out

print dbcc checkverify"("$var")" > ${Pathh}/salida_v.out
print "go" >> ${Pathh}/salida_v.out

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/salida.out -o${Pathh}/ejecucion.out -w350


print "RESULTADO DEL PROCESO" >> ${Pathh}/ejecucion.out
print "." >> ${Pathh}/ejecucion.out

cat ${Pathh}/ejecucion.out >> ${Pathh}/mensaje.msg

print USE dbccdb > ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out
print drop table scan_$var >> ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out
print drop table text_$var >> ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/salida.out -o${Pathh}/borrado.out -w350

print "FIN DE LA DB" $var >> ${Pathh}/borrado.out
print "." >> ${Pathh}/borrado.out

cat ${Pathh}/borrado.out >> ${Pathh}/mensaje.msg
cat ${Pathh}/mensaje.msg >> ${Pathh}/mensaje_final.msg

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/salida_v.out -o${Pathh}/ejecucion_v.out -w350

done

mail -s "CHECKSTORAGE - PROCESS" dba@mail.com.ar < ${Pathh}/mensaje_final.msg

if [[ -e ${Pathh}/configuraciones.out ]]
then
        rm ${Pathh}/configuraciones.out
fi

if [[ -e ${Pathh}/borrado.out ]]
then
        rm ${Pathh}/borrado.out
fi

if [[ -e ${Pathh}/mensaje.msg ]]
then
        rm ${Pathh}/mensaje.msg
fi

if [[ -e ${Pathh}/salida.out ]]
then
        rm ${Pathh}/salida.out
fi

if [[ -e ${Pathh}/salida_v.out ]]
then
        rm ${Pathh}/salida_v.out
fi

if [[ -e ${Pathh}/plandb.out ]]
then
        rm ${Pathh}/plandb.out
fi
if [[ -e ${Pathh}/espacios.out ]]
then
        rm ${Pathh}/espacios.out
fi

if [[ -e ${Pathh}/ejecucion.out ]]
then
        rm ${Pathh}/ejecucion.out
fi

if [[ -e ${Pathh}/ejecucion_v.out ]]
then
        rm ${Pathh}/ejecucion_v.out
fi
