## Baris Ertas
## 21702126


#   CTIS-486 Installation Project
##   Jenkins CI/CD Pipeline

## Credentials

The document is based on Jenkins CI/CD Pipeline along with Docker and Golang in Ubuntu environment.

## Jenkins Configurationip 

Jenkins requires Java in order to run. In this this case, OpenJDK is used and then Jenkins is installed. Following steps are executed:

*  # Java

1. Updating repositories:
```
sudo apt update
```
2. Install it:
```
sudo apt install openjdk-11-jdk
```
3. Confirm and check the installation:
```
sudo apt install openjdk-11-jdk
java -version
```
The result must be as following output segment:
```
java version "11.0.6" 2020-01-14 LTS
Java(TM) SE Runtime Environment 18.9 (build 11.0.6+8-LTS)
Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11.0.6+8-LTS, mixed mode)
```

*  # Jenkins

In `Debian/Ubuntu` based distribution the steps for Jenkins installation are as follows:

1. Add repository key to the system
```
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
```
2. Append the Debian package repository to the `sources.list`
```
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
```
3. Run `update` so that `apt` can use the new repository.
```
sudo apt-get update
```
4. Install Jenkins
```
sudo apt-get install jenkins
```
5. Check the status and if its not started automatically then start the service.
```
sudo systemctl status jenkins
sudo systemctl start jenkins
``` 
* # Enabling SSL on Jenkins

1. Default environment variables for `JAVA_HOME` and `JENKINS_HOME` are as follows:
```
jenkins: /var/lib/jenkins
java   : /usr/lib/jvm/java-11-openjdk-amd64/
```
To make the process easy these env. variables must be set. Hence, following steps should be executed:
```
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
export JENKINS_HOME=/var/lib/jenkins/
```

2. Create a directory called `keystore` in `$JENKINS_HOME` and then assign both user and group privileges of the directory to `jenkins` user.
```
mkdir $JENKINS_HOME/.keystore
chown -R jenkins:jenkins $JENKINS_HOME/.keystore
```

3. Creating self-signed SSL certificate

* The utilized tools in this step are `OpenSSL` and `Keytool`. `OpenSSL` comes by default with Ubuntu and `Keytool` as well with `Java` installation.

    * Open the `openssl` conf file: `sudo nano /etc/ssl/openssl.conf`
    * Add the following lines at the end of file.
      ```
      [ subject_alt_name ]
      subjectAltName = DNS:<preferred_domain_name>
      ``` 
    * Cd to `$JENKINS_HOME/.keystore` before executing the following steps.
    * To create public and private key pair execute the following based on your information. 
      ```
      sudo openssl req -x509 -nodes -newkey rsa:2048 -config /etc/ssl/  openssl.cnf -extensions subject_alt_name -keyout private.key -out   self_signed.pem -subj '/C=NG/ST=Lagos/L=Victoria_Island/  O=Your_Organization/OU=Your_department/CN=www.yourdomain.com/ emailAddress=youremail@yourdomain.com' -days 365
      ```
   * Export the public key which is `self_signed.pem` to `PKCS12` format. It will ask a password which you shouldn't forget because it will be required later.   
      ```
      sudo openssl pkcs12 -export -keypbe PBE-SHA1-3DES -certpbe  PBE-SHA1-3DES -export -in self_signed.pem -inkey private.key -name   myalias -out jkeystore.p12
      ```
    
  * Convert the `.p12` file to a `.jks` format.
    ```
    sudo keytool -importkeystore -destkeystore jkeystore.jks -deststoretype PKCS12 -srcstoretype PKCS12 -srckeystore jkeystore.p12
    ```
  * Generate a certificate file from the `.jks` file.
    ```
    sudo keytool -export -keystore jkeystore.jks -alias myalias -file self-signed.crt
    ```
  
  * Restart `jenkins`
    ```
    sudo service jenkins restart
    ```
4. Editing the Jenkins configuration file.

    * Open configuration file of Jenkins.
      ```
      sudo nano /etc/default/jenkins
      ``` 
    * Add the following 2 lines at the end of file.
      ```
      JAVA_ARGS="Djavax.net.ssl.trustStore=$JAVA_HOME/jre/lib/security/cacerts -Djavax.net.ssl.trustStorePassword=changeit"

      JAVA_ARGS="-Xmx2048m -Djava.awt.headless=true"
      ```
    * Disable `HTTP_PORT` by setting to `-1` instead of `8080`.

      ```
      JENKINS_ARGS="--webroot=/var/cache/$NAME/war --httpPort=$HTTP_PORT --httpsPort=8443 --httpsKeyStore=$JENKINS_HOME/.keystore/jkeystore.jks --httpsKeyStorePassword=<the_password_used_before>"
      ```
    * Start the service again.
      ```
      sudo systemctl restart jenkins
      ```
  
  5. Navigate to the browser and type `https://{server_ip}:8443`. Since the certificate is self-signed, ignore the error and proceed to the web page which can be done typing `thisisunsafe` and it will bypass the error.


* # Accepting connections on port `443` only. 

By default HTTPS connections use TCP port 443. In this case, Jenkins dashboard listens the port `8443`. Hence, it is incovenient to listen `8443`. A listener should be created for Jenkins dashboard for port `443`. Different solutions can be applied like using a load balancer that would take care of routing `443` to `8443` or using `nginx` or `apache` web servers using redirects. In this example, `iptables` is used to take care of port forwarding. To enable port `443` on Jenkins, the followings steps are executed by utilizing `iptables` command:

  1. Add the ports
  ```
  sudo iptables -I INPUT 1 -p tcp --dport 8443 -j ACCEPT
  sudo iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
  ```
  2. Then execute the following command for port forwarding.
  ```
  sudo iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
  ```

  Then accessing the Jenkins server will be avaliable without explicitliy writing the port `8443`. Just type `https://{server_ip}/`.

* # Installing Docker

Since the image will be pushed to `Docker Hub`, Docker is required. Install it by following below steps. 

1. Add Docker's official GPG key. 
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```
2. Set up stable repository. 

```
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
3. Install Docker Engine
```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

* # Pipeline for Golang Application

* Before we start to Jenkins pipeline, Golang should be installed. For Debian/Ubuntu based systems here are the steps:

1. Find a release of Go version and then use curl to retrieve the tarball. 
```
curl -OL https://golang.org/dl/go1.16.6.linux-amd64.tar.gz
```
2. Extract the archive.
```
sudo tar -C /usr/local -xzf go1.16.6.linux-amd64.tar.gz
```
3. Add the following line inside `~/.profile`.
```
export PATH=$PATH:/usr/local/go/bin
```
4. Execute the following command to apply changes immediately.
```
source ~/.profile
```

* # Configurations for Jenkins Pipeline, Docker and Go

* Log in to jenkins server and it will as a password where you will `Unlock` Jenkins. Copy the path run the following command and then copy the output, paste into the `administrator password` field. Then install the suggested plugins.
  ```
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```

* Create an admin user providing your own information and proceed. 
* You can bypass the instance configuration.

* Before we move on to application's files. Log in to Jenkins and install the Go plugin via `Manage Jenkins` > `Manage Plugins` > Search for `Go Plugin` under the Available tab. Apply the same thing for `Docker` and `Docker Pipeline` plugins. 

    *  The image will be pushed to `Docker Hub`. Hence, the credentials should be provided inside Jenkins dashboard. From `Manage Jenkins` go to `Manage Credentials` > `Domains(global)` > `Add Credentials`. Add your `Docker Hub` name and password, give an meaningful id which will be used in Jenkinsfile and write a simple description. 

        `Kind`: Username with password

        `Scope`: Global

    * Add `jenkins` user to `docker` group so that, in the `creating image` stage jenkins can make use of `docker` by executing the following line:
      ```
      sudo usermod -a -G docker jenkins
      ```

* The Go version that is going to be used should be added inside `Global Tool Configuration` (in `Manage Jenkins`). The name should be given carefully since it will be referred later in `Jenkinsfile`.

* To start Jenkins pipeline. Click `New Item` and then select `Pipeline`. 
In the opening screen come to select the `Advanced Project Options` and select `Pipeline Script from SCM` option under `Definition` menu. Then select `Git` option under `SCM`. Paste the url of the repository inside box and write the which specific branch will be used for the pipeline. `Jenkinsfile` we define later will be automatically read by the server while executing the stages.


* Requirements:

    * A simple application written in Go and its test
    * Dockerfile
    * Jenkinsfile

    `main.go`. Simple HTTP server and a single endpoint `/` where returns `Hello World!`.
    ```
    package main

    import (
    	"log"
    	"net/http"
    )

    type Server struct{}

    func (s *Server) ServeHTTP(w http.    ResponseWriter, r *http.Request) {
    	w.WriteHeader(http.StatusOK)
    	w.Header().Set("Content-Type",    "application/json")
    	w.Write([]byte(`{"message": "Hello    World!"}`))
    }

    func main() {
    	s := &Server{}
    	http.Handle("/", s)
    	log.Fatal(http.ListenAndServe   (":8085", nil))
    }
   ```
  `main_test.go`. Tests the HTTP server.
  ```
    package main

    import (
    	"io/ioutil"
    	"net/http"
    	"net/http/httptest"
    	"testing"
    )

    func TestServeHTTP(t *testing.T) {
    	handler := &Server{}
    	server := httptest.NewServer    (handler)
    	defer server.Close()

    	resp, err := http.Get(server.URL)
    	if err != nil {
    		t.Fatal(err)
    	}
    	if resp.StatusCode != 200 {
    		t.Fatalf("Received non-200    response: %d\n", resp.StatusCode)
    	}
    	expected := `{"message": "Hello     World!"}`
    	actual, err := ioutil.ReadAll(resp.   Body)
    	if err != nil {
    		t.Fatal(err)
    	}
    	if expected != string(actual) {
    		t.Errorf("Expected the message    '%s' but got '%s'\n", expected,   actual)
    	}
    }
   ```
   * `Dockerfile`. The app will be containerized and its image will pushed to the `dockerhub`.

   ```
    FROM golang:alpine as builder
    WORKDIR /app
    COPY . .
    ENV GO111MODULE=auto
    RUN CGO_ENABLED=0 GOOS=linux go build -a -o main .

    FROM alpine:latest
    RUN apk --no-cache add ca-certificates
    WORKDIR /root
    COPY --from=builder /app/main .
    #COPY --from=builder /app/.env .
    EXPOSE 8085
    CMD ["./main"]
   ```
   `Jenkinsfile`.   
    ```
      pipeline {
      agent any
      tools {
          go 'go1.16'
      }
      environment {
          GO111MODULE = 'auto'
          CGO_ENABLED = 0 
          GOPATH = "${JENKINS_HOME}/jobs/${JOB_NAME}/builds/${BUILD_ID}"
          registry = "barisertas/jenkins_go"
          registryCredential = "dockerhub_id"
          dockerImage = ""
      }
      stages {        
          stage('Build') {
              steps {
                  echo 'Compiling and building'
                  sh 'go build'
              }
          }

          stage('Test') {
              steps {
                  withEnv(["PATH+GO=${GOPATH}/bin"]){
                      echo 'Running test'
                      sh 'go test -v'
                  }
              }
          }   

          stage('Create Image') {
              steps {
                  script {
                      dockerImage = docker.build registry + ":$BUILD_NUMBER"
                  }
              }
          }

          stage('Publish') {
              steps {
                  script {
                      docker.withRegistry('', registryCredential) {
                          dockerImage.push()
                      }
                  }
              }
          }
       }
    } 
 
    ```

  Open the dashboard of an item you created as. Then click `Build now` and wait for the process to finish where you will see the whole progress of stages in a row. 

  Then check to make sure that the image is pushed to the `dockerhub`.
