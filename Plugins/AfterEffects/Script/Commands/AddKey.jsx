// 功能 : 快速 K 帧
// 基础属性 如果前面已经K帧了 后面继续 K上
// by BoBO
(function () {
    // 开始撤销组，方便用户撤销整个操作
    app.beginUndoGroup("只处理已有关键帧属性（含效果）");

    // 获取当前活动合成
    var comp = app.project.activeItem;
    if (!(comp instanceof CompItem)) {
        alert("请选择一个合成");
        return;
    }

    // 获取选中的图层
    var selLayers = comp.selectedLayers;
    if (selLayers.length === 0) {
        alert("请先选中至少一个图层");
        return;
    }

    var t = comp.time; // 当前时间

    // 递归处理属性，包含效果属性
    function processProperty(prop) {
        // 处理属性组（包括效果组）
        if (prop.propertyType === PropertyType.PROPERTY_GROUP || 
            prop.propertyType === PropertyType.INDEXED_GROUP || 
            prop.propertyType === PropertyType.NAMED_GROUP) {
            
            // 递归处理组中的每个属性
            for (var i = 1; i <= prop.numProperties; i++) {
                processProperty(prop.property(i));
            }
        } 
        // 处理普通属性（包括效果属性）
        else if (prop.propertyType === PropertyType.PROPERTY) {
            // 只处理已经有关键帧的属性
            if (prop.canSetExpression && prop.numKeys > 0) {
                try {
                    var nearestIndex = prop.nearestKeyIndex(t);
                    var nearestTime = prop.keyTime(nearestIndex);
                    var threshold = (1.0 / comp.frameRate) / 2; // 时间容差

                    // 检查当前时间点是否已有关键帧
                    if (Math.abs(nearestTime - t) < threshold) {
                        // 更新已有关键帧
                        prop.setValueAtKey(nearestIndex, prop.value);
                    } else {
                        // 在当前时间点添加新关键帧
                        prop.setValueAtTime(t, prop.value);
                    }
                } catch (err) {
                    // 跳过无法设置关键帧的属性
                }
            }
        }
    }

    // 处理每个选中图层及其效果
    for (var i = 0; i < selLayers.length; i++) {
        var layer = selLayers[i];
        
        // 处理图层本身属性
        processProperty(layer);
        
        // 处理图层上的所有效果
        if (layer.effect && layer.effect.numProperties > 0) {
            for (var e = 1; e <= layer.effect.numProperties; e++) {
                processProperty(layer.effect(e));
            }
        }
    }

    // 结束撤销组
    app.endUndoGroup();
})();