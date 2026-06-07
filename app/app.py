from flask import Flask 

app = Flask(__name__)

@app.route("/")
def index():
    return "EC2 behind Load Balancer is running.\n", 200

@app.route("/health")
def health():
    return "OK\n", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)