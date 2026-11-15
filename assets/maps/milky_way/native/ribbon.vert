attribute vec3 aStart;
attribute vec3 aEnd;
attribute vec4 aColor;
attribute float aCorner;
uniform mat4 uMVP;
uniform vec2 uViewport;
uniform float uThickness;
varying vec4 vColor;
void main() {
  vec4 a = uMVP * vec4(aStart, 1.0);
  vec4 b = uMVP * vec4(aEnd, 1.0);
  float endVertex = step(1.5, abs(aCorner));
  vec4 pos = mix(a, b, endVertex);
  vec2 dir = (b.xy/max(b.w,.01) - a.xy/max(a.w,.01)) * uViewport;
  dir /= max(length(dir), .001);
  vec2 normal = vec2(-dir.y, dir.x);
  float side = sign(aCorner);
  pos.xy += normal * side * uThickness / uViewport * pos.w;
  gl_Position = pos;
  vColor = aColor;
}
