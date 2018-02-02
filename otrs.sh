#!/bin/bash

if [ ! -f "/installed" ]  ; then
    su -c "/opt/src/link.pl /opt/src/otrs /opt/otrs" -s /bin/bash otrs
    
    rm /opt/otrs/bin/otrs.SetPermissions.pl
    cp /opt/src/otrs/bin/otrs.SetPermissions.pl /opt/otrs/bin/otrs.SetPermissions.pl


    ## Create missing directories from GIT
    for dir in "/opt/otrs/var/spool" "/opt/otrs/var/tmp" "/opt/otrs/var/article"; do
        mkdir "${dir}"
        chown otrs:www-data "${dir}"
    done

    /opt/otrs/bin/otrs.SetPermissions.pl --web-group=www-data

    # Create default files if first time
    for file in "Kernel/Config.pm" "var/cron/aaa_base"  "var/cron/otrs_daemon"; do
        if [ ! -e "/opt/otrs/${file}" ] ; then
             cp  "/opt/src/otrs/${file}.dist" "/opt/otrs/${file}"
             chown otrs:www-data "/opt/otrs/${file}"
             chmod 0666 "/opt/otrs/${file}"
        fi
    done

    ### Easy OTRS Docker ###
    cd /opt/otrs
    
    sed -i -e 's/some-pass/ligero/g' /opt/otrs/Kernel/Config.pm
    
    ###### SysConfig defaults ##############
    /etc/init.d/mysql start
    while ! mysqladmin ping --silent; do sleep 1; done
    
    if [ -n "${OTRS_DEFAULT_LANGUAGE}" ]; then
            su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name DefaultLanguage --value ${OTRS_DEFAULT_LANGUAGE}" -s /bin/bash otrs;
    fi
    
    if [ -n "${OTRS_FQDN}" ]; then
        su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name FQDN --value ${OTRS_FQDN}" -s /bin/bash otrs;
    fi
    
    if [ -n "${OTRS_SYSTEM_ID}" ]; then
        su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name SystemID --value ${OTRS_SYSTEM_ID}" -s /bin/bash otrs;
    fi
    
    su -c "/opt/otrs/bin/otrs.Console.pl Maint::Config::Rebuild" -s /bin/bash otrs;
    su -c "/opt/otrs/bin/otrs.Console.pl Admin::Config::Update --no-deploy --setting-name SecureMode --value 1" -s /bin/bash otrs;

    ### OTRS admin default password:
    su -c "/opt/otrs/bin/otrs.Console.pl Admin::User::SetPassword 'root@localhost' ligero" -s /bin/bash otrs;
    
    /etc/init.d/mysql stop
    while mysqladmin ping --silent; do sleep 1; done
    ########################################

    touch "/installed"
fi

/usr/bin/supervisord
