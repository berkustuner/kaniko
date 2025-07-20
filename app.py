from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from config import Config
from flask import render_template


app = Flask(__name__)
app.config.from_object(Config)
db = SQLAlchemy(app)

class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    task = db.Column(db.String(200), nullable=False)

@app.route("/ui", methods=["GET:"])
def ui():
    return render_template("index.html")


@app.before_first_request
def create_tables():
    with app.app_context():
        db.create_all()

@app.route("/", methods=["GET"])
def ping():
    return jsonify({"message": "API OK"}), 200

@app.route("/todos", methods=["GET"])
def list_todos():
    todos = Todo.query.all()  # hâlâ çalışıyor
    return jsonify([{"id": t.id, "task": t.task} for t in todos]), 200

@app.route("/todos", methods=["POST"])
def add_todo():
    data = request.get_json() or {}
    if not data.get("task"):
        return jsonify({"error": "task field is required"}), 400
    t = Todo(task=data["task"])
    db.session.add(t)
    db.session.commit()
    return jsonify({"id": t.id, "task": t.task}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

