#!/bin/bash

# Setting healthcheck status to "starting"
echo 'starting' > /opt/scripts/.docker_config/.healthcheck

# Reading ENV
adminport=$IOB_ADMINPORT
avahi=$AVAHI
multihost=$IOB_MULTIHOST
offlinemode=$OFFLINE_MODE
objectsdbhost=$IOB_OBJECTSDB_HOST
objectsdbport=$IOB_OBJECTSDB_PORT
objectsdbtype=$IOB_OBJECTSDB_TYPE
packages=$PACKAGES
setgid=$SETGID
setuid=$SETUID
statesdbhost=$IOB_STATESDB_HOST
statesdbport=$IOB_STATESDB_PORT
statesdbtype=$IOB_STATESDB_TYPE
usbdevices=$USBDEVICES
zwave=$ZWAVE

pkill_timeout=10      # timeout for iobroker shutdown in seconds

# Getting date and time for logging
dati=`date '+%Y-%m-%d %H:%M:%S'`

# Logging header
echo ' '
echo "$(printf -- '-%.0s' {1..80})"
echo -n "$(printf -- '-%.0s' {1..25})" && echo -n "     "$dati"      " && echo "$(printf -- '-%.0s' {1..25})"
echo "$(printf -- '-%.0s' {1..80})"
echo ' '
echo "$(printf -- '-%.0s' {1..80})"
echo "-----                 Welcome to your ioBroker-container!                  -----"
echo "-----                    Startupscript is now running.                     -----"
echo "-----                          Please be patient!                          -----"
echo "$(printf -- '-%.0s' {1..80})"
echo ' '
echo "$(printf -- '-%.0s' {1..80})"
echo "-----                        Debugging information                         -----"
echo "-----                                                                      -----"
echo "-----                                System                                -----"
echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" arch: $(uname -m))" && echo " -----"
echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" hostname: $(hostname))" && echo " -----"
echo "-----                                                                      -----"
echo "-----                             Docker-Image                             -----"
echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" image: ${VERSION})" && echo " -----"
echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" build: ${BUILD})" && echo " -----"
echo "-----                                                                      -----"
echo "-----                               Versions                               -----"
echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" node: $(node -v))" && echo " -----"
echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" npm: $(npm -v))" && echo " -----"
echo "-----                                                                      -----"
echo "-----                                 ENV                                  -----"
if [ "$avahi" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" AVAHI: $avahi)" && echo " -----"; fi
if [ "$adminport" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_ADMINPORT: $adminport)" && echo " -----"; fi
if [ "$multihost" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_MULTIHOST: $multihost)" && echo " -----"; fi
if [ "$objectsdbhost" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_OBJECTSDB_HOST: $objectsdbhost)" && echo " -----"; fi
if [ "$objectsdbport" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_OBJECTSDB_PORT: $objectsdbport)" && echo " -----"; fi
if [ "$objectsdbtype" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_OBJECTSDB_TYPE: $objectsdbtype)" && echo " -----"; fi
if [ "$statesdbhost" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_STATESDB_HOST: $statesdbhost)" && echo " -----"; fi
if [ "$statesdbport" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_STATESDB_PORT: $statesdbport)" && echo " -----"; fi
if [ "$statesdbtype" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" IOB_STATESDB_TYPE: $statesdbtype)" && echo " -----"; fi
if [ "$offlinemode" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" OFFLINE_MODE: $offlinemode)" && echo " -----"; fi
if [ "$packages" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" PACKAGES: "$packages")" && echo " -----"; fi
if [ "$setgid" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" SETGID: $setgid)" && echo " -----"; fi
if [ "$setuid" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" SETUID: $setuid)" && echo " -----"; fi
if [ "$usbdevices" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" USBDEVICES: $usbdevices)" && echo " -----"; fi
if [ "$zwave" != "" ]; then echo -n "-----                    " && echo -n "$(printf "%-20s %-28s" ZWAVE: $zwave)" && echo " -----"; fi
echo "$(printf -- '-%.0s' {1..80})"
echo ' '

#####
# STEP 1 - Preparing container
#####
echo "$(printf -- '-%.0s' {1..80})"
echo "-----                  Step 1 of 5: Preparing container                   -----"
echo "$(printf -- '-%.0s' {1..80})"
echo ' '

# Actions running on first start only
if [ -f /opt/.firstrun ]; then
  # Updating Linux packages
  if [ "$offlinemode" = "true" ]; then
    echo 'Offline mode is activated by ENV. Skipping Linux package updates on first run.'
    echo ' '
  else
    echo 'Updating Linux packages on first run...'
      bash /opt/scripts/setup_packages.sh -update
    echo 'Done.'
    echo ' '
  fi
  # Register maintenance script
  echo -n 'Registering maintenance script as command... '
  echo "alias maintenance=\'/opt/scripts/maintenance.sh\'" >> /root/.bashrc
  echo "alias maint=\'/opt/scripts/maintenance.sh\'" >> /root/.bashrc
  echo "alias m=\'/opt/scripts/maintenance.sh\'" >> /root/.bashrc
  echo 'Done.'
  echo ' '
else
  echo 'This is not the first run of this container. Skipping first run preparation.'
  echo ' '
fi

# Installing packages from ENV
if [ "$packages" != "" ] && [ "$offlinemode" = "true" ]; then
  echo 'Installing additional packages is set by ENV but offline mode is activated!'
  echo 'Skipping Linux packages installation.'
  echo ' '
else
  echo 'Installing additional packages is set by ENV.'
  echo "Checking the following Packages:" $packages"..."
  echo $packages > /opt/scripts/.docker_config/.packages
    bash /opt/scripts/setup_packages.sh -install
  echo 'Done.'
  echo ' '
fi

# Setting UID and/ or GID
if [ $(cat /etc/group | grep 'iobroker:' | cut -d':' -f3) != $setgid ] || [ $(cat /etc/passwd | grep 'iobroker:' | cut -d':' -f3) != $setuid ]; then
  echo "Different UID and/ or GID is set by ENV."
  echo -n "Changing UID to "$setuid" and GID to "$setgid"... "
    usermod -u $setuid iobroker
    groupmod -g $setgid iobroker
  echo 'Done.'
  echo ' '
fi

# Change directory for next steps
cd /opt/iobroker

#####
# STEP 2 - Detecting ioBroker-Installation
#####
echo "$(printf -- '-%.0s' {1..80})"
echo "-----             Step 2 of 5: Detecting ioBroker installation             -----"
echo "$(printf -- '-%.0s' {1..80})"
echo ' '

if [ `find /opt/iobroker -type f | wc -l` -lt 1 ]
then
  echo "There is no data detected in /opt/iobroker."
  echo -n "Restoring initial ioBroker installation... "
    tar -xf /opt/initial_iobroker.tar -C /
  echo 'Done.'
elif [ -f /opt/iobroker/iobroker ]
then
  echo "Existing installation of ioBroker detected in /opt/iobroker."
elif [ $(ls *_backupiobroker.tar.gz 2> /dev/null | wc -l) != "0" ] && [ $(tar -ztvf /opt/iobroker/*_backupiobroker.tar.gz "backup/backup.json" 2> /dev/null | wc -l) != "0" ]
then
  if [ "$multihost" = "slave" ]
  then
    echo "IoBroker backup file detected in /opt/iobroker. But Multihost is set to \"slave\"."
    echo "Restoring a backup is not supported on Multihost slaves. Please check configuration and start over."
    echo "For more information see ioBroker Docker Image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
    exit 1
  else
    echo "IoBroker backup file detected in /opt/iobroker."
    echo -n "Preparing restore... "
      mv /opt/iobroker/*.tar.gz /opt/
      tar -xf /opt/initial_iobroker.tar -C /
      mkdir /opt/iobroker/backups
      mv /opt/*.tar.gz /opt/iobroker/backups/
      # fixing permission errors during restore
      chown -R $setuid:$setgid /opt/iobroker
    echo 'Done.'
    echo -n "Restoring ioBroker... "
      bash iobroker restore 0 > /opt/iobroker/log/restore.log 2>&1
    echo 'Done.'
    echo ' '
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!!!!                             IMPORTANT NOTE                             !!!!!"
    echo "!!!!!        The sartup script restored iobroker from a backup file.         !!!!!"
    echo "!!!!! Check /opt/iobroker/log/restore.log to see if restore was successful.  !!!!!"
    echo "!!!!! When ioBroker now starts it will reinstall all Adapters automatically. !!!!!"
    echo "!!!!!         This might be take a looooong time! Please be patient!         !!!!!"
    echo "!!!!!  You can view installation process by taking a look at ioBroker log.   !!!!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  fi
else
  echo "There is data detected in /opt/iobroker but it looks like it is no instance of ioBroker or a valid backup file!"
  echo "Please check/ recreate mounted folder or volume and start over."
  exit 1
fi
echo ' '

#####
# STEP 3 - Checking ioBroker-Installation
#####
echo "$(printf -- '-%.0s' {1..80})"
echo "-----             Step 3 of 5: Checking ioBroker installation              -----"
echo "$(printf -- '-%.0s' {1..80})"
echo ' '

# (Re)Setting permissions to "/opt/iobroker" and "/opt/scripts"
echo -n "(Re)Setting folder permissions (This might take a while! Please be patient!)... "
  chown -R $setuid:$setgid /opt/iobroker
  chown -R $setuid:$setgid /opt/scripts
echo 'Done.'
echo ' '

# Backing up original iobroker-file and changing sudo to gosu
echo -n "Fixing \"sudo-bug\" by replacing sudo in iobroker with gosu... "
  cp -a /opt/iobroker/iobroker /opt/iobroker/iobroker.bak
  chmod 755 /opt/iobroker/iobroker
  sed -i 's/sudo -H -u/gosu/g' /opt/iobroker/iobroker
echo 'Done.'
echo ' '

# checking hostname in ioBroker to match container hostname
if [ $(bash iobroker object get system.adapter.admin.0 --pretty | grep -oP '(?<="host": ")[^"]*') != $(hostname) ] && [ "$multihost" != "slave" ]
then
  echo "Hostname in ioBroker does not match the hostname of this container."
  echo -n "Updating hostname to " $(hostname)"... "
    bash iobroker host $(iobroker object get system.adapter.admin.0 --pretty | grep -oP '(?<="host": ")[^"]*')
  echo 'Done.'
  echo ' '
fi

#####
# STEP 4 - Setting up prerequisites for some ioBroker-adapters
#####
echo "$(printf -- '-%.0s' {1..80})"
echo "-----                Step 4 of 5: Applying special settings                -----"
echo "$(printf -- '-%.0s' {1..80})"
echo ' '

echo "Some adapters have special requirements/ settings which can be activated by the use of environment variables."
echo "For more information see ioBroker Docker Image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
echo ' '

# Checking ENV for Adminport
if [ "$adminport" != "" ]
then
  if [ "$adminport" != $(bash iobroker object get system.adapter.admin.0 --pretty | grep -oP '(?<="port": )[^,]*') ]
  then
    echo "Adminport set by ENV does not match port configured in ioBroker installation."
    echo -n "Setting Adminport to \""$adminport"\"... "
      bash iobroker set admin.0 --port $adminport
    echo 'Done.'
    echo ' '
  fi
fi

# Checking ENV for AVAHI
if [ "$avahi" = "true" ] && [ "$offlinemode" = "true" ]; then
  echo 'Avahi-daemon is activated by ENV but offline mode is activated!'
  echo 'Skipping Avahi daemon setup.'
else
  echo 'Avahi-daemon is activated by ENV.'
    chmod 755 /opt/scripts/setup_avahi.sh
    bash /opt/scripts/setup_avahi.sh
  echo ' '
fi

# Checking ENV for Z-WAVE
if [ "$zwave" = "true" ] && [ "$offlinemode" = "true" ]; then
  echo 'Z-Wave is activated by ENV but offline mode is activated!'
  echo 'Skipping Z-Wave setup.'
else
  echo "Z-Wave is activated by ENV."
    chmod 755 /opt/scripts/setup_zwave.sh
    bash /opt/scripts/setup_zwave.sh
  echo ' '
fi

# checking ENV for USBDEVICES
if [ "$usbdevices" != "none" ]; then
  echo "Usb-device-support is activated by ENV."
  IFS=';' read -ra devicearray <<< "$usbdevices"
    for i in "${devicearray[@]}"
    do
      echo -n "Setting permissions for" $i"... "
      chown root:dialout $i
      chmod g+rw $i
    done
  echo 'Done.'
  echo ' '
fi

# Checking ENV for multihost setup
if [ "$multihost" != "" ]
then
  echo "Checking multihost setup..."
  # Configuring objects db host
  if [ "$multihost" = "master" ] && [ "$objectsdbtype" = "" ] && [ "$objectsdbhost" = "" ] && [ "$objectsdbport" = "" ]
  then
    echo "Multihost is set as \"master\" by ENV and no external objects db is set."
    echo -n "Setting host of objects db to \"0.0.0.0\" to allow external communication... "
      jq --arg objectsdbhost "0.0.0.0" '.objects.host = $objectsdbhost' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  elif [ "$multihost" = "master" ] && [ "$objectsdbhost" = "127.0.0.1" ]
  then
    echo "Multihost is set as \"master\" by ENV. But objects db host is set to \"127.0.0.1\" by ENV too."
    echo "This configuration will not allow slaves to connect the objects db! Please change or remove ENV \"IOB_OBJECTSDB_HOST\" and start over!"
    echo "For more information see ioBroker Docker Image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
    exit 1
  elif [ "$multihost" = "master" ] &&  [ "$objectsdbtype" != "" ] && [ "$objectsdbhost" != "" ] && [ "$objectsdbport" != "" ]
  then
    echo "Multihost is set as \"master\" by ENV and external objects db is set."
  elif ([ "$multihost" = "slave" ] && [ "$objectsdbtype" = "" ]) || ([ "$multihost" = "slave" ] && [ "$objectsdbhost" = "" ]) || ([ "$multihost" = "slave" ] && [ "$objectsdbport" = "" ])
  then
    echo "Multihost is set as \"slave\" by ENV. But no external objects db is set."
    echo "You have to configure ENVs \"IOB_OBJECTSDB_TYPE\", \"IOB_OBJECTSDB_HOST\" and \"IOB_OBJECTSDB_PORT\" to connect to a maser objects db."
    echo "Please check your settings and start over."
    echo "For more information see ioBroker Docker Image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
    exit 1
  elif [ "$multihost" = "slave" ] && [ "$objectsdbtype" != "" ] && [ "$objectsdbhost" != "" ] && [ "$objectsdbport" != "" ]
  then
    echo "Multihost is set as \"slave\" by ENV and external objects db is set."
  elif [ "$multihost" != "" ]
  then
    echo "Multihost is set but it seems like some configuration is missing."
    echo "Please checke if you have configured the ENVs \"MULTIHOST\", \"IOB_OBJECTSDB_TYPE\", \"IOB_OBJECTSDB_HOST\" and \"IOB_OBJECTSDB_PORT\" correctly and start over."
    echo "For more information see ioBroker Docker Image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
    exit 1
  fi

   # Configuring states db host
  if [ "$multihost" = "master" ] && [ "$statesdbtype" = "" ] && [ "$statesdbhost" = "" ] && [ "$statesdbport" = "" ]
  then
    echo "Multihost is set as \"master\" by ENV and no external states db is set."
    echo -n "Setting host of states db to \"0.0.0.0\" to allow external communication... "
      jq --arg statesdbhost "0.0.0.0" '.states.host = $statesdbhost' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  elif [ "$multihost" = "master" ] && [ "$statesdbhost" = "127.0.0.1" ]
  then
    echo "Multihost is set as \"master\" by ENV. But states db host is set to \"127.0.0.1\" by ENV too."
    echo "This configuration will not work! Please change or remove ENV \"IOB_STATESDB_HOST\" and start over!"
    echo "For more information see ioBroker Docker Image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
    exit 1
  elif [ "$multihost" = "master" ] && [ "$statesdbtype" != "" ] && [ "$statesdbhost" != "" ] && [ "$statesdbport" != "" ]
  then
    echo "Multihost is set as \"master\" by ENV and external states db is set."
  elif ([ "$multihost" = "slave" ] && [ "$statesdbtype" = "" ]) || ([ "$multihost" = "slave" ] && [ "$statesdbhost" = "" ]) || ([ "$multihost" = "slave" ] && [ "$statesdbport" = "" ])
  then
    echo "Multihost is set as \"slave\" by ENV. But no external states db is set."
    echo "You have to configure ENVs \"IOB_STATESDB_TYPE\", \"IOB_STATESDB_HOST\" and \"IOB_STATESDB_PORT\" to connect to a maser states db."
    echo "Please check your settings and start over."
    echo "For more information see ioBroker Docker Image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
    exit 1
  elif [ "$multihost" = "slave" ] && [ "$statesdbtype" != "" ] && [ "$statesdbhost" != "" ] && [ "$statesdbport" != "" ]
  then
    echo "Multihost is set as \"slave\" by ENV and external states db is set."
  elif [ "$multihost" != "" ]
  then
    echo "Multihost is set but it seems like some configuration is missing."
    echo "Please checke if you have configured the ENVs \"MULTIHOST\", \"IOB_STATESDB_TYPE\", \"IOB_STATESDB_HOST\" and \"IOB_STATESTDB_PORT\" correctly and start over."
    echo "For more information see ioBroker Docker image Docs (https://docs.buanet.de/iobroker-docker-image/docs/)."
    exit 1
  fi
  echo 'Done.'
  echo ' '
fi

# Checking ENVs for custom setup of objects db
if [ "$objectsdbtype" != "" ] || [ "$objectsdbhost" != "" ] || [ "$objectsdbport" != "" ]
then
  echo "Checking custom settings for objects db..."
  if [ "$objectsdbtype" != $(jq -r '.objects.type' /opt/iobroker/iobroker-data/iobroker.json) ]
  then
    echo "IOB_OBJECTSDB_TYPE is set and value is different from detected ioBroker installation."
    echo -n "Setting type of objects db to \""$objectsdbtype"\"... "
      jq --arg objectsdbtype "$objectsdbtype" '.objects.type = $objectsdbtype' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  else
    echo "IOB_OBJECTSDB_TYPE is set and value meets detected ioBroker installation."
  fi
  if [ "$objectsdbhost" != $(jq -r '.objects.host' /opt/iobroker/iobroker-data/iobroker.json) ]
  then
    echo "IOB_OBJECTSDB_HOST is set and value is different from detected ioBroker installation."
    echo -n "Setting host of objects db to \""$objectsdbhost"\"... "
      jq --arg objectsdbhost "$objectsdbhost" '.objects.host = $objectsdbhost' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  else
    echo "IOB_OBJECTSDB_HOST is set and value meets detected ioBroker installation."
  fi
  if [ "$objectsdbport" != $(jq -r '.objects.port' /opt/iobroker/iobroker-data/iobroker.json) ]
  then
    echo "IOB_OBJECTSDB_PORT is set and value is different from detected ioBroker installation."
    echo -n "Setting port of objects db to \""$objectsdbport"\"... "
      jq --arg objectsdbport $objectsdbport '.objects.port = $objectsdbport' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  else
    echo "IOB_OBJECTSDB_PORT is set and value meets detected ioBroker installation."
  fi
  echo "Done."
  echo ' '
fi

# Checking ENVs for custom setup of states db
if [ "$statesdbtype" != "" ] || [ "$statesdbhost" != "" ] || [ "$statesdbport" != "" ]
then
  echo "Checking custom settings for states db..."
  if [ "$statesdbtype" != $(jq -r '.states.type' /opt/iobroker/iobroker-data/iobroker.json) ]
  then
    echo "IOB_STATESDB_TYPE is set and value is different from detected ioBroker installation."
    echo -n "Setting type of states db to \""$statesdbtype"\"... "
      jq --arg statesdbtype "$statesdbtype" '.states.type = $statesdbtype' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  else
    echo "IOB_STATESDB_TYPE is set and value meets detected ioBroker installation."
  fi
  if [ "$statesdbhost" != $(jq -r '.states.host' /opt/iobroker/iobroker-data/iobroker.json) ]
  then
    echo "IOB_STATESDB_HOST is set and value is different from detected ioBroker installation."
    echo -n "Setting host of states db to \""$statesdbhost"\"... "
      jq --arg statesdbhost "$statesdbhost" '.states.host = $statesdbhost' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  else
    echo "IOB_STATESDB_HOST is set and value meets detected ioBroker installation."
  fi
  if [ "$statesdbport" != $(jq -r '.states.port' /opt/iobroker/iobroker-data/iobroker.json) ]
  then
    echo "IOB_STATESDB_PORT is set and value is different from detected ioBroker installation."
    echo -n "Setting port of states db to \""$statesdbport"\"... "
      jq --arg statesdbport $statesdbport '.states.port = $statesdbport' /opt/iobroker/iobroker-data/iobroker.json > /opt/iobroker/iobroker-data/iobroker.json.tmp && mv /opt/iobroker/iobroker-data/iobroker.json.tmp /opt/iobroker/iobroker-data/iobroker.json
      chown -R $setuid:$setgid /opt/iobroker/iobroker-data/iobroker.json && chmod 674 /opt/iobroker/iobroker-data/iobroker.json
    echo 'Done.'
  else
    echo "IOB_STATESDB_PORT is set and value meets detected ioBroker installation."
  fi
  echo "Done."
  echo ' '
fi

# Checking for Userscripts in /opt/userscripts
if [ `find /opt/userscripts -type f | wc -l` -lt 1 ]
then
  echo -n "There is no data detected in /opt/userscripts. Restoring exapmple userscripts... "
    tar -xf /opt/initial_userscripts.tar -C /
    chmod 755 /opt/userscripts/userscript_firststart_example.sh
    chmod 755 /opt/userscripts/userscript_everystart_example.sh
  echo 'Done.'
  echo ' '
elif [ -f /opt/userscripts/userscript_firststart.sh ] || [ -f /opt/userscripts/userscript_everystart.sh ]
then
  if [ -f /opt/userscripts/userscript_firststart.sh ] && [ -f /opt/.firstrun ]
  then
    echo "Userscript for first start detected and this is the first start of a new container."
    echo "Running userscript_firststart.sh..."
      chmod 755 /opt/userscripts/userscript_firststart.sh
      bash /opt/userscripts/userscript_firststart.sh
    echo "Done."
    echo ' '
  fi
  if [ -f /opt/userscripts/userscript_everystart.sh ]
  then
    echo "Userscript for every start detected. Running userscript_everystart.sh..."
      chmod 755 /opt/userscripts/userscript_everystart.sh
      bash /opt/userscripts/userscript_everystart.sh
    echo "Done."
    echo ' '
  fi
fi

# Removing first run marker when exists
if [ -f /opt/.firstrun ]
then
rm -f /opt/.firstrun
fi

#####
# STEP 5 - Starting ioBroker
#####
echo "$(printf -- '-%.0s' {1..80})"
echo "-----                    Step 5 of 5: ioBroker startup                     -----"
echo "$(printf -- '-%.0s' {1..80})"
echo ' '
echo "Starting ioBroker..."
echo ' '

# Setting healthcheck status to "running"
echo "running" > /opt/scripts/.docker_config/.healthcheck

# Function for graceful shutdown by SIGTERM signal
shut_down() {
  echo ' '
  echo "Recived termination signal (SIGTERM)."
  echo "Shutting down ioBroker..."

  local status timeout

  timeout="$(date --date="now + $pkill_timeout sec" +%s)"
  pkill -u iobroker -f iobroker.js-controller
  status=$?
  if (( status >= 2 )); then      # syntax error or fatal error
    return 1
  fi

  if (( status == 1 )); then      # no processes matched
    return
  fi

  # pgrep exits with status 1 when there are no matches
  while pgrep -u iobroker > /dev/null; (( $? != 1 )); do
    if (($(date +%s) > timeout)); then
      echo -e '\nTimeout reached. Killing remaining processes...'
      pkill --signal SIGKILL -u iobroker
      echo 'Done. Have a nice day!'
      exit
    fi

    echo -n '.'
    sleep 1
  done

  echo -e '\nDone. Have a nice day!'
  exit
}

# Trap to get signal for graceful shutdown
trap 'shut_down' SIGTERM

# IoBroker start
gosu iobroker node node_modules/iobroker.js-controller/controller.js & wait

# Fallback process for keeping container running when ioBroker is stopped for maintenance (e.g. js-controller update)
tail -f /dev/null
