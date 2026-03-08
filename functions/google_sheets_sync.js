"use strict";

// Google Sheets export/sync helpers.
// SECURITY MODEL:
// - Runs server-side only (Cloud Functions).
// - Uses Application Default Credentials (service account).
// - Spreadsheet access must be granted by sharing the sheet with the
//   service account email used by Cloud Functions.

const { google } = require("googleapis");

const SHEETS_SCOPE = "https://www.googleapis.com/auth/spreadsheets";

function toIsoStringMaybe(v) {
  if (!v) return "";
  if (typeof v === "string") return v;
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  if (v instanceof Date) return v.toISOString();

  // Firestore Timestamp (admin.firestore.Timestamp)
  if (v && typeof v.toDate === "function") {
    try {
      return v.toDate().toISOString();
    } catch (_) {
      return "";
    }
  }

  return "";
}

function safeJson(obj, { redactKeys = [] } = {}) {
  try {
    const redact = new Set(redactKeys);
    return JSON.stringify(
      obj,
      (k, v) => {
        if (redact.has(k)) return "<redacted>";

        // Firestore Timestamp
        if (v && typeof v.toDate === "function") {
          try {
            return v.toDate().toISOString();
          } catch (_) {
            return null;
          }
        }

        // Bytes (admin.firestore.Blob)
        if (v && typeof v.toBase64 === "function") {
          try {
            return { __type: "bytes", base64: v.toBase64() };
          } catch (_) {
            return null;
          }
        }

        // GeoPoint
        if (v && typeof v.latitude === "number" && typeof v.longitude === "number") {
          return { __type: "geopoint", lat: v.latitude, lng: v.longitude };
        }

        return v;
      },
      0
    );
  } catch (_) {
    return "{}";
  }
}

function asCell(v) {
  if (v === null || v === undefined) return "";
  if (typeof v === "string") return v;
  if (typeof v === "number" || typeof v === "boolean") return v;

  const iso = toIsoStringMaybe(v);
  if (iso) return iso;

  // Arrays/objects: put JSON so Sheets stays consistent.
  if (Array.isArray(v) || typeof v === "object") {
    return safeJson(v);
  }

  return String(v);
}

async function getSheetsClient() {
  const auth = new google.auth.GoogleAuth({
    scopes: [SHEETS_SCOPE],
  });
  const sheets = google.sheets({ version: "v4", auth });
  return sheets;
}

async function ensureSheetTabs({ sheets, spreadsheetId, titles }) {
  const resp = await sheets.spreadsheets.get({ spreadsheetId });
  const existing = new Set(
    ((resp.data && resp.data.sheets) || [])
      .map((s) => (s && s.properties ? String(s.properties.title || "") : ""))
      .filter(Boolean)
  );

  const toCreate = (titles || []).filter((t) => t && !existing.has(t));
  if (!toCreate.length) return;

  await sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    requestBody: {
      requests: toCreate.map((title) => ({
        addSheet: {
          properties: {
            title,
          },
        },
      })),
    },
  });
}

async function clearTab({ sheets, spreadsheetId, title }) {
  // Clear a very wide range to remove previous export content.
  await sheets.spreadsheets.values.clear({
    spreadsheetId,
    range: `${title}!A:ZZZ`,
  });
}

async function writeTabValues({
  sheets,
  spreadsheetId,
  title,
  values,
  chunkSize = 5000,
}) {
  const rows = Array.isArray(values) ? values : [];
  if (!rows.length) {
    await clearTab({ sheets, spreadsheetId, title });
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `${title}!A1`,
      valueInputOption: "RAW",
      requestBody: {
        values: [["(no data)"]],
      },
    });
    return;
  }

  await clearTab({ sheets, spreadsheetId, title });

  // Chunked updates to avoid request payload size limits.
  let startRow = 1;
  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize);

    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `${title}!A${startRow}`,
      valueInputOption: "RAW",
      requestBody: {
        values: chunk,
      },
    });

    startRow += chunk.length;
  }
}

module.exports = {
  asCell,
  safeJson,
  getSheetsClient,
  ensureSheetTabs,
  writeTabValues,
};
