*Créditos para o livro DevOps Na Prática (Danilo Sato)*

Esse README contém um compilado do livro com correções. Esse repositório não é suficiente para entender o conteúdo do livro.

### Criando máquinas

$vagrant box add hashicorp/precise32

Build Vagrantfile and $vagrant up

### Configurando DB manualmente

vagrant ssh db

    $sudo apt-get update
    
    $sudo apt-get install mysql-server (Choose password for db)
    
    $sudo apt-get install vim
    
Copia allow_external.cnf para /etc/mysql/conf.d/allow_external.cnf
    
    $sudo service mysql restart
    
Cria o banco loja_schema: 

    $mysqladmin -u root -p create loja_schema
    
    $mysql -u root -p -e "SHOW DATABASES;"
    
Deleta a conta anônima do MYSQL

    $mysql -u root -p -e "DELETE FROM mysql.user WHERE user=''; FLUSH PRIVILEGES"

Cria conta para manipulação do banco
    
    $mysql -u root -p -e "CREATE USER 'loja'@'localhost'"
    
    $mysql -u root -p -e "GRANT ALL PRIVILEGES ON loja_schema.* TO 'loja'@'localhost'"
    
    $mysql -u loja -p loja_schema -e "select database(), user()"
    

### Configurando servidor WEB manualmente

vagrant ssh web
    
    $sudo apt-get update
    
    $sudo apt-get install tomcat7 mysql-client
    
Acesse 192.168.33.12:8080 e veja se está tudo funcionando
    
Configurar certificado SSL:

	$ cd /var/lib/tomcat7/conf
    
    $sudo keytool -genkey -alias tomcat -keyalg RSA -keystore .keystore
    
Copia tomcat.xml para /var/lib/tomcat7/conf/server.xml
    
Copy tomcat7 to /etc/default/tomcat7
    
Reinicie o Tomcat 7

	$sudo service tomcat7 restart

Acesse https://192.168.33.12:8443 e veja se está tudo funcionando

### Fazendo build e deploy manualmente

Na mesma máquina do Web.

vagrant ssh web

	$sudo apt-get install git maven2 efault-jdk
	
Copie o código e realizar o build:

	$git clone https://github.com/dtsato/loja-virtual-devops.git
	
	$cd loja-virtual-devops
	
	$export MAVEN_OPTS=-Xmx256m
	
	$mvn install
	
É necessário configurar o bind da aplicação com o banco. Copie context.xml para
/var/lib/tomcat7/conf/context.xml.

Faça o deploy copiando o artefato para o tomcat

	$cd loja-virtual-devops
	
	$sudo cp combined/target/devopsnapratica.war /var/lib/tomcat7/webapps
	
Veja o log do deploy

	$tail -f /var/lib/tomcat7/logs/catalina.out
	
Acesse a aplicação http://192.168.33.12:8080/devopsnapratica/ e a página de admin http://192.168.33.12:8080/devopsnapratica/admin/






