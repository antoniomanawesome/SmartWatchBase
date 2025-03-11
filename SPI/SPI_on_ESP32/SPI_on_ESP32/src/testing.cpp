#include <Arduino.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 32 // OLED display height, in pixels

// Declaration for SSD1306 display connected using software SPI (default case):
#define OLED_MOSI   MOSI
#define OLED_CLK   SCK
#define OLED_DC    1
#define OLED_CS    SS
#define OLED_RESET 22
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT,
  OLED_MOSI, OLED_CLK, OLED_DC, OLED_RESET, OLED_CS);

uint8_t data[] = {9, 4, 5, 7, 2, 5, 1, 0, 1, 3, 2, 5, 5, 0};

void testdrawstyles(void);

void setup() {
    Serial.begin(9600);
  
    // SSD1306_SWITCHCAPVCC = generate display voltage from 3.3V internally
    if(!display.begin(SSD1306_SWITCHCAPVCC)) {
      Serial.println(F("SSD1306 allocation failed"));
      for(;;); // Don't proceed, loop forever
    }
  
    // Show initial display buffer contents on the screen --
    // the library initializes this with an Adafruit splash screen.
    display.display();
    delay(2000); // Pause for 2 seconds
  
    // Clear the buffer
    // display.clearDisplay();
  
    // Draw a single pixel in white
    // display.drawPixel(10, 10, SSD1306_WHITE);
  
    // Show the display buffer on the screen. You MUST call display() after
    // drawing commands to make them visible on screen!
    // display.display();
    delay(2000);
}

void loop(){
    //display time, temperature, pressure, and humidity
    testdrawstyles();
}

void testdrawstyles(void) {
    display.clearDisplay();
  
    display.setTextSize(1);             // Normal 1:1 pixel scale
    display.setTextColor(SSD1306_WHITE);        // Draw white text
    display.setCursor(0,0);             // Start at top-left corner
    
    display.print(F("The time is: "));
    display.print(data[0]);
    display.println(F(":00 PM"));
    display.println(F("Temperature: 72.5 F"));
    display.println(F("Pressure: 1013.25 hPa"));
    display.println(F("Humidity: 50%"));
  
    // display.setTextColor(SSD1306_BLACK, SSD1306_WHITE); // Draw 'inverse' text
    // display.println(3.141592);
  
    //display.setTextSize(2);             // Draw 2X-scale text
    // display.setTextColor(SSD1306_WHITE);
    // display.println(F("Jonathan Gutmann"));
  
    display.display();
    delay(2000);
  }