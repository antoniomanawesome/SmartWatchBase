#include <Arduino.h>

String sendMessage = "";
void setup() {
  Serial.begin(115200);    // Initialize the Serial monitor for console debug
  Serial2.begin(115200);   // Initialize Serial2 for sending data to FPGA
  
}

void loop() {

  if (Serial.available() > 0) {
    char inputChar = Serial.read();
    if (inputChar == '\n') {
      Serial2.println(sendMessage);  // Send the message through Serial2 with a newline character
      sendMessage = "";  // Reset the message
    } else {
      sendMessage += inputChar;  // Append characters to the message
    }
  }
}
