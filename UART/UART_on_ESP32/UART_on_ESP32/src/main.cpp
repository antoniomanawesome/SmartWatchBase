#include <Arduino.h>
String sendMessage = "";
char inputChar = '0';
void setup() {
  pinMode(TX2, OUTPUT); //setting UART2 Tx line to output (GPIO 17)
  Serial.begin(115200); // Initialize the Serial monitor for console debug
  Serial2.begin(115200, SERIAL_8N1); // Initialize Serial2 for sending data to FPGA (1 start bit, 1 stop bit, 8 data bits, no parity)
  //configure uart and experiment with serial write function
  
}

void loop() {

  if (Serial.available() > 0) { //if there is a character on the console, run this
    inputChar = Serial.read(); //reading the char and storing into inputChar
    if (inputChar == '\n') { //if enter is pressed, send char through UART2
      Serial2.write(sendMessage[0]);
      Serial.println(sendMessage[0]); //print to console for debug
      //Serial2.print(sendMessage);  // Send the message through Serial2 with a newline character
      sendMessage = "";  // Reset the message
    } 
    else{
      sendMessage += inputChar;
    }
  }
}

/*
sending lowercase D
d = 0x64 = 0b01100100
*/
