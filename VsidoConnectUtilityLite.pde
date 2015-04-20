import processing.serial.*;
import controlP5.*;

final color BG_COLOR = #cccccc;
final color LINE_COLOR = #888888;
final color TEXT_COLOR = #333333;
final color UI_BG_COLOR = #ffffff;
final color UI_INACTIVE_COLOR = #dddddd;
final color UI_ACTIVE_COLOR = #aaccff;
final color UI_TEXT_COLOR = #333333;

final String[] SERIAL_BAUTRATE_LIST = {"115200", "9600", "57600", "1000000"};
final String[] KID_LIST = {"0:BODY", "1:HEAD", "2:RIGHT ARM", "3:LEFT ARM", "4:RIGHT_LEG", "5:LEFT LEG"};

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
DropdownList dl_kid;
Numberbox nb_ik_x;
Numberbox nb_ik_y;
Numberbox nb_ik_z;
Button btn_set_ik;
Button btn_get_ik;
Numberbox nb_walk_speed;
Numberbox nb_walk_turn;
Button btn_walk;
CheckBox cb_log_visible;
Button btn_send_command;
Textarea ta_log;
Textfield tf_command;

// UIグループのインスタンス
// ※UIの設置Y座標はこれらのインスタンスのpos_yからの相対位置とする
GroupBox gb_serial_conn = new GroupBox(10, 10, 580, 90, "Serial Connection");
GroupBox gb_servo_angle = new GroupBox(10, 110, 580, 60, "Servo Angle Command");
GroupBox gb_ik = new GroupBox(10, 180, 580, 90, "IK Command");
GroupBox gb_walk = new GroupBox(10, 280, 580, 60, "Walk Command");
GroupBox gb_gpio = new GroupBox(10, 350, 580, 60, "GPIO");
GroupBox gb_pwm = new GroupBox(10, 420, 580, 90, "PWM");
GroupBox gb_send_command = new GroupBox(10, 520, 580, 90, "Send Command");

// シリアル接続関連
Serial serial_port;
boolean serial_connected = false;
byte[] buffer = {};

// 角度UIのための過去数値情報
float last_angle = 0.0;

void setup() {
  // Window立ち上げ
  size(1000, 620);
  
  // UI初期化
  cp5 = new ControlP5(this);
  // UIフォントを14ポイントに
  cp5.setControlFont(new ControlFont(createFont("Arial", 14), 14));

  // UI設置
  // ※ControlP5を使っているので、設置するだけでOK。draw()内に記述なし
  add_all_ui();

}

void draw() {
  // 背景色
  background(BG_COLOR);
  
  // 画面描画
  draw_all();

  // シリアル受信処理
  check_serial_rx();
}

// 画面描画メソッド
void draw_all() {
  // シリアル接続UIグループ
  gb_serial_conn.update();
  fill(TEXT_COLOR);
  textSize(14);
  text("Port", 20, gb_serial_conn.pos_y + 44);
  text("Baudrate", 400, gb_serial_conn.pos_y + 44);
  // サーボ角度設定コマンドUIグループ
  gb_servo_angle.update();
  fill(TEXT_COLOR);
  textSize(14);
  text("ServoID", 20, gb_servo_angle.pos_y + 44);
  text("Angle[deg]", 160, gb_servo_angle.pos_y + 44);
  textSize(10);
  text("-180", 320, gb_servo_angle.pos_y + 30);
  text("0", 446, gb_servo_angle.pos_y + 30);
  text("180", 560, gb_servo_angle.pos_y + 30);
  gb_ik.update();
  textSize(14);
  text("KID", 20, gb_ik.pos_y + 44);
  text("X", 200, gb_ik.pos_y + 44);
  text("Y", 300, gb_ik.pos_y + 44);
  text("Z", 400, gb_ik.pos_y + 44);
  gb_walk.update();
  textSize(14);
  text("Speed", 20, gb_walk.pos_y + 44);
  text("Turn", 160, gb_walk.pos_y + 44);
  gb_gpio.update();
  gb_pwm.update();
  gb_send_command.update();
  textSize(14);
  text("Command ([space] separated hex)", 20, gb_send_command.pos_y + 44);
}

// UIを画面上に追加
void add_all_ui() {
  //※DropdownListはUIを一番前面に持ってきたいので、最後に指定する

  // 接続ボタン
  btn_serial_connect = cp5.addButton("connect");
  uiCustomize(btn_serial_connect);
  btn_serial_connect.setPosition(370, gb_serial_conn.pos_y + 60);
  btn_serial_connect.setSize(100, 20);
  // 切断ボタン
  btn_serial_disconnect = cp5.addButton("disonnect");
  uiCustomize(btn_serial_disconnect);
  btn_serial_disconnect.setPosition(480, gb_serial_conn.pos_y + 60);
  btn_serial_disconnect.setSize(100, 20);

  // サーボID
  nb_servo_id = cp5.addNumberbox("servo_id");
  uiCustomize(nb_servo_id);
  nb_servo_id.setPosition(80, gb_servo_angle.pos_y + 30);
  nb_servo_id.setSize(60, 20);
  nb_servo_id.setRange(1, 255);
  nb_servo_id.setMultiplier(-1.0);
  nb_servo_id.setScrollSensitivity(10.0);
  nb_servo_id.setValue(1.0);
  // サーボ角度
  nb_servo_angle = cp5.addNumberbox("servo_angle");
  uiCustomize(nb_servo_angle);
  nb_servo_angle.setPosition(250, gb_servo_angle.pos_y + 30);
  nb_servo_angle.setSize(60, 20);
  nb_servo_angle.setRange(-180, 180);
  nb_servo_angle.setMultiplier(-1.0);
  nb_servo_angle.setScrollSensitivity(2.0);
  nb_servo_angle.setValue(0.0);
  // サーボ角度スライダー
  sl_servo_angle = cp5.addSlider("servo_angle_slider");
  uiCustomize(sl_servo_angle);
  sl_servo_angle.setPosition(320, gb_servo_angle.pos_y + 32);
  sl_servo_angle.setSize(260,16);
  sl_servo_angle.setRange(-180,180);
  sl_servo_angle.setNumberOfTickMarks(361);
  sl_servo_angle.setValue(7.0); // Todo:何故か7ズレるので、0にするために7とセット。原因を調べる。

  // IKのX
  nb_ik_x = cp5.addNumberbox("ik_x");
  uiCustomize(nb_ik_x);
  nb_ik_x.setPosition(220, gb_ik.pos_y + 30);
  nb_ik_x.setSize(60, 20);
  nb_ik_x.setRange(-100, 100);
  nb_ik_x.setMultiplier(-1.0);
  nb_ik_x.setScrollSensitivity(10.0);
  nb_ik_x.setValue(0.0);
  // IKのY
  nb_ik_y = cp5.addNumberbox("ik_y");
  uiCustomize(nb_ik_y);
  nb_ik_y.setPosition(320, gb_ik.pos_y + 30);
  nb_ik_y.setSize(60, 20);
  nb_ik_y.setRange(-100, 100);
  nb_ik_y.setMultiplier(-1.0);
  nb_ik_y.setScrollSensitivity(10.0);
  nb_ik_y.setValue(0.0);
  // IKのZ
  nb_ik_z = cp5.addNumberbox("ik_z");
  uiCustomize(nb_ik_z);
  nb_ik_z.setPosition(420, gb_ik.pos_y + 30);
  nb_ik_z.setSize(60, 20);
  nb_ik_z.setRange(-100, 100);
  nb_ik_z.setMultiplier(-1.0);
  nb_ik_z.setScrollSensitivity(10.0);
  nb_ik_z.setValue(0.0);
  // 座標指示ボタン
  btn_set_ik = cp5.addButton("set_ik");
  uiCustomize(btn_set_ik);
  btn_set_ik.setPosition(370, gb_ik.pos_y + 60);
  btn_set_ik.setSize(100, 20);
  // 現在地取得ボタン
  btn_get_ik = cp5.addButton("get_ik");
  uiCustomize(btn_get_ik);
  btn_get_ik.setPosition(480, gb_ik.pos_y + 60);
  btn_get_ik.setSize(100, 20);

  // 前進速度
  nb_walk_speed = cp5.addNumberbox("walk_speed");
  uiCustomize(nb_walk_speed);
  nb_walk_speed.setPosition(80, gb_walk.pos_y + 30);
  nb_walk_speed.setSize(60, 20);
  nb_walk_speed.setRange(-100, 100);
  nb_walk_speed.setMultiplier(-1.0);
  nb_walk_speed.setScrollSensitivity(10.0);
  nb_walk_speed.setValue(0.0);
  // 旋回速度
  nb_walk_turn = cp5.addNumberbox("walk_turn");
  uiCustomize(nb_walk_turn);
  nb_walk_turn.setPosition(210, gb_walk.pos_y + 30);
  nb_walk_turn.setSize(60, 20);
  nb_walk_turn.setRange(-100, 100);
  nb_walk_turn.setMultiplier(-1.0);
  nb_walk_turn.setScrollSensitivity(10.0);
  nb_walk_turn.setValue(0.0);
  // 現在地取得ボタン
  btn_walk = cp5.addButton("walk");
  uiCustomize(btn_walk);
  btn_walk.setPosition(480, gb_walk.pos_y + 30);
  btn_walk.setSize(100, 20);

  // 任意のコマンドを送信するためのテキストフィールド
  tf_command = cp5.addTextfield("send_command");
  uiCustomize(tf_command);
  tf_command.setPosition(20, gb_send_command.pos_y + 60);
  tf_command.setSize(440, 20);
  tf_command.setText("ff ");
  // 切断ボタン
  btn_send_command = cp5.addButton("send");
  uiCustomize(btn_send_command);
  btn_send_command.setPosition(480, gb_send_command.pos_y + 60);
  btn_send_command.setSize(100, 20);

  // 送受信ログの表示チェックボックス
  cb_log_visible = cp5.addCheckBox("log_visible");
  uiCustomize(cb_log_visible);
  cb_log_visible.setPosition(610, 10);
  cb_log_visible.setSize(20, 20);
  cb_log_visible.setItemsPerRow(1);
  cb_log_visible.addItem("Show TX/RX log", 0);
  // 送受信ログ
  ta_log = cp5.addTextarea("log");
  uiCustomize(ta_log);
  ta_log.setPosition(610, 40);
  ta_log.setSize(370, 540);
  ta_log.setColorBackground(UI_INACTIVE_COLOR);

  //DropdownList関連UI
  // 通信ポートのドロップダウンリスト
  dl_serial_port = cp5.addDropdownList("serial_port");
  uiCustomize(dl_serial_port);
  dl_serial_port.setWidth(320);
  dl_serial_port.setPosition(60, gb_serial_conn.pos_y + 50);
  dl_serial_port.addItems(Serial.list()); // シリアルポートの一覧を選択肢に追加
  // 通信ボーレートのドロップダウンリスト
  dl_serial_rate = cp5.addDropdownList("serial_rate");
  uiCustomize(dl_serial_rate);
  dl_serial_rate.setPosition(480, gb_serial_conn.pos_y + 50);
  dl_serial_rate.addItems(SERIAL_BAUTRATE_LIST);

  // KIDのドロップダウンリスト
  dl_kid = cp5.addDropdownList("kid");
  uiCustomize(dl_kid);
  dl_kid.setWidth(120);
  dl_kid.setPosition(60, gb_ik.pos_y + 50);
  dl_kid.addItems(KID_LIST); // シリアルポートの一覧を選択肢に追加
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
// Numberbox
void uiCustomize(Numberbox nb) {
  nb.setCaptionLabel("");
  nb.setColorValueLabel(UI_TEXT_COLOR);
  nb.setColorBackground(UI_BG_COLOR);
  nb.setColorActive(UI_ACTIVE_COLOR);
}
// Slider
void uiCustomize(Slider sl) {
  sl.setCaptionLabel("");
  sl.setSliderMode(Slider.FLEXIBLE);
  sl.snapToTickMarks(true);
  sl.setColorValueLabel(UI_TEXT_COLOR);
  sl.setColorBackground(UI_BG_COLOR);
  sl.setColorActive(UI_ACTIVE_COLOR);
}
// Checkbox
void uiCustomize(CheckBox cb) {
  cb.setCaptionLabel("");
  cb.setColorLabel(UI_TEXT_COLOR);
  cb.setColorBackground(UI_BG_COLOR);
  cb.setColorActive(UI_ACTIVE_COLOR);
}
// Textarea
void uiCustomize(Textarea ta) {
  ta.setCaptionLabel("");
  ta.setLineHeight(16);
  ta.setColor(UI_TEXT_COLOR);
  ta.setColorLabel(UI_TEXT_COLOR);
  ta.setColorForeground(UI_TEXT_COLOR);
  ta.setColorBackground(UI_BG_COLOR);
  ta.setColorActive(UI_ACTIVE_COLOR);
}
// Textfield
void uiCustomize(Textfield tf) {
  tf.setCaptionLabel("");
  tf.setColor(UI_TEXT_COLOR);
  tf.setColorCursor(UI_TEXT_COLOR);
  tf.setColorLabel(UI_TEXT_COLOR);
  tf.setColorForeground(UI_TEXT_COLOR);
  tf.setColorBackground(UI_BG_COLOR);
  tf.setColorActive(UI_ACTIVE_COLOR);
}

// UIグループのクラス
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

// ControlP5のイベント処理
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isGroup()) {
    println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
    // ログの表示チェックボックスをクリックした時
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
    // CONNECTボタンをクリックした時
    if (theEvent.controller().name() == "connect") {
      if (!serial_connected) {
        try {
          serial_port = new Serial(this, Serial.list()[(int)(dl_serial_port.getValue())], Integer.parseInt(SERIAL_BAUTRATE_LIST[(int)(dl_serial_rate.getValue())]));
          serial_connected = true;
        } catch (RuntimeException e) {
          System.out.println("port in use, trying again later...");
          serial_connected = false;
        }
      }
    }
    // DISCONNECTボタンをクリックした時
    if (theEvent.controller().name() == "disconnect") {
      if (serial_connected) {
        serial_port.clear();
        serial_port.stop();
        serial_connected = false; // todo:何か切断できていない様子
      }
    }
    // SERVO角度を変更した時
    if (theEvent.controller().name() == "servo_angle") {
      //sl_servo_angle.setValue(nb_servo_angle.getValue()); // todo:相互連動（今はスライダーからnumberboxへの一方向）
    }
    // SERVO角度スライダーを変更した時
    if (theEvent.controller().name() == "servo_angle_slider") {
      if (sl_servo_angle.getValue() != last_angle) {
        nb_servo_angle.setValue(sl_servo_angle.getValue());
        sendCommand(makeSingleAngleCommand((int)(nb_servo_id.getValue()), (float)(round(sl_servo_angle.getValue() * 10) / 10), (int)2));
        last_angle = sl_servo_angle.getValue();
      }
    }
    // SENDボタンをクリックした時
    if (theEvent.controller().name() == "send") {
      if (serial_connected) {
        sendCommand(parseCommand(tf_command.getText()));
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

// テキストで渡された任意のコードをパースしてコマンド群を生成する
// ※16進数として扱えるかのチェック程度しかしていない
byte[] parseCommand(String command_string) {
  String[] command_chrs = {};
  command_chrs = splitTokens(command_string);
  byte[] command = {};
  try {
    for (int i = 0; i < command_chrs.length; i++) {
      command = (byte[])append(command, (byte)(unhex(command_chrs[i])));
    }
  } catch (RuntimeException e) {
    System.out.println("illegal command format.");
    command = new byte[0];
  }
  return command;
}

// テキストで渡された任意のコードをパースしてコマンド群を生成する
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

void check_serial_rx() {
  int data;
  if (serial_port != null) {
    while (serial_port.available() > 0) {
      data = serial_port.read();
      println(data);
      // リターンコードの1バイト目検出
      if (data == 0xff) {
        buffer = new byte[0];
      }
      buffer = (byte[])append(buffer, (byte)data);
      if (buffer.length > 3) {
        if (buffer.length == buffer[2]) {
          // リターンコードの長さの取得と、取得の比較
          String log_text = "";
          log_text += "<";
          for (int i = 0; i < buffer.length; i++) {
            log_text += " ";
            log_text += hex(buffer[i]);
          }
          log_text += "\n";
          // 期待する長さのリターンコードを取得したらバッファをログに吐き出す
          if (cb_log_visible.getState(0)) {
            ta_log.append(log_text);
            ta_log.scroll(1.0);
            buffer = new byte[0];
          }
        }
      }
    }
  }
}
