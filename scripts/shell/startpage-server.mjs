#!/usr/bin/env node
import http from "node:http";
import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");
const BOOKMARKS = path.join(ROOT, "bookmarks.txt");
const INDEX = path.join(ROOT, "index.html");
const HOST = process.env.STARTPAGE_HOST || "127.0.0.1";
const PORT = Number(process.env.STARTPAGE_PORT || 8484);

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".ico": "image/x-icon",
};

function send(res, status, body, headers = {}) {
  const payload =
    typeof body === "string" || Buffer.isBuffer(body)
      ? body
      : JSON.stringify(body);
  res.writeHead(status, {
    "Cache-Control": "no-store",
    ...headers,
    "Content-Length": Buffer.byteLength(payload),
  });
  res.end(payload);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    req.on("error", reject);
  });
}

function sanitizeBookmarkText(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .filter((line) => /^https?:\/\//i.test(line))
    .join("\n");
}

async function serveStatic(req, res, urlPath) {
  let rel = decodeURIComponent(urlPath.split("?")[0] || "/");
  if (rel === "/") rel = "/index.html";
  const filePath = path.normalize(path.join(ROOT, rel));
  if (!filePath.startsWith(ROOT + path.sep) && filePath !== ROOT) {
    return send(res, 403, "Forbidden\n", {
      "Content-Type": "text/plain; charset=utf-8",
    });
  }
  try {
    const data = await fsp.readFile(filePath);
    const ext = path.extname(filePath).toLowerCase();
    return send(res, 200, data, {
      "Content-Type": MIME[ext] || "application/octet-stream",
    });
  } catch {
    return send(res, 404, "Not found\n", {
      "Content-Type": "text/plain; charset=utf-8",
    });
  }
}

const server = http.createServer(async (req, res) => {
  try {
    const method = req.method || "GET";
    const urlPath = req.url || "/";

    if (urlPath.startsWith("/api/bookmarks")) {
      if (method === "GET") {
        const text = fs.existsSync(BOOKMARKS)
          ? await fsp.readFile(BOOKMARKS, "utf8")
          : "";
        return send(res, 200, text, {
          "Content-Type": "text/plain; charset=utf-8",
        });
      }

      if (method === "PUT" || method === "POST") {
        const body = await readBody(req);
        const cleaned = sanitizeBookmarkText(body);
        const finalText = cleaned ? cleaned + "\n" : "";
        await fsp.writeFile(BOOKMARKS, finalText, "utf8");
        return send(
          res,
          200,
          { ok: true, count: cleaned ? cleaned.split("\n").length : 0 },
          { "Content-Type": "application/json; charset=utf-8" },
        );
      }

      res.setHeader("Allow", "GET, PUT, POST");
      return send(res, 405, "Method not allowed\n", {
        "Content-Type": "text/plain; charset=utf-8",
      });
    }

    if (method === "GET" || method === "HEAD") {
      if (method === "HEAD") {
        const exists = fs.existsSync(INDEX);
        return send(res, exists ? 200 : 404, "", {
          "Content-Type": "text/html; charset=utf-8",
        });
      }
      return serveStatic(req, res, urlPath);
    }

    return send(res, 405, "Method not allowed\n", {
      "Content-Type": "text/plain; charset=utf-8",
    });
  } catch (err) {
    console.error(err);
    return send(res, 500, "Internal server error\n", {
      "Content-Type": "text/plain; charset=utf-8",
    });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`startpage ready at http://${HOST}:${PORT}/`);
  console.log(`bookmarks file: ${BOOKMARKS}`);
});
