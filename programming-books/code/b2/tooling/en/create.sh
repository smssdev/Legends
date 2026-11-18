# Create a project from the vanilla TypeScript template
$ npm create vite@latest my-shop -- --template vanilla-ts --no-interactive
create-vite v9.3.4
Scaffolding project in ~/code/my-shop...
$ cd my-shop
# Download the packages it needs
$ npm install
added 17 packages, and audited 18 packages in 5s
# What the template created
$ find . -path ./node_modules -prune -o -type f -print | sort
./.gitignore
./index.html
./package-lock.json
./package.json
./src/format.ts
./src/main.ts
./src/products.ts
./src/style.css
./tsconfig.json
