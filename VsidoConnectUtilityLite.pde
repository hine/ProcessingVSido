import processing.serial.*;
import controlP5.*;

final color BG_COLOR = #cccccc;
final color LINE_COLOR = #888888;
final color TEXT_COLOR = #333333;
final color UI_BG_COLOR = #ffffff;
final color UI_INACTIVE_COLOR = #dddddd;
final color UI_ACTIVE_COLOR = #aaccff;
final color UI_TEXT_COLOR = #333333;

final String[] SERIAL_BAUTRATES = {"115200", "9600", "57600", "1000000"};

final byte COMMAND_ST = (byte)0xff;
final byte COMMAND_OP_TARGETANGLE = (byte)0x6f; // 'o'

// UIのためのControlP5
ControlP5 cp5;

// UIのインスタンス
DropdownList dl_serial_port;
DropdownList dl_serial_rate;
Button btn_serial_connect;
Button btn_serial_disconnect;
Numberbox nb_servo_id;
Numberbox nb_servo_angle;
Slider sl_servo_angle;
CheckBox cb_log_visible;
Textarea ta_log;

// UIグループのインスタンス
GroupBox gb_serial_conn = new GroupBox(10, 10, 580, 90, "Serial Connection");
GroupBox gb_servo_angle = new GroupBox(10, 110, 580, 60, "Servo Angle Command");

// シリアル接続
Serial serial_port;
boolean serial_connected = false;
byte[] buffer = {};

float last_angle = 0.0;

void setup() {
  // Window立ち上げ
  size(600, 400);
  
  // UI初期化
  cp5 = new ControlP5(this);
  // UIフォントを14ポイントに
  cp5.setControlFont(new ControlFont(createFont("Arial", 14), 14));

  // 以下UI設置

  // 接続ボタン
  btn_serial_connect = cp5.addButton("Connect");
  uiCustomize(btn_serial_connect);
  btn_serial_connect.setPosition(370, 70);
  btn_serial_connect.setSize(100, 20);
  // 切断ボタン
  btn_serial_disconnect = cp5.addButton("Disonnect");
  uiCustomize(btn_serial_disconnect);
  btn_serial_disconnect.setPosition(480, 70);
  btn_serial_disconnect.setSize(100, 20);
  // 通信ポートのドロップダウンリスト
  dl_serial_port = cp5.addDropdownList("serial_port");
  uiCustomize(dl_serial_port);
  dl_serial_port.setWidth(320);
  dl_serial_port.setPosition(60, 60);
  dl_serial_port.addItems(Serial.list()); // シリアルポートの一覧を選択肢に追加
  // 通信ボーレートのドロップダウンリスト
  dl_serial_rate = cp5.addDropdownList("serial_rate");
  uiCustomize(dl_serial_rate);
  dl_serial_rate.setPosition(480, 60);
  dl_serial_rate.addItems(SERIAL_BAUTRATES);

  // サーボID
  nb_servo_id = cp5.addNumberbox("servo_id");
  uiCustomize(nb_servo_id);
  nb_servo_id.setPosition(80, 140);
  nb_servo_id.setSize(60, 20);
  nb_servo_id.setRange(1, 255);
  nb_servo_id.setMultiplier(-1.0);
  nb_servo_id.setScrollSensitivity(10.0);
  nb_servo_id.setValue(1.0);
  // サーボ角度
  nb_servo_angle = cp5.addNumberbox("servo_angle");
  uiCustomize(nb_servo_angle);
  nb_servo_angle.setPosition(250, 140);
  nb_servo_angle.setSize(60, 20);
  nb_servo_angle.setRange(-180, 180);
  nb_servo_angle.setMultiplier(-1.0);
  nb_servo_angle.setScrollSensitivity(2.0);
  nb_servo_angle.setValue(0.0);
  // サーボ角度スライダー
  sl_servo_angle = cp5.addSlider("servo_angle_slider");
  uiCustomize(sl_servo_angle);
  sl_servo_angle.setPosition(320, 142);
  sl_servo_angle.setSize(260,16);
  sl_servo_angle.setRange(-180,180);
  sl_servo_angle.setNumberOfTickMarks(361);
  sl_servo_angle.setValue(7.0); // Todo:何故か7ズレるので、0にするために7とセット。原因を調べる。

  // 送受信ログの表示チェックボックス
  cb_log_visible = cp5.addCheckBox("log_visible");
  uiCustomize(cb_log_visible);
  cb_log_visible.setPosition(10, 180);
  cb_log_visible.setSize(20, 20);
  cb_log_visible.setItemsPerRow(1);
  cb_log_visible.addItem("Show TX/RX log", 0);
  // 送受信ログ
  ta_log = cp5.addTextarea("log");
  uiCustomize(ta_log);
  ta_log.setPosition(10, 210);
  ta_log.setSize(580, 170);
  ta_log.setLineHeight(16);
  ta_log.setColorBackground(UI_INACTIVE_COLOR);
}

void draw() {
  // 背景色
  background(BG_COLOR);
  
  // 画面描画
  draw_all();

  int data;
  if (serial_port != null) {
  while (serial_port.available() > 0) {
    data = serial_port.read();
    if (data == 0xff) {
      buffer = new byte[0];
    }
    buffer = (byte[])append(buffer, (byte)data);
    if (buffer.length > 3) {
      if (buffer.length == buffer[2]) {
        String log_text = "";
        log_text += "<";
        for (int i = 0; i < buffer.length; i++) {
          log_text += " ";
          log_text += hex(buffer[i]);
        }
        log_text += "\n";
        if (cb_log_visible.getState(0)) {
          ta_log.append(log_text);
          ta_log.scroll(1.0);
        }
      }
    }
  }
  }
}

// 各種UIのカスタマイズ
// DropdownList
void uiCustomize(DropdownList dl) {
  dl.setCaptionLabel("");
  dl.setItemHeight(20);
  dl.setBarHeight(20);
  dl.actAsPulldownMenu(true);
  dl.setBackgroundColor(UI_BG_COLOR);
  dl.setColorLabel(UI_TEXT_COLOR);
  dl.setColorBackground(UI_BG_COLOR);
  dl.setColorActive(UI_ACTIVE_COLOR);
}
// Button
void uiCustomize(Button btn) {
  btn.align(CENTER, CENTER, CENTER, CENTER);
  btn.setColorLabel(UI_TEXT_COLOR);
  btn.setColorBackground(UI_BG_COLOR);
  btn.setColorActive(UI_ACTIVE_COLOR);
}
void uiCustomize(Numberbox nb) {
  nb.setCaptionLabel("");
  nb.setColorValueLabel(UI_TEXT_COLOR);
  nb.setColorBackground(UI_BG_COLOR);
  nb.setColorActive(UI_ACTIVE_COLOR);
}
void uiCustomize(Slider sl) {
  sl.setCaptionLabel("");
  sl.setSliderMode(Slider.FLEXIBLE);
  sl.snapToTickMarks(true);
  sl.setColorValueLabel(UI_TEXT_COLOR);
  sl.setColorBackground(UI_BG_COLOR);
  sl.setColorActive(UI_ACTIVE_COLOR);
}
void uiCustomize(CheckBox cb) {
  cb.setCaptionLabel("");
  cb.setColorLabel(UI_TEXT_COLOR);
  cb.setColorBackground(UI_BG_COLOR);
  cb.setColorActive(UI_ACTIVE_COLOR);
}
void uiCustomize(Textarea ta) {
  ta.setCaptionLabel("");
  ta.setColor(UI_TEXT_COLOR);
  ta.setColorLabel(UI_TEXT_COLOR);
  ta.setColorForeground(UI_TEXT_COLOR);
  ta.setColorBackground(UI_BG_COLOR);
  ta.setColorActive(UI_ACTIVE_COLOR);
}

// 画面描画メソッド
void draw_all() {
  // シリアル接続UIグループ
  gb_serial_conn.update();
  fill(TEXT_COLOR);
  textSize(14);
  text("Port", 20, 54);
  text("Baudrate", 400, 54);
  // サーボ角度設定コマンドUIグループ
  gb_servo_angle.update();
  fill(TEXT_COLOR);
  textSize(14);
  text("ServoID", 20, 154);
  text("Angle[deg]", 160, 154);
  textSize(10);
  text("-180", 320, 140);
  text("0", 446, 140);
  text("180", 560, 140);

}

// 画面描画のためのクラス
// 
class GroupBox {
  private float pos_x;
  private float pos_y;
  private float width;
  private float height;
  private String label;
  public GroupBox(float x, float y, float w, float h, String l) {
    pos_x = x;
    pos_y = y;
    width = w;
    height = h;
    label = l;
  }
  public void update() {
    textSize(14);
    textAlign(LEFT);
    stroke(LINE_COLOR);
    noFill();
    rect(pos_x, pos_y + 6, width, height - 6);
    fill(BG_COLOR);
    noStroke();
    rect(pos_x + 4, pos_y, textWidth(label) + 4, 14);
    fill(TEXT_COLOR);
    stroke(LINE_COLOR);
    text(label, pos_x + 6, pos_y + 14);
  }
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {
    println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
    if (theEvent.group().name() == "log_visible") {
      if (cb_log_visible.getState(0)) {
        ta_log.setColorBackground(UI_BG_COLOR);
      } else {
        ta_log.setColorBackground(UI_INACTIVE_COLOR);
      }
    }
  }
  else if (theEvent.isController()) {
    println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());
    if (theEvent.controller().name() == "Connect") {
      if (!serial_connected) {
        try {
          serial_port = new Serial(this, Serial.list()[(int)(dl_serial_port.getValue())], Integer.parseInt(SERIAL_BAUTRATES[(int)(dl_serial_rate.getValue())]));
          serial_connected = true;
        } catch (RuntimeException e) {
          System.out.println("port in use, trying again later...");
          serial_connected = false;
        }
      }
    }
    if (theEvent.controller().name() == "Disconnect") {
      if (serial_connected) {
        serial_port.clear();
        serial_port.stop();
        serial_connected = false;
      }
    }
    if (theEvent.controller().name() == "servo_angle") {
      //sl_servo_angle.setValue(nb_servo_angle.getValue());
    }
    if (theEvent.controller().name() == "servo_angle_slider") {
      if (sl_servo_angle.getValue() != last_angle) {
        nb_servo_angle.setValue(sl_servo_angle.getValue());
        sendCommand(makeSingleAngleCommand((int)(nb_servo_id.getValue()), (float)(round(sl_servo_angle.getValue() * 10) / 10), (int)2));
        last_angle = sl_servo_angle.getValue();
      }
    }
  }
}

void sendCommand(byte[] command) {
  if (serial_connected) {
    String log_text = "";
    log_text += ">";
    for (int i = 0; i < command.length; i++) {
      serial_port.write(command[i]);
      log_text += " ";
      log_text += hex(command[i]);
    }
    log_text += "\n";
    if (cb_log_visible.getState(0)) {
      ta_log.append(log_text);
      ta_log.scroll(1.0);
    }
  }
}

void serialEvent(Serial p) {
}

byte[] makeSingleAngleCommand(int sid, float angle, int cycle) {
  byte[] data = {};
 
  data = (byte[])append(data, COMMAND_ST); // ST
  data = (byte[])append(data, COMMAND_OP_TARGETANGLE); // OP
  data = (byte[])append(data, (byte)0); // LN仮置き（あとで計算する）
  data = (byte[])append(data, (byte)0x02); // CYC
  data = (byte[])append(data, (byte)sid); // SID

  float deg = angle * 10;
  data = (byte[])append(data, (byte)(((short)deg << 1) &0x00ff)); // ANGLE_L
  data = (byte[])append(data, (byte)(((((short)deg << 1) >> 8) << 1) & 0x00ff)); // ANGLE_H
  
  data = (byte[])append(data, (byte)0); // SUM仮置き

  data[2] = byte(data.length);

  byte sum = 0;
  for (int i = 0; i < data.length - 1; i++) {
    sum ^= data[i];
  }
  data[7] = sum;
  return data;
}

