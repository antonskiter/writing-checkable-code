const RETRY_LIMIT = 3;

let currentRegion = "us-east-1";

const cache = new Map();

function isOrder(value) {
  return (
    typeof value === "object" &&
    value !== null &&
    typeof value.id === "string" &&
    typeof value.amount === "number"
  );
}

function persist(order) {
  cache.set(order.id, order.amount);
  return { ...order, amount: Math.round(order.amount * 100) / 100 };
}

function ingest(raw) {
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!isOrder(parsed)) {
    console.warn("bad order");
    return null;
  }
  return persist(parsed);
}

function handle(event) {
  switch (event.kind) {
    case "created":
      return "ok";
    case "updated":
      return "ok";
    default:
      return "ok";
  }
}

function stamp(order) {
  return { ...order, at: Date.now() };
}

function totals(orders) {
  const byId = {};
  for (const order of orders) {
    byId[order.id] = (byId[order.id] ?? 0) + order.amount;
  }
  return byId;
}

function load(raw) {
  try {
    return JSON.parse(raw);
  } catch (e) {}
  return [];
}

function setRegion(region) {
  currentRegion = region;
}

function region() {
  return currentRegion;
}

async function retry(url) {
  const deadline = Date.now() + 30000;
  while (Date.now() < deadline) {
    const response = await fetch(url);
    if (response.status < 500) {
      return response.json();
    }
  }
  throw new Error(url);
}

module.exports = {
  RETRY_LIMIT,
  isOrder,
  persist,
  ingest,
  handle,
  stamp,
  totals,
  load,
  setRegion,
  region,
  retry,
};
