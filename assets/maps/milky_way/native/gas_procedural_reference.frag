precision highp float;
varying vec2 vUV;
uniform sampler2D uGalaxy,uSectorField,uGuides;
uniform float uTime,uLayer,uOpacity,uBrightness,uSaturation,uDrift;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
float noise2(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),
            mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),f.x),f.y);
}
float fbm(vec2 p){
 float v=0.0,a=.54;
 for(int i=0;i<4;i++){v+=a*noise2(p);p=p*2.03+vec2(7.11,13.27);a*=.51;}
 return v;
}
void main(){
 vec2 uv=vUV;
 if(uv.x<0.0||uv.y<0.0||uv.x>1.0||uv.y>1.0)discard;
 // Маска заранее сглажена: один выборочный запрос вместо девяти.
 vec3 mask=texture2D(uSectorField,uv).rgb;
 float inSector=mask.g;
 float softEdge=clamp(mask.r,0.0,1.0);
 vec2 center=uv-.5;
 float rad=length(center)*2.0;
 // Основа всё ещё строится от секторной формы, но сама форма размывается,
 // чтобы не давать резких обрывов и жёстких внутренних перепадов.
 float feather=smoothstep(0.0,1.0,softEdge);
 float sectorHaze=smoothstep(0.0,0.88,softEdge);
 float diskBase=(1.0-smoothstep(0.18,1.12,rad));
 float allow=pow(clamp(feather*.46 + sectorHaze*.30 + inSector*.16 + diskBase*.18,0.0,1.0),0.56);
 if(allow<.00018)discard;
 float t=uTime*uDrift*.006;
 float turn=atan(center.y,center.x);
 vec2 drift=vec2(cos(turn+1.57),sin(turn+1.57))*t;
 vec2 nUv=uv+drift*(.4+.3*uLayer);
 float broad=fbm(nUv*14.2+vec2(1.3*uLayer,2.4*uLayer));
 float mid=fbm(nUv*57.0+vec2(6.2*uLayer,-2.3*uLayer));
 float fine=fbm(nUv*133.0-vec2(2.0*uLayer,1.3*uLayer));
 vec2 warp=vec2(mid-.5,broad-.5)*(.010+.005*uLayer);
 vec3 photo=texture2D(uGalaxy,clamp(uv+warp,0.001,.999)).rgb;
 vec3 guide=texture2D(uGuides,uv).rgb;
 float lum=dot(photo,vec3(.299,.587,.114));
 // Спиральная яркость берётся из формы пользовательского изображения,
 // а контуры секторов ограничивают газ снаружи.
 float arm=pow(clamp(lum*2.10,0.0,1.0),1.04);
 float filaments=smoothstep(.08,.74,broad*.46+mid*.34+fine*.20);
 float lane=smoothstep(.08,.60,mid);
 float interArm=0.26 + 0.30*diskBase + 0.12*sectorHaze;
 float armBody=(0.34+0.58*arm)*(.70+.26*filaments)*(.88+.14*lane);
 float density=interArm + armBody;
 density*=mix(.92,1.02,guide.r*.30+guide.g*.16+inSector*.12);
 density*=mix(.60,1.0,allow);
 float core=exp(-rad*rad*18.0);
 density+=core*(0.22+0.28*allow);
 // Колориметрия близка к исходной картине: дымчатые голубые, розовые,
 // серо-фиолетовые рукава и тёплое кремовое ядро.
 vec3 pale=pow(max(photo,vec3(.003)),vec3(.80));
 vec3 cool=vec3(.26,.33,.44);
 vec3 dusty=vec3(.50,.44,.49);
 float rose=smoothstep(.14,.62,photo.r-photo.b*.42+mid*.10);
 vec3 gas=mix(cool,dusty,rose*.54);
 gas=mix(gas,pale*1.04,.64);
 gas=mix(gas,vec3(.98,.87,.73),clamp(core*.72,0.,1.));
 float grey=dot(gas,vec3(.2126,.7152,.0722));
 gas=mix(vec3(grey),gas,uSaturation*.92);
 // Ещё мягче и ровнее: меньше пиковая плотность, больше общий туманный слой.
 float alpha=clamp(density*uOpacity*(.036+.040*filaments)*(.72+.28*allow),0.0,.108);
 gl_FragColor=vec4(gas*uBrightness,alpha);
}
