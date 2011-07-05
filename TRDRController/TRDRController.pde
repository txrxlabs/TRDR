/* Crazy People
 * By Mike Cook April 2009
 * Three RFID readers outputing 26 bit Wiegand code to pins:-
 * Reader A (Head) Pins 4 & 5
 * Reader B (Body) Pins 6 & 7
 * Reader C (Legs) Pins 8 & 9
 * Interrupt service routine gathers Wiegand pulses (zero or one) until 26 have been recieved
 * Then a sting is sent to processing
 */
/*
 * an extension to the interrupt support for arduino.
 * add pin change interrupts to the external interrupts, giving a way
 * for users to have interrupts drive off of any pin.
 * Refer to avr-gcc header files, arduino source and atmega datasheet.
 */

/*
 * Theory: all IO pins on Atmega168 are covered by Pin Change Interrupts.
 * The PCINT corresponding to the pin must be enabled and masked, and
 * an ISR routine provided.  Since PCINTs are per port, not per pin, the ISR
 * must use some logic to actually implement a per-pin interrupt service.
 */

/* Pin to interrupt map:
 * D0-D7 = PCINT 16-23 = PCIR2 = PD = PCIE2 = pcmsk2
 * D8-D13 = PCINT 0-5 = PCIR0 = PB = PCIE0 = pcmsk0
 * A0-A5 (D14-D19) = PCINT 8-13 = PCIR1 = PC = PCIE1 = pcmsk1
 */

#define rPinZero 0
#define rPinOne 1
#define rPinLight 2
#define bPin 8
#define innerPin 23
#define outerPin 24
#define innerMag 40
#define outerMag 39

long bit_holder = 0;
int bit_count = 0;

long previousMillis = 0;        // will store last time LED was updated
long interval = 5000;           // interval at which to reset display (milliseconds)
int numsFull[] = {30178,31936,23768,36686,30174,42073,25320,28808,23339,23844,
25339,41599,25380,23761,28797,23317,11342,28820,28823,31852,35623,34777,23389,26839,34894,30095,33563};
int numFull = sizeof(numsFull);

int numsTink[] = {22858,35617,13993,23528,34853,41621,28077,35741,23559,23305,32546,26763,23377,
33606,34884,23359,31858,26892,27102};
int numTink = sizeof(numsTink);





void reader1One(void){
if(digitalRead(rPinOne) == LOW) {
  Serial.print("1");
   bit_count++;
   bit_holder = bit_holder << 1;
   bit_holder |= 1;
  }
}

void reader1Zero(void) {
if(digitalRead(rPinZero) == LOW) {
  Serial.print("0");
  bit_count++;
  bit_holder = bit_holder << 1;
}
}

void lockInner(void) {
  Serial.println("Inner Door Locked.");
  digitalWrite(innerPin, LOW);
}

void lockOuter(void) {
    Serial.println("Outer Door Locked.");
  digitalWrite(outerPin, HIGH);
}
void openInner(void) {
  Serial.println("Inner Door Locked.");
  digitalWrite(innerPin, HIGH);
}

void openOuter(void) {
    Serial.println("Outer Door Locked.");
  digitalWrite(outerPin, LOW);
}



void setup()
{
  Serial.begin(9600);
  // Attach pin change interrupt service routines from the Wiegand RFID readers
  attachInterrupt(rPinOne, reader1One, CHANGE);  
  attachInterrupt(rPinZero, reader1Zero, CHANGE);
  
  delay(10);
  // the interrupt in the Atmel processor mises out the first negitave pulse as the inputs are already high,
  // so this gives a pulse to each reader input line to get the interrupts working properly.
  // Then clear out the reader variables.
  // The readers are open collector sitting normally at a one so this is OK
  pinMode(6,OUTPUT);
  digitalWrite(6,LOW);
  
  pinMode(rPinLight, OUTPUT); 
  digitalWrite(rPinLight, HIGH);       // turn on pullup resistors

  pinMode(outerPin, OUTPUT); // inner
  digitalWrite(outerPin, HIGH);
  
  pinMode(innerPin, OUTPUT); //outer
  digitalWrite(innerPin,LOW);
  
  pinMode(bPin, INPUT);
  pinMode(innerMag, INPUT); // inner door contact switch
  pinMode(outerMag, INPUT); // outer door contact switch
  delay(10);
  // put the reader input variables to zero
  digitalWrite(6, HIGH);  // show Arduino has finished initilisation
  Serial.println("Reader Init Complete.");
}

void loop() {
    if (millis() - previousMillis > interval) {
      bit_count = 0; bit_holder = 0; //in case something went wrong, clear the buffers
      previousMillis = millis();   // remember the last time we blinked the LED
    }
    
    if (bit_count == 26) {
      Serial.println("");
       processRFID(bit_holder);
       bit_holder=0;
       bit_count=0;
       previousMillis=millis();
       
    } 

  if(digitalRead(bPin)) {
    Serial.println("Bypass open active on pin 10"); 
   openFull(); 
  }
     
}
void openTink() {  
  Serial.println("Open Tink.");
  digitalWrite(rPinLight,LOW);
  digitalWrite(6,LOW);
  openOuter();
   long waitmillis = millis();
  boolean openinner = false;
  boolean openouter = false;
  boolean relockouter = false;
  boolean relockinner = false;
  while(millis()-waitmillis<10000) {
   if(!relockouter) openouter = !digitalRead(outerMag);
   if(!relockinner) openinner = !digitalRead(innerMag);

  if(openouter && digitalRead(outerMag)) {
    
    digitalWrite(outerPin, HIGH);
      Serial.println("Relatch outter on pin 19"); 
      relockouter=true;
    openouter = false;
  }
  if(openinner && digitalRead(innerMag)) {
      Serial.println("Relatch inner on pin 18");
    digitalWrite(outerPin, LOW);
    relockinner=true;
  openinner = false;
}
if((relockouter || relockinner) && digitalRead(bPin)) {
    Serial.println("Bypass open active on pin 10"); 
   openFull(); 
   break;
  }
  }
  digitalWrite(rPinLight,HIGH);
  digitalWrite(6,HIGH);
  lockOuter();
}

void openFull() {
  Serial.println("Open Full.");
   digitalWrite(rPinLight,LOW);
  digitalWrite(6,LOW);
  openOuter();
  openInner();
  long waitmillis = millis();
  boolean openinner = false;
  boolean openouter = false;
  boolean relockouter = false;
  boolean relockinner = false;
  while(millis()-waitmillis<10000) {
   if(!relockouter) openouter = !digitalRead(outerMag);
   if(!relockinner) openinner = !digitalRead(innerMag);

  if(openouter && digitalRead(outerMag)) {
    
    lockOuter();
      Serial.println("Relatch outter on pin 19"); 
      relockouter=true;
    openouter = false;
  }
  if(openinner && digitalRead(innerMag)) {
      Serial.println("Relatch inner on pin 18");
    lockInner();
    relockinner=true;
  openinner = false;
}
if((relockouter || relockinner) && digitalRead(bPin)) {
    Serial.println("Bypass open active on pin 10"); 
   openFull(); 
   break;
  }
  }
  digitalWrite(rPinLight,HIGH);
  digitalWrite(6,HIGH);
lockInner();
lockOuter();
}

void processRFID(long id) {
    Serial.print("id:");
  Serial.println(id);
  Serial.println(id, BIN);
  Serial.println((id>>17)&0x0FF, BIN);
  unsigned int facid = (unsigned int)((id>>17)&0x0FF);
  Serial.print("Facid:");
  Serial.println(facid);
if(facid != 113) {
    Serial.println("Card Unauthorized!");
    return;
}
 unsigned int val = (unsigned int)((id>>1)&0x0FFFF);
  Serial.print("Cardid:");
  Serial.println(val);
  for(int i=0;i<numFull;i++) {
  if(val == numsFull[i]) {
      Serial.println("Full Card Authorized!");
    openFull();
    return;
  }
  } for(int i=0;i<numTink;i++) {
  if(val == numsTink[i]) {
      Serial.println("Tink Card Authorized!");
    openTink();
    return;
  }
  }
  Serial.println("Card Unauthorized!");
}



