CREATE PROC sp_thresholdaction
     @dbname varchar(30),  
     @segmentname varchar(30),  
     @free_space int,  
     @status int  as  
begin  
print "Warning, not enough space in '%1!' segment - DB: '%2!'", @segmentname, @dbname 

dump transaction @dbname with truncate_only  print "LOG DUMP: '%1!' for '%2!' dumped", @segmentname, @dbname 

en