﻿﻿// 快速渲染 By BoBO
// 修改历史
// 2025.7.16 添加预览输出规则 输出目录更改
// 2024.5.31 1.修正选中 合成名 非 name#name#name 类型执行 按 合成名 输出  2.修正非选中合成 按 当前激活的合成 输出
// 2024.6.18 添加预览合成处理规则：输出到与AE文件同级的"预览"目录，跳过"_输出"目录

// 检查文件是否保存
if (app.project.file !== null) {
    var sel = app.project.selection;
    var filePath = app.project.file;
    var outputPath = getPath(filePath);

    clearQueue(); // 统一在开始处清空队列

    if (sel.length > 0) {
        SPCreateFolderAndOutputForSelectedCompsAttackDirection();
    } else {
        RenderDefault();
    }
    // 统一执行渲染
    app.project.renderQueue.render();
    alert(">>> 渲染完毕！！<<<");
    clearQueue();
} else {
    alert("请先保存文件！！");
}

function SPCreateFolderAndOutputForSelectedCompsAttackDirection() {
    if (outputPath != null) {
        var selectedItems = app.project.selection;

        for (var i = 0, len = selectedItems.length; i < len; i++) {
            var item = selectedItems[i];

            if (item instanceof CompItem) {
                var sequencePath;
                var sequenceFolderPath;
                
                if (item.name.indexOf('#') !== -1 && item.name.split('#').length === 3) {
                    // 符合 name#name#name 格式
                    var dirStr = item.name.toString().split('#')[2]; //截取方向
                    var AniName = item.name.match(/#(\S*)#/)[1]; //获取动作名

                    sequenceFolderPath = new Folder(outputPath.toString() + "/" + AniName + "/" + dirStr);
                    sequenceFolderPath.create();

                    sequencePath = new File(outputPath.toString() + "/" + AniName + "/" + dirStr + "/" + "[#####].png");
                } 
                // 添加预览合成处理规则 - 跳过"_输出"目录
                else if (item.name.indexOf("预览") !== -1) {
                    // 获取项目文件所在目录（跳过"_输出"目录）
                    var projectFolder = filePath.parent;
                    
                    // 创建预览目录（与AE文件同级）
                    var previewRoot = new Folder(projectFolder.fsName + "/预览");
                    if (!previewRoot.exists) previewRoot.create();
                    
                    // 创建包含完整合成名的子目录
                    sequenceFolderPath = new Folder(previewRoot.fsName + "/" + item.name);
                    sequenceFolderPath.create();
                    
                    sequencePath = new File(sequenceFolderPath.fsName + "/[#####].png");
                } 
                else {
                    // 不符合 name#name#name 格式，直接使用合成名
                    sequenceFolderPath = new Folder(outputPath.toString() + "/" + item.name);
                    sequenceFolderPath.create();

                    sequencePath = new File(outputPath.toString() + "/" + item.name + "/" + "[#####].png");
                }

                var RQItem = app.project.renderQueue.items.add(item);
                var lastOMItem = RQItem.outputModules[1];
                lastOMItem.file = sequencePath;
                lastOMItem.format = "PNG Sequence";
                lastOMItem.includeSourceXMP = false; // 确保不包含源 XMP 数据
            } else {
                alert("选中的项目 " + item.name + " 不是一个合成项（CompItem）。请选选中合成或者激活当前。");
            }
        }
    }
}

function RenderDefault() {
    var outputName = "[#####].png";
    var comp = app.project.activeItem;
    
    if (comp instanceof CompItem) {
        var qItem = app.project.renderQueue.items.add(comp);
        var outputModule = qItem.outputModules[1];
        outputModule.format = "PNG Sequence";
        outputModule.includeSourceXMP = false;

        var folderPath;
        var fileName;
        
        // 预览合成处理
        if (comp.name.indexOf("预览") !== -1) {
            var projectFolder = filePath.parent;
            var previewRoot = new Folder(projectFolder.fsName + "/预览");
            if (!previewRoot.exists) previewRoot.create();
            folderPath = previewRoot.fsName + "/" + comp.name;
            fileName = folderPath + "/[#####].png";
        } else {
            folderPath = outputPath + "/" + comp.name;
            fileName = folderPath + "/" + outputName;
        }
        
        Folder(folderPath).create();
        outputModule.file = new File(fileName);
    } else {
        alert("当前激活的项目不是一个合成项（CompItem）。");
    }
}

function clearQueue() {
    while (app.project.renderQueue.numItems > 0) {
        app.project.renderQueue.item(app.project.renderQueue.numItems).remove();
    }
}

function getPath(filePath) {
    var projectFolder = filePath.parent;
    return projectFolder.fsName + "/输出";
}
