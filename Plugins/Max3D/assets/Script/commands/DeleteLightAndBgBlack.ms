backgroundColor = color 0 0 0 -- 背景设置为黑色
delete lights -- 删除所有灯光
actionMan.executeAction -844228238 "13"  -- Viewport Lighting and Shadows: Standard
actionMan.executeAction -844228238 "12"  -- Viewport Lighting and Shadows: High Quality
actionMan.executeAction 0 "63566"  -- Views: Default Shading
actionMan.executeAction 0 "618"  -- Tools: Use Solid Colors Toggle
SetGridSpacing(10)