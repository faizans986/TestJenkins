pipeline {
  agent any

  tools {
    jdk 'java'       // Must match the name set in "Global Tool Configuration"
    maven 'maven'    // Must match the Maven name you set
  }
  
  options {
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    booleanParam(name: 'CHEF_ENABLED', defaultValue: false, description: 'Run Chef deployment after build')
  }

  environment {
    APP_NAME = 'hello-jenkins'
    CLIENT_IP = '54.226.161.197'   // Chef Client EC2 instance
    SSH_KEY = '~/.ssh/my-key.pem'  // Update with your actual PEM key path
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh 'mvn -q -DskipTests clean package'
      }
    }

    stage('Archive Artifact') {
      steps {
        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
      }
    }

    stage('Deploy with Chef') {
      when {
        expression { return params.CHEF_ENABLED }
      }
      steps {
        sh '''
          set -e
          echo "Copying cookbook to client node ${CLIENT_IP} ..."
          scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -r cookbooks/my_webserver ec2-user@${CLIENT_IP}:/home/ec2-user/

          echo "Running Chef client on ${CLIENT_IP} ..."
          ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ec2-user@${CLIENT_IP} \
          "sudo chef-client --local-mode --runlist 'recipe[my_webserver::default]'"
        '''
      }
    }
  }

  post {
    success {
      echo 'Build finished successfully.'
    }
  }
}
