CREATE PROC sp_threshold_default 

     @dbname varchar(30),  

     @segmentname varchar(30),  

     @free_space int,  

     @status int  as  

begin  

print "Warning, not enough space in '%1!' segment - DB: '%2!'", @segmentname, @dbname 

end