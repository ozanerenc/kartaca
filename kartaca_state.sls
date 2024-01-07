{% set os_family = grains['os_family'] %}
{% set os_major = grains['osmajorrelease'] %}

{% set user_info = salt['pillar.get']('common:user_info', {}) %}
{% set group_info = salt['pillar.get']('common:group_info', {}) %}
{% set sudo_user = salt['pillar.get']('common:sudo_user', '') %}
{% set timezone = salt['pillar.get']('common:timezone', 'UTC') %}
{% set ip_block = salt['pillar.get']('common:ip_block', '192.168.168.128/28') %}
{% set host_entry = salt['pillar.get']('common:host_entry', 'kartaca.local') %}
{% set mysql_root_password = salt['pillar.get']('mysql:root_password', 'root_password') %}
{% set mysql_db_name = salt['pillar.get']('mysql:db_name', 'wordpress') %}
{% set mysql_user = salt['pillar.get']('mysql:user', 'wordpress_user') %}
{% set mysql_user_password = salt['pillar.get']('mysql:user_password', 'wordpress_password') %}
    
{% set kartaca_pillar = salt['pillar.get']('kartaca_pillar', {}) %}

{% set user_info = kartaca_pillar.get('common:user_info', {}) %}
{% set sudo_user = kartaca_pillar.get('common:sudo_user', '') %}
{% set timezone = kartaca_pillar.get('common:timezone', 'UTC') %}
{% set ip_block = kartaca_pillar.get('common:ip_block', '192.168.168.128/28') %}
{% set host_entry = kartaca_pillar.get('common:host_entry', 'kartaca.local') %}

{% set ssl_cert_path = kartaca_pillar.get('nginx:ssl_cert_path', '/etc/nginx/ssl/self-signed.crt') %}
{% set ssl_key_path = kartaca_pillar.get('nginx:ssl_key_path', '/etc/nginx/ssl/self-signed.key') %}
{% set nginx_conf_path = kartaca_pillar.get('nginx:nginx_conf_path', '/etc/nginx/nginx.conf') %}
{% set nginx_logrotate_path = kartaca_pillar.get('nginx:nginx_logrotate_path', '/etc/logrotate.d/nginx') %}
{% set wordpress_dir = kartaca_pillar.get('wordpress_dir', '/var/www/wordpress2023') %}
{% set nginx_conf_source = kartaca_pillar.get('nginx:nginx_conf_source', 'salt://nginx_wordpress_setup/files/nginx.conf') %}
{% set nginx_php_conf_source = kartaca_pillar.get('nginx:nginx_php_conf_source', 'salt://nginx_wordpress_setup/files/nginx_php.conf') %}
{% set wp_config_path = kartaca_pillar.get('wp_config_path', '/var/www/wordpress2023/wp-config.php') %}

{% set mysql_root_password = kartaca_pillar.get('mysql:root_password', 'root_password') %}
{% set wordpress_db_name = kartaca_pillar.get('mysql:wordpress_db_name', 'wordpress_db') %}
{% set wordpress_db_user = kartaca_pillar.get('mysql:wordpress_db_user', 'wordpress_user') %}
{% set wordpress_db_password = kartaca_pillar.get('mysql:wordpress_db_password', 'wordpress_password') %}
{% set mysql_dump_path = kartaca_pillar.get('mysql:mysql_dump_path', '/backup/mysql_dump.sql') %}


{% if os_family == 'Debian' %}
  {% if os_major == 9 %}
    create_group:
        group.present:
            - name: {{ group_info.name }}
            - gid: {{ group_info.gid }}
            - system: True

    create_user:
        user.present:
            - name: {{ user_info.name }}
            - uid: {{ user_info.uid }}
            - gid: {{ user_info.gid }}
            - home: {{ user_info.home }}
            - shell: {{ user_info.shell }}
            - password: {{ user_info.password }}
            - groups: {{ user_info.groups | default([]) }}

    grant_sudo_privileges:
        cmd.run:
            - name: echo '{{ sudo_user }} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/{{ sudo_user }}

    set_system_timezone:
        timezone.system:
            - name: {{ timezone }}

    enable_ip_forwarding:
        sysctl.present:
            - name: net.ipv4.ip_forward
            - value: 1
            - config: /etc/sysctl.conf

    install_required_packages:
        pkg.installed:
            - names:
            - htop
            - tcptraceroute
            - ping
            - dnsutils
            - iostat
            - mtr

    install_hashicorp_repo:
        pkgrepo.managed:
            - name: hashicorp
            - file: /etc/apt/sources.list.d/hashicorp.list
            - humanname: HashiCorp Official Repository
            - baseurl: https://apt.releases.hashicorp.com
            - gpgcheck: 1
            - gpgkey: https://apt.releases.hashicorp.com/gpg

    install_terraform:
        pkg.installed:
            - names:
            - terraform=1.6.4

    configure_hosts_file:
        file.blockreplace:
            - name: /etc/hosts
            - marker_start: '# Salt managed section'
            - marker_end: '# End Salt managed section'
            - content: |
                {% for ip in range(129, 144) %}
                {{ ip }} {{ host_entry }}
                {% endfor %}
            - append_if_not_found: True
            - backup: '.bak'

  {% elif os_major == 22 %}


    install_mysql:
        pkg.installed:
            - names:
            - mysql-server

    configure_mysql:
        cmd.run:
            - name: mysql_secure_installation
            - require:
            - pkg: install_mysql
            - unless: mysql -u root -e "SELECT User FROM mysql.user WHERE User='root' AND Host='localhost'" | grep -q root

    start_mysql:
        service.running:
            - name: mysql
            - enable: True
            - watch:
            - cmd: configure_mysql

    create_mysql_db:
        cmd.run:
            - name: mysql -u root -e "CREATE DATABASE IF NOT EXISTS {{ mysql_db_name }};"
            - require:
            - service: start_mysql

    create_mysql_user:
        cmd.run:
            - name: mysql -u root -e "CREATE USER IF NOT EXISTS '{{ mysql_user }}'@'localhost' IDENTIFIED BY '{{ mysql_user_password }}';"
            - require:
            - cmd: create_mysql_db

    grant_mysql_privileges:
        cmd.run:
            - name: mysql -u root -e "GRANT ALL PRIVILEGES ON {{ mysql_db_name }}.* TO '{{ mysql_user }}'@'localhost';"
            - require:
            - cmd: create_mysql_user
  {% endif %}


{% elif os_family == 'RedHat' %}
  {% if 'CentOS' in grains['os'] and os_major == 9 %}
    create_group:
        group.present:
            - name: {{ group_info.name }}
            - gid: {{ group_info.gid }}
            - system: True

    create_user:
        user.present:
            - name: {{ user_info.name }}
            - uid: {{ user_info.uid }}
            - gid: {{ user_info.gid }}
            - home: {{ user_info.home }}
            - shell: {{ user_info.shell }}
            - password: {{ user_info.password }}
            - groups: {{ user_info.groups | default([]) }}

    grant_sudo_privileges:
        cmd.run:
            - name: echo '{{ sudo_user }} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/{{ sudo_user }}

    set_system_timezone:
        timezone.system:
            - name: {{ timezone }}

    enable_ip_forwarding:
        sysctl.present:
            - name: net.ipv4.ip_forward
            - value: 1
            - config: /etc/sysctl.conf

    install_required_packages:
        pkg.installed:
            - names:
            - htop
            - tcptraceroute
            - ping
            - dnsutils
            - iostat
            - mtr

    install_hashicorp_repo:
        pkgrepo.managed:
            - name: hashicorp
            - file: /etc/apt/sources.list.d/hashicorp.list
            - humanname: HashiCorp Official Repository
            - baseurl: https://apt.releases.hashicorp.com
            - gpgcheck: 1
            - gpgkey: https://apt.releases.hashicorp.com/gpg

    install_terraform:
        pkg.installed:
            - names:
            - terraform=1.6.4

    configure_hosts_file:
        file.blockreplace:
            - name: /etc/hosts
            - marker_start: '# Salt managed section'
            - marker_end: '# End Salt managed section'
            - content: |
                {% for ip in range(129, 144) %}
                {{ ip }} {{ host_entry }}
                {% endfor %}
            - append_if_not_found: True
            - backup: '.bak'
    {% endfor %}


    install_nginx:
        pkg.installed:
            - name: nginx

    configure_nginx_autostart:
        service.running:
            - name: nginx
            - enable: True
            - reload: True
            - watch:
            - file: {{ nginx_conf_path }}

    install_php_packages:
        pkg.installed:
            - names:
            - php-fpm
            - php-mysql
            - php-gd
            - php-xml
            - php-mbstring
            - php-json
            - php-curl
            - php-xmlrpc
            - php-dom
            - php-exif
            - php-fileinfo
            - php-hash
            - php-imagick
            - php-json
            - php-mysqli
            - php-mbstring
            - php-openssl
            - php-pcre
            - php-sodium
            - php-xml
            - php-zip

    download_wordpress:
        cmd.run:
            - name: 'curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz'
            - unless: 'test -f /tmp/wordpress.tar.gz'

    extract_wordpress:
        cmd.run:
            - name: 'tar -C {{ wordpress_dir }} -xzf /tmp/wordpress.tar.gz --strip-components=1'
            - unless: 'test -f {{ wp_config_path }}'

    create_mysql_db:
        mysql_database.present:
            - name: {{ wordpress_db_name }}
            - require:
              - user: create_mysql_user

    create_mysql_user:
        mysql_user.present:
            - name: {{ wordpress_db_user }}
            - password: {{ wordpress_db_password }}
            - host: localhost
            - require:
              - mysql_database: create_mysql_db

    configure_wp_config:
        cmd.run:
            - name: |
                echo "<?php
                define('DB_NAME', '{{ wordpress_db_name }}');
                define('DB_USER', '{{ wordpress_db_user }}');
                define('DB_PASSWORD', '{{ wordpress_db_password }}');
                define('DB_HOST', 'localhost');
                define('DB_CHARSET', 'utf8mb4');
                define('DB_COLLATE', '');
                $(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
                " > {{ wp_config_path }}
            - unless: 'test -f {{ wp_config_path }}'
            - require:
                - mysql_user: create_mysql_user

    configure_nginx:
        file.managed:
            - name: {{ nginx_conf_path }}
            - source: {{ nginx_conf_source }}
            - template: jinja
            - require:
            - pkg: install_nginx
            - watch_in:
                - service: nginx

    configure_nginx_php:
        file.managed:
            - name: /etc/nginx/conf.d/php.conf
            - source: {{ nginx_php_conf_source }}
            - template: jinja
            - watch_in:
                - service: nginx

    configure_wp_config_reload:
        cmd.run:
            - name: 'systemctl reload nginx'
            - watch:
                - file: {{ nginx_conf_path }}

    configure_logrotate:
        file.managed:
            - name: {{ nginx_logrotate_path }}
            - contents: |
                /var/log/nginx/*.log {
                    hourly
                    rotate 10
                    compress
                    delaycompress
                    missingok
                    notifempty
                    create 0640 www-data adm
                    sharedscripts
                    postrotate
                        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
                    endscript
                }
            - watch_in:
              - service: nginx
  {% endif %}
{% endif %}