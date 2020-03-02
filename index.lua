package.cpath = ngx.var.lua_dir .. "lib/?.so;;"
package.path = ngx.var.lua_dir .. "?.lua;;"

local cjson = require "cjson"
function e(message)
    local r = {}
    r['code'] = 0
    r['message'] = message
    ngx.say(cjson.encode(r))
end
function s(message)
    local r = {}
    r['code'] = 1
    r['message'] = message
    ngx.say(cjson.encode(r))
end

local redis = require "lib.resty.redis"
local red = redis:new()
local redis_config = require "config.redis"
local ok, err = red:connect(redis_config.host, redis_config.port)
if not ok then
    return e("failed to connect: ", err)
end

local res, err = red:get(redis_config.prefix .. ngx.var.host)
if not res then
    return e("failed to get the key: ", err)
end
if res == ngx.null then
    local mysql = require "lib.resty.mysql"
    local mysql_config = require "config.mysql"

    local db, err = mysql:new()
    if not db then
        return e("failed to instantiate mysql: ", err)
    end
    local ok, err, errcode, sqlstate = db:connect(mysql_config)
    if not ok then
        return e("failed to connect: ", err, ": ", errcode, " ", sqlstate)
    end
    local sql = "SELECT * FROM map WHERE domain = '" .. ngx.var.host .. "'"

    local res, err, errno, sqlstate = db:query(sql)
    db:close()
    -- ngx.say(#res)
    if not res then
        return e(err)
    end
    if #res > 0 then
        ok, err = red:set(redis_config.prefix .. ngx.var.host, res[1]['directory'])
        ngx.exec(res[1]['directory'] .. string.sub(ngx.var.uri, 2))
    end
    return
else
    ngx.exec(res .. string.sub(ngx.var.uri, 2))
end

