var activeComp = app.project.activeItem;

if (activeComp && activeComp instanceof CompItem) {

    var selectedLayers = app.project.activeItem.selectedLayers;

    if (selectedLayers.length > 0) {

        for (var i = 0; i < selectedLayers.length; i++) {

            var Effect = selectedLayers[i].Effects.addProperty("Particular");


            Effect.property("Velocity").setValue(200);
            Effect.property("Life [sec]").setValue(0.8);
            Effect.property("Life Random").setValue(50);

            Effect.property("Size").setValue(5);
            Effect.property("Size Random").setValue(50);

            // Effect.property("Set Color").setValue(2); 添加颜色
            Effect.property("Air Resistance").setValue(1);
        }
    
    }else{

        alert("请先选择一个或多个层。");

    }

}else{

  alert("请先打开一个合成。");

}
