#cloud-config
apt_update: true
packages:
  - git
  - python-dev
  - python-pip
  - libmysqlclient-dev

write_files:
  - content: |
      {
      "host": "${mysql_host}",
      "user": "${mysql_user}@${mysql_server_name}",
      "passwd": "${mysql_passwd}",
      "db": "${mysql_db}",
      "port": "3306"
      }
    path: /etc/app_config.json

runcmd:
  - ['mkdir', '-p', '/usr/src/app']
  - ['git', 'clone', '-b', 'feature/config-file','https://github.com/vngrs/sample-python-app.git', '/usr/src/app']
  - ['pip', 'install', '-r', '/usr/src/app/requirements.txt']
  - ['nohup', 'python', '/usr/src/app/app.py', '&']