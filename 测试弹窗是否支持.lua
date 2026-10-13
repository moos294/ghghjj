local 屏幕 = Instance.new("ScreenGui")
屏幕.Name = "TestGui"
屏幕.ResetOnSpawn = false
pcall(function() 屏幕.Parent = game:GetService("CoreGui") end)
if not 屏幕.Parent then 屏幕.Parent = game:GetService("Players").LocalPlayer.PlayerGui end

local 文字框 = Instance.new("TextLabel")
文字框.Size = UDim2.new(0, 500, 0, 400)
文字框.Position = UDim2.new(0, 20, 0, 20)
文字框.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
文字框.BackgroundTransparency = 0.3
文字框.TextColor3 = Color3.fromRGB(0, 255, 0)
文字框.TextScaled = true
文字框.Text = "测试开始..."
文字框.TextWrapped = true
文字框.Font = Enum.Font.Code
文字框.Parent = 屏幕

local function 显示(文字)
    文字框.Text = 文字框.Text .. "\n" .. tostring(文字)
end

显示("开始测试")

task.spawn(function()
    local 成功, 结果 = pcall(function()
        return game:HttpGet("https://cdn.jsdelivr.net/gh/moos294/366@main/crown.lua", true)
    end)
    if not 成功 then
        显示("下载失败: " .. tostring(结果))
        return
    end
    显示("下载成功 " .. #结果 .. " 字节")
    task.wait(0.3)
    local 函数, 错误 = loadstring(结果)
    if not 函数 then
        显示("编译失败: " .. tostring(错误))
        return
    end
    显示("编译成功")
    task.wait(0.3)
    local 执行成功, 执行错误 = pcall(函数)
    if not 执行成功 then
        显示("执行失败: " .. tostring(执行错误))
    else
        显示("全部成功！")
    end
end)