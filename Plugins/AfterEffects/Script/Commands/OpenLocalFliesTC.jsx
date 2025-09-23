//初始化文件，可能会被覆盖！

if(app.project.file !== null){
    var path=app.project['file'];
    findMyAEP();
}else{
    alert("文件未保存，请先保存文件！")
}

function findMyAEP() {
    app.beginUndoGroup("Find AEP");
    var myProject = app.project;
    var filepath = myProject.file.fsName;
    var	command = 'D:\\WorkFlow\\tools\\TotalCMD\\TOTALCMD.EXE /O /T /R= '+filepath;
    system.callSystem(command);
}