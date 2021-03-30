## Установка  
Убедитесь, что у вас установлен Docker.  

Клонируем репозиторий:  
`git clone https://github.com/winsewen/WordPressOnDocker.git`  

Переходим:  
`cd WordPressOnDocker`  

Создаем Docker образ:  
`docker build -t wordpress-test .
`  
Запускаем контейнер:  
`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker run -itd --name wordpress7 wordpress-test)`

Результатом выполнения команды будет IP-адрес контейнера, например: 172.17.0.2  
Для того, чтобы блог был доступен по адресу blog.example.com, необходимо прописать соотвествующую DNS-запись или отредактировать файл hosts  
# Блог доступен по адресу http://172.17.0.2  
# Мониторинг http://172.17.0.2:3000  
  
## Настройка WordPress:  
Перейти по адресу http://172.17.0.2 для установки пароля администратора и далнейшей настройки  
  
## Настройка Grafana:  
Перейти по адресу http://172.17.0.2:3000  
Логин: admin  
Пароль: admin  
