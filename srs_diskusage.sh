#!/usr/bin/ksh

# Crear tabla para guardar resultado
# select 'ASEDB'=convert(char(40),d.dsname+'.'+d.dbname), 'Q_Type'=case q_type when 0 then 'OBQ' else 'IBQ' end, 'Size_Mb'=count(used_flag)
# into tempdb..tempdb..srs_diskusage
# from rs_segments s, rs_databases d
# where used_flag = 1
# and s.q_number = d.dbid
# group by d.dsname+'.'+d.dbname, q_type, used_flag
#
# Trunca.sql
# truncate table tempdb..srs_diskusage
#
# Ejecuta.sql
# insert into tempdb..srs_diskusage
# select 'ASEDB'=convert(char(40),d.dsname+'.'+d.dbname), 'Q_Type'=case q_type when 0 then 'OBQ' else 'IBQ' end, 'Size_Mb'=count(used_flag)
# from rs_segments s, rs_databases d
# where used_flag = 1
# and s.q_number = d.dbid
# group by d.dsname+'.'+d.dbname, q_type, used_flag
#
# Consulta.sql
# select "Total: "+convert(varchar,sum(Size_Mb))
# from tempdb..srs_diskusage
#
# Lista.sql
# select * from tempdb..srs_diskusage order by 3 desc
#
# Do not forget about GO in each file. Also can be convert to variables so no need of files.
export LANG="en_US"
. $SYBASE/SYBASE.sh > /dev/null 2>&1

Dir=$Controles/SRS_DISKUSAGE

isql -U$login -P$pwd -S$DSQUERY -i$Dir/Trunca.sql -o$Dir/Trunca.out -w500 -Jiso_1

isql -U$login -P$pwd -S$DSQUERY -i$Dir/Ejecuta.sql -o$Dir/Ejecuta.out -w500 -Jiso_1

isql -U$login -P$pwd -S$DSQUERY -i$Dir/Consulta.sql -o$Dir/Consulta.out -w500 -Jiso_1

espacio=`grep "Total" $Dir/Consulta.out | awk '{print $2}'`

if [[ ${espacio} -gt 20000 ]]
then
	isql -U$login -P$pwd -S$DSQUERY -i$Dir/Lista.sql -o$Dir/Lista.out -w500 -Jiso_1
	print "." >> $Dir/Lista.out
	mail -s "RS - Disk Alert" dba@mail.com.ar < $Dir/Lista.out
fi

