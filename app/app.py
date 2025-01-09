from flask import Flask, render_template, request, jsonify
import subprocess

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/run-tool", methods=["POST"])
def run_tool():
    option = request.form.get("option")
    y_stream = request.form.get("y_stream", "")
    bug_id = request.form.get("bug_id", "")  # Capture the bug URL input, if provided

    print(f"Option: {option}, Bug ID: {bug_id}, Y-stream: {y_stream}")

    try:
        # Construct the command based on the selected option
        if option == "4" and bug_id:  # If option 4 is selected, include the bug_id
            print(f"Bug ID: {bug_id}")
            command = f"./tool/rn-utility-tool.sh {option} {y_stream} {bug_id}"
        else:
            command = f"./tool/rn-utility-tool.sh {option} {y_stream}"
            print(f"Option: {option}")

        # Execute the command
        result = subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT, text=True)
        return jsonify({"success": True, "output": result})

    except subprocess.CalledProcessError as e:
        print(f"Error: {e.output}")  # Print error output to the Flask logs
        return jsonify({"success": False, "error": e.output})

if __name__ == "__main__":
    app.run(debug=True)
