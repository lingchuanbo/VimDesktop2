-- 背景设置为黑色
backgroundColor = color 0 0 0
-- 删除所有灯光
delete lights
-- 删除particle view
delete $' particle view *'
-- 设置默认渲染器
renderers.current = Default_Scanline_Renderer()
-- 设置渲染模式为Catmull_Rom 比较锐利清晰
scanlineRender.antiAliasFilter =Catmull_Rom()
-- 设置单位
units.DisplayType = #Metric 
units.MetricType = #Centimeters 
units.CustomUnit = #Centimeters
units.SystemType = #Centimeters 
-- units.SystemType = #inches 
-- 去环境贴图
useEnvironmentMap = off
-- 设置网格为10
units.SystemScale = 1 

SetGridSpacing(10)

rendAtmosphere = on --打开大气效果

rendSaveFile =on --打开保存选项