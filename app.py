# app.py
from flask import Flask, request, jsonify, render_template
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, create_access_token, jwt_required
from config import Config

app = Flask(__name__)
app.config.from_object(Config)

db = SQLAlchemy(app)
jwt = JWTManager(app)

class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    task = db.Column(db.String(200), nullable=False)

@app.route("/ui", methods=["GET"])
def ui():
    return render_template("index.html")

@app.before_first_request
def create_tables():
    db.create_all()

@app.route("/", methods=["GET"])
def ping():
    return jsonify({"message": "API OK"}), 200

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    username = data.get("username")
    password = data.get("password")

    if username == app.config["APP_USER"] and password == app.config["APP_PASS"]:
        token = create_access_token(identity=username)
        return jsonify({"access_token": token}), 200
    return jsonify({"error": "invalid credentials"}), 401

@app.route("/todos", methods=["GET"])
@jwt_required()
def list_todos():
    todos = Todo.query.all()
    return jsonify([{"id": t.id, "task": t.task} for t in todos]), 200

@app.route("/todos", methods=["POST"])
@jwt_required()
def add_todo():
    data = request.get_json() or {}
    if not data.get("task"):
        return jsonify({"error": "task field is required"}), 400
    t = Todo(task=data["task"])
    db.session.add(t)
    db.session.commit()
    return jsonify({"id": t.id, "task": t.task}), 201

@app.route("/todos/<int:todo_id>", methods=["DELETE"])
@jwt_required()
def delete_todo(todo_id):
    t = Todo.query.get(todo_id)
    if not t:
        return jsonify({"error": "todo not found"}), 404
    db.session.delete(t)
    db.session.commit()
    return jsonify({"message": f"todo {todo_id} deleted"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

