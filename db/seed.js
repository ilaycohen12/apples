// Runs automatically ONCE, the first time the mongo container starts
// with an empty data volume (via /docker-entrypoint-initdb.d/).

// Switch to the "store" database (created automatically on first insert)
db = db.getSiblingDB('store');

// Insert the exact data from the requirements into the "fruits" collection
db.fruits.insertMany([
  { "_id": 1, "name": "apples",   "qty": 5, "rating": 3 },
  { "_id": 2, "name": "bananas",  "qty": 7, "rating": 1, "microsieverts": 0.1 },
  { "_id": 3, "name": "oranges",  "qty": 6, "rating": 2 },
  { "_id": 4, "name": "avocados", "qty": 3, "rating": 5 }
]);

print('Seeded store.fruits with ' + db.fruits.countDocuments() + ' documents');
