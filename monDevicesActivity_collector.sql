USE mon_db
go
IF OBJECT_ID('dbo.monDevicesActivity_collector') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monDevicesActivity_collector
    IF OBJECT_ID('dbo.monDevicesActivity_collector') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monDevicesActivity_collector >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monDevicesActivity_collector >>>'
END
go
CREATE PROCEDURE dbo.monDevicesActivity_collector
AS
BEGIN
insert into mon_db..monIQQueue_db1
select getdate() as Fecha,InstanceID, IOs, IOTime, LogicalName, IOType
--into monIQQueue_db1
from master..monIOQueue
insert into mon_db..monDeviceIO_DB1
select getdate() as Fecha,InstanceID, Reads, APFReads, Writes, DevSemaphoreRequests, DevSemaphoreWaits, IOTime, ReadTime, WriteTime, LogicalName, PhysicalName
--into monDeviceIO_DB1
from master..monDeviceIO
END
go
EXEC sp_procxmode 'dbo.monDevicesActivity_collector', 'unchained'
go
IF OBJECT_ID('dbo.monDevicesActivity_collector') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monDevicesActivity_collector >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monDevicesActivity_collector >>>'
go
