#!/bin/bash

cd $PWD
javac $1;
if [ $? -eq 0 ]; then
	name=$( awk -F '.' '{print $1}' <<< $1);
	java $name;
	echo $name run success!!;
else
	echo "Error"
fi
