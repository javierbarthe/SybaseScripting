IF OBJECT_ID('dbo.db_monitor_space') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.db_monitor_space
    IF OBJECT_ID('dbo.db_monitor_space') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.db_monitor_space >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.db_monitor_space >>>'
END
go
create procedure db_monitor_space
as
begin 
select [master]..sysusages.dbid, [master]..sysusages.segmap, [master]..sysusages.lstart, [master]..sysusages.size, [master]..sysusages.vstart, [master]..sysusages.location, [master]..sysusages.unreservedpgs, [master]..sysusages.crdate, [master]..sysusages.vdevno into #tmp1 from master..sysusages

select [master]..sysdatabases.name, [master]..sysdatabases.dbid, [master]..sysdatabases.suid, [master]..sysdatabases.status, [master]..sysdatabases.version, [master]..sysdatabases.logptr, [master]..sysdatabases.crdate, [master]..sysdatabases.dumptrdate, [master]..sysdatabases.status2, [master]..sysdatabases.audflags, [master]..sysdatabases.deftabaud, [master]..sysdatabases.defvwaud, [master]..sysdatabases.defpraud, [master]..sysdatabases.def_remote_type, [master]..sysdatabases.def_remote_loc, [master]..sysdatabases.status3, [master]..sysdatabases.status4, [master]..sysdatabases.audflags2, [master]..sysdatabases.spare, [master]..sysdatabases.durability, [master]..sysdatabases.lobcomp_lvl, [master]..sysdatabases.inrowlen, [master]..sysdatabases.dcompdefaultlevel into #tmp2 from master..sysdatabases order by status2

Select "ID" = ltrim(rtrim(convert(char(6),t1.dbid))), "DB"= left(db_name(t1.dbid),20),
 "Datos" = convert(int,sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) then @@maxpagesize/1024.*t1.size/1024 
                                                               else null 
                                                                   end)),
             "DatosLibre" = convert(int,str(sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) 
                                                                                 then @@maxpagesize/1024.*curunreservedpgs(t1.dbid,t1.lstart, t1.unreservedpgs)/1024 
                                                                                 else null 
                                                                                  end),11,0)),
             "DatosLibreGB" = convert(integer,str(sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) 
                                                                                         then @@maxpagesize/1024.*curunreservedpgs(t1.dbid,t1.lstart, t1.unreservedpgs)/1024 
                                                                                         else null 
                                                                                          end),11,0))/1024,
             "porcentaje"= (
                                        ((convert(int,str(sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) 
                                                                                    then @@maxpagesize/1024.*curunreservedpgs(t1.dbid,t1.lstart, t1.unreservedpgs)/1024 
                                                                                    else null 
                                                                                    end),11,0)))*100)/
                                        (convert(int,sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) 
                                                                             then @@maxpagesize/1024.*t1.size/1024 
                                                                             else null 
                                                                             end)))
                                        ),
             "Log" = isnull(str(sum(case when t1.segmap=4 
                                                            then @@maxpagesize/1024.*t1.size/1024 
                                                            else null 
                                                            end),11) ,"          -"),
             "LogGB" = isnull(convert(int,(str(sum(case when t1.segmap=4 
                                                            then @@maxpagesize/1024.*t1.size/1024 
                                                             else null 
                                                            end),11)))/1024 ,0),
             "LogLibre" = str(@@maxpagesize/1024.*lct_admin("logsegment_freepages", t1.dbid) /1024,11,0),
             "LogLibreGB" = convert(int,str(@@maxpagesize/1024.*lct_admin("logsegment_freepages", t1.dbid) /1024,11,0))/1024, 
             "porcloglibre"= (convert(int,str(@@maxpagesize/1024.*lct_admin("logsegment_freepages", t1.dbid) /1024,11,0))*100)/
                             (isnull(convert(int,(str(sum(case when t1.segmap=4 
                                                                                  then @@maxpagesize/1024.*t1.size/1024 
                                                                                  else null 
                                                                                   end),11))) ,0))
    from #tmp1 t1, 
         #tmp2 t2
   where t1.dbid = t2.dbid
   and db_name(t1.dbid) not in ('master','tempdb','model','sybsystemdb','sybsystemprocs')
   group by t1.dbid
  having ((
          ((convert(int,str(sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) 
                                     then @@maxpagesize/1024.*curunreservedpgs(t1.dbid,t1.lstart, t1.unreservedpgs)/1024 
                                     else null 
                                     end),11,0)))*100)/
                 convert(int,sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) 
                                      then @@maxpagesize/1024.*t1.size/1024 
                                      else null 
                                      end))
               )<= 1 
     and (convert(int,str(sum(case when (t1.segmap!=4 and t1.segmap not in (8,9,11)) 
                                   then @@maxpagesize/1024.*curunreservedpgs(t1.dbid,t1.lstart, t1.unreservedpgs)/1024 
                                   else null 
                                   end),11,0)))<=1001     )
      or ((convert(int,str(@@maxpagesize/1024.*lct_admin("logsegment_freepages", t1.dbid) /1024,11,0))*100)/
                             (isnull(convert(int,(str(sum(case when t1.segmap=4 
                                                                                  then @@maxpagesize/1024.*t1.size/1024 
                                                                                  else null 
                                                                                   end),11))) ,0))) < 10
order by left(db_name(t1.dbid),20)

end
go
EXEC sp_procxmode 'dbo.db_monitor_space', 'unchained'
go