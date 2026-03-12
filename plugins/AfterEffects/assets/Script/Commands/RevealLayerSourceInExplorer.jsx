// AE 脚本：定位选中素材的本地位置（支持时间线图层 & 项目面板）
(function () {
    var proj = app.project;
    if (!proj) {
        alert("没有打开的项目");
        return;
    }

    var itemsToProcess = [];

    // 1. 优先检查时间线上选中的图层
    var comp = app.project.activeItem;
    if (comp && comp instanceof CompItem && comp.selectedLayers.length > 0) {
        for (var i = 0; i < comp.selectedLayers.length; i++) {
            var layer = comp.selectedLayers[i];
            if (layer.source && layer.source instanceof FootageItem && layer.source.file) {
                itemsToProcess.push(layer.source.file);
            }
        }
    }

    // 2. 如果时间线上没选到素材，再检查项目窗口的选中项
    if (itemsToProcess.length === 0 && proj.selection.length > 0) {
        for (var j = 0; j < proj.selection.length; j++) {
            var item = proj.selection[j];
            if (item instanceof FootageItem && item.file) {
                itemsToProcess.push(item.file);
            }
        }
    }

    if (itemsToProcess.length === 0) {
        alert("请在时间线上或项目面板中选中一个或多个素材（必须是本地文件）");
        return;
    }

    // 3. 定位每个素材
    for (var k = 0; k < itemsToProcess.length; k++) {
        var file = itemsToProcess[k];
        if (file && file.exists) {
            if ($.os.indexOf("Windows") !== -1) {
                system.callSystem('explorer /select,"' + file.fsName + '"');
            } else {
                system.callSystem('open -R "' + file.fsName + '"');
            }
        }
    }
})();
