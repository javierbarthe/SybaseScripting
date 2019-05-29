USE mon_db
go
IF OBJECT_ID('dbo.monSpinlockActivity_collector') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monSpinlockActivity_collector
    IF OBJECT_ID('dbo.monSpinlockActivity_collector') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monSpinlockActivity_collector >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monSpinlockActivity_collector >>>'
END
go
CREATE PROCEDURE dbo.monSpinlockActivity_collector
AS
BEGIN
insert into monspinlockactivity_DB1
select
getdate() as SampleTime,
Grabs, Spins, Waits, OwnerPID, LastOwnerPID, Contention, InstanceID, SpinlockSlotID, SpinlockName
--into monspinlockactivity_DB1
from master..monspinlockactivity
END
go
EXEC sp_procxmode 'dbo.monSpinlockActivity_collector', 'unchained'
go
IF OBJECT_ID('dbo.monSpinlockActivity_collector') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monSpinlockActivity_collector >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monSpinlockActivity_collector >>>'
go
