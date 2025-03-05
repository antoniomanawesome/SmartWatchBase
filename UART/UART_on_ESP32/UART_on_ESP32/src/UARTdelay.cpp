#include <Arduino.h>


void setup() {
  pinMode(TX2, OUTPUT);
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1); 
  Serial.println("Setup done");
  
}

void loop() {

    for(uint8_t i = 0; i < 5; i++){
        Serial2.write(i);
        delay(100);
    }

    Serial.println("Loop Done");

}
