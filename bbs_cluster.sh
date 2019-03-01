#!/bin/bash

#定义路径
TXTPATH=/home/user1/cluster/byr_classify/$1
TEXTPATH=/home/user1/cluster/bbs-seq
VECTORPATH=/home/user1/cluster/bbs-sparse
CLUSTERPATH=/home/user1/cluster/bbs-kmeans
CLUSTERDUMP_FILE=/home/user1/cluster/bbs-kmeans-cluster-dump
CLUSTERPOINT_FILE=/home/user1/cluster/bbs-clusteredPoints

#设置mahout本地运行，不允许在hadoop上
export MAHOUT_LOCAL=T

#聚类过程
# 文本目录->SequenceFile 本地运行
# 生成TEXTPATH
mahout seqdirectory -i file://$TXTPATH/ -o file://$TEXTPATH/ -c UTF-8 -xm sequential -ow
mahout seqdirectory -i ./$TXTPATH -o ./$TEXTPATH/ -c UTF-8 -xm sequential -ow

# text->Vector
# 生成VECTORPATH
mahout seq2sparse -i $TEXTPATH -o $VECTORPATH -ow -wt tfidf -lnorm -nv -a  org.wltea.analyzer.lucene.IKAnalyzer --maxDFPercent 70 --namedVector

# Run K-Means
mahout kmeans -i $VECTORPATH/tfidf-vectors -k 1 -c /home/user1/cluster/bbs-kmeans-clusters -o $CLUSTERPATH  -dm org.apache.mahout.common.distance.CosineDistanceMeasure -x 200 --convergenceDelta 0.01 -ow --clustering
# Run Fuzzy-K-Means
#mahout fkmeans -i $VECTORPATH/tfidf-vectors -k 20 -c bbs-kmeans-clusters -o $CLUSTERPATH -dm org.apache.mahout.common.distance.CosineDistanceMeasure -m 1.05 -x 200 -ow --clustering --convergenceDelta 0.01

#获取聚类结果
mahout clusterdump -i $CLUSTERPATH/clusters-*-final -d $VECTORPATH/dictionary.file-0 -dt sequencefile -o $CLUSTERDUMP_FILE/ -n 10

mahout seqdumper -i $CLUSTERPATH/clusteredPoints/ -o $CLUSTERPOINT_FILE

#分析聚类结果，生成所需数据文件
awk -F '=' '{if(NR%12==1){print $1"="$2} if(NR%12!=1&&NR%12!=2){print $1$2}}' $CLUSTERDUMP_FILE >/home/user1/cluster/result

awk '{if(NR%11==1){split($1,a,"{");num=substr(a[2],3,length(a[2]));printf substr(a[1],4,length(a[1]))"\t"num"\t"} else if(NR%11==0){print $1","substr($3,0,5)";"} else if(NR%11!=1){printf $1","substr($3,0,5)";"}}' /home/user1/cluster/result >/home/user1/cluster/res_clusters

awk -F '=' 'NR>3{split(p,a,":");print substr(a[2],2,length(a[2]))"  "substr(a[7],3,length(a[7]))}{p=$1}' $CLUSTERPOINT_FILE > /home/user1/cluster/result

awk '{a[$1]=$2";"a[$1]}END{for(i in a) {print i"\t"a[i]}}' /home/user1/cluster/result > /home/user1/cluster/res_file

awk -F '\t' 'NR==FNR{a[$1]=$2;} NR>FNR{print $0"\t"a[$1]}' /home/user1/cluster/res_file res_clusters >/home/user1/cluster/result

#删除聚类过程中生成的文件
rm -f /home/user1/cluster/res_clusters
rm -f /home/user1/cluster/res_file
rm -f $CLUSTERDUMP_FILE
rm -f $CLUSTERPOINT_FILE
rm -rf $TEXTPATH
rm -rf $VECTORPATH
rm -rf $CLUSTERPATH
rm -rf /home/user1/cluster/bbs-kmeans-clusters



