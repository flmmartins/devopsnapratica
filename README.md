*Créditos para o livro DevOps Na Prática (Danilo Sato)*

Esse README contém um compilado do livro com correções. Esse repositório não é suficiente para entender o conteúdo do livro.

# Criando máquinas manualmente

$vagrant box add hashicorp/precise32

Build Vagrantfile and $vagrant up

### Configurando DB

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
    

### Configurando servidor WEB

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

### Fazendo build e deploy

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

### Configurando servidor de monitoração

Atualize a base de dados para obter versões mais atualizadas do Nagios:

	$ echo "Package: nagios* > PIN: release n=raring > Pin-priority: 990" | sudo tee /etc/apt/preferences.d/nagios
	$ echo "deb http://archive.ubuntu.com/ubuntu > raring main" | sudo tee /etc/apt/sources.list.d/raring.list
	$ sudo apt-get update
	
Instale o nagios

	$ sudo apt-get install nagios3 

Ele vai instalar o POSTFIX, um serviço de e-mail para isso vai pedir para que você selecione algumas opções. Neste momento, escolha *Internet Site* e depois *monitor.lojavirtualdevops.com.br*

Tente acessar o servidor com *http://nagiosadmin:<password>@192.168.33.14/nagios3* com o usuário nagiosadmin e sua senha.

Configure o monitoramento do servidor web e do banco de dados copiando a configuração:

	$ sudo cp /vagrant/loja_virtual.cfg /etc/nagios3/conf.d
	
	$ sudo service nagios3 reload

Com esse arquivo criamos um hostgroup chamado DB-SERVERS e WEB-SERVERS e adicionamos nossos servidores. Também adicionamos a eles o hostgroup SSH (checagens do serviço) e o Debian (coloca o logotipo e identifica nossos servidores).

Tem como checar os serviços de forma manual através da execução de scripts. Em */usr/lib/nagios/plugins*:

	$ ./check_ssh 192.168.33.12 - SSH OK - OpenSSH_5.9p1 Debian-5ubuntu1 (protocol 2.0)*
	
	$ ./check_ssh 192.168.33.11 - No route to host
	
Também existem outros scripts que podem ser executados:

	$ ./check_http -H 192.168.33.12 -p 8080
	
	$ ./check_disk -H 192.168.33.12 -w 10% -c 5%
	
Podemos extender esses comands ao criar diretivas no arquivo cfg.

**Alarmes**

O nagios pode disparar alarmes caso alguma checagem falhe. Esses alarmes podem ser por e-mail como observado em  */etc/nagios3/commands.cfg*. Também podemos definir a perioticidade dos alarmes em */etc/nagios3/conf.d/timeperiods_nagios2.cfg* e os contatos que irão receber notificações em */etc/nagios3/conf.d/contacts_nagios2.cfg*. Vamos editar informações de contato para que você receba um e-mail. Vá no último arquivo e troque *root@localhost* pelo seu endereço de e-mail.


Pode-se observar no menu de serviços que todos os monitoramentos estão OK. Vamos agora destruir o servidor de banco de dados e dar início a automação da infraestrutura:

	$ vagrant destroy db



# Criando máquinas automaticamente


## Banco de Dados


Deploy se refere a instalação e configuração de aplicação. Diferente de shell script, ferramentas de deploy automatizado possuem **idenpotência**. Não importa quanto vezes forem executados, eles só mudarão o necessário. Você declara o estado final do seu sistema e a ferramenta buscará esse estado.

### Puppet básico

Puppet utiliza um conjunto de instruções chamado *manifesto*. Vamos criar a máquina db com Puppet.

	$ vagrant up db
	$ vagrant ssh db
	
Se executar *sudo puppet apply db.pp* o pacote mysql-server vai ser instalado. O pacote é instalado de acordo com o provider indicado. Se executar:

	$ sudo puppet describe package
	
Vai mostrar os detalhes da diretiva package, bem como seus providers (yum, apt e etc). 

Agora vamos colocar o puppet no Vagrant. Crie um diretório manifests no mesmo lugar aonde está seu Vagrantfile. Vamos editar o arquivo para colocar o arquivo */etc/mysql/conf.d/allow_external.cnf*. O puppet só altera o arquivo se ele for modificado de acordo com o MD5.

### Usando templates

Ao invés de adicionarmos uma linha a um arquivo podemos usar um template que é copiado para a máquina que está sendo provisionada.

Também adicionamos uma diretiva **Service** que faz com que o serviço enteja sempre rodando (**ensure**), que esteja habilitado ao iniciar a máquina (**enable**), que consiga entender o comando restart e status do próprio service (**hasstatus, hasrestart**). Ele também tem uma dependência com o pacote do mysql como mostrado com a diretiva **require**.

A diretiva **notify** faz com que toda vez que o arquivo seja alterado, o serviço reinicie.

A diretiva **unless** especifica que, caso o comando seja executado com sucesso, o comando principal ***não*** irá executar.

A diretiva **onlyif** especifica que, caso o comando seja executado com sucesso, o comando principal ***irá*** executar.

Ambos os comandos **onlyif e unless** garantem a idempotência da diretiva **command**


## Web

### Usando templates com variáveis

Vamos criar uma máquina web2 e fazer o deploy nela primeiramente. Adicionamos umas linhas no Vagrant file e o arquivo web.pp. Ele vai instalar os pacotes e copiar alguns arquivos do tomcat7 necessários.

Variáveis no puppet são declaradas com cifrão:  **$variavel**

Você pode declarar variáveis e atribuir um valor a elas no manifesto. Elas podem ser colocadas em um arquivo template ERB e quando o puppet processar, vai substituir a variável no arquivo pelo valor declarado no manifesto. Você deve colocá-las no arquivo da seguinte forma: *<%= var %>*

Não esqueça de colocar a função **template** no arquivo ao qual vc quer carregar as variáveis.

# Refatorando código Puppet

### Usando classes

Classes, no Puppet, são um conjunto de recursos. Não é o mesmo que classes em programação.

Para declarar classe use:

**class <nome> {}**

Dentro de uma classe devemos ter recursos que são executados somente uma vez e não podem ser reaproveitados.

Para usar a classe vc deve utilizar:

**include <nome da classe>** ou **class ( "nome da classe>": ... )**


