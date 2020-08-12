precision highp float;
varying lowp vec2 textureCoordVarying;
uniform sampler2D Texture;

void main(){
    vec2 uv = textureCoordVarying.xy;
    float y;
    if (uv.y<= 0.5 && uv.y >= 0.0) {
        y = uv.y + 0.25;
    }else{
        y = uv.y - 0.25;
    }
    gl_FragColor = texture2D(Texture,vec2(uv.x,y));
}
