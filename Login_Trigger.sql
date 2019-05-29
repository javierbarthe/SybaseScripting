USE master
go
IF OBJECT_ID('dbo.Trigg_instanceDBA') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.Trigg_instanceDBA
    IF OBJECT_ID('dbo.Trigg_instanceDBA') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.Trigg_instanceDBA >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.Trigg_instanceDBA >>>'
END
go
Create proc dbo.Trigg_instanceDBA as  

    declare @aplicacion varchar(100)
	declare @loginname varchar(32) 
	declare @hostname varchar(32)   
    declare @usuarioid varchar(10) 
    declare @usuarioid_int int 
	declare @Conect_usrApp_ok int
	declare @Conect_usr_privilege_BCP int
	declare @ip			varchar(64) 
	
	select @aplicacion = get_appcontext ("SYS_SESSION", "applname")	 
	select @usuarioid = get_appcontext ("SYS_SESSION", "suserid")	 
	
	set @usuarioid_int = cast(@usuarioid as int)
	
	if  (   @aplicacion = 'bcp' 
		and suser_name() not like 'SSIS_%'
		and suser_name() not in ('implementacion','prdadmin')
		)
	begin
		
		set @loginname = suser_name() 
		
		set @Conect_usr_privilege_BCP = 0
		
		select 
			@Conect_usr_privilege_BCP = 1
		from DBA_login_privilege_BCP
		where 	login = @loginname
			and fecha_baja is null
		
		if @Conect_usr_privilege_BCP = 0
		begin
			
			insert into master..AbortedLogins_trigger values (getdate(),@loginname,@aplicacion,@hostname,@ip, 'Error BCP')  
			print "Login Abortado [%1!]: Ingreso no Autorizado con BCP desde [%2!]", @loginname, @aplicacion 
			select syb_quit()
		end
		
	end
	
	if  (@aplicacion in 
	('ASE isql','DBArtisan','SQL_Advantage','Aqua_Data_Studio','PowerBuilder','SC_ASEJ_Mgmt','Embarcadero IntelliSense','jTDS') 
	or @aplicacion like 'sqldbx%'
	or @aplicacion like 'Centura SQLWindows%'
	or @aplicacion like 'Gupta Team Developer%')
	and
	@usuarioid_int not in (20,5430,5129,1,5443,7963,2044,8245,6697,4321,8524)
		
	begin
        select @loginname = suser_name() 
        select @hostname = get_appcontext ("SYS_SESSION", "hostname")  
		insert into master..AbortedLogins_trigger values (getdate(),@loginname,@aplicacion,@hostname,@ip, 'Error aplicacion No Autorizada')  
        print "Login Abortado [%1!]: Ingreso no Autorizado desde [%2!]", @loginname, @aplicacion 
        select syb_quit()   	
	end
	
	if  (@aplicacion is null or rtrim(ltrim(@aplicacion)) = '')
	and	suser_name() 
		in (
			'user2',
			'user3'
			)
	begin
		set @hostname = get_appcontext ("SYS_SESSION", "hostname")  
		
		set @Conect_usrApp_ok = 0
		
		select 
			@Conect_usrApp_ok = 1
		from DBA_trg_SrvApp_HostName
		where HostName = @hostname
		
		if @Conect_usrApp_ok = 0
		begin
		
			if @hostname is null
			begin
				select
					@ip = ipaddr
					
				from sysprocesses
				where spid = @@spid
			end
			
			select 
				@Conect_usrApp_ok = 1
				
			from DBA_trg_SrvApp_HostName
			where ipaddr = @ip
			
			if @Conect_usrApp_ok = 0
			begin
			
				select @loginname = suser_name() 
				insert into master..AbortedLogins_trigger values (getdate(),@loginname,@aplicacion,@hostname,@ip, 'Error Servidor No Autorizado')  
				print "Login Abortado [%1!]: Ingreso no Autorizado desde [%2!]", @loginname, @aplicacion 
				select syb_quit()   	
				
			end
			
		end
		
	end
go
EXEC sp_procxmode 'dbo.Trigg_instanceDBA', 'unchained'
go
IF OBJECT_ID('dbo.Trigg_instanceDBA') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.Trigg_instanceDBA >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.Trigg_instanceDBA >>>'
go
REVOKE EXECUTE ON dbo.Trigg_instanceDBA FROM public
go
GRANT EXECUTE ON dbo.Trigg_instanceDBA TO public
go
