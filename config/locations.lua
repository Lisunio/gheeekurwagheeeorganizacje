-- type = 'criminal' nie korzysta z joba.
-- type = 'company' korzysta z ESX joba ustawionego w job.
-- interior = 'open' oznacza zwykłe wejście.
-- interior = 'teleport' tworzy wejście/wyjście przez target.

Config.Locations = {
    grove = {
        label = 'Grove Street',
        type = 'criminal',
        coords = vec3(114.76, -1961.18, 21.33),
        locker = vec3(112.35, -1961.35, 21.33),
        stash = vec3(109.92, -1960.64, 21.33),
        clothing = vec3(111.40, -1960.20, 21.33),
        interior = 'open',
        entry = nil,
        exit = nil,
        capacity = 500000,
        slots = 80
    },

    hidden = {
        label = 'Ukryta siedziba',
        type = 'criminal',
        coords = vec3(1388.0, -2080.0, 52.0),
        locker = vec3(1388.0, -2080.0, 52.0),
        stash = vec3(1390.0, -2080.0, 52.0),
        clothing = vec3(1386.0, -2080.0, 52.0),
        interior = 'teleport',
        entry = vec3(1380.0, -2080.0, 52.0),
        exit = vec3(1388.0, -2080.0, 52.0),
        capacity = 500000,
        slots = 80
    },

    -- Przykład firmy. Job musi istnieć w ESX.
    company_example = {
        label = 'Biuro firmy',
        type = 'company',
        job = 'mechanic',
        coords = vec3(-347.20, -133.30, 39.01),
        locker = vec3(-346.5, -134.0, 39.0),
        stash = vec3(-344.9, -134.2, 39.0),
        clothing = vec3(-349.0, -134.0, 39.0),
        interior = 'open',
        entry = nil,
        exit = nil,
        capacity = 500000,
        slots = 80
    },

    -- Eclipse Club (zasob mrp-eclipse). Szafki, magazyn i przebieranie obsluguje
    -- mrp-eclipse, wiec tutaj zostaje tylko tablet organizacji (target przy panelu klubu).
    eclipse = {
        label = 'Eclipse Club',
        type = 'company',
        job = 'eclipse',
        coords = vec3(99.74, -1298.23, 35.67),
        locker = nil,
        stash = nil,
        clothing = nil,
        interior = 'open',
        entry = nil,
        exit = nil,
        capacity = 500000,
        slots = 80
    }
}
