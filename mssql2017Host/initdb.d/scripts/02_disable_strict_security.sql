EXEC sys.sp_configure N'show advanced options', N'1';
RECONFIGURE WITH OVERRIDE;
EXEC sys.sp_configure N'clr strict security', N'0';
RECONFIGURE WITH OVERRIDE;
EXEC sys.sp_configure N'show advanced options', N'0';
RECONFIGURE WITH OVERRIDE;
GO
