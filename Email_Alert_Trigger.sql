CREATE TRIGGER Email_Alert_Trigger ON [dbo].[EmailAlerts] 
FOR INSERT, UPDATE 
AS

/* Query Email Settings */
declare @emailWait int
declare @semailCount int
select @emailWait = (SELECT sWaitMinutes FROM EmailSettings WHERE sID = 1)
select @semailCount = (SELECT sEmailCount FROM EmailSettings WHERE sID = 1)
set @semailCount = @semailCount + 1

/* Query Email Address */
declare @emailDesktop varchar(255)
declare @emailCell varchar(255)
select @emailDesktop = (SELECT sEmail FROM EmailUsers WHERE sType = 'desktop')
select @emailCell = (SELECT sEmail FROM EmailUsers WHERE sType = 'cell')

/* Process */
IF (SELECT sEmailCount FROM Inserted) < @semailCount
BEGIN
declare @SiteName varchar(255)
select @SiteName = (SELECT sSiteName FROM Inserted)
declare @SiteCode varchar(255)
select @SiteCode = (SELECT sSiteCode FROM Inserted)
declare @TLSNumber varchar(255)
select @TLSNumber = (SELECT sTLSNumber FROM Inserted)
declare @AlarmTime varchar(255)
select @AlarmTime = (SELECT sAlarmTime FROM Inserted)
declare @AlarmCategory varchar(255)
select @AlarmCategory = (SELECT sAlarmCategory FROM Inserted)
declare @AlarmType varchar(255)
select @AlarmType = (SELECT sAlarmType FROM Inserted)
declare @AlarmMSG varchar(255)
select @AlarmMSG = (SELECT sAlarmMsg FROM Inserted)
declare @EmailCount varchar(255)
select @EmailCount = (SELECT sEmailCount FROM Inserted)

/* Initialize Email */
declare @sub varchar(255)
declare @msg varchar(255)

/* Send Email to Desktop Email */
set @sub = @SiteCode + '*' + @AlarmMSG
set @msg = 'Site Name: ' + @SiteName + char(10) + 'Site Code: ' + @SiteCode + char(10) + 'TLS Number: ' + @TLSNumber + char(10) + 'Alarm Time: ' + @AlarmTime + char(10) + 'Alarm Category: ' + @AlarmCategory + char(10) + 'Alarm Type: ' + @AlarmType + char(10) + 'Alarm Message: ' + @AlarmMSG + char(10) + 'Email Count: ' + @EmailCount
exec master..xp_smtp_sendmail @from=N'FuelSystem@baltimorecity.gov', @from_name=N'FuelSystem', @to=@emailDesktop, @subject=@sub, @message=@msg,@server=N'balt-exfe1-srv'

/* Send Email to Cell Phones */
set @sub = ''
set @msg = @SiteName + ' (' + @SiteCode + '*' + @AlarmMsg + ')' + char(10) + 'TLS Number: ' + @TLSNumber + char(10) + 'Alarm Time: ' + @AlarmTime + char(10) + 'Alarm Type: ' + @AlarmType
exec master..xp_smtp_sendmail @from=N'FuelSystem@baltimorecity.gov', @from_name=N'FuelSystem', @to=@emailCell, @subject=@sub, @message=@msg,@server=N'balt-exfe1-srv'

END
ELSE
BEGIN
print 'Max Email Count Reached'
END
