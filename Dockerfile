# --- Base Image
FROM rockylinux:9.3

# --- Expose Ports
EXPOSE 80 443

# --- Environment Variables
ENV \
    DB_NAME=cacti \
    DB_USER=cactiuser \
    DB_PASS=cactipassword \
    DB_HOST=localhost \
    DB_PORT=3306 \
    RDB_NAME=cacti \
    RDB_USER=cactiuser \
    RDB_PASS=cactipassword \
    RDB_HOST=localhost \
    RDB_PORT=3306 \
    CACTI_URL_PATH=cacti \
    BACKUP_RETENTION=7 \
    BACKUP_TIME=0 \
    REMOTE_POLLER=0 \
    INITIALIZE_DB=0 \
    TZ=UTC \
    PHP_MEMORY_LIMIT=800M \
    PHP_MAX_EXECUTION_TIME=60 \
    PHP_SNMP=1

# --- Default Command
CMD ["/start.sh"]

# --- Start Script
COPY start.sh /start.sh

# --- Get Latest Version using curl
RUN mkdir -p /cacti_install && \
    yum install -y curl --allowerasing && \
    curl -L http://files.cacti.net/spine/cacti-spine-latest.tar.gz -o /cacti_install/cacti-spine-latest.tar.gz && \
    curl -L https://files.cacti.net/cacti/linux/cacti-latest.tar.gz -o /cacti_install/cacti-latest.tar.gz

# --- Supporting Files
# COPY cacti /cacti_install

# --- Service Configurations
COPY configs /template_configs
COPY configs/crontab /etc/crontab

# --- Settings/Extras
COPY plugins /cacti_install/plugins
COPY templates /templates
COPY settings /settings

# --- Scripts
COPY upgrade.sh /upgrade.sh
COPY restore.sh /restore.sh
COPY backup.sh /backup.sh

# --- Update OS, Install EPEL, PHP Extensions, Cacti/Spine Requirements, Other/Requests
RUN \
    yum update -y && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    yum install -y dnf-plugins-core && \
    yum config-manager --set-enabled crb && \
    yum install -y iputils && \
    yum install -y \
    php php-xml php-session php-sockets php-ldap php-gd \
    php-json php-mysqlnd php-gmp php-mbstring php-posix \
    php-snmp php-intl php-common php-cli php-devel php-pear \
    php-pdo && \
    yum install -y \
    rrdtool net-snmp net-snmp-utils cronie mariadb autoconf \
    bison openssl openldap mod_ssl net-snmp-libs automake \
    gcc gzip libtool make net-snmp-devel dos2unix m4 which \
    openssl-devel mariadb-devel sendmail wget help2man perl-libwww-perl && \
    yum clean all && \
    rm -rf /var/cache/yum/* && \
    chmod +x /upgrade.sh && \
    chmod +x /restore.sh && \
    chmod +x /backup.sh && \
    chmod u+s /usr/bin/ping && \
    chmod g+s /usr/bin/ping && \
    mkdir /backups && \
    mkdir /cacti && \
    mkdir /spine && \
    chmod 0644 /etc/crontab && \
    echo "ServerName localhost" > /etc/httpd/conf.d/fqdn.conf && \
    /usr/libexec/httpd-ssl-gencerts

