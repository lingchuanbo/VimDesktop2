# QuickSwitch 系列工具说明文档

## 概述

QuickSwitch 系列包含三个功能相关但各有特色的快速切换工具，均基于 AutoHotkey v2.0 开发。

## 工具列表

### 1. QuickSwitch.ahk - 统一快速切换工具
**功能描述：** 智能判断当前窗口类型，在普通窗口显示程序切换菜单，在文件对话框显示路径切换菜单。

**主要特性：**
- 🔄 **智能双模式**：同一快捷键在不同环境下显示不同菜单
- 🖥️ **程序窗口切换**：显示最近打开的程序，支持置顶显示
- 📁 **文件对话框路径切换**：在文件对话框中快速切换到文件管理器路径
- 🎨 **主题支持**：支持深色/浅色主题切换
- ⚡ **性能优化**：避免内存泄露，合理管理资源

**默认快捷键：**
- `Ctrl+Q` - 智能菜单显示
- `Ctrl+Tab` - 快速切换最近两个程序

**运行模式：**
- 全部运行（智能判断）
- 只运行路径跳转
- 只运行程序切换

### 2. QuickSwitchMu.ahk - 文件对话框路径切换专用工具
**功能描述：** 专门用于在文件对话框中快速切换到已打开的文件管理器路径。

**主要特性：**
- 📂 **文件管理器支持**：Total Commander、Windows Explorer、XYplorer、Directory Opus
- 🔖 **自定义路径**：支持添加常用路径到菜单
- 📝 **最近路径**：记录最近访问的路径
- 🎯 **自动切换模式**：可设置特定对话框自动切换到文件管理器路径
- 🎨 **菜单定制**：支持自定义菜单颜色、图标大小等

**默认快捷键：**
- `Ctrl+Q` - 显示路径切换菜单（仅在文件对话框中生效）

**支持的文件对话框：**
- 标准 Windows 文件对话框
- Blender 文件视图窗口
- 其他基于标准控件的文件对话框

### 3. QuickSwitchMuEx.ahk - 程序窗口切换专用工具
**功能描述：** 专门用于快速切换已打开的程序窗口，提供丰富的窗口管理功能。

**主要特性：**
- 🏆 **置顶程序**：重要程序可设置为置顶显示，带特殊标识
- 📊 **历史记录**：按最近使用顺序显示程序列表
- 🚫 **排除程序**：可设置不显示的系统程序
- ⚡ **快速访问**：支持数字/字母快捷键快速选择
- 🎯 **双程序切换**：快速在最近两个程序间切换
- 🔧 **程序管理**：支持关闭程序、添加/移除置顶等操作

**默认快捷键：**
- `Ctrl+Q` - 显示程序切换菜单
- `Ctrl+Tab` - 快速切换最近两个程序

## 配置文件说明

每个工具都有对应的 `.ini` 配置文件，支持以下配置：

### 通用配置项

```ini
[Settings]
; 主快捷键设置，支持 AutoHotkey 格式
; ^q (Ctrl+Q), ^j (Ctrl+J), !q (Alt+Q), #q (Win+Q)
Hotkey=^q

[Display]
; 菜单颜色（十六进制，如 C0C59C 或 Default）
MenuColor=Default
; 图标大小（像素）
IconSize=16
; 菜单显示位置
MenuPosX=100
MenuPosY=100
```

### QuickSwitch.ahk 特有配置

```ini
[Settings]
RunMode=0  ; 0=全部运行, 1=只运行路径跳转, 2=只运行程序切换

[WindowSwitchMenu]
Position=mouse  ; mouse=鼠标位置, fixed=固定位置

[PathSwitchMenu]
Position=fixed  ; mouse=鼠标位置, fixed=固定位置

[Theme]
DarkMode=0  ; 0=浅色主题, 1=深色主题
```

### QuickSwitchMu.ahk 特有配置

```ini
[FileManagers]
TotalCommander=1    ; 1=启用, 0=禁用
Explorer=1
XYplorer=1
DirectoryOpus=1

[CustomPaths]
EnableCustomPaths=1
MenuTitle=收藏路径
Path1=桌面|%USERPROFILE%\Desktop
Path2=文档|%USERPROFILE%\Documents

[RecentPaths]
EnableRecentPaths=1
MaxRecentPaths=10

[Dialogs]
; 对话框自动切换设置
; 格式：进程名___窗口标题=1（自动切换）或0（禁用）
blender.exe___Blender File View=1
```

### QuickSwitchMuEx.ahk 特有配置

```ini
[Settings]
MaxHistoryCount=10  ; 最大历史记录数量
EnableQuickAccess=1 ; 启用快速访问键
QuickAccessKeys=123456789abcdefghijklmnopqrstuvwxyz

[ExcludedApps]
App1=explorer.exe   ; 排除的程序
App2=dwm.exe

[PinnedApps]
App1=notepad.exe    ; 置顶显示的程序
App2=chrome.exe
```

## 使用建议

### 选择合适的工具

1. **如果你需要统一的切换体验**：选择 `QuickSwitch.ahk`
   - 一个快捷键解决所有切换需求
   - 智能判断当前环境
   - 功能最全面

2. **如果你主要需要文件对话框路径切换**：选择 `QuickSwitchMu.ahk`
   - 专门优化的文件对话框支持
   - 丰富的文件管理器集成
   - 自定义路径管理

3. **如果你主要需要程序窗口切换**：选择 `QuickSwitchMuEx.ahk`
   - 专门的程序管理功能
   - 置顶程序支持
   - 快速访问键

### 组合使用

你也可以同时运行多个工具，但需要注意：
- 避免快捷键冲突
- 建议修改配置文件中的快捷键设置
- 推荐使用 `QuickSwitch.ahk` 作为主工具

## 故障排除

### 常见问题

1. **快捷键不生效**
   - 检查是否有其他程序占用相同快捷键
   - 尝试修改配置文件中的快捷键设置
   - 以管理员权限运行

2. **文件管理器路径获取失败**
   - 确保文件管理器正在运行
   - 检查文件管理器版本兼容性
   - 查看配置文件中的文件管理器启用状态

3. **菜单显示异常**
   - 检查配置文件格式是否正确
   - 尝试删除配置文件让程序重新生成
   - 检查系统主题设置

### 配置文件修复

如果配置文件损坏，可以：
1. 删除对应的 `.ini` 文件
2. 重新运行程序
3. 程序会自动生成默认配置文件

## 更新日志

### v1.1 (QuickSwitch.ahk)
- 添加主题支持
- 优化内存管理
- 改进文件对话框检测

### v1.0 (QuickSwitchMu.ahk)
- 初始版本
- 支持多种文件管理器
- 自定义路径功能

### v1.0 (QuickSwitchMuEx.ahk)
- 初始版本
- 程序窗口切换
- 置顶程序支持

## 技术信息

- **开发语言**：AutoHotkey v2.0
- **系统要求**：Windows 10/11
- **依赖库**：WindowsTheme.ahk（仅 QuickSwitch.ahk）
- **许可证**：开源

## 作者信息

- **作者**：BoBO
- **版本**：见各工具文件头部注释
- **更新时间**：2024年

---

*如有问题或建议，请查看配置文件注释或联系作者。*