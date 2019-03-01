#!/bin/bash

#设置mahout本地运行，不允许在hadoop上
export MAHOUT_LOCAL=T

#获取词典
echo "开始生成话题关键词典..."
source /home/user1/cluster/mysql.sh

select_sql="SELECT word FROM White_noun WHERE word NOT IN(SELECT word FROM Black_noun WHERE support<against)
UNION
SELECT word FROM Primary_noun WHERE word NOT IN(SELECT word FROM Black_noun WHERE support<against)"

mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster_Dict} -e "${select_sql}" >/home/user1/cluster/all_noun.dict

echo "话题关键词典生成完毕..."

time2=$(date '+%s')
time1=$(date -d '-1 week' '+%s')
while read line
do
	bbs_name=$line
	echo $bbs_name
	#获取需要聚类的文件
	#java -jar ~/Desktop/HBaseOperation.jar $time1 $time2 $bbs_name
	rm -rf /home/user1/cluster/hdfs_output
	mkdir /home/user1/cluster/hdfs_output
#	首先尝试只取主帖
	cd /home/user1/cluster/HBaseHandlerJar
	java -jar HBaseHandler.jar $bbs_name 1 week > hbase_get.log
	cd /home/user1/cluster

	#判断文件夹中是否有数据
#	file_num=`ls /home/user1/cluster/hdfs_output | wc -l`
#	if [ $file_num -lt 50 ]; then
#		#如果未取到数据或者数据条目较少，则尝试取从帖
#		cd /home/user1/cluster/HBaseHandlerJar
#      		java -jar HBaseHandler.jar $bbs_name 1 week allPost >> hbase_get.log
#       	cd /home/user1/cluster
#	fi
#	file_num=`ls /home/user1/cluster/hdfs_output | wc -l`
#	if [ $file_num -lt 50 ]; then
#               #如果未取到数据或数据条目较少，则尝试取1个月的从帖
#               cd /home/user1/cluster/HBaseHandlerJar
#               java -jar HBaseHandler.jar $bbs_name 1 month allPost >> hbase_get.log
#               cd /home/user1/cluster
#       fi

	#打印日志
	file_num=`ls /home/user1/cluster/hdfs_output | wc -l`
	if [ $file_num -eq 0 ]; then
		echo $bbs_name" has no data in hbase this week..."
		continue
	else
		echo $bbs_name" has "$file_num" files this week..."
	fi
	
	bash /home/user1/cluster/no_classify_bbscluster.sh hdfs_output >> cluster_log

	#rm -f /home/user1/cluster/result

	bash /home/user1/cluster/sql.sh $bbs_name

done < /home/user1/cluster/bbs_to_run


#mkdir /home/user1/cluster/data
