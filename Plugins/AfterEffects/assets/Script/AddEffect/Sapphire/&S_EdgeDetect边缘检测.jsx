var activeComp = app.project.activeItem;

if (activeComp && activeComp instanceof CompItem) {

    var selectedLayers = app.project.activeItem.selectedLayers;

    if (selectedLayers.length > 0) {

        for (var i = 0; i < selectedLayers.length; i++) {

            var Effect = selectedLayers[i].Effects.addProperty("S_EdgeDetect");
            // 调整参数
            // Effect.property("Wipe Percent").setValue(50);
            // Effect.property("Grad Add").setValue(1);
            // Effect.property("Width Green").setValue(1);
            // Effect.property("Width Blue").setValue(1);
        }
    
    }else{

        alert("请先选择一个或多个层。");

    }

}else{

  alert("请先打开一个合成。");

}
