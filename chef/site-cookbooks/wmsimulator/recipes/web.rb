include_recipe 'apt::default'
include_recipe 'apache2::default'
include_recipe 'apache2::mod_wsgi'
include_recipe 'mysql::client'

#install python from package
include_recipe 'python::package'
#install pip from source
include_recipe 'python::pip'
#install python dependencies
%w{Flask  Flask-SQLAlchemy Flask-Admin  Flask-Cache  MySQL-python}.each do |python_pkg|
  python_pip python_pkg
end

#ensure git is installed
package 'git'

directory ::File.join node['wmsimulator']['install_dir'], 'shared/log' do
  recursive true
  owner 'www-data'
end

template ::File.join node['wmsimulator']['install_dir'], 'shared/configuration_custom.py'  do
  source 'configuration.py.erb'
end

include_recipe 'wmsimulator::deploy'

service 'apache2' do
  subscribes :reload, 'deploy_revision[wmsimulator]'
end

execute "seed database" do
  command "python defaults.py"
  cwd node['wmsimulator']['web_install_dir']
  action :nothing
  subscribes :run, 'deploy_revision[wmsimulator]'
end

#drop apache virtual host configuration
template "#{node['apache']['dir']}/sites-available/wmsimulator" do
  source 'apache_site.conf.erb'
  mode 0644
  notifies :reload, 'service[apache2]' 
end
apache_site 'wmsimulator' do
  action :enable
end