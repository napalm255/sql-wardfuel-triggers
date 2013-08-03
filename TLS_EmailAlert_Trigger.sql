CREATE TRIGGER TLS_EmailAlert_Trigger ON [dbo].[TLS_Alarm_History] 
FOR INSERT, UPDATE 
AS
IF (SELECT Notified FROM Inserted) = 0
BEGIN
IF (SELECT TLS_Alarms.Page
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0))) = 1
BEGIN
declare @SiteName varchar(255)
select @SiteName = (SELECT Sites.Site_Name
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

declare @SiteCode varchar(255)
select @SiteCode = (SELECT Sites.Code
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

declare @TLSNumber varchar(255)
select @TLSNumber = (SELECT TLS.TLS_Number
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

declare @AlarmTime varchar(255)
select @AlarmTime = (SELECT Inserted.Time
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

declare @AlarmCategory varchar(255)
select @AlarmCategory = (SELECT TLS_Alarms.Category_Description
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

declare @AlarmType varchar(255)
select @AlarmType = (SELECT TLS_Alarms.Type_Description
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

declare @AlarmMSG varchar(255)
select @AlarmMSG = (SELECT TLS_Alarms.TLS_Alarm_Message
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

declare @PagerNotified varchar(255)
select @PagerNotified = (SELECT Inserted.Notified
FROM Sites INNER JOIN ((Inserted INNER JOIN TLS_Alarms ON Inserted.fkTLS_Alarm_ID = TLS_Alarms.TLS_Alarm_ID) INNER JOIN TLS ON Inserted.fkTLS_ID = TLS.TLS_ID) ON Sites.Site_ID = TLS.fkSite_ID
WHERE (((Sites.Date_Deleted) Is Null) AND ((TLS.Date_Deleted) Is Null)) AND ((Alarm_Type<>0) OR (Category<>0)))

/* Query Email Settings */
declare @emailWait int
declare @emailCount int
select @emailWait = (SELECT sWaitMinutes FROM EmailSettings WHERE sID = 1)
select @emailCount = (SELECT sEmailCount FROM EmailSettings WHERE sID = 1)
set @emailCount = @emailCount + 1

/* Compare Timestamps */
declare @timeNow datetime
declare @timeDiff varchar(255)
declare @timeAlert datetime
select @timeAlert = (select top 1 sEmailTime from EmailAlerts WHERE sSiteCode = @SiteCode AND sTLSNumber = @TLSNumber AND sAlarmMsg = @AlarmMSG ORDER BY sEmailTime DESC)
set @timeNow = getdate()
select @timeDiff = (select Cast(Left(CAST(DateDiff(ss, @timeAlert, @timeNow)/60 as float)/60,CharIndex('.', CAST(DateDiff(ss, @timeAlert, @timeNow)/60 as float)/60)-1) as varchar) + ':' + Cast(Round(Cast(Substring(CAST(CAST(DateDiff(ss, @timeAlert, @timeNow)/60 as float)/60 AS varchar), CharIndex('.', CAST(DateDiff(ss, @timeAlert, @timeNow)/60 as float)/60),4) as float)*60,0) as varchar))

declare @delimiter varchar(255)
declare @diffHour int
declare @diffMin int
set @delimiter = charindex(':',@timeDiff)
set @diffHour = left(@timeDiff,@delimiter-1)
set @diffMin = right(@timeDiff,len(@timeDiff)-@delimiter)

IF (@timeAlert is not null)
BEGIN
	/* Record Found */
	IF (@diffHour = 0) AND (@diffMin < @emailWait)
	BEGIN
		declare @alertID int
		select @alertID = (select top 1 sID from EmailAlerts WHERE sSiteCode = @SiteCode AND sTLSNumber = @TLSNumber AND sAlarmMsg = @AlarmMSG ORDER BY sEmailTime DESC)
		IF (select top 1 sEmailCount from EmailAlerts WHERE sSiteCode = @SiteCode AND sTLSNumber = @TLSNumber AND sAlarmMsg = @AlarmMSG ORDER BY sEmailTime DESC) < @emailCount
		BEGIN
			update EmailAlerts set sAlarmTime = @AlarmTime, sEmailTime = getdate(), sEmailCount = sEmailCount+1 where sID = @alertID
		END
		ELSE
		BEGIN
			update EmailAlerts set sAlarmTime = @AlarmTime where sID = @alertID
		END
	END
	ELSE
	BEGIN
		/* Record Not Found */
		insert into EmailAlerts (sSiteName, sSiteCode, sTLSNumber, sAlarmTime, sAlarmCategory, sAlarmType, sAlarmMsg, sEmailTime, sEmailCount) VALUES (@SiteName,@SiteCode,@TLSNumber,@AlarmTime,@AlarmCategory,@AlarmType,@AlarmMSG,getdate(),1)
	END
END
ELSE
BEGIN
	/* Record Not Found */
	insert into EmailAlerts (sSiteName, sSiteCode, sTLSNumber, sAlarmTime, sAlarmCategory, sAlarmType, sAlarmMsg, sEmailTime, sEmailCount) VALUES (@SiteName,@SiteCode,@TLSNumber,@AlarmTime,@AlarmCategory,@AlarmType,@AlarmMSG,getdate(),1)
END


END
END
