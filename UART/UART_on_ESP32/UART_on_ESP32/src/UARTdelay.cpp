#include <Arduino.h>

String Message = "Claudius";

void setup() {
  pinMode(TX2, OUTPUT);
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1); 
  Serial.println("Setup done");
  
}

void loop() {

    for(int i = 0; i < Message.length(); i++){
        Serial2.write(Message[i]);
        delay(1000);
    }

}
