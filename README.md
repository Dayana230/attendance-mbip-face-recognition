# 📸 Face Recognition Attendance System

Sistem kehadiran menggunakan face recognition untuk MBIP (Majlis Bacaan & Ilmu Pagi).

## ✨ Features
- ✅ Face recognition menggunakan `face_recognition` library
- ✅ Real-time attendance tracking
- ✅ Admin dashboard untuk view & manage attendance
- ✅ Export attendance report ke PDF
- ✅ Mobile app (Flutter) untuk scan muka
- ✅ Attendance history untuk setiap user
- ✅ Admin control untuk enable/disable scanning

## 🛠️ Technology Stack

### Backend (Flask API)
- Python 3.x
- Flask
- face_recognition
- OpenCV
- FPDF (PDF generation)

### Mobile App (Flutter)
- Flutter 3.x
- Camera plugin
- HTTP requests
- Firebase Authentication

## 📥 Installation & Setup

### Prerequisites
- Python 3.8+
- Flutter SDK 3.x
- Git

### 1️⃣ Clone Repository
```bash
git clone https://github.com/Dayana230/attendance-mbip-face-recognition.git
cd attendance-mbip-face-recognition
```

### 2️⃣ Setup Backend (Flask API)
```bash
# Navigate to backend folder
cd attendance-api

# Install dependencies
pip install Flask==3.0.0
pip install face-recognition==1.3.0
pip install numpy==1.24.3
pip install opencv-python==4.8.1.78
pip install fpdf==1.7.2
pip install Werkzeug==3.0.1

# Run Flask server
python app.py
```

Server akan running di: `http://localhost:5000`

### 3️⃣ Setup Flutter Mobile App
```bash
# Navigate to Flutter project root
cd ..

# Get dependencies
flutter pub get

# Update IP address dalam code
# Edit files ni dan ganti IP dengan IP laptop yang run Flask:
# - lib/face_scan_page.dart (line ~70)
# - lib/attendance_history_page.dart (line ~30)
# Ganti: http://10.240.68.145:5000 → http://YOUR_IP:5000

# Run app
flutter run
```

**Cara Check IP Laptop:**
- Windows: `ipconfig` (cari "IPv4 Address")
- Mac/Linux: `ifconfig` atau `ip addr`

### 4️⃣ Setup Admin Dashboard

Buka browser dan pergi ke:
```
http://localhost:5000/admin
```

## 📱 How to Use

### For Users (Mobile App):
1. Open app dan login dengan Firebase account
2. Click "Scan Attendance"
3. Hadapkan muka ke camera
4. Click "Capture"
5. Sistem akan recognize dan auto save attendance

### For Admin (Web Dashboard):
1. Pergi ke `http://localhost:5000/admin`
2. View attendance by date
3. Enable/Disable scanning
4. Download PDF report
5. Delete records kalau perlu

## 📂 Project Structure
```
attendance-mbip-face-recognition/
├── attendance-api/          # Flask backend
│   ├── app.py              # Main Flask application
│   ├── templates/          # HTML templates untuk admin
│   ├── static/             # Static files (logo, etc)
│   ├── known_faces/        # Registered face images
│   └── uploads/            # Temporary uploaded images
├── lib/                    # Flutter Dart files
│   ├── main.dart
│   ├── face_scan_page.dart
│   ├── attendance_history_page.dart
│   └── ...
├── android/                # Android config
├── ios/                    # iOS config
└── README.md
```

## 🔧 Configuration

### Important Files:
- `attendance-api/attendance.json` - Attendance records database
- `attendance-api/scan_status.txt` - Scan enable/disable status
- `attendance-api/known_faces/` - Folder untuk registered faces

### Network Setup:
- Phone dan laptop MESTI connect WiFi yang sama
- Update IP address dalam Flutter code
- Pastikan port 5000 tak di-block oleh firewall

## 🐛 Troubleshooting

### Error: Connection timeout
- ✅ Pastikan Flask server running
- ✅ Check IP address betul ke tidak
- ✅ Phone & laptop on same WiFi
- ✅ Firewall allow port 5000

### Error: Face not detected
- ✅ Pastikan lighting cukup terang
- ✅ Muka facing camera dengan betul
- ✅ Register face dulu sebelum scan

## 👨‍💻 Developer
**Dayana**  
GitHub: [@Dayana230](https://github.com/Dayana230)

<img width="688" height="482" alt="image" src="https://github.com/user-attachments/assets/3076c1f4-6e56-4e0b-80c6-a21d608d3094" />


## 📄 License
This project is for educational purposes.

---

