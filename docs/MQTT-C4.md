# MQTT for Control4

Control4 环境下的 MQTT 客户端实现，基于 lua-mqtt 库适配。

## 实现说明

### mqtt_compat.lua
```lua
-- MQTT 兼容性实现
-- 为 Control4 环境提供缺少的 Lua 5.3 功能

-- 1. UTF8 支持
utf8 = utf8 or {}

-- UTF8 字符串长度计算
utf8.len = utf8.len or function(s)
    if type(s) ~= 'string' then
        error("bad argument #1 to 'len' (string expected, got " .. type(s) .. ")")
    end
    
    local len = 0
    local i = 1
    while i <= #s do
        local c = string.byte(s, i)
        if c < 128 then
            i = i + 1
        elseif c < 224 then
            i = i + 2
        elseif c < 240 then
            i = i + 3
        else
            i = i + 4
        end
        len = len + 1
    end
    return len
end

-- UTF8 字符迭代器
utf8.codes = utf8.codes or function(s)
    if type(s) ~= 'string' then
        error("bad argument #1 to 'codes' (string expected, got " .. type(s) .. ")")
    end
    
    local pos = 1
    return function()
        if pos > #s then return nil end
        
        local b1 = string.byte(s, pos)
        local bytes, code
        
        if b1 < 128 then
            bytes = 1
            code = b1
        elseif b1 < 224 then
            bytes = 2
            if pos + 1 > #s then
                error("invalid UTF-8 code")
            end
            code = (b1 - 192) * 64 + (string.byte(s, pos + 1) - 128)
        elseif b1 < 240 then
            bytes = 3
            if pos + 2 > #s then
                error("invalid UTF-8 code")
            end
            code = (b1 - 224) * 4096 + 
                   (string.byte(s, pos + 1) - 128) * 64 + 
                   (string.byte(s, pos + 2) - 128)
        else
            bytes = 4
            if pos + 3 > #s then
                error("invalid UTF-8 code")
            end
            code = (b1 - 240) * 262144 + 
                   (string.byte(s, pos + 1) - 128) * 4096 + 
                   (string.byte(s, pos + 2) - 128) * 64 + 
                   (string.byte(s, pos + 3) - 128)
        end
        
        local lastPos = pos
        pos = pos + bytes
        return lastPos, code
    end
end

-- 2. 数学类型检查
math.type = math.type or function(n)
    if type(n) ~= "number" then
        return nil
    end
    if n == math.floor(n) then
        return "integer"
    end
    return "float"
end

return {
    utf8 = utf8,
    math_type = math.type
}
```

## 功能特性

- 完整支持 MQTT 3.1.1 协议
- 适配 Control4 OS3 环境
- 支持 QoS 0, 1, 2
- 支持 UTF-8 主题
- 支持持久会话
- 支持遗嘱消息
- 支持保留消息

## 使用示例

```lua
-- 1. 加载库
require("mqtt_compat")  -- 必须先加载兼容层
local mqtt = require("mqtt311")

-- 2. 创建 MQTT 客户端
local client = mqtt.new({
    -- 网络连接封装
    socket = {
        connection = nil,
        
        connect = function(self, host, port)
            self.connection = C4:CreateNetworkConnection()
            -- 连接逻辑
        end,
        
        write = function(self, data)
            return self.connection:Write(data)
        end,
        
        read = function(self)
            return self.connection:Read()
        end,
        
        close = function(self)
            if self.connection then
                self.connection:Disconnect()
            end
        end
    },
    
    -- 日志处理
    logger = {
        debug = function(_, msg)
            C4:DebugLog("MQTT: " .. msg)
        end,
        
        error = function(_, msg)
            C4:ErrorLog("MQTT: " .. msg)
        end
    },
    
    -- 回调函数
    on_connect = function(success)
        -- 处理连接结果
    end,
    
    on_message = function(topic, payload)
        -- 处理收到的消息
    end,
    
    on_error = function(err)
        -- 处理错误
    end
})

-- 3. 连接到服务器
client:connect({
    host = "mqtt.example.com",
    port = 1883,
    clean = true,
    keep_alive = 60,
    client_id = "control4_client"
})

-- 4. 发布消息
client:publish("topic/test", "Hello from Control4!", {
    qos = 1,
    retain = false
})

-- 5. 订阅主题
client:subscribe("topic/#", {
    qos = 1
})
```

## 注意事项

1. 必须先加载 `mqtt_compat.lua`
2. Control4 环境已提供：
   - string.pack/unpack
   - bit 库
3. 网络连接请使用 C4:CreateNetworkConnection()
4. 日志请使用 C4:Log/C4:ErrorLog/C4:DebugLog

## 依赖说明

- Lua 5.1 (Control4 环境)
- Control4 OS3
- mqtt_compat.lua (提供 UTF8 和 math.type 支持)

## 许可证

MIT License

## 致谢

- 基于 [lua-mqtt](https://github.com/xHasKx/luamqtt) 库适配
- 感谢原作者的优秀工作
