#!/bin/bash

counter=1;
seconds=$1;
previousReceive=`awk -v OFS=, '/enp0s3:/ { print $2}' /proc/net/dev`;
previousUpload=`awk -v OFS=, '/enp0s3:/ { print $10}' /proc/net/dev`;
KB=$((1024*1024));
MB=$((1024*1024*1024));
box='\xe2\x96\xa0';
horLine='\xe2\x95\x90'
verLine='\xe2\x95\x91'
blueBlock=$(printf '\033[36m\xe2\x96\xa0')
yellowBlock=$(printf '\033[93m\xe2\x96\xa0')
greenBlock=$(printf '\033[92m\xe2\x96\xa0')
declare -a downloadValues
declare -a uploadValues

avgUpload=0;
avgReceive=0;

function calculatePrinting() {
	if [ $1 -lt 1024 ]
	then
		if [ $2 == 2 ]
		then
			printf "	\033[92m\U2191 \033[93m%1i B/s " $1
		else
			printf "	\033[92m\U2193 \033[93m%1i B/s " $1
		fi
	elif ([ $1 -lt $KB ] && [ $1 -gt 1024 ])
	then
		if [ $2 == 2 ] 
		then
			printf "	\033[92m\U2191 \033[93m%1i KB/s" $(($1/1024))
		else
			printf "	\033[92m\U2193 \033[93m%1i KB/s" $(($1/1024))
		fi
	elif ([ $1 -lt $MB ] && [ $1 -gt $KB ])
	then
		if [ $2 == 2 ]
		then
			printf "	\033[92m\U2191 \033[93m%1i MB/s" $(($1/1024/1024))
		else
			printf "	\033[92m\U2193 \033[93m%1i MB/s" $(($1/1024/1024))
		fi
	fi
}

function showTransfer() {

	local Receive=`awk -v OFS=, '/enp0s3:/ { print $2}' /proc/net/dev`
	local Upload=`awk -v OFS=, '/enp0s3:/ { print $10}' /proc/net/dev`
	let local counterReceive="$Receive-$previousReceive"
	let local counterUpload="$Upload-$previousUpload"
	
	avgReceive=$((($avgReceive+$counterReceive)/$counter))
	avgUpload=$((($avgUpload+$counterUpload)/$counter))
	previousReceive=$Receive
	previousUpload=$Upload

	printf "\n		\033[92mNow\033[91m:	"	
	calculatePrinting $counterReceive 1
	calculatePrinting $counterUpload 2
	printf "\n		\033[92mAverage\033[91m:"		
	calculatePrinting $avgReceive	1
	calculatePrinting $avgUpload 2
	printf "\n"
	
	downloadValues+=($counterReceive)
	uploadValues+=($counterUpload)
	counterUpload=$Upload
	counterReceive=$Receive
	avgReceive=$(($avgReceive*$counter))
	avgUpload=$(($avgUpload*$counter))
}

function showBattery() {
	local batteryPercentage=`awk -F "=" -v OFS=, '/POWER_SUPPLY_CAPACITY=/ { print $2}' /sys/class/power_supply/BAT0/uevent`
	printf "	\033[36mBattery Percentage \033[91m: \033[93m%1i\n" $batteryPercentage
}

function showSystemLoad() {
	printf "	\033[36mSystem Load  \033[91m: \n"
	local wholeValues=`awk  '{print $4}' /proc/loadavg`
	local runnableProcesses="$(cut -d'/' -f1 <<<$wholeValues)"
	local totalProcesses="$(cut -d'/' -f2 <<<$wholeValues)"
	printf "		\033[92mRunnable processes \033[91m: \033[93m%1s \n		\033[92mTotal processes \033[91m: \033[93m%2s\n" $runnableProcesses $totalProcesses 

}



function showLine() {
	
	padlimit=25
	

	if [ $1 -lt 1024 ]
	then
		blockAmount=$(echo "$1/50+1" | bc)
		calculatedOut=`calculatePrinting $1 $2`
		strLen=${#calculatedOut}
		spaceAmount=$(($padlimit-$strLen))
		spaceBar=$(printf "%*s" $spaceAmount ' ')
		bar=$(printf "%*s" $blockAmount '')
   		printf "$calculatedOut $spaceBar ${bar// /$blueBlock}" 
	elif ([ $1 -lt $KB ] && [ $1 -gt 1024 ])
	then
		blockAmount=$(echo "$1/50/1024+1" | bc)
		calculatedOut=`calculatePrinting $1 $2`
		strLen=${#calculatedOut}
		spaceAmount=$(($padlimit-$strLen))
		spaceBar=$(printf "%*s" $spaceAmount ' ')
		bar=$(printf "%*s" $blockAmount '')
   		printf "$calculatedOut $spaceBar ${bar// /$yellowBlock}" 
	elif ([ $1 -lt $MB ] && [ $1 -gt $KB ])
	then
		blockAmount=$(echo "$1/50/1024/1024+1" | bc)
		calculatedOut=`calculatePrinting $1 $2`
		strLen=${#calculatedOut}
		spaceAmount=$(($padlimit-$strLen))
		spaceBar=$(printf "%*s" $spaceAmount ' ')
		bar=$(printf "%*s" $blockAmount '')
   		printf "$calculatedOut $spaceBar ${bar// /$greenBlock}" 
	fi
}

function showGraphs () {
	printf "\n	\033[36mHistory of download \033[91m:\n"
	tabSizeD=${#downloadValues[@]}
	tabSizeU=${#uploadValues[@]}
	if [ $counter -le 10 ]; then
				for ((i=0; i<tabSizeD; i++))
					do
						showLine ${downloadValues[$i]} 1
						printf "\n"
				done
			else			
				for i in {0..10}
					do
						showLine ${downloadValues[$counter-$i-1]} 1
						printf "\n"
				done
			fi
		printf "\n	\033[36mHistory of upload \033[91m:\n"
		if [ $counter -le 10 ]; then
				for ((i=0; i<tabSizeU; i++))
					do
						showLine ${uploadValues[$i]} 2
						printf "\n"
				done
			else			
				for i in {0..10}
					do
						showLine ${uploadValues[$counter-$i-1]} 2
						printf "\n"
				done
			fi
}

function showLegend () {
	horSign=$(printf "%*s" $1 '')
	spacesAmount=$(($1-2))
	printf '\033[0m\n\n	\xe2\x95\x94'
	printf "${horSign// /'\xe2\x95\x90'}"
	printf '\xe2\x95\x97\n'
	printf "	\xe2\x95\x91 \033[36m		[LEGENDA]                \033[0m\xe2\x95\x91\n"
	printf "	\033[0m\xe2\x95\x91 %1s \033[91m------> \033[92mBit			 	 \033[0m\xe2\x95\x91\n" $blueBlock
	printf "	\033[0m\xe2\x95\x91 %1s \033[91m------> \033[92mKilo Bit			 \033[0m\xe2\x95\x91\n" $yellowBlock
	printf "	\033[0m\xe2\x95\x91 %1s \033[91m------> \033[92mMega Bit			 \033[0m\xe2\x95\x91\n" $greenBlock
	printf "	\033[0m\xe2\x95\x91 Box size \033[91m:  	\033[0m[\033[93m0 \033[0m- \033[93m50\033[0m]		 \033[0m\xe2\x95\x91\n"
	printf "	\033[0m\xe2\x95\x9a${horSign// /'\xe2\x95\x90'}\xe2\x95\x9d\n\n"
	
	
}

clear;
while [ $counter -le $seconds ]
	do
		printf "	\033[36mNetwork speed \033[91m: "
		showTransfer
		printf "        \033[36mUptime \033[91m:\033[0m \n"
		awk '{print "	\033[92m	Days \033[91m: \033[93m"int($1/86400)"\033[0m\n		\033[92mHours \033[91m: \033[93m"int($1/3600)"\033[0m\n		\033[92mMinutes \033[91m: \033[93m" int(($1%3600)/60) "\033[0m\n		\033[92mSeconds\033[91m: \033[93m"int($1%60)"\033[0m"}' /proc/uptime
		showBattery
		showSystemLoad
		showGraphs
		showLegend 40
		sleep 1;
		((counter++))
		clear;
done
