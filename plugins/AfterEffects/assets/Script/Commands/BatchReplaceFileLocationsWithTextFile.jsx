//Merged version with UI options for directory name and sequence name
//Works with sequences or still images, Windows only
//Features: decodeURI, URIToWinPath conversion, user interface for options

// Create UI Panel
function createUI() {
    var dialog = new Window("dialog", "批量替换文件位置选项");
    dialog.orientation = "column";
    dialog.alignChildren = "left";
    dialog.spacing = 10;
    dialog.margins = 16;

    // Title
    var titleGroup = dialog.add("group");
    titleGroup.add("statictext", undefined, "选择替换模式:");

    // Radio buttons for mode selection
    var modeGroup = dialog.add("panel", undefined, "模式选择");
    modeGroup.orientation = "column";
    modeGroup.alignChildren = "left";
    modeGroup.margins = 10;

    var dirNameRadio = modeGroup.add("radiobutton", undefined, "目录名模式 (Directory Name)");
    var seqNameRadio = modeGroup.add("radiobutton", undefined, "序列名模式 (Sequence Name)");

    // Set default selection
    dirNameRadio.value = true;

    // Description
    var descGroup = dialog.add("group");
    descGroup.orientation = "column";
    descGroup.alignChildren = "left";

    var desc1 = descGroup.add("statictext", undefined, "• 目录名模式: 支持序列帧重新链接");
    var desc2 = descGroup.add("statictext", undefined, "• 序列名模式: 不支持序列帧重新链接");

    // Buttons
    var buttonGroup = dialog.add("group");
    buttonGroup.alignment = "center";

    var okButton = buttonGroup.add("button", undefined, "确定");
    var cancelButton = buttonGroup.add("button", undefined, "取消");

    okButton.onClick = function () {
        dialog.close(1);
    };

    cancelButton.onClick = function () {
        dialog.close(0);
    };

    var result = dialog.show();

    if (result == 1) {
        return {
            useDirMode: dirNameRadio.value,
            useSeqMode: seqNameRadio.value
        };
    } else {
        return null;
    }
}

// Main execution - First check if items are selected and valid
var sel = app.project.selection;

if (sel.length == 0) {
    alert("请选择素材！");
} else {
    var validItems = true;

    // Validate selected items first
    for (var i = 0; i < sel.length; i++) {
        var currentItem = sel[i];

        if (!(currentItem instanceof FootageItem)) {
            alert("！！！非素材文件！！！");
            validItems = false;
            break;
        }
    }

    // Only show UI if items are valid
    if (validItems) {
        var userChoice = createUI();

        if (userChoice != null) {
            BatchReplaceFileLocationsWithTextFile(userChoice.useDirMode);
        }
    }
}

function BatchReplaceFileLocationsWithTextFile(useDirMode) {

    app.beginUndoGroup("Change File Locations");

    var txtFile = new File("~/Desktop/tempAE.txt");
    txtFile.open("w", "TEXT", "????");
    txt = "";
    sel = app.project.selection;
    var isSequence = new Array();

    if (sel.length == 0) {
        alert("Select footage items.");
    } else {
        for (i = 0; i < app.project.selection.length; i++) {
            isSequence[i] = !sel[i].mainSource.isStill;
            txt += URIToWinPath(sel[i].mainSource.file.toString()) + "\n";
        }

        txtFile.write(decodeURI("*** 修改完按提示保存，否者不起作用！***\n\n"));
        txtFile.write(decodeURI(txt));
        txtFile.close();
        txtFile.execute();

        isOk = confirm("请先确定记事本改变路径 ?\n\n重新加载中... ...!");

        if (isOk) {
            txtFile.open("r", "TEXT", "????");
            contents = txtFile.read();
            arrayContents = contents.split("\n");

            for (i = 0; i < app.project.selection.length; i++) {
                var tmpFile = new File(WinPathtoURI(arrayContents[i + 2]));

                if (isSequence[i]) {
                    try {
                        // 目录名模式: 参数1 (支持序列帧重新链接)
                        // 序列名模式: 参数0 (不支持序列帧重新链接)
                        var sequenceParam = useDirMode ? 1 : 0;
                        sel[i].replaceWithSequence(tmpFile, sequenceParam);
                    } catch (e) {
                        alert("路径存在错误请修正::\n\n" +
                            "素材名:【" + sel[i].name + "】路径错误\n\n" +
                            decodeURI(URIToWinPath(tmpFile.toString())));
                    }
                } else {
                    sel[i].replace(tmpFile);
                }

                writeLn(Math.round((i + 1) / app.project.selection.length * 100) + "%");
            }
        }
    }
    app.endUndoGroup();
}

function URIToWinPath(path) {
    str = path.replace(/\//, "");
    str = str.replace(/\//, ":/");
    str = str.replace(/%20/g, " ");
    str = str.replace(/\//g, "\\");
    return str;
}

function WinPathtoURI(path) {
    //windows, for now, the only one available!
    str = "/" + path.replace(":\\", "/");
    str = str.replace(/\\/g, "/");
    str = str.replace(/ /g, "%20");
    return str;
}