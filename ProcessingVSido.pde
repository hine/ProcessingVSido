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
final byte COMMAND_OP_IK = (byte)0x6b; // 'k'
final byte COMMAND_OP_WALK = (byte)0x74; // 't'
final byte COMMAND_OP_SETVID = (byte)0x73; // 's'
final byte COMMAND_OP_GPIO = (byte)0x69; // 'i'

// UIのためのControlP5
ControlP5 cp5;

// UIのインスタンス
DropdownList dl_serial_port;
DropdownList dl_serial_rate;
Button btn_refresh_port_list;
Button btn_serial_connect;
Button btn_serial_disconnect;
Numberbox nb_servo_id;
Textfield tf_servo_angle;
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
CheckBox cb_gpio_pin4;
CheckBox cb_gpio_pin5;
CheckBox cb_gpio_pin6;
CheckBox cb_gpio_pin7;
CheckBox cb_adjust_lnsum;
Textfield tf_command;
Button btn_send_command;
CheckBox cb_log_visible;
Textarea ta_log;
Textarea ta_status;

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
boolean is_from_tf = false;

void setup() {
  // Window立ち上げ
  size(1000, 650);
  
  // UI初期化
  cp5 = new ControlP5(this);
  // UIフォントを14ポイントに
  cp5.setControlFont(new ControlFont(createFont("Arial", 14), 14));

  // UI設置
  // ※ControlP5を使っているので、設置するだけでOK。draw()内に記述なし
  add_all_ui();
}

// メインループ
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

  // ポートリスト更新ボタン
  btn_refresh_port_list = cp5.addButton("refresh");
  uiCustomize(btn_refresh_port_list);
  btn_refresh_port_list.setPosition(60, gb_serial_conn.pos_y + 60);
  btn_refresh_port_list.setSize(100, 20);
  // 接続ボタン
  btn_serial_connect = cp5.addButton("connect");
  uiCustomize(btn_serial_connect);
  btn_serial_connect.setPosition(370, gb_serial_conn.pos_y + 60);
  btn_serial_connect.setSize(100, 20);
  // 切断ボタン
  btn_serial_disconnect = cp5.addButton("disconnect");
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
  tf_servo_angle = cp5.addTextfield("servo_angle");
  uiCustomize(tf_servo_angle);
  tf_servo_angle.setPosition(250, gb_servo_angle.pos_y + 30);
  tf_servo_angle.setSize(60, 20);
  tf_servo_angle.setText(str(0.0));
  // サーボ角度スライダー
  sl_servo_angle = cp5.addSlider("servo_angle_slider");
  uiCustomize(sl_servo_angle);
  sl_servo_angle.setPosition(320, gb_servo_angle.pos_y + 32);
  sl_servo_angle.setSize(260,16);
  sl_servo_angle.setRange(-180,180);
  sl_servo_angle.setNumberOfTickMarks(361);
  sl_servo_angle.setValue(0.0); // modeがFLEXIBLEだと数値がずれるがFIXならズレない。

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
  // 現在座標取得ボタン
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
  nb_walk_speed.setValue(100.0);
  // 旋回速度
  nb_walk_turn = cp5.addNumberbox("walk_turn");
  uiCustomize(nb_walk_turn);
  nb_walk_turn.setPosition(210, gb_walk.pos_y + 30);
  nb_walk_turn.setSize(60, 20);
  nb_walk_turn.setRange(-100, 100);
  nb_walk_turn.setMultiplier(-1.0);
  nb_walk_turn.setScrollSensitivity(10.0);
  nb_walk_turn.setValue(0.0);
  // 歩行ボタン
  btn_walk = cp5.addButton("walk");
  uiCustomize(btn_walk);
  btn_walk.setPosition(480, gb_walk.pos_y + 30);
  btn_walk.setSize(100, 20);

  // GPIOチェックボタン
  cb_gpio_pin4 = cp5.addCheckBox("gpio_pin4");
  uiCustomize(cb_gpio_pin4);
  cb_gpio_pin4.setPosition(30, gb_gpio.pos_y + 30);
  cb_gpio_pin4.setItemsPerRow(1);
  cb_gpio_pin4.addItem("pin4", 0);
  cb_gpio_pin5 = cp5.addCheckBox("gpio_pin5");
  uiCustomize(cb_gpio_pin5);
  cb_gpio_pin5.setPosition(110, gb_gpio.pos_y + 30);
  cb_gpio_pin5.setItemsPerRow(1);
  cb_gpio_pin5.addItem("pin5", 0);
  cb_gpio_pin6 = cp5.addCheckBox("gpio_pin6");
  uiCustomize(cb_gpio_pin6);
  cb_gpio_pin6.setPosition(190, gb_gpio.pos_y + 30);
  cb_gpio_pin6.setItemsPerRow(1);
  cb_gpio_pin6.addItem("pin6", 0);
  cb_gpio_pin7 = cp5.addCheckBox("gpio_pin7");
  uiCustomize(cb_gpio_pin7);
  cb_gpio_pin7.setPosition(270, gb_gpio.pos_y + 30);
  cb_gpio_pin7.setItemsPerRow(1);
  cb_gpio_pin7.addItem("pin7", 0);

  // 任意のコマンド送信時に自動的にLNとSUMを計算するチェックボックス
  cb_adjust_lnsum = cp5.addCheckBox("adjust_lnsum");
  uiCustomize(cb_adjust_lnsum);
  cb_adjust_lnsum.setPosition(400, gb_send_command.pos_y + 30);
  cb_adjust_lnsum.setItemsPerRow(1);
  cb_adjust_lnsum.addItem("auto adjust LN/SUM", 0);
  // 任意のコマンドを送信するためのテキストフィールド
  tf_command = cp5.addTextfield("send_command");
  uiCustomize(tf_command);
  tf_command.setPosition(20, gb_send_command.pos_y + 60);
  tf_command.setSize(440, 20);
  tf_command.setText("ff ");
  // 任意コマンド送信送信ボタン
  btn_send_command = cp5.addButton("send");
  uiCustomize(btn_send_command);
  btn_send_command.setPosition(480, gb_send_command.pos_y + 60);
  btn_send_command.setSize(100, 20);

  // 送受信ログの表示チェックボックス
  cb_log_visible = cp5.addCheckBox("log_visible");
  uiCustomize(cb_log_visible);
  cb_log_visible.setPosition(610, 20);
  cb_log_visible.setSize(20, 20);
  cb_log_visible.setItemsPerRow(1);
  cb_log_visible.addItem("Show TX/RX log", 0);
  // 送受信ログ
  ta_log = cp5.addTextarea("log");
  uiCustomize(ta_log);
  ta_log.showScrollbar();
  ta_log.setPosition(610, 50);
  ta_log.setSize(370, 550);
  ta_log.setColorBackground(UI_INACTIVE_COLOR);

  // Status表示
  ta_status = cp5.addTextarea("status");
  uiCustomize(ta_status);
  ta_status.hideScrollbar();
  ta_status.setPosition(10, height - 30);
  ta_status.setSize(980, 20);
  ta_status.setColorBackground(UI_INACTIVE_COLOR);

  //DropdownList関連UI
  // 通信ポートのドロップダウンリスト
  dl_serial_port = cp5.addDropdownList("serial_port");
  uiCustomize(dl_serial_port);
  dl_serial_port.setWidth(320);
  dl_serial_port.setPosition(60, gb_serial_conn.pos_y + 50);
  dl_serial_port.addItems(Serial.list()); // シリアルポートの一覧を選択肢に追加
  dl_serial_port.setValue(0);
  // 通信ボーレートのドロップダウンリスト
  dl_serial_rate = cp5.addDropdownList("serial_rate");
  uiCustomize(dl_serial_rate);
  dl_serial_rate.setPosition(480, gb_serial_conn.pos_y + 50);
  dl_serial_rate.addItems(SERIAL_BAUTRATE_LIST);
  dl_serial_rate.setValue(0);

  // KIDのドロップダウンリスト
  dl_kid = cp5.addDropdownList("kid");
  uiCustomize(dl_kid);
  dl_kid.setWidth(120);
  dl_kid.setPosition(60, gb_ik.pos_y + 50);
  dl_kid.addItems(KID_LIST); // シリアルポートの一覧を選択肢に追加
  dl_kid.setValue(0);
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
  sl.setSliderMode(Slider.FIX); // 本当はFLEXIBLEがいいんだけど、何故か数値がずれるので
  sl.snapToTickMarks(true);
  sl.setColorTickMark(UI_ACTIVE_COLOR);
  sl.setColorValueLabel(UI_TEXT_COLOR);
  sl.setColorBackground(UI_BG_COLOR);
  sl.setColorActive(UI_ACTIVE_COLOR);
}
// Checkbox
void uiCustomize(CheckBox cb) {
  cb.setCaptionLabel("");
  cb.setSize(20, 20);
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
  tf.setAutoClear(false);
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
        ta_log.clear();
        ta_log.setColorBackground(UI_INACTIVE_COLOR);
      }
    }
    // GPIOのチェックボックス
    if (theEvent.group().name() == "gpio_pin4") {
      if (cb_gpio_pin4.getState(0)) {
        if (serial_connected) {
          sendCommand(makeVidSetCommand(3, 0x78));
          delay(10);
          sendCommand(makeGPIOCommand(4, 1));
        } else {
          cb_gpio_pin4.deactivate(0);
        }
      } else {
        if (serial_connected) {
          sendCommand(makeGPIOCommand(4, 0));
        }
      }
    }
    if (theEvent.group().name() == "gpio_pin5") {
      if (cb_gpio_pin5.getState(0)) {
        if (serial_connected) {
          sendCommand(makeVidSetCommand(3, 0x78));
          delay(10);
          sendCommand(makeGPIOCommand(5, 1));
        } else {
          cb_gpio_pin5.deactivate(0);
        }
      } else {
        if (serial_connected) {
          sendCommand(makeGPIOCommand(5, 0));
        }
      }
    }
    if (theEvent.group().name() == "gpio_pin6") {
      if (cb_gpio_pin6.getState(0)) {
        if (serial_connected) {
          sendCommand(makeVidSetCommand(3, 0x78));
          delay(10);
          sendCommand(makeGPIOCommand(6, 1));
        } else {
          cb_gpio_pin6.deactivate(0);
        }
      } else {
        if (serial_connected) {
          sendCommand(makeGPIOCommand(6, 0));
        }
      }
    }
    if (theEvent.group().name() == "gpio_pin7") {
      if (cb_gpio_pin7.getState(0)) {
        if (serial_connected) {
          sendCommand(makeVidSetCommand(3, 0x78));
          delay(10);
          sendCommand(makeGPIOCommand(7, 1));
        } else {
          cb_gpio_pin7.deactivate(0);
        }
      } else {
        if (serial_connected) {
          sendCommand(makeGPIOCommand(7, 0));
        }
      }
    }
  }
  else if (theEvent.isController()) {
    println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());
    // REFRESHボタンをクリックした時
    if (theEvent.controller().name() == "refresh") {
      dl_serial_port.clear(); // リストを一旦削除
      dl_serial_port.addItems(Serial.list()); // シリアルポートの一覧を選択肢に追加
      dl_serial_port.setValue(0);
    }
    // CONNECTボタンをクリックした時
    if (theEvent.controller().name() == "connect") {
      if (!serial_connected) {
        try {
          serial_port = new Serial(this, Serial.list()[(int)(dl_serial_port.getValue())], Integer.parseInt(SERIAL_BAUTRATE_LIST[(int)(dl_serial_rate.getValue())]));
          serial_connected = true;
          ta_status.setText("Connected. [Port:" + dl_serial_port.getItem((int)(dl_serial_port.getValue())).getName() + " Boudrate:" + dl_serial_rate.getItem((int)(dl_serial_rate.getValue())).getName() + "]");
        } catch (RuntimeException e) {
          serial_connected = false;
          ta_status.setText("Cannot connect. Maybe in use.");
        }
      }
    }
    // DISCONNECTボタンをクリックした時
    if (theEvent.controller().name() == "disconnect") {
      if (serial_connected) {
        serial_port.clear();
        serial_port.stop();
        serial_connected = false;
        ta_status.setText("Disconnected.");
      }
    }
    // SERVO角度を変更した時
    if (theEvent.controller().name() == "servo_angle") {
      is_from_tf = true;
      delay(100);
      try {
        sl_servo_angle.setValue(Float.parseFloat(tf_servo_angle.getText())); // todo:相互連動（今はスライダーからnumberboxへの一方向）
      } catch (RuntimeException e) {
        tf_servo_angle.setText(str((float)(round(sl_servo_angle.getValue() * 10) / 10)));        
      }
    }
    // SERVO角度スライダーを変更した時
    if (theEvent.controller().name() == "servo_angle_slider") {
      if (sl_servo_angle.getValue() != last_angle) {
        if (is_from_tf) {
          is_from_tf = false;
        }
        tf_servo_angle.setText(str((float)(round(sl_servo_angle.getValue() * 10) / 10)));
        sendCommand(makeSingleAngleCommand((int)(nb_servo_id.getValue()), (float)(round(sl_servo_angle.getValue() * 10) / 10), (int)2));
        last_angle = sl_servo_angle.getValue();
      }
    }
    // SET_IKボタンをクリックした時
    if (theEvent.controller().name() == "set_ik") {
      if (serial_connected) {
        sendCommand(makeSetIKCommand((int)(dl_kid.getValue()), (int)(nb_ik_x.getValue()), (int)(nb_ik_y.getValue()), (int)(nb_ik_z.getValue())));
      }
    }
    // GET_IKボタンをクリックした時
    if (theEvent.controller().name() == "get_ik") {
      if (serial_connected) {
        sendCommand(makeGetIKCommand((int)(dl_kid.getValue())));
      }
    }
    // WALKボタンをクリックした時
    if (theEvent.controller().name() == "walk") {
      if (serial_connected) {
        sendCommand(makeWalkCommand((int)(nb_walk_speed.getValue()), (int)(nb_walk_turn.getValue())));
      }
    }
    // SENDボタンをクリックした時
    if ((theEvent.controller().name() == "send") || (theEvent.controller().name() == "send_command")) {
      if (serial_connected) {
        sendCommand(parseCommand(tf_command.getText()));
      }
    }
  }
}

// コマンド送信
void sendCommand(byte[] command) {
  if (serial_connected) {
    serial_port.write(command);
    String log_text = "";
    log_text += ">";
    for (int i = 0; i < command.length; i++) {
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

// コマンドのLNとSUMを計算する
byte[] adjustLnSum(byte[] command) {
  if (command.length > 3) {
    command[2] = byte(command.length);

    byte sum = 0;
    for (int i = 0; i < command.length - 1; i++) {
      sum ^= command[i];
    }
    command[command.length - 1] = sum;
  }
  return command;  
}

// テキストで渡された任意のコードをパースしてコマンドを生成する
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
  if (cb_adjust_lnsum.getState(0)) {
    return adjustLnSum(command);
  } else {
    return command;
  }
}

// サーボに角度の指示を送るコマンドを生成する
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

  return adjustLnSum(data);
}

// サーボにIK位置を指示するコマンドを生成する
byte[] makeSetIKCommand(int kid, int x, int y, int z) {
  byte[] data = {};
 
  data = (byte[])append(data, COMMAND_ST); // ST
  data = (byte[])append(data, COMMAND_OP_IK); // OP
  data = (byte[])append(data, (byte)0); // LN仮置き（あとで計算する）
  data = (byte[])append(data, (byte)0x01); // IKF(Utilityでは0で固定)
  data = (byte[])append(data, (byte)kid); // KID

  // XYZは-100〜100を0〜200に変換する
  data = (byte[])append(data, (byte)(x + 100)); // X
  data = (byte[])append(data, (byte)(y + 100)); // Y
  data = (byte[])append(data, (byte)(z + 100)); // Z
  
  data = (byte[])append(data, (byte)0); // SUM仮置き

  return adjustLnSum(data);
}

// サーボからIK位置を取得するコマンドを生成する
byte[] makeGetIKCommand(int kid) {
  byte[] data = {};

  data = (byte[])append(data, COMMAND_ST); // ST
  data = (byte[])append(data, COMMAND_OP_IK); // OP
  data = (byte[])append(data, (byte)0); // LN仮置き（あとで計算する）
  data = (byte[])append(data, (byte)0x08); // IKF(位置の要求)
  data = (byte[])append(data, (byte)kid); // KID

  data = (byte[])append(data, (byte)0); // SUM仮置き

  return adjustLnSum(data);
}

// サーボに歩行コマンドを生成する
byte[] makeWalkCommand(int speed, int turn) {
  byte[] data = {};
 
  data = (byte[])append(data, COMMAND_ST); // ST
  data = (byte[])append(data, COMMAND_OP_WALK); // OP
  data = (byte[])append(data, (byte)0); // LN仮置き（あとで計算する）
  data = (byte[])append(data, (byte)0x00); // WAD(Utilityでは0で固定)
  data = (byte[])append(data, (byte)0x02); // WLN(現在2で固定)

  // 速度ならびに旋回は-100〜100を0〜200に変換する
  data = (byte[])append(data, (byte)(speed + 100)); // X
  data = (byte[])append(data, (byte)(turn + 100)); // Y
  
  data = (byte[])append(data, (byte)0); // SUM仮置き

  return adjustLnSum(data);
}

// VIDの値のセットコマンドを生成する
byte[] makeVidSetCommand(int vid, int vdata) {
  byte[] data = {};
 
  data = (byte[])append(data, COMMAND_ST); // ST
  data = (byte[])append(data, COMMAND_OP_SETVID); // OP
  data = (byte[])append(data, (byte)0); // LN仮置き（あとで計算する）
  data = (byte[])append(data, (byte)vid); // VID
  data = (byte[])append(data, (byte)vdata); // VDT

  data = (byte[])append(data, (byte)0); // SUM仮置き

  return adjustLnSum(data);
}

// GPIOコマンドを生成する
byte[] makeGPIOCommand(int port, int value) {
  byte[] data = {};
 
  data = (byte[])append(data, COMMAND_ST); // ST
  data = (byte[])append(data, COMMAND_OP_GPIO); // OP
  data = (byte[])append(data, (byte)0); // LN仮置き（あとで計算する）
  data = (byte[])append(data, (byte)port); // IID(4-7)
  data = (byte[])append(data, (byte)value); // VAL

  data = (byte[])append(data, (byte)0); // SUM仮置き

  return adjustLnSum(data);
}

// シリアル受信処理（CONNECTからのリターンコード）
void check_serial_rx() {
  int data;
  if (serial_port != null) {
    while (serial_port.available() > 0) {
      data = serial_port.read();
      // println(data); // デバグ用出力
      // リターンコードの1バイト目検出
      if (data == 0xff) {
        buffer = new byte[0];
      }
      buffer = (byte[])append(buffer, (byte)data);
      if (buffer.length > 3) {
        // LN(3バイト目)を受信すると受信すべきバイト数がわかるので、LNの長さまではバッファに貯め続ける
        if (buffer.length == buffer[2]) {
          // LN(3バイト目)で指定された長さの受信をして、受信完了処理
          // リターンコードに応じた処理
          switch((int)buffer[1]) {
            case 0x21:
              // ack
              break;
            case 0x6b:
              // IK status
              if ((int)(dl_kid.getValue()) == (int)(buffer[4])) {
                nb_ik_x.setValue((float)(buffer[5] - 100));
                nb_ik_y.setValue((float)(buffer[6] - 100));
                nb_ik_z.setValue((float)(buffer[7] - 100));
              }
              break;
          }
          // バッファのログへの吐き出す
          String log_text = "";
          log_text += "<";
          for (int i = 0; i < buffer.length; i++) {
            log_text += " ";
            log_text += hex(buffer[i]);
          }
          log_text += "\n";
          //println(log_text);
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

