attribute vec3 aPos;
attribute vec3 aColor;
attribute vec3 aColorSecond;
attribute vec3 aColorThird;
attribute float aSize;
attribute float aGlow;
attribute float aKind;
attribute float aCount;
attribute vec4 aOwner;
uniform mat4 uMVP;
uniform float uPointScale;
varying vec3 vTint,vTintSecond,vTintThird;
varying float vKind,vCount,vGlow;
varying vec4 vOwner;
void main(){
 vec4 p=uMVP*vec4(aPos,1.0);
 gl_Position=p;
 gl_PointSize=clamp(aSize*uPointScale/max(p.w,0.3),2.0,64.0);
 vTint=aColor;
 vTintSecond=aColorSecond;
 vTintThird=aColorThird;
 vKind=aKind;
 vCount=aCount;
 vGlow=aGlow;
vOwner=aOwner;
}
