#!/bin/bash
#设置mahout本地运行，不允许在hadoop上
export MAHOUT_LOCAL=T

time2=$(date '+%s')
time1=$(date -d '-1 week' '+%s')

while read line
do
	bbs_name=$line
	echo $bbs_name
	#获取需要聚类的文件
	#java -jar ~/Desktop/HBaseOperation.jar $time1 $time2 $bbs_name

	rm -rf /home/user1/cluster/byr_classify/*
	mkdir /home/user1/cluster/byr_classify/AD/
	mkdir /home/user1/cluster/byr_classify/ART/
	mkdir /home/user1/cluster/byr_classify/BBS/
	mkdir /home/user1/cluster/byr_classify/ENTERTAINMENT/
	mkdir /home/user1/cluster/byr_classify/HOME/
	mkdir /home/user1/cluster/byr_classify/LIFE/
	mkdir /home/user1/cluster/byr_classify/SCHOOL/
	mkdir /home/user1/cluster/byr_classify/JOB/
	mkdir /home/user1/cluster/byr_classify/STUDY/
	mkdir /home/user1/cluster/byr_classify/TECHNOLOGY/
	rm -f /home/user1/cluster/byr_classify_file

	#classify
	java -jar ~/Desktop/ClassifyOperation.jar

	bash /home/user1/cluster/bbs_cluster.sh ART
	awk -F '\t' '{print "人文艺术\t"$0}' /home/user1/cluster/result >/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh BBS
	awk -F '\t' '{print "论坛事务\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh ENTERTAINMENT
	awk -F '\t' '{print "体育娱乐\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh HOME
	awk -F '\t' '{print "温暖家乡\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh LIFE
	awk -F '\t' '{print "生活时尚\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh SCHOOL
	awk -F '\t' '{print "学校生活\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh JOB
	awk -F '\t' '{print "工作招聘\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh STUDY
	awk -F '\t' '{print "学习交流\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh TECHNOLOGY
	awk -F '\t' '{print "科学技术\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data
	bash /home/user1/cluster/bbs_cluster.sh AD
	awk -F '\t' '{print "广告信息\t"$0}' /home/user1/cluster/result >>/home/user1/cluster/data

	rm -f /home/user1/cluster/result

	bash /home/user1/cluster/sql.sh $bbs_name

done < /home/user1/cluster/bbs_to_run


#mkdir /home/user1/cluster/data
