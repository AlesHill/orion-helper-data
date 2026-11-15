precision mediump float;
varying vec4 vColor;
uniform float uExposure;
uniform float uOpacity;
void main() {
  gl_FragColor = vec4(min(vColor.rgb*uExposure,vec3(1.0)), clamp(vColor.a*uOpacity,0.0,1.0));
}
