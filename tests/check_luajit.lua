local function checkLuaJIT()
    local info = {}
    local missing = {}
    
    print("=== LuaJIT 环境检查 ===\n")
    
    -- 检查 LuaJIT 是否存在
    if type(jit) == "table" then
        print("√ LuaJIT 已检测到")
        print("版本信息: " .. jit.version)
        info.version = jit.version
        
        -- 检查 JIT 状态
        print("\n=== JIT 状态 ===")
        if type(jit.status) == "function" then
            local status = {jit.status()}
            print("JIT 状态: " .. (status[1] and "启用" or "禁用"))
            info.jit_enabled = status[1]
        end
        
        -- 检查 FFI 库
        print("\n=== FFI 库检查 ===")
        local status, ffi = pcall(require, "ffi")
        if status then
            print("√ FFI 库可用")
            info.ffi_available = true
            
            -- 检查一些常用 FFI 函数
            local ffiFuncs = {
                "cdef",
                "new",
                "cast",
                "typeof",
                "sizeof"
            }
            
            for _, funcName in ipairs(ffiFuncs) do
                if type(ffi[funcName]) == "function" then
                    print("  √ ffi." .. funcName)
                else
                    print("  ✗ ffi." .. funcName)
                end
            end
        else
            print("✗ FFI 库不可用")
            info.ffi_available = false
        end
        
        -- 检查位运算支持
        print("\n=== 位运算支持 ===")
        local bitFuncs = {
            "bnot",
            "band",
            "bor",
            "bxor",
            "lshift",
            "rshift",
            "arshift",
            "rol",
            "ror"
        }
        
        local bit = bit or bit32
        if bit then
            print("√ 位运算库可用")
            info.bit_available = true
            
            for _, funcName in ipairs(bitFuncs) do
                if type(bit[funcName]) == "function" then
                    print("  √ bit." .. funcName)
                else
                    print("  ✗ bit." .. funcName)
                end
            end
        else
            print("✗ 位运算库不可用")
            info.bit_available = false
        end
        
        -- 检查 JIT 特定函数
        print("\n=== JIT 特定函数 ===")
        local jitFuncs = {
            "on",
            "off",
            "flush",
            "status",
            "opt"
        }
        
        for _, funcName in ipairs(jitFuncs) do
            if type(jit[funcName]) == "function" then
                print("√ jit." .. funcName)
            else
                print("✗ jit." .. funcName)
            end
        end
        
    else
        print("✗ 不是 LuaJIT 环境")
        return false, "非 LuaJIT 环境"
    end
    
    -- 检查 LuaJIT 特有的字符串特性
    print("\n=== 字符串特性 ===")
    local str = "test"
    if type(str) == "string" and str.gsub then
        print("√ 字符串元方法可用")
        info.string_metamethods = true
    else
        print("✗ 字符串元方法不可用")
        info.string_metamethods = false
    end
    
    -- 输出架构信息
    print("\n=== 架构信息 ===")
    if jit and jit.arch then
        print("架构: " .. jit.arch)
        info.arch = jit.arch
    end
    if jit and jit.os then
        print("操作系统: " .. jit.os)
        info.os = jit.os
    end
    
    return info, missing
end

-- 执行检查
local info, missing = checkLuaJIT()

-- 返回结果
return {
    is_luajit = type(jit) == "table",
    info = info,
    missing = missing
} 