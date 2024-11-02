// ODT serial console interface
// TEST 5: 2024.08.10 Read ODT console out, nanja.info
// TEST 6: 2024.08.25 Read/Write ODT console, nanja.info

#define d0_pin 2    // Data bit 0
#define d1_pin 3    // Data bit 1
#define d2_pin 4    // Data bit 2
#define d3_pin 5    // Data bit 3
#define d4_pin 6    // Data bit 4
#define d5_pin 7    // Data bit 5
#define d6_pin 8    // Data bit 6
#define d7_pin 9    // Data bti 7
#define a0_pin 10   // Address bit 0
#define a1_pin 11   // Address bit 1
#define a2_pin 12   // Address bit 2
#define a3_pin 13   // Address bit 3
#define rw_pin 14   // R/W
#define ds_pin 15   // /DEVSEL
#define A2RCSR 0    // Receiver Status; Read = rstb, Write = rrdy
#define A2RBUF 1    // Reciver Buffer Register
#define A2XCSR 2    // Transmitter Status; Read = xstb, Write = xrdy
#define A2XBUF 3    // Transmitter Buffer Register

void setup() {
  Serial.begin(115200);
  pinMode(ds_pin, OUTPUT);
  digitalWrite(ds_pin, HIGH);
  pinMode(a0_pin, OUTPUT);
  pinMode(a1_pin, OUTPUT);
  pinMode(a2_pin, OUTPUT);
  pinMode(a3_pin, OUTPUT);
  pinMode(rw_pin, OUTPUT);
  digitalWrite(rw_pin, LOW);
  addr(A2XCSR);
  digitalWrite(d7_pin, HIGH);
  ds();
  digitalWrite(rw_pin, HIGH);
  Serial.println("Serial Start");
}

void addr(byte address) {
  digitalWrite(a0_pin, bitRead(address, 0));
  digitalWrite(a1_pin, bitRead(address, 1));
  digitalWrite(a2_pin, bitRead(address, 2));
  digitalWrite(a3_pin, bitRead(address, 3));
}

void read() {
  pinMode(d0_pin, INPUT);
  pinMode(d1_pin, INPUT);
  pinMode(d2_pin, INPUT);
  pinMode(d3_pin, INPUT);
  pinMode(d4_pin, INPUT);
  pinMode(d5_pin, INPUT);
  pinMode(d6_pin, INPUT);
  pinMode(d7_pin, INPUT);
  digitalWrite(rw_pin, HIGH);
}

void write() {
  pinMode(d0_pin, OUTPUT);
  pinMode(d1_pin, OUTPUT);
  pinMode(d2_pin, OUTPUT);
  pinMode(d3_pin, OUTPUT);
  pinMode(d4_pin, OUTPUT);
  pinMode(d5_pin, OUTPUT);
  pinMode(d6_pin, OUTPUT);
  pinMode(d7_pin, OUTPUT);
  digitalWrite(rw_pin, LOW);
}

void ds() {
    digitalWrite(ds_pin, LOW);
    delayMicroseconds(1);
    digitalWrite(ds_pin, HIGH);
}

void loop() {
  static byte rdata;    // read from DCJ11's ODT data
  static byte wdata;    // write to DCJ11's ODT data
  static boolean rstb;  // Receiver Strobe
  static boolean xstb;  // Transmitter Strobe

  read();
  addr(A2XCSR);
  digitalWrite(ds_pin, LOW);
  delayMicroseconds(1);
  xstb = digitalRead(d7_pin);
  digitalWrite(ds_pin, HIGH);
  addr(A2RCSR);
  digitalWrite(ds_pin, LOW);
  delayMicroseconds(1);
  rstb = digitalRead(d7_pin);
  digitalWrite(ds_pin, HIGH);
  if (xstb)  {
    addr(A2XBUF);
    digitalWrite(ds_pin, LOW);
    delayMicroseconds(1);
    bitWrite(rdata, 0, digitalRead(d0_pin));
    bitWrite(rdata, 1, digitalRead(d1_pin));
    bitWrite(rdata, 2, digitalRead(d2_pin));
    bitWrite(rdata, 3, digitalRead(d3_pin));
    bitWrite(rdata, 4, digitalRead(d4_pin));
    bitWrite(rdata, 5, digitalRead(d5_pin));
    bitWrite(rdata, 6, digitalRead(d6_pin));
    bitWrite(rdata, 7, digitalRead(d7_pin));
    digitalWrite(ds_pin, HIGH);
    // xrdy = 0
    write();
    addr(A2XCSR);
    digitalWrite(d7_pin, LOW);
    ds();
    Serial.write(rdata);
    // xrdy = 1
    digitalWrite(d7_pin, HIGH);
    ds();
  } else if (rstb) {
    write();
    addr(A2RBUF);
    digitalWrite(d0_pin, bitRead(wdata, 0));
    digitalWrite(d1_pin, bitRead(wdata, 1));
    digitalWrite(d2_pin, bitRead(wdata, 2));
    digitalWrite(d3_pin, bitRead(wdata, 3));
    digitalWrite(d4_pin, bitRead(wdata, 4));
    digitalWrite(d5_pin, bitRead(wdata, 5));
    digitalWrite(d6_pin, bitRead(wdata, 6));
    digitalWrite(d7_pin, bitRead(wdata, 7));
    ds();
    // rrdy = 0
    addr(A2RCSR);
    digitalWrite(d7_pin, LOW);
    ds();
  } else {
    if (Serial.available() > 0) {
      wdata = Serial.read();
      // rrdy = 1
      write();
      addr(A2RCSR);
      digitalWrite(d7_pin, HIGH);
      ds();
    }
  }
}