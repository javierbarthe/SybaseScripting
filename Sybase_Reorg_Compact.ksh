#!/usr/bin/ksh
#---------------------------------------------------------------------------------------------------
#			Consideraciones al instalar
#			Crear la siguiente tabla en ADMINDBA: 
#			create table reorg_compact_log
#			(
#				cmd varchar(5000) not null,
#				fechaini datetime not null,
#				fechafin datetime null
#			)
#			Pasar por parametro usuario, password y servidor en el cual ejecutar.
#-----------------------------------------------------------------------------------------------------
. /sybase/SYBASE.sh > /dev/null 2>&1

User=$1
Pass=$2
Srv=$3

SqlScript=""
SqlScript="$SqlScript use admindba\ngo\n"
SqlScript="$SqlScript truncate table reorg_compact_log\ngo\n"
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
	SqlScript+="insert into admindba..reorg_compact_log select 'reorg compact '+db_name()+'..'+object_name(id),null,null from systabstats where (delrowcnt!=0 or forwrowcnt!=0) and object_name(id) not like 'sys%'\ngo\n"
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
		SqlScript2+="update admindba..reorg_compact_log set fechaini = getdate() where cmd = '"${var}"'\ngo\n"
        SqlScript2+=$var"\ngo\n"
		SqlScript2+="update admindba..reorg_compact_log set fechafin = getdate() where cmd = '"${var}"'\ngo\n"
		isql -U$User -P$Pass -S$Srv -w900 -b --retserverror << SQLL
$(echo -e $SqlScript2)
SQLL
echo -e $SqlScript2
done
echo "FIN"
exit 0;