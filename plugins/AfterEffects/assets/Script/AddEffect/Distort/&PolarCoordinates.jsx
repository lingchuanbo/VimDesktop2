var activeComp = app.project.activeItem;

if (activeComp && activeComp instanceof CompItem) {

    var selectedLayers = app.project.activeItem.selectedLayers;

    if (selectedLayers.length > 0) {

        for (var i = 0; i < selectedLayers.length; i++) {

            var Effect = selectedLayers[i].Effects.addProperty("ADBE Polar Coordinates");
            // 调整参数
            Effect.property("ADBE Polar Coordinates-0001").setValue(1);
            Effect.property("ADBE Polar Coordinates-0002").setValue(1);
        }
    
    }else{

        alert("请先选择一个或多个层。");

    }

}else{

  alert("请先打开一个合成。");

}
