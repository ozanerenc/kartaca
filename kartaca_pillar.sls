common:
  user_info:
    name: kartaca
    user_id: 2023
    home_dir: /home/krt
    shell: /bin/bash
    password: kartaca2023
  group_info:
    name: kartaca
    gid: 2023
  sudo_user: kartaca
  timezone: Istanbul
  ip_block: 192.168.168.128/28
  host_entry: kartaca.local

nginx:
  ssl_cert_path: /etc/nginx/ssl/self-signed.crt
  ssl_key_path: /etc/nginx/ssl/self-signed.key
  nginx_conf_path: /etc/nginx/nginx.conf
  nginx_logrotate_path: /etc/logrotate.d/nginx
  wordpress_dir: /var/www/wordpress2023
  nginx_conf_source: salt://nginx_wordpress_setup/files/nginx.conf
  nginx_php_conf_source: salt://nginx_wordpress_setup/files/nginx_php.conf
  wp_config_path: /var/www/wordpress2023/wp-config.php

mysql:
  mysql_root_password: root_password
  wordpress_db_name: wordpress_db
  wordpress_db_user: wordpress_user
  wordpress_db_password: wordpress_password
  mysql_dump_path: /backup/mysql_dump.sql
