#!/usr/bin/ksh
set -x
. /sybase/SYBASE.sh > /dev/null 2>&1

DiaActual=`date +%y%m%d%H%M`

EXCLUDE="sys|master|model|sybs"

ChkErr(){ if [ $1 != 0 ] ; then exit $1 ; fi }


SqlScript=""
SqlScript="$SqlScript use admindba\ngo\n"
SqlScript="$SqlScript create table TablasKB_${DiaActual}\n"
SqlScript="$SqlScript (tabla varchar(255),rowtotal numeric (19,2),reserved numeric (19,2),data numeric (19,2),index_size numeric (19,2),unused numeric (19,2),base varchar(255))\ngo\n"
isql -U$login -P$pwd -S$DSQUERY -w900 -b --retserverror << SQL
$(echo -e $SqlScript)
SQL

ChkErr $?

SqlScript=""
SqlScript="$SqlScript set nocount on\nuse master\ngo\n"
SqlScript="$SqlScript select name from master..sysdatabases where name not in ('master','model') and name not like 'tempdb%' and name not like 'syb%'\ngo\n"

for var in $(isql -U$login -P$pwd -S$DSQUERY -w900 -b --retserverror << SQL
$(echo $SqlScript)
SQL);do
	BASE=$var
	echo "Registrando tablas de la base: "$var
	SqlScript2=""
	SqlScript2="$SqlScript2 set nocount on\nuse ${var}\ngo\n"
	SqlScript2="$SqlScript2 select name from sysobjects where type = 'U'\ngo\n"
	for var2 in $(isql -U$login -P$pwd -S$DSQUERY -w900 -b --retserverror << SQL
$(echo $SqlScript2)
SQL);do
	SqlScript3=""
	SqlScript3="$SqlScript3 set nocount on\nuse ${var}\ngo\n"
	SqlScript3="$SqlScript3 sp_spaceused ${var2}\ngo\n"
	set -A ARRAY `isql -U$login -P$pwd -S$DSQUERY -w900 -b --retserverror << SQLL
	$(echo $SqlScript3)
SQLL`
	ChkErr $?
	SqlScript4=""
	SqlScript4="insert into admindba.dbo.TablasKB_${DiaActual} values (""'"${ARRAY[1]}"'"","${ARRAY[2]}","${ARRAY[3]}","${ARRAY[5]}","${ARRAY[7]}","${ARRAY[9]}",""'"${var}"'"")\ngo\n"
	isql -U$login -P$pwd -S$DSQUERY -w900 -b --retserverror << SQLL
	$(echo $SqlScript4)
SQLL
	done
done

echo "Termino la actualizacion del ranking por peso, la tabla se encuentra en admindba con el nombre TablasKB_${DiaActual}/n./n" | mail -s "UTILIZACION DE ESPACIO POR TABLA" dba@mail.com.ar