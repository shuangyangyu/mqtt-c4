-- MQTT 兼容性实现
-- 为开发环境提供 Control4 缺失功能的模拟

local M = {}

-- 环境检查
local function check_environment()
    local env = {
        is_c4 = (type(C4) == "table"),
        has_utf8 = (type(utf8) == "table"),
        has_pack = (type(string.pack) == "function"),
        has_unpack = (type(string.unpack) == "function"),
        has_math_type = (type(math.type) == "function")
    }
    
    -- 调试信息
    if _DEBUG then
        print("=== 环境检查 ===")
        print("Control4环境:", env.is_c4 and "是" or "否")
        print("UTF8支持:", env.has_utf8 and "是" or "否")
        print("Pack支持:", env.has_pack and "是" or "否")
        print("Unpack支持:", env.has_unpack and "是" or "否")
        print("Math.type支持:", env.has_math_type and "是" or "否")
        print("================")
    end
    
    return env
end

-- UTF8 实现
local function create_utf8()
    return {
        len = function(s)
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
        end,
        
        codes = function(s)
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
    }
end

-- Pack/Unpack 实现
local function create_string_extensions()
    return {
        pack = function(fmt, ...)
            local args = {...}
            local result = ""
            
            if fmt:match(">I2") then
                local n = args[1]
                if type(n) ~= "number" then
                    error("bad argument to 'pack' (number expected)")
                end
                result = string.char(
                    math.floor(n / 256) % 256,
                    n % 256
                )
            elseif fmt:match("s2") then
                local s = args[1]
                if type(s) ~= "string" then
                    error("bad argument to 'pack' (string expected)")
                end
                local len = #s
                result = string.char(
                    math.floor(len / 256) % 256,
                    len % 256
                ) .. s
            else
                error("unsupported format: " .. fmt)
            end
            
            return result
        end,
        
        unpack = function(fmt, data, pos)
            pos = pos or 1
            
            if fmt:match(">I2") then
                if pos + 1 > #data then
                    error("insufficient data to unpack")
                end
                local b1, b2 = string.byte(data, pos, pos + 1)
                return b1 * 256 + b2, pos + 2
            elseif fmt:match("s2") then
                if pos + 1 > #data then
                    error("insufficient data to unpack")
                end
                local b1, b2 = string.byte(data, pos, pos + 1)
                local len = b1 * 256 + b2
                if pos + 1 + len > #data then
                    error("insufficient data to unpack")
                end
                return string.sub(data, pos + 2, pos + 1 + len), pos + 2 + len
            else
                error("unsupported format: " .. fmt)
            end
        end
    }
end

-- Math.type 实现
local function create_math_extensions()
    return {
        type = function(n)
            if type(n) ~= "number" then
                return nil
            end
            if n == math.floor(n) then
                return "integer"
            end
            return "float"
        end
    }
end

-- 安全地应用补丁
local function apply_patches(env)
    env = env or check_environment()
    
    if not env.is_c4 then
        -- 在非 C4 环境中才应用补丁
        if not env.has_utf8 then
            _G.utf8 = create_utf8()
        end
        
        if not env.has_pack then
            local str_ext = create_string_extensions()
            string.pack = str_ext.pack
            string.unpack = str_ext.unpack
        end
        
        if not env.has_math_type then
            math.type = create_math_extensions().type
        end
        
        -- 添加整数除法运算符
        if not getmetatable(1).__idiv then
            local mt = getmetatable(1)
            if not mt then
                mt = {}
                debug.setmetatable(1, mt)
            end
            mt.__idiv = function(a, b)
                return math.floor(a / b)
            end
        end
    end
end

-- 导出
M.check_environment = check_environment
M.apply_patches = apply_patches
M.create_utf8 = create_utf8
M.create_string_extensions = create_string_extensions
M.create_math_extensions = create_math_extensions

-- 自动应用补丁（可以注释掉这行，改为手动控制）
apply_patches()

return M
