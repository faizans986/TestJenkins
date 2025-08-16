#
# Cookbook:: deploy_app
# Recipe:: default
#

jenkins_base = node['deploy_app']['jenkins_base']
job_name     = node['deploy_app']['job_name']
install_dir  = node['deploy_app']['install_dir']
service_user = node['deploy_app']['service_user']
service_name = node['deploy_app']['service_name']
java_pkg     = node['deploy_app']['java_pkg']
artifact_glob = node['deploy_app']['artifact_glob']

# Ensure Java present
package java_pkg do
  package_name java_pkg
  action :install
end

directory install_dir do
  owner service_user
  group service_user
  mode '0755'
  recursive true
end

# Determine artifact name from Jenkins (lastSuccessfulBuild)
artifact_url = ::File.join(jenkins_base, "job", job_name, "lastSuccessfulBuild", "artifact", artifact_glob)

app_jar = ::File.join(install_dir, "app.jar")

remote_file app_jar do
  source artifact_url
  owner service_user
  group service_user
  mode '0755'
  action :create
end

template "/etc/systemd/system/#{service_name}.service" do
  source "app.service.erb"
  variables(
    service_name: service_name,
    service_user: service_user,
    install_dir: install_dir
  )
  notifies :run, 'execute[daemon-reload]', :immediately
end

execute 'daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

service service_name do
  action [:enable, :start]
  subscribes :restart, "remote_file[#{app_jar}]", :delayed
  subscribes :restart, "template[/etc/systemd/system/#{service_name}.service]", :delayed
end
