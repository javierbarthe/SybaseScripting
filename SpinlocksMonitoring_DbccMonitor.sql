dbcc monitor("clear", "spinlock_s", "on")
go
waitfor delay "00:01:00" 		/* Sample time */
go
dbcc monitor("sample", "spinlock_s", "off")
go
dbcc monitor("select", "spinlock_s", "on")
go
dbcc traceon(8399)
go
dbcc traceoff(-1)
go


dbcc traceon(8399)
go

select @@spid
go
/*
** The spinlocks are displayed as 'name::id'. name is the
** name passed into ulinitspinlock(). For single instance
** spinlocks id will be 0, for array spinlocks id corresponds
** to the order the spinlocks were intialised in, with 0 being the first.
*/
select * into #t1 from sysmonitors

create index ind1 on #t1(field_id)
create index ind2 on #t1(value)

/* Get the number of transactions */
declare @xacts float
select @xacts = value from #t1
	where group_name = "access" and field_name="xacts"

if @xacts = 0
begin
	select @xacts = 1 /* avoid divide by zero errors */
end

select @xacts "Number of xacts"

print ""
print "Spinlocks with contention - ordered by percent contention"
print ""

select rtrim(P.field_name) as spinlock, P.value as grabs, P.field_id
into #t2 from #t1 P
where P.group_name = "spinlock_p_0"
and P.value > 0


select P.spinlock, P.grabs, W.value as waits, (100 * W.value)/P.grabs as wait_percent, P.field_id
into #t3 from #t2 P, #t1 W
where W.group_name = "spinlock_w_0"
and P.field_id = W.field_id

select P.spinlock, P.grabs, P.waits,
P.wait_percent, S.value / P.waits as spins_per_wait, S.value as total_spins,
P.grabs / @xacts as grabs_per_xact
from #t3 P, #t1 S
where
        S.group_name = "spinlock_s_0"
        and P.field_id = S.field_id
        and P.waits != 0
        order by P.wait_percent desc
        compute sum(P.grabs), sum(P.grabs / @xacts)
drop table #t2
drop table #t3 
/*print ""
print "Spinlocks with no contention - ordered by number of grabs"
print ""

select rtrim(P.field_name) + "::" + convert(char(5), P.field_id
	- (select min(field_id)
from #t1 where field_name = P.field_name)) as spinlock,
P.value grabs,
P.value / @xacts as grabs_per_xact
from #t1 P, #t1 W
where
	    P.group_name = "spinlock_p_0"
	and W.group_name = "spinlock_w_0"
	and P.field_id = W.field_id
 	and P.value > 1 	/* one because getting the stats gets the spinlock */
	and W.value = 0
	order by grabs desc
	compute sum(P.value), sum(P.value / @xacts)
go
*/
dbcc traceoff(-1)
go