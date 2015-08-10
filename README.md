1. vagrant box add hashicorp/precise32
2. Build Vagrantfile
3. vagrant ssh db
    3.1 $sudo apt-get update
    3.2 $sudo apt-get install mysql-server
    3.3 Password for db
    3.4 $sudo apt-get install vim
    3.5 copy allow_external.cnf to /etc/mysql/conf.d/allow_external.cnf
    3.6 $sudo service mysql restart
    3.7 Create database loja_schema: $mysqladmin -u root -p create loja_schema
    3.8 $mysql -u root -p -e "SHOW DATABASES;"
    3.9 $mysql -u root -p -e "DELETE FROM mysql.user WHERE user=''; FLUSH PRIVILEGES"
    3.10 $mysql -u root -p -e "CREATE USER 'loja'@'localhost'"
    3.11 $mysql -u root -p -e "GRANT ALL PRIVILEGES ON loja_schema.* TO 'loja'@'localhost'"
    3.12 mysql -u loja -p loja_schema -e "select database(), user()"

4. vagrant ssh web
    4.1 $sudo apt-get update
    4.2 $sudo apt-get install tomcat7 mysql-client
    4.3 Acesse 192.168.33.12:8080
    4.4 Configurar certificado SSL: #cd /var/lib/tomcat7/conf
    4.5 $sudo keytool -genkey -alias tomcat -keyalg RSA -keystore .keystore
    4.6 $sudo apt-get install vim
    4.7 Copy tomcat.xml to /var/lib/tomcat7/conf/server.xml
    4.8 Copy tomcat7 to /etc/default/tomcat7
    4.9 $sudo service tomcat7 restart
    4.10 Acesse https://192.168.33.12:8443
