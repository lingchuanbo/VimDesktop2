var activeComp = app.project.activeItem;

if (activeComp && activeComp instanceof CompItem) {

    var selectedLayers = app.project.activeItem.selectedLayers;

    if (selectedLayers.length > 0) {

        for (var i = 0; i < selectedLayers.length; i++) {

            var Effect = selectedLayers[i].Effects.addProperty("Glow");
            // 调整模糊效果的参数
            Effect.property("Glow Threshold").setValue(25.5);
            Effect.property("Glow Colors").setValue(2);
            Effect.property("Color Looping").setValue(1);
        }
    
    }else{

        alert("请先选择一个或多个层。");

    }

}else{

  alert("请先打开一个合成。");

}
