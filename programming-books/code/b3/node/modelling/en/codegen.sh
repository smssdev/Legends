# Generate TypeScript types from the real database
$ npm run db:types --silent 2>&1 | grep -v '^$'
• Loaded environment variables from '.env'.
• No dialect specified. Assuming 'postgres'.
• Introspecting database...
✓ Introspected 4 tables and generated ./src/db-types.ts in 35ms.
  
