attribute vec3 aPos; attribute vec4 aColor; uniform mat4 uMVP; varying vec4 vColor; void main(){ gl_Position=uMVP*vec4(aPos,1.0);vColor=aColor;}
