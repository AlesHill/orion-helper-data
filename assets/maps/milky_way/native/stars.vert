attribute vec3 aPos;
attribute vec4 aColor;
attribute float aSize;
attribute float aPhase; // Индивидуальная фаза мерцания

uniform mat4 uMVP;
uniform float uDotScale,uTime,uTwinkle,uDrift,uThickness,uGuide;
varying vec4 vColor;
void main(){
  vec3 p=aPos;
  // Небольшое тангенциальное движение фоновых звёзд, без изменения координат систем.
  float radius=max(length(p.xy),.06);
  vec2 tangent=vec2(-p.y,p.x)/radius;
  float t=uTime*.16+aPhase;
  p.xy += tangent * (uDrift * .006 * sin(t));
  p.z *= uThickness;
  vec4 q=uMVP*vec4(p,1.0);
  gl_Position=q;
  gl_PointSize=clamp(aSize*uDotScale/max(q.w,.5),1.0,54.0);
  float pulse=1.0 + uTwinkle*.13*sin(uTime*.88+aPhase);
  
  vColor=vec4(aColor.rgb*pulse,aColor.a*pulse);
}
