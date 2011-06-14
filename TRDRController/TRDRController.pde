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

long bit_holder = 0;
int bit_count = 0;

long previousMillis = 0;        // will store last time LED was updated
long interval = 5000;           // interval at which to reset display (milliseconds)
int nums[] = {30178,31936,23768,36686,30174,42073,25320,28808,23339,23844,25339,41599,25380,35623,34777,23389,26839,34894,
              30095,33563,28797,22858,35617,13993,23528,34853,41621,28077,35741,23559,23305,34884};
int num = sizeof(nums);

void DATA0(void) {
    bit_count++;
    bit_holder = bit_holder << 1;
}

void DATA1(void) {
   bit_count++;
   bit_holder = bit_holder << 1;
   bit_holder |= 1;
}


void reader1One(void) {

if(digitalRead(1) == LOW) {
   bit_count++;
   bit_holder = bit_holder << 1;
   bit_holder |= 1;
  }
}

void reader1Zero(void) {
if(digitalRead(0) == LOW) {
  bit_count++;
  bit_holder = bit_holder << 1;
}
}


void setup()
{
  Serial.begin(9600);
  // Attach pin change interrupt service routines from the Wiegand RFID readers
  attachInterrupt(1, reader1One, CHANGE);  
  attachInterrupt(0, reader1Zero, CHANGE);
  delay(10);
  // the interrupt in the Atmel processor mises out the first negitave pulse as the inputs are already high,
  // so this gives a pulse to each reader input line to get the interrupts working properly.
  // Then clear out the reader variables.
  // The readers are open collector sitting normally at a one so this is OK
  pinMode(6,OUTPUT);
  digitalWrite(6,LOW);
  
  pinMode(2, OUTPUT); 
  digitalWrite(2, HIGH);       // turn on pullup resistors

  pinMode(13, OUTPUT); // inner
  digitalWrite(13, LOW);
  
  pinMode(12, OUTPUT); //outer
  digitalWrite(12,HIGH);
  
  pinMode(10, INPUT);
  
  delay(10);
  // put the reader input variables to zero
  digitalWrite(6, HIGH);  // show Arduino has finished initilisation
}

void loop() {
    if (millis() - previousMillis > interval) {
      bit_count = 0; bit_holder = 0; //in case something went wrong, clear the buffers
      previousMillis = millis();   // remember the last time we blinked the LED
    }
    
    if (bit_count == 26) {
       processRFID(bit_holder);
       bit_holder=0;
       bit_count=0;
       previousMillis=millis();
       
    } 

  if(digitalRead(10)) {
    Serial.println("Bypass open active on pin 10"); 
   open(); 
  }
     
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
  for(int i=0;i<num;i++) {
  if(val == nums[i]) {
      Serial.println("Card Authorized!");
    open();
    return;
  }
  }
  Serial.println("Card Unauthorized!");
  return;
}
void open() {  
  digitalWrite(2,LOW);
  digitalWrite(6,LOW);
  digitalWrite(13,HIGH);
  digitalWrite(12,LOW);
  delay(10000);
  digitalWrite(2,HIGH);
  digitalWrite(6,HIGH);
  digitalWrite(13,LOW);
  digitalWrite(12,HIGH);
}

