
# Disconnect installation method
Red Hat inspection and reporting tool
https://quipucords.github.io/quipudocs/

1. In a disconnected environment, we need to go for the offline installation method as shown below. Please note, this will work for RHEL 7.x
Download all the dependencies and the 2 container files from here : https://spideroak.com/browse/share/beapen/111

The 2 container files are postgres.9.6.10.tar and quipucords_server_image.tar.gz. The dependencies are in the zip file QPC Dependencies_76.zip

2. Copy these to fresh installation images   
Load all RPMs at /path and using qpc-tools installer deploy with offline mode
```
#rpm -Uvh --force /path/*.rpm
#qpc-tools server install --offline-files=/path --version=0.9.2
```

3. You will be prompted for a server password and database password of your choice.
```
# qpc-tools cli install --offline-files=/path
```

4. Configuring the QPC Command Line Tool Connection
```
# qpc server config --host 127.0.0.1
```

5. Log in to the QPC Server via CLI or GUI
```
# qpc server login - To log in via CLI
```

Enter the server user name and password at the prompts. The default login is admin and the password is the server password you provided after typing the qpc-tools server install command.
To log in via GUI use a browser of your choice and browse to http://127.0.0.1:9443
Use the same credentials used in CLI

6. Continue with steps from Page 4 of the Quick Start Guide.

# install walkthrough
```
cat > /etc/yum.repos.d/public.repo << 'EOF'
[rhel-7-server-rpms]
name=rhel-7-server-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-rpms
gpgcheck=0
enabled=1

[rhel-7-server-extras-rpms]
name=rhel-7-server-extras-rpms
baseurl=http://10.66.208.115/rhel7osp/rhel-7-server-extras-rpms
gpgcheck=0
enabled=1

EOF

yum install https://github.com/quipucords/qpc-tools/releases/latest/download/qpc-tools.el7.noarch.rpm

# qpc server install
qpc-tools server install

# qpc client install
qpc-tools cli install

# config server
qpc server config --host 10.66.208.160
# Server config /root/.config/qpc/server.config was not found.
# Server connectivity was successfully configured. The server will be contacted via "https" at host "10.66.208.160" with port "9443".

# login into server
qpc server login

# add cred
qpc cred add --type network --name qpcnetworksource --username qpctester --password --become-method su --become-user root --become-password
qpc cred add --type network --name cred_rhvhost --username root --password

# add source
qpc source add --type network --name registry --hosts 10.66.208.115 --cred qpcnetworksource
qpc source add --type network --name source_rhvhost --hosts 10.66.208.[51:53] --cred cred_rhvhost

# add scan
qpc scan add --name scan_registry1 --sources registry
qpc scan add --name scan_rhvhost1 --sources source_rhvhost

# run scan
qpc scan start --name scan_registry1
qpc scan start --name scan_rhvhost1

# view a scan
qpc scan job --id 1
qpc scan list
qpc scan job --name scan_registry1

qpc scan job --id 2
qpc scan list
qpc scan job --name scan_rhvhost1

# download scan report
qpc report download --scan-job 1 --output-file=~/scan_output.tar.gz
qpc report download --scan-job 2 --output-file=~/scan_output_rhvhost.tar.gz
```