uniform sampler2D texture;
uniform vec3 lightDir;

varying vec3 vNormal;
varying vec2 vTexCoord;

void main() {
  vec4 texColor = texture2D(texture, vTexCoord);

  float diff = dot(normalize(vNormal), normalize(lightDir));

  // 3-band toon quantization
  float shade;
  if (diff > 0.5) {
    shade = 1.0;
  } else if (diff > 0.0) {
    shade = 0.78;
  } else {
    shade = 0.55;
  }

  gl_FragColor = vec4(texColor.rgb * shade, texColor.a);
}
