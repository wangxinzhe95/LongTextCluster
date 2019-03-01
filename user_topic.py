#!/usr/bin/python
import sys
import string
import re


f=open("topic_words")
line=f.readline()
line=f.readline()
d={}
while line:
	liness=line.split()
	topic=liness[0]
	words=re.split(';|,',liness[1])
	for i in range(0,10):
		word=words[i*2]		
		if d.get(word):
			if topic not in d[word]:
				d[word].append(topic)
		else:
			l=[topic]
			d[word]=l
	line = f.readline()
f.close()

f=open("user_result")
output = open('user_data', 'w')
line=f.readline()
while line:
	c={}
	liness=line.split()
	words=re.split(';|,',liness[2])
	for i in range(0,10):
		word=words[i*2]		
		if d.get(word):
			for topic in d[word]:
				if c.get(topic):
					c[topic]+=1
				else:
					c[topic]=1
	t=sorted(c.items(),key=lambda a:a[1],reverse=True)
	if t:
		output.write(t[0][0]+"\t"+line)
	else:
		output.write("NULL"+"\t"+line)
	line = f.readline()
f.close()

