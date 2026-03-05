**特别说明**

此版本基于 [vimdesktop2](https://github.com/kawvin/VimDesktop2) 的优化版。

**快速启动**
1. 运行 `vimd.bat` 或 `vimd.exe`
2. 主配置文件：`config/vimd.ini`
3. 自定义脚本：`config/Custom.ahk`

**目录结构**
- `src`：入口与核心模块
- `libs`：公共库与工具类
- `plugins`：插件目录
- `config`：配置与自定义
- `apps`：附加工具
- `docs`：文档与示例
- `lang`：语言包

**开发提示**
- 入口脚本：`src/vimd.ahk`
- 插件入口集合：`plugins/plugins.ahk`（由 `plugins/check.ahk` 自动生成）
- 可选插件元信息：`plugins/<PluginName>/plugin.meta.ini`（可自定义入口文件，修改后会自动刷新入口）
