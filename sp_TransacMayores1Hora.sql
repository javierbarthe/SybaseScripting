create procedure dbo.sp_TransacMayores1Hora
as
begin

create table #TransacMayores1Hora_transac(
spid int null,
kpid int null,
DB varchar(15) null,
command varchar(35) null,
WaitEventID   smallint  null,
SecondsWaiting   int  null,
hostname varchar(35) null,
clientip varchar(35) null,
application varchar(35) null,
Usuario varchar(35) null,
starttime datetime null,
fecha_carga datetime null,
matar int null
)

create  table #TransacMayores1Hora_locks(
   fecha_carga   datetime  null,
   DB varchar(50),
   spid   int  null,
   id   int  null,
   page   int  null,
   type   int  null,
   class   varchar(30)  null,
   fid   int  null,
   context   tinyint  null,
   row   int  null,
   loid   int  null,
   partitionid   int  null,
   nodeid   int  null
)

create  table #usuarios(
   usuario   varchar(50)  null
)
-- CARGO USUARIOS EXCLUIDOS

insert into #usuarios values ('user1')

--cargo temporal

declare @fecha datetime
set @fecha = getdate()

insert into #TransacMayores1Hora_transac
	select b.spid,b.kpid,db_name(b.dbid) as DB,b.command,b.WaitEventID,b.SecondsWaiting,b.hostname,c.clientip,b.application,suser_name(serveruserid) as Usuario,a.starttime, @fecha, 0 from master..syslogshold a
	 inner join master..monprocess b
	  on a.spid = b.spid
	 inner join master..monprocesslookup c
	 on a.spid = c.spid
	 where a.name not like '%replication%'
	 and datediff(hh,starttime,getdate()) >= 1
	 order by b.spid
		
		--fin cargo temporal
		
--updateo TransacMayores1Hora_transac	
		
update mon_db..TransacMayores1Hora_transac
		set fecha_carga = transactemp.fecha_carga,
		SecondsWaiting = transactemp.SecondsWaiting --nuevo
from #TransacMayores1Hora_transac transactemp
where transactemp.spid = mon_db..TransacMayores1Hora_transac.spid
and transactemp.kpid = mon_db..TransacMayores1Hora_transac.kpid
and transactemp.DB = mon_db..TransacMayores1Hora_transac.DB
and transactemp.WaitEventID = mon_db..TransacMayores1Hora_transac.WaitEventID --nuevo
and transactemp.command = mon_db..TransacMayores1Hora_transac.cmd --nuevo
--fin update

-- insert

	/* Adaptive Server has expanded all '*' elements in the following statement */ insert into mon_db..TransacMayores1Hora_transac
	select a.spid, a.kpid, a.DB, a.command, a.WaitEventID, a.SecondsWaiting, a.hostname, a.clientip, a.application, a.Usuario, a.starttime, a.fecha_carga, a.matar from master..#TransacMayores1Hora_transac a
	left join mon_db..TransacMayores1Hora_transac b
		on a.spid = b.spid
		and a.kpid = b.kpid
		and a.DB = b.DB
		where b.spid is null
		and b.kpid is null
		and b.DB is null
		
-- fin insert

--cargo temporal locks

insert into #TransacMayores1Hora_locks

--   select @fecha as fecha_carga,db_name(b.dbid) as DB ,b.spid,b.id,b.page,b.type,b.class,b.fid,b.context,b.row,b.loid,b.partitionid,b.nodeid
--	 from master..syslogshold a 
--	inner join master..syslocks b
--	 on a.spid = b.spid
--	 and a.dbid = b.dbid
--	where a.name not like '$replication_truncation_point' 
--	and datediff(hh,a.starttime,getdate()) >= 1
--	order by b.spid

select @fecha as fecha_carga,db_name(b.dbid) as DB ,b.spid,b.id,b.page,b.type,b.class,b.fid,b.context,b.row,b.loid,b.partitionid,b.nodeid
from master..syslogshold a  
inner join master..syslocks b
on a.spid = b.spid
and a.dbid = b.dbid
inner join master..monprocess c
on a.spid = c.spid
and a.dbid = c.dbid
where suser_name(c.serveruserid) not in (select usuario from #usuarios)
and a.name not like '$replication_truncation_point' 
and datediff(hh,a.starttime,getdate()) >= 1
order by b.spid	
	
-- fin cargo temporal locks

--updateo TransacMayores1Hora_locks		
update mon_db..TransacMayores1Hora_locks
		set fecha_carga = lockstemp.fecha_carga
from #TransacMayores1Hora_locks lockstemp
where lockstemp.spid = mon_db..TransacMayores1Hora_locks.spid
and lockstemp.id = mon_db..TransacMayores1Hora_locks.id
and lockstemp.DB = mon_db..TransacMayores1Hora_locks.DB
--fin update locks
	
	-- insert

 insert into mon_db..TransacMayores1Hora_locks
	select a.fecha_carga, a.DB, a.spid, a.id, a.page, a.[type], a.class, a.fid, a.context, a.row, a.loid, a.partitionid, a.nodeid                                                           from master..#TransacMayores1Hora_locks a
	left join mon_db..TransacMayores1Hora_locks b
		on a.spid = b.spid
		and a.id = b.id
		and a.DB = b.DB
		where b.spid is null
		and b.id is null
		and b.DB is null

-- fin insert
	
end
go