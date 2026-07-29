import java.time.Instant

const val RETRY_LIMIT = 3

var region = "us-east-1"

sealed class Entry {
    data class Created(val id: String, val amount: Double) : Entry()
    data class Updated(val id: String, val amount: Double) : Entry()
    data class Deleted(val id: String) : Entry()
}

open class Store {
    protected val entries = mutableMapOf<String, Double>()

    open fun put(id: String, amount: Double) {
        entries[id] = amount
    }

    fun total(id: String): Double = entries.getValue(id)

    fun ids(): List<String> = entries.keys.toList()
}

class CappedStore : Store() {
    override fun put(id: String, amount: Double) {
        if (entries.size >= 2) return
        entries[id] = amount
    }
}

class Ledger {
    private val store = Store()
    private val cache = mutableMapOf<String, Double>()

    fun apply(entry: Entry): String = when (entry) {
        is Entry.Created -> {
            store.put(entry.id, entry.amount)
            "ok"
        }
        is Entry.Updated -> {
            store.put(entry.id, entry.amount)
            "ok"
        }
        is Entry.Deleted -> "ok"
    }

    fun handle(kind: String): String {
        return if (kind == "created") {
            onCreated()
        } else if (kind == "updated") {
            onUpdated()
        } else {
            onCreated()
        }
    }

    private fun onCreated(): String = "ok"

    private fun onUpdated(): String = "ok"

    fun validate(id: String?, amount: Double): Boolean {
        if (id == null) return false
        return amount >= 0
    }

    fun persist(id: String, amount: Double): Double {
        require(id.isNotEmpty()) { "invalid record" }
        cache[id] = amount
        return amount
    }

    fun process(id: String?, amount: Double): Double? {
        if (!validate(id, amount)) {
            println("bad record")
            return null
        }
        return try {
            persist(id!!, amount)
        } catch (e: Exception) {
            null
        }
    }

    fun stamp(id: String): String = "$id@${Instant.now().toEpochMilli()}"

    fun fetchDeadline(): Long = Instant.now().toEpochMilli() + 30_000

    fun renderRow(
        label: String, amount: Double, unit: String, precision: Int,
        align: String, width: Int, fill: Char
    ): String {
        val text = "%.${precision}f%s".format(amount, unit)
        val body = label + text
        return if (align == "right") body.padStart(width, fill) else body.padEnd(width, fill)
    }
}
