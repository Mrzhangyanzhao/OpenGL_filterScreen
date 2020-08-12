precision highp float;

varying lowp vec2 textureCoordVarying;
uniform sampler2D Texture;

void main (){
    vec2 uv = textureCoordVarying.xy;
    if (uv.y < 1.0/3.0) {
        uv.y = uv.y + 1.0/3.0;
    } else if (uv.y > 2.0/3.0){
        uv.y = uv.y - 1.0/3.0;
    }
    gl_FragColor = texture2D(Texture, uv);
}
