USE mon_db
go
IF OBJECT_ID('dbo.mondeadlocks_collector') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.mondeadlocks_collector
    IF OBJECT_ID('dbo.mondeadlocks_collector') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.mondeadlocks_collector >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.mondeadlocks_collector >>>'
END
go
CREATE PROCEDURE dbo.mondeadlocks_collector
AS
BEGIN
    declare @maxresolvetime datetime

    select @maxresolvetime = max(ResolveTime) from mondeadlocks_DB1

	insert into mondeadlocks_DB1
	select 
	master.dbo.mondeadlock.DeadlockID, 
	master.dbo.mondeadlock.VictimKPID, 
	master.dbo.mondeadlock.ResolveTime, 
	db_name(master.dbo.mondeadlock.ObjectDBID) as ObjectDB, 
	master.dbo.mondeadlock.PageNumber, 
	master.dbo.mondeadlock.RowNumber, 
	master.dbo.mondeadlock.HeldFamilyID, 
	master.dbo.mondeadlock.HeldSPID, 
	master.dbo.mondeadlock.HeldKPID, 
	db_name(master.dbo.mondeadlock.HeldProcDBID) as HeldProcDB, 
	object_name(master.dbo.mondeadlock.HeldProcedureID,master.dbo.mondeadlock.HeldProcDBID) as HeldProc, 
	master.dbo.mondeadlock.HeldBatchID, 
	master.dbo.mondeadlock.HeldContextID, 
	master.dbo.mondeadlock.HeldLineNumber, 
	master.dbo.mondeadlock.WaitFamilyID, 
	master.dbo.mondeadlock.WaitSPID, 
	master.dbo.mondeadlock.WaitKPID, 
	master.dbo.mondeadlock.WaitTime, 
	master.dbo.mondeadlock.ObjectName, 
	master.dbo.mondeadlock.HeldUserName,
	master.dbo.mondeadlock.HeldApplName, 
	master.dbo.mondeadlock.HeldTranName, 
	master.dbo.mondeadlock.HeldLockType, 
	master.dbo.mondeadlock.HeldCommand, 
	master.dbo.mondeadlock.WaitUserName, 
	master.dbo.mondeadlock.WaitLockType 
--	into mondeadlocks_DB1
	from master.dbo.mondeadlock 
	where master.dbo.mondeadlock.ResolveTime > @maxresolvetime
END
go
EXEC sp_procxmode 'dbo.mondeadlocks_collector', 'unchained'
go
IF OBJECT_ID('dbo.mondeadlocks_collector') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.mondeadlocks_collector >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.mondeadlocks_collector >>>'
go
