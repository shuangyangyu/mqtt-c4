-- 检查环境函数
local function checkDependencies()
    local missing = {}
    local warnings = {}
    
    -- 检查基础函数
    local basicFuncs = {
        {"error", _G.error},
        {"pcall", _G.pcall},
        {"setmetatable", _G.setmetatable},
        {"tostring", _G.tostring},
        {"type", _G.type}
    }
    
    print("=== 检查基础函数 ===")
    for _, func in ipairs(basicFuncs) do
        local name, fn = func[1], func[2]
        if type(fn) ~= "function" then
            table.insert(missing, "基础函数: " .. name)
            print("✗ 基础函数: " .. name)
        else
            print("√ 基础函数: " .. name)
        end
    end
    
    -- 检查字符串函数 (Lua 5.1 原生支持)
    local stringFuncs = {
        "byte", "char", "format", "len", "sub"
    }
    
    print("\n=== 检查字符串函数 (Lua 5.1) ===")
    for _, funcName in ipairs(stringFuncs) do
        if type(string[funcName]) ~= "function" then
            table.insert(missing, "字符串函数: string." .. funcName)
            print("✗ 字符串函数: string." .. funcName)
        else
            print("√ 字符串函数: string." .. funcName)
        end
    end
    
    -- 检查表操作函数
    local tableFuncs = {
        "concat", "insert", "remove"
    }
    
    print("\n=== 检查表操作函数 ===")
    for _, funcName in ipairs(tableFuncs) do
        if type(table[funcName]) ~= "function" then
            table.insert(missing, "表操作函数: table." .. funcName)
            print("✗ 表操作函数: table." .. funcName)
        else
            print("√ 表操作函数: table." .. funcName)
        end
    end
    
    -- 检查数学函数 (Lua 5.1 原生支持)
    local mathFuncs = {
        "random", "floor"
    }
    
    print("\n=== 检查数学函数 (Lua 5.1) ===")
    for _, funcName in ipairs(mathFuncs) do
        if type(math[funcName]) ~= "function" then
            table.insert(missing, "数学函数: math." .. funcName)
            print("✗ 数学函数: math." .. funcName)
        else
            print("√ 数学函数: math." .. funcName)
        end
    end
    
    -- 检查位运算库
    print("\n=== 检查位运算库 ===")
    local bitFuncs = {
        "band", "bor", "rshift", "lshift"
    }
    
    local status, bit = pcall(require, "bit")
    if not status then
        table.insert(missing, "位运算库 (bit)")
        print("✗ 位运算库加载失败")
    else
        print("√ 位运算库已加载")
        for _, funcName in ipairs(bitFuncs) do
            if type(bit[funcName]) ~= "function" then
                table.insert(missing, "位运算函数: bit." .. funcName)
                print("✗ 位运算函数: bit." .. funcName)
            else
                print("√ 位运算函数: bit." .. funcName)
            end
        end
    end
    
    -- 检查需要实现的 Lua 5.3 功能
    print("\n=== 检查需要实现的 Lua 5.3 功能 ===")
    
    -- 检查 math.type
    if type(math.type) ~= "function" then
        table.insert(warnings, "需要实现 math.type")
        print("! 需要实现: math.type")
    else
        print("√ 已存在: math.type")
    end
    
    -- 检查 string.pack/unpack
    if type(string.pack) ~= "function" then
        table.insert(warnings, "需要实现 string.pack")
        print("! 需要实现: string.pack")
    else
        print("√ 已存在: string.pack")
    end
    
    if type(string.unpack) ~= "function" then
        table.insert(warnings, "需要实现 string.unpack")
        print("! 需要实现: string.unpack")
    else
        print("√ 已存在: string.unpack")
    end
    
    -- 检查 UTF8 支持
    if type(utf8) ~= "table" then
        table.insert(warnings, "需要实现 utf8 库")
        print("! 需要实现: utf8 库")
    else
        if type(utf8.len) ~= "function" then
            table.insert(warnings, "需要实现 utf8.len")
            print("! 需要实现: utf8.len")
        else
            print("√ 已存在: utf8.len")
        end
        
        if type(utf8.codes) ~= "function" then
            table.insert(warnings, "需要实现 utf8.codes")
            print("! 需要实现: utf8.codes")
        else
            print("√ 已存在: utf8.codes")
        end
    end
    
    -- 检查 C4 特定函数
    print("\n=== 检查 Control4 特定函数 ===")
    if type(C4) ~= "table" then
        table.insert(warnings, "C4 全局对象不存在")
        print("✗ C4 全局对象不存在")
    else
        print("√ C4 全局对象存在")
    end
    
    -- 输出结果
    print("\n=== 检查结果 ===")
    if #missing > 0 then
        print("\n缺少的基础组件:")
        for _, item in ipairs(missing) do
            print("✗ " .. item)
        end
    else
        print("√ 所有基础组件都已存在")
    end
    
    if #warnings > 0 then
        print("\n需要实现的 Lua 5.3 组件:")
        local seen = {}  -- 用于去重
        for _, item in ipairs(warnings) do
            if not seen[item] then
                seen[item] = true
                if item:match("utf8") then
                    print("! " .. "需要实现: utf8 库及其函数 (utf8.len, utf8.codes)")
                elseif not item:match("C4") then
                    print("! " .. item)
                end
            end
        end
        
        -- Control4 相关警告单独显示
        for _, item in ipairs(warnings) do
            if item:match("C4") and not seen["C4"] then
                seen["C4"] = true
                print("\n提示: " .. item .. " (仅在 Control4 环境中需要)")
            end
        end
    end
    
    return #missing == 0, missing, warnings
end

-- 执行检查
local success, missing, warnings = checkDependencies()

-- 返回检查结果
return {
    success = success,
    missing = missing,
    warnings = warnings
}
