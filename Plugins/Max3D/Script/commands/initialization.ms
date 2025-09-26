-- 3DsMax 初始化工具 - 带GUI界面
-- 作者: BoBO
-- 创建日期: 2024年

-- 全局变量
global MaxInitRollout

-- 主界面定义
rollout MaxInitRollout "3DsMax 初始化工具" width:300 height:400
(
    group "显示设置"
    (
        checkbox chkBackground "黑色背景" checked:true align:#left
        checkbox chkGrid "设置网格" checked:true align:#left
        spinner spnGridValue "网格值:" range:[1,1000,10] type:#integer width:60 align:#left offset:[80,-20]
        checkbox chkAtmosphere "开启大气效果" checked:true align:#left
        checkbox chkSaveFile "开启保存选项" checked:true align:#left
        checkbox chkGradientColors "使用渐变颜色" checked:true align:#left
        checkbox chkHighQualityLighting "高质量视口照明和阴影" checked:true align:#left
    )
    
    group "场景清理"
    (
        checkbox chkDeleteLights "删除所有灯光" checked:true align:#left
        checkbox chkDeleteParticleView "删除粒子视图" checked:true align:#left
    )
    
    group "渲染设置"
    (
        checkbox chkDefaultRenderer "默认扫描线渲染器" checked:true align:#left
        checkbox chkCatmullRom "Catmull-Rom抗锯齿" checked:true align:#left
        checkbox chkEnvMap "关闭环境贴图" checked:true align:#left
    )
    
    -- 单位设置已独立到单独脚本
    
    group "操作"
    (
        button btnApply "应用" width:80 height:30 align:#center pos:[10, 330] tooltip:"按回车键快速应用设置"
        button btnReset "重置" width:60 height:30 align:#center pos:[95, 330]
        button btnClose "关闭" width:80 height:30 align:#center pos:[160, 330] tooltip:"按ESC键快速关闭"
    )
    
    label lblStatus "" align:#left height:20
    
    -- 键盘事件处理 - 使用定时器检测
    on MaxInitRollout open do
    (
        format "对话框已打开，启动键盘监听\n"
        
        -- 重置键盘状态
        lastEnterState = false
        lastEscState = false
        
        -- 启动键盘检测定时器
        try
        (
            keyHookTimer = dotNetObject "System.Windows.Forms.Timer"
            keyHookTimer.Interval = 100  -- 100毫秒检测一次
            keyHookTimer.add_Tick checkKeyboardState
            keyHookTimer.Start()
            format "键盘监听定时器已启动\n"
        )
        catch(ex)
        (
            format "启动键盘监听失败: %\n" ex
        )
    )
    
    on MaxInitRollout close do
    (
        format "对话框关闭，停止键盘监听\n"
        -- 停止键盘检测定时器
        try
        (
            if keyHookTimer != undefined then
            (
                keyHookTimer.Stop()
                keyHookTimer.Dispose()
                keyHookTimer = undefined
                format "键盘监听定时器已停止\n"
            )
        )
        catch(ex)
        (
            format "停止键盘监听失败: %\n" ex
        )
    )
    
    -- 应用设置函数
    on btnApply pressed do
    (
        try
        (
            -- 显示设置
            if chkBackground.checked then
            (
                backgroundColor = color 0 0 0
                lblStatus.text = "已设置黑色背景"
            )
            
            if chkGrid.checked then
            (
                units.SystemScale = 1
                SetGridSpacing(spnGridValue.value)
                lblStatus.text = lblStatus.text + " | 网格设置为" + (spnGridValue.value as string)
            )
            
            if chkAtmosphere.checked then
            (
                rendAtmosphere = on
                lblStatus.text = lblStatus.text + " | 开启大气效果"
            )
            
            if chkSaveFile.checked then
            (
                rendSaveFile = on
                lblStatus.text = lblStatus.text + " | 开启保存选项"
            )
            
            if chkGradientColors.checked then
            (
                actionMan.executeAction 0 "617"  -- Tools: Use Gradient Colors Toggle
                lblStatus.text = lblStatus.text + " | 使用渐变颜色"
            )
            
            if chkHighQualityLighting.checked then
            (
                actionMan.executeAction -844228238 "12"  -- Viewport Lighting and Shadows: High Quality
                lblStatus.text = lblStatus.text + " | 高质量视口照明和阴影"
            )
            
            -- 场景清理
            if chkDeleteLights.checked then
            (
                delete lights
                lblStatus.text = lblStatus.text + " | 删除所有灯光"
            )
            
            if chkDeleteParticleView.checked then
            (
                try(delete $' particle view *') catch()
                lblStatus.text = lblStatus.text + " | 删除粒子视图"
            )
            
            -- 渲染设置
            if chkDefaultRenderer.checked then
            (
                renderers.current = Default_Scanline_Renderer()
                lblStatus.text = lblStatus.text + " | 设置默认渲染器"
            )
            
            if chkCatmullRom.checked then
            (
                scanlineRender.antiAliasFilter = Catmull_Rom()
                lblStatus.text = lblStatus.text + " | 设置Catmull-Rom抗锯齿"
            )
            
            if chkEnvMap.checked then
            (
                useEnvironmentMap = off
                lblStatus.text = lblStatus.text + " | 关闭环境贴图"
            )
            
            -- 单位设置已独立到单独脚本
            
            messageBox "3DsMax初始化设置已成功应用！" title:"初始化完成"
        )
        catch
        (
            messageBox ("应用设置时出错: " + getCurrentException()) title:"错误"
        )
    )
    
    -- 重置为默认设置
    on btnReset pressed do
    (
        chkBackground.checked = true
        chkGrid.checked = true
        spnGridValue.value = 10
        chkAtmosphere.checked = true
        chkSaveFile.checked = true
        chkGradientColors.checked = false
        chkHighQualityLighting.checked = false
        chkDeleteLights.checked = true
        chkDeleteParticleView.checked = true
        chkDefaultRenderer.checked = true
        chkCatmullRom.checked = true
        chkEnvMap.checked = true
        lblStatus.text = "已重置为默认设置"
    )
    
    -- 关闭窗口
    on btnClose pressed do
    (
        -- 停止键盘检测定时器
        try
        (
            if keyHookTimer != undefined then
            (
                keyHookTimer.Stop()
                keyHookTimer.Dispose()
                keyHookTimer = undefined
                format "手动关闭时停止键盘监听\n"
            )
        )
        catch()
        
        try(destroyDialog MaxInitRollout) catch()
    )
)

-- 创建浮动窗口函数
fn createMaxInitDialog = 
(
    try
    (
        -- 如果窗口已存在，先销毁
        try(destroyDialog MaxInitRollout) catch()
        
        -- 创建新窗口，确保能够接收键盘事件
        createDialog MaxInitRollout style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing) modal:false
        
        -- 多种方法确保窗口获得焦点以接收键盘事件
        setFocus MaxInitRollout
        windows.sendMessage MaxInitRollout.hwnd 0x0007 0 0 -- WM_SETFOCUS
        
        -- 强制设置窗口为前台窗口
        try(windows.setForegroundWindow MaxInitRollout.hwnd) catch()
        
        -- 设置窗口位置（屏幕中央）
        screenWidth = sysInfo.desktopSize[1]
        screenHeight = sysInfo.desktopSize[2]
        dialogWidth = 320
        dialogHeight = 500
        
        setDialogPos MaxInitRollout [(screenWidth - dialogWidth) / 2, (screenHeight - dialogHeight) / 2]
        
        -- messageBox "3DsMax初始化工具已启动！\n选择需要的选项后点击'应用设置'。" title:"工具启动"
    )
    catch
    (
        messageBox ("创建窗口时出错: " + getCurrentException()) title:"错误"
    )
)

-- 主启动函数
fn startMaxInitializationTool = 
(
    createMaxInitDialog()
)

-- 宏脚本定义，便于添加到3DsMax菜单

-- 自动启动界面
startMaxInitializationTool()

-- 使用说明
print "=========================================="
print "3DsMax 初始化工具 已启动"
print "GUI界面已自动弹出"
print "=========================================="
