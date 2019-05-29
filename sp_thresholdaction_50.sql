/*

Este threshold en particular, guarda metricas en la tabla logdown cuando la tempdb llega a un 50% del segmento de log utilizado.
Para consultarla, ejecutar el siguiente comando

select * from mon_db..logdown

*/

CREATE PROC sp_thresholdaction_50
     @dbname varchar(30),  
     @segmentname varchar(30),  
     @free_space int,  
     @status int  as  
begin  
	print "Warning 50, not enough space in '%1!' segment - DB: '%2!'", @segmentname, @dbname 
	dump transaction @dbname with truncate_only  print "LOG DUMP: '%1!' for '%2!' dumped", @segmentname, @dbname 
	
Insert into mon_db..logdown
select 
	getdate(),
	a.dbid, a.reserved, a.spid, a.page, a.xactid, a.masterxactid, a.starttime, a.name, a.xloid                                                       ,
	object_name(b.id,b.dbid),
	b.ipaddr,
	b.loggedindatetime,
	b.program_name,
	b.cpu,
	b.physical_io,
	b.memusage,
	b.blocked,
	b.suid,
	b.cmd
from 
	master..syslogshold a
inner join
	master..sysprocesses b
on 	a.spid = b.spid
where db_name(a.dbid) = @dbname
end
