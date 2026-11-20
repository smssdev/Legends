# المرحلة 1: اعتماديات الإنتاج وحدها، من ملف القفل
FROM node:22-slim AS deps
WORKDIR /app
# تُنسخ قبل الكود: هذه الطبقة لا يُعاد بناؤها إلا حين تتغير الاعتماديات
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# المرحلة 2: الصورة التي تعمل؛ لا شيء من المرحلة 1 إلا node_modules
FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src
# لا تعمل بصلاحيات root داخل الحاوية أبداً
USER node
EXPOSE 3000
# يسأل Docker التطبيق نفسه هل هو بخير
HEALTHCHECK --interval=5s --timeout=2s \
  CMD node -e "fetch('http://localhost:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"
CMD ["node", "src/server.ts"]
