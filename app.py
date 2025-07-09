from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Merhaba Dünya! Bu bir Kaniko deploy testidir."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

