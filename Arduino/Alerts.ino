#include <ArduinoJson.h>

const int triggerPin = 9;
const int echoPin = 11;
long duration;
int distance;
int distanceThreshold = 50;

int outOfRangeCount = 0;  // Counter to keep track of consecutive misses
unsigned long lastLogTime = 0;
unsigned long logInterval = 30000;  // 5 minutes in milliseconds

void setup() {
  pinMode(triggerPin, OUTPUT);
  pinMode(echoPin, INPUT);
  Serial.begin(9600);
}

void loop() {
  // Ultrasonic pulse
  digitalWrite(triggerPin, LOW);
  delayMicroseconds(2);
  digitalWrite(triggerPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(triggerPin, LOW);

  // Read distance
  duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.0344 / 2;

  // Debug: Uncomment to see live distance
  //  Serial.print("Distance: ");
  // Serial.println(distance);

  if (distance < distanceThreshold) {
    outOfRangeCount = 0;  // Reset counter if detected
  } else {
    outOfRangeCount++;  // Increment if out of range
  }

  // Log caution only if two consecutive checks show out of range
  if (outOfRangeCount >= 2 && millis() - lastLogTime > logInterval) {
    DynamicJsonDocument doc(1024);
    doc["timestamp"] = millis();
    doc["message"] = "Caution: Patient has gone out of bounds";

    String output;
    serializeJson(doc, output);
    Serial.println(output);

    lastLogTime = millis();
    outOfRangeCount = 0;  // Reset after logging
  }

  delay(1000);  // Check once every second
}
