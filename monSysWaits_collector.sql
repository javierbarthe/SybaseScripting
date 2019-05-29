USE mon_db
go
IF OBJECT_ID('dbo.monSysWaits_collector') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.monSysWaits_collector
    IF OBJECT_ID('dbo.monSysWaits_collector') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.monSysWaits_collector >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.monSysWaits_collector >>>'
END
go
CREATE PROCEDURE dbo.monSysWaits_collector
AS
BEGIN
        insert into mon_db..monSysWaits_DB1
        select 	getdate() as SampleTime,
				w.Waits, w.WaitTime, w.WaitEventID, i.Description
        --into mon_db..monSysWaits_DB1
        from master..monSysWaits w, master..monWaitEventInfo i
        where w.WaitEventID = i.WaitEventID
END
go
EXEC sp_procxmode 'dbo.monSysWaits_collector', 'unchained'
go
IF OBJECT_ID('dbo.monSysWaits_collector') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.monSysWaits_collector >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.monSysWaits_collector >>>'
go
