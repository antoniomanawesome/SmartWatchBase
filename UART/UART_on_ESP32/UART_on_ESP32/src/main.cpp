#include <Arduino.h>

String sendMessage = "";
void setup() {
  pinMode(TX, OUTPUT); //setting UART0 Tx line to output 
  Serial.begin(115200); // Initialize the Serial monitor for console debug
  Serial2.begin(115200, SERIAL_8N1); // Initialize Serial2 for sending data to FPGA
  //configure uart and experiment with serial write function
  
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
    Serial.println(sendMessage);
    //delay(1000);
  }
}
