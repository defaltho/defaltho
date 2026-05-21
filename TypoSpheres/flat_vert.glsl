uniform mat4 transformMatrix;
uniform mat3 normalMatrix;

attribute vec4 position;
attribute vec3 normal;
attribute vec2 texCoord;

varying vec3 vNormal;
varying vec2 vTexCoord;

void main() {
  vNormal = normalize(normalMatrix * normal);
  vTexCoord = texCoord;
  gl_Position = transformMatrix * position;
}
