# Use the official Python slim image.
FROM python:3.11-slim

# Allow statements and log messages to immediately appear in the logs
ENV PYTHONUNBUFFERED True

# Set the working directory in the container.
WORKDIR /app

# Copy requirement file(s) to the container.
# We assume the context is the root of the repo for multi-stage/multi-service builds,
# or we can adjust for building from within the 'agent' folder.
COPY agent/requirements.txt ./agent/

# Install packages.
RUN pip install --no-cache-dir -r ./agent/requirements.txt

# Copy the agent source code.
COPY agent/ ./agent/

# Set PYTHONPATH to allow importing 'firebase_client' from 'main.py'
ENV PYTHONPATH=/app/agent

# Run the ADK server.
# The ADK engine looks for 'root_agent' in the specified module.
# Default port for Cloud Run is 8080.
CMD ["python", "-m", "google.adk.engine", "--agent", "main:root_agent", "--port", "8080"]
