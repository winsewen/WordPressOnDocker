## Установка  
Убедитесь что у вас установлен Docker.
Клонируем репозиторий:    
`git clone https://github.com/winsewen/WordPressOnDocker.git`  
Переходим:  
`cd WordPressOnDocker`  
Создаем Docker образ:  
`docker build -t wordpress-test .`  
Запускаем контейнер:  
`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker run -itd --name wordpress7 wordpress-test)`


