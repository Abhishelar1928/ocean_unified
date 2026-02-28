const express = require("express");
const cors = require("cors");
const marineRoutes = require("./routes/marineRoutes");
const { startScheduler } = require("./services/scheduler");

const app = express();
const PORT = process.env.PORT || 5000;

// ─── Middleware ───────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── Request Logger ──────────────────────────────────────────
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// ─── Routes ──────────────────────────────────────────────────
app.use("/api", marineRoutes);

// ─── Health Check ────────────────────────────────────────────
app.get("/", (_req, res) => {
  res.json({
    service: "Fisherman EduSea – Marine Data & AI Advisory API",
    version: "1.0.0",
    status: "running",
    endpoints: {
      all_data: "GET  /api/marine-data",
      by_state: "GET  /api/marine-data?state=Maharashtra",
      refresh: "POST /api/marine-data/refresh",
      learning: "POST /api/generate-learning",
      states: "GET  /api/states",
    },
  });
});

// ─── Global Error Handler ────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error("[Server Error]", err.stack || err.message);
  res.status(500).json({
    success: false,
    error: "Internal server error.",
  });
});

// ─── Start Server & Scheduler ────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🚀 Fisherman EduSea API running on http://localhost:${PORT}`);
  console.log(`   Endpoints:`);
  console.log(`     GET  http://localhost:${PORT}/api/marine-data`);
  console.log(`     GET  http://localhost:${PORT}/api/marine-data?state=Maharashtra`);
  console.log(`     POST http://localhost:${PORT}/api/marine-data/refresh`);
  console.log(`     POST http://localhost:${PORT}/api/generate-learning`);
  console.log(`     GET  http://localhost:${PORT}/api/states\n`);

  // Start the 6-hour data refresh scheduler
  startScheduler();
});
