#!/usr/bin/env bash
# LazyMap
# Daniel Compton
# www.commonexploits.com
# contact@commexploits.com
# Twitter = @commonexploits
# Updated 01/09/2013
# Tested on Bactrack 5 & Kali Nessus version 4 & 5

# Important info - read first!

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


VERSION="2.0"

#####################################################################################################################

# User config options

# Turn on/off Nmap scan options - Default setting is Full TCP and Quick UDP

FULLTCP="on" # to disable/enable Full TCP Scan set to "off" / "on"
SCRIPT="off" # to disable/enable safe script Scan set to "off" / "on"
QUICKUDP="on" # to disable/enable quick UDP scan set to "off" / "on"
COMMONTCP="off" # to disable/enable common TCP scan set to "off" / "on"

######################################################################################################################
# Script Starts

sp="▁ ▃ ▄ ▅ ▆ ▇ █ ▇ ▆ ▅ ▄ ▃"

progressbar () {
	 printf "\e[00;34m\r%3d%% complete (per subnet)  " $PERCENT
}
spin() {
   printf "\b${sp:sc++:15} "
   ((sc==${#sp})) && sc=0
}
endspin() {
   printf "\r%s\n" "$@"
}

sc=0


clear
echo -e "\e[00;32m#############################################################\e[00m"
echo ""
echo "***   Lazymap - Internal Auto Nmap Script Version $VERSION  ***"
echo ""
echo -e "\e[00;32m#############################################################\e[00m"
echo ""
echo ""
echo -e "\e[01;32m[-]\e[00m If any of the scans are too slow, press Ctrl c to auto switch to a T5 scans"
echo ""
echo -e "\e[01;32m[-]\e[00m It can auto create you a custom Nessus policy based on only the unique open ports for faster scanning - see script header for details"
echo ""
echo -e "\e[01;32m[-]\e[00m All output including hosts up, down, unique ports and an audit of each scan start stop times can be found in the output directory."
echo ""
echo -e "\e[01;32m[-]\e[00m Press Enter to continue"
echo ""
read ENTERKEY
clear
#Check for multiple Nessus policy files
NESSUSPOLICYNO=$(grep -l -i "<NessusClientData_v2>" --exclude=\*.sh * 2>/dev/null |wc -l)
if [ $NESSUSPOLICYNO -gt 1 ]
	then
		echo ""
		echo -e "\e[01;31m[!]\e[00m I found more than 1 .nessus policy file template within this directory. Please correct this and run again!\e[00m"
		echo ""
		DOTNESSUS=$(grep -l -i "<NessusClientData_v2>" --exclude=\*.sh* 2>/dev/null)
		echo -e "\e[00;31m$DOTNESSUS\e[00m"
		echo ""
		exit 1
fi

# Check if root
if [[ $EUID -ne 0 ]]; then
        echo ""
        echo -e "\e[01;31m[!]\e[00m This program must be run as root. Run again with 'sudo'"
        echo ""
        exit 1
fi

echo ""
echo -e "\e[01;32m[-]\e[00m The following Interfaces are available"
echo ""
	ifconfig | grep -o "eth.*" |cut -d " " -f1
echo ""
echo -e "\e[1;31m--------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the interface to scan from as the source"
echo -e "\e[1;31m--------------------------------------------------\e[00m"
read INT

ifconfig | grep -i -w $INT >/dev/null

if [ $? = 1 ]
	then
		echo ""
		echo -e "\e[1;31m Sorry the interface you entered does not exist! - check and try again."
		echo ""
		exit 1
else
echo ""
fi
LOCAL=$(ifconfig $INT |grep "inet addr:" |cut -d ":" -f 2 |awk '{ print $1 }')
MASK=$(ifconfig |grep -i $LOCAL | grep -i mask: |cut -d ":" -f 4)
clear
echo ""
echo ""
echo -e "\e[01;32m[-]\e[00m Your source IP address is set as follows \e[1;32m"$LOCAL"\e[00m with the mask of \e[1;32m"$MASK"\e[00m"
echo ""
ifconfig $INT |grep "inet addr:" |grep "192.168.186.*" >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo -e "\e[1;31m It seems you are running in VMWARE with a NAT network connection." 
		echo ""
		echo -e "\e[1;31m If you intend to scan from a static IP you should set the NIC to BRIDGED mode, script will continue but CTRL C to quit and change if required."
		echo ""
		sleep 5
	else
echo ""
fi
echo -e "\e[1;31m------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Would you like to change your source IP address or gateway..? - Enter yes or no and press ENTER"
echo -e "\e[1;31m------------------------------------------------------------------------------------------------------\e[00m"
read IPANSWER
if [ $IPANSWER = yes ]
	then
		echo ""
		echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
		echo -e "\e[01;31m[?]\e[00m Enter the IP address/subnet for the source interface you want to set. i.e 192.168.1.1/24 and press ENTER"
		echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
		read SETIPINT
		ifconfig $INT $SETIPINT up
		SETLOCAL=`ifconfig $INT |grep "inet addr:" |cut -d ":" -f 2 |awk '{ print $1 }'`
		SETMASK=`ifconfig |grep -i $SETLOCAL | grep -i mask: |cut -d ":" -f 4`
		echo ""
		echo -e "Your source IP address is set as follows \e[1;33m"$SETLOCAL"\e[00m with the mask of \e[1;33m"$SETMASK"\e[00m"
		echo ""
		echo -e "\e[1;31m-------------------------------------------------------------------------------------------\e[00m"
		echo -e "\e[01;31m[?]\e[00m Would you like to change your default gateway..? - Enter yes or no and press ENTER"
		echo -e "\e[1;31m-------------------------------------------------------------------------------------------\e[00m"
		read GATEWAYANSWER
			if [ $GATEWAYANSWER = yes ]
		then
		echo ""
		echo -e "\e[1;31m----------------------------------------------------------\e[00m"
		echo -e "\e[01;31m[?]\e[00m Enter the default gateway you want set and press ENTER"
		echo -e "\e[1;31m----------------------------------------------------------\e[00m"
		read SETGATEWAY
		route add default gw $SETGATEWAY
		echo ""
		clear
		echo ""
		echo -e "\e[01;32m[+]\e[00m The default gateway has been added below" 
		echo ""
		ROUTEGW=`route |grep -i default`
		echo -e "\e[1;33m$ROUTEGW\e[00m"
		echo ""
	else
echo ""
	fi
fi
echo ""
echo -e "\e[1;31m------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the reference or client name for the scan"
echo -e "\e[1;31m------------------------------------------------------\e[00m"
read REF
echo ""
echo -e "\e[1;31m-----------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Enter the IP address/Range or the exact path to an input file"
echo -e "\e[1;31m-----------------------------------------------------------------------\e[00m"
read -e RANGE
mkdir "$REF" >/dev/null 2>&1
cd "$REF"
echo "$REF" > REF
echo "$INT" > INT
echo ""
echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Do you want to exclude any IPs from the scan i.e your Windows host? - Enter yes or no and press ENTER"
echo -e "\e[1;31m-----------------------------------------------------------------------------------------------------------\e[00m"
read EXCLUDEANS

if [ $EXCLUDEANS = yes ]
		then
			echo ""
			echo -e "\e[1;31m------------------------------------------------------------------------------------------\e[00m"
			echo -e "\e[01;31m[?]\e[00m Enter the IP addresses to exclude i.e 192.168.1.1, 192.168.1.1-10 - normal nmap format"
			echo -e "\e[1;31m------------------------------------------------------------------------------------------\e[00m"
			read EXCLUDEDIPS
			EXCLUDE="--exclude "$EXCLUDEDIPS""
			echo "$EXCLUDE" > excludetmp
			echo -e "\e[01;33m[-]\e[00m The following IP addresses were asked to be excluded from the scan = "$EXCLUDEDIPS"" > "$REF"_nmap_hosts_excluded.txt
		else
			EXCLUDE=""
			echo "$EXCLUDE" > excludetmp
		fi

		echo $RANGE |grep "[0-9]" >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo ""
		echo -e "\e[01;32m[-]\e[00m  You entered a manual IP or range, scan will now start"
		echo ""
		echo -e "\e[01;32m[-]\e[00m $REF - Finding Live hosts via $INT, please wait"
		echo ""
		nmap -e $INT -sP $EXCLUDE -n --stats-every 4 -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan $RANGE >/dev/null &
		sleep 5
		until [ "$STATUS" = "success" ]
		do
		PERCENT=`cat "$REF"_nmap_PingScan.xml 2>/dev/null |grep "percent" |cut -d '"' -f 6 |tail -1 |cut -d "." -f 1`
		STATUS=`cat "$REF"_nmap_PingScan.xml 2>/dev/null |grep -i "exit" |cut -d '"' -f 10`
		
        progressbar && spin

        # do work
        sleep 0.2
		
	done
endspin
		
		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep "Up" |awk '{print $2}' > "$REF"_hosts_Up.txt
		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep  "Down" |awk '{print $2}' > "$REF"_hosts_Down.txt

echo ""
echo -e "\e[01;32m[+]\e[00m Scan is 100% complete"
echo ""

	else
		echo ""
		echo -e "\e[01;32m[-]\e[00m You entered a file as the input, I will just check I can read it ok"
		cat $RANGE >/dev/null 2>&1
			if [ $? = 1 ]
			then
				echo ""
				echo -e "\e[01;31m[!]\e[00m Sorry I can't read that file, check the path and try again!"
				echo ""
			exit 1
		else
			echo ""
			echo -e "\e[01;32m[+]\e[00m I can read the input file ok, Scan will now start"
			echo ""
			echo -e "\e[01;32m[-]\e[00m $REF - Finding Live hosts via $INT, please wait...\e[00m"
			echo ""
			nmap -e $INT -sP $EXCLUDE -n --stats-every 4 -PE -PM -PS21,22,23,25,26,53,80,81,110,111,113,135,139,143,179,199,443,445,465,514,548,554,587,993,995,1025,1026,1433,1720,1723,2000,2001,3306,3389,5060,5900,6001,8000,8080,8443,8888,10000,32768,49152 -PA21,80,443,13306 -vvv -oA "$REF"_nmap_PingScan -iL $RANGE >/dev/null &
			sleep 5
		until [ "$STATUS" = "success" ]
		do
		PERCENT=`cat "$REF"_nmap_PingScan.xml 2>/dev/null |grep "percent" |cut -d '"' -f 6 |tail -1 |cut -d "." -f 1`
		STATUS=`cat "$REF"_nmap_PingScan.xml 2>/dev/null |grep -i "exit" |cut -d '"' -f 10`
		
        progressbar && spin

        # do work
        sleep 0.2
		
	done
endspin
		
		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep "Up" |awk '{print $2}' > "$REF"_hosts_Up.txt
		cat "$REF"_nmap_PingScan.gnmap 2>/dev/null | grep  "Down" |awk '{print $2}' > "$REF"_hosts_Down.txt

echo ""
echo -e "\e[01;32m[+]\e[00m Scan is 100% complete"
echo ""
		fi
fi
echo ""
HOSTSCOUNT=$(cat "$REF"_hosts_Up.txt |wc -l)
HOSTSUPCHK=$(cat "$REF"_hosts_Up.txt)
if [ -z "$HOSTSUPCHK" ]
	then
		echo ""
		echo -e "\e[01;31m[!]\e[00m It seems there are no live hosts present in the range specified..I will run a Arp-scan to double check"
		echo ""
		sleep 4
		arp-scan --interface $INT --file "$REF"_hosts_Down.txt > "$REF"_arp_scan.txt 2>&1
		arp-scan --interface $INT --file "$REF"_hosts_Down.txt |grep -i "0 responded" >/dev/null 2>&1
			if [ $? = 0 ]
				then
					echo -e "\e[01;32m[!]\e[00m No live hosts were found using arp-scan - check IP range/source address and try again. It may be there are no live hosts."
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
					echo -e "\e[01;33m[-]\e[00m Nmap didn't find any live hosts, but apr-scan found the following hosts within the range...script will exit. Try adding these to the host list to scan."
					echo ""
					rm "INT" 2>&1 >/dev/null
					rm "REF" 2>&1 >/dev/null
					rm "excludetmp" 2>&1 >/dev/null
					echo -e "\e[00;32m$ARPUP\e[00m"
					echo ""
					exit 1
	fi
fi
echo -e "\e[1;32m-----------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m The following $HOSTSCOUNT hosts were found up for $REF"
echo -e "\e[1;32m-----------------------------------------------------------------\e[00m"
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[00;32m$HOSTSUP\e[00m"
echo ""
echo -e "\e[01;32m[-]\e[00m Press Enter to scan the live hosts, or CTRL C to cancel"
read ENTER

if [ $COMMONTCP = "on" ]
then
# Scanning Common TCP Ports - CTRL - C if slow to switch to T5 fast
gnome-terminal --title="$REF - Common TCP Port Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);trap control_c SIGINT; control_c() { clear ; echo "" ; echo "" ; echo -e "\e[01;33m[-]\e[00m You interupted the Common TCP Scan for "$REF" - it was probably too slow..? I will run it again with T5..please wait.." ; echo "" ; sleep 3 ; echo -e "\e[01;33m[-]\e[00m Cleaning up T4 Common TCP scan files.." ; sleep 3 ; rm "$REF"_nmap_CommonPorts* >/dev/null ; clear ; echo "" ; echo -e "\e[01;32m[-]\e[00m Now Starting Common TCP scan with T5 option..."$REF"" ; echo "" ; nmap -e $INT -sS $EXCLUDE -PN -T5 -sV --version-intensity 1 -vvv -oA "$REF"_nmap_CommonPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[01;32m[+]\e[00m $REF - Common TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ; exit $? ; } ; echo "" ; echo -e "\e[01;32m[-]\e[00m Starting Common TCP scan for $REF"; echo "" ;  echo -e "\e[01;33m[-]\e[00m If the scan runs too slow, just press CTRL C to switch to a T5 speed scan" ; echo "" ; sleep 3 ; nmap -e $INT -sS $EXCLUDE -PN -T4 -sV --version-intensity 1 -vvv -oA "$REF"_nmap_CommonPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[01;32m[+]\e[00m $REF - Common TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Common TCP scan as turned off in options"
fi

if [ $SCRIPT = "on" ]
then
#Script Scan (not CTRL C option)
gnome-terminal --title="$REF - Script Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);nmap -e $INT -PN $EXCLUDE -A -vvv -oA "$REF"_nmap_ScriptScan -iL "$REF"_hosts_Up.txt -n; echo ""; echo -e "\e[01;32m[+]\e[00m $REF - Script Scan Complete, Press ENTER to Exit";echo "";read ENTERKEY;'
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Script Scan as turned off in options"
fi

if [ $QUICKUDP = "on" ]
then
#Scanning Quick UDP (1,000) Ports - CTRL - C if slow to switch to T5 fast
gnome-terminal --title="$REF - Quick UDP Port Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);trap control_c SIGINT; control_c() { clear ; echo "" ; echo "" ; echo -e "\e[01;33m[-]\e[00m You interupted the Quick UDP Scan for "$REF" - it was probably too slow..? I will run it again with T5..please wait." ; echo "" ; sleep 3 ; echo -e "\e[01;33m[-]\e[00m Cleaning up T4 Quick UDP scan files." ; sleep 3 ; rm "$REF"_nmap_QuickUDP* >/dev/null ; clear ; echo "" ; echo -e "\e[01;32m[-]\e[00m Now Starting Quick UDP scan with T5 option..."$REF"" ; echo "" ; nmap -e $INT -sU $EXCLUDE -Pn -T5 -vvv -oA "$REF"_nmap_QuickUDP -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[01;32m[+]\e[00m $REF - Quick UDP Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ; exit $? ; } ; echo "" ; echo -e "\e[01;32m[-]\e[00m Starting Quick UDP scan for $REF"; echo "" ;  echo -e "\e[01;33m[-]\e[00m If the scan runs too slow, just press CTRL C to switch to a T5 speed scan" ; echo "" ; sleep 3 ; nmap -e $INT -sU $EXCLUDE -Pn -T4 -vvv -oA "$REF"_nmap_QuickUDP -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[01;32m[+]\e[00m $REF - Quick UDP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Quick UDP Scan as turned off in options"
fi

if [ $FULLTCP = "on" ]
then
# Scanning Full TCP Ports - CTRL - C if slow to switch to T5 fast
gnome-terminal --title="$REF - Full TCP Port Scan - $INT" -x bash -c 'REF=$(cat REF);INT=$(cat INT);EXCLUDE=$(cat excludetmp);trap control_c SIGINT; control_c() { clear ; echo "" ; echo "" ; echo -e "\e[01;33m[-]\e[00m You interupted the Full TCP Scan for "$REF" - it was probably too slow..? I will run it again with T5..please wait." ; echo "" ; sleep 3 ; echo -e "\e[01;33m[-]\e[00m Cleaning up T4 Full TCP scan files.." ; sleep 3 ; rm "$REF"_nmap_FullPorts* >/dev/null ; clear ; echo "" ; echo -e "\e[01;32m[-]\e[00m Now Starting Full TCP scan with T5 option..."$REF"" ; echo "" ; nmap -e $INT -sS $EXCLUDE -PN -T5 -p- -sV --version-intensity 1 -vvv -oA "$REF"_nmap_FullPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[01;32m[+]\e[00m $REF - Full TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ; exit $? ; } ; echo "" ; echo -e "\e[01;32m[-]\e[00m Starting Full TCP scan for $REF"; echo "" ;  echo -e "\e[01;33m[-]\e[00m If the scan runs too slow, just press CTRL C to switch to a T5 speed scan" ; echo "" ; sleep 3 ; nmap -e $INT -sS $EXCLUDE -PN -T4 -p- -sV --version-intensity 1 -vvv -oA "$REF"_nmap_FullPorts -iL "$REF"_hosts_Up.txt -n ; echo "" ; echo -e "\e[01;32m[+]\e[00m $REF - Full TCP Port Scan Complete, Press ENTER to Exit" ; echo "" ; read ENTERKEY ;'
else
echo ""
echo -e "\e[01;33m[-]\e[00m Skipping Full TCP as turned off in options"
fi

#clear temp files
sleep 5
rm "INT" 2>&1 >/dev/null
rm "REF" 2>&1 >/dev/null
rm "excludetmp" 2>&1 >/dev/null

clear
echo ""
echo -e "\e[01;32m[-]\e[00m Once all scans are complete, press ENTER on this window to list all unique ports found and continue - $REF"
read ENTERKEY
clear
echo ""
echo -e "\e[1;32m----------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m The following scan start/finish times were recorded for $REF"
echo -e "\e[1;32m----------------------------------------------------------------------------------\e[00m"
echo ""
PINGTIMESTART=`cat "$REF"_nmap_PingScan.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
PINGTIMESTOP=`cat "$REF"_nmap_PingScan.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
COMMONTCPTIMESTART=`cat "$REF"_nmap_CommonPorts.nmap 2>/dev/null  |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
COMMONTCPTIMESTOP=`cat "$REF"_nmap_CommonPorts.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
FULLTCPTIMESTART=`cat "$REF"_nmap_FullPorts.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
FULLTCPTIMESTOP=`cat "$REF"_nmap_FullPorts.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
QUICKUDPTIMESTART=`cat "$REF"_nmap_QuickUDP.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
QUICKUDPTIMESTOP=`cat "$REF"_nmap_QuickUDP.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`
SCRIPTTIMESTART=`cat "$REF"_nmap_ScriptScan.nmap 2>/dev/null |grep -i "scan initiated" | awk '{ print $6 ,$7 ,$8, $9, $10}'`
SCRIPTTIMESTOP=`cat "$REF"_nmap_ScriptScan.nmap 2>/dev/null |grep -i "nmap done" | awk '{ print $5, $6 ,$7 , $8, $9}'`

if [ -z "$PINGTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Ping sweep started $PINGTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Ping sweep started $PINGTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Ping sweep started $PINGTIMESTART\e[00m - \e[00;32mfinished successfully $PINGTIMESTOP"
		echo "Ping sweep started $PINGTIMESTART - finished successfully $PINGTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$COMMONTCPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Common TCP scan started $COMMONTCPTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Common TCP scan started $COMMONTCPTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Common TCP scan started $COMMONTCPTIMESTART\e[00m - \e[00;32mfinished successfully $COMMONTCPTIMESTOP"
		echo "Common TCP scan started $COMMONTCPTIMESTART - finished successfully $COMMONTCPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$FULLTCPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Full TCP scan started $FULLTCPTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Full TCP scan started $FULLTCPTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Full TCP scan started $FULLTCPTIMESTART\e[00m - \e[00;32mfinished successfully $FULLTCPTIMESTOP"
		echo "Full TCP scan started $FULLTCPTIMESTART - finished successfully $FULLTCPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$QUICKUDPTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Quick UDP scan started $QUICKUDPTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Quick UDP scan started $QUICKUDPTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Quick UDP scan started $QUICKUDPTIMESTART\e[00m - \e[00;32mfinished successfully $QUICKUDPTIMESTOP"
		echo "Quick UDP scan started $QUICKUDPTIMESTART - finished successfully $QUICKUDPTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
if [ -z "$SCRIPTTIMESTOP" ]
	then
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;31m[!]\e[00m Script scan started $SCRIPTTIMESTART\e[00m - \e[1;31mscan did not complete or was interrupted!"
		echo "Script scan started $SCRIPTTIMESTART - scan did not complete or was interrupted!" >> "$REF"_nmap_scan_times.txt
	else
		echo ""
		echo "" >> "$REF"_nmap_scan_times.txt
		echo -e "\e[01;32m[+]\e[00m Script scan started $SCRIPTTIMESTART\e[00m - \e[00;32mfinished successfully $SCRIPTTIMESTOP"
		echo "Script scan started $SCRIPTTIMESTART - finished successfully $SCRIPTTIMESTOP" >> "$REF"_nmap_scan_times.txt
fi
echo ""
echo -e "\e[1;32m------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m Unique TCP and UDP Port Summary - $REF"
echo -e "\e[1;32m------------------------------------------------------------------\e[00m"
UNIQUE=$(cat *.xml |grep -i 'open"' |grep -i "portid=" |cut -d '"' -f 4,5,6| grep -o '[0-9]*' |sort --unique |paste -s -d, 2>&1)
echo $UNIQUE >"$REF"_nmap_unique_ports.txt
if [ -z "$UNIQUE" ]
then
	echo -e "\e[01;31m[!]\e[00m No open ports were found on any scans"
else
echo -e "\e[00;32m$UNIQUE\e[00m"
echo ""
fi
echo ""
echo -e "\e[1;32m-----------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m The following $HOSTSCOUNT hosts were up and scanned for $REF"
echo -e "\e[1;32m-----------------------------------------------------------------------\e[00m"
HOSTSUP=$(cat "$REF"_hosts_Up.txt)
echo -e "\e[00;32m$HOSTSUP\e[00m"
echo ""
echo ""
#Check for excluded IPs
ls "$REF"_nmap_hosts_excluded.txt >/dev/null 2>&1
if [ $? = 0 ]
	then
		echo -e "\e[1;32m--------------------------------------------------------------------------------\e[00m"
		echo -e "\e[01;32m[+]\e[00m The following hosts were requested to be excluded from scans for $REF"
		echo -e "\e[1;32m---------------------------------------------------------------------------------\e[00m"
		echo -e "\e[00;32m$EXCLUDEDIPS\e[00m"
		echo ""
	else
	echo ""
fi
echo -e "\e[01;33m[-]\e[00m Output files have all been saved to the \e[00;32m"$REF"\e[00m directory"
echo ""

# check for Nessus template

POLICYNAME=$(grep -l -i "</NessusClientData_v2>" --exclude=\*.sh --exclude=\*.exe --exclude=\*.bin ../* 2>/dev/null) #default Nessus template - save just one template with any extension - must be within script directory
ls "$POLICYNAME" 2>&1 >/dev/null
if [ $? = 0 ]
	then
	cat "$POLICYNAME" |grep -i "screenshot" 2>&1 >/dev/null
		if [ $? = 0 ]
			then
				echo ""
				echo -e "\e[01;33m[-]\e[00m Nessus Version 5 Policy detected, I will output for this version"
				echo ""
				NESSUSVER="5"
			else
				echo ""
				echo -e "\e[01;33m[-]\e[00m Nessus Version detected is older than Version 5, I will output a compatible version"
				echo ""
				NESSUSVER="4"
		fi
if [ "$NESSUSVER" = 5 ]
	then
## Nessus 5 Custom Policy
	FINDPOLICY=$(cat $POLICYNAME |grep policyName) #find Nessus policy name
	NEWPOLICY="<policyName>$REF</policyName>" #set Nessus policy name
	NEWPORTS="<value>$UNIQUE</value>" #set Nessus policy unique tcp/udp ports
	NEWCOMMENTS="<policy_comments>"$REF" Custom Scan of the following unique ports "$UNIQUE"</policy_comments>" #Add Nessus policy comments
	ENABLESAFE="<value>yes</value>" #enable Nessus safe checks only - wont run DoS plugins
	ENABLECLOSED="<value>yes</value>" #set Nessus consider unscanned ports closed - scans only unique ports
	OFFSTOP="<value>no</value>" #set Nessus to disable stop scan on disconnect
	# Create custom Nessus 5 Policy
	cat $POLICYNAME | sed "s#$FINDPOLICY#$NEWPOLICY#" >"$REF"_nessus_policy.nessus
	FINDPORTS=$(cat $POLICYNAME |awk '/port_range/{getline; print NR}') #find ports
	FINDSAFE=$(cat $POLICYNAME | awk '/<name>safe_checks/{getline; print NR}') #find Nessus safe check value
	FINDCLOSED=$(cat $POLICYNAME |awk '/unscanned_closed/{getline; print NR}') # find consider unclosed ports closed
	FINDSTOP=$(cat $POLICYNAME |awk '/stop_scan_on_disconnect/{getline; print NR}') #find stop scan on disconnect
	FINDCOMMENTS=$(cat $POLICYNAME |awk '/<policy_comments>tempcomment/{getline; print NR}') #find nessus comment value
	sed -i "$FINDPORTS"i"$NEWPORTS" "$REF"_nessus_policy.nessus
	sed -i "$FINDSAFE"i"$ENABLESAFE" "$REF"_nessus_policy.nessus
	sed -i "$FINDCLOSED"i"$ENABLECLOSED" "$REF"_nessus_policy.nessus
	sed -i "$FINDSTOP"i"$OFFSTOP" "$REF"_nessus_policy.nessus
	sed -i '/visibility/a<policy_comments>'"$NEWCOMMENTS"'</policy_comments>' "$REF"_nessus_policy.nessus
	echo ""
		echo -e "\e[01;32m[+]\e[00m I have created a custom policy Nessus 5 policy file named \e[01;32m"$REF"_nessus_policy.nessus\e[00m - Import this into Nessus for a faster custom scan just on the above live hosts"
		echo ""
		echo -e "\e[01;33m[-]\e[00m Remember to export and update the Nessus template file regularly after updating Nessus to ensure the latest modules are included - ensure the correct options are enabled"
		echo ""
		
elif [ "$NESSUSVER" = 4 ]
	then
	## Nessus 4 Custom Policy
	FINDPOLICY=$(cat $POLICYNAME |grep policyName) #find Nessus policy name
	NEWPOLICY="<Policy><policyName>$REF</policyName>" #set Nessus policy name
	NEWPORTS="<value>$UNIQUE</value>" #set Nessus policy unique tcp/udp ports
	FINDCOMMENTS=$(cat $POLICYNAME |grep policyComments) #find Nessus comment value
	NEWCOMMENTS="<policyComments>"$REF" Custom Scan of the following unique ports "$UNIQUE"</policyComments>" #Add Nessus policy comments
	ENABLESAFE="<value>yes</value>" #enable Nessus safe checks only - wont run DoS plugins
	ENABLECLOSED="<value>yes</value>" #set Nessus consider unscanned ports closed - scans only unique ports
	OFFSTOP="<value>no</value>" #set Nessus to disable stop scan on disconnect
	# Create custom Nessus Policy
	cat $POLICYNAME | sed "s#$FINDPOLICY#$NEWPOLICY#" |sed "s#$FINDCOMMENTS#$NEWCOMMENTS#"  >"$REF"_nessus_policy.nessus
	FINDPORTS=$(cat $POLICYNAME |awk '/port_range/{getline; print NR}') #find ports
	FINDSAFE=$(cat $POLICYNAME | awk '/safe_checks/{getline; print NR}') #find Nessus safe check value
	FINDCLOSED=$(cat $POLICYNAME |awk '/unscanned_closed/{getline; print NR}') # find consider unclosed ports closed
	FINDSTOP=$(cat $POLICYNAME |awk '/stop_scan_on_disconnect/{getline; print NR}') #find stop scan on disconnect
	sed -i "$FINDPORTS"i"$NEWPORTS" "$REF"_nessus_policy.nessus
	sed -i "$FINDSAFE"i"$ENABLESAFE" "$REF"_nessus_policy.nessus
	sed -i "$FINDCLOSED"i"$ENABLECLOSED" "$REF"_nessus_policy.nessus
	sed -i "$FINDSTOP"i"$OFFSTOP" "$REF"_nessus_policy.nessus
		echo ""
		echo -e "\e[01;32m[+]\e[00m I have created a custom policy Nessus 4 policy file named \e[01;32m"$REF"_nessus_policy.nessus\e[00m - Import this into Nessus for a faster custom scan just on the above live hosts"
		echo ""
		echo -e "\e[01;33m[-]\e[00m Remember to export and update the Nessus template file regularly after updating Nessus to ensure the latest modules are included - ensure the correct options are enabled"
		echo ""
	fi
		
	else
	echo ""
fi
exit 0
