# DeMitra 🧠🤝

**An Integrated Assistive System for Dementia Patients and Caregivers**

DeMitra is a smart, affordable, and empathetic digital solution designed to improve the quality of life for individuals living with dementia. By combining cognitive aids, safety features, and a multilingual AI companion, DeMitra aims to foster independence for patients while reducing the emotional and physical burden on caregivers.

---

## 🌟 Key Features

* **🤖 Empathetic AI Chatbot:** Powered by the **Google Gemini AI API**, the chatbot provides friendly, 24/7 interaction to combat social isolation and offer emotional support.
* **🆘 Distress Detection:** The app monitors for distress keywords (e.g., "help," "I'm scared") and automatically triggers soothing responses and caregiver alerts.
* **📅 Health & Routine Management:** Includes medication schedules, reminders for daily tasks, and routine tracking to help maintain structure.
* **🧠 Cognitive Exercises:** A suite of memory recall activities and interactive mental exercises designed to stimulate cognitive function.
* **🌍 Multilingual Support:** Specifically tailored for diverse users with support for **English, Hindi, and Marathi**, making it accessible to a wider demographic in India.
* **🌿 Calming UI/UX:** Developed with a consistent green-themed interface based on color psychology to promote a sense of safety and tranquility.

---

## 🚀 Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Cross-platform Android & iOS)
* **Backend:** [Firebase](https://firebase.google.com/) (Authentication, Real-time Database, and Cloud Messaging)
* **AI Engine:** [Google Gemini API](https://ai.google.dev/) (Natural Language Processing for the companion chatbot)
* **Language Support:** Dart / Internationalization (i18n)

---

## 🛠️ Installation & Setup

### Prerequisites

* Flutter SDK installed on your machine.
* A Firebase project set up.
* A Google Gemini API Key.

### Steps

1. **Clone the Repository:**
```bash
git clone https://github.com/prisha-sus/DeMitra.git
cd DeMitra

```


2. **Install Dependencies:**
```bash
flutter pub get

```


3. **Firebase Configuration:**
* Place your `google-services.json` (for Android) in `android/app/`.
* Place your `GoogleService-Info.plist` (for iOS) in `ios/Runner/`.


4. **API Key Setup:**
* Create a `.env` file in the root directory (or use a config file as specified in the source) and add your Gemini API key:


```env
GEMINI_API_KEY=your_api_key_here

```


5. **Run the App:**
```bash
flutter run

```



---

## 📂 Project Structure

```text
lib/
├── models/          # Data models for patients and caregivers
├── screens/         # UI screens (Home, Chatbot, Cognitive Games)
├── services/        # Firebase and Gemini API integration logic
├── utils/           # Localization (Hindi/Marathi/English) and constants
└── widgets/         # Reusable UI components

```

---

*Developed with ❤️ to bring a friend to those who need it most.*
