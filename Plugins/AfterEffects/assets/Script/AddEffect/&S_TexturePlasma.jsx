var activeComp = app.project.activeItem;

if (activeComp && activeComp instanceof CompItem) {

    var selectedLayers = app.project.activeItem.selectedLayers;

    if (selectedLayers.length > 0) {

        for (var i = 0; i < selectedLayers.length; i++) {

            var Effect = selectedLayers[i].Effects.addProperty("S_TexturePlasma");
            // 调整参数
            Effect.property("Noise Frequency").setValue(3);
            Effect.property("Phase Speed").setValue(4);
            Effect.property("Glow Color").setValue([0,0,0,1]);
        }
    
    }else{

        alert("请先选择一个或多个层。");

    }

}else{

  alert("请先打开一个合成。");

}
