#!/usr/bin/env bash
# LazyMap
# Daniel Compton
# www.commonexploits.com
# contact@commexploits.com
# Twitter = @commonexploits
# 19/12/2012
# Tested on Bactrack 5 only.

# Import info - read first!

# Nmap Lazy Script - For Internal Inf Testing. tested only on BT5 gnome. Scans should launch 4x terminals at once, may only work on BT5!
# 
# For the auto creation of a custom Nessus policy - export and place one policy file within the same directory as the script with any filename or extension - it will find it use this as a template.
# For Nessus template use ensure the following options are set UDP SCAN=ON, SNMP SCAN=ON, SYN SCAN=ON,  PING HOST=OFF, TCP SCAN=OFF - the script will enable safe checks and consider unscanned ports as closed - double check before scanning.


#####################################################################################
# Released as open source by NCC Group Plc - http://www.nccgroup.com/

# Developed by Daniel Compton, daniel dot compton at nccgroup dot com

# https://github.com/nccgroup/vlan-hopping

#Released under AGPL see LICENSE for more information

######################################################################################




VERSION="1.8"

#####################################################################################################################

# User config options

# Turn on/off Nmap scan options

FULLTCP="on" # to disable/enable Full TCP Scan set to "off" / "on"
SCRIPT="on" # to disable/enable safe script Scan set to "off" / "on"
QUICKUDP="on" # to disable/enable quick UDP scan set to "off" / "on" 
COMMONTCP="on" # to disable/enabke commong TCP scan set to "off" / "on"

######################################################################################################################
# Script Starts

clear
echo -e "\e[00;32m#############################################################\e[00m"
echo ""
echo "***   Lazymap - Internal Auto Nmap Script Version $VERSION  ***"
echo ""
echo -e "\e[00;32m#############################################################\e[00m"
echo ""
echo ""
echo -e "\e[1;33mIf any of the scans are too slow, press Ctrl c to auto switch to a T5 scans\e[00m"
echo ""
echo -e "\e[1;33mIt can auto create you a custom Nessus policy based on only the unique open ports for faster scanning - see script header for details\e[00m"
echo ""
echo -e "\e[1;33mAll output including hosts up, down, unique ports and an audit of each scan start stop times can be found in the output directory.\e[00m"
echo ""
echo -e "\e[1;33mPress Enter to continue\e[00m"
echo ""
read ENTERKEY
clear
#Check for multiple Nessus policy files
NESSUSPOLICYNO=$(grep -l --exclude=\*.sh -i "<NessusClientData_v2>" * |wc -l)
if [ $NESSUSPOLICYNO -gt 1 ]
	then
		echo ""
		echo -e "\e[1;31mI found more than 1 .nessus policy file template. Please correct this and run again!\e[00m"
		echo ""
		DOTNESSUS=$(grep -l --exclude=\*.sh -i "<NessusClientData_v2>" *)
		echo -e "\e[00;31m$DOTNESSUS\e[00m"
		echo ""
		exit 1
	else
		echo ""
fi
echo -e "\e[1;33m----------------------------------------\e[00m"
echo "The following Interfaces are available"
echo -e "\e[1;33m----------------------------------------\e[00m"

	ifconfig | grep -o "eth.*" |cut -d " " -f1
echo -e "\e[1;31m--------------------------------------------------\e[00m"
echo "Enter the interface to scan from as the source"
echo -e "\e[1;31m--------------------------------------------------\e[00m"
read INT

ifconfig | grep -i -w $INT >/dev/null

if [ $? = 1 ]
	then
		echo ""
		echo -e "\e[1;31mSorry the interface you entered does not exist! - check and try again.\e[00m"
		echo ""
		exit 1
else
echo ""
fi
LOCAL=$(ifconfig $INT |grep "inet addr:" |cut -d ":" -f 2 |awk '{ print $1 }')
MASK=$(ifconfig |grep -i $LOCAL | grep -i mask: |cut -d ":" -f 4)
clear
echo ""
echo -e "Your source IP address is set as follows \e[1;33m"$LOCAL"\e[00m with the mask of \e[1;33m"$MASK"\e[00m"
echo ""
ifconfig $INT |grep "inet addr:" |grep "192.168.186.*" >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo -e "\e[1;31mIt seems you are running in VMWARE with a NAT network connection.\e[00m" 
		echo ""
		echo -e "\e[1;33mIf you intend to scan from a static IP you should set the NIC to BRIDGED mode, script will continue but CTRL C to quit and change if required.\e[00m"
		echo ""
		sleep 5
	else
echo ""
fi
echo -e "\e[1;31m---------------------------------------------------------------------------------------------------\e[00m"
echo "Would you like to change your source IP address or gateway..? - Enter yes or no and press ENTER"
echo -e "\e[1;31m---------------------------------------------------------------------------------------------------\e[00m"
read IPANSWER
if [ $IPANSWER = yes ]
	then
		echo ""
		echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
		echo "Enter the IP address/subnet for the source interface you want to set. i.e 192.168.1.1/24 and press ENTER"
		echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
		read SETIPINT
		ifconfig $INT $SETIPINT up
		SETLOCAL=`ifconfig $INT |grep "inet addr:" |cut -d ":" -f 2 |awk '{ print $1 }'`
		SETMASK=`ifconfig |grep -i $SETLOCAL | grep -i mask: |cut -d ":" -f 4`
		echo ""
		echo -e "Your source IP address is set as follows \e[1;33m"$SETLOCAL"\e[00m with the mask of \e[1;33m"$SETMASK"\e[00m"
		echo ""
		echo -e "\e[1;31m----------------------------------------------------------------------------------------\e[00m"
		echo "Would you like to change your default gateway..? - Enter yes or no and press ENTER"
		echo -e "\e[1;31m----------------------------------------------------------------------------------------\e[00m"
		read GATEWAYANSWER
			if [ $GATEWAYANSWER = yes ]
		then
		echo ""
		echo -e "\e[1;31m--------------------------------------------------------\e[00m"
		echo "Enter the default gateway you want set and press ENTER"
		echo -e "\e[1;31m--------------------------------------------------------\e[00m"
		read SETGATEWAY
		route add default gw $SETGATEWAY
		echo ""
		clear
		echo ""
		echo "The default gateway has been added below" 
		echo ""
		ROUTEGW=`route |grep -i default`
		echo -e "\e[1;33m$ROUTEGW\e[00m"
		echo ""
	else
echo ""
	fi
fi
echo -e "\e[1;31m--------------------------------------------------\e[00m"
echo "Enter the reference or client name for the scan"
echo -e "\e[1;31m--------------------------------------------------\e[00m"
read REF
echo ""
echo -e "\e[1;31m-------------------------------------------------------------------\e[00m"
echo "Enter the IP address/Range or the exact path to an input file"
echo -e "\e[1;31m-------------------------------------------------------------------\e[00m"
read RANGE

mkdir "$REF" >/dev/null 2>&1
cd "$REF"
echo "$REF" > REF
echo "$INT" > INT
echo ""
echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
echo "Do you want to exclude any IPs from the scan i.e your Windows host? - Enter yes or no and press ENTER"
echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
read EXCLUDEANS

if [ $EXCLUDEANS = yes ]
		then
			echo ""
			echo -e "\e[1;31m------------------------------------------------------------------------------------------\e[00m"
			echo "Enter the IP addresses to exclude i.e 192.168.1.1, 192.168.1.1-10 - normal nmap format"
			echo -e "\e[1;31m------------------------------------------------------------------------------------------\e[00m"
			read EXCLUDEDIPS
			EXCLUDE="--exclude "$EXCLUDEDIPS""
			echo "$EXCLUDE" > excludetmp
			echo "This following IP addresses were asked to be excluded from the scan = "$EXCLUDEDIPS"" > "$REF"_nmap_hosts_excluded.txt
		else
			EXCLUDE=""
			echo "$EXCLUDE" > excludetmp
		fi

		echo $RANGE |grep "[0-9]" >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo ""
		echo -e "\e[1;33mYou enterted a manual IP or range, scan will now start...\e[00m"
		echo ""
		echo -e "\e[1;33m$REF - Finding Live hosts via $INT, please wait...\e[00m"
		nmap -e $INT -sP $EXCLUDE -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan $RANGE >/dev/null
		cat "$REF"_nmap_PingScan.gnmap |grep "Up" |awk '{print $2}' > "$REF"_hosts_Up.txt
		cat "$REF"_nmap_PingScan.gnmap | grep  "Down" |awk '{print $2}' > "$REF"_hosts_Down.txt
	else
		echo ""
		echo -e "\e[1;33mYou entered a file as the input, I will just check I can read it ok...\e[00m"
		cat $RANGE >/dev/null 2>&1
			if [ $? = 1 ]
			then
				echo ""
				echo -e "\e[1;31mSorry I can't read that file, check the path and try again!\e[00m"
				echo ""
			exit 1
		else
			echo ""
			echo -e "\e[1;33mI can read the input file ok, Scan will now start...\e[00m"
			echo ""
			echo -e "\e[1;33m$REF - Finding Live hosts via $INT, please wait...\e[00m"
			nmap -e $INT -sP $EXCLUDE -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan -iL $RANGE >/dev/null
			cat "$REF"_nmap_PingScan.gnmap |grep "Up" |awk '{print $2}' > "$REF"_hosts_Up.txt
			cat "$REF"_nmap_PingScan.gnmap | grep  "Down" |awk '{print $2}' > "$REF"_hosts_Down.txt
		fi
fi
clear
HOSTSCOUNT=$(cat "$REF"_hosts_Up.txt |wc -l)
HOSTSUPCHK=$(cat "$REF"_hosts_Up.txt)
if [ -z "$HOSTSUPCHK" ]
	then
		echo ""
		echo -e "\e[1;33mIt seems there are no live hosts present in the range specified..I will run a Arp-scan to double check...\e[00m"
		echo ""
		sleep 4
		arp-scan --interface $INT --file "$REF"_hosts_Down.txt > "$REF"_arp_scan.txt 2>&1
		arp-scan --interface $INT --file "$REF"_hosts_Down.txt |grep -i "0 responded" >/dev/null 2>&1
			if [ $? = 0 ]
				then
					echo -e "\e[1;31mNo live hosts were found using arp-scan - check IP range/source address and try again. It may be there are no live hosts.\e[00m"
					echo ""
					rm "INT" 2>&1 >/dev/null
					rm "REF" 2>&1 >/dev/null
					rm "excludetmp" 2>&1 >/dev/null
					touch "$REF"_no_live_hosts.txt
					exit 1
			else
					arp-scan --interface $INT --file "$REF"_hosts_Down.txt > "$REF"_arp_scan.txt 2>&1
					ARPUP=$(cat "$REF"_arp_scan.txt)
					echo ""
					echo -e "\e[1;33mNmap didn't find any live hosts, but apr-scan found the following hosts within the range...script will exit. Try adding these to the host list to scan.\e[00m"
					echo ""
					rm "INT" 2>&1 >/dev/null
					rm "REF" 2>&1 >/dev/null
					rm "excludetmp" 2>&1 >/dev/null
					echo -e "\e[00;32m$ARPUP\e[00m"
					echo ""
					exit 1
	fi
fi
echo -e "\e[1;33m-----------------------------------------------------------------\e[00m"
echo "The following $HOSTSCOUNT hosts were found up for $REF"
echo -e "\e[1;33m-----------------------------------------------------------------\e[00m"
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[00;32m$HOSTSUP\e[00m"
echo ""
echo -e "\e[1;33mPress Enter to scan the live hosts, or CTRL C to cancel\e[00m"
read ENTER

if [ $COMMONTCP = "on" ]
then
# Scanning Common TCP Ports - CTRL - C if slow to switch to T5 fast
gnome-terminal --title="$REF - Common TCP Port Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);trap control_c SIGINT; control_c() { clear ; echo "" ; echo "" ; echo -e "\e[1;33mYou interupted the Common TCP Scan for "$REF" - it was probably too slow..? I will run it again with T5..please wait..\e[00m" ; echo "" ; sleep 3 ; echo -e "\e[1;33mCleaning up T4 Common TCP scan files..\e[00m" ; sleep 3 ; rm "$REF"_nmap_CommonPorts* >/dev/null ; clear ; echo "" ; echo -e "\e[1;33mNow Starting Common TCP scan with T5 option..."$REF"\e[00m" ; echo "" ; nmap -e $INT -sS $EXCLUDE -PN -T5 -sV --version-intensity 1 -vvv -oA "$REF"_nmap_CommonPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[00;32m$REF - Common TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ; exit $? ; } ; echo "" ; echo -e "\e[1;33mStarting Common TCP scan for $REF\e[00m"; echo "" ;  echo -e "\e[1;33mIf the scan runs too slow, just press CTRL C to switch to a T5 speed scan\e[00m" ; echo "" ; sleep 3 ; nmap -e $INT -sS $EXCLUDE -PN -T4 -sV --version-intensity 1 -vvv -oA "$REF"_nmap_CommonPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[00;32m$REF - Common TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
echo "Skipping Common TCP scan as turned off in options"
fi

if [ $SCRIPT = "on" ]
then
#Script Scan (not CTRL C option)
gnome-terminal --title="$REF - Script Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);nmap -e $INT -PN $EXCLUDE -A -vvv -oA "$REF"_nmap_ScriptScan -iL "$REF"_hosts_Up.txt -n; echo ""; echo -e "\e[00;32m$REF - Script Scan Complete, Press ENTER to Exit";echo "";read ENTERKEY;'
else
echo "Skipping Script Scan as turned off in options"
fi

if [ $QUICKUDP = "on" ]
then
#Scanning Quick UDP (1,000) Ports - CTRL - C if slow to switch to T5 fast
gnome-terminal --title="$REF - Quick UDP Port Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);trap control_c SIGINT; control_c() { clear ; echo "" ; echo "" ; echo -e "\e[1;33mYou interupted the Quick UDP Scan for "$REF" - it was probably too slow..? I will run it again with T5..please wait..\e[00m" ; echo "" ; sleep 3 ; echo -e "\e[1;33mCleaning up T4 Quick UDP scan files..\e[00m" ; sleep 3 ; rm "$REF"_nmap_QuickUDP* >/dev/null ; clear ; echo "" ; echo -e "\e[1;33mNow Starting Quick UDP scan with T5 option..."$REF"\e[00m" ; echo "" ; nmap -e $INT -sU $EXCLUDE -Pn -T5 -vvv -oA "$REF"_nmap_QuickUDP -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[00;32m$REF - Quick UDP Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ; exit $? ; } ; echo "" ; echo -e "\e[1;33mStarting Quick UDP scan for $REF\e[00m"; echo "" ;  echo -e "\e[1;33mIf the scan runs too slow, just press CTRL C to switch to a T5 speed scan\e[00m" ; echo "" ; sleep 3 ; nmap -e $INT -sU $EXCLUDE -Pn -T4 -vvv -oA "$REF"_nmap_QuickUDP -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[00;32m$REF - Quick UDP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
echo "Skipping Quick UDP Scan as turned off in options"
fi

if [ $FULLTCP = "on" ]
then
# Scanning Full TCP Ports - CTRL - C if slow to switch to T5 fast
gnome-terminal --title="$REF - Full TCP Port Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);trap control_c SIGINT; control_c() { clear ; echo "" ; echo "" ; echo -e "\e[1;33mYou interupted the Full TCP Scan for "$REF" - it was probably too slow..? I will run it again with T5..please wait..\e[00m" ; echo "" ; sleep 3 ; echo -e "\e[1;33mCleaning up T4 Full TCP scan files..\e[00m" ; sleep 3 ; rm "$REF"_nmap_FullPorts* >/dev/null ; clear ; echo "" ; echo -e "\e[1;33mNow Starting Full TCP scan with T5 option..."$REF"\e[00m" ; echo "" ; nmap -e $INT -sS $EXCLUDE -PN -T5 -p- -sV --version-intensity 1 -vvv -oA "$REF"_nmap_FullPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[00;32m$REF - Full TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ; exit $? ; } ; echo "" ; echo -e "\e[1;33mStarting Full TCP scan for $REF\e[00m"; echo "" ;  echo -e "\e[1;33mIf the scan runs too slow, just press CTRL C to switch to a T5 speed scan\e[00m" ; echo "" ; sleep 3 ; nmap -e $INT -sS $EXCLUDE -PN -T4 -p- -sV --version-intensity 1 -vvv -oA "$REF"_nmap_FullPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[00;32m$REF - Full TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
echo "Skipping Full TCP as turned off in options"
fi

#clear temp files
sleep 5
rm "INT" 2>&1 >/dev/null
rm "REF" 2>&1 >/dev/null
rm "excludetmp" 2>&1 >/dev/null

clear
echo ""
echo -e "\e[1;33mOnce all scans are complete, press ENTER to list all unique ports found - $REF\e[00m"
read ENTERKEY
clear
echo ""
echo -e "\e[1;33m----------------------------------------------------------------------------------\e[00m"
echo "The following scan start/finish times were recorded for $REF"
echo -e "\e[1;33m----------------------------------------------------------------------------------\e[00m"
echo ""
PINGTIMESTART=`cat "$REF"_nmap_PingScan.nmap |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
PINGTIMESTOP=`cat "$REF"_nmap_PingScan.nmap |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
COMMONTCPTIMESTART=`cat "$REF"_nmap_CommonPorts.nmap |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
COMMONTCPTIMESTOP=`cat "$REF"_nmap_CommonPorts.nmap |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
FULLTCPTIMESTART=`cat "$REF"_nmap_FullPorts.nmap |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
FULLTCPTIMESTOP=`cat "$REF"_nmap_FullPorts.nmap |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
QUICKUDPTIMESTART=`cat "$REF"_nmap_QuickUDP.nmap |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
QUICKUDPTIMESTOP=`cat "$REF"_nmap_QuickUDP.nmap |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
SCRIPTTIMESTART=`cat "$REF"_nmap_ScriptScan.nmap |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
SCRIPTTIMESTOP=`cat "$REF"_nmap_ScriptScan.nmap |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`

if [ -z "$PINGTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mPing sweep started $PINGTIMESTART\e[00m - \e[1;31mscan did not complete or was interupted!\e[00m"
		echo "Ping sweep started $PINGTIMESTART - scan did not complete or was interupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mPing sweep started $PINGTIMESTART\e[00m - \e[00;32mfinished successfully $PINGTIMESTOP\e[00m"
		echo "Ping sweep started $PINGTIMESTART - finsihed successfully $PINGTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$COMMONTCPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mCommon TCP scan started $COMMONTCPTIMESTART\e[00m - \e[1;31mscan did not complete or was interupted!\e[00m"
		echo "Common TCP scan started $COMMONTCPTIMESTART - scan did not complete or was interupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mCommon TCP scan started $COMMONTCPTIMESTART\e[00m - \e[00;32mfinished successfully $COMMONTCPTIMESTOP\e[00m"
		echo "Common TCP scan started $COMMONTCPTIMESTART - finished successfully $COMMONTCPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$FULLTCPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mFull TCP scan started $FULLTCPTIMESTART\e[00m - \e[1;31mscan did not complete or was interupted!\e[00m"
		echo "Full TCP scan started $FULLTCPTIMESTART - scan did not complete or was interupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mFull TCP scan started $FULLTCPTIMESTART\e[00m - \e[00;32mfinished successfully $FULLTCPTIMESTOP\e[00m"
		echo "Full TCP scan started $FULLTCPTIMESTART - finished successfully $FULLTCPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$QUICKUDPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mQuick UDP scan started $QUICKUDPTIMESTART\e[00m - \e[1;31mscan did not complete or was interupted!\e[00m"
		echo "Quick UDP scan started $QUICKUDPTIMESTART - scan did not complete or was interupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mQuick UDP scan started $QUICKUDPTIMESTART\e[00m - \e[00;32mfinished successfully $QUICKUDPTIMESTOP\e[00m"
		echo "Quick UDP scan started $QUICKUDPTIMESTART - finished successfully $QUICKUDPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$SCRIPTTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mScript scan started $SCRIPTTIMESTART\e[00m - \e[1;31mscan did not complete or was interupted!\e[00m"
		echo "Script scan started $SCRIPTTIMESTART - scan did not complete or was interupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[1;33mScript scan started $SCRIPTTIMESTART\e[00m - \e[00;32mfinished successfully $SCRIPTTIMESTOP\e[00m"
		echo "Script scan started $SCRIPTTIMESTART - finished successfully $SCRIPTTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
echo ""
echo -e "\e[1;33m------------------------------------------------------------------\e[00m"
echo "Unique TCP and UDP Port Summary - $REF"
echo -e "\e[1;33m------------------------------------------------------------------\e[00m"
UNIQUE=$(cat *.xml |grep -i 'open"' |grep -i "portid=" |cut -d '"' -f 4,5,6| grep -o '[0-9]*' |sort --unique |paste -s -d,)
echo $UNIQUE >"$REF"_nmap_unique_ports.txt
echo -e "\e[00;32m$UNIQUE\e[00m"
echo ""
echo -e "\e[1;33m-----------------------------------------------------------------------\e[00m"
echo "The following $HOSTSCOUNT hosts were up and scanned for $REF"
echo -e "\e[1;33m-----------------------------------------------------------------------\e[00m"
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[00;32m$HOSTSUP\e[00m"
echo ""
echo ""
#Check for excluded IPs
ls "$REF"_nmap_hosts_excluded.txt >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo -e "\e[1;33m--------------------------------------------------------------------------------\e[00m"
		echo "The following hosts were requested to be excluded from scans for $REF"
		echo -e "\e[1;33m---------------------------------------------------------------------------------\e[00m"
		echo -e "\e[00;32m$EXCLUDEDIPS\e[00m"
		echo ""
	else
	echo ""
fi
echo -e "\e[1;33mOutput files have all been saved to the\e[00m \e[00;32m"$REF"\e[00m \e[1;33mdirectory\e[00m"
echo ""

# check for Nessus template
POLICYNAME=$(grep -l --exclude=\*.sh -i "<NessusClientData_v2>" ../*) #default Nessus template - save just one template with any extenstion - must be within script directory
ls "$POLICYNAME" >/dev/null 2>&1
if [ $? = 0 ]
	then
	FINDPOLICY=$(cat $POLICYNAME |grep policyName) #find Nessus policy name
	NEWPOLICY="<Policy><policyName>$REF</policyName>" #set Nessus policy name
	NEWPORTS="<value>$UNIQUE</value>" #set Nessus policy unique tcp/udp ports
	FINDCOMMENTS=$(cat $POLICYNAME |grep policyComments) #find nessus comment value
	NEWCOMMENTS="<policyComments>"$REF" Custom Scan of the following unique ports "$UNIQUE"</policyComments>" #Add Nessus policy comments
	ENABLESAFE="<value>yes</value>" #enable Nessus safe checks only - wont run DoS plugins
	ENABLECLOSED="<value>yes</value>" #set Nessus consider unscanned ports closed - scans only unqiue ports
	OFFSTOP="<value>no</value>" #set Nessus to disable stop scan on disconnect
	# Create custom Nessus Policy
	cat $POLICYNAME | sed "s#$FINDPOLICY#$NEWPOLICY#" |sed "s#$FINDCOMMENTS#$NEWCOMMENTS#"  >"$REF"_nessus.policy
	FINDPORTS=$(cat $POLICYNAME |awk '/port_range/{getline; print NR}') #find ports
	FINDSAFE=$(cat $POLICYNAME | awk '/safe_checks/{getline; print NR}') #find Nessus safe check value
	FINDCLOSED=$(cat $POLICYNAME |awk '/unscanned_closed/{getline; print NR}') # find consider unclosed ports closed
	FINDSTOP=$(cat $POLICYNAME |awk '/stop_scan_on_disconnect/{getline; print NR}') #find stop scan on disconnect
	sed -i "$FINDPORTS"i"$NEWPORTS" "$REF"_nessus.policy
	sed -i "$FINDSAFE"i"$ENABLESAFE" "$REF"_nessus.policy
	sed -i "$FINDCLOSED"i"$ENABLECLOSED" "$REF"_nessus.policy
	sed -i "$FINDSTOP"i"$OFFSTOP" "$REF"_nessus.policy
		echo ""
		echo -e "\e[00;32mI have created a custom policy Nessus policy file named ""$REF"_nessus.policy" - Import this into Nessus for a faster custom scan just on the above live hosts\e[00m"
		echo ""
		echo -e "\e[1;33mRemember to export and update the Nessus template file regularly after updating Nessus to ensure the latest modules are included - ensure the correct options are enabled\e[00m"
		echo ""
	else
	echo ""
fi
exit 0