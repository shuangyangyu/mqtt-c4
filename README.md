# MQTT-C4

Control4 环境下的 MQTT 客户端实现，基于 lua-mqtt 库适配。

## 功能特性

- 完整支持 MQTT 3.1.1 协议
- 专门适配 Control4 OS3 环境
- 支持 QoS 0, 1, 2
- 支持 UTF-8 主题
- 支持持久会话
- 支持遗嘱消息
- 支持保留消息

## 目录结构

```
mqtt-c4/
  ├── src/                # 源代码
  │   ├── mqtt311.lua     # MQTT 3.1.1 实现
  │   ├── mqtt_compat.lua # 兼容层
  │   └── driver.lua      # 驱动示例
  │
  ├── docs/               # 文档
  │   └── MQTT-C4.md      # 使用说明
  │
  └── tests/              # 测试
      ├── check_luajit.lua      # LuaJIT 环境检查
      └── check_mqtt_deps.lua   # 依赖检查
```

## 快速开始

1. 复制 `mqtt311.lua` 和 `mqtt_compat.lua` 到你的驱动目录

2. 在驱动中引入:
```lua
-- 1. 首先加载兼容性实现
require("mqtt_compat")

-- 2. 然后加载 MQTT 库
local mqtt = require("mqtt311")

-- 3. 创建 MQTT 客户端
local client = mqtt.new({
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
    
    logger = {
        debug = function(_, msg)
            C4:DebugLog("MQTT: " .. msg)
        end,
        
        error = function(_, msg)
            C4:ErrorLog("MQTT: " .. msg)
        end
    }
})
```

## 环境要求

- Control4 OS3
- Lua 5.1
- Control4 驱动开发环境

## 依赖说明

Control4 环境已提供:
- string.pack/unpack
- bit 库

mqtt_compat.lua 提供:
- UTF8 支持 (utf8.len, utf8.codes)
- math.type 支持

## 测试

1. 环境检查:
```lua
dofile("tests/check_luajit.lua")
dofile("tests/check_mqtt_deps.lua")
```

2. 查看测试结果，确保所有依赖都可用

## 文档

详细使用说明请查看 [MQTT-C4.md](docs/MQTT-C4.md)

## 示例

完整的驱动示例请查看 [driver.lua](src/driver.lua)

## 常见问题

1. 必须先加载 mqtt_compat.lua
2. 网络连接请使用 C4:CreateNetworkConnection()
3. 日志请使用 C4:Log/C4:ErrorLog/C4:DebugLog

## 贡献指南

1. Fork 本仓库
2. 创建新分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 版本历史

- v0.1.0 - 2024-03-xx
  * 首次发布
  * 基本功能实现
  * Control4 环境适配

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 致谢

- 基于 [lua-mqtt](https://github.com/xHasKx/luamqtt) 库适配
- 感谢原作者的优秀工作

## 联系方式

- 项目地址：[https://github.com/你的用户名/mqtt-c4](https://github.com/你的用户名/mqtt-c4)
- 问题反馈：[https://github.com/你的用户名/mqtt-c4/issues](https://github.com/你的用户名/mqtt-c4/issues)
