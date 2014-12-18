#!/bin/bash

for file in ./*.cpp
do
	./120 $file
	read -p "Ready to read next? " answer
done
