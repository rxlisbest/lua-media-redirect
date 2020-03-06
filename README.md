# lua-media-redirect
#### 项目需要
- linux
- openresty
- mysql
- redis

#### 部署步骤
- git clone https://github.com/rxlisbest/dynamic-domain
- 新建数据库:dynamic_domain 
- 数据库中执行脚本:dynamic_domain.sql
- 修改数据库配置文件config/mysql.lua
```
return {
            host = "127.0.0.1",
            port = 3306,
            database = "dynamic_domain",
            user = "root",
            password = "root",
            charset = "utf8",
            -- prefix = "rrs_",
            max_packet_size = 1024 * 1024,
        }
```
- 修改redis配置文件config/redis.lua
```
return {
            host = "127.0.0.1",
            port = 6379,
            user = "root",
            password = "root",
            prefix = 'dd_',
            auth = '',
        }
```
- 修改nginx.conf如下:
```
    geo $lua_dir {
       default "lua项目目录"; # must-have
    }
    server {
        listen 80;
        server_name localhost;
        lua_code_cache on;
        location = /api/add {
            default_type application/json;
            set $lua_file "api_add.lua"; # must-have
            content_by_lua_file $lua_dir$lua_file;
        }
        location = /api/delete {
            default_type application/json;
            set $lua_file "api_delete.lua"; # must-have
            content_by_lua_file $lua_dir$lua_file;
        }
    }
    server {
        listen 80 default;
        lua_code_cache on;
        location / {
            default_type text/html;
            set $lua_file "proxy.lua"; # must-have
            content_by_lua_file $lua_dir$lua_file;
        }
        location ~* /.*/.* {
            root /Library/WebServer/Documents/htdocs/upload_server/public/upload;
            default_type application/octet-stream;
        }
    }
```
- 启动nginx服务
#### 接口调用
- 新增
```
action: http://localhost/api/add
method: POST
content-type: application/x-www-form-urlencoded 
param: domain
param: directory
```
- 删除
```
action: http://localhost/api/delete
method: POST
content-type: application/x-www-form-urlencoded 
param: domain
```

