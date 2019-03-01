#!/bin/bash
source ./mysql.sh
#定义路径
TXTPATH=user
TEXTPATH=user-seq
VECTORPATH=user-sparse
CLUSTERPATH=user-kmeans
CLUSTERDUMP_FILE=user-kmeans-cluster-dump
CLUSTERPOINT_FILE=user-clusteredPoints

#设置mahout本地运行，不允许在hadoop上
export MAHOUT_LOCAL=T

#mysql参数

#获取需要监测的用户列表
select_sql="select distinct uid,short_id from ${TABLE_SpiderUser}"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_User} -e "${select_sql}" >monitor_user

#获取关键词-话题字典
select_sql="select topic,top_terms from ${TABLE_Trans}"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "${select_sql}" >topic_words

#对每个uid进行聚类
cat monitor_user | awk 'NR>1' | while read uid bbs_name
do
	#从数据库获取此uid的所有帖子
	DBNAME_BBS="ipom_spider_"$bbs_name
	get_userdata_sql="select * from article where uid='${uid}'"
	mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DBNAME_BBS} -e "${get_userdata_sql}" >$uid"_file"
	#为此uid建立本地目录
	mkdir user
	awk -F '\t' '{print $6"\n"$7>"user/""'$bbs_name'""_"$1"_"$2"_""'$uid'" ;close ("user/""'$bbs_name'""_"$1"_"$2"_""'$uid'");}' $uid"_file"

	#聚类过程
	# 文本目录->SequenceFile 本地运行
	# 生成TEXTPATH
	mahout seqdirectory -i file://$(pwd)/$TXTPATH/ -o file://$(pwd)/$TEXTPATH/ -c UTF-8 -xm sequential -ow

	# text->Vector
	# 生成VECTORPATH
	mahout seq2sparse -i $TEXTPATH -o $VECTORPATH -ow -wt tfidf -lnorm -nv -a  org.wltea.analyzer.lucene.IKAnalyzer --maxDFPercent 70 --namedVector

	# Run K-Means
	mahout kmeans -i $VECTORPATH/tfidf-vectors -k 8 -c bbs-kmeans-clusters -o $CLUSTERPATH  -dm org.apache.mahout.common.distance.CosineDistanceMeasure -x 200 --convergenceDelta 0.01 -ow --clustering
	# Run Fuzzy-K-Means
	#mahout fkmeans -i $VECTORPATH/tfidf-vectors -k 20 -c bbs-kmeans-clusters -o $CLUSTERPATH -dm org.apache.mahout.common.distance.CosineDistanceMeasure -m 1.05 -x 200 -ow --clustering --convergenceDelta 0.01

	# 得到聚类结果
	mahout clusterdump -i $CLUSTERPATH/clusters-*-final -d ./$VECTORPATH/dictionary.file-0 -dt sequencefile -o ./$CLUSTERDUMP_FILE/ -n 10

	mahout seqdumper -i $CLUSTERPATH/clusteredPoints/ -o ./$CLUSTERPOINT_FILE

	#分析聚类结果，生成所需数据文件
	awk -F '=' '{if(NR%12==1){print $1"="$2} if(NR%12!=1&&NR%12!=2){print $1$2}}' $CLUSTERDUMP_FILE >user_result

	awk '{if(NR%11==1){split($1,a,"{");num=substr(a[2],3,length(a[2]));printf substr(a[1],4,length(a[1]))"\t"num"\t"} else if(NR%11==0){print $1","substr($3,0,5)";"} else if(NR%11!=1){printf $1","substr($3,0,5)";"}}' user_result >user_res_clusters

	awk -F '=' 'NR>3{split(p,a,":");print substr(a[2],2,length(a[2]))"  "substr(a[7],3,length(a[7]))}{p=$1}' $CLUSTERPOINT_FILE > user_result

	awk '{a[$1]=$2";"a[$1]}END{for(i in a) {print i"\t"a[i]}}' user_result > user_res_file

	awk -F '\t' 'NR==FNR{a[$1]=$2;} NR>FNR{print $0"\t"a[$1]}' user_res_file user_res_clusters >user_result

	#删除聚类过程中生成的文件
	rm -f user_res_clusters
	rm -f user_res_file
	rm -f $CLUSTERDUMP_FILE
	rm -f $CLUSTERPOINT_FILE
	rm -rf $TEXTPATH
	rm -rf $VECTORPATH
	rm -rf $CLUSTERPATH
	rm -rf bbs-kmeans-clusters

	#话题发现算法，根据聚类出的十个关键词和关键词-话题字典得到话题
	python topic.py

	#创建表
	TABLE_User="Cluster_User"
	create_table_sql="create table IF NOT EXISTS ${TABLE_User} (id int(11) primary key not null auto_increment, bbs_name varchar(50),user_id varchar(50), file_num varchar(10), topic varchar(200), top_terms varchar(200), file_id longtext) DEFAULT CHARSET=utf8"
	mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "${create_table_sql}"

	#清空数据表
	mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "delete from ${TABLE_User} where bbs_name='${bbs_name}' and user_id='${uid}'"

	#话题发现结果传至数据库
	while read line
	do
		line_arr=($line)
		cluster_id=${line_arr[1]}
		file_num=${line_arr[2]}
		top_terms=${line_arr[3]}
		file_id=${line_arr[4]}
		topic=${line_arr[0]}
		insert_sql="insert into ${TABLE_User} (bbs_name,user_id,file_num,topic,top_terms,file_id) values('${bbs_name}','${uid}','${file_num}','${topic}','${top_terms}','${file_id}')"
		mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "${insert_sql}"
	done < user_data

	rm -rf user
	rm -f $uid"_file"
done

