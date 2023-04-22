pipeline {
    agent any
    
    stages {
        //Stage to perform AZURE login by taking the credentials from Jenkins credentials
        stage ("Az login") {
            steps {
            withCredentials([usernamePassword(credentialsId: 'azure-user-pass', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
              sh ('az login -u ${USERNAME} -p ${PASSWORD}')
               }
            }
        }
        
        //Initialize the directory and perform updates if needed
        stage ("terraform init") {
            steps {
                sh ('terraform init') 
            }
        }
        //validate the terraform syntax
        stage ("terraform validate") {
            steps {
                sh ('terraform validate') 
            }
        }
        //run the tf against the state and informs on the actions to take
        stage ("terraform plan") {
            steps {
                sh ('terraform plan') 
            }
        }

        //apply the steps and pass the credentials to be used when logging in to the VM
        //auto approve to automate the script and no color to avoid having strange characters in output
        stage ("terraform apply") {
            steps {
              withCredentials([usernamePassword(credentialsId: 'VM02user', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
               sh ('terraform apply -var "username=${USERNAME}" -var "password=${PASSWORD}" --auto-approve -no-color')
              }  
            }
        }
    }
}
