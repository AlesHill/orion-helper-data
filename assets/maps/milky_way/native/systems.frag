precision mediump float;
varying vec3 vTint,vTintSecond,vTintThird;
varying float vKind,vCount,vGlow;
varying vec4 vOwner;
uniform float uTime;
float spot(vec2 p,vec2 c,float k){vec2 q=p-c;return exp(-k*dot(q,q));}
void main(){
 vec2 p=gl_PointCoord*2.0-1.0;
 float r=length(p);
 float core=exp(-15.0*r*r);
 float halo=exp(-3.0*r*r);
 float alpha=clamp((.95*core+.38*halo)*vGlow,0.0,1.0);
 vec3 col=vTint;
 if(vKind < -0.5){
  // Пустой объект: никакого звёздного ядра, только слабый контур маркера.
  float outline = 1.0-smoothstep(.030,.085,abs(r-.58));
  alpha = outline*.62;
 } else if(vCount>1.5){
  float a=uTime*.20;
  vec2 shift=vec2(cos(a),sin(a))*.30;
  float left=spot(p,shift,29.0),right=spot(p,-shift,30.0);
  float third=(vCount>2.5) ? (.80*spot(p,vec2(.0,.38),28.0)) : 0.0;
  float lights=left+right+third;
  col=(vTint*left+vTintSecond*right+vTintThird*third)/max(.0001,lights);
  alpha=clamp((lights*.87+.16*halo)*vGlow,0.0,1.0);
 } else if(vKind>5.5&&vKind<6.5){
  // Чёрная дыра: тёмный силуэт, тонкий аккреционный обод и широкий мягкий ореол.
  float ring=exp(-pow((r-.52)*13.0,2.0));
  float outer=exp(-pow((r-.65)*4.5,2.0))*.17;
  col=mix(vec3(.006,.008,.016),vTint,clamp(ring*1.5+outer,.0,1.0));
  alpha=clamp((r<.37? .96: ring*.92+outer)*vGlow,0.0,1.0);
 } else if(vKind>6.5&&vKind<7.5){
  // Пульсар: узкие противоположные лучи и регулярно пульсирующее ядро.
  float ray=exp(-p.x*p.x*95.0)*(1.0-smoothstep(.1,.98,abs(p.y)));
  alpha=clamp((core*(1.0+.22*sin(uTime*2.4))+ray*.50+.14*halo)*vGlow,0.0,1.0);
 } else if(vKind>7.5&&vKind<8.5){
  // Магнетар: холодные дуги и пульсация магнитного ореола.
  float angle=atan(p.y,p.x)+uTime*.08;
  float ring=exp(-pow((r-.63)*11.0,2.0))*(.55+.45*cos(angle*4.0));
  alpha=clamp((core*(1.0+.16*sin(uTime*1.6))+ring*.55+.12*halo)*vGlow,0.0,1.0);
 } else if(vKind>9.5){
  // Вольфа — Райе: горячая звезда с расширенным неоднородным ветром.
  float a=atan(p.y,p.x);
  float wind=(.6+.4*cos(a*7.0+uTime*.12))*exp(-3.8*r*r);
  alpha=clamp((core+wind*.43)*vGlow,0.0,1.0);
 } else if(vKind>2.5&&vKind<3.5){
  // Сверхгигант: широкое свечение с несколькими дифракционными лучами.
  float cross=exp(-p.x*p.x*82.0)+exp(-p.y*p.y*82.0);
  alpha=clamp((core+.55*halo+.18*cross)*vGlow,0.0,1.0);
 } else if(vKind>1.5&&vKind<2.5){
  // Красный гигант: широкая мягкая оболочка.
  alpha=clamp((.65*core+.75*exp(-2.0*r*r))*vGlow,0.0,1.0);
 } else if(vKind>3.5&&vKind<5.5){
  // Белые карлики и нейтронные звёзды выглядят компактнее.
  alpha=clamp((1.05*exp(-26.0*r*r)+.16*halo)*vGlow,0.0,1.0);
 } else if(vKind>8.5&&vKind<9.5){
  // Коричневые карлики дают слабое, рассеянное свечение.
  alpha=clamp((.50*core+.15*halo)*vGlow,0.0,1.0);
 }
 // Тонкий обруч показывает государство, не меняя спектральный цвет звезды.
 float ownerRing=(1.0-smoothstep(.027,.072,abs(r-.83)))*vOwner.a;
 col=mix(col,vOwner.rgb,ownerRing);
 alpha=max(alpha,ownerRing*.92);
 if(r>1.0||alpha<.002)discard;
 gl_FragColor=vec4(col,alpha);
}
