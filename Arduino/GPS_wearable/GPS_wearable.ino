void setup() {
  Serial.begin(9600);
  randomSeed(analogRead(A0));  // Better randomness
}

void loop() {
  // Latitude and Longitude bounds for Pune
  float latMin = 18.48;
  float latMax = 18.58;
  float lonMin = 73.80;
  float lonMax = 73.90;

  // Generate valid random lat/lon
  float latitude = latMin + (random(0, 100000) / 100000.0) * (latMax - latMin);
  float longitude = lonMin + (random(0, 100000) / 100000.0) * (lonMax - lonMin);

  // Print as comma-separated GPS coordinate
  Serial.print(latitude, 6);
  Serial.print(",");
  Serial.println(longitude, 6);

  delay(5000); // 5 seconds delay between updates
}
