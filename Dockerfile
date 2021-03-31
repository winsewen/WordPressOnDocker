FROM ubuntu:20.04
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y nginx php-fpm php-mysqli php-xml mysql-server wget php-gd php-zip php-imagick php-mbstring php-curl sudo
RUN usermod -d /var/lib/mysql/ mysql
RUN sed -i 's/index index.html index.htm index.nginx-debian.html;/index index.php;/g' /etc/nginx/sites-enabled/default
RUN sed -i 's|#location ~ \\.php\$ {|location ~ \\.php\$ {\n\t\tfastcgi_pass unix:/var/run/php/php7.4-fpm.sock;\n\t\tinclude snippets/fastcgi-php.conf;\n\t}\n\t#location ~ \\.php\$ {|g' /etc/nginx/sites-enabled/default
RUN sed -i 's|/var/www/html|/var/www/html/wordpress|g' /etc/nginx/sites-enabled/default

COPY alertmanager-0.21.0.linux-amd64.tar.gz latest-ru_RU.tar.gz node_exporter-1.1.2.linux-amd64.tar.gz prometheus-2.25.2.linux-amd64.tar.gz grafana_7.5.2_amd64.deb /opt/
#RUN wget https://ru.wordpress.org/latest-ru_RU.tar.gz
RUN tar -xvf /opt/latest-ru_RU.tar.gz -C /var/www/html/
RUN rm /opt/latest-ru_RU.tar.gz
RUN cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
RUN sed -i 's|database_name_here|wordpress|g' /var/www/html/wordpress/wp-config.php
RUN sed -i 's|username_here|wordpress|g' /var/www/html/wordpress/wp-config.php
RUN sed -i 's|password_here|wordpress|g' /var/www/html/wordpress/wp-config.php
RUN sed -i 's|впишите сюда уникальную фразу|heKEATaTVF4uoX34zK9p9gLylskTTbCU|g' /var/www/html/wordpress/wp-config.php
RUN chown www-data:www-data /var/www/html/wordpress -R

RUN echo mysql -e \"CREATE DATABASE wordpress /*\!40100 DEFAULT CHARACTER SET utf8 */\;\" | tee -a /etc/run-once.sh
RUN echo mysql -e \"CREATE USER wordpress@localhost IDENTIFIED BY \'wordpress\'\;\" | tee -a /etc/run-once.sh
RUN echo mysql -e \"GRANT ALL PRIVILEGES ON wordpress.* TO \'wordpress\'@\'localhost\'\;\" | tee -a /etc/run-once.sh
RUN echo mysql -e \"FLUSH PRIVILEGES\;\" | tee -a /etc/run-once.sh
RUN echo sed -i \'s#/etc/run-once.sh##g\' /etc/rc.local | tee -a /etc/run-once.sh 
RUN chmod +x /etc/run-once.sh

#RUN wget https://dl.grafana.com/oss/release/grafana_7.5.2_amd64.deb
RUN apt install -y /opt/grafana_7.5.2_amd64.deb
RUN rm /opt/grafana_7.5.2_amd64.deb

#RUN wget https://github.com/prometheus/prometheus/releases/download/v2.25.2/prometheus-2.25.2.linux-amd64.tar.gz
RUN mkdir /etc/prometheus
RUN mkdir /var/lib/prometheus
RUN tar zxvf /opt/prometheus-*.linux-amd64.tar.gz -C /opt/
RUN rm /opt/prometheus-*.linux-amd64.tar.gz
RUN cp -r /opt/prometheus-*.linux-amd64/prometheus /opt/prometheus-*.linux-amd64/promtool /usr/local/bin/
RUN cp -r /opt/prometheus-*.linux-amd64/console_libraries /opt/prometheus-*.linux-amd64/consoles /opt/prometheus-*.linux-amd64/prometheus.yml /etc/prometheus
RUN useradd --no-create-home --shell /bin/false prometheus
RUN chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
RUN chown prometheus:prometheus /usr/local/bin/prometheus
RUN chown prometheus:prometheus /usr/local/bin/promtool

#RUN wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz
RUN mkdir /etc/alertmanager /var/lib/prometheus/alertmanager
RUN tar zxvf /opt/alertmanager-*.linux-amd64.tar.gz -C /opt/
RUN rm /opt/alertmanager-*.linux-amd64.tar.gz
RUN cp /opt/alertmanager-*.linux-amd64/alertmanager /opt/alertmanager-*.linux-amd64/amtool /usr/local/bin/
RUN cp /opt/alertmanager-*.linux-amd64/alertmanager.yml /etc/alertmanager
RUN useradd --no-create-home --shell /bin/false alertmanager
RUN chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/prometheus/alertmanager
RUN chown alertmanager:alertmanager /usr/local/bin/alertmanager
RUN chown alertmanager:alertmanager /usr/local/bin/amtool

#RUN wget https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz
RUN tar zxvf /opt/node_exporter-*.linux-amd64.tar.gz -C /opt
RUN rm /opt/node_exporter-*.linux-amd64.tar.gz
RUN cp /opt/node_exporter-*.linux-amd64/node_exporter /usr/local/bin/
RUN useradd --no-create-home --shell /bin/false nodeusr
RUN chown -R nodeusr:nodeusr /usr/local/bin/node_exporter

RUN sed -i 's|# - alertmanager:9093|- alertmanager:9093|g' /etc/prometheus/prometheus.yml
RUN sed -i "s|- job_name: 'prometheus'|- job_name: 'node'|g" /etc/prometheus/prometheus.yml
RUN sed -i 's|localhost:9090|localhost:9100|g' /etc/prometheus/prometheus.yml

RUN echo '#!/bin/bash' | tee /etc/rc.local
RUN echo '/etc/init.d/nginx restart' | tee -a /etc/rc.local
RUN echo '/etc/init.d/php7.4-fpm restart' | tee -a /etc/rc.local
RUN echo '/etc/init.d/mysql start' | tee -a /etc/rc.local
RUN echo '/etc/init.d/grafana-server start' | tee -a /etc/rc.local
RUN echo '/etc/run-once.sh' | tee -a /etc/rc.local
RUN echo 'sudo -u nodeusr /usr/local/bin/node_exporter &' | tee -a /etc/rc.local
RUN echo 'sudo -u alertmanager /usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/prometheus/alertmanager &' | tee -a /etc/rc.local
RUN echo 'sudo -u prometheus /usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries' | tee -a /etc/rc.local
RUN echo 'exit 0' | tee -a /etc/rc.local
RUN chmod +x /etc/rc.local

CMD /etc/rc.local
