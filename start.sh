#!/bin/bash

echo "Building Java backend..."
mvn clean package

echo "Starting Java backend..."
java -jar target/p2p-1.0-SNAPSHOT.jar &
BACKEND_PID=$!

echo "Waiting for backend to start..."
sleep 3

if [ ! -d "ui/node_modules" ]; then
  echo "Installing frontend dependencies..."
  cd ui && npm install && cd ..
fi

echo "Starting frontend..."
cd ui && npm run dev

echo "Stopping backend (PID: $BACKEND_PID)..."
kill $BACKEND_PID
