/*
Claude Sessions Exporter (run in Chrome DevTools Console on https://claude.ai/recents)

Creates the same export shape used in chatgpt-export:
  claude-export/
    markdown/*.md
    html/*.html
    json/*.json
    files/<conversation>/*

Output location:
  Uses File System Access API. You will be prompted to pick a folder.
  Pick Desktop, and this script will create ./claude-export inside it.
*/

(async () => {
  const CONFIG = {
    exportFolderName: "claude-export",
    recentsPath: "/recents",
    recentsScrollDelayMs: 900,
    recentsStableRounds: 5,
    recentsMaxRounds: 240,
    chatLoadTimeoutMs: 45000,
    chatSettleMs: 1800,
    chatScrollDelayMs: 700,
    chatMaxScrollRounds: 60,
    chatStableRounds: 4,
    minTextForSuccess: 120,
    maxFileNameLength: 120,
  };

  const ORIGIN = location.origin;
  const PREFIX = "[claude-export]";

  const log = (...args) => console.log(PREFIX, ...args);
  const warn = (...args) => console.warn(PREFIX, ...args);
  const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  function assertRecentsPage() {
    if (!location.pathname.startsWith(CONFIG.recentsPath)) {
      throw new Error(
        `Open ${ORIGIN}${CONFIG.recentsPath} first, then run this script again.`,
      );
    }
  }

  function cleanText(text) {
    return (text || "")
      .replace(/\u00a0/g, " ")
      .replace(/\r/g, "")
      .replace(/[ \t]+\n/g, "\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  }

  function sanitizeFilePart(input) {
    const safe = (input || "Untitled")
      .replace(/[\\/:*?"<>|]/g, "-")
      .replace(/\s+/g, " ")
      .trim()
      .slice(0, CONFIG.maxFileNameLength);
    return safe || "Untitled";
  }

  function shortId(id) {
    if (!id) return "unknown";
    const m = String(id).match(/[0-9a-f]{8}/i);
    return m ? m[0] : String(id).slice(0, 8);
  }

  function baseName(title, id) {
    return `${sanitizeFilePart(title)}_${shortId(id)}`;
  }

  function formatUtc(isoString) {
    if (!isoString) return "";
    const d = new Date(isoString);
    if (Number.isNaN(d.getTime())) return "";
    const y = d.getUTCFullYear();
    const mo = String(d.getUTCMonth() + 1).padStart(2, "0");
    const da = String(d.getUTCDate()).padStart(2, "0");
    const h = String(d.getUTCHours()).padStart(2, "0");
    const mi = String(d.getUTCMinutes()).padStart(2, "0");
    return `${y}-${mo}-${da} ${h}:${mi} UTC`;
  }

  function htmlEscape(s) {
    return String(s || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  async function waitFor(fn, timeoutMs, label) {
    const start = Date.now();
    while (Date.now() - start < timeoutMs) {
      try {
        const value = fn();
        if (value) return value;
      } catch {
        // ignore transient DOM errors
      }
      await sleep(150);
    }
    throw new Error(`Timeout while waiting for ${label}`);
  }

  function getScrollableWithMostChatLinks(doc = document) {
    const all = [
      doc.scrollingElement,
      ...doc.querySelectorAll("main, div, section"),
    ].filter(Boolean);
    let best = doc.scrollingElement || null;
    let bestScore = -1;

    for (const el of all) {
      const dh = (el.scrollHeight || 0) - (el.clientHeight || 0);
      if (dh < 120) continue;
      let links = 0;
      try {
        links = el.querySelectorAll('a[href^="/chat/"]').length;
      } catch {
        links = 0;
      }
      const score = dh + links * 1000;
      if (score > bestScore) {
        bestScore = score;
        best = el;
      }
    }

    return best;
  }

  function getChatScrollable(doc) {
    const textarea = doc.querySelector(
      "textarea, [contenteditable='true'][role='textbox']",
    );
    const all = [
      doc.scrollingElement,
      ...doc.querySelectorAll("main, div, section"),
    ].filter(Boolean);

    let candidates = all.filter(
      (el) => (el.scrollHeight || 0) - (el.clientHeight || 0) > 120,
    );

    if (textarea) {
      const local = candidates.filter(
        (el) => el.contains(textarea) || el.contains(textarea.parentElement),
      );
      if (local.length) candidates = local;
    }

    candidates.sort(
      (a, b) =>
        b.scrollHeight - b.clientHeight - (a.scrollHeight - a.clientHeight),
    );
    return candidates[0] || doc.scrollingElement || null;
  }

  function extractRecentsVisible() {
    const anchors = Array.from(
      document.querySelectorAll(
        'a[href^="/chat/"][data-primary="true"], a[href^="/chat/"]',
      ),
    );

    const byId = new Map();

    for (const a of anchors) {
      const href = a.getAttribute("href") || "";
      const m = href.match(/\/chat\/([0-9a-f-]{36})/i);
      if (!m) continue;

      const id = m[1];
      const row = a.closest("tr") || a.closest("li") || a.parentElement;
      const timeEl = row?.querySelector?.("time[datetime]") || null;

      const rawTitle =
        a.getAttribute("aria-label") ||
        a.textContent ||
        row?.querySelector?.("[aria-label]")?.getAttribute?.("aria-label") ||
        "Untitled";

      const title =
        cleanText(rawTitle).replace(/^Select\s+/i, "") || "Untitled";

      const existing = byId.get(id) || {
        id,
        title,
        url: `${ORIGIN}/chat/${id}`,
        datetime: null,
        relativeTime: null,
      };

      if (!existing.title || existing.title === "Untitled")
        existing.title = title;
      if (timeEl?.dateTime) existing.datetime = timeEl.dateTime;
      if (timeEl?.textContent)
        existing.relativeTime = cleanText(timeEl.textContent);

      byId.set(id, existing);
    }

    return Array.from(byId.values());
  }

  async function collectAllRecents() {
    log("Collecting sessions from recents...");
    const scroller = getScrollableWithMostChatLinks(document);
    const map = new Map();

    let stable = 0;
    let rounds = 0;
    let lastCount = -1;

    while (
      stable < CONFIG.recentsStableRounds &&
      rounds < CONFIG.recentsMaxRounds
    ) {
      rounds += 1;
      const visible = extractRecentsVisible();
      for (const item of visible) {
        if (!map.has(item.id)) {
          map.set(item.id, item);
        } else {
          const prev = map.get(item.id);
          map.set(item.id, {
            ...prev,
            ...item,
            title: prev.title || item.title,
          });
        }
      }

      const count = map.size;
      if (count === lastCount) stable += 1;
      else stable = 0;
      lastCount = count;

      if (scroller) {
        scroller.scrollTop = scroller.scrollHeight;
      } else {
        window.scrollTo(0, document.body.scrollHeight);
      }

      await sleep(CONFIG.recentsScrollDelayMs);
    }

    const sessions = Array.from(map.values());
    log(`Found ${sessions.length} sessions.`);

    return sessions;
  }

  function createExtractorFromDocument(doc, fallbackMeta = {}) {
    const titleFromH1 = cleanText(doc.querySelector("h1")?.textContent || "");
    const titleFromMeta = cleanText(doc.title || "").replace(
      /\s*[–-]\s*Claude\s*$/i,
      "",
    );
    const title =
      titleFromH1 || titleFromMeta || fallbackMeta.title || "Untitled";

    const idMatch = (doc.location?.pathname || fallbackMeta.url || "").match(
      /\/chat\/([0-9a-f-]{36})/i,
    );
    const conversationId = idMatch ? idMatch[1] : fallbackMeta.id || null;

    const main = doc.querySelector("main") || doc.body;
    const cloned = main.cloneNode(true);

    for (const node of cloned.querySelectorAll(
      "script, style, nav, aside, footer, textarea, button",
    )) {
      node.remove();
    }

    const plainText = cleanText(cloned.innerText || "");

    const turns = [];

    const messageSelectors = [
      '[data-testid*="user-message"]',
      '[data-testid*="assistant-message"]',
      '[data-testid*="message"]',
      "[data-message-author-role]",
      '[data-role="user"]',
      '[data-role="assistant"]',
      "article",
    ];

    let nodes = [];
    for (const sel of messageSelectors) {
      const found = Array.from(main.querySelectorAll(sel)).filter(
        (el) => cleanText(el.innerText).length > 0,
      );
      if (found.length >= 2) {
        nodes = found;
        break;
      }
    }

    if (nodes.length) {
      const filtered = nodes.filter(
        (node) =>
          !nodes.some((other) => other !== node && other.contains(node)),
      );
      filtered.forEach((node, i) => {
        const blob = [
          node.getAttribute("data-message-author-role") || "",
          node.getAttribute("data-role") || "",
          node.getAttribute("data-testid") || "",
          node.getAttribute("aria-label") || "",
          node.className || "",
        ]
          .join(" ")
          .toLowerCase();

        let role = "unknown";
        if (blob.includes("user") || blob.includes("human")) role = "user";
        else if (blob.includes("assistant") || blob.includes("claude"))
          role = "assistant";

        turns.push({
          index: i + 1,
          role,
          text: cleanText(node.innerText || ""),
        });
      });
    }

    const fileLinks = Array.from(main.querySelectorAll("a[href]"))
      .map((a) => {
        const href = a.href;
        const text = cleanText(a.textContent || "");
        return { href, text, download: a.getAttribute("download") || null };
      })
      .filter((x) => {
        if (!x.href) return false;
        if (x.href.startsWith(`${ORIGIN}/chat/`)) return false;
        if (x.href.startsWith(`${ORIGIN}/recents`)) return false;

        const looksLikeFile =
          !!x.download ||
          /\.(pdf|png|jpe?g|gif|webp|svg|txt|md|csv|json|zip|tar|gz|docx?|xlsx?|pptx?)($|[?#])/i.test(
            x.href,
          ) ||
          /(attachment|artifact|download|file|storage|blob|s3|cdn)/i.test(
            x.href,
          );

        return looksLikeFile;
      });

    const attachments = [];
    const seen = new Set();
    for (const link of fileLinks) {
      if (seen.has(link.href)) continue;
      seen.add(link.href);
      attachments.push(link);
    }

    return {
      title,
      conversationId,
      plainText,
      turns,
      attachments,
      html: main.outerHTML || "",
    };
  }

  async function getSessionContentViaFetch(session) {
    const resp = await fetch(session.url, { credentials: "include" });
    if (!resp.ok) throw new Error(`HTTP ${resp.status} for ${session.url}`);

    const rawHtml = await resp.text();
    const parser = new DOMParser();
    const doc = parser.parseFromString(rawHtml, "text/html");

    const extracted = createExtractorFromDocument(doc, session);

    return {
      ...extracted,
      rawHtml,
      sourceMode: "fetch-html",
    };
  }

  async function ensureWorkerWindow() {
    const w = window.open("about:blank", "claude_export_worker");
    if (!w) {
      throw new Error(
        "Popup blocked. Allow popups for claude.ai and run the script again.",
      );
    }
    return w;
  }

  async function getSessionContentViaWorkerWindow(session, workerWindow) {
    workerWindow.location.href = session.url;

    await waitFor(
      () => {
        try {
          return (
            workerWindow.document?.readyState === "complete" &&
            /\/chat\//.test(workerWindow.location?.pathname || "")
          );
        } catch {
          return false;
        }
      },
      CONFIG.chatLoadTimeoutMs,
      `chat page load: ${session.url}`,
    );

    await sleep(CONFIG.chatSettleMs);

    const doc = workerWindow.document;
    const scroller = getChatScrollable(doc) || doc.scrollingElement;

    if (scroller) {
      let stable = 0;
      let lastH = -1;

      for (
        let i = 0;
        i < CONFIG.chatMaxScrollRounds && stable < CONFIG.chatStableRounds;
        i += 1
      ) {
        scroller.scrollTop = 0;
        await sleep(CONFIG.chatScrollDelayMs);
        const h = scroller.scrollHeight;
        if (h === lastH) stable += 1;
        else stable = 0;
        lastH = h;
      }

      scroller.scrollTop = scroller.scrollHeight;
      await sleep(350);
    }

    const extracted = createExtractorFromDocument(doc, session);

    return {
      ...extracted,
      rawHtml: doc.documentElement?.outerHTML || "",
      sourceMode: "live-dom",
    };
  }

  function markdownFromSession(s) {
    const chunks = [];
    chunks.push(`# ${s.title || "Untitled"}`);
    if (s.datetime) chunks.push(`\n*${formatUtc(s.datetime)}*`);

    if (Array.isArray(s.turns) && s.turns.length) {
      for (const t of s.turns) {
        const role =
          t.role === "assistant"
            ? "Assistant"
            : t.role === "user"
              ? "User"
              : "Message";
        chunks.push(`\n## ${role}\n\n${t.text || ""}`);
      }
    } else if (s.plainText) {
      chunks.push(`\n${s.plainText}`);
    }

    return chunks.join("\n").trim() + "\n";
  }

  function htmlFromSession(s, allSessions) {
    const title = s.title || "Untitled";
    const date = s.datetime ? formatUtc(s.datetime) : "";
    const body =
      Array.isArray(s.turns) && s.turns.length
        ? s.turns
            .map((t) => {
              const role =
                t.role === "assistant"
                  ? "Assistant"
                  : t.role === "user"
                    ? "User"
                    : "Message";
              return `<section class="message ${t.role || "unknown"}"><h2>${htmlEscape(role)}</h2><pre>${htmlEscape(
                t.text || "",
              )}</pre></section>`;
            })
            .join("\n")
        : `<pre>${htmlEscape(s.plainText || "")}</pre>`;

    const nav = allSessions
      .map((x) => {
        const active = x.id === s.id ? ' class="active"' : "";
        const href = `../html/${encodeURIComponent(baseName(x.title, x.id))}.html`;
        return `<a${active} href="${href}">${htmlEscape(x.title || "Untitled")}</a>`;
      })
      .join("\n");

    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1" />
<title>${htmlEscape(title)}</title>
<style>
*{box-sizing:border-box} body{margin:0;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Arial,sans-serif;display:flex;height:100vh}
aside{width:280px;overflow:auto;border-right:1px solid #e6e6e6;background:#fafafa;padding:12px}
aside a{display:block;padding:8px 10px;margin:2px 0;border-radius:8px;color:#111;text-decoration:none;font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
aside a.active,aside a:hover{background:#ececec}
main{flex:1;overflow:auto;padding:24px;max-width:920px}
h1{margin:0 0 6px 0;font-size:24px}.date{color:#6c6c6c;font-size:13px;margin-bottom:24px}
.message{margin:0 0 24px 0}.message h2{font-size:14px;margin:0 0 8px 0;color:#555;text-transform:uppercase;letter-spacing:.04em}
pre{white-space:pre-wrap;word-break:break-word;background:#f6f6f6;padding:12px;border-radius:10px;margin:0}
</style>
</head>
<body>
<aside>${nav}</aside>
<main>
<h1>${htmlEscape(title)}</h1>
<div class="date">${htmlEscape(date)}</div>
${body}
</main>
</body>
</html>`;
  }

  async function pickExportFolders() {
    if (!("showDirectoryPicker" in window)) {
      throw new Error(
        "Your browser does not support File System Access API (showDirectoryPicker).",
      );
    }

    log(
      "Choose your Desktop folder in the picker so the script can create claude-export there.",
    );
    const desktopHandle = await window.showDirectoryPicker({
      mode: "readwrite",
      startIn: "desktop",
    });

    const root = await desktopHandle.getDirectoryHandle(
      CONFIG.exportFolderName,
      { create: true },
    );
    const markdown = await root.getDirectoryHandle("markdown", {
      create: true,
    });
    const html = await root.getDirectoryHandle("html", { create: true });
    const json = await root.getDirectoryHandle("json", { create: true });
    const files = await root.getDirectoryHandle("files", { create: true });

    return { root, markdown, html, json, files };
  }

  async function writeTextFile(dirHandle, fileName, content) {
    const fh = await dirHandle.getFileHandle(fileName, { create: true });
    const w = await fh.createWritable();
    await w.write(content);
    await w.close();
  }

  async function writeBlobFile(dirHandle, fileName, blob) {
    const fh = await dirHandle.getFileHandle(fileName, { create: true });
    const w = await fh.createWritable();
    await w.write(blob);
    await w.close();
  }

  function fileNameFromUrl(url, fallback = "file") {
    try {
      const u = new URL(url);
      const last = decodeURIComponent(
        (u.pathname.split("/").pop() || "").trim(),
      );
      const clean = sanitizeFilePart(last || fallback);
      return clean || fallback;
    } catch {
      return fallback;
    }
  }

  async function saveAttachments(session, filesRootHandle) {
    const saved = [];
    const dir = await filesRootHandle.getDirectoryHandle(
      baseName(session.title, session.id),
      { create: true },
    );

    for (let i = 0; i < (session.attachments || []).length; i += 1) {
      const att = session.attachments[i];
      const suggested =
        att.download || att.text || fileNameFromUrl(att.href, `file-${i + 1}`);
      const fname = sanitizeFilePart(suggested || `file-${i + 1}`);

      try {
        const res = await fetch(att.href, { credentials: "include" });
        if (!res.ok) throw new Error(`HTTP ${res.status}`);

        const blob = await res.blob();
        const finalName = fname.includes(".")
          ? fname
          : `${fname}${guessExtFromType(blob.type)}`;
        await writeBlobFile(dir, finalName, blob);

        saved.push({
          name: finalName,
          url: att.href,
          size: blob.size,
          contentType: blob.type || null,
          ok: true,
        });
      } catch (error) {
        saved.push({
          name: fname,
          url: att.href,
          ok: false,
          error: String(error?.message || error),
        });
      }
    }

    return saved;
  }

  function guessExtFromType(contentType) {
    if (!contentType) return "";
    if (contentType.includes("json")) return ".json";
    if (contentType.includes("markdown")) return ".md";
    if (contentType.includes("plain")) return ".txt";
    if (contentType.includes("png")) return ".png";
    if (contentType.includes("jpeg")) return ".jpg";
    if (contentType.includes("gif")) return ".gif";
    if (contentType.includes("webp")) return ".webp";
    if (contentType.includes("pdf")) return ".pdf";
    if (contentType.includes("zip")) return ".zip";
    return "";
  }

  // ------------------------------
  // Main flow
  // ------------------------------

  assertRecentsPage();

  const folders = await pickExportFolders();
  const sessions = await collectAllRecents();

  if (!sessions.length) {
    throw new Error("No Claude sessions found on /recents.");
  }

  const workerWindow = await ensureWorkerWindow();

  const exported = [];

  for (let i = 0; i < sessions.length; i += 1) {
    const s = sessions[i];
    log(`[${i + 1}/${sessions.length}] Exporting: ${s.title}`);

    let extracted = null;

    try {
      extracted = await getSessionContentViaFetch(s);
      if (
        !extracted.plainText ||
        extracted.plainText.length < CONFIG.minTextForSuccess
      ) {
        throw new Error(
          "Fetched HTML did not include enough conversation text.",
        );
      }
    } catch (err) {
      warn(`Fetch extraction fallback for ${s.title}:`, err?.message || err);
      extracted = await getSessionContentViaWorkerWindow(s, workerWindow);
    }

    const merged = {
      id: s.id,
      title: extracted.title || s.title || "Untitled",
      url: s.url,
      datetime: s.datetime || null,
      relativeTime: s.relativeTime || null,
      extractedAt: new Date().toISOString(),
      sourceMode: extracted.sourceMode,
      plainText: extracted.plainText || "",
      turns: extracted.turns || [],
      attachments: extracted.attachments || [],
      rawHtmlSize: (extracted.rawHtml || "").length,
    };

    const savedAttachments = await saveAttachments(merged, folders.files);
    merged.savedAttachments = savedAttachments;

    const name = baseName(merged.title, merged.id);

    await writeTextFile(
      folders.markdown,
      `${name}.md`,
      markdownFromSession(merged),
    );
    await writeTextFile(
      folders.json,
      `${name}.json`,
      JSON.stringify(merged, null, 2),
    );
    await writeTextFile(
      folders.html,
      `${name}.html`,
      htmlFromSession(merged, sessions),
    );

    exported.push(merged);
  }

  await writeTextFile(
    folders.root,
    "index.json",
    JSON.stringify(
      {
        source: `${ORIGIN}/recents`,
        exportedAt: new Date().toISOString(),
        count: exported.length,
        conversations: exported.map((x) => ({
          id: x.id,
          title: x.title,
          url: x.url,
          datetime: x.datetime,
          relativeTime: x.relativeTime,
          turns: x.turns.length,
          sourceMode: x.sourceMode,
        })),
      },
      null,
      2,
    ),
  );

  try {
    workerWindow.close();
  } catch {
    // ignore
  }

  log("Done.");
  log(`Export completed: ~/Desktop/${CONFIG.exportFolderName}`);
})();
