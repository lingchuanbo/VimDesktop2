{
    /** ===================== 优化的图层本地化资源转换 ===================== */

    function main() {
        if (!app.project.file) { alert("请先保存 AE 工程文件，再运行脚本。"); return; }

        var activeComp = (app.project.activeItem instanceof CompItem) ? app.project.activeItem : null;
        var selectedLayers = activeComp ? activeComp.selectedLayers : [];
        var selectedItems = app.project.selection || [];

        if ((!selectedLayers || selectedLayers.length === 0) && (!selectedItems || selectedItems.length === 0)) {
            alert("请在时间轴或项目窗口中至少选择一个对象（图层 / 素材 / 合成）。");
            return;
        }

        var exportFormat = askExportFormat(); // "PNG" | "MOV" | null
        if (!exportFormat) return;

        var projFolder = app.project.file.parent;
        var assetsRoot = new Folder(projFolder.fsName + "/素材");
        if (!assetsRoot.exists) assetsRoot.create();

        // 根据格式创建对应的输出目录
        var outputDir;
        if (exportFormat === "MOV") {
            outputDir = new Folder(assetsRoot.fsName + "/mov");
        } else {
            outputDir = new Folder(assetsRoot.fsName + "/序列图");
        }
        if (!outputDir.exists) outputDir.create();

        // 组织任务，记录图层位置信息
        var tasks = [];

        // 时间轴图层处理
        if (selectedLayers && selectedLayers.length) {
            for (var i = 0; i < selectedLayers.length; i++) {
                var L = selectedLayers[i];
                if (!L || !L.source) continue;

                // 记录图层详细信息
                var layerInfo = {
                    name: L.name,
                    index: L.index,
                    comp: L.containingComp,
                    inPoint: L.inPoint,
                    outPoint: L.outPoint,
                    startTime: L.startTime
                };

                var layerName = sanitize(L.name);
                pushTask(tasks, {
                    scope: "layer",
                    layer: L,
                    source: L.source,
                    layerInfo: layerInfo,
                    outputDir: outputDir,
                    displayName: layerName
                });
            }
        }

        // 项目窗口项处理
        if (selectedItems && selectedItems.length) {
            for (var j = 0; j < selectedItems.length; j++) {
                var it = selectedItems[j];
                if (!(it instanceof CompItem) && !(it instanceof FootageItem)) continue;

                var itemName = sanitize(it.name);
                pushTask(tasks, {
                    scope: "item",
                    item: it,
                    source: it,
                    outputDir: outputDir,
                    displayName: itemName
                });
            }
        }

        if (tasks.length === 0) { alert("未找到可处理的对象。"); return; }

        app.beginUndoGroup("优化的图层本地化资源转换");

        var logs = [], warns = [];
        for (var k = 0; k < tasks.length; k++) {
            try {
                processTask(tasks[k], exportFormat, logs, warns);
            }
            catch (e) {
                warns.push("【失败】" + label(tasks[k]) + " → " + e);
            }
        }

        app.endUndoGroup();

        var msg = "处理完成：\n" + logs.join("\n");
        if (warns.length) msg += "\n\n注意/错误：\n" + warns.join("\n");
        alert(msg);
    }

    /* ===================== 核心处理逻辑 ===================== */

    function processTask(t, exportFormat, logs, warns) {
        var src = t.source;
        var layerName = t.displayName;

        // 创建临时合成进行独立渲染
        var tempComp = createTempCompForLayer(t, src);
        if (!tempComp) {
            warns.push("【跳过】无法创建临时合成：" + label(t));
            return;
        }

        try {
            // 构建输出路径
            var outPath = buildOptimizedOutputPath(t.outputDir, layerName, exportFormat);

            // 渲染临时合成
            var rendered = renderCompTo(tempComp, outPath, exportFormat);

            // 导入渲染结果
            var imported = (exportFormat === "PNG") ? importSequence(rendered) : importSingle(rendered);
            if (!imported) throw "导入失败";

            // 替换或添加到原位置上方
            if (t.scope === "layer" && t.layer && t.layerInfo) {
                replaceLayerAndPosition(t.layer, imported, t.layerInfo);
            } else if (t.scope === "item") {
                replaceAllUsages(src, imported);
            }

            logs.push("【OK】" + label(t) + " → " + outPath);

        } finally {
            // 清理临时合成
            if (tempComp) tempComp.remove();
        }
    }

    function createTempCompForLayer(task, source) {
        var layerName = task.displayName;
        var tempCompName = "_temp_render_" + layerName;

        // 获取源的基本属性
        var width = 1920, height = 1080, frameRate = 25, duration = 1;

        if (source instanceof CompItem) {
            width = source.width;
            height = source.height;
            frameRate = source.frameRate;
            duration = source.duration;
        } else if (source instanceof FootageItem) {
            width = source.width || 1920;
            height = source.height || 1080;
            frameRate = source.frameRate || 25;
            duration = Math.max(source.duration || 1, 1 / frameRate);
        }

        // 如果是图层，使用图层的时间范围
        if (task.scope === "layer" && task.layerInfo) {
            duration = task.layerInfo.outPoint - task.layerInfo.inPoint;
        }

        // 创建临时合成
        var tempComp = app.project.items.addComp(tempCompName, width, height, 1.0, duration, frameRate);

        // 添加源到临时合成
        var tempLayer = tempComp.layers.add(source);

        // 如果是图层，复制原图层的时间设置
        if (task.scope === "layer" && task.layerInfo) {
            tempLayer.startTime = 0; // 从0开始
            tempLayer.inPoint = 0;
            tempLayer.outPoint = duration;
        }

        return tempComp;
    }

    function buildOptimizedOutputPath(outputDir, layerName, format) {
        var safeName = sanitize(layerName);

        if (format === "PNG") {
            // PNG序列：素材/序列图/图层名/00000.png
            var seqDir = new Folder(outputDir.fsName + "/" + safeName);
            if (!seqDir.exists) seqDir.create();
            return seqDir.fsName + "/[#####].png";
        } else {
            // MOV文件：素材/mov/图层名.mov
            return outputDir.fsName + "/" + safeName + ".mov";
        }
    }

    function replaceLayerAndPosition(originalLayer, newSource, layerInfo) {
        var comp = layerInfo.comp;
        var originalIndex = layerInfo.index;

        // 在原图层上方添加新图层
        var newLayer = comp.layers.add(newSource, originalIndex);

        // 复制原图层的时间属性
        newLayer.startTime = layerInfo.startTime;
        newLayer.inPoint = layerInfo.inPoint;
        newLayer.outPoint = layerInfo.outPoint;

        // 可选：隐藏原图层而不是删除
        originalLayer.enabled = false;

        return newLayer;
    }

    /* ===================== 工具函数 ===================== */

    function askExportFormat() {
        var dlg = new Window("dialog", "选择导出格式");
        dlg.alignChildren = ["fill", "top"];

        var rbPNG = dlg.add("radiobutton", undefined, "PNG 序列");
        var rbMOV = dlg.add("radiobutton", undefined, "MOV");
        rbPNG.value = true;

        var buttonGroup = dlg.add("group");
        buttonGroup.alignment = "center";
        var okBtn = buttonGroup.add("button", undefined, "确定");
        var cancelBtn = buttonGroup.add("button", undefined, "取消");

        var choice = null;
        okBtn.onClick = function () {
            choice = rbMOV.value ? "MOV" : "PNG";
            dlg.close(1);
        };
        cancelBtn.onClick = function () {
            dlg.close(0);
        };

        return (dlg.show() === 1) ? choice : null;
    }

    function pushTask(list, t) {
        var key = ((t.source && t.source.id) ? t.source.id : ("L@" + (t.layer ? t.layer.index : Math.random()))) + "|" + t.outputDir.fsName;
        for (var i = 0; i < list.length; i++) {
            if (list[i]._key === key) return;
        }
        t._key = key;
        list.push(t);
    }

    function label(t) {
        if (t.scope === "layer" && t.layer && t.layer.containingComp) {
            return "[图层] " + t.layer.name + " @ " + t.layer.containingComp.name;
        }
        if (t.scope === "item" && t.item) {
            return "[项目项] " + t.item.name;
        }
        return "[未知]";
    }

    function sanitize(s) {
        return String(s).replace(/[\/\\:*?"<>|]/g, "_").replace(/^\s+|\s+$/g, "");
    }

    function renderCompTo(compItem, outPath, fmt) {
        var rqItem = app.project.renderQueue.items.add(compItem);

        // 应用渲染设置模板
        try {
            rqItem.applyTemplate("最佳设置");
        } catch (e) {
            try {
                rqItem.applyTemplate("Best Settings");
            } catch (e2) { }
        }

        var om = rqItem.outputModule(1);
        om.file = new File(outPath);

        // 强制设置输出格式
        if (fmt === "PNG") {
            // 多种方式尝试设置PNG序列格式
            var pngSet = false;

            // 方法1：直接设置格式
            try {
                om.format = "PNG Sequence";
                pngSet = true;
            } catch (e1) {
                try {
                    om.format = "PNG";
                    pngSet = true;
                } catch (e2) { }
            }

            // 方法2：如果直接设置失败，尝试应用模板
            if (!pngSet) {
                pngSet = tryApplyOM(om, ["PNG 序列带透明", "PNG 序列", "PNG Sequence with Alpha", "PNG Sequence", "PNG"]);
            }

            // 方法3：手动查找并应用PNG相关模板
            if (!pngSet) {
                var templates = om.templates;
                for (var t = 0; t < templates.length; t++) {
                    var templateName = (templates[t] + "").toLowerCase();
                    if (templateName.indexOf("png") !== -1) {
                        try {
                            om.applyTemplate(templates[t]);
                            pngSet = true;
                            break;
                        } catch (e) { }
                    }
                }
            }

            if (!pngSet) {
                alert("警告：无法设置PNG格式，将使用默认格式。请检查AE输出模块模板设置。");
            }

            // 设置透明通道
            try {
                om.includeAlpha = true;
            } catch (e) { }

        } else {
            // MOV格式处理
            var applied = tryApplyOM(om, ["无损带透明", "无损", "Lossless with Alpha", "Lossless"]);
            if (!applied) {
                try {
                    om.format = "QuickTime";
                } catch (e) { }
            }
        }

        // 执行渲染
        rqItem.render = true;
        app.project.renderQueue.render();
        rqItem.remove();

        // 返回渲染结果文件
        if (fmt === "PNG") {
            var pat = parseSeqPattern(outPath);
            var first = findFirstFrameSafe(new Folder(pat.dir), pat.prefix, pat.ext);
            if (!first) throw "未找到导出的 PNG 序列。";
            return first;
        } else {
            var f = new File(outPath);
            if (!f.exists) throw "未找到导出的 MOV 文件。";
            return f;
        }
    }

    function tryApplyOM(om, names) {
        var tmps = om.templates || [];

        // 首先尝试精确匹配
        for (var i = 0; i < names.length; i++) {
            var target = names[i].toLowerCase();
            for (var j = 0; j < tmps.length; j++) {
                if ((tmps[j] + "").toLowerCase() === target) {
                    try {
                        om.applyTemplate(tmps[j]);
                        return true;
                    } catch (e) { }
                }
            }
        }

        // 如果精确匹配失败，尝试包含匹配
        for (var i = 0; i < names.length; i++) {
            var target = names[i].toLowerCase();
            for (var j = 0; j < tmps.length; j++) {
                var templateName = (tmps[j] + "").toLowerCase();
                if (templateName.indexOf(target.split(" ")[0]) !== -1) { // 匹配关键词如"png"
                    try {
                        om.applyTemplate(tmps[j]);
                        return true;
                    } catch (e) { }
                }
            }
        }

        return false;
    }

    function parseSeqPattern(p) {
        var f = new File(p);
        return {
            dir: f.parent.fsName,
            prefix: f.displayName.replace(/\[#+\]\.[^\.]+$/, ""),
            ext: f.displayName.replace(/^.*\./, "")
        };
    }

    function findFirstFrameSafe(dirFolder, prefix, ext) {
        if (!dirFolder.exists) return null;
        var all = listFilesSafe(dirFolder, "*." + ext);
        var cand = [];
        var re = new RegExp("^" + escapeReg(prefix) + "\\d+\\." + escapeReg(ext) + "$", "i");

        for (var i = 0; i < all.length; i++) {
            var f = all[i];
            if (f instanceof File && re.test(f.displayName)) {
                cand.push(f);
            }
        }

        if (cand.length === 0) return null;
        cand.sort(function (a, b) {
            return (a.displayName < b.displayName) ? -1 : 1;
        });
        return cand[0];
    }

    function listFilesSafe(folder, wildcard) {
        var arr = folder.getFiles(wildcard || "*");
        var out = [];
        for (var i = 0; i < arr.length; i++) {
            out.push(arr[i]);
        }
        return out;
    }

    function importSingle(fileObj) {
        if (!fileObj || !fileObj.exists) return null;
        var io = new ImportOptions(fileObj);
        return app.project.importFile(io);
    }

    function importSequence(firstFrameFile) {
        if (!firstFrameFile || !firstFrameFile.exists) return null;
        var io = new ImportOptions(firstFrameFile);
        io.sequence = true;
        io.forceAlphabetical = true;
        return app.project.importFile(io);
    }

    function replaceAllUsages(oldItem, newItem) {
        for (var i = 1; i <= app.project.numItems; i++) {
            var it = app.project.items[i];
            if (!(it instanceof CompItem)) continue;
            var Ls = it.layers;
            for (var j = 1; j <= Ls.length; j++) {
                var L = Ls[j];
                if (L && L.source === oldItem) {
                    L.replaceSource(newItem, false);
                }
            }
        }
    }

    function escapeReg(s) {
        return String(s).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    }

    /* ===================== 入口 ===================== */
    try {
        main();
    } catch (e) {
        alert("脚本未捕获错误：\n" + e);
    }
}