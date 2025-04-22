
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const nodemailer = require('nodemailer');
const twilio = require('twilio');
const admin = require('firebase-admin');

const app = express();
const port = 3000;

// Firestore initialization
const serviceAccount = require("/home/lucifer/Downloads/dementia-app-dc774-firebase-adminsdk-fbsvc-0d7c329e39.json"); // Add this file to root
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

app.use(cors());
app.use(bodyParser.json());

/* --- Twilio Setup --- */
const accountSid = 'AC755a1b232b31a01ace0376d567b528d8';
const authToken = 'a81690a38ff6bd478a25825ed70e7d23';
const twilioClient = twilio(accountSid, authToken);
const fromWhatsAppNumber = 'whatsapp:+14155238886'; // Twilio sandbox number
const toWhatsAppNumber = 'whatsapp:+919637982831'; // Caregiver's number

/* --- Nodemailer Setup --- */
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'biradartejas842@gmail.com',
    pass: 'ggwk sady jrfv nihh' //changed this since my orignal password is private
  },
});

/* --- Send WhatsApp Route --- */
app.post('/send_whatsapp', async (req, res) => {
  try {
    const { message } = req.body;
    await twilioClient.messages.create({
      from: fromWhatsAppNumber,
      to: toWhatsAppNumber,
      body: message || 'Alert: Please check on the patient immediately!',
    });
    res.status(200).send('WhatsApp message sent.');
  } catch (error) {
    console.error(error);
    res.status(500).send('Failed to send WhatsApp message.');
  }
});

/* --- Send Mail Route --- */
app.post('/send_mail', async (req, res) => {
  try {
    const { subject, text } = req.body;
    const mailOptions = {
      from: 'biradartejas842@gmail.com',
      to: 'atharva.shirke24@vit.edu',
      subject: subject || 'Patient Alert',
      text: text || 'Alert: Something might be wrong with the patient.',
    };
    await transporter.sendMail(mailOptions);
    res.status(200).send('Email sent.');
  } catch (error) {
    console.error(error);
    res.status(500).send('Failed to send email.');
  }
});

/* --- Firestore Danger Listener --- */
const logsRef = db.collection('logs');

logsRef.onSnapshot(snapshot => {
  snapshot.docChanges().forEach(change => {
    if (change.type === 'added') {
      const data = change.doc.data();
      if (data.message && data.message.toLowerCase().includes('danger')) {
        // Send push notification logic here (handled in Flutter)
        console.log('DANGER detected in logs! Triggering alerts...');
        
        // Optionally: trigger WhatsApp and Email from here
        // Or handle this from Flutter by calling /send_mail and /send_whatsapp
      }
    }
  });
});

app.listen(port, () => {
  console.log(`Server running on http://192.168.2.125:${port}`);
});
