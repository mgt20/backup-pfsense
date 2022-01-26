backup-pfsense (backup pfsense)
===

### Description
This script saves the configuration of a pfSense firewall, by retrieving the XML file remotely via HTTP(S).

## Variables
You will need to create a file and within it provide the username and password of the pfsense user that will perform the automated backups. For the config file, format it like this:

```
pfsense_username=usernamehere

pfsense_password=passwordhere
```

I recommend limiting access to that file, with something like ```chmod 0400 filename``` , replacing 'filename' with the actual filename of the file that contains the username and password

I recommend that you create a dedicated user (System > User Manager) with at least the "WebCfg - Diagnostics: Backup & Restore" privilege.
For security reasons, the "admin" account is not recommended (password in clear text in the script).

You must edit the script (nano, vim, etc.) to enter at least:
- [X] IP or FQDN name (without trailing slash)
- [X] path to a file with the username and password to pfsense
- [X] path to the backup location

## 🚦 Minimum Requirements
Need
- [X] shell or bash
- [X] wget or cURL

In theory works on any Linux distribution. Tested on Debian, CentOS, pfSense.

Note: modification of the BACKUP_RRD, BACKUP_PKGINFO, BACKUP_PASSWORD variables is currently not supported._

## Compatibility
This script is compatible with pfSense:
- [X] 2.5.x
- [X] 2.4.x
- [X] 2.3.x
- [X] 2.2.x

Not tested on lower versions.

Validated with the versions:
- [X] 2.5.2
- [X] 2.4.3
- [X] 2.4.0
- [X] 2.3.4-RELEASE-p1
- [X] 2.3.3
- [X] 2.3.2
- [X] 2.3.1
- [X] 2.2.5

### 🚀 Usage
It is recommended to create a dedicated directory to store the script there.
XML configurations are stored in a dedicated subdirectory.

Version cURL:
```
chmod +x pfmotion_curl.sh
./pfmotion_curl.sh
```

The backup file contains the name of the firewall:
```
/tmp/conf_backup/config-<host-name>_<domain>-<YYYYmmDDHHMMSS>.xml
```
Example :
```
/tmp/conf_backup/config-pf_blogmotion.fr-20171007002812.xml
```

