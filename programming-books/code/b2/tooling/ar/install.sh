# أضف مدققاً للكود ومنسّقاً له
$ npm install -D eslint @eslint/js typescript-eslint prettier
npm error code ERESOLVE
npm error ERESOLVE unable to resolve dependency tree
npm error Found: typescript@7.0.2
npm error Could not resolve dependency:
npm error peer typescript@">=4.8.4 <6.1.0" from typescript-eslint@8.73.0
# اختر نسخة TypeScript يدعمها typescript-eslint
$ npm install -D typescript@~6.0.0 eslint @eslint/js typescript-eslint prettier
added 96 packages, removed 1 package, changed 1 package, and audited 113 packages in 6s
# الاعتماديات المباشرة، ونسخها بالضبط
$ npm ls --depth=0
├── @eslint/js@10.0.1
├── eslint@10.15.0
├── prettier@3.10.1
├── typescript-eslint@8.73.0
├── typescript@6.0.3
└── vite@8.3.8
# سمِّ الأوامر التي سيشغّلها الفريق
$ npm pkg set scripts.lint="eslint src" scripts.format="prettier --write src" scripts.check="tsc && eslint src && prettier --check src"
