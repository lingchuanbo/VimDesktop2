# AutoIMESwitcher 自动输入法切换库使用说明

## 概述

AutoIMESwitcher 是一个通用的自动输入法切换库，可以为任何应用程序提供智能的输入法自动切换功能。当用户在应用程序中退出文本输入状态时，会自动切换到英文输入法，确保快捷键和VIM模式的正常使用。

## 功能特性

- **智能检测**：自动检测输入控件状态和鼠标光标类型
- **多重触发**：支持窗口激活、控件焦点变化、鼠标点击等多种触发方式
- **即时响应**：鼠标点击后50ms内完成检测和切换
- **高度可配置**：支持自定义输入控件模式、光标类型、检查间隔等
- **调试友好**：可选的调试信息显示
- **多应用支持**：同时支持多个应用程序的自动切换

## 快速开始

### 1. 引入库文件

```ahk
#Include Lib/AutoIMESwitcher.ahk
```

### 2. 基本设置

```ahk
; 在插件初始化函数中设置自动IME切换
AutoIMESwitcher.Setup("YourApp.exe", {
    enableDebug: false,
    checkInterval: 500,
    enableMouseClick: true,
    inputControlPatterns: ["Edit"],
    cursorTypes: ["IBeam", "Unknown"]
})
```

### 3. 在Before函数中使用

```ahk
YourApp_Before() {
    ; 使用AutoIMESwitcher处理输入状态检测和IME切换
    return AutoIMESwitcher.HandleBeforeAction("YourApp.exe")
}
```

## 配置选项详解

### Setup() 方法参数

```ahk
AutoIMESwitcher.Setup(processName, options)
```

**参数说明：**

- `processName` (字符串): 目标应用程序的进程名，如 "AfterFX.exe"
- `options` (对象): 配置选项对象

**配置选项：**

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enableDebug` | 布尔值 | `false` | 是否启用调试信息显示 |
| `checkInterval` | 数字 | `500` | 状态检查间隔（毫秒） |
| `enableMouseClick` | 布尔值 | `true` | 是否启用鼠标点击监听 |
| `inputControlPatterns` | 数组 | `["Edit"]` | 输入控件匹配模式 |
| `cursorTypes` | 数组 | `["IBeam", "Unknown"]` | 输入状态光标类型 |

## 使用示例

### 示例1：Visual Studio Code 插件

```ahk
/*
[PluginInfo]
PluginName=VSCode
Author=YourName
Version=1.0
Comment=Visual Studio Code
*/

#Include Lib/AutoIMESwitcher.ahk

VSCode() {
    ; 热键映射数组
    KeyArray := Array()
    KeyArray.push({ Key: "ctrl+s", Mode: "VIM模式", Group: "文件", Func: "SaveFile", Param: "", Comment: "保存文件" })
    
    ; 注册窗口
    vim.SetWin("VSCode", "", "Code.exe")
    
    ; 注册按键
    RegisterPluginKeys(KeyArray, "VSCode")
    
    ; 设置自动IME切换
    AutoIMESwitcher.Setup("Code.exe", {
        enableDebug: false,
        checkInterval: 300,
        enableMouseClick: true,
        inputControlPatterns: ["Edit", "RichEdit", "Scintilla"],
        cursorTypes: ["IBeam", "Unknown"]
    })
}

VSCode_Before() {
    return AutoIMESwitcher.HandleBeforeAction("Code.exe")
}
```

### 示例2：Photoshop 插件

```ahk
/*
[PluginInfo]
PluginName=Photoshop
Author=YourName
Version=1.0
Comment=Adobe Photoshop
*/

#Include Lib/AutoIMESwitcher.ahk

Photoshop() {
    ; 热键映射数组
    KeyArray := Array()
    KeyArray.push({ Key: "v", Mode: "VIM模式", Group: "工具", Func: "SelectMoveTool", Param: "", Comment: "移动工具" })
    
    ; 注册窗口
    vim.SetWin("Photoshop", "", "Photoshop.exe")
    
    ; 注册按键
    RegisterPluginKeys(KeyArray, "Photoshop")
    
    ; 设置自动IME切换（Photoshop有特殊的文本控件）
    AutoIMESwitcher.Setup("Photoshop.exe", {
        enableDebug: false,
        checkInterval: 400,
        enableMouseClick: true,
        inputControlPatterns: ["Edit", "TextEdit", "TypeTool"],
        cursorTypes: ["IBeam", "Unknown", "Text"]
    })
}

Photoshop_Before() {
    return AutoIMESwitcher.HandleBeforeAction("Photoshop.exe")
}
```

### 示例3：启用调试模式

```ahk
; 启用调试模式来观察检测过程
AutoIMESwitcher.Setup("YourApp.exe", {
    enableDebug: true,  ; 启用调试信息
    checkInterval: 500,
    enableMouseClick: true,
    inputControlPatterns: ["Edit", "RichEdit"],
    cursorTypes: ["IBeam", "Unknown"]
})
```

## 工作原理

### 触发机制

1. **窗口激活触发**：当从其他应用切换到目标应用时
2. **输入状态退出触发**：从输入控件或IBeam光标状态退出时
3. **光标状态变化触发**：鼠标光标从IBeam变为其他类型时
4. **焦点控件变化触发**：控件焦点变化且不在输入状态时
5. **鼠标点击触发**：点击非输入区域时立即检测
6. **VIM模式按键触发**：在Before函数中检测并切换

### 检测逻辑

```
是否在输入状态 = (控件匹配输入模式) OR (光标类型为输入类型)

如果不在输入状态 → 切换到英文输入法
如果在输入状态 → 保持当前输入法状态
```

## 高级用法

### 自定义输入控件检测

```ahk
; 为特殊应用自定义输入控件模式
AutoIMESwitcher.Setup("SpecialApp.exe", {
    inputControlPatterns: [
        "Edit",           ; 标准编辑框
        "RichEdit",       ; 富文本编辑框
        "Scintilla",      ; 代码编辑器
        "TextBox",        ; 自定义文本框
        "CustomInput"     ; 应用特有的输入控件
    ],
    cursorTypes: [
        "IBeam",          ; 标准文本光标
        "Unknown",        ; 未知状态（某些输入框）
        "Text",           ; 文本光标
        "Hand"            ; 某些特殊情况
    ]
})
```

### 多应用同时支持

```ahk
; 可以同时为多个应用设置自动IME切换
AutoIMESwitcher.Setup("App1.exe", { enableDebug: false })
AutoIMESwitcher.Setup("App2.exe", { enableDebug: false })
AutoIMESwitcher.Setup("App3.exe", { enableDebug: true })

; 在各自的Before函数中调用
App1_Before() {
    return AutoIMESwitcher.HandleBeforeAction("App1.exe")
}

App2_Before() {
    return AutoIMESwitcher.HandleBeforeAction("App2.exe")
}

App3_Before() {
    return AutoIMESwitcher.HandleBeforeAction("App3.exe")
}
```

## 故障排除

### 常见问题

1. **输入法切换不生效**
   - 确保已正确引入IME.ahk库
   - 检查进程名是否正确
   - 尝试启用调试模式观察检测过程

2. **检测不准确**
   - 调整`inputControlPatterns`以匹配应用的特殊控件
   - 添加应用特有的光标类型到`cursorTypes`
   - 调整`checkInterval`间隔

3. **性能问题**
   - 增大`checkInterval`值减少检查频率
   - 禁用`enableMouseClick`如果不需要鼠标点击检测

### 调试技巧

```ahk
; 启用调试模式观察状态
AutoIMESwitcher.Setup("YourApp.exe", {
    enableDebug: true,
    checkInterval: 1000  ; 增大间隔便于观察
})
```

调试信息会显示：
- 当前控件名称
- 当前光标类型
- 是否在输入状态
- 上次输入状态
- 触发的切换原因

## 最佳实践

1. **合理设置检查间隔**：平衡响应速度和性能
2. **精确配置控件模式**：根据应用特点调整检测规则
3. **适当使用调试模式**：开发时启用，发布时关闭
4. **测试多种场景**：确保各种输入退出情况都能正确处理

## 更新日志

### v1.0
- 初始版本
- 支持多重触发机制
- 支持多应用同时使用
- 提供完整的配置选项
- 包含调试功能

## 贡献

如果你发现问题或有改进建议，欢迎提交反馈。这个库的设计目标是为所有需要智能输入法切换的应用提供统一、可靠的解决方案。