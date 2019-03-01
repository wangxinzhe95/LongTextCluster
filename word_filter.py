__author__ = 'lynn'
#!/usr/bin/python
import sys
import string
import re

# f=open("noun.dict")
f=open("all_noun.dict")
d=set()
line=f.readline()
while line:
        line = line.strip('\n')
        d.add(line)
        line=f.readline()
f.close()
f=open("data")
output=open('final_data','w')
line=f.readline()
while line:
        str=line.split("\t")
        topic=str[0]
        cluster_id=str[1]
        file_num=str[2]
        top_terms=str[3].split(";")
        file_id=str[4]
        res=""
        for item in top_terms:
                word=item.split(",")
                if word[0] in d:
                        res=res+item+";"
        if res=="":
                res=str[3]
        output.write(topic+"\t"+cluster_id+"\t"+file_num+"\t"+res+"\t"+file_id)
        line=f.readline()
f.close()
output.close()

