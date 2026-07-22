// Creates the database user the UniFi Network Application uses to connect to
// MongoDB. Runs once, only while the mongo data directory is still empty.
// postroot.sh replaces MONGO_PASS_PLACEHOLDER with the generated password.
db.getSiblingDB("unifi").createUser({
  user: "unifi",
  pwd: "MONGO_PASS_PLACEHOLDER",
  roles: [{ role: "dbOwner", db: "unifi" }]
});
db.getSiblingDB("unifi_stat").createUser({
  user: "unifi",
  pwd: "MONGO_PASS_PLACEHOLDER",
  roles: [{ role: "dbOwner", db: "unifi_stat" }]
});
