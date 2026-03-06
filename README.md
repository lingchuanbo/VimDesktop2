# VimDesktop

基于 AHK v2 的桌面键盘增强工具，提供类 Vim 的键位体系、插件化扩展与稳定的热重载能力。适合在 Windows 下统一操作习惯、快速控制各类应用与窗口。

## 主要特性
- 插件体系标准化：`plugins/<PluginName>/plugin.meta.ini` 管理元信息，入口自动生成
- 双层启停控制：`[plugins]` 作为总开关，`[PluginName] enabled` 作为插件优先开关
- 热重载与局部刷新：只刷新变更部分，避免全量重载
- 配置校验：定位到具体文件/分节/键名
- 扩展管理：支持独立进程扩展与自动启停
- 托盘菜单：快速访问常用操作与状态

## 快速开始
1. 运行 `vimd.exe` 或 `vimd.bat`
2. 主配置文件：`config/vimd.ini`
3. 自定义脚本：`config/Custom.ahk`

## 目录结构
- `src`：入口与核心模块
- `libs`：公共库与工具
- `plugins`：插件目录与入口聚合
- `config`：配置与自定义脚本
- `docs`：文档与示例
- `lang`：语言包
- `apps`：附加小工具（可忽略）

## 配置说明
- 总开关：`[plugins] <PluginName>=1/0`
- 插件开关：`[PluginName] enabled=1/0`（优先级更高）
- 插件默认模式：`[plugins_DefaultMode] <PluginName>=normal/insert/...`

## 插件体系
- 入口聚合：`plugins/plugins.ahk`（由 `plugins/check.ahk` 生成）
- 元信息：`plugins/<PluginName>/plugin.meta.ini`
- 修改元信息或入口后，执行 `plugins/check.ahk` 重新生成入口

## 热重载
- 修改 `config/vimd.ini` 后会触发局部刷新
- 仅变更的分节与键会被应用，避免重建全部映射

## 配置校验
- 运行校验后可生成详细报告
- 报告包含文件、分节、键名与问题描述

## 运行环境
- AutoHotkey v2（默认路径：`C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`）

## 相关文档
- `docs/插件配置独立化说明.md`
- `docs/扩展功能使用说明.md`
- `docs/按键提示自动隐藏功能说明.md`

如需发布包、更新日志或更多示例，可继续扩展 `docs`。
