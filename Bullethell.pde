import ddf.minim.*;

final float PLAYER_SPEED         = 0.4;
final float LAZOR_SPEED          = 0.7;
final int   LAZOR_NUM            = 32;
final int   LAZOR_DELAY          = 150;
final float ENEMY_SPEED_INIT     = 0.1;
final float ENEMY_SPEED_INC      = 0.33;
final int   ENEMY_NUM            = 30;
final int   ENEMY_DELAY_INIT     = 800;
final float ENEMY_DELAY_INC      = 0.33;
final float FIREBALL_SPEED       = 0.4;
final int   FIREBALL_NUM         = 10;
final int   FIREBALL_DELAY_INIT  = 400;
final float FIREBALL_DELAY_INC   = 0.1667;


final int   KILL_SCORE           = 10;
final int   START_DELAY          = 1000;
final int   LEVEL_DELAY          = 10000;
final int   UPGRADE_DELAY        = 5000;

Minim minim;
AudioPlayer explosion, lose, pew, roundstart, start, ufo_pew, upgrade, levelup;

PImage rocket, space_background, fireball, upgrade_rpm, upgrade_double;
PImage[] lazor = new PImage[4];
PImage[] enemy = new PImage[5];

float posX, posY;
int dirX, dirY;

int levelTimer;
int level;

int upgradeState;
int upgradeType;
float upgradeX, upgradeY;
boolean upgradeAlive;
int upgradeTimer;

float[] lazorX = new float[LAZOR_NUM];
float[] lazorY = new float[LAZOR_NUM];
boolean[] lazorAlive = new boolean[LAZOR_NUM];
int lazorTimer;


float[] enemyX = new float[ENEMY_NUM];
float[] enemyY = new float[ENEMY_NUM];
int[] enemyHealth = new int[ENEMY_NUM];
int[] enemyType = new int[ENEMY_NUM];
float enemySpeed; 
int enemyTimer;
float enemyDelay;

float[] fireballX = new float[FIREBALL_NUM];
float[] fireballY = new float[FIREBALL_NUM];
float[] fireballDirX = new float[FIREBALL_NUM];
float[] fireballDirY = new float[FIREBALL_NUM];
boolean[] fireballAlive = new boolean[FIREBALL_NUM];
int fireballTimer = 0;
float fireballDelay;

boolean gameover = true;
int score;

boolean gameover_freeze = false;
float slowmo_factor = 1.0;

int[] highscores = new int[10];

int lastTime = 0;

boolean showFramerate = false;

void setup() {
  size(800, 640);
  frameRate(100);
  imageMode(CENTER);
  space_background = loadImage("Sprites/background_large.png");
  //  space_background.resize(640, 640);
  rocket = loadImage("Sprites/rocket.png");
  lazor[0] = loadImage("Sprites/lazer_blue.png");
  lazor[1] = loadImage("Sprites/lazer_green.png");
  lazor[2] = loadImage("Sprites/lazer_red.png");
  lazor[3] = loadImage("Sprites/lazer_yellow.png");
  fireball = loadImage("Sprites/fireball.png");
  enemy[0] = loadImage("Sprites/meteorite_large1.png");
  enemy[1] = loadImage("Sprites/meteorite_large2.png"); 
  enemy[2] = loadImage("Sprites/ufo.png");
  enemy[3] = loadImage("Sprites/meteorite_medium1.png");
  enemy[4] = loadImage("Sprites/meteorite_medium2.png");
  upgrade_double = loadImage("Sprites/nuclear.png");
  upgrade_rpm = loadImage("Sprites/energy.png");

  minim = new Minim(this);

  explosion =  minim.loadFile("Sounds/explosion.wav");
  lose =  minim.loadFile("Sounds/lose.wav");
  pew =  minim.loadFile("Sounds/pew.wav");
  roundstart =  minim.loadFile("Sounds/roundstart.wav");
  start =  minim.loadFile("Sounds/start.wav");
  ufo_pew =  minim.loadFile("Sounds/ufo_pew.wav");
  upgrade = minim.loadFile("Sounds/upgrade.wav");
  levelup = minim.loadFile("Sounds/levelup.wav");

  BufferedReader highscoreReader = createReader("highscores.txt"); 
  String line = null;
  try {
    for (int i = 0; i < 10; i++) {
      if (highscoreReader != null && (line = highscoreReader.readLine()) != null) {
        highscores[i] = parseInt(line);
      } else {
        highscores[i] = 0;
      }
    }
    if (highscoreReader != null) highscoreReader.close();
  } 
  catch (IOException e) {
    e.printStackTrace();
  }
  start.play();
}
void draw() {
  int deltaTime = millis() - lastTime;
  lastTime += deltaTime;

  if (!gameover) {
    if (gameover_freeze) {
      deltaTime = 0;
    }
    image(space_background, width/2, height/2);

    posX += deltaTime * dirX * PLAYER_SPEED;
    posY += deltaTime * dirY * PLAYER_SPEED;


    if (posX < 0) posX += width; 
    if (posX > width) posX -= width;
    if (posY < 32) posY = 32;
    if (posY > height - 32) posY = height - 32;

    levelTimer += deltaTime;
    if (levelTimer >= LEVEL_DELAY) {
      levelTimer = 0;
      level++;
      levelup.rewind(); 
      levelup.play();
      enemyDelay = ENEMY_DELAY_INIT/(1+level*ENEMY_DELAY_INC);
      fireballDelay = FIREBALL_DELAY_INIT/(1+level*FIREBALL_DELAY_INC);
      enemySpeed = ENEMY_SPEED_INIT*(1+level*ENEMY_DELAY_INC);
    }

    if (upgradeState != 0) upgradeTimer += deltaTime;
    if (upgradeTimer >= UPGRADE_DELAY) {
      upgradeState = 0;
    }

    if (upgradeAlive) {
      if (abs(upgradeX-posX) <= 24 && abs(upgradeY-posY) <= 32) {
        upgrade.rewind();
        upgrade.play();
        upgradeTimer = 0;
        upgradeAlive = false;
        if (upgradeType == 0) {
          if (upgradeState == 0) upgradeState = 2;
          else if (upgradeState == 1) upgradeState = 3;
        } else {
          if (upgradeState == 0) upgradeState = 1;
          else if (upgradeState == 2) upgradeState = 3;
        }
      }
      if (upgradeType == 0) {
        image(upgrade_rpm, upgradeX, upgradeY);
      } else {
        image(upgrade_double, upgradeX, upgradeY);
      }
    }

    lazorTimer += deltaTime;
    if (lazorTimer >= LAZOR_DELAY ||(upgradeState >= 2 && lazorTimer >= LAZOR_DELAY/2)) {
      pew.rewind();
      pew.play();
      if (upgradeState == 1 || upgradeState == 3) {
        spawnLazor(posX-8, posY-20);
        spawnLazor(posX+8, posY-20);
      } else {
        spawnLazor(posX, posY-20);
      }

      lazorTimer = 0;
    }
    for (int i= 0; i < LAZOR_NUM; i++) {
      if (lazorAlive[i]) {
        lazorY[i] -= deltaTime * LAZOR_SPEED;
        if (lazorY[i] < -16) {
          lazorAlive[i] = false;
        }
        for (int j = 0; j < ENEMY_NUM; j++) {
          if (enemyHealth[j] > 0) {
            if (abs(enemyY[j] - lazorY[i]) <= (enemyType[j] <= 1 ? 48 : 32)) {
              if (abs(enemyX[j] - lazorX[i]) <= (enemyType[j] <= 2 ? 32 : 16)) {
                lazorAlive[i] = false;
                enemyHealth[j] -= 1;
                if (enemyHealth[j] <= 0) {
                  explosion.rewind();
                  explosion.play();
                  score += KILL_SCORE;
                  if ((int)random(9) == 0 && enemyY[j] >= 16) {
                    spawnUpgrade(enemyX[j], enemyY[j]);
                  }
                }
              }
            }
          }
        }
        image(lazor[upgradeState], lazorX[i], lazorY[i]);
      }
    }

    enemyTimer += deltaTime;
    if (enemyTimer >= enemyDelay) {
      spawnEnemy();
      enemyTimer = 0;
    }
    for (int i= 0; i < ENEMY_NUM; i++) {
      if (enemyHealth[i] > 0) {
        enemyY[i] += deltaTime * enemySpeed;
        if (enemyY[i] > height+32) {
          enemyHealth[i] = 0;
        }
        if (abs(enemyX[i]-posX) <= (enemyType[i] <= 2 ? 28 : 17)) {
          if (abs(enemyY[i] - posY) <= (enemyType[i] <= 1 ? 34 : 23)) {
            youdead();
          }
        }
        image(enemy[enemyType[i]], enemyX[i], enemyY[i]);
      }
    }

    fireballTimer += deltaTime;
    if (fireballTimer >= fireballDelay) {
      for (int i = 0; i < ENEMY_NUM; i++) {
        if (enemyType[i] == 2 && enemyHealth[i] > 0 && enemyY[i] < 2*height/3) {
          spawnFireball(enemyX[i], enemyY[i]);
          ufo_pew.rewind();
          ufo_pew.play();
        }
      }

      fireballTimer = 0;
    }

    for (int i = 0; i < FIREBALL_NUM; i++) {
      if (fireballAlive[i]) {
        fireballX[i] += fireballDirX[i] * deltaTime * FIREBALL_SPEED;
        fireballY[i] += fireballDirY[i] * deltaTime * FIREBALL_SPEED;

        if (fireballX[i] < 16 || fireballX[i] > width + 16 ||fireballY[i] < 16 ||fireballY[i] > height +16) {
          fireballAlive[i] = false;
        }

        if (abs(fireballX[i]-posX) <= 15) {
          if (abs(fireballY[i] - posY) <= 20) {
            youdead();
          }
        }

        image(fireball, fireballX[i], fireballY[i]);
      }
    }

    image(rocket, posX, posY);

    textAlign(LEFT, TOP);
    textSize(16);
    text("Score: " + score, 0, 0);

    textAlign(RIGHT, TOP);
    text("Level: " + level, width, 0);
    if (showFramerate) {
      textAlign(RIGHT, BOTTOM);
      text("FPS: " + (int)frameRate, width, height);
    }
    
    if (gameover_freeze) {
      textSize(72);
      textAlign(CENTER, CENTER);
      text("GAME OVER!", width/2, height/2);
    }
  } else {
    background(0);
    textAlign(CENTER, CENTER);
    textSize(40);
    text("Score: " + score, width/2, 64);
    textSize(32);
    text("Press space to (re-)start", width/2, height-64);
    textSize(20);
    text("Highscores:", width/2, height/2 -130);
    textSize(16);
    for (int i= 0; i < 10; i++) {
      textAlign(RIGHT, CENTER);
      text((i+1)+".", width/2-32, height/2 + (i-5)*20);
      text(highscores[i], width/2+45, height/2 + (i-5)*20);
    }
  }
}

void keyPressed() {
  if (keyCode == LEFT || key == 'a') {
    dirX--;
    if (dirX < -1) dirX = -1;
  } else if (keyCode == RIGHT || key == 'd') {
    dirX++;
    if (dirX > 1) dirX = 1;
  } else if (keyCode == UP || key == 'w') {
    dirY--;
    if (dirY < -1) dirY = -1;
  } else if (keyCode == DOWN || key == 's') {
    dirY++;
    if (dirY > 1) dirY = 1;
  } else if (key == 'f') {
    showFramerate = !showFramerate;
  } else if (key == ' ') {
    if(gameover_freeze) {
      gameover_freeze = false;
      gameover = true;
    }
    else if (gameover) {
      score = 0;

      posX = width/2;
      posY = height-32;

      for (int i = 0; i < LAZOR_NUM; i++) lazorAlive[i] = false;
      for (int i = 0; i < FIREBALL_NUM; i++) fireballAlive[i] = false;
      for (int i = 0; i < ENEMY_NUM; i++) enemyHealth[i]  = 0;

      lazorTimer = -START_DELAY;
      enemyTimer = -START_DELAY;
      levelTimer = -START_DELAY;
      enemyDelay = ENEMY_DELAY_INIT;
      enemySpeed = ENEMY_SPEED_INIT;
      fireballDelay = FIREBALL_DELAY_INIT;

      level = 0;

      upgradeState = 0;
      upgradeAlive = false;

      gameover = false;

      start.pause();
      lose.pause();
      roundstart.rewind(); 
      roundstart.play();
    }
  }
}

void keyReleased() {
  if (keyCode == LEFT || key == 'a') {
    dirX++;
    if (dirX > 1) dirX = 1;
  } else if (keyCode == RIGHT || key == 'd') {
    dirX--;
    if (dirX < -1) dirX = -1;
  } else if (keyCode == UP || key == 'w') {
    dirY++;
    if (dirY > 1) dirY = 1;
  } else if (keyCode == DOWN || key == 's') {
    dirY--;
    if (dirY < -1) dirY = -1;
  }
}

void spawnLazor(float x, float y) {
  for (int i= 0; i < LAZOR_NUM; i++) {
    if (!lazorAlive[i]) {
      lazorAlive[i]= true;
      lazorX[i] = x;
      lazorY[i] = y;
      return;
    }
  }
  println("Can't spawn LAZOR!!!");
}

void spawnEnemy() {
  for (int i= 0; i < ENEMY_NUM; i++) {
    if (enemyHealth[i] == 0) {
      enemyX[i] = random(32, width-32);
      enemyY[i] = -32;
      enemyType[i] = (int)random(0, 5);
      enemyHealth[i] = enemyType[i] <= 1 ? 2 : 1;
      return;
    }
  }
  println("Can't spawn Enemy!!!");
}

void spawnFireball(float x, float y) {
  for (int i= 0; i < FIREBALL_NUM; i++) {
    if (!fireballAlive[i]) {
      fireballAlive[i]= true;
      fireballX[i] = x;
      fireballY[i] = y;
      float distance = sqrt(sq(x-posX)+sq(y-posY));
      fireballDirX[i] = (posX-x)/distance;
      fireballDirY[i] = (posY-y)/distance;
      return;
    }
  }
  //  println("Can't spawn Fireball!!!");
}

void spawnUpgrade(float x, float y) {
  upgradeType = (int) random(2);
  upgradeX = x;
  upgradeY = y;
  upgradeAlive = true;
}

void youdead() {
  println("You dead mate! (Score:"+ score +")" );
  start_gameover();
  lose.rewind();
  lose.play();

  for (int i = 0; i< 10; i++) {
    if (score >= highscores[i]) {
      for (int j = 9; j > i; j--) {
        highscores[j] = highscores[j-1];
      }
      highscores[i] = score;
      break;
    }
  }
  PrintWriter highscoreWriter = createWriter("highscores.txt");
  for (int i = 0; i < 10; i++) {
    highscoreWriter.println(highscores[i]);
  }
  highscoreWriter.close();
}

void start_gameover() {
  gameover_freeze = true;
  slowmo_factor = 1.0;
}
