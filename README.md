# Jenkins + GitHub + Chef: End-to-End Mini Pipeline

This repo is a **plug-and-play demo** showing how a developer change triggers a Jenkins build and deploys with **Chef** to an EC2 instance.

## What you get
- Simple Spring Boot app (`/` says *Hello from Jenkins CI!*).
- `Jenkinsfile` for a fully working pipeline: checkout → build → archive → (optional) Chef deploy.
- Chef cookbook `deploy_app` that:
  - Installs Java,
  - Fetches the last Jenkins build artifact,
  - Manages a **systemd** service for the app,
  - Restarts automatically on new builds.

---

## 1) Prereqs
- Jenkins running on an EC2 instance (port 8080).
- Git installed on Jenkins (`sudo yum install -y git`).
- Maven installed on Jenkins (`sudo yum install -y maven` or install via tarball).
- (Optional for deploy stage) **Chef Workstation** installed on the Jenkins node:
  ```bash
  curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P chef-workstation
  ```
- A **target EC2** where the app will run (Amazon Linux 2 or similar) bootstrapped to Chef Server or using client.rb to talk to your Chef server.
  - Example bootstrap from Jenkins node:
    ```bash
    knife bootstrap <TARGET_EC2_IP> -x ec2-user --sudo -i <your-key.pem> --node-name webserver
    ```

---

## 2) Create Jenkins Job (Multibranch or Pipeline)
- Create a **Pipeline** job in Jenkins.
- Choose **Pipeline script from SCM** and point to this repo.
- Leave `Jenkinsfile` at the root.
- First run: `Build Now` to confirm packaging works.

**Parameters**
- `CHEF_ENABLED`: set to **true** to run Chef after the build.
- `CHEF_NODE`: set node search, e.g., `name:webserver`.

---

## 3) Verify the Build
- On Jenkins, after a successful build, go to **Build # → Artifacts** and see the `target/hello-jenkins-*.jar` file.
- You can also run the app locally for a smoke test:
  ```bash
  java -jar target/hello-jenkins-0.0.1-SNAPSHOT.jar
  curl http://localhost:8080/
  ```

---

## 4) Chef Cookbook: `deploy_app`
### Configure attributes
Edit `chef/cookbooks/deploy_app/attributes/default.rb` to match your Jenkins details:

```ruby
default['deploy_app']['jenkins_base'] = 'http://<JENKINS_IP>:8080'
default['deploy_app']['job_name'] = '<YOUR_JENKINS_JOB_NAME>'
default['deploy_app']['artifact_glob'] = 'target/hello-jenkins-0.0.1-SNAPSHOT.jar'
default['deploy_app']['service_user'] = 'ec2-user'
default['deploy_app']['install_dir'] = '/opt/hello-jenkins'
```

### Add to the node run list
```
knife node run_list add webserver 'recipe[deploy_app]'
```

### Trigger deployment
- Run the Jenkins job with `CHEF_ENABLED=true`, **or**
- SSH to the node and run:
  ```bash
  sudo chef-client
  ```

---

## 5) How it works (Interview explanation)
- Dev pushes Git → Jenkins **SCM poll/webhook** triggers a build.
- Jenkins runs Maven build → produces jar → archives artifact.
- Jenkins optionally triggers **Chef**.
- Chef recipe fetches the **lastSuccessfulBuild** artifact from Jenkins and manages a **systemd** service to run the app.
- On next build, Chef sees a new artifact checksum and restarts the service = **zero-touch deploys**.

---

## Troubleshooting
- If the Jenkins server is not publicly reachable, expose it via SG or reverse proxy, or host artifacts on S3 as a public (or signed) URL.
- Ensure security groups allow inbound on ports you expect (8080 Jenkins, 8081/8082 if you proxy, 22 for SSH).
- For Amazon Linux, the Java package may be `java-17-amazon-corretto` instead of OpenJDK 17—update the cookbook accordingly.
