precision mediump float;
varying vec4 vColor;
uniform float uExposure,uSaturation;
void main(){
 vec2 d=gl_PointCoord*2.-1.;
 float r=dot(d,d);
 // Яркий звёздный центр и мягкое цветное гало; отдельно от толщины диска.
 float core=exp(-7.0*r);
 float halo=exp(-2.5*r)*(1.0-smoothstep(.82,1.0,r));
 float fall=.38*halo+.82*core;
 float gray=dot(vColor.rgb,vec3(.2126,.7152,.0722));
 vec3 tint=max(vec3(0.),mix(vec3(gray),vColor.rgb,uSaturation));
 gl_FragColor=vec4(tint*uExposure,vColor.a*fall*uExposure);
}
