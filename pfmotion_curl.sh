#!/bin/sh
# Author: Mr Xhark -> @xhark
# License : Creative Commons http://creativecommons.org/licenses/by-nd/4.0/deed.fr
# Website : http://blogmotion.fr
# backup pfsense from v2.2.6 to v2.4.3 and more (https://doc.pfsense.org/index.php/Remote_Config_Backup)

version="2022.01.25_cURL"
rundir="$( cd "$( dirname "$0" )" && pwd )"

##############################
######### VARIABLES  #########

config_file=/etc/server-credentials/pfsense #read username and password from a config file here formatted like this:
#pfsense_username=usernamehere
#pfsense_password=passwordhere

# pfSense host OR IP (note: do not include the final /, otherwise backup will fail)
pfsense_host=https://192.168.0.1

# where to store backups
backup_dir=~/DRIVE/share/backup/pfsense/automated_backups

######## END VARIABLES ########
##############################

######################################### DO NOT TOUCH ANYTHING BELOW THIS LINE #########################################

. $config_file #load the username and password from the congig file location provided in variables section

echo
echo "*** pfMotion-backup script by @xhark (v${version}) ***"
echo

curl -V $i >/dev/null 2>&1 || { echo "ERROR : cURL MUST be installed to run this script."; exit 1; }

# backup filename
backup_name="$backup_dir/pfSense-backup-`date +%Y-%m-%d`.xml"
cookie_file="`mktemp /tmp/pfsbck.XXXXXXXX`"
csrf1_token="`mktemp /tmp/csrf1.XXXXXXXX`"
csrf2_token="`mktemp /tmp/csrf2.XXXXXXXX`"
config_tmp="`mktemp /tmp/config-tmp-xml.XXXXXXXX`"
now=`date +%Y%m%d%H%M%S`

unset RRD PKG PW

if [ "$backup_rrd" = "0" ] ;	 then RRD="&donotbackuprrd=yes" ; fi
if [ "$backup_pkginfo" = "0" ] ; then PKG="&nopackages=yes" ; fi
if [ -n "$backup_password" ] ; 	 then PW="&encrypt_password=$backup_password&encrypt_passconf=$backup_password&encrypt=on" ; fi

mkdir -p "$backup_dir"

# fetch login
curl -Ss --noproxy '*' --insecure --cookie-jar $cookie_file "$pfsense_host/diag_backup.php" \
  | grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/' > $csrf1_token \
  || echo "ERROR: FETCH"

# submit the login
curl -Ss --noproxy '*' --insecure --location --cookie-jar $cookie_file --cookie $cookie_file \
  --data "login=Login&usernamefld=${pfsense_username}&passwordfld=${pfsense_password}&__csrf_magic=$(cat $csrf1_token)" \
 "$pfsense_host/diag_backup.php"  | grep "name='__csrf_magic'" \
  | sed 's/.*value="\(.*\)".*/\1/' > $csrf2_token \
  || echo "ERROR: SUBMIT THE LOGIN"

# submit download to save config xml
curl -Ss --noproxy '*' --insecure --cookie-jar $cookie_file --cookie $cookie_file \
  --data "Submit=download&download=download&donotbackuprrd=yes&__csrf_magic=$(head -n 1 $csrf2_token)" \
  "$pfsense_host/diag_backup.php" > $config_tmp \
  || echo "ERROR: SAVING XML FILE"

# check if credentials are valid
if grep -qi 'username or password' $config_tmp; then
        echo ; echo "   !!! AUTHENTICATION ERROR (${pfsense_host}): PLEASE CHECK LOGIN AND PASSWORD"; echo
        rm -f $config_tmp
        exit 1
fi

# xml file contains doctype when the URL is wrong
if grep -qi 'doctype html' $config_tmp; then
	echo ; echo "   !!! URL ERROR (${pfsense_host}): HTTP OR HTTPS ?"; echo
	rm -f $config_tmp
	exit 1
fi

hostname=$(grep -m1 '<hostname' $config_tmp | cut -f2 -d">"|cut -f1 -d"<")
domain=$(grep -m1 '<domain' $config_tmp | cut -f2 -d">"|cut -f1 -d"<")
backup_file="config-${hostname}_${domain}-${now}.xml"

# definitive config file name
mv $config_tmp "$backup_dir/$backup_file" && echo "Backup OK : $backup_dir/$backup_file" || echo "Backup NOK !!! ERROR !!!"

# cleaning tmp and cookie files
rm -f "$cookie_file" "$csrf1_token" "$csrf2_token"

# delete backups older than six months old
find "$backup_dir/" -type f -mtime +183 -exec rm {} \; #https://www.provya.com/blog/pfsense-making-automatic-backups-with-a-script/

echo
exit 0
