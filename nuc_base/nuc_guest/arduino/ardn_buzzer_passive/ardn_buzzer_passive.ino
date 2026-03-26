//*******************************************************************************
// Project : 12 Passive Buzzer in Sensor Kit
// Board : Arduino Uno 
// By : Kit Plus
//*******************************************************************************

int DigitalPin = 7;  // Digital input

void setup()
{
    pinMode(DigitalPin, OUTPUT);
    Serial.begin(115200);
    while (!Serial) { }
}

void loop()
{
    if (Serial.available() > 0) {
        char c = Serial.read();
        if (c == '1') {
            tone(DigitalPin, 1000); // 1000Hz ON
        } else if (c == '0') {
            noTone(DigitalPin);     // OFF
        }
    }

    delay(10);
}
