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

-- 返回模块（可选）
return {
    utf8 = utf8,
    math_type = math.type
}
