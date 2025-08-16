# === Update these for your environment ===
default['deploy_app']['jenkins_base'] = 'http://<JENKINS_IP>:8080'
default['deploy_app']['job_name'] = 'hello-jenkins-pipeline'
default['deploy_app']['artifact_glob'] = 'target/hello-jenkins-0.0.1-SNAPSHOT.jar'

# Where to install/run the app on the node
default['deploy_app']['install_dir'] = '/opt/hello-jenkins'
default['deploy_app']['service_user'] = 'ec2-user'
default['deploy_app']['service_name'] = 'hello-jenkins'
default['deploy_app']['java_pkg'] = 'java-17-amazon-corretto'
