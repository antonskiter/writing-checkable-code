class Results:
    def __init__(self, inputs, formulas):
        self._inputs = dict(inputs)
        self._formulas = formulas
        self._version = 0
        self._values = {}
        self.computed = []

    def write(self, name, value):
        self._inputs[name] = value
        self._version += 1
        self._values.clear()

    def last_known(self, name):
        entry = self._values.get(name)
        return None if entry is None else entry[1]

    def value(self, name):
        entry = self._values.get(name)
        if entry is None or entry[0] != self._version:
            reads, formula = self._formulas[name]
            self.computed.append(name)
            entry = (self._version, formula(*(self._inputs[r] for r in reads)))
            self._values[name] = entry
        return entry[1]
