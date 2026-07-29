import { Order } from "./orders";

const MAX_RETRIES = 3;

export function renderRow(
  label: string,
  order: Order,
  unit: string,
  precision: number,
  align: string,
  width: number,
  fill: string,
): string {
  const text = `${order.amount.toFixed(precision)}${unit}`;
  if (align === "right") {
    return (label + text).padStart(width, fill);
  }
  return (label + text).padEnd(width, fill);
}

export function totals(orders: Order[]): Record<string, number> {
  const byId: Record<string, number> = {};
  for (const order of orders) {
    byId[order.id] = (byId[order.id] ?? 0) + order.amount;
  }
  return byId;
}

export function attempts(): number {
  return MAX_RETRIES;
}

export function summarise(orders: Order[]): string {
  const ids = new Set(orders.map((o) => o.id));
  return [...ids].join(",");
}

export function load(raw: string): Order[] {
  try {
    return JSON.parse(raw) as Order[];
  } catch (e) {}
  return [];
}
