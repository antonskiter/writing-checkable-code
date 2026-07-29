export const RETRY_LIMIT = 3;

let currentRegion = "us-east-1";

export type Event =
  | { kind: "created"; id: string; amount: number }
  | { kind: "updated"; id: string; amount: number }
  | { kind: "deleted"; id: string };

export interface Order {
  id: string;
  amount: number;
}

export function isOrder(value: unknown): boolean {
  if (typeof value !== "object" || value === null) return false;
  const candidate = value as Record<string, unknown>;
  return typeof candidate.id === "string" && typeof candidate.amount === "number";
}

export function persist(order: Order): Order {
  return { ...order, amount: Math.round(order.amount * 100) / 100 };
}

export function ingest(raw: string): Order | null {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!isOrder(parsed)) {
    console.warn("bad order");
    return null;
  }
  return persist(parsed as Order);
}

export function handle(event: Event): string {
  switch (event.kind) {
    case "created":
      return "ok";
    case "updated":
      return "ok";
    default:
      return "ok";
  }
}

export function stamp(order: Order): Order & { at: number } {
  return { ...order, at: Date.now() };
}

export function setRegion(region: string): void {
  currentRegion = region;
}

export function region(): string {
  return currentRegion;
}

export function retry(url: string): Promise<Response> {
  // @ts-ignore
  return fetch(url, { retries: RETRY_LIMIT });
}
