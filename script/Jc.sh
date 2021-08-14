#!/bin/bash

#cd $PWD
javac $1.java;
if [ $? -eq 0 ]; then
	#name=$( awk -F '.' '{print $1}' <<< $1);
	java $1;
else
	echo "Error"
fi
