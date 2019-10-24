---
resolv_config:
  - nameserver:
      - "192.168.1.1"
      - "9.9.9.9"
  - search:
      - "atelierasap.com"

# Nextcloud
mysql_root_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          37386239373061316537333231306466323235306133636132313139356163343334343334396237
          3763656432653035383966393239633932366532613832640a626238363937326563343538346161
          39656330316665643562343233363630626365373463613061323534393061396364633763623834
          3061333966316565330a366635663737356231313165333239363334326461346431383836343639
          30313134376537356663646437393337336631646537633033633663373937353835373066633239
          6161346539633737303039653435633234356637393236313035
nextcloud_dbpassword: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          61636539653362613765303138643566656666663761623535316234343366633163653536636361
          3166666335336130626338663363623439643766663638360a383666323536346531323261333164
          35323434313539353832303136333938656231326365356165653732646465653564643562393166
          6466326638323264660a623461636338363930613633613661313665666130353636326130633130
          63653634663662363336376532653834646463616361343238313837646161393263386336326366
          6532303235383238356361376564343236353839356530316536
nextcloud_dbuser: "nextcloud"
nextcloud_dbname: "nextcloud"
nextcloud_dbhost: "localhost"
nextcloud_passwordsalt: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          35343434323231353736376430656630333730613837636537383937643264643335333732336461
          6565373563393332643662316639363038356265313865390a346238323135336535666363633935
          30623866343962396161326665666462303465363337353634633734653666313166663437343137
          3139663935386666360a613764633233303365656162313163363238613132643534643032306436
          31666135656637306566623438316561336563353738346233363337633730383532
nextcloud_secret: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          30646162346337363630393036386336353864666636663130386136666235363638616261303835
          6466386336656637306530306237333363393663306331620a633462663261383835316135363035
          65336137623537626530616232616139613931356336346539306465316435386661373137323036
          6534656538386665650a643838313564613330303264613939613135396437396433616135326430
          65383334373139633666383839373539376235643135616564306238663139623866316433343333
          61313766383338646134383433303631363337343532313835643663366238373162323464663936
          373665373465373534646535633066636530
nextcloud_instanceid: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          35613431313736373334653461616234363863376332616562616532343335313062656333613066
          6636396338363763383736616337353535666230323134660a376164666439646536363262396532
          39653437376637313232383331323366616532626633313538626433363233303831636339356631
          3737313864333766660a306338643964356233653162356635363333663837303961396435393165
          3536
nextcloud_deploy_t: "/var/www/data.atelierasap.com"
nextcloud_domain: "data.atelierasap.com"
nextcloud_admin_user: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          63623164343732323335653433313763626466623336373435356334643039336436636230666239
          3936643134346362306337633165653864393764386437650a336534386236643661316338376336
          38633762323739373163393532333938306462653338333833333536633439653166626631663838
          3332396435623535640a666163356164363265656561636465646631323732613330656335626333
          3830
nextcloud_admin_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          65616630363834656538383238313838336133306362346534303137623034366261323936643838
          6537363932373331636436333431336566336130356661640a393038633236346235393463336633
          32316537336664646663333831303866326161366334383932373363373331323933633161396465
          3765356439386630330a386137626436383137343638643363643866313731316234643966333739
          38653935643466316334303032363135663462356434396135313337653534643539

# MySQL
mysql_packages:
  - mariadb-client
  - mariadb-server
  - python-mysqldb
mysql_databases:
  - name: nextcloud
    encoding: utf8mb4
    collation: utf8mb4_general_ci
mysql_users:
  - name: nextcloud
    host: "localhost"
    password: "{{ nextcloud_dbpassword }}"
    priv: "nextcloud.*:ALL"
    state: present

# Certbot
certbot_certs:
  - email: "{{ my_email }}"
    path: "/var/www/certbot"
    state: "present"
    post_hook: "/bin/systemctl restart nginx.service"
    domains:
      - data.atelierasap.com

# Nginx
nginx_vhosts:
  - server_names:
      - data.atelierasap.com
    state: "present"
    root: /var/www/data.atelierasap.com/current
    index: index.php index.html
    extra_parameters: |
      add_header X-Robots-Tag none;
      add_header X-Download-Options noopen;
      add_header X-Permitted-Cross-Domain-Policies none;
      add_header Referrer-Policy no-referrer;
      fastcgi_hide_header X-Powered-By;
      location = /.well-known/carddav {
        return 301 $scheme://$host/remote.php/dav;
      }
      location = /.well-known/caldav {
        return 301 $scheme://$host/remote.php/dav;
      }
      client_max_body_size 512M;
      fastcgi_buffers 64 4K;
      location / {
        rewrite ^ /index.php$request_uri;
      }
      location ~ ^\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
      }
      location ~ ^\/(?:autotest|occ|issue|indie|db_|console) {
        deny all;
      }
      location ~ ^\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:$|\/) {
        fastcgi_split_path_info ^(.+?\.php)(\/.*|)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS on;
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
      }
      location ~ ^\/(?:updater|oc[ms]-provider)(?:$|\/) {
        try_files $uri/ =404;
        index index.php;
      }
      location ~ \.(?:css|js|woff2?|svg|gif)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;
        access_log off;
      }
      location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
        try_files $uri /index.php$request_uri;
        access_log off;
      }
nginx_user: nginx

# PHP
php_default_version_debian: "7.2"
php_enable_webserver: false
php_enable_php_fpm: true
php_enable_apc: false
php_use_managed_ini: true
php_fpm_listen: "127.0.0.1:9000"
php_fpm_listen_allowed_clients: "127.0.0.1"
php_fpm_pm_max_children: 50
php_fpm_pm_start_servers: 5
php_fpm_pm_min_spare_servers: 5
php_fpm_pm_max_spare_servers: 5
php_fpm_pool_user: "nginx"
php_fpm_pool_group: "nginx"
php_memory_limit: "521M"
php_max_execution_time: "60"
php_max_input_time: "60"
php_max_input_vars: "1000"
php_realpath_cache_size: "32K"
php_file_uploads: "On"
php_upload_max_filesize: "512M"
php_max_file_uploads: "20"
php_post_max_size: "512M"
php_date_timezone: "Europe/Paris"
php_allow_url_fopen: "On"
php_sendmail_path: "/usr/sbin/sendmail -t -i"
php_output_buffering: "4096"
php_short_open_tag: false
php_error_reporting: "E_ALL & ~E_DEPRECATED & ~E_STRICT"
php_display_errors: "Off"
php_display_startup_errors: "On"
php_expose_php: "On"
php_session_cookie_lifetime: 0
php_session_gc_probability: 1
php_session_gc_divisor: 1000
php_session_gc_maxlifetime: 1440
php_session_save_handler: files
php_session_save_path: ''
php_disable_functions: []
php_opcache_zend_extension: "opcache.so"
php_opcache_enable: "1"
php_opcache_enable_cli: "0"
php_opcache_memory_consumption: "128"
php_opcache_interned_strings_buffer: "8"
php_opcache_max_accelerated_files: "10000"
php_opcache_max_wasted_percentage: "5"
php_opcache_validate_timestamps: "0"
php_opcache_revalidate_path: "0"
php_opcache_revalidate_freq: "1"
php_opcache_max_file_size: "0"
