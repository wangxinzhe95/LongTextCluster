#!/bin/bash
source /home/user1/cluster/mysql.sh

bbs_name=$1

#表名
TABLE_Cluster="Cluster_"${bbs_name}
TABLE_ClusterOld="Cluster_"${bbs_name}"_old"

#获取关键词-话题字典
#select_sql="SELECT word FROM White_noun WHERE word NOT IN(SELECT word FROM Black_noun)
#UNION
#SELECT word FROM Primary_noun WHERE word NOT IN(SELECT word FROM Black_noun)"

cd /home/user1/cluster
#mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster_Dict} -e "${select_sql}" >all_noun.dict
python word_filter.py
cd

#将聚类结果传至mysql数据库
create_table_sql="create table IF NOT EXISTS ${TABLE_Cluster} (id int(11) primary key not null auto_increment, cluster_id varchar(10), topic varchar(100), file_num varchar(10), top_terms varchar(200), file_id varchar(20000)) DEFAULT CHARSET=utf8"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "${create_table_sql}" 

create_table_sql="create table IF NOT EXISTS ${TABLE_ClusterOld} (id int(11) primary key not null auto_increment, cluster_id varchar(10),topic varchar(100), file_num varchar(10), top_terms varchar(200), file_id varchar(20000)) DEFAULT CHARSET=utf8"
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "${create_table_sql}"

#清空数据表
mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "delete from ${TABLE_Cluster}"


while read line
do
	line_arr=($line)
	cluster_id=${line_arr[1]}
	file_num=${line_arr[2]}
	top_terms=${line_arr[3]}
	file_id=${line_arr[4]}
	topic=${line_arr[0]}
	insert_sql="insert into ${TABLE_Cluster} (cluster_id,file_num,topic,top_terms,file_id) values('${cluster_id}','${file_num}','${topic}','${top_terms}','${file_id}')"
	insert_sql2="insert into ${TABLE_ClusterOld} (cluster_id,file_num,topic,top_terms,file_id) values('${cluster_id}','${file_num}','${topic}','${top_terms}','${file_id}')"
	mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "${insert_sql}"
	mysql -h${HOSTNAME}  -P${PORT}  -u${USERNAME} -p${PASSWORD} ${DB_Cluster} -e "${insert_sql2}"
done < /home/user1/cluster/final_data

