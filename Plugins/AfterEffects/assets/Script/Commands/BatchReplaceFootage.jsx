// 根据合成名字快速匹配素材路径
// By.BoBO
// 2024.6.1 优化代码结构 功能已基本完整
// 2024.5.31 构建

var selectedItems = app.project.selection;
if (selectedItems.length > 0) {
    processSelectedItems(selectedItems);
} else {
    alert("当前未选中!!!");
}

function processSelectedItems(items) {
    for (var i = 0; i < items.length; i++) {
        var item = items[i];
        if (item instanceof CompItem) {
            processCompItem(item);
        } else {
            alert("请选中一个合成!");
        }
    }
}

function processCompItem(comp) {
    var nameParts = comp.name.split('#');
    if (nameParts.length !== 3) {
        alert("合成名称格式应为 'name#idle#direction'.");
        return;
    }

    var replaceIdle = nameParts[1];
    var replaceDirection = nameParts[2];

    app.beginUndoGroup("Replace and Reload Comp Assets");

    var assetPaths = getUniqueAssetPaths(comp, replaceIdle, replaceDirection);

    if (assetPaths.length > 0) {
        var pathsMessage = buildPathsMessage(assetPaths);
        alert(pathsMessage);
        replaceFootageAssets(assetPaths);
    } else {
        alert("未找到任何素材。");
    }

    app.endUndoGroup();
}

function getUniqueAssetPaths(comp, replaceIdle, replaceDirection) {
    var assetPaths = [];

    for (var i = 1; i <= comp.numLayers; i++) {
        var layer = comp.layer(i);

        if (layer instanceof AVLayer && layer.source instanceof FootageItem && layer.source.file) {
            var source = layer.source;
            var modifiedPath = source.file.fsName
                .replace(/run|idle|ride_idle|ride_run|ride|die|attack1|attack2|attack3|attack4|attack5|attack|cast|parry|defense|stand2|walk|stand/g, replaceIdle)
                .replace(/东南|东北|东|南|北/g, replaceDirection);

            if (!isPathInArray(modifiedPath, assetPaths)) {
                assetPaths.push({ original: source, modified: modifiedPath });
            }
        }
    }

    return assetPaths;
}

function isPathInArray(path, array) {
    for (var i = 0; i < array.length; i++) {
        if (array[i].modified === path) {
            return true;
        }
    }
    return false;
}

function buildPathsMessage(assetPaths) {
    var message = "素材路径列表:\n\n";
    for (var i = 0; i < assetPaths.length; i++) {
        message += "修改前：" + assetPaths[i].original.file.fsName + "\n";
        message += "修改后：" + assetPaths[i].modified + "\n\n";
    }
    return message;
}

function replaceFootageAssets(assetPaths) {
    for (var i = 0; i < assetPaths.length; i++) {
        try {
            var source = assetPaths[i].original;
            var newFile = new File(assetPaths[i].modified);
            source.replaceWithSequence(newFile, 1); // Replace footage with an image sequence
        } catch (e) {
            // alert("重新加载失败：" + assetPaths[i].modified);
        }
    }
}
