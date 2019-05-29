USE mon_db
go
IF OBJECT_ID('dbo.monTablesActivity_collector') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monTablesActivity_collector
    IF OBJECT_ID('dbo.monTablesActivity_collector') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monTablesActivity_collector >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monTablesActivity_collector >>>'
END
go
CREATE PROCEDURE dbo.monTablesActivity_collector
AS
BEGIN
insert into monOpenObjectActivity_DB1
select 
getdate() as SampleTime,
DBID, ObjectID, IndexID, InstanceID, DBName, ObjectName, LogicalReads, PhysicalReads, APFReads, PagesRead, PhysicalWrites, 
PagesWritten, RowsInserted, RowsDeleted, RowsUpdated, Operations, LockRequests, LockWaits, OptSelectCount, LastOptSelectDate, 
UsedCount, LastUsedDate, HkgcRequests, HkgcPending, HkgcOverflows, PhysicalLocks, PhysicalLocksRetained, PhysicalLocksRetainWaited, 
PhysicalLocksDeadlocks, PhysicalLocksWaited, PhysicalLocksPageTransfer, TransferReqWaited, AvgPhysicalLockWaitTime, MaxPhysicalLockWaitTime, 
AvgTransferReqWaitTime, MaxTransferReqWaitTime, TotalServiceRequests, PhysicalLocksDowngraded, PagesTransferred, ClusterPageWrites, AvgServiceTime, MaxServiceTime, 
AvgQueueWaitTime, MaxQueueWaitTime, AvgTimeWaitedOnLocalUsers, MaxTimeWaitedOnLocalUsers, AvgTransferSendWaitTime, MaxTransferSendWaitTime, AvgIOServiceTime, MaxIOServiceTime, 
AvgDowngradeServiceTime, MaxDowngradeServiceTime, SharedLockWaitTime, ExclusiveLockWaitTime, UpdateLockWaitTime, ObjectCacheDate, HkgcRequestsDcomp, HkgcPendingDcomp, HkgcOverflowsDcomp, 
IOSize1Page, IOSize2Pages, IOSize4Pages, IOSize8Pages, PRSSelectCount, LastPRSSelectDate, PRSRewriteCount, LastPRSRewriteDate, NumLevel0Waiters, AvgLevel0WaitTime
from master..monOpenObjectActivity
END
go
EXEC sp_procxmode 'dbo.monTablesActivity_collector', 'unchained'
go
IF OBJECT_ID('dbo.monTablesActivity_collector') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monTablesActivity_collector >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monTablesActivity_collector >>>'
go
