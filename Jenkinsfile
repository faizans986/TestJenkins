pipeline {
  agent any

  tools {
    jdk 'java'       // this must match the name you set in "Global Tool Configuration"
    maven 'maven'    // this must match the Maven name you set
  }
  
  options {
    buildDiscarder(logRotator(numToKeepStr: '20'))
    // timestamps()
  }

  parameters {
    booleanParam(name: 'CHEF_ENABLED', defaultValue: false, description: 'Run Chef deployment after build')
    string(name: 'CHEF_NODE', defaultValue: 'webserver', description: 'Chef node name or search query, e.g., name:webserver')
  }

  environment {
    APP_NAME = 'hello-jenkins'
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
          echo "Triggering Chef on ${CHEF_NODE} ..."
          if command -v knife >/dev/null 2>&1; then
            knife ssh "${CHEF_NODE}" "sudo chef-client" -x ec2-user || knife ssh "${CHEF_NODE}" "sudo chef-client"
          else
            echo "knife not found. Install Chef Workstation on Jenkins node to enable Chef-based deploys."
          fi
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
