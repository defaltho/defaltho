ArrayList<Ball> balls;
PFont font;
PFont uiFont;
int SPH_DETAIL = 20;
String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#&*!?{}[]<>^~";

String displayText = "THIS\nIS\nDBR STD";
String[] lines;

// Controllable parameters
float ballRadius = 65;
float ballSpacing = 1.55;
float spaceWidth = 0.8;
float lineSpacing = 2.2;
float mouseForce = 18.0;
float mouseZone = 5.0;
float springK = 0.04;
float springDamp = 0.88;
float rotSpringK = 0.06;
float rotDamp = 0.88;
float windAmount = 0.008;

// Modes
boolean freeMode = false;
boolean showUI = true;
boolean editingText = false;
int cursorBlink = 0;
int alignMode = 1; // 0=left, 1=center, 2=right

// Multi-line text buffer (stores actual newlines)
ArrayList<String> textLines = new ArrayList<String>();

// UI
Slider[] sliders;
float uiPanelW = 184;
float uiPanelH;
float alignBtnY;
float textFieldY;
float textAreaH = 60;

void setup() {
  size(1200, 800, P3D);
  smooth(2);
  String fontName = "SansSerif";
  String[] available = PFont.list();
  for (String f : available) {
    if (f.equals("Helvetica Bold")) { fontName = "Helvetica Bold"; break; }
    if (f.equals("Helvetica Neue Bold")) { fontName = "Helvetica Neue Bold"; break; }
    if (f.equals("Arial Bold")) { fontName = "Arial Bold"; break; }
  }
  font = createFont(fontName, 192);
  uiFont = createFont("SansSerif", 12);

  textLines.add("THIS");
  textLines.add("IS");
  textLines.add("DBR STD");

  buildSphereData();
  applyText();
  buildSliders();
  rebuildBalls();
}

void buildSliders() {
  int sx = 16;
  int sy = 16;
  int sw = 160;
  int sh = 12;
  int gap = 28;

  sliders = new Slider[] {
    new Slider("Scale",       sx, sy + gap*0,  sw, sh, 30, 120,  ballRadius),
    new Slider("Spacing",     sx, sy + gap*1,  sw, sh, 1.0, 2.5, ballSpacing),
    new Slider("Line Height", sx, sy + gap*2,  sw, sh, 1.5, 3.5, lineSpacing),
    new Slider("Mouse Force", sx, sy + gap*3,  sw, sh, 0, 40,    mouseForce),
    new Slider("Mouse Zone",  sx, sy + gap*4,  sw, sh, 2, 10,    mouseZone),
    new Slider("Spring K",    sx, sy + gap*5,  sw, sh, 0.005, 0.15, springK),
    new Slider("Spring Damp", sx, sy + gap*6,  sw, sh, 0.8, 0.99,  springDamp),
    new Slider("Rot Spring",  sx, sy + gap*7,  sw, sh, 0.01, 0.2,  rotSpringK),
    new Slider("Rot Damp",    sx, sy + gap*8,  sw, sh, 0.7, 0.98,  rotDamp),
    new Slider("Wind",        sx, sy + gap*9,  sw, sh, 0, 0.06,    windAmount),
  };

  alignBtnY = sy + gap * 10 + 10;
  textFieldY = alignBtnY + 28;
  textAreaH = 60;
  uiPanelH = textFieldY + textAreaH + 40;
}

void readSliders() {
  ballRadius  = sliders[0].val;
  ballSpacing = sliders[1].val;
  lineSpacing = sliders[2].val;
  mouseForce  = sliders[3].val;
  mouseZone   = sliders[4].val;
  springK     = sliders[5].val;
  springDamp  = sliders[6].val;
  rotSpringK  = sliders[7].val;
  rotDamp     = sliders[8].val;
  windAmount  = sliders[9].val;
}

void rebuildBalls() {
  balls = new ArrayList<Ball>();

  if (freeMode) {
    for (int i = 0; i < 40; i++) {
      float ang = random(TWO_PI);
      float dist = random(40, 300);
      char c = chars.charAt((int) random(chars.length()));
      Ball b = new Ball(width/2 + cos(ang)*dist, height/2 + sin(ang)*dist, c, i);
      b.hasHome = false;
      balls.add(b);
    }
    return;
  }

  float lh = ballRadius * lineSpacing;
  float totalH = lines.length * lh;
  float startY = (height - totalH) / 2 + ballRadius;
  float margin = ballRadius;

  for (int l = 0; l < lines.length; l++) {
    String line = lines[l];
    float sp = ballRadius * ballSpacing;
    float sw = ballRadius * spaceWidth;
    float lineW = 0;

    for (int i = 0; i < line.length(); i++) {
      lineW += (line.charAt(i) == ' ') ? sw : sp;
    }
    if (line.length() > 0) {
      lineW -= (line.charAt(line.length()-1) == ' ') ? sw : sp;
    }

    float cx;
    if (alignMode == 0) {
      cx = margin;
    } else if (alignMode == 2) {
      cx = width - lineW - margin;
    } else {
      cx = (width - lineW) / 2;
    }
    float cy = startY + l * lh;

    for (int i = 0; i < line.length(); i++) {
      char c = line.charAt(i);
      if (c == ' ') {
        cx += sw;
        continue;
      }
      Ball b = new Ball(cx, cy, c, balls.size());
      b.hasHome = true;
      balls.add(b);
      cx += sp;
    }
  }
}

void draw() {
  background(0);

  float fov = PI / 4.0;
  float cameraZ = (height / 2.0) / tan(fov / 2.0);
  perspective(fov, (float) width / height, 10, cameraZ * 4);
  camera(width / 2, height / 2, cameraZ, width / 2, height / 2, 0, 0, 1, 0);
  noLights();
  noStroke();

  PVector mouse = new PVector(mouseX, mouseY, 0);
  float t = frameCount * 0.004;

  boolean overUI = false;
  if (showUI) {
    if (mouseX < uiPanelW + 16 && mouseY < uiPanelH + 16) {
      overUI = true;
    }
    for (Slider s : sliders) {
      if (s.dragging) { overUI = true; break; }
    }
  }

  for (Ball b : balls) {
    if (!overUI) b.repelFromMouse(mouse);
    b.applyWind(t);
    if (b.hasHome) {
      b.springBack();
    } else {
      b.attractToCenter();
    }
    b.update();
  }

  for (int pass = 0; pass < 3; pass++) {
    for (int i = 0; i < balls.size(); i++) {
      for (int j = i + 1; j < balls.size(); j++) {
        balls.get(i).collide(balls.get(j));
      }
    }
  }

  for (Ball b : balls) {
    b.display();
  }

  // UI
  if (showUI) {
    hint(DISABLE_DEPTH_TEST);
    camera();
    noLights();
    ortho();

    noStroke();
    fill(0, 200);
    rect(8, 8, uiPanelW + 8, uiPanelH, 6);

    for (Slider s : sliders) {
      s.display();
    }

    float tfx = 16;

    // Alignment buttons
    fill(255, 180);
    textFont(uiFont);
    textAlign(LEFT, BOTTOM);
    textSize(10);
    text("Align:", tfx, alignBtnY);

    String[] alignLabels = {"LEFT", "CENTER", "RIGHT"};
    float btnW = 50;
    float btnGap = 5;
    float btnX = tfx;
    float btnY = alignBtnY + 3;
    for (int i = 0; i < 3; i++) {
      boolean active = (alignMode == i);
      noStroke();
      fill(active ? 255 : 60);
      rect(btnX, btnY, btnW, 18, 3);
      fill(active ? 0 : 200);
      textAlign(CENTER, CENTER);
      textSize(10);
      text(alignLabels[i], btnX + btnW / 2, btnY + 8);
      btnX += btnW + btnGap;
    }

    // Text area label
    fill(255, 180);
    textAlign(LEFT, BOTTOM);
    textSize(10);
    text("Text (Enter = new line, Esc = apply):", tfx, textFieldY);

    // Text area box
    if (editingText) {
      stroke(255);
    } else {
      stroke(80);
    }
    strokeWeight(1);
    fill(editingText ? 30 : 15);
    rect(tfx, textFieldY + 3, 160, textAreaH, 3);

    // Draw text lines inside the area
    noStroke();
    fill(255);
    textAlign(LEFT, TOP);
    textSize(11);

    cursorBlink++;
    float lineH = 14;
    float areaTop = textFieldY + 7;
    float areaBottom = textFieldY + 3 + textAreaH - 4;
    int maxVisible = (int)((areaBottom - areaTop) / lineH);
    int startLine = max(0, textLines.size() - maxVisible);

    for (int i = startLine; i < textLines.size(); i++) {
      float textY = areaTop + (i - startLine) * lineH;
      if (textY > areaBottom) break;
      String ln = textLines.get(i);
      boolean isLastLine = (i == textLines.size() - 1);
      String displayLn = ln;
      if (editingText && isLastLine && (cursorBlink / 30) % 2 == 0) {
        displayLn += "|";
      }
      text(displayLn, tfx + 4, textY);
    }

    // Free mode toggle
    float toggleY = textFieldY + textAreaH + 12;
    fill(freeMode ? 255 : 80);
    noStroke();
    rect(tfx, toggleY, 160, 20, 3);
    fill(freeMode ? 0 : 200);
    textAlign(CENTER, CENTER);
    textSize(11);
    text(freeMode ? "FREE MODE  [ON]" : "FREE MODE  [OFF]", tfx + 80, toggleY + 9);

    hint(ENABLE_DEPTH_TEST);
  }
}

void mousePressed() {
  if (showUI) {
    // Check sliders
    for (Slider s : sliders) {
      if (s.isOver(mouseX, mouseY)) {
        s.dragging = true;
        return;
      }
    }

    float tfx = 16;

    // Check alignment buttons
    float btnW = 50;
    float btnGap = 5;
    float btnX = tfx;
    float btnY = alignBtnY + 3;
    for (int i = 0; i < 3; i++) {
      if (mouseX >= btnX && mouseX <= btnX + btnW && mouseY >= btnY && mouseY <= btnY + 18) {
        alignMode = i;
        if (!freeMode) rebuildBalls();
        return;
      }
      btnX += btnW + btnGap;
    }

    // Check text area click
    if (mouseX >= tfx && mouseX <= tfx + 160 && mouseY >= textFieldY + 3 && mouseY <= textFieldY + 3 + textAreaH) {
      editingText = true;
      return;
    } else {
      if (editingText) {
        editingText = false;
        applyText();
      }
    }

    // Check free mode toggle
    float toggleY = textFieldY + textAreaH + 12;
    if (mouseX >= tfx && mouseX <= tfx + 160 && mouseY >= toggleY && mouseY <= toggleY + 20) {
      freeMode = !freeMode;
      rebuildBalls();
      return;
    }
  }

  // Free mode: click to add ball
  if (freeMode) {
    boolean overUI = showUI && mouseX < uiPanelW + 16 && mouseY < uiPanelH + 16;
    if (!overUI) {
      char c = chars.charAt((int) random(chars.length()));
      Ball b = new Ball(mouseX, mouseY, c, balls.size());
      b.hasHome = false;
      balls.add(b);
    }
  }
}

void mouseDragged() {
  boolean changed = false;
  for (Slider s : sliders) {
    if (s.dragging) {
      s.updateVal(mouseX);
      changed = true;
    }
  }
  if (changed) {
    float oldRadius = ballRadius;
    float oldSpacing = ballSpacing;
    float oldLine = lineSpacing;
    readSliders();
    if (!freeMode && (abs(ballRadius - oldRadius) > 0.5 ||
        abs(ballSpacing - oldSpacing) > 0.01 ||
        abs(lineSpacing - oldLine) > 0.01)) {
      rebuildBalls();
    }
  }
}

void mouseReleased() {
  for (Slider s : sliders) {
    s.dragging = false;
  }
}

void keyPressed() {
  if (editingText) {
    if (key == ESC) {
      editingText = false;
      applyText();
      key = 0;
    } else if (key == ENTER || key == RETURN) {
      textLines.add("");
    } else if (key == BACKSPACE) {
      int last = textLines.size() - 1;
      if (last >= 0) {
        String lastLine = textLines.get(last);
        if (lastLine.length() > 0) {
          textLines.set(last, lastLine.substring(0, lastLine.length() - 1));
        } else if (textLines.size() > 1) {
          textLines.remove(last);
        }
      }
    } else if (key >= 32 && key < 127) {
      int last = textLines.size() - 1;
      if (last >= 0) {
        textLines.set(last, textLines.get(last) + key);
      }
    }
    return;
  }

  if (key == 'h' || key == 'H') {
    showUI = !showUI;
  }
  if (key == 'r' || key == 'R') {
    rebuildBalls();
  }
  if (key == 'f' || key == 'F') {
    freeMode = !freeMode;
    rebuildBalls();
  }
  if (key == '1') { alignMode = 0; if (!freeMode) rebuildBalls(); }
  if (key == '2') { alignMode = 1; if (!freeMode) rebuildBalls(); }
  if (key == '3') { alignMode = 2; if (!freeMode) rebuildBalls(); }
}

void applyText() {
  StringBuilder sb = new StringBuilder();
  for (int i = 0; i < textLines.size(); i++) {
    if (i > 0) sb.append('\n');
    sb.append(textLines.get(i));
  }
  displayText = sb.toString();
  lines = split(displayText, '\n');
  if (!freeMode) {
    rebuildBalls();
  }
}

// Pre-computed unit sphere geometry (shared by all balls)
float[][] sphVerts;
float[][] sphNorms;
float[][] sphUVs;

void buildSphereData() {
  int total = SPH_DETAIL * SPH_DETAIL * 6;
  sphVerts = new float[total][3];
  sphNorms = new float[total][3];
  sphUVs   = new float[total][2];
  int idx = 0;
  for (int i = 0; i < SPH_DETAIL; i++) {
    float lat0 = map(i, 0, SPH_DETAIL, 0, PI);
    float lat1 = map(i + 1, 0, SPH_DETAIL, 0, PI);
    for (int j = 0; j < SPH_DETAIL; j++) {
      float lon0 = map(j, 0, SPH_DETAIL, 0, TWO_PI);
      float lon1 = map(j + 1, 0, SPH_DETAIL, 0, TWO_PI);

      float x0=sin(lat0)*cos(lon0), y0=cos(lat0), z0=sin(lat0)*sin(lon0);
      float x1=sin(lat0)*cos(lon1), y1=cos(lat0), z1=sin(lat0)*sin(lon1);
      float x2=sin(lat1)*cos(lon1), y2=cos(lat1), z2=sin(lat1)*sin(lon1);
      float x3=sin(lat1)*cos(lon0), y3=cos(lat1), z3=sin(lat1)*sin(lon0);

      sphVerts[idx] = new float[]{x0,y0,z0}; sphNorms[idx] = new float[]{x0,y0,z0}; sphUVs[idx] = new float[]{0.5+x0/2, 0.5+y0/2}; idx++;
      sphVerts[idx] = new float[]{x1,y1,z1}; sphNorms[idx] = new float[]{x1,y1,z1}; sphUVs[idx] = new float[]{0.5+x1/2, 0.5+y1/2}; idx++;
      sphVerts[idx] = new float[]{x2,y2,z2}; sphNorms[idx] = new float[]{x2,y2,z2}; sphUVs[idx] = new float[]{0.5+x2/2, 0.5+y2/2}; idx++;
      sphVerts[idx] = new float[]{x0,y0,z0}; sphNorms[idx] = new float[]{x0,y0,z0}; sphUVs[idx] = new float[]{0.5+x0/2, 0.5+y0/2}; idx++;
      sphVerts[idx] = new float[]{x2,y2,z2}; sphNorms[idx] = new float[]{x2,y2,z2}; sphUVs[idx] = new float[]{0.5+x2/2, 0.5+y2/2}; idx++;
      sphVerts[idx] = new float[]{x3,y3,z3}; sphNorms[idx] = new float[]{x3,y3,z3}; sphUVs[idx] = new float[]{0.5+x3/2, 0.5+y3/2}; idx++;
    }
  }
}

void drawTexturedSphere(float r, PImage tex) {
  textureMode(NORMAL);
  beginShape(TRIANGLES);
  noStroke();
  texture(tex);
  for (int i = 0; i < sphVerts.length; i++) {
    normal(sphNorms[i][0], sphNorms[i][1], sphNorms[i][2]);
    vertex(sphVerts[i][0]*r, sphVerts[i][1]*r, sphVerts[i][2]*r, sphUVs[i][0], sphUVs[i][1]);
  }
  endShape();
}


class Ball {
  PVector pos, vel;
  PVector home;
  boolean hasHome;
  float radius, mass;
  float rotX, rotY, rotZ;
  float rotVelX, rotVelY, rotVelZ;
  float noiseOffX, noiseOffY;
  PImage tex;
  char glyph;
  int id;

  Ball(float x, float y, char c, int _id) {
    home = new PVector(x, y, 0);
    pos = new PVector(x, y, 0);
    vel = new PVector(0, 0, 0);
    radius = ballRadius;
    mass = radius * radius;
    id = _id;
    hasHome = true;

    rotX = 0; rotY = 0; rotZ = 0;
    rotVelX = 0; rotVelY = 0; rotVelZ = 0;

    noiseOffX = random(1000);
    noiseOffY = random(2000);

    glyph = c;
    tex = makeTexture();
  }

  PImage makeTexture() {
    int s = 256;
    PGraphics pg = createGraphics(s, s);
    pg.beginDraw();
    pg.background(255);
    pg.fill(0);
    pg.textFont(font);
    pg.textAlign(CENTER, CENTER);
    pg.textSize(s * 0.72);
    pg.text(glyph, s / 2, s / 2 - s * 0.04);
    pg.endDraw();
    PImage img = pg.get();
    pg.dispose();
    return img;
  }

  void applyWind(float t) {
    vel.x += (noise(noiseOffX + t) - 0.5) * windAmount;
    vel.y += (noise(noiseOffY + t) - 0.5) * windAmount;
  }

  void attractToCenter() {
    float cx = width / 2;
    float cy = height / 2;
    float dx = cx - pos.x;
    float dy = cy - pos.y;
    float d = sqrt(dx*dx + dy*dy);
    if (d > 1) {
      vel.x += (dx / d) * d * 0.0003;
      vel.y += (dy / d) * d * 0.0003;
    }
    vel.mult(0.97);

    rotVelX += -rotX * 0.01;
    rotVelY += -rotY * 0.01;
    rotVelZ += -rotZ * 0.01;
    rotVelX *= 0.95;
    rotVelY *= 0.95;
    rotVelZ *= 0.95;
  }

  void repelFromMouse(PVector mouse) {
    float dx = pos.x - mouse.x;
    float dy = pos.y - mouse.y;
    float d = sqrt(dx * dx + dy * dy);
    float zone = radius * mouseZone;
    if (d < zone && d > 1) {
      float strength = map(d, 0, zone, mouseForce, 0);
      float nx = dx / d;
      float ny = dy / d;
      vel.x += nx * strength * 0.3;
      vel.y += ny * strength * 0.3;
      vel.z += random(-0.5, 0.5) * strength * 0.1;

      rotVelX += ny * strength * 0.008;
      rotVelY -= nx * strength * 0.008;
      rotVelZ += random(-1, 1) * strength * 0.003;
    }
  }

  void springBack() {
    vel.x += (home.x - pos.x) * springK;
    vel.y += (home.y - pos.y) * springK;
    vel.z += (0 - pos.z) * springK;

    rotVelX += -rotX * rotSpringK;
    rotVelY += -rotY * rotSpringK;
    rotVelZ += -rotZ * rotSpringK;

    rotVelX *= rotDamp;
    rotVelY *= rotDamp;
    rotVelZ *= rotDamp;
  }

  void update() {
    if (hasHome) {
      vel.mult(springDamp);
    }
    pos.add(vel);

    rotX += rotVelX;
    rotY += rotVelY;
    rotZ += rotVelZ;

    if (!hasHome) {
      float m = radius;
      if (pos.x < m) { pos.x = m; vel.x *= -0.3; }
      if (pos.x > width - m) { pos.x = width - m; vel.x *= -0.3; }
      if (pos.y < m) { pos.y = m; vel.y *= -0.3; }
      if (pos.y > height - m) { pos.y = height - m; vel.y *= -0.3; }
    }
  }

  void collide(Ball other) {
    PVector diff = PVector.sub(other.pos, pos);
    float dist = diff.mag();
    float minDist = radius * 2;
    if (dist < minDist && dist > 0.01) {
      PVector n = diff.copy().normalize();
      float overlap = minDist - dist;
      pos.sub(PVector.mult(n, overlap * 0.25));
      other.pos.add(PVector.mult(n, overlap * 0.25));

      PVector relVel = PVector.sub(vel, other.vel);
      float vn = relVel.dot(n);
      if (vn > 0) return;

      float j = -(1 + 0.15) * vn * 0.5;
      PVector impulse = PVector.mult(n, j);
      vel.add(impulse);
      other.vel.sub(impulse);
    }
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotateX(rotX);
    rotateY(rotY);
    rotateZ(rotZ);
    drawTexturedSphere(radius, tex);
    popMatrix();
  }
}


class Slider {
  String label;
  float x, y, w, h;
  float minVal, maxVal, val;
  boolean dragging = false;

  Slider(String _label, float _x, float _y, float _w, float _h, float _min, float _max, float _val) {
    label = _label;
    x = _x; y = _y; w = _w; h = _h;
    minVal = _min; maxVal = _max; val = _val;
  }

  boolean isOver(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y - 4 && my <= y + h + 10;
  }

  void updateVal(float mx) {
    float t = constrain((mx - x) / w, 0, 1);
    val = lerp(minVal, maxVal, t);
  }

  void display() {
    float t = (val - minVal) / (maxVal - minVal);

    fill(255, 180);
    textFont(uiFont);
    textAlign(LEFT, BOTTOM);
    textSize(10);
    text(label + ": " + nf(val, 1, 2), x, y);

    noStroke();
    fill(60);
    rect(x, y + 2, w, h, 3);

    fill(255);
    rect(x, y + 2, w * t, h, 3);

    float hx = x + w * t;
    fill(255);
    ellipse(hx, y + 2 + h / 2, h + 4, h + 4);
  }
}
