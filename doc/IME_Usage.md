# IME 输入法管理库使用说明

本库从 InputTip 项目中提取了核心的 IME（输入法）管理功能，提供了获取和切换输入法状态的完整解决方案。

## 功能特性

- 获取当前输入法状态（中文/英文）
- 切换输入法到指定状态
- 获取详细的输入法状态信息
- 支持多种输入法和键盘布局
- 提供简单易用的函数接口

## 快速开始

### 1. 引入库文件

```ahk
#Include Lib/IME.ahk

; 设置必要的前置条件
DetectHiddenWindows 1
SetStoreCapsLockMode 0
```

### 2. 基本使用

```ahk
; 检查当前输入法是否为中文
if (isCN()) {
    MsgBox("当前是中文输入法")
} else {
    MsgBox("当前是英文输入法")
}

; 切换到中文输入法
switch_CN()

; 切换到英文输入法
switch_EN()

; 切换输入法状态
IME_Toggle()
```

## API 参考

### 类方法 (IME 类)

#### IME.GetInputMode([hwnd])
获取当前输入法输入模式
- **参数**: `hwnd` - 窗口句柄（可选，默认为当前焦点窗口）
- **返回值**: `1` 表示中文，`0` 表示英文

#### IME.SetInputMode(mode [, hwnd])
设置输入法到指定状态
- **参数**: 
  - `mode` - 要设置的状态（1: 中文，0: 英文）
  - `hwnd` - 窗口句柄（可选）

#### IME.ToggleInputMode([hwnd])
切换输入法状态
- **参数**: `hwnd` - 窗口句柄（可选）

#### IME.CheckInputMode([hwnd])
获取详细的输入法状态信息
- **参数**: `hwnd` - 窗口句柄（可选）
- **返回值**: 包含 `statusMode` 和 `conversionMode` 的对象

#### IME.GetKeyboardLayoutList()
获取系统中所有可用的键盘布局
- **返回值**: 键盘布局标识符数组

### 便捷函数

#### isCN()
判断当前输入法是否为中文
- **返回值**: `1` 表示中文，`0` 表示英文

#### switch_CN()
切换到中文输入法
- 自动处理大写锁定状态

#### switch_EN()
切换到英文输入法
- 自动处理大写锁定状态

#### IME_Toggle()
切换输入法状态（中文↔英文）

#### getIMEStatus()
获取输入法状态信息
- **返回值**: 包含状态码和转换码的对象

## 配置选项

### IME 类静态属性

```ahk
; 设置超时时间（毫秒）
IME.checkTimeout := 1000

; 设置默认基础状态（0: 英文，1: 中文）
IME.baseStatus := 0

; 设置工作模式（1: 简单模式，0: 自定义模式）
IME.mode := 1

; 自定义模式规则（仅在 mode = 0 时有效）
IME.modeRules := ["0*1*1", "1*0*0"]  ; 示例规则
```

## 使用示例

### 示例 1: 基本状态检测和切换

```ahk
#Include Lib/IME.ahk
DetectHiddenWindows 1

; 热键：F1 显示当前状态
F1::{
    status := isCN() ? "中文" : "英文"
    MsgBox("当前输入法: " . status)
}

; 热键：F2 切换到中文
F2::switch_CN()

; 热键：F3 切换到英文
F3::switch_EN()

; 热键：F4 切换状态
F4::IME_Toggle()
```

### 示例 2: 应用程序特定的输入法切换

```ahk
#Include Lib/IME.ahk
DetectHiddenWindows 1

; 当激活记事本时自动切换到中文
#HotIf WinActive("ahk_class Notepad")
~LButton::switch_CN()
#HotIf

; 当激活 VS Code 时自动切换到英文
#HotIf WinActive("ahk_exe Code.exe")
~LButton::switch_EN()
#HotIf
```

### 示例 3: 详细状态监控

```ahk
#Include Lib/IME.ahk
DetectHiddenWindows 1

; 每秒检查一次输入法状态
SetTimer(CheckIMEStatus, 1000)

CheckIMEStatus() {
    status := getIMEStatus()
    currentMode := isCN() ? "中文" : "英文"
    
    ; 在托盘提示中显示状态
    A_IconTip := "输入法: " . currentMode . " (状态码: " . status.statusMode . ")"
}
```

## 注意事项

1. **前置条件**: 使用前必须设置 `DetectHiddenWindows 1` 和 `SetStoreCapsLockMode 0`
2. **权限要求**: 某些应用程序可能需要管理员权限才能正确检测和切换输入法
3. **兼容性**: 主要支持 Windows 系统的标准输入法，对第三方输入法的支持可能有限
4. **性能**: 频繁调用状态检测函数可能会影响性能，建议适当控制调用频率

## 故障排除

### 常见问题

1. **无法检测输入法状态**
   - 确保设置了 `DetectHiddenWindows 1`
   - 检查是否有足够的权限访问目标窗口

2. **切换输入法失败**
   - 确保设置了 `SetStoreCapsLockMode 0`
   - 检查目标应用程序是否支持输入法切换

3. **状态检测不准确**
   - 尝试调整 `IME.checkTimeout` 值
   - 考虑使用自定义模式并配置相应的规则

### 调试技巧

```ahk
; 启用详细的状态信息显示
F12::{
    status := getIMEStatus()
    info := "输入法状态调试信息:`n"
    info .= "当前模式: " . (isCN() ? "中文" : "英文") . "`n"
    info .= "状态码: " . status.statusMode . "`n"
    info .= "转换码: " . status.conversionMode . "`n"
    info .= "键盘布局: " . Format("0x{:08X}", IME.GetKeyboardLayout())
    MsgBox(info, "IME 调试信息")
}
```

## 更多信息

- 原始项目: [InputTip](https://github.com/abgox/InputTip)
- 相关文档: 查看 `IME_Example.ahk` 获取完整的使用示例