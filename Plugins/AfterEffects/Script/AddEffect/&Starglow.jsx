var activeComp = app.project.activeItem;

if (activeComp && activeComp instanceof CompItem) {

    var selectedLayers = app.project.activeItem.selectedLayers;

    if (selectedLayers.length > 0) {

        for (var i = 0; i < selectedLayers.length; i++) {

            var Effect = selectedLayers[i].Effects.addProperty("Starglow");
            // 调整模糊效果的参数
            Effect.property("Up Left").setValue(0);
            Effect.property("Up Right").setValue(0);
            Effect.property("Down Left").setValue(0);
            Effect.property("Down Right").setValue(0);
            Effect.property("tc Starglow-0023").setValue(1);
            Effect.property("tc Starglow-0026").setValue([1,1,1,1]);
            Effect.property("tc Starglow-0031").setValue(1);
            Effect.property("tc Starglow-0034").setValue([1,1,1,1]);
        }
    
    }else{

        alert("请先选择一个或多个层。");

    }

}else{

  alert("请先打开一个合成。");

}
