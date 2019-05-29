#!/usr/bin/ksh

export LANG="en_US"
. /sybase/SYBASE.sh > /dev/null 2>&1

User=`grep -E "USER" /home/sybase/params.txt | awk '{print $2}'`
Pass=`grep -E "PASS" /home/sybase/params.txt | awk '{print $2}'`
Srv=`grep -E "SERVER_5200" /home/sybase/params.txt | awk '{print $2}'`

Pathh=/home/sybase/controles/Integridad

if [[ -e ${Pathh}/errores_total.out ]]
then
        rm ${Pathh}/errores_total.out
fi

for var in $(grep -E "Base:" ${Pathh}/bases.out | awk '{print $2}');do

print sp_dbcc_faultreport short,$var > ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/salida.out -o${Pathh}/errores.out -w350

print "FAULTS DB" $var >> ${Pathh}/errores.out

print sp_dbcc_recommendations $var > ${Pathh}/salida.out
print "go" >> ${Pathh}/salida.out

isql -U${User} -P${Pass} -S${Srv} -i${Pathh}/salida.out -o${Pathh}/recomendations.out -w350

print "RECOMMENDATIONS DB" $var >> ${Pathh}/recomendations.out
print "." >> ${Pathh}/recomendations.out
cat ${Pathh}/recomendations.out >> ${Pathh}/errores.out
cat ${Pathh}/errores.out >> ${Pathh}/errores_total.out

done

mail -s "CHEKSTORAGE - REPORT" dba@mail.com.ar < ${Pathh}/errores_total.out

if [[ -e ${Pathh}/recomendations.out ]]
then
        rm ${Pathh}/recomendations.out
fi

if [[ -e ${Pathh}/errores.out ]]
then
        rm ${Pathh}/errores.out
fi
