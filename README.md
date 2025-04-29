# DeltaMind: AI-Powered Learning Assistant

## 🧠 Overview

DeltaMind is an intelligent learning assistant that helps users create personalized quizzes from their study materials using AI. It analyzes your content, generates relevant questions, and provides tailored feedback to enhance your learning experience.

## ✨ Features

- **AI-Generated Quizzes**: Upload PDF or text files, or paste your study notes to instantly generate quizzes
- **Personalized Learning**: Choose quiz types (multiple choice, true/false), difficulty levels, and question count
- **Smart Feedback**: Receive AI-powered recommendations based on your quiz performance
- **Cross-Platform**: Works seamlessly on web, iOS, and Android
- **Streak Freeze**: Pause your streak to maintain your momentum even during breaks.
- **Analytics**: Gain deeper insights into your learning progress and quiz performance.


## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.7.2 or higher)
- [Dart SDK](https://dart.dev/get-dart) (v3.0.0 or higher)
- [Supabase Account](https://supabase.com) for backend services
- [Google AI Gemini API Key](https://ai.google.dev/) for AI-powered features

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/rafapradana/deltamind.git
   cd deltamind
   ```

2. Create a `.env` file in the project root with the following variables:
   ```
   SUPABASE_URL=contact_me_to_get_the_url
   SUPABASE_ANON_KEY=contact_me_to_get_the_anon_key
   GEMINI_API_KEY=use_your_own_gemini_api_key

   ```

3. Install dependencies
   ```bash
   flutter pub get
   ```

4. Run the app
   ```bash
   flutter run
   ```

## 🏗️ Architecture

DeltaMind follows a feature-first architecture with Riverpod for state management:

```
lib/
├── core/            # Core utilities, constants, and helpers
├── features/        # Feature modules (auth, quiz, history, etc.)
├── models/          # Data models
├── services/        # Service layer (API clients, database)
└── main.dart        # Application entry point
```

## 🤝 Contributing

We welcome contributions to DeltaMind! Please see our [Contributing Guidelines](CONTRIBUTING.md) for more details.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - UI toolkit
- [Supabase](https://supabase.com) - Backend as a Service
- [Google Gemini AI](https://ai.google.dev/) - AI-powered features
- [Syncfusion Flutter PDF](https://www.syncfusion.com/flutter-widgets/flutter-pdf) - PDF processing
