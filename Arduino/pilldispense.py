from flask import Flask, jsonify
import serial

app = Flask(__name__)

SERIAL_PORT = '/dev/ttyUSB0'  # Change as needed
BAUD_RATE = 9600

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
    print(f"[DISPENSE] Connected to {SERIAL_PORT}")
except Exception as e:
    print(f"[DISPENSE ERROR] Could not open serial port: {e}")
    ser = None

@app.route("/dispense", methods=["POST"])
def dispense():
    try:
        if ser and ser.is_open:
            ser.write(b'DISPENSE\n')
            print("[DISPENSE] Command sent.")
            return jsonify({"status": "success", "message": "Dispense command sent"}), 200
        else:
            return jsonify({"status": "error", "message": "Serial port not open"}), 500
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
