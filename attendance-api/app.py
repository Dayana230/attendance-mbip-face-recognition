from flask import Flask, request, jsonify, render_template, send_file
from fpdf import FPDF
from flask import after_this_request, send_file
import numpy as np
import uuid, os, json, csv
from datetime import datetime
from werkzeug.utils import secure_filename
import face_recognition

app = Flask(__name__)

ATTENDANCE_FILE = 'attendance.json'
KNOWN_FACES_DIR = 'known_faces'
UPLOAD_DIR = 'uploads'
SCAN_STATUS_FILE = 'scan_status.txt'

os.makedirs(KNOWN_FACES_DIR, exist_ok=True)
os.makedirs(UPLOAD_DIR, exist_ok=True)

# ======================
# SCAN STATUS
# ======================
def is_scan_enabled():
    if not os.path.exists(SCAN_STATUS_FILE):
        return False
    with open(SCAN_STATUS_FILE) as f:
        return f.read().strip() == 'ON'


# ======================
# LOAD KNOWN FACES
# ======================
def load_known_faces():
    encodings, names = [], []
    for name in os.listdir(KNOWN_FACES_DIR):
        folder = os.path.join(KNOWN_FACES_DIR, name)
        if not os.path.isdir(folder):
            continue
        for img in os.listdir(folder):
            if img.lower().endswith(('jpg','png','jpeg')):
                image = face_recognition.load_image_file(os.path.join(folder, img))
                enc = face_recognition.face_encodings(image)
                if enc:
                    encodings.append(enc[0])
                    names.append(name)
    return encodings, names


# ======================
# SAVE ATTENDANCE
# ======================
def save_attendance(name, department='-'):
    today = datetime.now().strftime("%Y-%m-%d")
    time_now = datetime.now().strftime("%H:%M:%S")

    data = {}
    if os.path.exists(ATTENDANCE_FILE):
        with open(ATTENDANCE_FILE) as f:
            data = json.load(f)

    data.setdefault(today, [])

    for r in data[today]:
        if r['name'] == name:
            return

    data[today].append({
        "id": str(uuid.uuid4()),
        "name": name,
        "department": department,
        "time": time_now
    })

    with open(ATTENDANCE_FILE, 'w') as f:
        json.dump(data, f, indent=4)


# ======================
# REGISTER FACE
# ======================
@app.route('/register_face', methods=['POST'])
def register_face():
    name = request.form.get('name')
    image = request.files.get('image')

    if not name or not image:
        return jsonify({"error": "Missing data"}), 400

    folder = os.path.join(KNOWN_FACES_DIR, secure_filename(name))
    os.makedirs(folder, exist_ok=True)

    path = os.path.join(folder, f"{uuid.uuid4()}.jpg")
    image.save(path)

    img = face_recognition.load_image_file(path)
    if not face_recognition.face_encodings(img):
        os.remove(path)
        return jsonify({"error": "No face detected"}), 400

    return jsonify({"status": "success"})


# ======================
# RECOGNIZE FACE
# ======================
@app.route('/recognize', methods=['POST'])
def recognize():
    if not is_scan_enabled():
        return jsonify({"status":"blocked","message":"Scan OFF by admin"}), 403

    known_enc, known_names = load_known_faces()
    if not known_enc:
        return jsonify({"error": "No registered faces"}), 500

    file = request.files['image']
    path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}.jpg")
    file.save(path)

    img = face_recognition.load_image_file(path)
    enc = face_recognition.face_encodings(img)
    os.remove(path)

    if not enc:
        return jsonify({"status":"failed","message":"No face detected"})

    dist = face_recognition.face_distance(known_enc, enc[0])
    idx = np.argmin(dist)

    if dist[idx] < 0.4:
        name = known_names[idx]
        save_attendance(name)
        return jsonify({"status":"success","name":name})

    return jsonify({"status":"failed","message":"Unknown face"})


# ======================
# ADMIN PAGE
# ======================
@app.route('/admin')
def admin():
    date = request.args.get('date', datetime.now().strftime('%Y-%m-%d'))
    data = []
    total = 0
    last_update = "-"

    if os.path.exists(ATTENDANCE_FILE):
        with open(ATTENDANCE_FILE) as f:
            all_data = json.load(f)
            data = all_data.get(date, [])
            total = len(data)
            if data:
                last_update = data[-1]['time']

    return render_template(
        'admin.html',
        data=data,
        selected_date=date,
        total_attendance=total,
        last_update=last_update
    )


# ======================
# TOGGLE SCAN
# ======================
@app.route('/admin/toggle_scan', methods=['POST'])
def toggle_scan():
    enabled = request.json.get('enabled')
    with open(SCAN_STATUS_FILE, 'w') as f:
        f.write('ON' if enabled else 'OFF')
    return jsonify({"status":"success"})

# ======================
# STATUS SCAN
# ======================

@app.route('/scan_status')
def scan_status():
    return jsonify({
        "enabled": is_scan_enabled()
    })

# ======================
# ADMIN USER
# ======================

@app.route('/admin/users')
def admin_users():
    users = get_all_users()  # query DB
    return render_template('admin_users.html', users=users)


# ======================
# DELETE RECORD
# ======================
@app.route('/delete', methods=['POST'])
def delete():
    req = request.json
    date, rid = req['date'], req['id']

    with open(ATTENDANCE_FILE) as f:
        data = json.load(f)

    data[date] = [r for r in data.get(date, []) if r['id'] != rid]

    with open(ATTENDANCE_FILE, 'w') as f:
        json.dump(data, f, indent=4)

    return jsonify({"status":"success"})


# ======================
# DOWNLOAD CSV
# ======================
@app.route('/admin/download')
def download_pdf():
    date = request.args.get('date')
    filename = f"attendance_{date}.pdf"
    logo_path = os.path.join('static', 'MBIP.png')

    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)

    # =========================
    # LOGO (CENTER)
    # =========================
    if os.path.exists(logo_path):
        pdf.image(logo_path, x=85, y=10, w=40)  # betul-betul tengah
    pdf.ln(38)

    # =========================
    # TITLE
    # =========================
    pdf.set_font("Arial", "B", 14)
    pdf.cell(0, 10, f"Attendance MBIP - {date}", ln=True, align="C")
    pdf.ln(10)

    # =========================
    # TABLE HEADER
    # =========================
    pdf.set_font("Arial", "B", 11)
    pdf.set_fill_color(220, 220, 220)

    pdf.cell(90, 10, "Name", border=1, align="C", fill=True)
    pdf.cell(50, 10, "Department", border=1, align="C", fill=True)
    pdf.cell(40, 10, "Time", border=1, align="C", fill=True)
    pdf.ln()

    # =========================
    # TABLE DATA
    # =========================
    pdf.set_font("Arial", "", 10)

    if os.path.exists(ATTENDANCE_FILE):
        with open(ATTENDANCE_FILE) as af:
            data = json.load(af)
            for r in data.get(date, []):

                y_before = pdf.get_y()

                # NAME (auto wrap)
                pdf.multi_cell(90, 8, r.get('name',''), border=1)
                y_after = pdf.get_y()
                height = y_after - y_before

                # Department
                pdf.set_xy(10 + 90, y_before)
                pdf.cell(50, height, r.get('department','-'), border=1)

                # Time
                pdf.set_xy(10 + 140, y_before)
                pdf.cell(40, height, r.get('time',''), border=1)

                pdf.set_y(y_after)

    pdf.output(filename)

    @after_this_request
    def remove_file(response):
        try:
            os.remove(filename)
        except:
            pass
        return response

    return send_file(filename, as_attachment=True)


# ======================
# GET ATTENDANCE HISTORY BY NAME
# ======================
@app.route('/attendance', methods=['GET'])
def get_attendance():
    name = request.args.get('name')
    
    if not name:
        return jsonify({"error": "Name parameter required"}), 400
    
    history = []
    
    if os.path.exists(ATTENDANCE_FILE):
        with open(ATTENDANCE_FILE) as f:
            all_data = json.load(f)
            
            # Loop through all dates
            for date, records in all_data.items():
                # Find records matching this name
                for record in records:
                    if record['name'] == name:
                        history.append({
                            "id": record.get('id', ''),
                            "name": record['name'],
                            "department": record.get('department', '-'),
                            "date": date,
                            "time": record['time']
                        })
    
    # Sort by date (newest first)
    history.sort(key=lambda x: x['date'], reverse=True)
    
    return jsonify({"history": history})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
