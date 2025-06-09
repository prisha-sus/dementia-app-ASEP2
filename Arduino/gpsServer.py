from flask import Flask, request, jsonify

app = Flask(__name__)

latest_location = {
    "latitude": 0.0,
    "longitude": 0.0
}

@app.route("/api/location", methods=["POST"])
def receive_location():
    try:
        data = request.get_json(force=True)

        # Extract nested latitude and longitude
        coords = data.get("location", {}).get("coords", {})
        lat = coords.get("latitude")
        lon = coords.get("longitude")

        if lat is not None and lon is not None:
            latest_location["latitude"] = lat
            latest_location["longitude"] = lon
            print(f"[Traccar] Updated location: {lat}, {lon}")
            return jsonify({"status": "success"}), 200
        else:
            print("[WARN] Missing lat/lon in received data:", data)
            return jsonify({"error": "Missing latitude/longitude"}), 400

    except Exception as e:
        print("[ERROR] Failed to parse location:", e)
        return jsonify({"error": "Invalid request"}), 400

@app.route("/get_location", methods=["GET"])
def get_location():
    return jsonify(latest_location)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5001)
