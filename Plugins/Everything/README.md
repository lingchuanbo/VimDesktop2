# Everything插件配置说明

## 配置文件位置
`Plugins/Everything/everything.ini`

## 配置项说明

### [Everything]
- `everything_path`: Everything程序的完整路径
- `enable_double_click`: 是否启用桌面双击启动Everything功能 (true/false)
- `show_debug_info`: 是否显示调试信息 (true/false)

## 配置示例
```ini
[Everything]
everything_path = D:\BoBO\WorkFlow\tools\TotalCMD\Tools\Everything\Everything.exe
; 桌面双击启动Everything功能开关 (true/false)
enable_double_click = true
; 调试信息显示开关 (true/false)
show_debug_info = false
```

## 快捷键配置管理

在Everything窗口中，按Insert进入VIM模式后：

- `cd` - 切换桌面双击启动功能的开启/关闭
- `ci` - 切换调试信息显示的开启/关闭
- `i` - 显示所有可用按键帮助

## 功能说明

### 桌面双击启动 (enable_double_click)
- `true`: 启用桌面空白处双击启动Everything
- `false`: 禁用桌面双击功能

支持的双击区域：
- 桌面空白处
- 任务栏空白处  
- 文件夹空白处

### 调试信息 (show_debug_info)
- `true`: 双击时显示检测信息（窗口类、控件名、AccName等）
- `false`: 不显示调试信息

## 注意事项

1. 修改配置文件后需要重新加载插件才能生效
2. 如果AccName获取失败，会自动回退到简单检测模式
3. 配置文件使用UTF-8编码，支持中文注释
4. 程序路径支持相对路径和绝对路径

## 故障排除

如果双击功能不工作：
1. 检查 `enable_double_click` 是否为 `true`
2. 设置 `show_debug_info = true` 查看检测信息
3. 确认Everything程序路径是否正确
4. 检查是否有安全软件阻止了辅助功能API