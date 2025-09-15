import { executePerpustakaanQuery } from "./database";

// This mimics the perpustakaan database interface
const db = {
  query: executePerpustakaanQuery
};

export default db;