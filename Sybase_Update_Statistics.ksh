#!/usr/bin/ksh
#---------------------------------------------------------------------------------------------------
#			Consideraciones al instalar
#			Crear la siguiente tabla en ADMINDBA: 
#			create table update_stats_tables
#			(
#				cambio numeric(19,4) null,
#				name varchar(1000) null,
#				rowcnt integer null,
#				DB varchar(255) null,
#				fecha_ini datetime null,
#				fecha_fin datetime null
#			)				
#			Pasar por parametro usuario, password y servidor en el cual ejecutar.
#-----------------------------------------------------------------------------------------------------
. /sybase/SYBASE.sh > /dev/null 2>&1

User=$1
Pass=$2
Srv=$3

SqlScript=""
SqlScript="$SqlScript use admindba\ngo\n"
SqlScript="$SqlScript truncate table update_stats_tables\ngo\n"
isql -U$User -P$Pass -S$Srv -w900 -b --retserverror << SQL
$(echo -e $SqlScript)
SQL

SqlScript=""
SqlScript+="set nocount on\nuse master\ngo\n"
SqlScript+="select name from master..sysdatabases where name not in ('master','model') and name not like 'tempdb%' and name not like 'syb%'\ngo\n"

for var in $(isql -U$User -P$Pass -S$Srv -w900 -b --retserverror << SQL
$(echo -e $SqlScript)
SQL);do
	BASE=$var
	echo "Registrando tablas de la base: "$var
	SqlScript=""
	SqlScript+="Use "$var"\ngo\n"
	SqlScript+="insert into admindba..update_stats_tables select datachange(a.name, null, null), 'update index statistics '+db_name()+'..'+a.name, b.rowcnt,db_name(), null, null from sysobjects a inner join systabstats b on a.id = b.id where a.type = 'U' and datachange(a.name, null, null) > 10 and indid = 0 order by 1 desc\ngo\n"
	isql -U$User -P$Pass -S$Srv -w900 -b --retserverror << SQLL
	$(echo -e $SqlScript)
SQLL
done

SqlScript=""
SqlScript+="set nocount on\nuse admindba\ngo\n"
SqlScript+="select name from update_stats_tables order by cambio desc\ngo\n"
echo "Ejecutando sentencias"
for var in $(isql -U$User -P$Pass -S$Srv -w900 -b --retserverror << SQL
$(echo -e $SqlScript)
SQL);do
        SqlScript2=""
		SqlScript2+="update admindba..update_stats_tables set fecha_ini = getdate () where name = '"${var}"'\ngo\n"
        SqlScript2+=$var"\ngo\n"
		SqlScript2+="update admindba..update_stats_tables set fecha_fin = getdate () where name = '"${var}"'\ngo\n"
		isql -U$User -P$Pass -S$Srv -w900 -b --retserverror << SQLL
$(echo -e $SqlScript2)
SQLL
echo -e $SqlScript2
done
echo "FIN"
exit 0;