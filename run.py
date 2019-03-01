#!/usr/bin/python
import os
import sys
import string
import time
from threading import Timer

def task(func, inerval, delay):
	start = time.time()
	if delay != 0:
		sleep(delay)
	func()
	end = time.time()
	if start + inerval > end:
		Timer(start + inerval - end, task, (func, inerval, 0)).start()
	else:
		times = round(end - start / inerval)
		Timer(start + (times + 1) * inerval - end, task, (func, inerval, 0)).start()

def scheduler(func, inerval, delay=0):
	Timer(inerval, task, (func, inerval, delay)).start()

if __name__ == '__main__':
	def say_hello():
		output = os.popen('bash ~/hadoop/lynn/bbs.sh')
		print(output.read())
	scheduler(say_hello, 3600, 0)
