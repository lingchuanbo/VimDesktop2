// 素材整理
// BoBO
// 24.12.5
// 修正移动丢失问题

var myDefaults = new Object();
myDefaults.myFolders = new Array("Comps", "Footage", "tmp", "Solids", "Precomps");
myDefaults.myFolderObjects = new Array();
myDefaults.myPlaceholderObjects = new Array();


// 清理重复的素材
function removeDuplicateFootage() {
    var proj = app.project;
    var items = proj.items;
    var seenFiles = {};
    var duplicates = [];

    app.beginUndoGroup("Remove Duplicate Footage");

    for (var i = 1; i <= items.length; i++) {
        var item = items[i];
        if (item instanceof FootageItem && !item.usedIn.length) {
            var filePath = item.file ? item.file.fsName : null;
            if (filePath) {
                if (seenFiles[filePath]) {
                    duplicates.push(item);
                } else {
                    seenFiles[filePath] = true;
                }
            }
        }
    }

    for (var j = 0; j < duplicates.length; j++) {
        duplicates[j].remove();
    }

    app.endUndoGroup();
}

// 重载素材
function ReloadFootages() {
    var proj = app.project;
    if (proj.numItems > 0) {
        app.beginUndoGroup("ReFootages");

        for (var i = 1; i <= proj.numItems; i++) {
            var curItem = proj.item(i);

            if (curItem instanceof FootageItem && !curItem.mainSource.isMissing) {
                try {
                    if (!curItem.mainSource.isStill) {
                        curItem.mainSource.reload();
                    }
                } catch (e) {
                    alert("无法重新加载素材：" + curItem.name + "\n错误信息：" + e.toString());
                }

                // 检查是否为静态图像
                if (!(curItem.mainSource instanceof SolidSource) && 
                    curItem.usedIn.length == 0 && 
                    !curItem.mainSource.isStill) {
                    curItem.replaceWithSequence(curItem.mainSource.file, 1);
                }
            }
        }

        app.endUndoGroup();
    }
}
function retrieveProjectItems(itemType, winObj) {
    stats = winObj;
    stats.text = "Retrieving Project Items...";
    var typeOptions = new Array("Composition", "Folder", "Footage");
    for (var t = 0; t < 3; t += 1) {
        if (itemType == typeOptions[t]) {
            itemAry = new Array();
            proj = app.project;
            itemTotal = proj.numItems;
            for (var i = 1; i <= itemTotal; i += 1) {
                curItem = proj.item(i);
                if (curItem.typeName == itemType) {
                    itemAry[itemAry.length] = curItem;
                }
            }
            return itemAry;
        }
    }
}

function removeAllEmptyFolders(currentFolder) {
    for (var i = currentFolder.numItems; i >= 1; i--) {
        var item = currentFolder.item(i);
        if (item instanceof FolderItem) {
            removeAllEmptyFolders(item);
        }
    }
    if (currentFolder !== app.project.rootFolder && currentFolder.numItems === 0) {
        try { currentFolder.remove(); } catch (e) {}
    }
}

function moveToFolder(curItemAry, parFolder, winObj) {
    stats = winObj.statusGrp.status;
    bar = winObj.progBar;
    var itemAryLength = curItemAry.length;
    for (var i = 0; i < itemAryLength; i += 1) {
        curItemAry[i].parentFolder = parFolder;
        stats.text = "Moving " + curItemAry[i].name;
        bar.value++;
    }
}

function grabPlaceholders() {
    var ni = app.project.numItems;
    for (var n = 1; n <= ni; n += 1) {
        curItem = app.project.item(n);
        for (var i = 0; i < 4; i += 1) {
            if (curItem instanceof FootageItem && curItem.name == "Placeholder") {
                myDefaults.myPlaceholderObjects[myDefaults.myPlaceholderObjects.length] = curItem;
                break;
            }
        }
    }
    return myDefaults.myPlaceholderObjects;
}

function grabMyFolderObjects() {
    var ni = app.project.numItems;
    for (var n = 1; n <= ni; n += 1) {
        curItem = app.project.item(n);
        for (var i = 0; i < 4; i += 1) {
            if (curItem instanceof FolderItem && curItem.name == myDefaults.myFolders[i]) {
                myDefaults.myFoldersObjects[myDefaults.myFoldersObjects.length] = curItem;
                break;
            }
        }
    }
}

function grabSpecificExtType(itemType, extName, stillVideo, winObj) {
    function grabExt(itemName) {
        var n = itemName.split(".");
        if (n.length > 1) {
            return n[n.length - 1].toString().toLowerCase();
        } else {
            return null;
        }
    }
    stats = winObj.statusGrp.status;
    tmp = new Array();
    proj = app.project;
    pi = proj.numItems;
    for (var i = 1; i <= pi; i += 1) {
        curItem = proj.item(i);
        stats.text = "Grabbing all " + itemType.toString() + "...";
        if (eval("curItem instanceof " + itemType)) {
            ext = grabExt(curItem.name);
            userExt = extName.toString().toLowerCase();
            if (ext == userExt) {
                if (curItem.duration > 1 && stillVideo == "Video") {
                    tmp[tmp.length] = curItem;
                } else if (curItem.duration == 0 && stillVideo == "Still") {
                    tmp[tmp.length] = curItem;
                } else {
                    tmp[tmp.length] = curItem;
                }
            }
        }
    }
    if (tmp.length >= 1) {
        return tmp;
    } else {
        return null;
    }
}

function grabAllExt() {
    tmp = new Array();
    proj = app.project;
    ni = proj.numItems;
    ph = false;
    for (var i = 1; i <= ni; i += 1) {
        curItem = proj.item(i);
        var n = curItem.name.split(".");
        if (curItem instanceof FootageItem) {
            if (n.length > 1) {
                tmp[tmp.length] = n[n.length - 1].toString().toLowerCase();
            }
        }
    }
    tmp = sortAndRemoveDups(tmp);
    return tmp;
}

function sortAndRemoveDups(aryInput) {
    var arySorted = aryInput.sort();
    var aryLength = arySorted.length;
    var results = new Array();
    for (var i = 0; i < aryLength; i += 1) {
        if (arySorted[i] != arySorted[i + 1]) {
            results[results.length] = arySorted[i];
        }
    }
    return results;
}

function grabAllSolids(statObj) {
    itemAry = new Array();
    proj = app.project;
    itemTotal = proj.numItems;
    statObj.text = "Retrieving all solids...";
    for (var i = 1; i <= itemTotal; i += 1) {
        curItem = proj.item(i);
        if (curItem.duration == 0) {
            if (curItem.mainSource.color) {
                itemAry[itemAry.length] = curItem;
            }
        }
    }
    return itemAry;
}

function grabAllPrecomps(statObj) {
    itemAry = new Array();
    proj = app.project;
    itemTotal = proj.numItems;
    statObj.text = "Retrieving all precomps...";
    for (var i = 1; i <= itemTotal; i += 1) {
        curItem = proj.item(i);
        if (curItem instanceof CompItem) {
            if (curItem.usedIn.length > 0) {
                itemAry[itemAry.length] = curItem;
            }
        }
    }
    return itemAry;
}

function progressBarPopup() {
    var pwpRes = "palette{orientation:'column', alignChildren:['fill', 'top'],\n\t\tstatusGrp: Group{orientation:'stack', alignment:['fill', 'top'], alignChildren:['fill', 'top'],\n\t\t\tstatus: StaticText{text:'Organizing...', alignment:['fill', 'center'], preferredSize:[300, -1]},\n\t\t},\n\t\tprogBar: Progressbar{text:'myProgBar', value:0},\n\t\tcloseBut: Button{text:'Close'},\n\t}";
    var pwpWin = new Window(pwpRes);
    
    // 新增函数：检查是否为预览类型合成
    function isPreviewComp(compName) {
        return /([\u4e00-\u9fa5a-zA-Z0-9_]+)\s*预览/g.test(compName);
    }

    // 新增函数：检查是否为输出类型合成
    function isOutputComp(compName) {

        return /[\w\u4e00-\u9fff]+#[\w\u4e00-\u9fff]+#[\w\u4e00-\u9fff]+/g.test(compName);
    }

    app.beginUndoGroup("Project Cleanup");
    
    // 记录原始文件夹
    myDefaults.myFolders = ["Comps", "Footage", "tmp", "Solids", "Precomps"];
    
    var s = pwpWin.statusGrp.status;
    projExt = grabAllExt().sort();
    projExtLength = projExt.length;
    
    var projectComps = retrieveProjectItems("Composition", s);
    var projectCompsLength = projectComps.length;
    
    var projectFootage = retrieveProjectItems("Footage", s);
    var projectFootageLength = projectFootage.length;
    
    var projectFolder = retrieveProjectItems("Folder", s);
    var projectFolderLength = projectFolder.length;
    
    var solids = grabAllSolids(s);
    var solidsLength = solids.length;
    
    var preComps = grabAllPrecomps(s);
    var preCompsLength = preComps.length;
    
    var placeHolders = grabPlaceholders();
    var placeHoldersLength = placeHolders.length;
    
    // 创建默认文件夹
    cFolder = app.project.items.addFolder(myDefaults.myFolders[0]);
    fFolder = app.project.items.addFolder(myDefaults.myFolders[1]);
    tmpFolder = app.project.items.addFolder(myDefaults.myFolders[2]);
    sFolder = app.project.items.addFolder(myDefaults.myFolders[3]);
    pcFolder = app.project.items.addFolder(myDefaults.myFolders[4]);
    

    // 处理 placeholder
    if (placeHoldersLength > 0) {
        phFolder = app.project.items.addFolder("Placeholder");
        phFolder.parentFolder = fFolder;
    }
    
    pwpWin.progBar.maxvalue = parseInt(projExtLength + projectCompsLength + projectFootageLength + projectFolderLength + solidsLength + preCompsLength + placeHoldersLength);
    
    moveToFolder(projectFolder, tmpFolder, pwpWin);
    moveToFolder(projectComps, cFolder, pwpWin);
    moveToFolder(preComps, pcFolder, pwpWin);
    pcFolder.parentFolder = cFolder;
    moveToFolder(projectFootage, fFolder, pwpWin);
    
    // 按扩展名创建文件夹
    for (var pe = 0; pe < projExtLength; pe += 1) {
        pf = app.project.items.addFolder(projExt[pe]);
        s.text = "Creating " + projExt[pe].toString() + " folder...";
        grabItems = grabSpecificExtType("FootageItem", projExt[pe].toString(), "", pwpWin);
        pwpWin.progBar.maxvalue += grabItems.length;
        moveToFolder(grabItems, pf, pwpWin);
        pf.parentFolder = fFolder;
    }
    
    // 处理 placeholder
    if (placeHoldersLength > 0) {
        moveToFolder(placeHolders, phFolder, pwpWin);
    }
    
    // 移动实体
    moveToFolder(solids, sFolder, pwpWin);

    // 新增预览和输出文件夹
    var previewFolder = app.project.items.addFolder("预览");
    var outputFolder = app.project.items.addFolder("输出");

    // 预先收集预览和输出的合成
    var previewComps = [];
    var outputComps = [];

    // 遍历所有合成，按规则移动到指定文件夹
    for (var i = 1; i <= app.project.numItems; i++) {

        var currentItem = app.project.item(i);
        
        
        // 检查是否是合成
        if (currentItem instanceof CompItem) {

            if (isPreviewComp(currentItem.name)) {

                previewComps.push(currentItem);
                currentItem.label = 9

            }
            
            if (isOutputComp(currentItem.name)) {

                outputComps.push(currentItem);
                currentItem.label = 8

            }
        }
    }

    // 批量移动预览合成
    moveToFolder(previewComps, previewFolder, pwpWin);
    
    // 批量移动输出合成
    moveToFolder(outputComps, outputFolder, pwpWin);

    // 删除临时文件夹
    s.text = "正在删除空文件夹...";
    tmpFolder.remove();
    removeAllEmptyFolders(app.project.rootFolder);
    
    app.endUndoGroup();
    pwpWin.progBar.value = pwpWin.progBar.maxvalue;
    s.text = "All done!";
}

if (app.project.file != null) {
    removeDuplicateFootage();
    progressBarPopup();
    app.project.consolidateFootage();
    ReloadFootages();
} else {
    alert("请先打开一个项目或保存当前项目。");
}