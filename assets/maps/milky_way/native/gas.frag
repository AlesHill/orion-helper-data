precision mediump float;
varying vec2 vUV;
uniform sampler2D uGasLayer;
uniform float uFade,uOpacity;
void main(){
 // RGB заранее содержит цвет газа, умноженный на плотность и на 8.
 // Сложение GPU возвращает исходную картинку без повторных вычислений шума.
 vec3 gas=texture2D(uGasLayer,vUV).rgb;
 gl_FragColor=vec4(gas*uFade*uOpacity*0.125,1.0);
}
