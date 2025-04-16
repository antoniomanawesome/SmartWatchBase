#include <Arduino.h>

String receiveMessage = "";
char inputChar = '0';
void setup() {
  pinMode(RX2, INPUT); //setting UART2 Rx line to input (GPIO 16)
  Serial.begin(115200); // Initialize the Serial monitor for console debug
  Serial2.begin(115200, SERIAL_8N1); // Initialize Serial2 for receiving data from FPGA 
  // (1 start bit, 1 stop bit, 8 data bits, no parity)  
}

void loop() {

  while (Serial2.available() > 0) {
    char receivedChar = Serial2.read();
    if (receivedChar == '\n') {
      Serial.println(receiveMessage);  // Print the received message in the Serial monitor
      receiveMessage = "";  // Reset the received message
    } else {
      receiveMessage += receivedChar;  // Append characters to the received message
    }
  }
}

