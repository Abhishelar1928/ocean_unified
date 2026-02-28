# Ocean Unified

An AI-powered oceanographic decision-support system that helps fishing vessels identify optimal fishing zones and navigate efficiently.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [System Architecture](#system-architecture)
- [Main Features](#main-features)
- [Technical Highlights](#technical-highlights)
- [Getting Started](#getting-started)

---

## Problem Statement

Fishing vessels currently lack access to real-time information about:

- Where fish density is highest
- Real-time optimal fishing zones
- Efficient routes to fishing zones

Manual exploration wastes fuel, time, and money.

---

## Solution

This platform addresses these challenges by:

- Using an AI model to predict fishing probability
- Converting predictions into GeoJSON format
- Displaying an interactive map on the web via `app.py`
- Displaying the same predictions in a Flutter mobile app
- Using clustering for performance at scale
- Allowing users to get directions from their location to a fishing hotspot

---

## System Architecture

### Backend

- Python
- GeoJSON generation
- Prediction model
- Map rendering (web version)

### Mobile

- Flutter
- FlutterMap
- Marker clustering
- GeoJSON parsing
- Route visualization

---

## Main Features

### 1. North Sea Prediction Mode

- Loads `north_sea_fishing_prediction.geojson`
- Displays fishing probability points
- Color-coded by intensity

### 2. Smart Marker Clustering

- Handles 8000+ prediction points
- Smooth zoom and pan
- Dynamic cluster breakdown

### 3. Sea Mode Toggle

- Switch to marine visualization
- Focus on ocean-only region

### 4. Direction to Fishing Hotspot

- User selects start location
- Route drawn to selected prediction point
- Distance-based navigation

### 5. Performance Optimized Rendering

- No raw 8000 marker overload
- Uses clustering
- Fast mobile rendering

### 6. Cross-Platform Deployment

- Web (`app.py`)
- Mobile (Flutter Android app)

---

## Technical Highlights

- AI-powered marine prediction model
- GeoJSON-based spatial data handling
- Scalable to 8000+ geospatial points
- Optimized mobile rendering using clustering
- Real-time route visualization
- Oceanographic decision-support system

---

## Getting Started

### Web Application

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Run the web app:
   ```bash
   python app.py
   ```

### Mobile Application

1. Install Flutter by following the official guide: https://docs.flutter.dev/get-started/install
2. Navigate to the Flutter project directory (e.g., `cd flutter_app`).
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```