#!/bin/sh

startTime=235959
perDate=$(date "+%Y%m%d")
isNewDay="1"
isFirstTime="1"
yes="1"
no="0"

while true ; do
	curTime=$(date "+%H%M%S")
	curDate=$(date "+%Y%m%d")
	if [ $isNewDay = $yes ] ; then
		if [ $curTime -gt $startTime ] ; then
			if [ $isFirstTime = $no ] ; then
				bash /home/user1/cluster/no_classify_bbsclusterrun.sh
				echo $curDate $curTime >> run_log
			fi
			isNewDay=$yes
		else
			if [ $isFirstTime = $yes ] ; then
				isFirstTime=$no
			fi
		fi
	else
		if [ $curDate -gt $perDate ] ; then
			isNewDay=$yes
			perDate=$curDate
		fi
	fi
	sleep 1
done
