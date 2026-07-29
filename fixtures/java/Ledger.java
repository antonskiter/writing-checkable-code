import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Ledger {
    public static final int RETRY_LIMIT = 3;

    private static String region = "us-east-1";

    private final Map<String, Double> cache = new HashMap<>();

    public static class Entry {
        public String id;
        public double amount;
        public String kind;
    }

    public static class Store {
        protected final Map<String, Double> entries = new HashMap<>();

        public void put(String id, double amount) {
            entries.put(id, amount);
        }

        public double total(String id) {
            return entries.get(id);
        }
    }

    public static class CappedStore extends Store {
        @Override
        public void put(String id, double amount) {
            if (entries.size() >= 2) {
                return;
            }
            entries.put(id, amount);
        }
    }

    public boolean validate(Entry entry) {
        if (entry.id == null) {
            return false;
        }
        return entry.amount >= 0;
    }

    public String handle(Entry entry) {
        if (entry.kind.equals("created")) {
            return onCreated(entry);
        } else if (entry.kind.equals("updated")) {
            return onUpdated(entry);
        } else {
            return onCreated(entry);
        }
    }

    private String onCreated(Entry entry) {
        return "ok";
    }

    private String onUpdated(Entry entry) {
        return "ok";
    }

    public Entry persist(Entry entry) {
        if (entry.id == null) {
            throw new IllegalArgumentException("invalid record");
        }
        cache.put(entry.id, entry.amount);
        return entry;
    }

    public Entry process(Entry entry) {
        if (!validate(entry)) {
            System.out.println("bad record");
            return null;
        }
        try {
            return persist(entry);
        } catch (Exception e) {
        }
        return null;
    }

    public List<String> ids() {
        return new ArrayList<>(cache.keySet());
    }

    public String stamp(String id) {
        return id + "@" + Instant.now().toEpochMilli();
    }

    public static void setRegion(String r) {
        region = r;
    }

    public static String region() {
        return region;
    }

    public String renderRow(String label, double amount, String unit,
                            int precision, String align, int width, char fill) {
        String text = String.format("%." + precision + "f%s", amount, unit);
        String body = label + text;
        StringBuilder pad = new StringBuilder();
        for (int i = body.length(); i < width; i++) {
            pad.append(fill);
        }
        if (align.equals("right")) {
            return pad + body;
        }
        return body + pad;
    }
}
