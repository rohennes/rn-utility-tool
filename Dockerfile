# Use the official Python image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install dependencies (including curl and jq for the script to function properly)
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy the application files to the container
COPY . .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port Flask will run on
EXPOSE 5000

# Set the environment variable to point to Flask's entry point
ENV FLASK_APP=app/app.py

# Start the Flask application
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
