-- الإيراد الشهري المتكرر: ما تجلبه الاشتراكات المدفوعة كل شهر
SELECT plan, count(*) AS salons, sum(price) / 100 AS mrr_egp
FROM salons JOIN plans ON plans.id = salons.plan
GROUP BY plan ORDER BY plan;
