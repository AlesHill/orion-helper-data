precision mediump float; varying vec4 vColor; uniform float uExposure; void main(){gl_FragColor=vec4(vColor.rgb*uExposure,vColor.a);}
