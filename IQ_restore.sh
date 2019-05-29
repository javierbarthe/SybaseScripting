#!/usr/bin/ksh

export LANG="en_US"
. /sybase/IQ.sh > /dev/null 2>&1

PathControl=/home/sybase/controles/IQ_Restore/

echo "RESTORE DATABASE '/sybaseiq/DW.db' FROM '/backup/BKPIQ/IQ_full.bck'" > ${PathControl}restore.sql
echo "RENAME IQ_SYSTEM_MAIN TO '/sybaseiq/devices/rdev_sys_main'" >> ${PathControl}restore.sql
echo "RENAME IQ_SYSTEM_TEMP TO '/sybaseiq/devices/rdev_sys_tmp'" >> ${PathControl}restore.sql
echo "RENAME IQ_USER_MAIN_1 TO '/sybaseiq/devices/rdev_usr_main_1'" >> ${PathControl}restore.sql
echo "RENAME IQ_USER_MAIN_2 TO '/sybaseiq/devices/rdev_usr_main_2'" >> ${PathControl}restore.sql
echo "go" >> ${PathControl}restore.sql
sleep 15

stop_iq -stop all
sleep 15

#########################################################################################################################################################################################################
#MIG
start_iq -n util_db -x 'tcpip{port=1888}' 
sleep 10
#########################################################################################################################################################################################################
chequeomotor2=`ps -efa | grep "iqsrv16 -n util_db" | grep -v grep | wc -l`

if [ ${chequeomotor2} -eq 0 ]
        then
        mail -s "DB RESTORE" dba@mail.com.ar < ${PathControl}errorutil_db.mail
        exit
fi
#########################################################################################################################################################################################################
	cd $SYBASE
	rm -f DW.db
	sleep 2
	rm -f DW.iqmsg
	sleep 2
	rm -f DW.log
	sleep 10
	
dbisql -nogui -c "uid=dba;password=sql;eng=util_db;dbn=utility_db" -host 192.168.xx.xx -port 1888 ${PathControl}restore.sql > ${PathControl}restore.out
sleep 15

stop_iq -stop all

sleep 15

#########################################################################################################################################################################################################

cd /sybaseiq/
sh start_iq16.sh
sleep 5

#########################################################################################################################################################################################################
chequeomotor4=`ps -efa | grep "/sybase/IQ-16_0/bin64/iqsrv16" | grep -v grep | wc -l`

if [ ${chequeomotor4} -eq 0 ]
    then
mail -s "DB RESTORE" dba@mail.com.ar < ${PathControl}start_iq16.mail
exit
fi

echo "Finalizo el restore de DW " > ${PathControl}Aviso.msg
echo "." >> ${PathControl}Aviso.msg
mail -s "DB RESTORE" dba@mail.com.ar < ${PathControl}Aviso.msg
