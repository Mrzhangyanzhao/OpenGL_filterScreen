precision highp float;
varying lowp vec2 textureCoordVarying;
uniform sampler2D Texture;

void main (){
    vec2 uv = textureCoordVarying.xy;
    
    if(uv.x <= 0.5){
        uv.x = uv.x * 2.0;
    }else{
        uv.x = (uv.x - 0.5) * 2.0;
    }
    
    if (uv.y<= 0.5) {
        uv.y = uv.y * 2.0;
    }else{
        uv.y = (uv.y - 0.5) * 2.0;
    }
    gl_FragColor = texture2D(Texture,uv);
}

