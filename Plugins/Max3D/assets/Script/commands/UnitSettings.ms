-- 3DsMax 单位设置工具 - 独立脚本
-- 作者: BoBO
-- 创建日期: 2024年
-- 优化版本: 显示当前系统单位，下面显示修改属性

-- 全局变量
global UnitSettingsRollout

-- 获取当前单位显示文本的函数
fn getCurrentUnitDisplayText = 
(
    local unitText = ""
    try
    (
        case units.SystemType of
        (
            #Millimeters: unitText = "毫米"
            #Centimeters: unitText = "厘米"
            #Meters: unitText = "米"
            #Kilometers: unitText = "千米"
            #Inches: unitText = "英寸"
            #Feet: unitText = "英尺"
            #Miles: unitText = "英里"
            default: unitText = "未知单位"
        )
        
        local displayTypeText = ""
        case units.DisplayType of
        (
            #Generic: displayTypeText = "通用"
            #Metric: displayTypeText = "公制"
            #US: displayTypeText = "美制"
            default: displayTypeText = "未知"
        )
        
        return "当前系统单位: " + unitText + " (" + displayTypeText + ")"
    )
    catch
    (
        return "当前系统单位: 无法获取"
    )
)

-- 主界面定义
rollout UnitSettingsRollout "3DsMax 单位设置工具 v1.0" width:350 height:250
(
    group "当前系统单位"
    (
        label lblCurrentUnit "当前系统单位: 正在获取..." align:#left height:25
        label lblCurrentDetails "详细信息: 正在获取..." align:#left height:20
    )
    
    group "单位系统设置"
    (
        radiobuttons rdoUnits "单位系统:" labels:#("厘米", "米", "英寸") default:1 align:#left
        checkbox chkMetricDisplay "公制显示" checked:true align:#left
    )
    

    
    group "操作"
    (
        button btnApply "应用" width:60 height:30 align:#center pos:[10, 190]
        button btnReset "重置" width:60 height:30 align:#center pos:[70, 190]
        button btnClose "关闭" width:60 height:30 align:#center pos:[130, 190]
    )
    
    label lblStatus "" align:#left height:20
    
    -- 更新当前单位显示的函数
    fn updateCurrentUnitDisplay = 
    (
        lblCurrentUnit.text = getCurrentUnitDisplayText()
        
        local detailsText = ""
        try
        (
            detailsText = "系统类型: " + units.SystemType as string + " | "
            detailsText += "显示类型: " + units.DisplayType as string + " | "
            detailsText += "公制类型: " + units.MetricType as string
        )
        catch
        (
            detailsText = "详细信息: 无法获取"
        )
        lblCurrentDetails.text = detailsText
    )
    
    -- 窗口打开时初始化显示
    on UnitSettingsRollout open do
    (
        updateCurrentUnitDisplay()
    )
    
    -- 应用单位设置函数
    on btnApply pressed do
    (
        try
        (
            -- 单位设置
            case rdoUnits.state of
            (
                1: -- 厘米
                (
                    units.DisplayType = #Metric 
                    units.MetricType = #Centimeters 
                    units.CustomUnit = #Centimeters
                    units.SystemType = #Centimeters
                    lblStatus.text = "单位设置为厘米"
                )
                2: -- 米
                (
                    units.DisplayType = #Metric 
                    units.MetricType = #Meters 
                    units.CustomUnit = #Meters
                    units.SystemType = #Meters
                    lblStatus.text = "单位设置为米"
                )
                3: -- 英寸
                (
                    units.DisplayType = #US 
                    units.SystemType = #Inches
                    lblStatus.text = "单位设置为英寸"
                )
            )
            
            if chkMetricDisplay.checked then
            (
                units.DisplayType = #Metric
                lblStatus.text = lblStatus.text + " | 公制显示"
            )
            
            updateCurrentUnitDisplay()
            
            messageBox "单位设置已成功应用！" title:"单位设置完成"
        )
        catch
        (
            messageBox ("应用单位设置时出错: " + getCurrentException()) title:"错误"
        )
    )
    
    -- 重置为默认设置
    on btnReset pressed do
    (
        rdoUnits.state = 1
        chkMetricDisplay.checked = true
        lblStatus.text = "已重置为默认设置（厘米）"
        updateCurrentUnitDisplay()
    )
    
    -- 关闭窗口
    on btnClose pressed do
    (
        try(destroyDialog UnitSettingsRollout) catch()
    )
)

-- 创建浮动窗口函数
fn createUnitSettingsDialog = 
(
    try
    (
        -- 如果窗口已存在，先销毁
        try(destroyDialog UnitSettingsRollout) catch()
        
        -- 创建新窗口
        createDialog UnitSettingsRollout style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)
        
        -- 设置窗口位置（屏幕中央）
        screenWidth = sysInfo.desktopSize[1]
        screenHeight = sysInfo.desktopSize[2]
        dialogWidth = 370
        dialogHeight = 310
        
        setDialogPos UnitSettingsRollout [(screenWidth - dialogWidth) / 2, (screenHeight - dialogHeight) / 2]
        
        -- messageBox "3DsMax单位设置工具已启动！" title:"工具启动"
    )
    catch
    (
        messageBox ("创建窗口时出错: " + getCurrentException()) title:"错误"
    )
)

-- 主启动函数
fn startUnitSettingsTool = 
(
    createUnitSettingsDialog()
)
-- 自动启动界面
startUnitSettingsTool()