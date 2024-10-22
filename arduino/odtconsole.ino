// ODT serial console interface
// TEST 5: 2024.08.10 Read ODT console out, nanja.info
// TEST 6: 2024.08.25 Read/Write ODT console, nanja.info

#define d0_pin 2
#define d1_pin 3
#define d2_pin 4
#define d3_pin 5
#define d4_pin 6
#define d5_pin 7
#define d6_pin 8
#define d7_pin 9
#define dir_pin 10    // LOW = Read from DCJ11, HIGH : Write to DCJ11
#define oe_n_pin 11   // ODT data enable
#define rrdy_pin 12   // Ready to read from DCJ11's ODT data
#define rstb_pin 13   // Strobe for read from DCJ11's ODT data
#define wrdy_pin 14   // Ready to write to DCJ11's ODT data
#define wstb_pin 15   // Strobe for write to DCJ11's ODT data

void setup() {
//  Serial.begin(9600);
  Serial.begin(115200);
  pinMode(d0_pin, INPUT);
  pinMode(d1_pin, INPUT);
  pinMode(d2_pin, INPUT);
  pinMode(d3_pin, INPUT);
  pinMode(d4_pin, INPUT);
  pinMode(d5_pin, INPUT);
  pinMode(d6_pin, INPUT);
  pinMode(d7_pin, INPUT);
  pinMode(rrdy_pin, OUTPUT);
  pinMode(rstb_pin, INPUT);
  pinMode(wrdy_pin, OUTPUT);
  pinMode(wstb_pin, INPUT);
  pinMode(dir_pin, OUTPUT);
  pinMode(oe_n_pin, OUTPUT);
  digitalWrite(rrdy_pin, HIGH);
  digitalWrite(wrdy_pin, LOW);
  digitalWrite(dir_pin, LOW);
  digitalWrite(oe_n_pin, HIGH);
  Serial.println("Serial Start");
}

void loop() {
  static byte rdata;  // read from DCJ11's ODT data
  static byte wdata;  // write to DCJ11's ODT data
  if (digitalRead(rstb_pin)) {
    digitalWrite(dir_pin, LOW);
    pinMode(d0_pin, INPUT);
    pinMode(d1_pin, INPUT);
    pinMode(d2_pin, INPUT);
    pinMode(d3_pin, INPUT);
    pinMode(d4_pin, INPUT);
    pinMode(d5_pin, INPUT);
    pinMode(d6_pin, INPUT);
    pinMode(d7_pin, INPUT);
    digitalWrite(oe_n_pin, LOW);
    bitWrite(rdata, 0, digitalRead(d0_pin));
    bitWrite(rdata, 1, digitalRead(d1_pin));
    bitWrite(rdata, 2, digitalRead(d2_pin));
    bitWrite(rdata, 3, digitalRead(d3_pin));
    bitWrite(rdata, 4, digitalRead(d4_pin));
    bitWrite(rdata, 5, digitalRead(d5_pin));
    bitWrite(rdata, 6, digitalRead(d6_pin));
    bitWrite(rdata, 7, digitalRead(d7_pin));
    digitalWrite(oe_n_pin, HIGH);
    digitalWrite(rrdy_pin, LOW);
    Serial.write(rdata);
    digitalWrite(rrdy_pin, HIGH);
  } else if (digitalRead(wstb_pin)) {
    digitalWrite(dir_pin, HIGH);
    pinMode(d0_pin, OUTPUT);
    pinMode(d1_pin, OUTPUT);
    pinMode(d2_pin, OUTPUT);
    pinMode(d3_pin, OUTPUT);
    pinMode(d4_pin, OUTPUT);
    pinMode(d5_pin, OUTPUT);
    pinMode(d6_pin, OUTPUT);
    pinMode(d7_pin, OUTPUT);
    digitalWrite(d0_pin, bitRead(wdata, 0));
    digitalWrite(d1_pin, bitRead(wdata, 1));
    digitalWrite(d2_pin, bitRead(wdata, 2));
    digitalWrite(d3_pin, bitRead(wdata, 3));
    digitalWrite(d4_pin, bitRead(wdata, 4));
    digitalWrite(d5_pin, bitRead(wdata, 5));
    digitalWrite(d6_pin, bitRead(wdata, 6));
    digitalWrite(d7_pin, bitRead(wdata, 7));
    digitalWrite(oe_n_pin, LOW);
    digitalWrite(wrdy_pin, LOW);
  } else {
    if (Serial.available() > 0) {
      wdata = Serial.read();
      digitalWrite(wrdy_pin, HIGH);
    }
    digitalWrite(oe_n_pin, HIGH);
  }
}