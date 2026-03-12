# WindowHighlight - 窗口边框高亮显示工具

## 功能概述

WindowHighlight 是一个基于 AutoHotkey v2.0 开发的窗口边框高亮显示工具，能够为当前活动窗口添加彩色边框，帮助用户快速识别当前焦点窗口。

### 主要特性

- **实时高亮**：自动检测活动窗口并显示彩色边框
- **双模式支持**：针对不同程序提供 V1 和 V2 两种显示模式
- **高度可配置**：支持边框颜色、宽度、透明度等多项自定义设置
- **智能过滤**：可配置排除特定程序，避免不必要的高亮显示
- **兼容性模式**：针对老旧程序提供特殊兼容处理
- **轻量级设计**：优化内存使用，最小化系统资源占用

## 安装与使用

### 系统要求
- Windows 10/11
- AutoHotkey v2.0 或更高版本

### 快速开始
1. 确保已安装 AutoHotkey v2.0
2. 双击运行 `WindowHighlight.ahk`
3. 程序将在系统托盘中显示图标
4. 切换不同窗口即可看到边框高亮效果

### 基本操作
- **F12**：快速开关高亮功能
- **右键托盘图标**：访问菜单选项
  - 开关高亮：启用/禁用高亮功能
  - 重新加载：重新加载配置文件
  - 退出：关闭程序

## 配置说明

配置文件：`WindowHighlight.ini`

### [Settings] 基本设置

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `BorderColor` | 十六进制颜色 | `0x12ED93` | 边框颜色，格式：0xRRGGBB |
| `BorderWidth` | 整数 | `2` | 边框宽度（像素） |
| `Opacity` | 整数 | `255` | 边框透明度（0-255，255为完全不透明） |
| `UpdateInterval` | 整数 | `20` | 检测间隔（毫秒，值越小响应越快但占用资源越多） |
| `Enabled` | 布尔值 | `1` | 启动时是否启用高亮（1=启用，0=禁用） |
| `ShowDialogs` | 布尔值 | `1` | 是否为对话框显示高亮 |
| `CompatibilityMode` | 布尔值 | `1` | 兼容性模式，针对老旧程序优化 |

#### 颜色配置示例
```ini
BorderColor=0xFF0000  ; 红色
BorderColor=0x00FF00  ; 绿色
BorderColor=0x0000FF  ; 蓝色
BorderColor=0xFFFF00  ; 黄色
BorderColor=0xFF00FF  ; 紫色
BorderColor=0x00FFFF  ; 青色
```

### [V1Programs] V1模式程序列表

针对某些特殊程序使用 V1 显示模式（Region 方法），通常用于解决兼容性问题。

| 程序 | 默认值 | 说明 |
|------|--------|------|
| `Photoshop.exe` | `1` | Adobe Photoshop |
| `Weixin.exe` | `1` | 微信 |
| `TIM.exe` | `0` | 腾讯 TIM |

```ini
[V1Programs]
Photoshop.exe=1  ; 使用V1模式
Weixin.exe=1     ; 使用V1模式
TIM.exe=0        ; 使用V2模式
```

### [ExcludePrograms] 排除程序列表

完全排除特定程序，不显示任何高亮效果。

| 程序 | 默认值 | 说明 |
|------|--------|------|
| `explorer.exe` | `0` | Windows 资源管理器 |
| `taskmgr.exe` | `0` | 任务管理器 |
| `cmd.exe` | `1` | 命令提示符 |
| `powershell.exe` | `1` | PowerShell |
| `conhost.exe` | `1` | 控制台宿主进程 |
| `TIM.exe` | `1` | 腾讯 TIM |

```ini
[ExcludePrograms]
explorer.exe=0    ; 不排除
taskmgr.exe=0     ; 不排除
cmd.exe=1         ; 排除
powershell.exe=1  ; 排除
conhost.exe=1     ; 排除
```

## 高级配置

### 性能优化

**低性能设备推荐配置：**
```ini
[Settings]
UpdateInterval=50     ; 降低检测频率
BorderWidth=1         ; 减少边框宽度
Opacity=200          ; 适当降低透明度
```

**高性能设备推荐配置：**
```ini
[Settings]
UpdateInterval=10     ; 提高响应速度
BorderWidth=3         ; 增加边框宽度
Opacity=255          ; 完全不透明
```

### 自定义排除规则

如需排除更多程序，可在 `[ExcludePrograms]` 节中添加：

```ini
[ExcludePrograms]
notepad.exe=1         ; 排除记事本
calc.exe=1            ; 排除计算器
mspaint.exe=1         ; 排除画图
```

### 添加 V1 模式程序

如果某个程序显示异常，可尝试将其添加到 V1 模式：

```ini
[V1Programs]
YourProgram.exe=1     ; 替换为实际程序名
```

## 技术说明

### 显示模式差异

**V2 模式（默认）：**
- 使用单个 GUI 窗口 + Region 技术
- 性能更好，内存占用更少
- 适用于大多数现代程序

**V1 模式（兼容）：**
- 使用 Region 方法创建边框
- 针对特殊程序的兼容性优化
- 适用于某些老旧或特殊的程序

### 窗口检测机制

程序通过以下步骤检测和显示边框：

1. **定时检测**：每隔指定间隔检测活动窗口
2. **窗口过滤**：根据配置过滤不需要高亮的窗口
3. **模式选择**：根据程序类型选择 V1 或 V2 显示模式
4. **精确定位**：使用 DWM API 获取窗口精确位置
5. **边框绘制**：创建并显示彩色边框

## 故障排除

### 常见问题

**Q: 某些程序不显示边框？**
A: 检查该程序是否在排除列表中，或尝试将其添加到 V1 模式列表。

**Q: 边框显示不准确？**
A: 尝试启用兼容性模式，或将程序添加到 V1 模式列表。

**Q: 程序占用资源过高？**
A: 增加 `UpdateInterval` 值，减少检测频率。

**Q: 边框闪烁？**
A: 检查是否有其他窗口管理工具冲突，或尝试调整透明度设置。

### 调试模式

如需调试，可以临时修改代码中的错误处理部分，查看具体错误信息。

## 版本信息

- **版本**：v1.0
- **作者**：BoBO
- **发布日期**：2025年8月7日
- **兼容性**：AutoHotkey v2.0+

## 许可证

本工具遵循开源许可证，可自由使用和修改。

---

*如有问题或建议，请联系开发者或提交 Issue。*