#include <WiFi.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>

const char* WIFI_SSID  = "Topkapi_Ogrenci";
const char* WIFI_PASS  = "TPU2025ogr";
const char* WS_HOST    = "10.245.1.148";
const int   WS_PORT    = 8000;
const char* CAR_ID     = "car1";
const char* CAR_SECRET = "smartcar-esp32-secret-2024";

#define ENA 21
#define ENB 26
#define IN1 18
#define IN2 19
#define IN3 22
#define IN4 23

WiFiServer httpServer(80);
int motorSpeed = 200;

const char* htmlPage = R"rawliteral(
<!DOCTYPE html>
<html lang='tr'>
<head>
<meta charset='UTF-8'>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<title>SmartCar Kontrol</title>
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:Arial,sans-serif;text-align:center;background:#fff9f0;display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:100vh;padding:20px;}
h1{color:#cc0000;margin-bottom:20px;font-size:24px;}
#joystick-container{position:relative;width:220px;height:220px;border:3px solid #cc0000;border-radius:50%;background:rgba(0,0,0,0.05);margin-bottom:30px;touch-action:none;user-select:none;}
#joystick{position:absolute;width:80px;height:80px;background:#ff3333;border-radius:50%;top:70px;left:70px;box-shadow:0 0 15px #ff9999;}
.buttons{display:flex;gap:12px;flex-wrap:wrap;justify-content:center;margin-bottom:16px;}
.btn{padding:14px 20px;font-size:16px;cursor:pointer;border-radius:12px;border:2px solid #cc0000;background:#fff;color:#cc0000;font-weight:bold;}
.btn:hover{background:#cc0000;color:#fff;}
.stop-btn{background:#cc0000;color:#fff;font-size:20px;padding:16px 40px;border-radius:12px;border:none;cursor:pointer;margin-bottom:12px;}
.drift-btn{background:#fff;color:#000;border:2px solid #ff6600;font-size:18px;padding:14px 36px;border-radius:12px;cursor:pointer;margin-bottom:16px;}
.drift-btn.active{background:#ff6600;color:#fff;}
.speed-label{font-size:18px;color:#b30000;font-weight:bold;}
</style>
</head>
<body>
<h1>🚗 SmartCar Kontrol</h1>
<div id="joystick-container"><div id="joystick"></div></div>
<div class="buttons">
  <button class="btn" onclick="setSpeed(50)">🐢 50</button>
  <button class="btn" onclick="setSpeed(100)">100</button>
  <button class="btn" onclick="setSpeed(150)">⚡ 150</button>
  <button class="btn" onclick="setSpeed(200)">200</button>
  <button class="btn" onclick="setSpeed(250)">🚀 250</button>
</div>
<button class="stop-btn" onclick="send('stop')">⏹ DUR</button><br>
<button class="drift-btn" id="driftBtn" onclick="doDrift()">💨 DRIFT AT!</button>
<div class="speed-label">Hız: <span id="speedVal">200</span></div>
<script>
const joystick=document.getElementById('joystick');
const container=document.getElementById('joystick-container');
const driftBtn=document.getElementById('driftBtn');
const W=container.offsetWidth,H=container.offsetHeight;
const JW=joystick.offsetWidth,JH=joystick.offsetHeight;
const centerX=W/2,centerY=H/2,maxDist=W/2-JW/2;
let lastDir='',mouseActive=false;
container.addEventListener('touchstart',onMove,{passive:false});
container.addEventListener('touchmove',onMove,{passive:false});
container.addEventListener('touchend',onEnd);
container.addEventListener('mousedown',e=>{mouseActive=true;onMove({touches:[e]});});
document.addEventListener('mouseup',()=>{mouseActive=false;onEnd();});
document.addEventListener('mousemove',e=>{if(mouseActive)onMove({touches:[e]});});
function onMove(e){
  e.preventDefault();
  const t=e.touches[0];
  const rect=container.getBoundingClientRect();
  const dx=t.clientX-rect.left-centerX;
  const dy=t.clientY-rect.top-centerY;
  const dist=Math.min(Math.sqrt(dx*dx+dy*dy),maxDist);
  const angle=Math.atan2(dy,dx);
  joystick.style.left=(centerX+dist*Math.cos(angle)-JW/2)+'px';
  joystick.style.top=(centerY+dist*Math.sin(angle)-JH/2)+'px';
  let dir='stop';
  if(dist>20){
    const deg=angle*(180/Math.PI);
    if(deg>-45&&deg<45)dir='right';
    else if(deg>=45&&deg<135)dir='down';
    else if(deg>=-135&&deg<-45)dir='up';
    else dir='left';
  }
  if(dir!==lastDir){
    lastDir=dir;
    if(dir==='up')send('forward');
    else if(dir==='down')send('backward');
    else if(dir==='left')send('left');
    else if(dir==='right')send('right');
    else send('stop');
  }
}
function onEnd(){
  joystick.style.left=(centerX-JW/2)+'px';
  joystick.style.top=(centerY-JH/2)+'px';
  send('stop');lastDir='';
}
function send(cmd){fetch('/control?cmd='+cmd).catch(()=>{});}
function setSpeed(val){document.getElementById('speedVal').innerText=val;fetch('/speed?value='+val).catch(()=>{});}
function doDrift(){driftBtn.classList.add('active');fetch('/drift').then(()=>setTimeout(()=>driftBtn.classList.remove('active'),2000)).catch(()=>{});}
</script>
</body>
</html>
)rawliteral";

void dur(){
  digitalWrite(IN1,LOW);digitalWrite(IN2,LOW);
  digitalWrite(IN3,LOW);digitalWrite(IN4,LOW);
  analogWrite(ENA,0);analogWrite(ENB,0);
}

void moveMotor(const String& cmd, int spd){
  spd=constrain(spd,0,255);
  if(cmd=="forward") {digitalWrite(IN1,HIGH);digitalWrite(IN2,LOW);digitalWrite(IN3,HIGH);digitalWrite(IN4,LOW);}
  else if(cmd=="backward"){digitalWrite(IN1,LOW);digitalWrite(IN2,HIGH);digitalWrite(IN3,LOW);digitalWrite(IN4,HIGH);}
  else if(cmd=="left")   {digitalWrite(IN1,LOW);digitalWrite(IN2,HIGH);digitalWrite(IN3,HIGH);digitalWrite(IN4,LOW);}
  else if(cmd=="right")  {digitalWrite(IN1,HIGH);digitalWrite(IN2,LOW);digitalWrite(IN3,LOW);digitalWrite(IN4,HIGH);}
  else{dur();return;}
  analogWrite(ENA,spd);analogWrite(ENB,spd);
}

void drift(){
  analogWrite(ENA,255);analogWrite(ENB,255);
  digitalWrite(IN1,HIGH);digitalWrite(IN2,LOW);digitalWrite(IN3,HIGH);digitalWrite(IN4,LOW);delay(400);
  digitalWrite(IN1,HIGH);digitalWrite(IN2,LOW);digitalWrite(IN3,LOW);digitalWrite(IN4,HIGH);delay(700);
  digitalWrite(IN1,LOW);digitalWrite(IN2,HIGH);digitalWrite(IN3,HIGH);digitalWrite(IN4,LOW);delay(700);
  digitalWrite(IN1,HIGH);digitalWrite(IN2,LOW);digitalWrite(IN3,HIGH);digitalWrite(IN4,LOW);delay(400);
  dur();
}

WebSocketsClient ws;
bool wsConnected=false;

void sendLog(const String& cmd,int spd){
  StaticJsonDocument<128> doc;
  doc["type"]="log";doc["car_id"]=CAR_ID;
  doc["command"]=cmd;doc["speed"]=spd;doc["uptime"]=millis()/1000;
  String out;serializeJson(doc,out);ws.sendTXT(out);
}

void onWsEvent(WStype_t type,uint8_t* payload,size_t length){
  switch(type){
    case WStype_CONNECTED:
      wsConnected=true;
      ws.sendTXT("{\"type\":\"car_ready\",\"car_id\":\""+String(CAR_ID)+"\"}");
      Serial.println("WS baglandi");break;
    case WStype_DISCONNECTED:
      wsConnected=false;dur();Serial.println("WS kesildi");break;
    case WStype_TEXT:{
      StaticJsonDocument<256> doc;
      if(deserializeJson(doc,payload))break;
      const char* t=doc["type"];if(!t)break;
      if(strcmp(t,"command")==0){
        String cmd=doc["command"]|"stop";
        int spd=doc["speed"]|180;
        moveMotor(cmd,spd);sendLog(cmd,spd);
        ws.sendTXT("{\"type\":\"ack\",\"status\":\"ok\"}");
      }break;
    }
    default:break;
  }
}

void handleHttp(WiFiClient& client){
  String req=client.readStringUntil('\r');client.flush();
  if(req.indexOf("/control?cmd=forward")!=-1)       moveMotor("forward",motorSpeed);
  else if(req.indexOf("/control?cmd=backward")!=-1) moveMotor("backward",motorSpeed);
  else if(req.indexOf("/control?cmd=left")!=-1)     moveMotor("left",motorSpeed);
  else if(req.indexOf("/control?cmd=right")!=-1)    moveMotor("right",motorSpeed);
  else if(req.indexOf("/control?cmd=stop")!=-1)     dur();
  else if(req.indexOf("/drift")!=-1)                drift();
  else if(req.indexOf("/speed?value=")!=-1){
    motorSpeed=constrain(req.substring(req.indexOf("/speed?value=")+13).toInt(),50,255);
  }
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/html; charset=utf-8");
  client.println("Connection: close");client.println();
  client.print(htmlPage);client.stop();
}

void setup(){
  Serial.begin(115200);
  pinMode(ENA,OUTPUT);pinMode(ENB,OUTPUT);
  pinMode(IN1,OUTPUT);pinMode(IN2,OUTPUT);
  pinMode(IN3,OUTPUT);pinMode(IN4,OUTPUT);
  dur();
  WiFi.mode(WIFI_STA);WiFi.begin(WIFI_SSID,WIFI_PASS);
  while(WiFi.status()!=WL_CONNECTED){delay(500);Serial.print(".");}
  Serial.println("\nIP: "+WiFi.localIP().toString());
  String wsPath="/api/v1/ws/car/"+String(CAR_ID)+"?token="+String(CAR_SECRET);
  ws.begin(WS_HOST,WS_PORT,wsPath);
  ws.onEvent(onWsEvent);ws.setReconnectInterval(3000);
  httpServer.begin();
}

void loop(){
  ws.loop();
  WiFiClient client=httpServer.available();
  if(client)handleHttp(client);
  if(WiFi.status()!=WL_CONNECTED){WiFi.reconnect();delay(5000);}
}