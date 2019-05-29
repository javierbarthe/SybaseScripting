#!/usr/bin/ksh

EXCLUDE="cob_distrib|sys|master|model|sybs"



RestoreBase(){
	echo "---Restore base $1----"
	base=$(echo "$1"|awk -F/ '$0=$4')
	base_s0=$1_s0.dmp
	acum="use master\ngo\nload database $base from '$base_s0' \n"
	
	####acum2=$(ls $1_s*.dmp|grep -v _s0.dmp| awk '{ printf " \n \t stripe on '\''%s'\'' \n",$1 }')
	ls $1_s*.dmp|grep -v _s0.dmp|while read s_dmp
	do
		acum="$acum\n \t stripe on '$s_dmp' \n"
	done
	echo $acum
	echo "----------------------"
}

PathUltimosBackups=$(find /dumps -type d -name 'BKP_*' 2>/dev/null|grep -v antes|sort|tail -1)

echo ${PathUltimosBackups}

find ${PathUltimosBackups} -type f -name '*.dmp' |sed "s:_s[0-9]\.dmp::"|uniq|egrep -v "(${EXCLUDE})"|while read cadabase
do
	RestoreBase $cadabase

done




