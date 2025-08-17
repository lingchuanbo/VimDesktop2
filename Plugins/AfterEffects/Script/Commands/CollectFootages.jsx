// 自动化 收集素材脚本
// ByBoBO
// 20250816
{
    function padNumber(num, digits) {
        var s = num.toString();
        while (s.length < digits) s = "0" + s;
        return s;
    }

    // 创建进度窗口
    function createProgressWindow(totalItems) {
        var win = new Window("palette", "收集素材进度");
        win.orientation = "column";
        win.alignChildren = "fill";
        win.preferredSize.width = 400;
        win.spacing = 10;
        win.margins = 16;

        // 状态文本
        win.statusText = win.add("statictext", undefined, "准备开始...");
        win.statusText.preferredSize.height = 20;

        // 进度条
        win.progressBar = win.add("progressbar", undefined, 0, totalItems);
        win.progressBar.preferredSize.height = 20;

        // 详细信息
        win.detailText = win.add("statictext", undefined, "");
        win.detailText.preferredSize.height = 20;

        // 取消按钮
        win.cancelBtn = win.add("button", undefined, "取消");
        win.cancelBtn.onClick = function () {
            win.cancelled = true;
            win.close();
        };

        win.cancelled = false;
        win.center();
        win.show();
        return win;
    }

    function collectFootages() {
        var proj = app.project;
        if (!proj.file) {
            alert("请先保存工程文件再运行脚本！");
            return;
        }

        var projFolder = proj.file.parent;
        var targetRoot = new Folder(projFolder.fsName + "/素材");
        if (!targetRoot.exists) targetRoot.create();

        // 选中的素材，否则全项目
        var itemsToProcess = [];
        if (proj.selection.length > 0) {
            for (var i = 0; i < proj.selection.length; i++) {
                if (proj.selection[i] instanceof FootageItem) {
                    itemsToProcess.push(proj.selection[i]);
                }
            }
        } else {
            for (var j = 1; j <= proj.numItems; j++) {
                if (proj.item(j) instanceof FootageItem) {
                    itemsToProcess.push(proj.item(j));
                }
            }
        }

        if (itemsToProcess.length === 0) {
            alert("未找到任何素材！");
            return;
        }

        // 统计信息
        var stats = {
            totalItems: itemsToProcess.length,
            sequenceItems: 0,
            singleItems: 0,
            sequenceFrames: 0,
            copiedFrames: 0,
            failedItems: 0,
            processedItems: 0
        };

        // 创建进度窗口（仅在素材较多时显示）
        var progressWin = null;
        if (itemsToProcess.length > 5) {
            progressWin = createProgressWindow(itemsToProcess.length);
        }

        app.beginUndoGroup("收集素材");

        for (var k = 0; k < itemsToProcess.length; k++) {
            var item = itemsToProcess[k];
            stats.processedItems = k + 1;

            // 更新进度（仅在有进度窗口时）
            if (progressWin) {
                // 检查是否取消
                if (progressWin.cancelled) {
                    app.endUndoGroup();
                    progressWin.close();
                    alert("操作已取消");
                    return;
                }

                try {
                    progressWin.statusText.text = "处理素材 " + (k + 1) + "/" + itemsToProcess.length + ": " + item.name;
                    progressWin.progressBar.value = k + 1;
                    progressWin.update();
                } catch (e) {
                    // 进度窗口更新失败，继续处理
                }
            }

            if (!item.file) {
                stats.failedItems++;
                continue;
            }

            var srcFile = item.file;
            var ext = srcFile.name.split(".").pop().toLowerCase();

            // 判断是否为序列素材 - 使用多种方法检测
            var isSequence = false;

            // 方法1: 检查isSequence属性
            if (item.mainSource.isSequence === true) {
                isSequence = true;
            }

            // 方法2: 检查duration > 0 且不是视频文件
            if (!isSequence && item.duration > 0 && !item.mainSource.isStill) {
                var fileName = srcFile.name.toLowerCase();
                var videoExts = ["mov", "mp4", "avi", "mkv", "wmv", "flv", "webm"];
                var isVideo = false;
                for (var v = 0; v < videoExts.length; v++) {
                    if (fileName.indexOf("." + videoExts[v]) !== -1) {
                        isVideo = true;
                        break;
                    }
                }
                if (!isVideo) {
                    isSequence = true;
                }
            }

            // 方法3: 检查文件名是否包含数字序列模式
            if (!isSequence) {
                var seqPattern = /\d{4,}\.(png|jpg|jpeg|tiff|tif|exr|dpx)$/i;
                if (seqPattern.test(srcFile.name)) {
                    isSequence = true;
                }
            }

            if (isSequence) {
                // ========== 处理序列素材 ==========
                stats.sequenceItems++;
                if (progressWin) {
                    progressWin.detailText.text = "处理序列: " + item.name;
                    progressWin.update();
                }

                var sequenceFolder = new Folder(targetRoot.fsName + "/序列图");
                if (!sequenceFolder.exists) sequenceFolder.create();

                var seqName = srcFile.name;
                var match = seqName.match(/(.*?)(\d+)(\.[^.]+)$/);
                if (match) {
                    var prefix = match[1];
                    var number = parseInt(match[2], 10);
                    var digits = match[2].length;
                    var suffix = match[3];

                    // 获取原始文件夹名称（如 smoke）
                    var originalFolderName = srcFile.parent.name;

                    // 在序列图文件夹下创建原始文件夹结构：素材\序列图\smoke\
                    var seqTargetFolder = new Folder(sequenceFolder.fsName + "/" + originalFolderName);
                    if (!seqTargetFolder.exists) seqTargetFolder.create();

                    // 通过扫描目录来计算帧数
                    var sequenceFiles = [];

                    try {
                        var parentFolder = srcFile.parent;
                        var files = parentFolder.getFiles();

                        for (var f = 0; f < files.length; f++) {
                            if (files[f] instanceof File) {
                                var fname = files[f].name;
                                // 检查是否匹配序列模式：前缀 + 数字 + 后缀
                                if (fname.indexOf(prefix) === 0 && fname.indexOf(suffix) === fname.length - suffix.length) {
                                    var middlePart = fname.substring(prefix.length, fname.length - suffix.length);
                                    if (/^\d+$/.test(middlePart)) {
                                        var frameNum = parseInt(middlePart, 10);
                                        sequenceFiles.push({
                                            name: fname,
                                            number: frameNum
                                        });
                                    }
                                }
                            }
                        }

                        // 按数字排序
                        sequenceFiles.sort(function (a, b) { return a.number - b.number; });
                        stats.sequenceFrames += sequenceFiles.length;

                    } catch (e) {
                        stats.failedItems++;
                        continue;
                    }

                    // 复制所有序列帧
                    for (var s = 0; s < sequenceFiles.length; s++) {
                        var sourceFile = new File(srcFile.parent.fsName + "/" + sequenceFiles[s].name);
                        var targetFile = new File(seqTargetFolder.fsName + "/" + sequenceFiles[s].name);

                        if (sourceFile.exists) {
                            try {
                                if (sourceFile.copy(targetFile)) {
                                    stats.copiedFrames++;
                                }
                            } catch (err) {
                                // 复制失败，继续下一个
                            }
                        }
                    }

                    // 重新指向新路径 - 使用专业的序列替换方法
                    if (sequenceFiles.length > 0) {
                        var firstFrameFile = new File(seqTargetFolder.fsName + "/" + sequenceFiles[0].name);
                        if (firstFrameFile.exists) {
                            try {
                                // 使用专业方法 - replaceWithSequence(file, 1)
                                item.replaceWithSequence(firstFrameFile, 1);
                            } catch (err1) {
                                try {
                                    // 备选方案
                                    item.replaceWithSequence(firstFrameFile, 0);
                                } catch (err2) {
                                    try {
                                        // 删除并重新导入序列
                                        var itemName = item.name;
                                        var itemParentFolder = item.parentFolder;
                                        item.remove();

                                        var importOptions = new ImportOptions(firstFrameFile);
                                        importOptions.sequence = true;
                                        var newItem = app.project.importFile(importOptions);
                                        newItem.name = itemName;
                                        newItem.parentFolder = itemParentFolder;
                                    } catch (err3) {
                                        // 最后备选
                                        try {
                                            item.replace(firstFrameFile);
                                        } catch (err4) {
                                            stats.failedItems++;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // ========== 处理单张素材 ==========
                stats.singleItems++;
                if (progressWin) {
                    progressWin.detailText.text = "处理单张: " + item.name;
                    progressWin.update();
                }

                var targetFolder = new Folder(targetRoot.fsName + "/" + ext);
                if (!targetFolder.exists) targetFolder.create();

                var targetFile = new File(targetFolder.fsName + "/" + srcFile.name);
                try {
                    if (srcFile.copy(targetFile)) {
                        stats.copiedFrames++;
                        item.replace(targetFile);
                    }
                } catch (err) {
                    stats.failedItems++;
                }
            }
        }

        app.endUndoGroup();
        if (progressWin) {
            progressWin.close();
        }

        // 显示精简日志
        var logMessage = "=== 素材收集完成 ===\n\n";
        logMessage += "总素材数量: " + stats.totalItems + "\n";
        logMessage += "序列素材: " + stats.sequenceItems + " 个\n";
        logMessage += "单张素材: " + stats.singleItems + " 个\n";
        logMessage += "序列总帧数: " + stats.sequenceFrames + " 帧\n";
        logMessage += "成功复制: " + stats.copiedFrames + " 个文件\n";
        if (stats.failedItems > 0) {
            logMessage += "失败项目: " + stats.failedItems + " 个\n";
        }
        logMessage += "\n素材已收集到: " + targetRoot.fsName;

        alert(logMessage);
    }

    collectFootages();
}
