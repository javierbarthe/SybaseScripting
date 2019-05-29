#!/usr/bin/ksh

#
# monitorcfg.sql
# sp_monitorconfig 'all'
#
# sysmon.sql (I/O better clear or MDA)
# exec sp_sysmon '00:02:00', "noclear" 
#
#
#
export LANG="en_US"
. $SYBASE/SYBASE.sh > /dev/null 2>&1

fecha=$(date "+%Y_%-b%-d_%-H_%M")
fechaA=$(date "+%Y")
fechaM=$(date "+%-b")
fechaD=$(date "+%-d")
fechah=$(date "+%-H")
fecham=$(date "+%M")

if [[ -z ${fechah} ]] ; then
        fechah=00
        fecha=${fechaA}_${fechaM}${fechaD}_${fechah}_${fecham}
fi

#VARIABLES
User=`grep -w "USER" /home/sybase/params.txt | awk '{print $2}'`
Pass=`grep -w "PASS" /home/sybase/params.txt | awk '{print $2}'`
Srv=`grep -w "SERVER_5200" /home/sybase/params.txt | awk '{print $2}'`

Path=$Controles/Sysmon/

archivo=${Path}${fecha}.txt

isql -U${User} -P${Pass} -S${Srv} -i${Path}sysmon.sql -o${Path}${fecha}.txt -w300 -Jiso_1

isql -U${User} -P${Pass} -S${Srv} -i${Path}monitorcfg.sql -o${Path}monitorcfg.out -w300 -Jiso_1

cat ${Path}monitorcfg.out >> ${Path}${fecha}.txt
rm ${Path}monitorcfg.out


#variables configurables
anio=$(date "+%Y")
mes=$(date "+%m")
ambiente=$Srv

if [ ! -d "/backup/sysmon/$ambiente/$anio" ]; then
  mkdir /backup/sysmon/$ambiente/$anio
fi

if [ ! -d "/backup/sysmon/$ambiente/$anio/$mes" ]; then
  mkdir /backup/sysmon/$ambiente/$anio/$mes
fi

mv ${Path}${fecha}.txt /backup/sysmon/$ambiente/$anio/$mes/

