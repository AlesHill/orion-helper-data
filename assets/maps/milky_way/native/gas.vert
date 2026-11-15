attribute vec3 aPos;
uniform mat4 uMVP;
uniform float uLayerZ,uThickness;
varying vec2 vUV;
void main(){
 vUV=vec2((aPos.x+5.0)/10.0,1.0-(aPos.y+5.0)/10.0);
 gl_Position=uMVP*vec4(aPos.xy,uLayerZ*uThickness,1.0);
}
